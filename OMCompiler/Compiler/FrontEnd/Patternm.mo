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

encapsulated package Patternm
" file:        Patternm.mo
  package:     Patternm
  description: Patternmatching


  This module contains the patternmatch algorithm for the MetaModelica
  matchcontinue expression."

import Absyn;
import Ceval;
import ClassInf;
import ConnectionGraph;
import DAE;
import FCore;
import HashTableStringToPath;
import SCode;
import Dump;
import InnerOuter;
import Prefix;
import Types;
import UnitAbsyn;

protected

import Algorithm;
import AvlSetString;
import BaseHashTable;
import ComponentReference;
import Connect;
import DAEUtil;
import ElementSource;
import Expression;
import ExpressionDump;
import Error;
import ErrorExt;
import Flags;
import FGraph;
import Inst;
import InstSection;
import InstTypes;
import InstUtil;
import List;
import Lookup;
import MetaModelica.Dangerous;
import SCodeUtil;
import Static;
import System;
import Util;
import SCodeDump;

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
  input SourceInfo info;
  output Util.Status outStatus;
algorithm
  outStatus := match (args,fieldNameList,status,info)
    local
      list<String> argsNames;
      String str1,str2;
    case ({},_,_,_) then status;
    else
      equation
        (argsNames,_) = Absyn.getNamedFuncArgNamesAndValues(args);
        str1 = stringDelimitList(argsNames, ",");
        str2 = stringDelimitList(fieldNameList, ",");
        Error.addSourceMessage(Error.META_INVALID_PATTERN_NAMED_FIELD, {str1,str2}, info);
      then Util.FAILURE();
  end match;
end checkInvalidPatternNamedArgs;

public function elabPatternCheckDuplicateBindings
  input FCore.Cache cache;
  input FCore.Graph env;
  input Absyn.Exp lhs;
  input DAE.Type ty;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Pattern pattern;
algorithm
  (outCache,pattern) := elabPattern2(cache,env,lhs,ty,info,Error.getNumErrorMessages());
  checkPatternsDuplicateAsBindings(pattern::{}, info);
end elabPatternCheckDuplicateBindings;

protected function elabPattern
  input FCore.Cache cache;
  input FCore.Graph env;
  input Absyn.Exp lhs;
  input DAE.Type ty;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Pattern pattern;
algorithm
  (outCache,pattern) := elabPattern2(cache,env,lhs,ty,info,Error.getNumErrorMessages());
end elabPattern;

protected function checkPatternsDuplicateAsBindings
  input list<DAE.Pattern> patterns;
  input SourceInfo info;
protected
  list<String> usedVariables;
algorithm
  (_, usedVariables) := traversePatternList(patterns, findBoundVariables, {});
  usedVariables := List.sortedUniqueOnlyDuplicates(List.sort(usedVariables, Util.strcmpBool), stringEq);
  if not listEmpty(usedVariables) then
    Error.addSourceMessage(Error.DUPLICATE_DEFINITION, {stringDelimitList(usedVariables, ", ")}, info);
    fail();
  end if;
end checkPatternsDuplicateAsBindings;

protected function findBoundVariables
  input DAE.Pattern pat;
  input list<String> boundVars;
  output DAE.Pattern outPat=pat;
  output list<String> outBoundVars;
algorithm
  outBoundVars := match pat
    case DAE.PAT_AS() then pat.id::boundVars;
    case DAE.PAT_AS_FUNC_PTR() then pat.id::boundVars;
    else boundVars;
  end match;
end findBoundVariables;

protected function elabPattern2
  input FCore.Cache inCache;
  input FCore.Graph env;
  input Absyn.Exp inLhs;
  input DAE.Type ty;
  input SourceInfo info;
  input Integer numError;
  output FCore.Cache outCache;
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
      FCore.Cache cache;
      Absyn.Exp lhs;
      DAE.Attributes attr;
      DAE.Exp elabExp;
      DAE.Properties prop;
      DAE.Const const;
      Values.Value val;
      SCode.Variability variability;

    case (cache,_,Absyn.INTEGER(i),_,_,_)
      equation
        et = validPatternType(ty,DAE.T_INTEGER_DEFAULT,inLhs,info);
      then (cache,DAE.PAT_CONSTANT(et,DAE.ICONST(i)));

    case (cache,_,Absyn.REAL(str),_,_,_)
      equation
        et = validPatternType(ty,DAE.T_REAL_DEFAULT,inLhs,info);
        r = System.stringReal(str);
      then (cache,DAE.PAT_CONSTANT(et,DAE.RCONST(r)));

    case (cache,_,Absyn.UNARY(Absyn.UMINUS(),Absyn.INTEGER(i)),_,_,_)
      equation
        et = validPatternType(ty,DAE.T_INTEGER_DEFAULT,inLhs,info);
        i = -i;
      then (cache,DAE.PAT_CONSTANT(et,DAE.ICONST(i)));

    case (cache,_,Absyn.UNARY(Absyn.UMINUS(),Absyn.REAL(str)),_,_,_)
      equation
        et = validPatternType(ty,DAE.T_REAL_DEFAULT,inLhs,info);
        r = System.stringReal(str);
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
        validPatternType(ty,DAE.T_NONE_DEFAULT,inLhs,info);
      then (cache,DAE.PAT_CONSTANT(NONE(),DAE.META_OPTION(NONE())));

    case (cache,_,Absyn.CALL(Absyn.CREF_IDENT("SOME",{}),Absyn.FUNCTIONARGS({exp},{})),DAE.T_METAOPTION(ty = ty2),_,_)
      equation
        (cache,pattern) = elabPattern(cache,env,exp,ty2,info);
      then (cache,DAE.PAT_SOME(pattern));

    case (cache,_,Absyn.CONS(head,tail),tyTail as DAE.T_METALIST(ty = tyHead),_,_)
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

    case (cache,_,Absyn.TUPLE(exps),DAE.T_TUPLE(types = tys),_,_)
      equation
        (cache,patterns) = elabPatternTuple(cache,env,exps,tys,info,inLhs);
      then (cache,DAE.PAT_CALL_TUPLE(patterns));

    case (cache,_,lhs as Absyn.CALL(fcr,fargs),DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(utPath)),_,_)
      equation
        (cache,pattern) = elabPatternCall(cache,env,Absyn.crefToPath(fcr),fargs,utPath,info,lhs);
      then (cache,pattern);

    case (cache,_,lhs as Absyn.CALL(fcr,fargs),DAE.T_METAUNIONTYPE(path = utPath),_,_)
      equation
        (cache,pattern) = elabPatternCall(cache,env,Absyn.crefToPath(fcr),fargs,utPath,info,lhs);
      then (cache,pattern);

    case (cache,_,lhs as Absyn.CALL(fcr,fargs),DAE.T_METARECORD(utPath = utPath),_,_)
      equation
        (cache,pattern) = elabPatternCall(cache,env,Absyn.crefToPath(fcr),fargs,utPath,info,lhs);
      then (cache,pattern);

    case (cache,_,Absyn.CREF(),ty1,_,_)
      guard
        Types.isBoxedType(ty1) or
        (match Types.unboxedType(ty1)
          case DAE.T_ENUMERATION() then true;
          case DAE.T_INTEGER() then true;
          case DAE.T_REAL() then true;
          case DAE.T_STRING() then true;
          case DAE.T_BOOL() then true;
          else false;
        end match)
      equation
        (cache,elabExp,DAE.PROP(type_=ty2, constFlag=const)) = Static.elabExp(cache,env,inLhs,false,false,Prefix.NOPRE(),info);
        et = validPatternType(ty1,ty2,inLhs,info);
        true = Types.isConstant(const);
        (cache, val) = Ceval.ceval(cache, env, elabExp, false, inMsg = Absyn.MSG(info));
        elabExp = ValuesUtil.valueExp(val);
      then (cache, DAE.PAT_CONSTANT(et, elabExp));

    case (cache,_,Absyn.AS(id,exp),ty2,_,_)
      equation
        (cache,DAE.TYPES_VAR(ty = ty1, attributes = attr),_,_,_,_) = Lookup.lookupIdent(cache,env,id);
        lhs = Absyn.CREF(Absyn.CREF_IDENT(id, {}));
        Static.checkAssignmentToInput(lhs, attr, env, false, info);
        et = validPatternType(ty2,ty1,inLhs,info);
        (cache,pattern) = elabPattern(cache,env,exp,ty2,info);
        pattern = if Types.isFunctionType(ty2) then DAE.PAT_AS_FUNC_PTR(id,pattern) else DAE.PAT_AS(id,et,attr,pattern);
      then (cache,pattern);

    case (cache,_,Absyn.CREF(Absyn.CREF_IDENT(id,{})),ty2,_,_)
      algorithm
        (cache,DAE.TYPES_VAR(ty = ty1, attributes = attr as DAE.ATTR(variability=variability)),_,_,_,_) := Lookup.lookupIdent(cache,env,id);
        if SCode.isParameterOrConst(variability) then
          Error.addSourceMessage(Error.PATTERN_VAR_NOT_VARIABLE, {id, SCodeDump.unparseVariability(variability)}, info);
          fail();
        end if;
        Static.checkAssignmentToInput(inLhs, attr, env, false, info);
        et := validPatternType(ty2,ty1,inLhs,info);
        pattern := if Types.isFunctionType(ty2) then DAE.PAT_AS_FUNC_PTR(id,DAE.PAT_WILD()) else DAE.PAT_AS(id,et,attr,DAE.PAT_WILD());
      then (cache,pattern);

    case (cache,_,Absyn.AS(id,_),_,_,_)
      equation
        failure((_,_,_,_,_,_) = Lookup.lookupIdent(cache,env,id));
        Error.addSourceMessage(Error.LOOKUP_VARIABLE_ERROR,{id,""},info);
      then fail();

    case (cache,_,Absyn.CREF(Absyn.CREF_IDENT("NONE",{})),_,_,_)
      equation
        failure((_,_,_,_,_,_) = Lookup.lookupIdent(cache,env,"NONE"));
        Error.addSourceMessage(Error.META_NONE_CREF,{},info);
      then fail();

    case (cache,_,Absyn.CREF(Absyn.CREF_IDENT(id,{})),_,_,_)
      equation
        failure((_,_,_,_,_,_) = Lookup.lookupIdent(cache,env,id));
        false = "NONE" == id;
        Error.addSourceMessage(Error.LOOKUP_VARIABLE_ERROR,{id,""},info);
      then fail();

    case (cache,_,Absyn.CREF(Absyn.WILD()),_,_,_) then (cache,DAE.PAT_WILD());

    case (_,_,lhs,_,_,_)
      equation
        true = numError == Error.getNumErrorMessages();
        str = Dump.printExpStr(lhs) + " of type " + Types.unparseType(ty);
        Error.addSourceMessage(Error.META_INVALID_PATTERN, {str}, info);
      then fail();

  end matchcontinue;
end elabPattern2;

protected function elabPatternTuple
  input FCore.Cache inCache;
  input FCore.Graph env;
  input list<Absyn.Exp> inExps;
  input list<DAE.Type> inTys;
  input SourceInfo info;
  input Absyn.Exp lhs "for error messages";
  output FCore.Cache outCache;
  output list<DAE.Pattern> patterns;
algorithm
  (outCache,patterns) := match (inCache,env,inExps,inTys,info,lhs)
    local
      Absyn.Exp exp;
      String s;
      DAE.Pattern pattern;
      DAE.Type ty;
      FCore.Cache cache;
      list<Absyn.Exp> exps;
      list<DAE.Type> tys;

    case (cache,_,{},{},_,_) then (cache,{});

    case (cache,_,exp::exps,ty::tys,_,_)
      equation
        (cache,pattern) = elabPattern(cache,env,exp,ty,info);
        (cache,patterns) = elabPatternTuple(cache,env,exps,tys,info,lhs);
      then (cache,pattern::patterns);

    else
      equation
        s = Dump.printExpStr(lhs);
        s = "pattern " + s;
        Error.addSourceMessage(Error.WRONG_NO_OF_ARGS, {s}, info);
      then fail();
  end match;
end elabPatternTuple;

protected function elabPatternCall
  input FCore.Cache inCache;
  input FCore.Graph env;
  input Absyn.Path callPath;
  input Absyn.FunctionArgs fargs;
  input Absyn.Path utPath;
  input SourceInfo info;
  input Absyn.Exp lhs "for error messages";
  output FCore.Cache outCache;
  output DAE.Pattern pattern;
algorithm
  (outCache,pattern) := matchcontinue (inCache,env,callPath,fargs,utPath,info,lhs)
    local
      String s;
      DAE.Type t;
      Absyn.Path utPath1,utPath2,fqPath;
      Integer index,numPosArgs;
      list<Absyn.NamedArg> namedArgList,invalidArgs;
      list<Absyn.Exp> funcArgsNamedFixed,funcArgs, funcArgs2;
      list<String> fieldNameList,fieldNamesNamed;
      list<DAE.Type> fieldTypeList, typeVars;
      list<DAE.Var> fieldVarList;
      list<DAE.Pattern> patterns;
      list<tuple<DAE.Pattern,String,DAE.Type>> namedPatterns;
      Boolean knownSingleton;
      FCore.Cache cache;
      Boolean allWild;

    case (cache,_,_,Absyn.FUNCTIONARGS(funcArgs,namedArgList),utPath2,_,_)
      algorithm
        (cache,_,_) :=
          Lookup.lookupType(cache, env, callPath, NONE());
        (cache,DAE.T_METARECORD(utPath=utPath1,index=index,fields=fieldVarList,typeVars=typeVars,knownSingleton = knownSingleton,path = fqPath),_) :=
          Lookup.lookupType(cache, env, callPath, NONE());
        validUniontype(utPath1,utPath2,info,lhs);

        fieldTypeList := List.map(fieldVarList, Types.getVarType);
        fieldNameList := List.map(fieldVarList, Types.getVarName);

        if Flags.isSet(Flags.PATTERNM_ALL_INFO) then
          for namedArg in namedArgList loop
            _ := match namedArg
              case Absyn.NAMEDARG(argValue=Absyn.CREF(Absyn.WILD()))
                equation
                  Error.addSourceMessage(Error.META_EMPTY_CALL_PATTERN, {namedArg.argName}, info);
                then ();
              else ();
            end match;
          end for;
          if listEmpty(namedArgList) and not listEmpty(funcArgs) then
            allWild := true;
            for arg in funcArgs loop
              allWild := match arg
                case Absyn.CREF(Absyn.WILD()) then true;
                else false;
              end match;
              if not allWild then
                break;
              end if;
            end for;
            if allWild then
              Error.addSourceMessage(Error.META_ALL_EMPTY, {Absyn.pathString(callPath)}, info);
            end if;
          end if;
        end if;

        (funcArgs,namedArgList) := checkForAllWildCall(funcArgs,namedArgList,listLength(fieldNameList));

        numPosArgs := listLength(funcArgs);
        (_,fieldNamesNamed) := List.split(fieldNameList, numPosArgs);
        checkMissingArgs(fqPath,numPosArgs,fieldNamesNamed,listLength(namedArgList),info);
        (funcArgsNamedFixed,invalidArgs) := generatePositionalArgs(fieldNamesNamed,namedArgList,{});
        funcArgs2 := listAppend(funcArgs,funcArgsNamedFixed);
        Util.SUCCESS() := checkInvalidPatternNamedArgs(invalidArgs,fieldNameList,Util.SUCCESS(),info);
        (cache,patterns) := elabPatternTuple(cache,env,funcArgs2,fieldTypeList,info,lhs);
      then (cache,DAE.PAT_CALL(fqPath,index,patterns,fieldVarList,typeVars,knownSingleton));

    case (cache,_,_,Absyn.FUNCTIONARGS(funcArgs,namedArgList),utPath2,_,_)
      equation
        (cache,DAE.T_FUNCTION(funcResultType = DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_),varLst=fieldVarList), path = fqPath),_) =
          Lookup.lookupType(cache, env, callPath, NONE());
        true = Absyn.pathEqual(fqPath,utPath2);

        fieldTypeList = List.map(fieldVarList, Types.getVarType);
        fieldNameList = List.map(fieldVarList, Types.getVarName);

        (funcArgs,namedArgList) = checkForAllWildCall(funcArgs,namedArgList,listLength(fieldNameList));

        numPosArgs = listLength(funcArgs);
        (_,fieldNamesNamed) = List.split(fieldNameList, numPosArgs);
        checkMissingArgs(fqPath,numPosArgs,fieldNamesNamed,listLength(namedArgList),info);

        (funcArgsNamedFixed,invalidArgs) = generatePositionalArgs(fieldNamesNamed,namedArgList,{});
        funcArgs2 = listAppend(funcArgs,funcArgsNamedFixed);
        Util.SUCCESS() = checkInvalidPatternNamedArgs(invalidArgs,fieldNameList,Util.SUCCESS(),info);
        (cache,patterns) = elabPatternTuple(cache,env,funcArgs2,fieldTypeList,info,lhs);
        namedPatterns = List.thread3Tuple(patterns, fieldNameList, List.map(fieldTypeList,Types.simplifyType));
        namedPatterns = List.filterOnTrue(namedPatterns, filterEmptyPattern);
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
  input SourceInfo info;
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
        str = Absyn.pathString(path) + " missing pattern for fields: " + str;
        Error.addSourceMessage(Error.META_INVALID_PATTERN,{str},info);
      then fail();
*/
    /*
    case (path,_,_,_,info)
      equation
        str = Absyn.pathString(path) + " mixing positional and named patterns";
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
      then ({},{});
    else (args,named);
  end match;
end checkForAllWildCall;

protected function validPatternType
  input DAE.Type inTy1;
  input DAE.Type inTy2;
  input Absyn.Exp lhs;
  input SourceInfo info;
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
        (_,_) = Types.matchType(crefExp,ty1,ty2,true);
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
  input SourceInfo info;
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
      then "SOME(" + str + ")";
    case DAE.PAT_META_TUPLE(pats)
      equation
        str = stringDelimitList(List.map(pats,patternStr),",");
      then "(" + str + ")";

    case DAE.PAT_CALL_TUPLE(pats)
      equation
        str = stringDelimitList(List.map(pats,patternStr),",");
      then "(" + str + ")";

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

    case DAE.PAT_CONS(head,tail) then patternStr(head) + "::" + patternStr(tail);

    case DAE.PAT_CONSTANT(exp=exp) then ExpressionDump.printExpStr(exp);
    // case DAE.PAT_CONSTANT(SOME(et),exp) then "(" + Types.unparseType(et) + ")" + ExpressionDump.printExpStr(exp);
    case DAE.PAT_AS(id=id,pat=pat) then id + " as " + patternStr(pat);
    case DAE.PAT_AS_FUNC_PTR(id, pat) then id + " as " + patternStr(pat);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Patternm.patternStr not implemented correctly"});
      then "*PATTERN*";
  end matchcontinue;
end patternStr;

public function elabMatchExpression
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp matchExp;
  input Boolean impl;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  Integer numError = Error.getNumErrorMessages();
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,matchExp,impl,performVectorization,inPrefix,info,numError)
    local
      Absyn.MatchType matchTy;
      Absyn.Exp inExp;
      list<Absyn.Exp> inExps;
      list<Absyn.ElementItem> decls;
      list<Absyn.Case> cases;
      list<DAE.Element> matchDecls;
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
      FCore.Cache cache;
      FCore.Graph env;
      Integer hashSize;
      list<list<String>> inputAliases,inputAliasesAndCrefs;
      AvlSetString.Tree declsTree;

    case (cache,env,Absyn.MATCHEXP(matchTy=matchTy,inputExp=inExp,localDecls=decls,cases=cases),_,_,pre,_,_)
      equation
        // First do inputs
        inExps = convertExpToPatterns(inExp);
        (inExps,inputAliases,inputAliasesAndCrefs) = List.map_3(inExps,getInputAsBinding);
        (cache,elabExps,elabProps) = Static.elabExpList(cache,env,inExps,impl,performVectorization,pre,info);
        // Then add locals
        (cache,SOME((env,DAE.DAE(matchDecls),declsTree))) = addLocalDecls(cache,env,decls,FCore.matchScopeName,impl,info);
        tys = List.map(elabProps, Types.getPropType);
        env = addAliasesToEnv(env, tys, inputAliases, info);
        (cache,elabCases,resType) = elabMatchCases(cache,env,cases,tys,inputAliasesAndCrefs,declsTree,impl,performVectorization,pre,info);
        prop = DAE.PROP(resType,DAE.C_VAR());
        et = Types.simplifyType(resType);
        (elabExps,inputAliases,elabCases) = filterUnusedPatterns(elabExps,inputAliases,elabCases) "filterUnusedPatterns() First time to speed up the other optimizations.";
        elabCases = caseDeadCodeElimination(matchTy, elabCases, {}, {}, false);
        // Do DCE before converting mc to m
        matchTy = optimizeContinueToMatch(matchTy,elabCases,info);
        elabCases = optimizeContinueJumps(matchTy, elabCases);
        // hashSize = Util.nextPowerOf2(listLength(matchDecls)) + 1; // faster, but unstable in RML
        hashSize = Util.nextPrime(listLength(matchDecls));
        ht = getUsedLocalCrefs(Flags.isSet(Flags.PATTERNM_SKIP_FILTER_UNUSED_AS_BINDINGS),DAE.MATCHEXPRESSION(DAE.MATCHCONTINUE(),elabExps,inputAliases,matchDecls,elabCases,et),hashSize);
        (matchDecls,ht) = filterUnusedDecls(matchDecls,ht,{},HashTableStringToPath.emptyHashTableSized(hashSize));
        (elabExps,inputAliases,elabCases) = filterUnusedPatterns(elabExps,inputAliases,elabCases) "filterUnusedPatterns() again to filter out the last parts.";
        (elabMatchTy, elabCases) = optimizeMatchToSwitch(matchTy,elabCases,info);
        checkConstantMatchInputs(elabExps, info);
        exp = DAE.MATCHEXPRESSION(elabMatchTy,elabExps,inputAliases,matchDecls,elabCases,et);
      then (cache,exp,prop);
    else
      equation
        true = numError == Error.getNumErrorMessages();
        str = Dump.printExpStr(matchExp);
        Error.addSourceMessage(Error.META_MATCH_GENERAL_FAILURE, {str}, info);
      then fail();
  end matchcontinue;
end elabMatchExpression;

protected function checkConstantMatchInputs
  input list<DAE.Exp> inputs;
  input SourceInfo info;
algorithm
  for i in inputs loop
    if Expression.isConstValue(i) then
      Error.addSourceMessage(Error.META_MATCH_CONSTANT, {ExpressionDump.printExpStr(i)}, info);
    end if;
  end for;
end checkConstantMatchInputs;

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
  input SourceInfo info;
  output DAE.MatchType outType;
  output list<DAE.MatchCase> outCases;
algorithm
  (outType, outCases) := matchcontinue (matchTy,cases,info)
    local
      tuple<Integer,DAE.Type,Integer> tpl;
      list<list<DAE.Pattern>> patternMatrix;
      list<Option<list<DAE.Pattern>>> optPatternMatrix;
      Integer numNonEmptyColumns;
      String str;
      DAE.Type ty;
    case (Absyn.MATCHCONTINUE(),_,_) then (DAE.MATCHCONTINUE(), cases);
    case (_,_,_)
      algorithm
        true := listLength(cases) > 2;
        for c in cases loop
          DAE.CASE(patternGuard=NONE()) := c;
        end for;
        patternMatrix := List.transposeList(List.map(cases,getCasePatterns));
        (optPatternMatrix,numNonEmptyColumns) := removeWildPatternColumnsFromMatrix(patternMatrix,{},0);
        tpl := findPatternToConvertToSwitch(optPatternMatrix,1,numNonEmptyColumns,info);
        (_,ty,_) := tpl;
        str := Types.unparseType(ty);
        Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.PATTERNM_ALL_INFO),Error.MATCH_TO_SWITCH_OPTIMIZATION, {str}, info);
        outType := DAE.MATCH(SOME(tpl));
        outCases := optimizeSwitchedMatchCases(outType, cases);
      then
        (outType, outCases);

    else (DAE.MATCH(NONE()), cases);
  end matchcontinue;
end optimizeMatchToSwitch;

protected function optimizeSwitchedMatchCases
  "This function optimizes the cases of a match that has been optimized into a switch."
  input DAE.MatchType inMatchType;
  input list<DAE.MatchCase> inCases;
  output list<DAE.MatchCase> outCases;
algorithm
  outCases := match(inMatchType)
    local
      DAE.Pattern pat;
      list<DAE.Pattern> patl;

    // If we're switching on a uniontype, mark all cases that look like RECORD()
    // as singleton, so we can skip doing pattern matching on them (we're
    // already switching on their type, we don't need to check the type in the
    // case also.
    case DAE.MATCH(switch = SOME((_, DAE.T_METATYPE(), _)))
      then list(
          match c
            case DAE.CASE(patterns = {pat as DAE.PAT_CALL(patterns = patl)})
              algorithm
                if allPatternsWild(patl) then
                  pat.knownSingleton := true;
                  c.patterns := {pat};
                end if;
              then
                c;

            else c;
          end match
        for c in inCases);

    else inCases;
  end match;
end optimizeSwitchedMatchCases;

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
        optPats = if alwaysMatch then NONE() else SOME(pats);
        numAcc = if alwaysMatch then numAcc else numAcc+1;
        (acc,numAcc) = removeWildPatternColumnsFromMatrix(patternMatrix,optPats::acc,numAcc);
      then (acc,numAcc);
  end match;
end removeWildPatternColumnsFromMatrix;

protected function findPatternToConvertToSwitch
  input list<Option<list<DAE.Pattern>>> inPatternMatrix;
  input Integer index;
  input Integer numPatternsInMatrix "If there is only 1 pattern, we can optimize the default case";
  input SourceInfo info;
  output tuple<Integer,DAE.Type,Integer> tpl;
algorithm
  tpl := matchcontinue  (inPatternMatrix,index,numPatternsInMatrix,info)
    local
      list<DAE.Pattern> pats;
      DAE.Type ty;
      Integer extraarg;
      list<Option<list<DAE.Pattern>>> patternMatrix;

    case (SOME(pats)::_,_,_,_)
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
        ix = stringHashDjb2Mod(str,65536);
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

    case ({},_,DAE.T_STRING(),_,_)
      equation
        true = listLength(ixs)>11; // hashing has a considerable overhead, only convert to switch if it is worth it
        ix = findMinMod(ixs,1);
      then (DAE.T_STRING_DEFAULT,ix);

    case ({_},_,DAE.T_STRING(),_,1)
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
        {} = List.sortedDuplicates(ixs, intEq);
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
        cases = setCasePatternsCheckZero(cases,patternMatrix);
      then (outInputs,outAliases,cases);
    else (inputs,inAliases,inCases);
  end matchcontinue;
end filterUnusedPatterns;

protected function setCasePatternsCheckZero
  "Handles the case when the pattern matrix becomes empty because no input is matched"
  input list<DAE.MatchCase> inCases;
  input list<list<DAE.Pattern>> patternMatrix;
  output list<DAE.MatchCase> outCases;
algorithm
  outCases := match (inCases,patternMatrix)
    case ({},{}) then inCases;
    case (_,{})
      then List.map1(inCases,setCasePatterns,{});
    else List.threadMap(inCases,patternMatrix,setCasePatterns);
  end match;
end setCasePatternsCheckZero;

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
        (_,true) = Expression.traverseExpBottomUp(e,Expression.hasNoSideEffects,true);
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
        (_,ht) = Expression.traverseExpBottomUp(exp, addLocalCref, HashTableStringToPath.emptyHashTableSized(hashSize));
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
      SourceInfo resultInfo, info;
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
  input DAE.Pattern inPat;
  input tuple<HashTableStringToPath.HashTable,SourceInfo> inTpl;
  output DAE.Pattern pat=inPat;
  output tuple<HashTableStringToPath.HashTable,SourceInfo> outTpl=inTpl;
algorithm
  pat := matchcontinue (pat,inTpl)
    local
      HashTableStringToPath.HashTable ht;
      String id;
      SourceInfo info;
      tuple<HashTableStringToPath.HashTable,SourceInfo> tpl;
    case ((DAE.PAT_AS(id=id,pat=pat),(ht,info)))
      equation
        true = BaseHashTable.hasKey(id, ht);
        Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.PATTERNM_ALL_INFO),Error.META_UNUSED_AS_BINDING, {id}, info);
      then pat;
    case ((DAE.PAT_AS_FUNC_PTR(id=id,pat=pat),(ht,_)))
      equation
        true = BaseHashTable.hasKey(id, ht);
      then pat;
    else
      algorithm
        pat := simplifyPattern(inPat, 1);
      then pat;
  end matchcontinue;
end removePatternAsBinding;

protected function addLocalCref
"Use with Expression.traverseExpBottomUp to collect all CREF's that could be references to local
variables."
  input DAE.Exp inExp;
  input HashTableStringToPath.HashTable inHt;
  output DAE.Exp outExp;
  output HashTableStringToPath.HashTable outHt;
algorithm
  (outExp,outHt) := match (inExp,inHt)
    local
      DAE.Exp exp;
      HashTableStringToPath.HashTable ht;
      String name;
      list<DAE.MatchCase> cases;
      DAE.Pattern pat;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cr;
    case (exp as DAE.CREF(componentRef=cr),ht)
      equation
        ht = addLocalCrefHelper(cr,ht);
      then (exp,ht);
    case (exp as DAE.CALL(path=Absyn.IDENT(name), attr=DAE.CALL_ATTR(builtin=false)),ht)
      equation
        ht = BaseHashTable.add((name,Absyn.IDENT("")), ht);
      then (exp,ht);
    case (exp as DAE.PATTERN(pattern=pat),ht)
      equation
        (_,ht) = traversePattern(pat, addPatternAsBindings, ht);
      then (exp,ht);
    case (exp as DAE.MATCHEXPRESSION(cases=cases),ht)
      equation
        ht = addCasesLocalCref(cases,ht);
      then (exp,ht);
    else (inExp,inHt);
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
        (_,ht) = Expression.traverseExpBottomUp(exp, addLocalCref, ht);
        ht = addLocalCrefSubs(subs,ht);
      then ht;
    case (DAE.INDEX(exp)::subs,ht)
      equation
        (_,ht) = Expression.traverseExpBottomUp(exp, addLocalCref, ht);
        ht = addLocalCrefSubs(subs,ht);
      then ht;
    else iht;
  end match;
end addLocalCrefSubs;

protected function checkDefUse
"Use with Expression.traverseExpBottomUp to collect all CREF's that could be references to local
variables."
  input DAE.Exp inExp;
  input tuple<AvlSetString.Tree,AvlSetString.Tree,SourceInfo> inTpl;
  output DAE.Exp outExp;
  output tuple<AvlSetString.Tree,AvlSetString.Tree,SourceInfo> outTpl;
algorithm
  (outExp,outTpl) := matchcontinue (inExp,inTpl)
    local
      DAE.Exp exp;
      AvlSetString.Tree localsTree,useTree;
      String name;
      DAE.Pattern pat;
      DAE.ComponentRef cr;
      SourceInfo info;
      DAE.Type ty;
      tuple<AvlSetString.Tree,AvlSetString.Tree,SourceInfo> extra;
    case (DAE.CREF(componentRef=cr,ty=ty),extra as (localsTree,useTree,info))
      algorithm
        name := ComponentReference.crefFirstIdent(cr);
        if AvlSetString.hasKey(localsTree,name) and not AvlSetString.hasKey(useTree,name) then
          Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.PATTERNM_ALL_INFO),Error.META_UNUSED_ASSIGNMENT,{name},info);
          outExp := DAE.CREF(DAE.WILD(),ty);
        else
          outExp := inExp;
        end if;
      then (outExp,extra);
    case (DAE.PATTERN(pattern=pat),extra)
      equation
        (pat,extra) = traversePattern(pat, checkDefUsePattern, extra);
      then (DAE.PATTERN(pat),extra);
    else (inExp,inTpl);
  end matchcontinue;
end checkDefUse;

protected function checkDefUsePattern
"Replace unused assignments with wildcards"
  input DAE.Pattern inPat;
  input tuple<AvlSetString.Tree,AvlSetString.Tree,SourceInfo> inTpl;
  output DAE.Pattern outPat;
  output tuple<AvlSetString.Tree,AvlSetString.Tree,SourceInfo> outTpl=inTpl;
algorithm
  outPat := match (inPat,inTpl)
    local
      AvlSetString.Tree localsTree,useTree;
      String name;
      DAE.Pattern pat;
      SourceInfo info;
      DAE.Type ty;
      tuple<AvlSetString.Tree,AvlSetString.Tree,SourceInfo> extra;
    case ((DAE.PAT_AS(id=name,pat=pat),(localsTree,useTree,info)))
      equation
        if AvlSetString.hasKey(localsTree,name) and not AvlSetString.hasKey(useTree,name) then
          Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.PATTERNM_ALL_INFO),Error.META_UNUSED_AS_BINDING,{name},info);
        else
          pat = inPat;
        end if;
      then pat;
    case ((DAE.PAT_AS_FUNC_PTR(id=name,pat=pat),(localsTree,useTree,info)))
      equation
        if AvlSetString.hasKey(localsTree,name) and not AvlSetString.hasKey(useTree,name) then
          Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.PATTERNM_ALL_INFO),Error.META_UNUSED_AS_BINDING,{name},info);
        else
          pat = inPat;
        end if;
      then pat;
    else
      algorithm
        (pat,_) := simplifyPattern(inPat,1);
      then pat;
  end match;
end checkDefUsePattern;

protected function useLocalCref
"Use with Expression.traverseExpBottomUp to collect all CREF's that could be references to local
variables."
  input DAE.Exp inExp;
  input AvlSetString.Tree inTree;
  output DAE.Exp outExp;
  output AvlSetString.Tree outTree;
algorithm
  (outExp,outTree) := match (inExp,inTree)
    local
      DAE.Exp exp;
      AvlSetString.Tree tree;
      String name;
      list<DAE.MatchCase> cases;
      DAE.Pattern pat;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cr;
    case (exp as DAE.CREF(componentRef=cr),tree)
      equation
        tree = useLocalCrefHelper(cr,tree);
      then (exp,tree);
    case (exp as DAE.CALL(path=Absyn.IDENT(name), attr=DAE.CALL_ATTR(builtin=false)),tree)
      equation
        tree = AvlSetString.add(tree, name);
      then (exp,tree);
    case (exp as DAE.PATTERN(pattern=pat),tree)
      equation
        (_,tree) = traversePattern(pat, usePatternAsBindings, tree);
      then (exp,tree);
    case (exp as DAE.MATCHEXPRESSION(cases=cases),tree)
      equation
        tree = useCasesLocalCref(cases,tree);
      then (exp,tree);
    else (inExp,inTree);
  end match;
end useLocalCref;

protected function useLocalCrefHelper
  input DAE.ComponentRef cr;
  input AvlSetString.Tree inTree;
  output AvlSetString.Tree tree;
algorithm
  tree := match (cr,inTree)
    local
      String name;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cr2;
    case (DAE.CREF_IDENT(ident=name,subscriptLst=subs), _)
      equation
        tree = useLocalCrefSubs(subs,inTree);
      then AvlSetString.add(tree, name);
    case (DAE.CREF_QUAL(ident=name,subscriptLst=subs,componentRef=cr2),_)
      equation
        tree = useLocalCrefSubs(subs,inTree);
        tree = AvlSetString.add(tree, name);
      then useLocalCrefHelper(cr2,tree);
    else inTree;
  end match;
end useLocalCrefHelper;

protected function useLocalCrefSubs
  "Cref subscripts may also contain crefs"
  input list<DAE.Subscript> isubs;
  input AvlSetString.Tree inTree;
  output AvlSetString.Tree tree;
algorithm
  tree := match (isubs,inTree)
    local
      DAE.Exp exp;
      list<DAE.Subscript> subs;

    case ({},_) then inTree;
    case (DAE.SLICE(exp)::subs,_)
      equation
        (_,tree) = Expression.traverseExpBottomUp(exp, useLocalCref, inTree);
        tree = useLocalCrefSubs(subs,tree);
      then tree;
    case (DAE.INDEX(exp)::subs,_)
      equation
        (_,tree) = Expression.traverseExpBottomUp(exp, useLocalCref, inTree);
        tree = useLocalCrefSubs(subs,tree);
      then tree;
    else inTree;
  end match;
end useLocalCrefSubs;

protected function usePatternAsBindings
  "Traverse patterns and as-bindings as variable references in the hashtable"
  input DAE.Pattern inPat;
  input AvlSetString.Tree inTree;
  output DAE.Pattern outPat=inPat;
  output AvlSetString.Tree outTree;
algorithm
  outTree := matchcontinue inPat
    case DAE.PAT_AS()
      then AvlSetString.add(inTree, inPat.id);
    case DAE.PAT_AS_FUNC_PTR()
      then AvlSetString.add(inTree, inPat.id);
    else inTree;
  end matchcontinue;
end usePatternAsBindings;

protected function useCasesLocalCref
  input list<DAE.MatchCase> icases;
  input AvlSetString.Tree inTree;
  output AvlSetString.Tree tree;
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
  input DAE.Pattern inPat;
  input A extra;
  output DAE.Pattern outPat;
  output A outExtra=extra;
  replaceable type A subtypeof Any;
algorithm
  outPat := match inPat
    local
      Absyn.Path name;
      DAE.Pattern pat,pat2;
      list<tuple<DAE.Pattern, String, DAE.Type>> namedPatterns;
      list<DAE.Pattern> patterns;
    case DAE.PAT_CALL_NAMED(name, namedPatterns)
      equation
        namedPatterns = List.filterOnTrue(namedPatterns, filterEmptyPattern);
      then if listEmpty(namedPatterns) then DAE.PAT_WILD() else DAE.PAT_CALL_NAMED(name, namedPatterns);
    case DAE.PAT_CALL_TUPLE(patterns)
      then if allPatternsWild(patterns) then DAE.PAT_WILD() else inPat;
    case DAE.PAT_META_TUPLE(patterns)
      then if allPatternsWild(patterns) then DAE.PAT_WILD() else inPat;
    else inPat;
  end match;
end simplifyPattern;

protected function addPatternAsBindings
  "Traverse patterns and as-bindings as variable references in the hashtable"
  input DAE.Pattern inPat;
  input HashTableStringToPath.HashTable inHt;
  output DAE.Pattern pat=inPat;
  output HashTableStringToPath.HashTable ht=inHt;
algorithm
  ht := matchcontinue inPat
    local
      String id;
    case DAE.PAT_AS(id=id)
      then BaseHashTable.add((id,Absyn.IDENT("")), ht);
    case DAE.PAT_AS_FUNC_PTR(id=id)
      then BaseHashTable.add((id,Absyn.IDENT("")), ht);
    else ht;
  end matchcontinue;
end addPatternAsBindings;

public function traversePatternList<TypeA>
  input list<DAE.Pattern> inPatterns;
  input Func func;
  input TypeA inExtra;
  output list<DAE.Pattern> outPatterns={};
  output TypeA extra=inExtra;
  partial function Func
    input DAE.Pattern inPattern;
    input TypeA inExtra;
    output DAE.Pattern outPattern;
    output TypeA outExtra;
  end Func;
protected
  DAE.Pattern p;
algorithm
  for pat in inPatterns loop
    (p, extra) := traversePattern(pat, func, extra);
    outPatterns := p :: outPatterns;
  end for;
  outPatterns := Dangerous.listReverseInPlace(outPatterns);
end traversePatternList;

public function traversePattern<TypeA>
  input DAE.Pattern inPattern;
  input Func func;
  input TypeA inExtra;
  output DAE.Pattern outPattern;
  output TypeA extra=inExtra;
  partial function Func
    input DAE.Pattern inPattern;
    input TypeA inExtra;
    output DAE.Pattern outPattern;
    output TypeA outExtra;
  end Func;
algorithm
  (outPattern,extra) := match inPattern
    local
      TypeA a;
      DAE.Pattern pat,pat1,pat2;
      list<DAE.Pattern> pats;
      list<String> fields;
      list<DAE.Type> types, typeVars;
      String id,str;
      Option<DAE.Type> ty;
      Absyn.Path name;
      Integer index;
      list<tuple<DAE.Pattern,String,DAE.Type>> namedpats;
      Boolean knownSingleton;
      list<DAE.Var> fieldVars;
      DAE.Attributes attr;
    case DAE.PAT_AS(id,ty,attr,pat2)
      equation
        (pat2,extra) = traversePattern(pat2,func,extra);
        pat = DAE.PAT_AS(id,ty,attr,pat2);
        (pat,extra) = func(pat,extra);
      then (pat,extra);
    case DAE.PAT_AS_FUNC_PTR(id,pat2)
      equation
        (pat2,extra) = traversePattern(pat2,func,extra);
        pat = DAE.PAT_AS_FUNC_PTR(id,pat2);
        (pat,extra) = func(pat,extra);
      then (pat,extra);
    case DAE.PAT_CALL(name,index,pats,fieldVars,typeVars,knownSingleton)
      equation
        (pats,extra) = traversePatternList(pats, func, extra);
        pat = DAE.PAT_CALL(name,index,pats,fieldVars,typeVars,knownSingleton);
        (pat,extra) = func(pat,extra);
      then (pat,extra);
    case DAE.PAT_CALL_NAMED(name,namedpats)
      equation
        pats = List.map(namedpats,Util.tuple31);
        fields = List.map(namedpats,Util.tuple32);
        types = List.map(namedpats,Util.tuple33);
        (pats,extra) = traversePatternList(pats, func, extra);
        namedpats = List.thread3Tuple(pats, fields, types);
        pat = DAE.PAT_CALL_NAMED(name,namedpats);
        (pat,extra) = func(pat,extra);
      then (pat,extra);
    case DAE.PAT_CALL_TUPLE(pats)
      equation
        (pats,extra) = traversePatternList(pats, func, extra);
        pat = DAE.PAT_CALL_TUPLE(pats);
        (pat,extra) = func(pat,extra);
      then (pat,extra);
    case DAE.PAT_META_TUPLE(pats)
      equation
        (pats,extra) = traversePatternList(pats, func, extra);
        pat = DAE.PAT_META_TUPLE(pats);
        (pat,extra) = func(pat,extra);
      then (pat,extra);
    case DAE.PAT_CONS(pat1,pat2)
      equation
        (pat1,extra) = traversePattern(pat1,func,extra);
        (pat2,extra) = traversePattern(pat2,func,extra);
        pat = DAE.PAT_CONS(pat1,pat2);
        (pat,extra) = func(pat,extra);
      then (pat,extra);
    case (pat as DAE.PAT_CONSTANT())
      equation
        (pat,extra) = func(pat,extra);
      then (pat,extra);
    case DAE.PAT_SOME(pat1)
      equation
        (pat1,extra) = traversePattern(pat1,func,extra);
        pat = DAE.PAT_SOME(pat1);
        (pat,extra) = func(pat,extra);
      then (pat,extra);
    case (pat as DAE.PAT_WILD())
      equation
        (pat,extra) = func(pat,extra);
      then (pat,extra);
    case pat
      equation
        str = "Patternm.traversePattern failed: " + patternStr(pat);
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
      SourceInfo info;
      String name;
      list<DAE.Element> acc;
      HashTableStringToPath.HashTable unusedHt;

    case ({},_,acc,unusedHt) then (listReverse(acc),unusedHt);
    case (DAE.VAR(componentRef=DAE.CREF_IDENT(ident=name), source=DAE.SOURCE(info=info))::rest,_,acc,unusedHt)
      equation
        false = BaseHashTable.hasKey(name, ht);
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

protected function caseDeadCodeElimination
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
      SourceInfo info;
      list<DAE.MatchCase> acc;

    case (_,{},_,acc,false) then listReverse(acc);
    case (_,{},_,acc,true) then caseDeadCodeElimination(matchType,listReverse(acc),{},{},false);
    case (_,DAE.CASE(body={},result=NONE(),info=info)::{},_,acc,_)
      equation
        Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.PATTERNM_ALL_INFO), Error.META_DEAD_CODE, {"Last pattern is empty"}, info);
      then caseDeadCodeElimination(matchType,listReverse(acc),{},{},false);
        /* Tricky to get right; I'll try again later as it probably only gives marginal results anyway
    case (Absyn.MATCH(),DAE.CASE(patterns=pats,info=info)::rest,prevPatterns as _::_,acc,iter)
      equation
        oinfo = findOverlappingPattern(pats,acc);
        Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.PATTERNM_ALL_INFO), Error.META_DEAD_CODE, {"Unreachable pattern"}, info);
        Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.PATTERNM_ALL_INFO), Error.META_DEAD_CODE, {"Shadowing case"}, oinfo);
      then caseDeadCodeElimination(matchType,rest,pats::prevPatterns,acc,true);
      */
    case (Absyn.MATCHCONTINUE(),DAE.CASE(patterns=pats,body={},result=NONE(),info=info)::rest,_,acc,_)
      equation
        true = Flags.isSet(Flags.PATTERNM_DCE);
        Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.PATTERNM_ALL_INFO), Error.META_DEAD_CODE, {"Empty matchcontinue case"}, info);
        acc = caseDeadCodeElimination(matchType,rest,pats::prevPatterns,acc,true);
      then acc;
    case (_,(case_ as DAE.CASE(patterns=pats))::rest,_,acc,_) then caseDeadCodeElimination(matchType,rest,pats::prevPatterns,case_::acc,iter);
  end matchcontinue;
end caseDeadCodeElimination;

/*
protected function findOverlappingPattern
  input list<DAE.Pattern> patterns;
  input list<DAE.MatchCase> prevCases;
  output SourceInfo info;
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
      SourceInfo resultInfo, info;
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
  input SourceInfo info;
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
  input SourceInfo info;
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
        res = if not res then patternListsDoNotOverlap(ps1,ps2) else res;
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
    case (DAE.PAT_AS_FUNC_PTR(),_) then false;
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
        res = if res then Absyn.pathEqual(name1, name2) else res;
      then not res;

    case (DAE.PAT_CALL(name1,ix1,ps1,_,_),DAE.PAT_CALL(name2,ix2,ps2,_,_))
      equation
        res = ix1 == ix2;
        res = if res then Absyn.pathEqual(name1, name2) else res;
        res = if res then patternListsDoNotOverlap(ps1, ps2) else not res;
      then res;

    // TODO: PAT_CALLED_NAMED?

    // Constant patterns...
    case (DAE.PAT_CONSTANT(exp=e1),DAE.PAT_CONSTANT(exp=e2))
      then not Expression.expEqual(e1, e2);
    case (DAE.PAT_CONSTANT(),_) then true;
    case (_,DAE.PAT_CONSTANT()) then true;

    else false;
  end match;
end patternsDoNotOverlap;

protected function elabMatchCases
  input FCore.Cache cache;
  input FCore.Graph env;
  input list<Absyn.Case> cases;
  input list<DAE.Type> tys;
  input list<list<String>> inputAliases;
  input AvlSetString.Tree matchExpLocalTree;
  input Boolean impl;
  input Boolean performVectorization;
  input Prefix.Prefix pre;
  input SourceInfo info;
  output FCore.Cache outCache;
  output list<DAE.MatchCase> elabCases;
  output DAE.Type resType;
protected
  list<DAE.Exp> resExps;
  list<DAE.Type> resTypes,tysFixed;
algorithm
  tysFixed := List.map(tys, Types.getUniontypeIfMetarecordReplaceAllSubtypes);
  (outCache,elabCases,resExps,resTypes) := elabMatchCases2(cache,env,cases,tysFixed,inputAliases,matchExpLocalTree,impl,performVectorization,pre,{},{},{});
  (elabCases,resType) := fixCaseReturnTypes(elabCases,resExps,resTypes,info);
end elabMatchCases;

protected function elabMatchCases2
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Case> cases;
  input list<DAE.Type> tys;
  input list<list<String>> inputAliases;
  input AvlSetString.Tree matchExpLocalTree;
  input Boolean impl;
  input Boolean performVectorization;
  input Prefix.Prefix pre;
  input list<DAE.MatchCase> inAccCases "Order does matter";
  input list<DAE.Exp> inAccExps "Order does matter";
  input list<DAE.Type> inAccTypes "Order does not matter";
  output FCore.Cache outCache;
  output list<DAE.MatchCase> elabCases;
  output list<DAE.Exp> resExps;
  output list<DAE.Type> resTypes;
algorithm
  (outCache,elabCases,resExps,resTypes) :=
  match (inCache,inEnv,cases,inAccExps,inAccTypes)
    local
      Absyn.Case case_;
      list<Absyn.Case> rest;
      DAE.MatchCase elabCase;
      Option<DAE.Type> optType;
      Option<DAE.Exp> optExp;
      FCore.Cache cache;
      FCore.Graph env;
      list<DAE.Exp> accExps;
      list<DAE.Type> accTypes;

    case (cache,_,{},accExps,accTypes) then (cache,listReverse(inAccCases),listReverse(accExps),listReverse(accTypes));
    case (cache,env,case_::rest,accExps,accTypes)
      equation
        (cache,elabCase,optExp,optType) = elabMatchCase(cache,env,case_,tys,inputAliases,matchExpLocalTree,impl,performVectorization,pre);
        (cache,elabCases,accExps,accTypes) = elabMatchCases2(cache,env,rest,tys,inputAliases,matchExpLocalTree,impl,performVectorization,pre,elabCase::inAccCases,List.consOption(optExp,accExps),List.consOption(optType,accTypes));
      then (cache,elabCases,accExps,accTypes);
  end match;
end elabMatchCases2;

protected function elabMatchCase
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Case acase;
  input list<DAE.Type> tys;
  input list<list<String>> inputAliases;
  input AvlSetString.Tree matchExpLocalTree;
  input Boolean impl;
  input Boolean performVectorization;
  input Prefix.Prefix pre;
  output FCore.Cache outCache;
  output DAE.MatchCase elabCase;
  output Option<DAE.Exp> resExp;
  output Option<DAE.Type> resType;
algorithm
  (outCache,elabCase,resExp,resType) :=
  match (inCache,inEnv,acase)
    local
      Absyn.Exp result,pattern;
      list<Absyn.Exp> patterns;
      list<DAE.Pattern> elabPatterns, elabPatterns2;
      Option<Absyn.Exp> patternGuard;
      Option<DAE.Exp> elabResult,dPatternGuard;
      list<DAE.Element> caseDecls;
      Absyn.ClassPart cp;
      list<Absyn.AlgorithmItem> eqAlgs;
      list<SCode.Statement> algs;
      list<DAE.Statement> body;
      list<Absyn.ElementItem> decls;
      SourceInfo patternInfo,resultInfo,info;
      Integer len;
      FCore.Cache cache;
      FCore.Graph env;
      AvlSetString.Tree caseLocalTree,localsTree,useTree;

    case (cache,env,Absyn.CASE(pattern=pattern,patternGuard=patternGuard,patternInfo=patternInfo,localDecls=decls,classPart=cp,result=result,resultInfo=resultInfo,info=info))
      equation
        (cache,SOME((env,DAE.DAE(caseDecls),caseLocalTree))) = addLocalDecls(cache,env,decls,FCore.caseScopeName,impl,info);
        patterns = convertExpToPatterns(pattern);
        patterns = if listLength(tys)==1 then {pattern} else patterns;
        (cache,elabPatterns) = elabPatternTuple(cache, env, patterns, tys, patternInfo, pattern);
        checkPatternsDuplicateAsBindings(elabPatterns, patternInfo);
        // open a pattern type scope
        env = FGraph.openNewScope(env, SCode.NOT_ENCAPSULATED(), SOME(FCore.patternTypeScope), NONE());
        // and add the ID as pattern types to it
        (elabPatterns2, cache) = addPatternAliasesList(elabPatterns, inputAliases, cache, inEnv);
        (_, env) = traversePatternList(elabPatterns2, addEnvKnownAsBindings, env);
        eqAlgs = Static.fromEquationsToAlgAssignments(cp);
        algs = SCodeUtil.translateClassdefAlgorithmitems(eqAlgs);
        (cache,body) = InstSection.instStatements(cache, env, InnerOuter.emptyInstHierarchy, pre, ClassInf.FUNCTION(Absyn.IDENT("match"), false), algs, ElementSource.addElementSourceFileInfo(DAE.emptyElementSource,patternInfo), SCode.NON_INITIAL(), true, InstTypes.neverUnroll);
        (cache,body,elabResult,resultInfo,resType) = elabResultExp(cache,env,body,result,impl,performVectorization,pre,resultInfo);
        (cache,dPatternGuard) = elabPatternGuard(cache,env,patternGuard,impl,performVectorization,pre,patternInfo);
        localsTree = AvlSetString.join(matchExpLocalTree, caseLocalTree);
        // Start building the def-use chain bottom-up
        useTree = AvlSetString.new();
        (_,useTree) = Expression.traverseExpBottomUp(DAE.META_OPTION(elabResult), useLocalCref, useTree);
        (body,useTree) = statementListFindDeadStoreRemoveEmptyStatements(body,localsTree,useTree);
        (_,useTree) = Expression.traverseExpBottomUp(DAE.META_OPTION(dPatternGuard), useLocalCref, useTree);
        (elabPatterns,_) = traversePatternList(elabPatterns, checkDefUsePattern, (localsTree,useTree,patternInfo));
        // Do the same thing again, for fun and glory
        useTree = AvlSetString.new();
        (_,useTree) = Expression.traverseExpBottomUp(DAE.META_OPTION(elabResult), useLocalCref, useTree);
        (body,useTree) = statementListFindDeadStoreRemoveEmptyStatements(body,localsTree,useTree);
        (_,useTree) = Expression.traverseExpBottomUp(DAE.META_OPTION(dPatternGuard), useLocalCref, useTree);
        (elabPatterns,_) = traversePatternList(elabPatterns, checkDefUsePattern, (localsTree,useTree,patternInfo));
        elabCase = DAE.CASE(elabPatterns, dPatternGuard, caseDecls, body, elabResult, resultInfo, 0, info);
      then (cache,elabCase,elabResult,resType);

      // ELSE is the same as CASE, but without pattern
    case (cache,env,Absyn.ELSE(localDecls=decls,classPart=cp,result=result,resultInfo=resultInfo,info=info))
      equation
        // Needs to be same length as any other pattern for the simplification algorithms, etc to work properly
        len = listLength(tys);
        patterns = List.fill(Absyn.CREF(Absyn.WILD()),listLength(tys));
        pattern = if len == 1 then Absyn.CREF(Absyn.WILD()) else Absyn.TUPLE(patterns);
        (cache,elabCase,elabResult,resType) = elabMatchCase(cache, env, Absyn.CASE(pattern,NONE(),info,decls,cp,result,resultInfo,NONE(),info), tys, inputAliases, matchExpLocalTree, impl, performVectorization, pre);
      then (cache,elabCase,elabResult,resType);

  end match;
end elabMatchCase;

protected function elabResultExp
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Statement> inBody "Is input in case we want to optimize for tail-recursion";
  input Absyn.Exp exp;
  input Boolean impl;
  input Boolean performVectorization;
  input Prefix.Prefix pre;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output list<DAE.Statement> outBody;
  output Option<DAE.Exp> resExp;
  output SourceInfo resultInfo;
  output Option<DAE.Type> resType;
algorithm
  (outCache,outBody,resExp,resultInfo,resType) :=
  matchcontinue (inCache,inEnv,inBody,exp)
    local
      DAE.Exp elabExp;
      DAE.Properties prop;
      DAE.Type ty;
      FCore.Cache cache;
      FCore.Graph env;
      list<DAE.Statement> body;
      SourceInfo info;

    case (cache,_,body,Absyn.CALL(function_ = Absyn.CREF_IDENT("fail",{}), functionArgs = Absyn.FUNCTIONARGS({},{})))
      then (cache,body,NONE(),inInfo,NONE());

    case (cache,env,body,_)
      equation
        (cache,elabExp,prop) = Static.elabExp(cache,env,exp,impl,performVectorization,pre,inInfo);
        ty = Types.getPropType(prop);
        (elabExp,ty) = makeTupleFromMetaTuple(elabExp,ty);
        (body,elabExp,info) = elabResultExp2(not Flags.isSet(Flags.PATTERNM_MOVE_LAST_EXP),body,elabExp,inInfo);
      then (cache,body,SOME(elabExp),info,SOME(ty));
  end matchcontinue;
end elabResultExp;

protected function elabPatternGuard
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Option<Absyn.Exp> patternGuard;
  input Boolean impl;
  input Boolean performVectorization;
  input Prefix.Prefix pre;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output Option<DAE.Exp> outPatternGuard;
algorithm
  (outCache,outPatternGuard) :=
  matchcontinue (inCache,inEnv,patternGuard,impl,performVectorization,pre,inInfo)
    local
      Absyn.Exp exp;
      DAE.Exp elabExp;
      DAE.Properties prop;
      FCore.Cache cache;
      FCore.Graph env;
      SourceInfo info;
      String str;

    case (cache,_,NONE(),_,_,_,_)
      then (cache,NONE());

    case (cache,env,SOME(exp),_,_,_,info)
      equation
        (cache,elabExp,prop) = Static.elabExp(cache,env,exp,impl,performVectorization,pre,info);
        (elabExp,_) = Types.matchType(elabExp,Types.getPropType(prop),DAE.T_BOOL_DEFAULT,true);
      then (cache,SOME(elabExp));

    case (cache,env,SOME(exp),_,_,_,info)
      equation
        (_,_,prop) = Static.elabExp(cache,env,exp,impl,performVectorization,pre,info);
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
  input SourceInfo info;
  output list<DAE.Statement> outBody;
  output DAE.Exp outExp;
  output SourceInfo outInfo;
algorithm
  (outBody,outExp,outInfo) := matchcontinue (skipPhase,body,elabExp,info)
    local
      DAE.Exp elabCr1,elabCr2;
      list<DAE.Exp> elabCrs1,elabCrs2;
      list<DAE.Statement> b;
      DAE.Exp e;
      SourceInfo i;

    case (true,b,e,i) then (b,e,i);
    case (_,b,elabCr2 as DAE.CREF(),_)
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
  input SourceInfo info;
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
  input SourceInfo inInfo;
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
      SourceInfo resultInfo,info2;
      list<DAE.MatchCase> cases;
      list<DAE.Exp> exps;
      SourceInfo info;

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

public function traverseConstantPatternsHelper<T>
  input DAE.Exp inExp;
  input T inT;
  input FuncExpType func;
  output DAE.Exp outExp;
  output T outT=inT;
  partial function FuncExpType
    input DAE.Exp inExp;
    input T inTypeT;
    output DAE.Exp outExp;
    output T outT;
  end FuncExpType;
algorithm
  outExp := match inExp
    local
      list<DAE.MatchCase> cases, cases2;
      DAE.MatchCase case_;
      list<DAE.Pattern> patterns;
    case outExp as DAE.MATCHEXPRESSION(cases=cases)
      algorithm
        cases2 := {};
        for c in cases loop
          case_ := c;
          case_ := match case_
            case DAE.CASE()
              algorithm
               (patterns, outT) := traversePatternList(case_.patterns, function traverseConstantPatternsHelper2(func=func), outT);
               if not valueEq(case_.patterns, patterns) then
                 case_.patterns := patterns;
               end if;
              then case_;
          end match;
          cases2 := case_::cases2;
        end for;
        cases2 := Dangerous.listReverseInPlace(cases2);
        if not valueEq(cases,cases2) then
          outExp.cases := cases2;
        end if;
        (outExp,outT) := func(outExp,outT);
      then outExp;
    else
      algorithm
        (outExp,outT) := func(inExp,outT);
      then outExp;
  end match;
end traverseConstantPatternsHelper;

function traverseConstantPatternsHelper2<T>
  input DAE.Pattern inPattern;
  input T inExtra;
  input FuncExpType func;
  output DAE.Pattern outPattern;
  output T extra=inExtra;
  partial function FuncExpType
    input DAE.Exp inExp;
    input T inTypeT;
    output DAE.Exp outExp;
    output T outT;
  end FuncExpType;
algorithm
  outPattern := match inPattern
    local
      DAE.Exp exp;
    case outPattern as DAE.PAT_CONSTANT()
      algorithm
        (exp, extra) := func(outPattern.exp, extra);
        if not referenceEq(outPattern.exp, exp) then
          outPattern.exp := exp;
        end if;
      then outPattern;
    else inPattern;
  end match;
end traverseConstantPatternsHelper2;

public function traverseCases
  replaceable type A subtypeof Any;
  input list<DAE.MatchCase> inCases;
  input FuncExpType func;
  input A inA;
  output list<DAE.MatchCase> outCases;
  output A oa;
  partial function FuncExpType
    input DAE.Exp inExp;
    input A inTypeA;
    output DAE.Exp outExp;
    output A outA;
  end FuncExpType;
algorithm
  (outCases,oa) := match (inCases,func,inA)
    local
      list<DAE.Pattern> patterns;
      list<DAE.Element> decls;
      list<DAE.Statement> body,body1;
      Option<DAE.Exp> result,result1,patternGuard,patternGuard1;
      Integer jump;
      SourceInfo resultInfo,info;
      list<DAE.MatchCase> cases,cases1;
      A a;

    case ({},_,a) then ({},a);
    case (DAE.CASE(patterns,patternGuard,decls,body,result,resultInfo,jump,info)::cases,_,a)
      equation
        (body1,(_,a)) = DAEUtil.traverseDAEEquationsStmts(body,Expression.traverseSubexpressionsHelper,(func,a));
        (patternGuard1,a) = Expression.traverseExpOpt(patternGuard,func,a);
        (result1,a) = Expression.traverseExpOpt(result,func,a);
        (cases1,a) = traverseCases(cases,func,a);
        cases = if referenceEq(cases,cases1) and referenceEq(patternGuard,patternGuard1) and referenceEq(result,result1) and referenceEq(body,body1)
          then inCases
          else DAE.CASE(patterns,patternGuard1,decls,body1,result1,resultInfo,jump,info)::cases1;
      then (cases,a);
  end match;
end traverseCases;

public function traverseCasesTopDown<A>
  input list<DAE.MatchCase> inCases;
  input FuncExpType func;
  input A inA;
  output list<DAE.MatchCase> cases = {};
  output A a = inA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input A inTypeA;
    output DAE.Exp outExp;
    output Boolean cont;
    output A outA;
  end FuncExpType;
protected
  list<DAE.Pattern> patterns;
  list<DAE.Element> decls;
  list<DAE.Statement> body,body1;
  Option<DAE.Exp> result,result1,patternGuard,patternGuard1;
  Integer jump;
  SourceInfo resultInfo,info;
  tuple<FuncExpType,A> tpl;
algorithm
  for c in inCases loop
    DAE.CASE(patterns,patternGuard,decls,body,result,resultInfo,jump,info) := c;
    tpl := (func,a);
    (body1,(_,a)) := DAEUtil.traverseDAEEquationsStmts(body,Expression.traverseSubexpressionsTopDownHelper,tpl); // TODO: Enable with new tarball
    (patternGuard1,a) := Expression.traverseExpOptTopDown(patternGuard,func,a);
    (result1,a) := Expression.traverseExpOptTopDown(result,func,a);
    cases := DAE.CASE(patterns,patternGuard1,decls,body1,result1,resultInfo,jump,info)::cases;
  end for;
  cases := listReverse(cases); // TODO: in-place reverse?
end traverseCasesTopDown;

protected function filterEmptyPattern
  input tuple<DAE.Pattern,String,DAE.Type> tpl;
  output Boolean outB;
algorithm
  outB := match tpl
    case ((DAE.PAT_WILD(),_,_)) then false;
    else true;
  end match;
end filterEmptyPattern;

protected function addLocalDecls
"Adds local declarations to the environment and returns the DAE"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.ElementItem> els;
  input String scopeName;
  input Boolean impl;
  input SourceInfo info;
  output FCore.Cache outCache;
  output Option<tuple<FCore.Graph,DAE.DAElist,AvlSetString.Tree>> res;
algorithm
  (outCache,res) := matchcontinue (inCache,inEnv,els,scopeName,impl,info)
    local
      list<Absyn.ElementItem> ld;
      list<SCode.Element> ld2,ld3,ld4;
      list<tuple<SCode.Element, DAE.Mod>> ld_mod;
      DAE.DAElist dae1;
      FCore.Graph env2;
      ClassInf.State dummyFunc;
      String str;
      FCore.Cache cache;
      FCore.Graph env;
      Boolean b;
      AvlSetString.Tree declsTree;
      list<String> names;

    case (cache,env,{},_,_,_)
      equation
        declsTree = AvlSetString.new();
      then (cache,SOME((env,DAE.emptyDae,declsTree)));
    case (cache,env,ld,_,_,_)
      equation
        env2 = FGraph.openScope(env, SCode.NOT_ENCAPSULATED(), scopeName,NONE());

        // Tranform declarations such as Real x,y; to Real x; Real y;
        ld2 = SCodeUtil.translateEitemlist(ld, SCode.PROTECTED());

        // Filter out the components (just to be sure)
        true = List.applyAndFold1(ld2, boolAnd, SCode.isComponentWithDirection, Absyn.BIDIR(), true);
        ((cache,b)) = List.fold1(ld2, checkLocalShadowing, env, (cache,false));
        ld2 = if b then {} else ld2;

        // Transform the element list into a list of element,NOMOD
        ld_mod = InstUtil.addNomod(ld2);

        dummyFunc = ClassInf.FUNCTION(Absyn.IDENT("dummieFunc"), false);
        (cache,env2,_) = InstUtil.addComponentsToEnv(cache, env2,
          InnerOuter.emptyInstHierarchy, DAE.NOMOD(), Prefix.NOPRE(),
          dummyFunc, ld_mod, impl);
        (cache,env2,_,_,dae1,_,_,_,_,_) = Inst.instElementList(
          cache,env2, InnerOuter.emptyInstHierarchy, UnitAbsyn.noStore,
          DAE.NOMOD(), Prefix.NOPRE(), dummyFunc, ld_mod, {},
          impl, InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, Connect.emptySet, true);

        names = List.map(ld2, SCode.elementName);
        declsTree = AvlSetString.addList(AvlSetString.new(), names);

        res = if b then NONE() else SOME((env2,dae1,declsTree));
      then (cache,res);

    case (cache,_,ld,_,_,_)
      equation
        ld2 = SCodeUtil.translateEitemlist(ld, SCode.PROTECTED());
        (ld2 as _::_) = List.filterOnTrue(ld2, SCode.isNotComponent);
        str = stringDelimitList(List.map1(ld2, SCodeDump.unparseElementStr, SCodeDump.defaultOptions),", ");
        Error.addSourceMessage(Error.META_INVALID_LOCAL_ELEMENT,{str},info);
      then (cache,NONE());

    case (cache,_,ld,_,_,_)
      equation
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
  input FCore.Graph env;
  input tuple<FCore.Cache,Boolean> inTpl;
  output tuple<FCore.Cache,Boolean> outTpl=inTpl;
protected
  String name;
  FCore.Cache cache;
  Boolean b;
  SourceInfo info;
  SCode.Variability var;
algorithm
  SCode.COMPONENT(name=name, info=info) := elt;
  (cache,_) := inTpl;
  try
    (cache,DAE.ATTR(variability=var),_,_,_,_,_,_,_) := Lookup.lookupVarInternalIdent(cache,env,name);
    b := match var
      // Allow shadowing constants. Should be safe since they become values pretty much straight away.
      case SCode.CONST() then true;
      else false;
    end match;
  else
    b := true;
  end try;
  if not b then
    Error.addSourceMessage(Error.MATCH_SHADOWING,{name},info);
    outTpl := (cache,true);
  end if;
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
      SourceInfo resultInfo,info;
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
  outPatterns := List.toListWithPositions(inPatterns);
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
  (_,c1) := traversePattern(pat1,patternComplexity,0);
  (_,c2) := traversePattern(pat2,patternComplexity,0);
  // If both complexities are equal, keep the original ordering
  // If c1 is 0, and c2 is not 0 we move the left pattern to the end.
  // Else we move the cheaper pattern to the beginning
  greater := if c1 == c2 then i1 > i2 else (if c2 == 0 then false else (if c1 == 0 then true else c1 > c2));
end sortPatternsByComplexityWork;

protected function patternComplexity
  input DAE.Pattern inPat;
  input Integer inComplexity;
  output DAE.Pattern outPat=inPat;
  output Integer i=inComplexity;
algorithm
  i := match inPat
    local
      DAE.Pattern p;
      DAE.Exp exp;
    case DAE.PAT_CONSTANT(exp=exp)
      equation
        (_,i) = Expression.traverseExpBottomUp(exp,constantComplexity,i);
      then i;
    case DAE.PAT_CONS()
      then i+5;
    case DAE.PAT_CALL(knownSingleton=false)
      then i+5;
    case DAE.PAT_SOME()
      then i+5;
    else i;
  end match;
end patternComplexity;

protected function constantComplexity
  input DAE.Exp inExp;
  input Integer ii;
  output DAE.Exp outExp;
  output Integer oi;
algorithm
  (outExp,oi) := match (inExp,ii)
     local
       DAE.Exp e;
       String str;
       Integer i;
     case (e as DAE.SCONST(str),i) then (e,i+5+stringLength(str));
     case (e as DAE.ICONST(_),i) then (e,i+1);
     case (e as DAE.BCONST(_),i) then (e,i+1);
     case (e as DAE.RCONST(_),i) then (e,i+2);
     case (e,i) then (e,i+5); // lists and such; add a little something in addition to its members....
  end match;
end constantComplexity;

protected function addEnvKnownAsBindings
  input DAE.Pattern inPat;
  input FCore.Graph inEnv;
  output DAE.Pattern pat=inPat;
  output FCore.Graph env=inEnv;
algorithm
  env := match pat
    case DAE.PAT_AS()
      then addEnvKnownAsBindings2(pat,env,findFirstNonAsPattern(pat.pat));
    else env;
  end match;
end addEnvKnownAsBindings;

protected function addEnvKnownAsBindings2
  input DAE.Pattern inPat;
  input FCore.Graph inEnv;
  input DAE.Pattern firstPattern;
  output FCore.Graph env=inEnv;
algorithm
  env := match (inPat,firstPattern)
    local
      Absyn.Path name,path;
      String id,scope;
      DAE.Type ty;
      DAE.Pattern pat;
      list<DAE.Var> fields;
      Integer index;
      Boolean knownSingleton;
      DAE.Attributes attr;
      list<DAE.Type> typeVars;
    case (DAE.PAT_AS(id=id,attr=attr),DAE.PAT_CALL(index=index,typeVars=typeVars,fields=fields,knownSingleton=knownSingleton,name=name))
      equation
         path = Absyn.stripLast(name);
         ty = DAE.T_METARECORD(name,path,typeVars,index,fields,knownSingleton);
         env = FGraph.mkComponentNode(env, DAE.TYPES_VAR(id,attr,ty,DAE.UNBOUND(),NONE()), SCode.COMPONENT(id,SCode.defaultPrefixes,SCode.defaultVarAttr,Absyn.TPATH(name,NONE()),SCode.NOMOD(),SCode.noComment,NONE(),Absyn.dummyInfo), DAE.NOMOD(), FCore.VAR_DAE(), FGraph.empty());
      then env;
    else env;
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

protected function addPatternAliasesList
  input list<DAE.Pattern> inPatterns;
  input list<list<String>> inAliases;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  output list<DAE.Pattern> outPatterns = {};
  output FCore.Cache outCache = inCache;
protected
  list<String> aliases;
  list<list<String>> rest_aliases = inAliases;
algorithm
  for pat in inPatterns loop
    aliases :: rest_aliases := rest_aliases;
    (pat, outCache) := addPatternAliases(pat, aliases, outCache, inEnv);
    outPatterns := pat :: outPatterns;
  end for;

  outPatterns := listReverse(outPatterns);
end addPatternAliasesList;

protected function addPatternAliases
  input DAE.Pattern inPattern;
  input list<String> inAliases;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  output DAE.Pattern pat = inPattern;
  output FCore.Cache outCache = inCache;
protected
  DAE.Attributes attr;
algorithm
  for alias in inAliases loop
    (outCache, DAE.TYPES_VAR(attributes = attr), _, _, _, _) :=
      Lookup.lookupIdent(outCache, inEnv, alias);
    pat := DAE.PAT_AS(alias, NONE(), attr, pat);
  end for;
end addPatternAliases;

protected function addAliasesToEnv
  input FCore.Graph inEnv;
  input list<DAE.Type> inTypes;
  input list<list<String>> inAliases;
  input SourceInfo info;
  output FCore.Graph outEnv;
algorithm
  outEnv := match (inEnv,inTypes,inAliases,info)
    local
      list<DAE.Type> tys;
      list<list<String>> aliases;
      list<String> rest;
      String id;
      FCore.Graph env;
      DAE.Type ty;
      DAE.Attributes attr;
    case (_,{},{},_) then inEnv;
    case (_,_::tys,{}::aliases,_) then addAliasesToEnv(inEnv,tys,aliases,info);
    case (env,ty::_,(id::rest)::aliases,_)
      equation
        attr = DAE.dummyAttrInput;
        env = FGraph.mkComponentNode(env, DAE.TYPES_VAR(id,attr,ty,DAE.UNBOUND(),NONE()), SCode.COMPONENT(id,SCode.defaultPrefixes,SCode.defaultVarAttr,Absyn.TPATH(Absyn.IDENT("$dummy"),NONE()),SCode.NOMOD(),SCode.noComment,NONE(),info), DAE.NOMOD(), FCore.VAR_DAE(), FGraph.empty());
      then addAliasesToEnv(env,inTypes,rest::aliases,info);
  end match;
end addAliasesToEnv;

protected function statementListFindDeadStoreRemoveEmptyStatements
  input list<DAE.Statement> inBody;
  input AvlSetString.Tree localsTree;
  input AvlSetString.Tree inUseTree;
  output list<DAE.Statement> body;
  output AvlSetString.Tree useTree;
algorithm
  (body,useTree) := List.map1Fold(listReverse(inBody),statementFindDeadStore,localsTree,inUseTree);
  body := List.select(body,isNotDummyStatement);
  body := listReverse(body);
end statementListFindDeadStoreRemoveEmptyStatements;

protected function statementFindDeadStore
  input DAE.Statement inStatement;
  input AvlSetString.Tree localsTree;
  input AvlSetString.Tree inUseTree;
  output DAE.Statement outStatement;
  output AvlSetString.Tree useTree;
algorithm
  (outStatement,useTree) := match inStatement
    local
      AvlSetString.Tree elseTree;
      list<DAE.Statement> body;
      DAE.ComponentRef cr;
      DAE.Exp exp,lhs,cond,msg,level;
      list<DAE.Exp> exps;
      DAE.Else else_;
      DAE.Type ty;
      SourceInfo info;
      Boolean b;
      String id;
      Integer index;
      DAE.ElementSource source;

    case DAE.STMT_ASSIGN(type_=ty,exp1=lhs,exp=exp,source=source as DAE.SOURCE(info=info))
      equation
        (_,useTree) = Expression.traverseExpBottomUp(exp, useLocalCref, inUseTree);
        lhs = Expression.traverseExpBottomUp(lhs, checkDefUse, (localsTree,useTree,info));
        outStatement = Algorithm.makeAssignmentNoTypeCheck(ty,lhs,exp,source);
      then (outStatement,useTree);

    case DAE.STMT_TUPLE_ASSIGN(type_=ty,expExpLst=exps,exp=exp,source=source as DAE.SOURCE(info=info))
      equation
        (_,useTree) = Expression.traverseExpBottomUp(exp, useLocalCref, inUseTree);
        (DAE.TUPLE(exps),_) = Expression.traverseExpBottomUp(DAE.TUPLE(exps), checkDefUse, (localsTree,useTree,info));
        outStatement = Algorithm.makeTupleAssignmentNoTypeCheck(ty,exps,exp,source);
      then (outStatement,useTree);

    case DAE.STMT_ASSIGN_ARR(type_=ty,lhs=lhs,exp=exp,source=source as DAE.SOURCE(info=info))
      equation
        (_,useTree) = Expression.traverseExpBottomUp(exp, useLocalCref, inUseTree);
        lhs = Expression.traverseExpBottomUp(lhs, checkDefUse, (localsTree,useTree,info));
        outStatement = Algorithm.makeArrayAssignmentNoTypeCheck(ty,lhs,exp,source);
      then (outStatement,useTree);

    case DAE.STMT_IF(exp=exp,statementLst=body,else_=else_,source=source)
      equation
        (else_,elseTree) = elseFindDeadStore(else_, localsTree, inUseTree);
        (body,useTree) = statementListFindDeadStoreRemoveEmptyStatements(body,localsTree,inUseTree);
        (_,useTree) = Expression.traverseExpBottomUp(exp, useLocalCref, useTree);
        useTree = AvlSetString.join(useTree,elseTree);
      then (DAE.STMT_IF(exp,body,else_,source),useTree);

    case DAE.STMT_FOR(ty,b,id,index,exp,body,source)
      equation
        // Loops repeat, so check for usage in the whole loop before removing any dead stores.
        ErrorExt.setCheckpoint(getInstanceName());
        (_, useTree) = List.map1Fold(body, statementFindDeadStore, localsTree, inUseTree);
        ErrorExt.rollBack(getInstanceName());
        (body,useTree) = statementListFindDeadStoreRemoveEmptyStatements(body,localsTree, useTree);
        (_,useTree) = Expression.traverseExpBottomUp(exp, useLocalCref, useTree);
        // TODO: We should remove ident from the use-tree in case of shadowing... But our avlTree cannot delete
        useTree = AvlSetString.join(useTree,inUseTree);
      then (DAE.STMT_FOR(ty,b,id,index,exp,body,source),useTree);

    case DAE.STMT_WHILE(exp=exp,statementLst=body,source=source)
      equation
        // Loops repeat, so check for usage in the whole loop before removing any dead stores.
        ErrorExt.setCheckpoint(getInstanceName());
        (_, useTree) = List.map1Fold(body, statementFindDeadStore, localsTree, inUseTree);
        ErrorExt.rollBack(getInstanceName());
        (body,useTree) = statementListFindDeadStoreRemoveEmptyStatements(body, localsTree, useTree);
        (_,useTree) = Expression.traverseExpBottomUp(exp, useLocalCref, useTree);
        // The loop might not be entered just like if. The following should not remove all previous uses:
        // while false loop
        //   return;
        // end while;
        useTree = AvlSetString.join(useTree,inUseTree);
      then (DAE.STMT_WHILE(exp,body,source),useTree);

    // No PARFOR in MetaModelica
    case DAE.STMT_PARFOR() then fail();

    case DAE.STMT_ASSERT(cond=cond,msg=msg,level=level)
      equation
        (_,useTree) = Expression.traverseExpBottomUp(cond, useLocalCref, inUseTree);
        (_,useTree) = Expression.traverseExpBottomUp(msg, useLocalCref, useTree);
        (_,useTree) = Expression.traverseExpBottomUp(level, useLocalCref, useTree);
      then (inStatement,useTree);

    // Reset the tree; we do not execute anything after this
    case DAE.STMT_TERMINATE(msg=exp)
      equation
        (_,useTree) = Expression.traverseExpBottomUp(exp, useLocalCref, AvlSetString.new());
      then (inStatement,useTree);

    // No when or reinit in functions
    case DAE.STMT_WHEN() then fail();
    case DAE.STMT_REINIT() then fail();

    // There is no use after this one, so we can reset the tree
    case DAE.STMT_NORETCALL(exp=DAE.CALL(path=Absyn.IDENT("fail")))
      then (inStatement,AvlSetString.new());

    case DAE.STMT_RETURN() then (inStatement,AvlSetString.new());

    case DAE.STMT_NORETCALL(exp=exp)
      equation
        (_,useTree) = Expression.traverseExpBottomUp(exp, useLocalCref, inUseTree);
      then (inStatement,useTree);

    case DAE.STMT_BREAK() then (inStatement,inUseTree);
    case DAE.STMT_CONTINUE() then (inStatement,inUseTree);
    case DAE.STMT_ARRAY_INIT() then (inStatement,inUseTree);
    case DAE.STMT_FAILURE(body=body,source=source)
      equation
        (body,useTree) = statementListFindDeadStoreRemoveEmptyStatements(body,localsTree,inUseTree);
      then (DAE.STMT_FAILURE(body,source),useTree);
  end match;
end statementFindDeadStore;

protected function elseFindDeadStore
  input DAE.Else inElse;
  input AvlSetString.Tree localsTree;
  input AvlSetString.Tree inUseTree;
  output DAE.Else outElse;
  output AvlSetString.Tree useTree;
algorithm
  (outElse,useTree) := match (inElse,localsTree,inUseTree)
    local
      DAE.Exp exp;
      list<DAE.Statement> body;
      DAE.Else else_;
      AvlSetString.Tree elseTree;
    case (DAE.NOELSE(),_,_) then (inElse,inUseTree);
    case (DAE.ELSEIF(exp,body,else_),_,_)
      equation
        (body,useTree) = statementListFindDeadStoreRemoveEmptyStatements(body,localsTree,inUseTree);
        (_,useTree) = Expression.traverseExpBottomUp(exp, useLocalCref, useTree);
        (else_,elseTree) = elseFindDeadStore(else_, localsTree, inUseTree);
        useTree = AvlSetString.join(useTree,elseTree);
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
  Error.assertionOrAddSourceMessage(b or not Flags.isSet(Flags.PATTERNM_ALL_INFO),Error.META_DEAD_CODE,{"Statement optimised away"},ElementSource.getElementSourceFileInfo(Algorithm.getStatementSource(statement)));
end isNotDummyStatement;

protected function makeTupleFromMetaTuple
  input DAE.Exp inExp;
  input DAE.Type inType;
  output DAE.Exp exp;
  output DAE.Type ty;
algorithm
  (exp,ty) := match (inExp,inType)
    local
      list<DAE.Exp> exps;
      list<DAE.Type> tys,tys2;
      list<Absyn.Path> source;
    case (DAE.META_TUPLE(exps),DAE.T_METATUPLE(types=tys))
      equation
        tys2 = List.map(tys, Types.unboxedType);
        (exps,tys2) = Types.matchTypeTuple(exps, tys, tys2, false);
      then (DAE.TUPLE(exps),DAE.T_TUPLE(tys2,NONE()));
    else (inExp,inType);
  end match;
end makeTupleFromMetaTuple;

protected function convertExpToPatterns
  "Converts an expression to a list of patterns. If the expression is a tuple
   then the contents of the tuple are returned, otherwise the expression itself
   is returned as a list."
  input Absyn.Exp inExp;
  output list<Absyn.Exp> outInputs;
algorithm
  outInputs := match inExp
    case Absyn.TUPLE() then inExp.expressions;
    else {inExp};
  end match;
end convertExpToPatterns;

annotation(__OpenModelica_Interface="frontend");
end Patternm;
