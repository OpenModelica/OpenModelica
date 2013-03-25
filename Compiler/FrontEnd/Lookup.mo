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

encapsulated package Lookup
" file:        Lookup.mo
  package:     Lookup
  description: Scoping rules

  RCS: $Id$

  This module is responsible for the lookup mechanism in Modelica.
  It is responsible for looking up classes, variables, etc. in the
  environment Env by following the lookup rules.
  The most important functions are:
  lookupClass - to find a class
  lookupType - to find types (e.g. functions, types, etc.)
  lookupVar - to find a variable in the instance hierarchy."

public import Absyn;
public import ClassInf;
public import DAE;
public import Env;
public import HashTableStringToPath;
public import SCode;
public import Util;
public import Types;

protected import BaseHashTable;
protected import Builtin;
protected import ComponentReference;
protected import Config;
protected import Connect;
protected import ConnectionGraph;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import Inst;
protected import InstExtends;
protected import InnerOuter;
protected import List;
protected import Mod;
protected import Prefix;
protected import Static;
protected import UnitAbsyn;
protected import SCodeDump;

public uniontype SearchStrategy
  record SEARCH_LOCAL_ONLY
    "this one searches only in the local scope, it won't find *time* variable"
  end SEARCH_LOCAL_ONLY;
  record SEARCH_ALSO_BUILTIN
    "this one searches also in the builtin scope, it will find *time* variable"
  end SEARCH_ALSO_BUILTIN;
end SearchStrategy;

public uniontype SplicedExpData
  record SPLICEDEXPDATA "data for 'spliced expression' (typically a component reference) returned in lookupVar"
    Option<DAE.Exp> splicedExp "the spliced expression";
    Types.Type identType "the type of the variable without subscripts, needed for vectorization";
  end SPLICEDEXPDATA;
end SplicedExpData;

/*   - Lookup functions

  These functions look up class and variable names in the environment.
  The names are supplied as a path, and if the path is qualified, a
  variable named as the first part of the path is searched for, and the
  name is looked for in it.

 */

public function lookupType
" This function finds a specified type in the environment.
  If it finds a function instead, this will be implicitly instantiated
  and lookup will start over.
"
  input Env.Cache inCache;
  input Env.Env inEnv "environment to search in";
  input Absyn.Path inPath "type to look for";
  input Option<Absyn.Info> msg "Messaage flag, SOME() outputs lookup error messages";
  output Env.Cache outCache;
  output DAE.Type outType "the found type";
  output Env.Env outEnv "The environment the type was found in";
algorithm
  (outCache,outType,outEnv):=
  matchcontinue (inCache,inEnv,inPath,msg)
    local
      DAE.Type t;
      list<Env.Frame> env_1,env,env_2;
      Absyn.Path path;
      SCode.Element c;
      String classname,scope;
      Env.Cache cache;
      Absyn.Info info;

    // Special handling for Connections.isRoot
    case (cache,env,Absyn.QUALIFIED("Connections", Absyn.IDENT("isRoot")),_)
      equation
        t = DAE.T_FUNCTION({("x", DAE.T_ANYTYPE_DEFAULT, DAE.C_VAR(), NONE())}, DAE.T_BOOL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT, DAE.emptyTypeSource);
      then
        (cache, t, env);

    // Special handling for MultiBody 3.x rooted() operator
    case (cache,env,Absyn.IDENT("rooted"),_)
      equation
        t = DAE.T_FUNCTION({("x", DAE.T_ANYTYPE_DEFAULT, DAE.C_VAR(), NONE())}, DAE.T_BOOL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT, DAE.emptyTypeSource);
      then
        (cache, t, env);

      // For simple names
    case (cache,env,(path as Absyn.IDENT(name = _)),_)
      equation
        (cache,t,env_1) = lookupTypeInEnv(cache,env,path);
      then
        (cache,t,env_1);

      // Special classes (function, record, metarecord, external object)
    case (cache,env,path,_)
      equation
        (cache,c,env_1) = lookupClass(cache,env,path,false);
        (cache,t,env_2) = lookupType2(cache,env_1,path,c);
      then
        (cache,t,env_2);

       // Error for type not found
    case (cache,env,path,SOME(info))
      equation
        classname = Absyn.pathString(path);
        classname = stringAppend(classname," (its type) ");
        scope = Env.printEnvPathStr(env);
        Error.addSourceMessage(Error.LOOKUP_ERROR, {classname,scope}, info);
      then
        fail();
  end matchcontinue;
end lookupType;

protected function lookupType2
" This function handles the case when we looked up a class, but need to
check if it is function, record, metarecord, etc.
"
  input Env.Cache inCache;
  input Env.Env inEnv "environment to search in";
  input Absyn.Path inPath "type to look for";
  input SCode.Element inClass "the class lookupType found";
  output Env.Cache outCache;
  output DAE.Type outType "the found type";
  output Env.Env outEnv "The environment the type was found in";
algorithm
  (outCache,outType,outEnv) := matchcontinue (inCache,inEnv,inPath,inClass)
    local
      DAE.Type t;
      list<Env.Frame> env_1,env_2,env_3;
      Absyn.Path path;
      SCode.Element c;
      String id;
      Env.Cache cache;
      SCode.Restriction r;
      list<Types.Var> types;
      list<String> names;
      ClassInf.State ci_state;
      SCode.Encapsulated encflag;
      DAE.TypeSource ts;

    // Record constructors
    case (cache,env_1,path,c as SCode.CLASS(name=id,restriction=SCode.R_RECORD()))
      equation
        (cache,env_1,t) = buildRecordType(cache,env_1,c);
      then
        (cache,t,env_1);

    // lookup of an enumeration type
    case (cache,env_1,path,c as SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=r as SCode.R_ENUMERATION()))
      equation
        env_2 = Env.openScope(env_1, encflag, SOME(id), SOME(Env.CLASS_SCOPE()));
        ci_state = ClassInf.start(r, Env.getEnvName(env_2));
        // Debug.fprintln(Flags.INST_TRACE, "LOOKUP TYPE ICD: " +& Env.printEnvPathStr(env_1) +& " path:" +& Absyn.pathString(path));
        (cache,env_3,_,_,_,_,_,types,_,_,_,_) =
        Inst.instClassIn(
          cache,env_2,InnerOuter.emptyInstHierarchy,UnitAbsyn.noStore,
          DAE.NOMOD(), Prefix.NOPRE(),
          ci_state, c, SCode.PUBLIC(), {}, false, Inst.INNER_CALL(),
          ConnectionGraph.EMPTY, Connect.emptySet, NONE());
        // build names
        (_,names) = SCode.getClassComponents(c);
        // generate the enumeration type
        ts = Types.mkTypeSource(SOME(path));
        t = DAE.T_ENUMERATION(NONE(), path, names, types, {}, ts);
        env_3 = Env.extendFrameT(env_3, id, t);
      then
        (cache,t,env_3);

    // Metamodelica extension, Uniontypes
    case (cache,env_1,path,c as SCode.CLASS(restriction=SCode.R_METARECORD(index=_)))
      equation
        (cache,env_2,t) = buildMetaRecordType(cache,env_1,c);
      then
        (cache,t,env_2);

    // Classes that are external objects. Implicitly instantiate to get type
    case (cache,env_1,path,c)
      equation
        // Debug.fprintln(Flags.INST_TRACE, "LOOKUP TYPE ICD: " +& Env.printEnvPathStr(env_1) +& " path:" +& Absyn.pathString(path));
        true = Inst.classIsExternalObject(c);
        (cache,_::env_1,_,_,_,_,_,_,_,_) = Inst.instClass(
          cache,env_1,InnerOuter.emptyInstHierarchy, UnitAbsyn.noStore,
          DAE.NOMOD(), Prefix.NOPRE(), c,
          {}, false, Inst.TOP_CALL(), ConnectionGraph.EMPTY, Connect.emptySet);
        SCode.CLASS(name=id) = c;
        (cache,t,env_2) = lookupTypeInEnv(cache,env_1,Absyn.IDENT(id));
      then
        (cache,t,env_2);

    // If we find a class definition that is a function or external function
    // with the same name then we implicitly instantiate that function, look
    // up the type.
    case (cache,env_1,path,c as SCode.CLASS(name = id,restriction=SCode.R_FUNCTION(_)))
      equation
        // Debug.fprintln(Flags.INST_TRACE, "LOOKUP TYPE ICD: " +& Env.printEnvPathStr(env_1) +& " path:" +& Absyn.pathString(path));
        (cache,env_2,_) =
        Inst.implicitFunctionTypeInstantiation(cache,env_1,InnerOuter.emptyInstHierarchy,c);
        (cache,t,env_3) = lookupTypeInEnv(cache,env_2,Absyn.IDENT(id));
      then
        (cache,t,env_3);
  end matchcontinue;
end lookupType2;

public function lookupMetarecordsRecursive
"Takes a list of paths to Uniontypes. Use this list to create a list of T_METARECORD.
The function is guarded against recursive definitions by accumulating all paths it
starts to traverse."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Path> inUniontypePaths;
  output Env.Cache outCache;
  output list<DAE.Type> outMetarecordTypes;
algorithm
  (outCache,_,outMetarecordTypes) := lookupMetarecordsRecursive2(inCache, inEnv, inUniontypePaths, HashTableStringToPath.emptyHashTable(), {});
end lookupMetarecordsRecursive;

protected function lookupMetarecordsRecursive2
"Takes a list of paths to Uniontypes. Use this list to create a list of T_METARECORD.
The function is guarded against recursive definitions by accumulating all paths it
starts to traverse."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Path> inUniontypePaths;
  input HashTableStringToPath.HashTable inHt;
  input list<DAE.Type> inAcc;
  output Env.Cache outCache;
  output HashTableStringToPath.HashTable outHt;
  output list<DAE.Type> outMetarecordTypes;
algorithm
  (outCache,outHt,outMetarecordTypes) := match (inCache, inEnv, inUniontypePaths, inHt, inAcc)
    local
      Env.Cache cache;
      Env.Env env;
      Absyn.Path first;
      list<Absyn.Path>  rest;
      HashTableStringToPath.HashTable ht;
      list<DAE.Type> acc;

    case (cache, _, {}, ht, acc) then (cache, ht, acc);
    case (cache, env, first::rest, ht, acc)
      equation
        (cache,ht,acc) = lookupMetarecordsRecursive3(cache, env, first, Absyn.pathString(first), ht, acc);
        (cache,ht,acc) = lookupMetarecordsRecursive2(cache, env, rest, ht, acc);
      then (cache, ht, acc);
  end match;
end lookupMetarecordsRecursive2;

protected function lookupMetarecordsRecursive3
"Takes a list of paths to Uniontypes. Use this list to create a list of T_METARECORD.
The function is guarded against recursive definitions by accumulating all paths it
starts to traverse."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path path;
  input String str;
  input HashTableStringToPath.HashTable inHt;
  input list<DAE.Type> inAcc;
  output Env.Cache outCache;
  output HashTableStringToPath.HashTable outHt;
  output list<DAE.Type> outMetarecordTypes;
algorithm
  (outCache,outHt,outMetarecordTypes) := matchcontinue (inCache, inEnv, path, str, inHt, inAcc)
    local
      Env.Cache cache;
      Env.Env env;
      list<Absyn.Path> uniontypePaths;
      list<DAE.Type>    uniontypeTypes;
      DAE.Type ty;
      list<DAE.Type> acc;
      HashTableStringToPath.HashTable ht;

    case (cache, env, _, _, ht, acc)
      equation
        _ = BaseHashTable.get(str, ht);
      then (cache, ht, acc);
    case (cache, env, _, _, ht, acc)
      equation
        ht = BaseHashTable.add((str,path),ht);
        (cache, ty, _) = lookupType(cache, env, path, SOME(Absyn.dummyInfo));
        acc = ty::acc;
        uniontypeTypes = Types.getAllInnerTypesOfType(ty, Types.uniontypeFilter);
        uniontypePaths = List.flatten(List.map(uniontypeTypes, Types.getUniontypePaths));
        (cache, ht, acc) = lookupMetarecordsRecursive2(cache, env, uniontypePaths, ht, acc);
      then (cache,ht,acc);
  end matchcontinue;
end lookupMetarecordsRecursive3;

public function isPrimitive
"function: isPrimitive
  author: PA

  Returns true if classname is any of the builtin classes:
  Real, Integer, String, Boolean
"
  input Absyn.Path inPath;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inPath)
    case(Absyn.FULLYQUALIFIED(inPath)) then isPrimitive(inPath);
    case (Absyn.IDENT(name = "Integer")) then true;
    case (Absyn.IDENT(name = "Real")) then true;
    case (Absyn.IDENT(name = "Boolean")) then true;
    case (Absyn.IDENT(name = "String")) then true;
    case (_) then false;
  end matchcontinue;
end isPrimitive;

public function lookupClass "Tries to find a specified class in an environment"
  input Env.Cache inCache;
  input Env.Env inEnv "Where to look";
  input Absyn.Path inPath "Path of the class to look for";
  input Boolean msg "Controls error messages";
  output Env.Cache outCache;
  output SCode.Element outClass;
  output Env.Env outEnv;
algorithm
  /*
  (Env.CLASS(cls = outClass, env = outEnv), _, _) :=
    FLookup.lookupClassName(inPath, inEnv, Absyn.dummyInfo);
  outCache := inCache;
  */
  // print("Lookup C1: " +& Absyn.pathString(inPath) +& " env: " +& Env.printEnvPathStr(inEnv) +& " msg: " +& boolString(msg) +& "\n");
  (outCache,outClass,outEnv,_) := lookupClass1(inCache, inEnv, inPath, {}, Util.makeStatefulBoolean(false), msg);
  // outEnv := selectUpdatedEnv(inEnv, outEnv);
  // print("Lookup C2: " +& " outenv: " +& Env.printEnvPathStr(outEnv) +& "\n");
end lookupClass;

protected function lookupClass1 "help function to lookupClass, does all the work."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath "The path of the class to lookup";
  input list<Env.Frame> inPrevFrames "Environment in reverse order. Contains frames we previously had in the scope. Will be looked up instead of the environment in order to avoid infinite recursion.";
  input Util.StatefulBoolean inState "If true, we have found a class. If the path was qualified, we should no longer look in previous frames of the environment";
  input Boolean msg "Print error messages";
  output Env.Cache outCache;
  output SCode.Element outClass;
  output Env.Env outEnv "The environment in which the class was found (not the environment inside the class)";
  output list<Env.Frame> outPrevFrames;
algorithm
  (outCache,outClass,outEnv,outPrevFrames) := matchcontinue (inCache,inEnv,inPath,inPrevFrames,inState,msg)
    local
      String id,scope;
    case (_,_,_,_,_,_)
      equation
        (outCache,outClass,outEnv,outPrevFrames) = lookupClass2(inCache,inEnv,inPath,inPrevFrames,inState,false);
      then (outCache,outClass,outEnv,outPrevFrames);
    case (_,_,_,_,_,true)
      equation
        id = Absyn.pathString(inPath);
        scope = Env.printEnvPathStr(inEnv);
        Error.addMessage(Error.LOOKUP_ERROR, {id,scope});
      then fail();
  end matchcontinue;
end lookupClass1;

protected function lookupClass2 "help function to lookupClass, does all the work."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath "The path of the class to lookup";
  input list<Env.Frame> inPrevFrames "Environment in reverse order. Contains frames we previously had in the scope. Will be looked up instead of the environment in order to avoid infinite recursion.";
  input Util.StatefulBoolean inState "If true, we have found a class. If the path was qualified, we should no longer look in previous frames of the environment";
  input Boolean msg "Print error messages";
  output Env.Cache outCache;
  output SCode.Element outClass;
  output Env.Env outEnv "The environment in which the class was found (not the environment inside the class)";
  output list<Env.Frame> outPrevFrames;
algorithm
  (outCache,outClass,outEnv,outPrevFrames) := matchcontinue (inCache,inEnv,inPath,inPrevFrames,inState,msg)
    local
      Env.Frame f;
      Env.Cache cache;
      SCode.Element c;
      list<Env.Frame> env,env_1,env_2,fs,prevFrames;
      Absyn.Path path,p,scope;
      String id,pack;
      Option<Env.Frame> optFrame;

    // First look in cache for environment. If found look up class in that environment.
    case (cache,env,path,prevFrames,_,_)
      equation
        // Debug.traceln("lookupClass " +& Absyn.pathString(path) +& " s:" +& Env.printEnvPathStr(env));
        scope = Env.getEnvName(env);
        f::fs = Env.cacheGet(scope,path,cache);
        Util.setStatefulBoolean(inState,true);
        id = Absyn.pathLastIdent(path);
        (cache,c,env,prevFrames) = lookupClassInEnv(cache,fs,id,{},inState,msg);
        //print("HIT:");print(Absyn.pathString(path));print(" scope");print(Absyn.pathString(scope));print("\n");
        //print(Env.printCacheStr(cache));
      then
        (cache,c,env,prevFrames);

    // Fully qualified names are looked up in top scope. With previous frames remembered.
    case (cache,env,Absyn.FULLYQUALIFIED(path),{},_,_)
      equation
        f::prevFrames = listReverse(env);
        Util.setStatefulBoolean(inState,true);
        (cache,c,env_1,prevFrames) = lookupClass2(cache,{f},path,prevFrames,inState,msg);
      then
        (cache,c,env_1,prevFrames);

    // Qualified names are handled in a special function in order to avoid infinite recursion.
    case (cache,env,(p as Absyn.QUALIFIED(name = pack,path = path)),prevFrames,_,_)
      equation
        (optFrame,prevFrames) = lookupPrevFrames(pack,prevFrames);
        (cache,c,env_2,prevFrames) = lookupClassQualified(cache,env,pack,path,optFrame,prevFrames,inState,msg);
      then
        (cache,c,env_2,prevFrames);

    // Simple names
    case (cache,env,Absyn.IDENT(name = id),prevFrames,_,_)
      equation
        (cache,c,env_1,prevFrames) = lookupClassInEnv(cache,env, id, prevFrames, inState, msg);
      then
        (cache,c,env_1,prevFrames);

    /*
    case (cache,env,p,_,_,_)
      equation
        Debug.traceln("lookupClass failed " +& Absyn.pathString(p) +& " " +& Env.printEnvPathStr(env));
      then fail();
    */
  end matchcontinue;
end lookupClass2;

protected function lookupClassQualified
  input Env.Cache inCache;
  input Env.Env inEnv;
  input String id;
  input Absyn.Path path;
  input Option<Env.Frame> inOptFrame;
  input list<Env.Frame> inPrevFrames "Environment in reverse order. Contains frames we previously had in the scope. Will be looked up instead of the environment in order to avoid infinite recursion.";
  input Util.StatefulBoolean inState "If true, we have found a class. If the path was qualified, we should no longer look in previous frames of the environment";
  input Boolean msg "Print error messages";
  output Env.Cache outCache;
  output SCode.Element outClass;
  output Env.Env outEnv "The environment in which the class was found (not the environment inside the class)";
  output list<Env.Frame> outPrevFrames;
algorithm
  (outCache,outClass,outEnv,outPrevFrames) := matchcontinue (inCache,inEnv,id,path,inOptFrame,inPrevFrames,inState,msg)
    local
      SCode.Element c;
      Absyn.Path scope;
      Env.Cache cache;
      Env.Env env,prevFrames;
      Env.Frame frame;
      Option<Env.Frame> optFrame;

    // Qualified names first identifier cached in previous frames
    case (cache,env,_,_,SOME(frame),prevFrames,_,_)
      equation
        Util.setStatefulBoolean(inState,true);
        env = frame::env;
        (cache,c,env,prevFrames) = lookupClass2(cache,env,path,prevFrames,inState,msg);
      then
        (cache,c,env,prevFrames);

    // Qualified names first identifier cached
    case (cache,env,_,_,NONE(),prevFrames,_,_)
      equation
        // false = Util.getStatefulBoolean(inState); ???
        scope = Env.getEnvName(env);
        env = Env.cacheGet(scope,Absyn.IDENT(id),cache);
        Util.setStatefulBoolean(inState,true);
        (cache,c,env,prevFrames) = lookupClass2(cache,env,path,{},inState,msg);
        //print("Qualified cache hit on ");print(Absyn.pathString(p));print("\n");
      then
        (cache,c,env,prevFrames);

    // Qualified names in package and non-package
    case (cache,env,_,_,NONE(),_,_,_)
      equation
        (cache,c,env,prevFrames) = lookupClass2(cache,env,Absyn.IDENT(id),{},inState,msg);
        (optFrame,prevFrames) = lookupPrevFrames(id,prevFrames);
        (cache,c,env,prevFrames) = lookupClassQualified2(cache,env,path,c,optFrame,prevFrames,inState,msg);
      then
        (cache,c,env,prevFrames);

  end matchcontinue;
end lookupClassQualified;

protected function lookupClassQualified2
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path path;
  input SCode.Element inC;
  input Option<Env.Frame> optFrame;
  input list<Env.Frame> inPrevFrames "Environment in reverse order. Contains frames we previously had in the scope. Will be looked up instead of the environment in order to avoid infinite recursion.";
  input Util.StatefulBoolean inState "If true, we have found a class. If the path was qualified, we should no longer look in previous frames of the environment";
  input Boolean msg "Print error messages";
  output Env.Cache outCache;
  output SCode.Element outClass;
  output Env.Env outEnv "The environment in which the class was found (not the environment inside the class)";
  output list<Env.Frame> outPrevFrames;
algorithm
  (outCache,outClass,outEnv,outPrevFrames) := match (inCache,inEnv,path,inC,optFrame,inPrevFrames,inState,msg)
    local
      Env.Cache cache;
      Env.Env env,prevFrames;
      Env.Frame frame;
      SCode.Restriction restr;
      ClassInf.State ci_state;
      SCode.Encapsulated encflag;
      String id;
      SCode.Element c;

    case (cache,env,_,_,SOME(frame),prevFrames,_,_)
      equation
        env = frame::env;
        (cache,c,env,prevFrames) = lookupClass2(cache,env,path,prevFrames,inState,msg);
        // Debug.fprintln(Flags.INST_TRACE, "LOOKUP CLASS QUALIFIED FRAME: " +& Env.printEnvPathStr(env) +& " path: " +& Absyn.pathString(path) +& " class: " +& SCodeDump.shortElementStr(c));
      then (cache,c,env,prevFrames);

    case (cache,env,_,SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr),NONE(),_,_,_)
      equation
        env = Env.openScope(env, encflag, SOME(id), Env.restrictionToScopeType(restr));
        ci_state = ClassInf.start(restr, Env.getEnvName(env));
        // Debug.fprintln(Flags.INST_TRACE, "LOOKUP CLASS QUALIFIED PARTIALICD: " +& Env.printEnvPathStr(env) +& " path: " +& Absyn.pathString(path) +& " class: " +& SCodeDump.shortElementStr(c));
        (cache,env,_,_) =
        Inst.partialInstClassIn(
          cache,env,InnerOuter.emptyInstHierarchy,
          DAE.NOMOD(), Prefix.NOPRE(),
          ci_state, inC, SCode.PUBLIC(), {});
        // Was 2 cases for package/non-package - all they did was fail or succeed on this
        // If we comment it out, we get faster code, and less of it to maintain
        // ClassInf.valid(cistate1, SCode.R_PACKAGE());
        (cache,c,env,prevFrames) = lookupClass2(cache,env,path,{},inState,msg);
      then (cache,c,env,prevFrames);
  end match;
end lookupClassQualified2;

protected function lookupPrevFrames
  input String id;
  input list<Env.Frame> inPrevFrames;
  output Option<Env.Frame> outFrame;
  output list<Env.Frame> outPrevFrames;
algorithm
  (outFrame,outPrevFrames) := matchcontinue (id,inPrevFrames)
    local
      String sid;
      list<Env.Frame> prevFrames;
      Env.Frame frame;
    case (_,(frame as Env.FRAME(name = SOME(sid)))::prevFrames)
      equation
        true = id ==& sid;
      then (SOME(frame),prevFrames);
    case (_,_) then (NONE(),{});
  end matchcontinue;
end lookupPrevFrames;

protected function lookupQualifiedImportedVarInFrame
"function: lookupQualifiedImportedVarInFrame
  author: PA
  Looking up variables (constants) imported using qualified imports,
  i.e. import Modelica.Constants.PI;"
  input list<Absyn.Import> inImports;
  input SCode.Ident ident;
  output DAE.ComponentRef outCref;
algorithm
  (outCref) := matchcontinue (inImports,ident)
    local
      String id;
      list<Absyn.Import> rest;
      Absyn.Path path;

      // For imported simple name, e.g. A, not possible to assert sub-path package
    case (Absyn.QUAL_IMPORT(path = path) :: rest, _)
      equation
        id = Absyn.pathLastIdent(path);
        true = id ==& ident;
      then ComponentReference.pathToCref(path);

    // Named imports, e.g. import A = B.C;
    case (Absyn.NAMED_IMPORT(name = id,path = path) :: rest, _)
      equation
        true = id ==& ident;
      then ComponentReference.pathToCref(path);

    // Check next frame.
    case (_ :: rest, _) then lookupQualifiedImportedVarInFrame(rest, ident);
  end matchcontinue;
end lookupQualifiedImportedVarInFrame;

protected function moreLookupUnqualifiedImportedVarInFrame
"function: moreLookupUnqualifiedImportedVarInFrame
  Helper function for lookup_unqualified_imported_var_in_frame. Returns
  true if there are unqualified imports that matches a sought constant."
  input Env.Cache inCache;
  input list<Absyn.Import> inImports;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output Boolean outBoolean;
algorithm
  (outCache,outBoolean) := matchcontinue (inCache,inImports,inEnv,inIdent)
    local
      Env.Frame f;
      String ident;
      Boolean res;
      list<Env.Frame> env,prevFrames;
      list<Absyn.Import> rest;
      Env.Cache cache;
      DAE.ComponentRef cref;
      Absyn.Path path;

    case (cache,Absyn.UNQUAL_IMPORT(path = path) :: rest,env,ident)
      equation
        f::prevFrames = listReverse(env);
        cref = ComponentReference.pathToCref(path);
        cref = ComponentReference.crefPrependIdent(cref,ident,{},DAE.T_UNKNOWN_DEFAULT);
        (cache,_,_,_,_,_,_,_,_) = lookupVarInPackages(cache,{f},cref,prevFrames,Util.makeStatefulBoolean(false));
      then
        (cache,true);

    // look into the parent scope
    case (cache,(_ :: rest),env,ident)
      equation
        (cache, res) = moreLookupUnqualifiedImportedVarInFrame(cache, rest, env, ident);
      then
        (cache, res);

    // we reached the end, no more lookup
    case (cache,{},_,_) then (cache, false);

  end matchcontinue;
end moreLookupUnqualifiedImportedVarInFrame;

protected function lookupUnqualifiedImportedVarInFrame "function: lookupUnqualifiedImportedVarInFrame
  Find a variable from an unqualified import locally in a frame"
  input Env.Cache inCache;
  input list<Absyn.Import> inImports;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output Env.Env outClassEnv;
  output DAE.Attributes outAttributes;
  output DAE.Type outType;
  output DAE.Binding outBinding;
  output Option<DAE.Const> constOfForIteratorRange "SOME(constant-ness) of the range if this is a for iterator, NONE() if this is not a for iterator";
  output Boolean outBoolean;
  output SplicedExpData splicedExpData;
  output Env.Env outComponentEnv;
  output String name;
algorithm
  (outCache,outClassEnv,outAttributes,outType,outBinding,constOfForIteratorRange,outBoolean,splicedExpData,outComponentEnv,name):=
  matchcontinue (inCache,inImports,inEnv,inIdent)
    local
      Env.Frame f;
      DAE.ComponentRef cref;
      String ident;
      Boolean more,unique;
      list<Env.Frame> env,classEnv,componentEnv,prevFrames;
      DAE.Attributes attr;
      DAE.Type ty;
      DAE.Binding bind;
      list<Absyn.Import> rest;
      Env.Cache cache;
      Absyn.Path path;
      Option<DAE.Const> cnstForRange;

    // unique
    case (cache,Absyn.UNQUAL_IMPORT(path = path) :: rest,env,ident)
      equation
        f::prevFrames = listReverse(env);
        cref = ComponentReference.pathToCref(path);
        cref = ComponentReference.crefPrependIdent(cref,ident,{},DAE.T_UNKNOWN_DEFAULT);
        (cache,classEnv,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name) = lookupVarInPackages(cache,{f},cref,prevFrames,Util.makeStatefulBoolean(false));
        (cache,more) = moreLookupUnqualifiedImportedVarInFrame(cache, rest, env, ident);
        unique = boolNot(more);
      then
        (cache,classEnv,attr,ty,bind,cnstForRange,unique,splicedExpData,componentEnv,name);

    // search in the parent scopes
    case (cache,_ :: rest,env,ident)
      equation
        (cache,classEnv,attr,ty,bind,cnstForRange,unique,splicedExpData,componentEnv,name) = lookupUnqualifiedImportedVarInFrame(cache, rest, env, ident);
      then
        (cache,classEnv,attr,ty,bind,cnstForRange,unique,splicedExpData,componentEnv,name);
  end matchcontinue;
end lookupUnqualifiedImportedVarInFrame;

protected function lookupQualifiedImportedClassInFrame
"function: lookupQualifiedImportedClassInFrame
  Helper function to lookupQualifiedImportedClassInEnv."
  input Env.Cache inCache;
  input list<Absyn.Import> inImport;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  input Util.StatefulBoolean inState;
  output Env.Cache outCache;
  output SCode.Element outClass;
  output Env.Env outEnv;
  output Env.Env outPrevFrames;
algorithm
  (outCache,outClass,outEnv,outPrevFrames) := matchcontinue (inCache,inImport,inEnv,inIdent,inState)
    local
      Env.Frame fr;
      SCode.Element c;
      list<Env.Frame> env_1,env,prevFrames;
      String id,ident;
      list<Absyn.Import> rest;
      Absyn.Path path;
      Env.Cache cache;

    case (cache,Absyn.QUAL_IMPORT(path = Absyn.IDENT(name = id)) :: _,env,ident,_)
      equation
        true = id ==& ident "For imported paths A, not possible to assert sub-path package";
        Util.setStatefulBoolean(inState,true);
        fr::prevFrames = listReverse(env);
        (cache,c,env_1,prevFrames) = lookupClass2(cache,{fr},Absyn.IDENT(id),prevFrames,Util.makeStatefulBoolean(false),true);
      then
        (cache,c,env_1,prevFrames);

    case (cache,Absyn.QUAL_IMPORT(path = path) :: rest,env,ident,_)
      equation
        id = Absyn.pathLastIdent(path) "For imported path A.B.C, assert A.B is package" ;
        true = id ==& ident;
        Util.setStatefulBoolean(inState,true);

        fr::prevFrames = listReverse(env);
        // strippath = Absyn.stripLast(path);
        // (cache,c2,env_1,_) = lookupClass2(cache,{fr},strippath,prevFrames,Util.makeStatefulBoolean(false),true);
        (cache,c,env_1,prevFrames) = lookupClass2(cache,{fr},path,prevFrames,Util.makeStatefulBoolean(false),true);
      then
        (cache,c,env_1,prevFrames);

    case (cache,Absyn.NAMED_IMPORT(name = id,path = path) :: rest,env,ident,_)
      equation
        true = id ==& ident "Named imports";
        Util.setStatefulBoolean(inState,true);
        fr::prevFrames = listReverse(env);
        // strippath = Absyn.stripLast(path);
        // Debug.traceln("named import " +& id +& " is " +& Absyn.pathString(path));
        // (cache,c2,env_1,prevFrames) = lookupClass2(cache,{fr},strippath,prevFrames,Util.makeStatefulBoolean(false),true);
        (cache,c,env_1,prevFrames) = lookupClass2(cache,{fr},path,prevFrames,Util.makeStatefulBoolean(false),true);
      then
        (cache,c,env_1,prevFrames);

    case (cache,_ :: rest,env,ident,_)
      equation
        (cache,c,env_1,prevFrames) = lookupQualifiedImportedClassInFrame(cache,rest,env,ident,inState);
      then
        (cache,c,env_1,prevFrames);
  end matchcontinue;
end lookupQualifiedImportedClassInFrame;

protected function moreLookupUnqualifiedImportedClassInFrame
"function: moreLookupUnqualifiedImportedClassInFrame
  Helper function for lookupUnqualifiedImportedClassInFrame"
  input Env.Cache inCache;
  input list<Absyn.Import> inImports;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output Boolean outBoolean;
algorithm
  (outCache,outBoolean) := matchcontinue (inCache,inImports,inEnv,inIdent)
    local
      Env.Frame fr,f;
      SCode.Element c;
      String id,ident;
      SCode.Encapsulated encflag;
      Boolean res;
      SCode.Restriction restr;
      list<Env.Frame> env_1,env2,env;
      ClassInf.State ci_state;
      Absyn.Path path;
      Absyn.Ident firstIdent;
      list<Absyn.Import> rest;
      Env.Cache cache;

    // Look in cache
    case (cache,Absyn.UNQUAL_IMPORT(path = path) :: rest,env,ident)
      equation
        firstIdent = Absyn.pathFirstIdent(path);
        f :: _ = Env.cacheGet(Absyn.IDENT(firstIdent),path,cache);
        (cache,_,_) = lookupClass(cache,{f}, Absyn.IDENT(ident), false);
      then
        (cache, true);

    // Not found, instantiate
    case (cache,Absyn.UNQUAL_IMPORT(path = path) :: rest,env,ident)
      equation
        fr = Env.topFrame(env);
        (cache,(c as SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr)),env_1) = lookupClass(cache, {fr}, path, false);
        env2 = Env.openScope(env_1, encflag, SOME(id), Env.restrictionToScopeType(restr));
        ci_state = ClassInf.start(restr, Env.getEnvName(env2));
        // Debug.fprintln(Flags.INST_TRACE, "LOOKUP MORE UNQUALIFIED IMPORTED ICD: " +& Env.printEnvPathStr(env) +& "." +& ident);
        (cache,(f :: _),_,_) = Inst.partialInstClassIn(cache, env2,
          InnerOuter.emptyInstHierarchy, DAE.NOMOD(), Prefix.NOPRE(), ci_state,
          c, SCode.PUBLIC(), {}); (cache,_,_) = lookupClass(cache,{f},
          Absyn.IDENT(ident), false);
      then
        (cache, true);

    // look in the parent scope
    case (cache,_ :: rest,env,ident)
      equation
        (cache, res) = moreLookupUnqualifiedImportedClassInFrame(cache, rest, env, ident);
      then
        (cache, res);
    case (cache,{},_,_) then (cache,false);
  end matchcontinue;
end moreLookupUnqualifiedImportedClassInFrame;

protected function lookupUnqualifiedImportedClassInFrame
"function: lookupUnqualifiedImportedClassInFrame
  Finds a class from an unqualified import locally in a frame"
  input Env.Cache inCache;
  input list<Absyn.Import> inImports;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output SCode.Element outClass;
  output Env.Env outEnv;
  output Env.Env outPrevFrames;
  output Boolean outBoolean;
algorithm
  (outCache,outClass,outEnv,outPrevFrames,outBoolean) := matchcontinue (inCache,inImports,inEnv,inIdent)
    local
      Env.Frame fr;
      SCode.Element c,c_1;
      String id,ident;
      SCode.Encapsulated encflag;
      Boolean more,unique;
      SCode.Restriction restr;
      list<Env.Frame> env_1,env2,env,prevFrames;
      ClassInf.State ci_state,cistate1;
      Absyn.Path path;
      list<Absyn.Import> rest;
      Env.Cache cache;
      Absyn.Ident firstIdent;

    // Look in cache, unique
    case (cache,Absyn.UNQUAL_IMPORT(path = path) :: rest,env,ident)
      equation
        firstIdent = Absyn.pathFirstIdent(path);
        env2 = Env.cacheGet(Absyn.IDENT(firstIdent),path,cache);
        (cache,c_1,env2,prevFrames) = lookupClass2(cache,env,Absyn.IDENT(ident),{},Util.makeStatefulBoolean(true),false) "Restrict import to the imported scope only, not its parents..." ;
        (cache,more) = moreLookupUnqualifiedImportedClassInFrame(cache, rest, env, ident);
        unique = boolNot(more);
      then
        (cache,c_1,env2,prevFrames,unique);

    // Not in cache, instantiate, unique
    case (cache,Absyn.UNQUAL_IMPORT(path = path) :: rest,env,ident)
      equation
        fr::prevFrames = listReverse(env);
        (cache,(c as SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr)),env_1,prevFrames) = lookupClass2(cache,{fr},path,prevFrames,Util.makeStatefulBoolean(false),false);
        env2 = Env.openScope(env_1, encflag, SOME(id), Env.restrictionToScopeType(restr));
        ci_state = ClassInf.start(restr, Env.getEnvName(env2));
        // Debug.fprintln(Flags.INST_TRACE, "LOOKUP UNQUALIFIED IMPORTED ICD: " +& Env.printEnvPathStr(env) +& "." +& ident);
        (cache,env2,_,cistate1) =
        Inst.partialInstClassIn(cache, env2, InnerOuter.emptyInstHierarchy,
          DAE.NOMOD(), Prefix.NOPRE(), ci_state, c, SCode.PUBLIC(), {});
        // Restrict import to the imported scope only, not its parents, thus {f} below
        (cache,c_1,env2,prevFrames) = lookupClass2(cache,env2,Absyn.IDENT(ident),prevFrames,Util.makeStatefulBoolean(true),false) "Restrict import to the imported scope only, not its parents..." ;
        (cache,more) = moreLookupUnqualifiedImportedClassInFrame(cache, rest, env, ident);
        unique = boolNot(more);
      then
        (cache,c_1,env2,prevFrames,unique);

    // look in the parent scope
    case (cache,_ :: rest,env,ident)
      equation
        (cache,c,env_1,prevFrames,unique) = lookupUnqualifiedImportedClassInFrame(cache, rest, env, ident);
      then
        (cache,c,env_1,prevFrames,unique);
  end matchcontinue;
end lookupUnqualifiedImportedClassInFrame;

public function lookupRecordConstructorClass
"function: lookupRecordConstructorClass
  Searches for a record constructor implicitly defined by a record class."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output Env.Cache outCache;
  output SCode.Element outClass;
  output Env.Env outEnv;
algorithm
  (outCache,outClass,outEnv) := match (inCache,inEnv,inPath)
    local
      SCode.Element c;
      Env.Env env,env_1;
      Absyn.Path path;
      String name;
      Env.Cache cache;

    case (cache,env,path)
      equation
        (cache,c,env_1) = lookupClass(cache,env, path, false);
        SCode.CLASS(name = name, restriction=SCode.R_RECORD()) = c;
        (cache,_,c) = buildRecordConstructorClass(cache,env_1,c);
      then
        (cache,c,env_1);
  end match;
end lookupRecordConstructorClass;

public function lookupConnectorVar
"looks up a connector variable, but takes InnerOuter attribute from component if
 inside connector, i.e. for connector reference a.b the innerOuter attribute is
 fetched from a."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef cr;
  output Env.Cache outCache;
  output DAE.Attributes attr;
  output DAE.Type tp;
algorithm
  (outCache,attr,tp) := match(inCache,inEnv,cr)
    local
      DAE.ComponentRef cr1;
      SCode.ConnectorType ct;
      SCode.Parallelism prl;
      SCode.Variability var;
      Absyn.Direction dir;
      Absyn.InnerOuter io;
      DAE.Type ty1;
      DAE.Attributes attr1;
      Env.Cache cache;
      Env.Env env;
      SCode.Visibility vis;

    // unqualified component reference
    case(cache,env,DAE.CREF_IDENT(ident=_))
      equation
        (cache,attr1,ty1,_,_,_,_,_,_) = lookupVarLocal(cache,env,cr);
      then
        (cache,attr1,ty1);

    // qualified component reference
    case(cache,env,DAE.CREF_QUAL(ident=_))
      equation
        (cache,attr1 as DAE.ATTR(ct,prl,var,dir,_,vis),ty1,_,_,_,_,_,_) = lookupVarLocal(cache,env,cr);
        cr1 = ComponentReference.crefStripLastIdent(cr);
        // Find innerOuter attribute from "parent"
        (cache,DAE.ATTR(innerOuter=io),_,_,_,_,_,_,_) = lookupVarLocal(cache,env,cr1);
      then
        (cache,DAE.ATTR(ct,prl,var,dir,io,vis),ty1);
  end match;
end lookupConnectorVar;

public function lookupVar
  "LS: when looking up qualified component reference, lookupVar only
   checks variables when looking for the prefix, i.e. for Constants.PI
   where Constants is a package and is implicitly instantiated, PI is not
   found since Constants is not a variable (it is a type and/or class).

   1) One option is to make it a variable and put it in the global frame.
   2) Another option is to add a lookup rule that also looks in types.

   Now implicitly instantiated packages exists both as a class and as a
   type (see implicit_instantiation in Inst.mo). Is this correct?

   lookupVar is modified to implement 2. Is this correct?

   old lookupVar is changed to lookupVarInternal and a new lookupVar
   is written, that first tests the old lookupVar, and if not found
   looks in the types

   function: lookupVar

   This function tries to finds a variable in the environment

   Arg1: The environment to search in
   Arg2: The variable to search for."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
  output Env.Cache outCache;
  output DAE.Attributes outAttributes;
  output DAE.Type outType;
  output DAE.Binding outBinding;
  output Option<DAE.Const> constOfForIteratorRange "SOME(constant-ness) of the range if this is a for iterator, NONE() if this is not a for iterator";
  output SplicedExpData outSplicedExpData;
  output Env.Env outClassEnv "only used for package constants";
  output Env.Env outComponentEnv "only used for package constants";
  output String name "so the FQ path can be constructed";
algorithm
  (outCache,outAttributes,outType,outBinding,constOfForIteratorRange,outSplicedExpData,outClassEnv,outComponentEnv,name) :=
  matchcontinue (inCache,inEnv,inComponentRef)
    local
      DAE.Attributes attr;
      DAE.Type ty;
      DAE.Binding binding;
      list<Env.Frame> env, componentEnv, classEnv;
      DAE.ComponentRef cref;
      Env.Cache cache;
      SplicedExpData splicedExpData;
      Option<DAE.Const> cnstForRange;

    /*
    case (cache,env,cref)
      equation
        true = Flags.isSet(Flags.LOOKUP);
        Debug.traceln("lookupVar: " +&
          ComponentReference.printComponentRefStr(cref) +&
          " in env: " +&
          Env.printEnvPathStr(env) +& "\n");
      then
        fail();
    */
    // try the old lookupVarInternal
    case (cache,env,cref)
      equation
        (cache,attr,ty,binding,cnstForRange,splicedExpData,classEnv,componentEnv,name) = lookupVarInternal(cache, env, cref, SEARCH_ALSO_BUILTIN());
      then
        (cache,attr,ty,binding,cnstForRange,splicedExpData,classEnv,componentEnv,name);

    // then look in classes (implicitly instantiated packages)
    case (cache,env,cref)
      equation
        (cache,classEnv,attr,ty,binding,cnstForRange,splicedExpData,componentEnv,name) = lookupVarInPackages(cache,env,cref,{},Util.makeStatefulBoolean(false));
        checkPackageVariableConstant(classEnv,attr,ty,cref);
        // optional Expression.exp to return
      then
        (cache,attr,ty,binding,cnstForRange,splicedExpData,classEnv,componentEnv,name);

    // fail if we couldn't find it
    case (_,env,cref)
      equation
        //Debug.fprintln(Flags.FAILTRACE,  "- Lookup.lookupVar failed " +& ComponentReference.printComponentRefStr(cref) +& " in " +& Env.printEnvPathStr(env));
      then fail();
  end matchcontinue;
end lookupVar;

protected function checkPackageVariableConstant "
Variables in packages must be constant. This function produces an error message and fails
if variable is not constant."
  input Env.Env env;
  input DAE.Attributes attr;
  input DAE.Type tp;
  input DAE.ComponentRef cref;
algorithm
  _ := matchcontinue(env,attr,tp,cref)
    local
      String s1,s2;

    // do not fail if is a constant
    case (_,DAE.ATTR(variability= SCode.CONST()),_,_) then ();

    // fail if is not a constant
    case (_,_,_,_)
      equation
        s1 = ComponentReference.printComponentRefStr(cref);
        s2 = Env.printEnvPathStr(env);
        Error.addMessage(Error.PACKAGE_VARIABLE_NOT_CONSTANT,{s1,s2});
        Debug.fprintln(Flags.FAILTRACE, "- Lookup.checkPackageVariableConstant failed: " +& s1 +& " in " +& s2);
      then fail();
  end matchcontinue;
end checkPackageVariableConstant;

public function lookupVarInternal "function: lookupVarInternal
  Helper function to lookupVar. Searches the frames for variables."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
  input SearchStrategy searchStrategy "if SEARCH_LOCAL_ONLY it won't search in the builtin scope";
  output Env.Cache outCache;
  output DAE.Attributes outAttributes;
  output DAE.Type outType;
  output DAE.Binding outBinding;
  output Option<DAE.Const> constOfForIteratorRange "SOME(constant-ness) of the range if this is a for iterator, NONE() if this is not a for iterator";
  output SplicedExpData splicedExpData;
  output Env.Env outClassEnv "the environment of the variable, typically the same as input, but e.g. for loop scopes can be 'stripped'";
  output Env.Env outComponentEnv "the component environment of the variable";
  output String name;
algorithm
  (outCache,outAttributes,outType,outBinding,constOfForIteratorRange,splicedExpData,outClassEnv,outComponentEnv,name) :=
  matchcontinue (inCache,inEnv,inComponentRef,searchStrategy)
    local
      DAE.Attributes attr;
      DAE.Type ty;
      DAE.Binding binding;
      Option<String> sid;
      Env.AvlTree ht;
      list<Env.Frame> fs;
      Env.Frame f;
      DAE.ComponentRef ref;
      Env.Cache cache;
      Option<DAE.Const> cnstForRange;
      Env.Env env,componentEnv;

    // look into the current frame
    case (cache, Env.FRAME(name = sid,clsAndVars = ht)::fs, ref, _)
      equation
          (cache,attr,ty,binding,cnstForRange,splicedExpData,componentEnv,name) = lookupVarF(cache, ht, ref);
      then
        (cache,attr,ty,binding,cnstForRange,splicedExpData,inEnv,componentEnv,name);

    // look in the next frame, only if current frame is a for loop scope.
    case (cache, f :: fs, ref, _)
      equation
        true = frameIsImplAddedScope(f);
        (cache,attr,ty,binding,cnstForRange,splicedExpData,env,componentEnv,name) = lookupVarInternal(cache, fs, ref, searchStrategy);
      then
        (cache,attr,ty,binding,cnstForRange,splicedExpData,env,componentEnv,name);

    // If not in top scope, look in top scope for builtin variables, e.g. time.
    case (cache, fs as _::_::_, ref, SEARCH_ALSO_BUILTIN())
      equation
        true = Builtin.variableIsBuiltin(ref);
        (f as Env.FRAME(clsAndVars = ht)) = Env.topFrame(fs);
        (cache,attr,ty,binding,cnstForRange,splicedExpData,componentEnv,name) = lookupVarF(cache, ht, ref);
      then
        (cache,attr,ty,binding,cnstForRange,splicedExpData,{f},componentEnv,name);

  end matchcontinue;
end lookupVarInternal;

protected function frameIsImplAddedScope
"returns true if the frame is a for-loop scope or a valueblock scope.
This is indicated by the name of the frame."
  input Env.Frame f;
  output Boolean b;
algorithm
  b := matchcontinue(f)
    local String name;
    case(Env.FRAME(name=SOME(name))) equation
      true = listMember(name, Env.implicitScopeNames);
    then true;
    case(_) then false;
  end matchcontinue;
end frameIsImplAddedScope;

public function lookupVarInPackages "function: lookupVarInPackages
  This function is called when a lookup of a variable with qualified names
  does not have the first element as a component, e.g. A.B.C is looked up
  where A is not a component. This implies that A is a class, and this
  class should be temporary instantiated, and the lookup should
  be performed within that class. I.e. the function performs lookup of
  variables in the class hierarchy.

  Note: the splicedExpData is currently not relevant, since constants are always evaluated to a value.
        However, this might change in the future since it makes more sense to calculate the constants
        during setup in runtime (to gain precision and postpone choice of precision to runtime)."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
  input list<Env.Frame> inPrevFrames "Environment in reverse order. Contains frames we previously had in the scope. Will be looked up instead of the environment in order to avoid infinite recursion.";
  input Util.StatefulBoolean inState "If true, we have found a class. If the path was qualified, we should no longer look in a lower scope.";
  output Env.Cache outCache;
  output Env.Env outClassEnv;
  output DAE.Attributes outAttributes;
  output DAE.Type outType;
  output DAE.Binding outBinding;
  output Option<DAE.Const> constOfForIteratorRange "SOME(constant-ness) of the range if this is a for iterator, NONE() if this is not a for iterator";
  output SplicedExpData splicedExpData "currently not relevant for constants, but might be used in the future";
  output Env.Env outComponentEnv;
  output String name "We only return the environment the component was found in; not its FQ name.";
algorithm
  (outCache,outClassEnv,outAttributes,outType,outBinding,constOfForIteratorRange,splicedExpData,outComponentEnv,name) :=
  matchcontinue (inCache,inEnv,inComponentRef,inPrevFrames,inState)
    local
      SCode.Element c;
      String n,id;
      SCode.Encapsulated encflag;
      SCode.Restriction r;
      list<Env.Frame> env2,env3,env5,env,fs,p_env,prevFrames, classEnv, componentEnv;
      ClassInf.State ci_state;
      DAE.Attributes attr;
      DAE.Type ty;
      DAE.Binding bind;
      DAE.ComponentRef cref,cr;
      list<DAE.Subscript> sb;
      Option<String> sid;
      Env.Frame f;
      Env.Cache cache;
      Option<DAE.Const> cnstForRange;
      Absyn.Path path,scope;
      Boolean unique;
      Env.AvlTree ht;
      Env.ImportTable importTable;
      list<Absyn.Import> imports;

      // If we search for A1.A2....An.x while in scope A1.A2...An, just search for x.
      // Must do like this to ensure finite recursion
    case (cache,env,cr as DAE.CREF_QUAL(ident = id,subscriptLst = {},componentRef = cref),prevFrames,_) /* First part of name is a previous frame */
      equation
        (SOME(f),prevFrames) = lookupPrevFrames(id,prevFrames);
        Util.setStatefulBoolean(inState,true);
        (cache,classEnv,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name) = lookupVarInPackages(cache,f::env,cref,prevFrames,inState);
      then
        (cache,classEnv,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name);

    // lookup of constants on form A.B in packages. First look in cache.
    case (cache,env,cr as DAE.CREF_QUAL(ident = id,subscriptLst = {},componentRef = cref),prevFrames,_) /* First part of name is a class. */
      equation
        (NONE(),prevFrames) = lookupPrevFrames(id,prevFrames);
        scope = Env.getEnvName(env);
        path = ComponentReference.crefToPath(cr);
        id = Absyn.pathLastIdent(path);
        path = Absyn.stripLast(path);
        f::fs = Env.cacheGet(scope,path,cache);
        Util.setStatefulBoolean(inState,true);
        (cache,attr,ty,bind,cnstForRange,splicedExpData,classEnv,componentEnv,name) = lookupVarLocal(cache,f::fs, ComponentReference.makeCrefIdent(id,DAE.T_UNKNOWN_DEFAULT,{}));
        //print("found ");print(ComponentReference.printComponentRefStr(cr));print(" in cache\n");
      then
        (cache,f::fs,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name);

    // lookup of constants on form A.B in packages. instantiate package and look inside.
    case (cache,env,cr as DAE.CREF_QUAL(ident = id,subscriptLst = {},componentRef = cref),prevFrames,_) /* First part of name is a class. */
      equation
        (NONE(),prevFrames) = lookupPrevFrames(id,prevFrames);
        (cache,(c as SCode.CLASS(name=n,encapsulatedPrefix=encflag,restriction=r)),env2,prevFrames) =
          lookupClass2(
            cache,
            env,
            Absyn.IDENT(id),
            prevFrames,
            Util.makeStatefulBoolean(true) /* In order to use the prevFrames, we need to make sure we can't instantiate one of the classes too soon! */,
            false);
        Util.setStatefulBoolean(inState,true);

        env3 = Env.openScope(env2, encflag, SOME(n), Env.restrictionToScopeType(r));
        ci_state = ClassInf.start(r, Env.getEnvName(env3));
        // Debug.fprintln(Flags.INST_TRACE, "LOOKUP VAR IN PACKAGES ICD: " +& Env.printEnvPathStr(env3) +& " var: " +& ComponentReference.printComponentRefStr(cref));
        (cache,env5,_,_,_,_,_,_,_,_,_,_) =
        Inst.instClassIn(cache,env3,InnerOuter.emptyInstHierarchy,UnitAbsyn.noStore,
          DAE.NOMOD(), Prefix.NOPRE(), ci_state, c, SCode.PUBLIC(), {},
          /*true*/false, Inst.INNER_CALL(), ConnectionGraph.EMPTY,
          Connect.emptySet, NONE());
        (cache,p_env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name) = lookupVarInPackages(cache,env5,cref,prevFrames,inState);
      then
        (cache,p_env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name);

    // Why is this done? It is already done done in lookupVar!
    // BZ: This is due to recursive call when it might become DAE.CREF_IDENT calls.
    case (cache,env,(cr as DAE.CREF_IDENT(ident = id,subscriptLst = sb)),prevFrames,_)
      equation
        (cache,attr,ty,bind,cnstForRange,splicedExpData,classEnv,componentEnv,name) = lookupVarLocal(cache, env, cr);
        Util.setStatefulBoolean(inState,true);
      then
        (cache,env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name);

    // Lookup where the first identifier is a component.
    case (cache, env as (Env.FRAME(clsAndVars = ht) :: _), cr, _, _)
      equation
        (cache, attr, ty, bind, cnstForRange, splicedExpData, componentEnv, name) = lookupVarF(cache, ht, cr);
      then
        (cache, env, attr, ty, bind, cnstForRange, splicedExpData, componentEnv, name);

    // Search among qualified imports, e.g. import A.B; or import D=A.B;
    case (cache,(env as (Env.FRAME(name = sid, importTable = importTable) :: _)),DAE.CREF_IDENT(ident = id,subscriptLst = sb),prevFrames,_)
      equation
        imports = getQualifiedImports(importTable);
        cr = lookupQualifiedImportedVarInFrame(imports, id);
        Util.setStatefulBoolean(inState,true);
        f::prevFrames = listReverse(env);
        (cache,p_env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name) = lookupVarInPackages(cache,{f},cr,prevFrames,inState);
      then
        (cache,p_env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name);

    // Search among unqualified imports, e.g. import A.B.*
    case (cache,(env as (Env.FRAME(name = sid, importTable = importTable) :: _)),(cr as DAE.CREF_IDENT(ident = id,subscriptLst = sb)),prevFrames,_)
      equation
        imports = getUnQualifiedImports(importTable);
        (cache,p_env,attr,ty,bind,cnstForRange,unique,splicedExpData,componentEnv,name) = lookupUnqualifiedImportedVarInFrame(cache, imports, env, id);
        reportSeveralNamesError(unique,id);
        Util.setStatefulBoolean(inState,true);
      then
        (cache,p_env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name);

     // Search parent scopes
    case (cache,((f as Env.FRAME(name = SOME(id))):: fs),cr,prevFrames,_)
      equation
        false = Util.getStatefulBoolean(inState);
        (cache,p_env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name) = lookupVarInPackages(cache,fs,cr,f::prevFrames,inState);
      then
        (cache,p_env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name);

    case (cache,env,cr,prevFrames,_)
      equation
        //true = Flags.isSet(Flags.FAILTRACE);
        //Debug.traceln("- Lookup.lookupVarInPackages failed on exp:" +& ComponentReference.printComponentRefStr(cr) +& " in scope: " +& Env.printEnvPathStr(env));
      then
        fail();
  end matchcontinue;
end lookupVarInPackages;

public function getQualifiedImports
  input Env.ImportTable importTable;
  output list<Absyn.Import> imports;
algorithm
  Env.IMPORT_TABLE(qualifiedImports = imports) := importTable;
end getQualifiedImports;

public function getUnQualifiedImports
  input Env.ImportTable importTable;
  output list<Absyn.Import> imports;
algorithm
  Env.IMPORT_TABLE(unqualifiedImports = imports) := importTable;
end getUnQualifiedImports;

public function lookupVarLocal
"function: lookupVarLocal
  This function is very similar to `lookup_var\', but it only looks
  in the topmost environment frame, which means that it only finds
  names defined in the local scope.
  ----EXCEPTION---: When the topmost scope is the scope of a for loop, the lookup
  continues on the next scope. This to allow variables in the local scope to
  also be found even if inside a for scope.
  Arg1: The environment to search in
  Arg2: The variable to search for."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
  output Env.Cache outCache;
  output DAE.Attributes outAttributes;
  output DAE.Type outType;
  output DAE.Binding outBinding;
  output Option<DAE.Const> constOfForIteratorRange "SOME(constant-ness) of the range if this is a for iterator, NONE() if this is not a for iterator";
  output SplicedExpData splicedExpData;
  output Env.Env outClassEnv;
  output Env.Env outComponentEnv;
  output String name;
algorithm
  // adrpo: use lookupVarInternal as is the SAME but it doesn't search in the builtin scope!
  (outCache,outAttributes,outType,outBinding,constOfForIteratorRange,splicedExpData,outClassEnv,outComponentEnv,name) :=
    lookupVarInternal(inCache, inEnv, inComponentRef, SEARCH_LOCAL_ONLY());
end lookupVarLocal;

public function lookupIdentLocal "function: lookupIdentLocal
  Searches for a variable in the local scope."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output DAE.Var outVar;
  output SCode.Element outElement;
  output DAE.Mod outMod;
  output Env.InstStatus instStatus;
  output Env.Env outComponentEnv;
algorithm
  (outCache,outVar,outElement,outMod,instStatus,outComponentEnv):=
  matchcontinue (inCache,inEnv,inIdent)
    local
      DAE.Var fv;
      SCode.Element c;
      DAE.Mod m;
      Env.InstStatus i;
      Env.Frame f;
      list<Env.Frame> env,fs,componentEnv;
      Option<String> sid;
      Env.AvlTree ht;
      String id;
      Env.Cache cache;

    // component environment
    case (cache, env as Env.FRAME(name = sid, clsAndVars = ht)::fs, id)
      equation
        (cache,fv,c,m,i,componentEnv) = lookupVar2(cache, ht, id);
      then
        (cache,fv,c,m,i,componentEnv);

    // Look in the next frame, if the current frame is a for loop scope.
    case (cache, f::fs, id)
      equation
        true = frameIsImplAddedScope(f);
        (cache,fv,c,m,i,componentEnv) = lookupIdentLocal(cache, fs, id);
      then
        (cache,fv,c,m,i,componentEnv);

  end matchcontinue;
end lookupIdentLocal;

public function lookupClassLocal "function: lookupClassLocal
  Searches for a class definition in the local scope."
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output SCode.Element outClass;
  output Env.Env outEnv;
algorithm
  (outClass,outEnv) := match (inEnv,inIdent)
    local
      SCode.Element cl;
      list<Env.Frame> env;
      Option<String> sid;
      Env.AvlTree ht;
      String id;
    case (env as (Env.FRAME(name = sid, clsAndVars = ht) :: _),id) /* component environment */
      equation
        Env.CLASS(cl,env,_) = Env.avlTreeGet(ht, id);
      then
        (cl,env);
  end match;
end lookupClassLocal;

public function lookupAndInstantiate
 "performs a lookup of a class and then instantiate that class
  to return its environment. Helper function used e.g by Inst.mo"
  input Env.Cache inCache;
  input Env.Env env;
  input Absyn.Path path;
  input SCode.Mod mod;
  input Boolean msg;
  output Env.Cache outCache;
  output Env.Env classEnv;
algorithm
  (outCache,classEnv) := matchcontinue(inCache,env,path,mod,msg)
    local  Env.Cache cache;
      String cn2;
      SCode.Encapsulated enc,enc2;
      SCode.Restriction r;
      ClassInf.State new_ci_state;
      Env.Env cenv,cenv_2;
      Absyn.Path scope;
      SCode.Element c;
      Absyn.Ident ident;
      DAE.Mod dmod;

    // Try to find in cache.
    case(cache,env,path,mod,msg) /* Should we only lookup if it is SCode.NOMOD? */
      equation
        (cache,(c as SCode.CLASS(name=cn2,encapsulatedPrefix=enc2,restriction=r)),cenv) = lookupClass(cache,env,path,msg);
        scope = Env.getEnvName(cenv);
        ident = Absyn.pathLastIdent(path);
       classEnv = Env.cacheGet(scope,Absyn.IDENT(ident),cache);
      then
        (cache,classEnv);

    // Not found in cache, lookup and instantiate.
    case(cache,env,path,mod,msg)
      equation
        // Debug.traceln("lookupAndInstantiate " +& Absyn.pathString(path) +& ", s:" +& Env.printEnvPathStr(env) +& "m:" +& SCodeDump.printModStr(mod));
        (cache,(c as SCode.CLASS(name=cn2,encapsulatedPrefix=enc2,restriction=r)),cenv) = lookupClass(cache, env, path, msg);
        cenv_2 = Env.openScope(cenv, enc2, SOME(cn2), Env.restrictionToScopeType(r));
        new_ci_state = ClassInf.start(r, Env.getEnvName(cenv_2));
        dmod = Mod.elabUntypedMod(mod,env,Prefix.NOPRE());
        //(cache,dmod,_ /* Return fn's here */) = Mod.elabMod(cache,env,Prefix.NOPRE(),mod,true); - breaks things but is needed for other things... bleh
        // Debug.traceln("dmod: " +& Mod.printModStr(dmod));
        // Debug.fprintln(Flags.INST_TRACE, "LOOKUP AND INST ICD: " +& Env.printEnvPathStr(cenv) +& "." +& cn2);
        (cache,classEnv,_,_) =
        Inst.partialInstClassIn(cache, cenv_2, InnerOuter.emptyInstHierarchy,
          dmod, Prefix.NOPRE(), new_ci_state, c, SCode.PUBLIC(), {});
      then
        (cache,classEnv);

    case(cache,env,path,mod,msg)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln( "- Lookup.lookupAndInstantiate failed " +&  Absyn.pathString(path) +& " with mod: " +& SCodeDump.printModStr(mod) +& " in scope " +& Env.printEnvPathStr(env));
     then
       fail();
  end matchcontinue;
end lookupAndInstantiate;

public function lookupIdent
"function: lookupIdent
  Same as lookupIdentLocal, except check all frames"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output DAE.Var outVar;
  output SCode.Element outElement;
  output DAE.Mod outMod;
  output Env.InstStatus instStatus;
  output Env.Env outEnv "the env where we found the ident";
algorithm
  (outCache,outVar,outElement,outMod,instStatus,outEnv):=
  matchcontinue (inCache,inEnv,inIdent)
    local
      DAE.Var fv;
      SCode.Element c;
      DAE.Mod m;
      Env.InstStatus i;
      Option<String> sid;
      Env.AvlTree ht;
      String id;
      Env.Env rest,e;
      Env.Cache cache;

    case (cache,(Env.FRAME(name = sid,clsAndVars = ht) :: _),id)
      equation
        (cache,fv,c,m,i,_) = lookupVar2(cache, ht, id);
      then
        (cache,fv,c,m,i,inEnv);

    case (cache,(_ :: rest),id)
      equation
        (cache,fv,c,m,i,e) = lookupIdent(cache, rest, id);
      then
        (cache,fv,c,m,i,e);

  end matchcontinue;
end lookupIdent;

// Function lookup
public function lookupFunctionsInEnv
"function: lookupFunctionsInEnv
  Returns a list of types that the function has."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inId;
  input Absyn.Info inInfo;
  output Env.Cache outCache;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  (outCache,outTypesTypeLst) := matchcontinue (inCache,inEnv,inId,inInfo)
    local
      Env.Env env_1;
      Env.Frame f;
      list<DAE.Type> res;
      list<Absyn.Path> names;
      Env.AvlTree httypes;
      Env.AvlTree ht;
      String str;
      Env.Cache cache;
      Env.Env env;
      Absyn.Path id;
      Absyn.Info info;

    // Builtin operators are looked up in top frame directly
    case (cache,env,(id as Absyn.IDENT(name = str)),info)
      equation
        _ = Static.elabBuiltinHandler(str) "Check for builtin operators" ;
        (cache,env as {Env.FRAME(clsAndVars = ht,types = httypes)}) = Builtin.initialEnv(cache);
        (cache,res) = lookupFunctionsInFrame(cache, ht, httypes, env, str, info);
      then
        (cache,res);

    // Check for special builtin operators that can not be represented in environment like for instance cardinality
    case (cache,_,id as Absyn.IDENT(name = str),_)
      equation
        _ = Static.elabBuiltinHandlerGeneric(str);
        (cache,env) = Builtin.initialEnv(cache);
        res = createGenericBuiltinFunctions(env, str);
      then
        (cache,res);

    // not fully qualified!
    case (cache,env,id,info)
      equation
        failure(Absyn.FULLYQUALIFIED(_) = id);
        (cache,res) = lookupFunctionsInEnv2(cache,env,id,false,info);
      then (cache,res);

    // fullyqual
    case (cache,env,Absyn.FULLYQUALIFIED(id),info)
      equation
        f = Env.topFrame(env);
        (cache,res) = lookupFunctionsInEnv2(cache,{f},id,true,info);
      then (cache,res);

    case (cache,env,id,info)
      equation
        (cache,SCode.CLASS(classDef=SCode.OVERLOAD(pathLst=names),info=info),env_1) = lookupClass(cache,env,id,false);
        (cache,res) = lookupFunctionsListInEnv(cache,env_1,names,info,{});
        // print(stringDelimitList(List.map(res,Types.unparseType),"\n###\n"));
      then (cache,res);

    case (cache,_,_,_) then (cache,{});

    case (_,_,id,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprintln(Flags.FAILTRACE, "lookupFunctionsInEnv failed on: " +& Absyn.pathString(id));
      then
        fail();

  end matchcontinue;
end lookupFunctionsInEnv;

public function lookupFunctionsListInEnv
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Path> inIds;
  input Absyn.Info info;
  input list<DAE.Type> inAcc;
  output Env.Cache outCache;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  (outCache,outTypesTypeLst) := matchcontinue (inCache,inEnv,inIds,info,inAcc)
    local
      Absyn.Path id;
      list<DAE.Type> res;
      String str;
      Env.Cache cache;
      Env.Env env;
      list<Absyn.Path> ids;
      list<DAE.Type> acc;

    case (cache,_,{},_,acc) then (cache,listReverse(acc));
    case (cache,env,id::ids,_,acc)
      equation
        (cache,res as _::_) = lookupFunctionsInEnv(cache,env,id,info);

        (cache,acc) = lookupFunctionsListInEnv(cache,env,ids,info,listAppend(res,acc));
      then (cache,acc);
    case (_,env,id::_,_,_)
      equation
        str = Absyn.pathString(id) +& " not found in scope: " +& Env.printEnvPathStr(env);
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, info);
      then fail();
  end matchcontinue;
end lookupFunctionsListInEnv;

protected function lookupFunctionsInEnv2
"function: lookupFunctionsInEnv
  Returns a list of types that the function has."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input Boolean followedQual "cannot pop frames if we followed a qualified path at any point";
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  (outCache,outTypesTypeLst) := matchcontinue (inCache,inEnv,inPath,followedQual,info)
    local
      Absyn.Path id,path;
      Option<String> sid;
      Env.AvlTree httypes;
      Env.AvlTree ht;
      list<DAE.Type> res;
      list<Env.Frame> env,fs,env_1,env2,env_2;
      String pack,str;
      SCode.Element c;
      SCode.Encapsulated encflag;
      SCode.Restriction restr;
      ClassInf.State ci_state,cistate1;
      Env.Frame f;
      Env.Cache cache;
      Env.FrameType frameTy;

    // Simple name, search frame
    case (cache,(env as (Env.FRAME(name = sid,clsAndVars = ht,types = httypes) :: fs)),id as Absyn.IDENT(name = str),_,_)
      equation
        (cache,res as _::_)= lookupFunctionsInFrame(cache, ht, httypes, env, str, info);
      then
        (cache,res);

    // Simple name, if class with restriction function found in frame instantiate to get type.
    case (cache, f::fs, id as Absyn.IDENT(name = str),_,_)
      equation
        // adrpo: do not search in the entire environment as we anyway recurse with the fs argument!
        //        just search in {f} not f::fs as otherwise we might get us in an infinite loop
        // Bjozac: Readded the f::fs search frame, otherwise we might get caught in a inifinite loop!
        //           Did not investigate this further then that it can crasch the kernel.
        (cache,(c as SCode.CLASS(name=str,encapsulatedPrefix=encflag,restriction=restr)),env_1) = lookupClass(cache,f::fs, id, false);
        true = SCode.isFunctionRestriction(restr);
        // get function dae from instantiation
        // Debug.fprintln(Flags.INST_TRACE, "LOOKUP FUNCTIONS IN ENV ID ICD: " +& Env.printEnvPathStr(env_1) +& "." +& str);
        (cache,(env_2 as (Env.FRAME(name = sid,clsAndVars = ht,types = httypes)::_)),_)
           = Inst.implicitFunctionTypeInstantiation(cache,env_1,InnerOuter.emptyInstHierarchy, c);

        (cache,res as _::_)= lookupFunctionsInFrame(cache, ht, httypes, env_2, str, info);
      then
        (cache,res);

    // For qualified function names, e.g. Modelica.Math.sin
    case (cache,(env as (Env.FRAME(name = sid,clsAndVars = ht,types = httypes) :: fs)),id as Absyn.QUALIFIED(name = pack,path = path),_,_)
      equation
        (cache,(c as SCode.CLASS(name=str,encapsulatedPrefix=encflag,restriction=restr)),env_1) = lookupClass(cache, env, Absyn.IDENT(pack), false) ;
        env2 = Env.openScope(env_1, encflag, SOME(str), Env.restrictionToScopeType(restr));
        ci_state = ClassInf.start(restr, Env.getEnvName(env2));

        // Debug.fprintln(Flags.INST_TRACE, "LOOKUP FUNCTIONS IN ENV QUAL ICD: " +& Env.printEnvPathStr(env2) +& "." +& str);
        (cache,env_2,_,cistate1) =
        Inst.partialInstClassIn(
          cache, env2, InnerOuter.emptyInstHierarchy,
          DAE.NOMOD(), Prefix.NOPRE(),
          ci_state, c, SCode.PUBLIC(), {});
        (cache,res) = lookupFunctionsInEnv2(cache, env_2, path, true, info);
      then
        (cache,res);

    // Did not match. Search next frame.
    case (cache,Env.FRAME(frameType = frameTy)::fs,id,false,_)
      equation
        false = valueEq(frameTy, Env.ENCAPSULATED_SCOPE());
        (cache,res) = lookupFunctionsInEnv2(cache, fs, id, false, info);
      then
        (cache,res);

    case (cache,Env.FRAME(frameType = Env.ENCAPSULATED_SCOPE())::env,id as Absyn.IDENT(name = str),false,_)
      equation
        (cache,env) = Builtin.initialEnv(cache);
        (cache,res) = lookupFunctionsInEnv2(cache, env, id, true, info);
      then
        (cache,res);

  end matchcontinue;
end lookupFunctionsInEnv2;

protected function createGenericBuiltinFunctions
"function: createGenericBuiltinFunctions
  author: PA
  This function creates function types on-the-fly for special builtin
  operators/functions which can not be represented in the builtin
  environment."
  input Env.Env inEnv;
  input String inString;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  outTypesTypeLst := match (inEnv,inString)
    local list<Env.Frame> env;

    // function_name cardinality
    case (env,"cardinality")
      then {DAE.T_FUNCTION(
              {("x",DAE.T_COMPLEX(ClassInf.CONNECTOR(Absyn.IDENT("$$"),false),{},NONE(),DAE.emptyTypeSource),DAE.C_VAR(),NONE())},
              DAE.T_INTEGER_DEFAULT,
              DAE.FUNCTION_ATTRIBUTES_DEFAULT,
              DAE.emptyTypeSource),
            DAE.T_FUNCTION(
              {("x",DAE.T_COMPLEX(ClassInf.CONNECTOR(Absyn.IDENT("$$"),true),{},NONE(),DAE.emptyTypeSource),DAE.C_VAR(),NONE())},
              DAE.T_INTEGER_DEFAULT,
              DAE.FUNCTION_ATTRIBUTES_DEFAULT,
              DAE.emptyTypeSource)};

  end match;
end createGenericBuiltinFunctions;

// - Internal functions
//   Type lookup

protected function lookupTypeInEnv
"function: lookupTypeInEnv"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output Env.Cache outCache;
  output DAE.Type outType;
  output Env.Env outEnv;
algorithm
  (outCache,outType,outEnv):=
  matchcontinue (inCache,inEnv,inPath)
    local
      DAE.Type c;
      list<Env.Frame> env_1,env,fs;
      Option<String> sid;
      Env.AvlTree httypes;
      Env.AvlTree ht;
      String id;
      Env.Frame f;
      Env.Cache cache;
      Absyn.Path path;

    case (cache,(env as (Env.FRAME(name = sid,clsAndVars = ht,types = httypes) :: fs)),Absyn.IDENT(name = id))
      equation
        (cache,c,env_1) = lookupTypeInFrame(cache, ht, httypes, env, id);
      then
        (cache,c,env_1);

    case (cache,f::fs,path)
      equation
        (cache,c,env_1) = lookupTypeInEnv(cache,fs,path);
      then
        (cache,c,(f :: env_1));
  end matchcontinue;
end lookupTypeInEnv;

protected function lookupTypeInFrame
"function: lookupTypeInFrame
  Searches a frame for a type."
  input Env.Cache inCache;
  input Env.AvlTree inBinTree1;
  input Env.AvlTree inBinTree2;
  input Env.Env inEnv3;
  input SCode.Ident inIdent4;
  output Env.Cache outCache;
  output DAE.Type outType;
  output Env.Env outEnv;
algorithm
  (outCache,outType,outEnv):=
  match (inCache,inBinTree1,inBinTree2,inEnv3,inIdent4)
    local
      DAE.Type t;
      Env.AvlTree httypes;
      Env.AvlTree ht;
      list<Env.Frame> env;
      String id;
      Env.Cache cache;
      Env.Item item;
    case (cache,ht,httypes,env,id)
      equation
        item = Env.avlTreeGet(httypes, id);
        (cache,t,env) = lookupTypeInFrame2(cache,item,env,id);
      then
        (cache,t,env);
  end match;
end lookupTypeInFrame;

protected function lookupTypeInFrame2
"function: lookupTypeInFrame
  Searches a frame for a type."
  input Env.Cache inCache;
  input Env.Item item;
  input Env.Env inEnv3;
  input SCode.Ident inIdent4;
  output Env.Cache outCache;
  output DAE.Type outType;
  output Env.Env outEnv;
algorithm
  (outCache,outType,outEnv):=
  match (inCache,item,inEnv3,inIdent4)
    local
      DAE.Type t,ty;
      list<Env.Frame> env,cenv,env_1,env_3;
      String id,n;
      SCode.Element cdef;
      Env.Cache cache;

    case (cache,Env.TYPE((t :: _)),env,id) then (cache,t,env);

    case (cache,Env.VAR(var = _),env,id)
      equation
        Error.addMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id});
      then
        fail();

    // Record constructor function
    case (cache,Env.CLASS((cdef as SCode.CLASS(name=n,restriction=SCode.R_RECORD())),cenv,_),env,id)
      equation
        (cache,env_3,ty) = buildRecordType(cache,env,cdef);
      then
        (cache,ty,env_3);

    case (cache,Env.CLASS((cdef as SCode.CLASS(name=n,restriction=SCode.R_METARECORD(index=_))),cenv,_),env,id)
      equation
        (cache,env_3,ty) = buildMetaRecordType(cache,cenv,cdef);
      then
        (cache,ty,env_3);

    // Found function
    case (cache,Env.CLASS((cdef as SCode.CLASS(restriction=SCode.R_FUNCTION(_))),cenv,_),env,id)
      equation
        // Debug.fprintln(Flags.INST_TRACE, "LOOKUP TYPE IN FRAME ICD: " +& Env.printEnvPathStr(env) +& " id:" +& id);

        // select the env if is the same as cenv as is updated!
        cenv = selectUpdatedEnv(env, cenv);

        (cache ,env_1,_) = Inst.implicitFunctionInstantiation(
          cache,cenv,InnerOuter.emptyInstHierarchy,
          DAE.NOMOD(), Prefix.NOPRE(), cdef, {});

        (cache,ty,env_3) = lookupTypeInEnv(cache, env_1, Absyn.IDENT(id));
      then
        (cache,ty,env_3);

  end match;
end lookupTypeInFrame2;

protected function lookupFunctionsInFrame
"function: lookupFunctionsInFrame
  This actually only looks up the function name and find all
  corresponding types that have this function name."
  input Env.Cache inCache;
  input Env.AvlTree inBinTree1;
  input Env.AvlTree inBinTree2;
  input Env.Env inEnv3;
  input SCode.Ident inIdent4;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  (outCache,outTypesTypeLst) := matchcontinue (inCache,inBinTree1,inBinTree2,inEnv3,inIdent4,info)
    local
      list<DAE.Type> tps;
      Env.AvlTree httypes;
      Env.AvlTree ht;
      list<Env.Frame> env,cenv,env_1;
      String id,n;
      SCode.Element cdef;
      DAE.Type ftype,t;
      DAE.Type tty;
      Env.Cache cache;
      SCode.Restriction restr;

    // Classes and vars Types
    case (cache,ht,httypes,env,id,_)
      equation
        Env.TYPE(tps) = Env.avlTreeGet(httypes, id);
      then
        (cache,tps);

    // MetaModelica Partial Function. sjoelund
    case (cache,ht,httypes,env,id,_)
      equation
        Env.VAR(instantiated = DAE.TYPES_VAR(ty = tty as DAE.T_FUNCTION(funcArg = _))) = Env.avlTreeGet(ht, id);
        tty = Types.setTypeSource(tty, Types.mkTypeSource(SOME(Absyn.IDENT(id))));
      then
        (cache,{tty});

    case (cache,ht,httypes,env,id,_)
      equation
        Env.VAR(var = _) = Env.avlTreeGet(ht, id);
        Error.addSourceMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id}, info);
      then
        fail();

    // Records, create record constructor function
    case (cache,ht,httypes,env,id,_)
      equation
        Env.CLASS((cdef as SCode.CLASS(name=n,restriction=SCode.R_RECORD())),cenv,_) = Env.avlTreeGet(ht, id);
        (cache,_,ftype) = buildRecordType(cache,env,cdef);
      then
        (cache,{ftype});

    // Found class that is function, instantiate to get type
    case (cache,ht,httypes,env,id,_)
      equation
        Env.CLASS((cdef as SCode.CLASS(restriction=restr)),cenv,_) = Env.avlTreeGet(ht, id);
        true = SCode.isFunctionRestriction(restr) "If found class that is function.";

        // select the env if is the same as cenv as is updated!
        cenv = selectUpdatedEnv(env, cenv);

        //function dae collected from instantiation
        // Debug.fprintln(Flags.INST_TRACE, "LOOKUP FUNCTIONS IN FRAME ICD: " +& Env.printEnvPathStr(env) +& "." +& id);
        (cache,env_1,_) =
        Inst.implicitFunctionTypeInstantiation(cache,cenv,InnerOuter.emptyInstHierarchy,cdef) ;

        (cache,tps) = lookupFunctionsInEnv2(cache,env_1,Absyn.IDENT(id),true,info);
      then
        (cache,tps);

    // Found class that is is external object
    case (cache,ht,httypes,env,id,_)
      equation
        Env.CLASS(cdef,cenv,_) = Env.avlTreeGet(ht, id);
        true = Inst.classIsExternalObject(cdef);

        // select the env if is the same as cenv as is updated!
        cenv = selectUpdatedEnv(env, cenv);

        // Debug.fprintln(Flags.INST_TRACE, "LOOKUP FUNCTIONS IN FRAME ICD: " +& Env.printEnvPathStr(env) +& "." +& id);
        (cache,env_1,_,_,_,_,t,_,_,_) =
          Inst.instClass(cache,cenv,InnerOuter.emptyInstHierarchy,UnitAbsyn.noStore,
            DAE.NOMOD(), Prefix.NOPRE(), cdef, {}, false, Inst.TOP_CALL(),
            ConnectionGraph.EMPTY, Connect.emptySet);
        (cache,t,_) = lookupTypeInEnv(cache,env_1, Absyn.IDENT(id));
        // s = Types.unparseType(t);
        // print("type :");print(s);print("\n");
      then
        (cache,{t});

  end matchcontinue;
end lookupFunctionsInFrame;

public function selectUpdatedEnv
  input Env.Env inNewEnv;
  input Env.Env inOldEnv;
  output Env.Env outEnv;
algorithm
  outEnv := matchcontinue(inNewEnv, inOldEnv)
    local Env.Env env;

    // return old if is top scope!
    case (_, _)
      equation
        true = Env.isTopScope(inNewEnv);
      then
        inOldEnv;
    // if they point to the same env, return the new one
    case (_, _)
      equation
        true = stringEq(Env.getEnvNameStr(inNewEnv),
                        Env.getEnvNameStr(inOldEnv));
      then
        inNewEnv;

    else then inOldEnv;
  end matchcontinue;
end selectUpdatedEnv;

protected function buildRecordType ""
  input Env.Cache cache;
  input Env.Env env;
  input SCode.Element icdef;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output Types.Type ftype;
protected
  String name;
  Env.Env env_1;
  SCode.Element cdef;
algorithm
  (outCache,_,cdef) := buildRecordConstructorClass(cache,env,icdef);
  name := SCode.className(cdef);
  // Debug.fprintln(Flags.INST_TRACE", "LOOKUP BUILD RECORD TY ICD: " +& Env.printEnvPathStr(env) +& "." +& name);
  (outCache,outEnv,_) := Inst.implicitFunctionTypeInstantiation(
     outCache,env,InnerOuter.emptyInstHierarchy, cdef);
  (outCache,ftype,_) := lookupTypeInEnv(outCache,outEnv,Absyn.IDENT(name));
end buildRecordType;

public function buildRecordConstructorClass
"function: buildRecordConstructorClass

  Creates the record constructor class, i.e. a function, from the record
  class given as argument."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.Element inClass;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output SCode.Element outClass;
algorithm
  (outCache,outEnv,outClass) :=
  matchcontinue (inCache,inEnv,inClass)
    local
      list<SCode.Element> funcelts,elts;
      SCode.Element reselt;
      SCode.Element cl;
      String id;
      Absyn.Info info;
      Env.Cache cache;
      Env.Env env;

    case (cache,env,cl as SCode.CLASS(name=id,info=info))
      equation
        (cache,env,funcelts,elts) = buildRecordConstructorClass2(cache,env,cl,DAE.NOMOD());
        reselt = buildRecordConstructorResultElt(funcelts,id,env,info);
        cl = SCode.CLASS(id,SCode.defaultPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_FUNCTION(SCode.FR_RECORD_CONSTRUCTOR()),SCode.PARTS((reselt :: funcelts),{},{},{},{},{},{},NONE(),{},NONE()),info);
      then
        (cache,env,cl);
    case (cache,env,cl)
      equation
        Debug.fprintln(Flags.FAILTRACE,"buildRecordConstructorClass failed");
      then fail();
  end matchcontinue;
end buildRecordConstructorClass;

protected function buildRecordConstructorClass2
  input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.Element cl;
  input DAE.Mod mods;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output list<SCode.Element> funcelts;
  output list<SCode.Element> elts;
algorithm
  (outCache,outEnv,funcelts,elts) := matchcontinue(inCache,inEnv,cl,mods)
    local
      list<SCode.Element> cdefelts,classExtendsElts,extendsElts,compElts;
      list<tuple<SCode.Element,DAE.Mod>> eltsMods;
      String name;
      Absyn.Path fpath;
      Absyn.Info info;
      Env.Cache cache;
      Env.Env env,env1;

    /* a class with parts */
    case (cache,env,SCode.CLASS(name = name,info = info),_)
      equation
        (cache,env,_,elts,_,_,_,_) = InstExtends.instDerivedClasses(cache,env,InnerOuter.emptyInstHierarchy,DAE.NOMOD(),Prefix.NOPRE(),cl,true,info);
        env = Env.openScope(env, SCode.NOT_ENCAPSULATED(), SOME(name), SOME(Env.CLASS_SCOPE()));
        fpath = Env.getEnvName(env);
        (cdefelts,classExtendsElts,extendsElts,compElts) = Inst.splitElts(elts);
        (_,env,_,_,eltsMods,_,_,_,_) = InstExtends.instExtendsAndClassExtendsList(Env.emptyCache(), env, InnerOuter.emptyInstHierarchy, DAE.NOMOD(), Prefix.NOPRE(), extendsElts, classExtendsElts, ClassInf.RECORD(fpath), name, true, false);
        eltsMods = listAppend(eltsMods,Inst.addNomod(compElts));
        // print("Record Elements: " +&
        //   stringDelimitList(
        //     List.map(
        //       List.map(
        //         eltsMods,
        //         Util.tuple21),
        //       SCodeDump.printElementStr), "\n"));
        (env1,_) = Inst.addClassdefsToEnv(env, InnerOuter.emptyInstHierarchy, Prefix.NOPRE(), cdefelts, false, NONE());
        (_,env1,_) = Inst.addComponentsToEnv(Env.emptyCache(),env1,InnerOuter.emptyInstHierarchy,mods,Prefix.NOPRE(),ClassInf.RECORD(fpath),eltsMods,eltsMods,{},{},true);
        funcelts = buildRecordConstructorElts(eltsMods,mods,env1);
      then (cache,env1,funcelts,elts);

    // fail
    case(cache,env,_,_) equation
      Debug.traceln("buildRecordConstructorClass2 failed, cl:"+&SCodeDump.printClassStr(cl)+&"\n");
    then fail();
      /* TODO: short class defs */
  end matchcontinue;
end buildRecordConstructorClass2;

protected function selectModifier
"@author: adrpo
 if the first modifier is empty (NOMOD) use the second one!"
  input DAE.Mod inModID;
  input DAE.Mod inModNoID;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue (inModID, inModNoID)
    case (DAE.NOMOD(),_) then inModNoID;
    case (_, _) then inModID;
  end matchcontinue;
end selectModifier;

protected function buildRecordConstructorElts
"function: buildRecordConstructorElts
  Helper function to build_record_constructor_class. Creates the elements
  of the function class.

  TODO: This function should be replaced by a proper instantiation using instClassIn instead, followed by a
  traversal of the DAE.Var changing direction to input.
  Reason for not doing that now: records can contain arrays with unknown dimensions."
  input list<tuple<SCode.Element,DAE.Mod>> inSCodeElementLst;
  input DAE.Mod mods;
  input Env.Env env;
  output list<SCode.Element> outSCodeElementLst;
algorithm
  outSCodeElementLst := matchcontinue (inSCodeElementLst,mods,env)
    local
      list<tuple<SCode.Element,DAE.Mod>> rest;
      list<SCode.Element> res;
      SCode.Element comp;
      String id;
      SCode.ConnectorType ct;
      SCode.Replaceable repl;
      SCode.Visibility vis;
      SCode.Final f;
      SCode.Redeclare redecl;
      Absyn.InnerOuter io;
      list<Absyn.Subscript> d;
      SCode.Parallelism prl;
      SCode.Variability var;
      Absyn.Direction dir;
      Absyn.TypeSpec tp;
      Option<SCode.Comment> comment;
      Option<Absyn.Exp> cond;
      SCode.Mod mod,umod;
      DAE.Mod mod_1, compMod, fullMod, selectedMod, cmod;
      Absyn.Info info;

    case ({},_,_) then {};

    // final becomes protected, Modelica Spec 3.2, Section 12.6, Record Constructor Functions, page 140
    case ((((comp as
      SCode.COMPONENT(
        id,
        SCode.PREFIXES(vis, redecl, f as SCode.FINAL(), io, repl),
        SCode.ATTR(d,ct,prl,var,dir),tp,mod,comment,cond,info)),cmod) :: rest),_,_)
      equation
        (_,mod_1) = Mod.elabMod(Env.emptyCache(), env, InnerOuter.emptyInstHierarchy, Prefix.NOPRE(), mod, true, info);
        mod_1 = Mod.merge(mods,mod_1,env,Prefix.NOPRE());
        // adrpo: this was wrong, you won't find any id modification there!!!
        // bjozac: This was right, you will find id modification unless modifers does not belong to component!
        // adrpo 2009-11-23 -> solved by selecting the full modifier if the component modifier is empty!
        compMod = Mod.lookupModificationP(mod_1,Absyn.IDENT(id));
        fullMod = mod_1;
        selectedMod = selectModifier(compMod, fullMod); // if the first one is empty use the other one.
        (_,cmod) = Mod.updateMod(Env.emptyCache(),env,InnerOuter.emptyInstHierarchy,Prefix.NOPRE(),cmod,true,info);
        selectedMod = Mod.merge(cmod,selectedMod,env,Prefix.NOPRE());
        umod = Mod.unelabMod(selectedMod);
        res = buildRecordConstructorElts(rest, mods, env);
        // - Prefixes (constant, parameter, final, discrete, input, output, ...) of the remaining record components are removed.
        // adrpo: 2010-11-09 : TODO! FIXME! why is this?? keep the variability!
        // mahge: 2013-01-15 : direction should be set to bidir.
        // var = SCode.VAR();
        dir = Absyn.BIDIR();
        vis = SCode.PROTECTED();
      then
        (SCode.COMPONENT(id,SCode.PREFIXES(vis,redecl, f,io,repl),SCode.ATTR(d,ct,prl,var,dir),tp,umod,comment,cond,info) :: res);

    // constants become protected, Modelica Spec 3.2, Section 12.6, Record Constructor Functions, page 140
    // mahge: 2013-01-15 : only if they have bindings. otherwise they are still modifiable.
    case ((((comp as
      SCode.COMPONENT(
        id,
        SCode.PREFIXES(vis, redecl, f, io, repl),
        SCode.ATTR(d,ct,prl,var as SCode.CONST(),dir),tp,mod as SCode.NOMOD(),comment,cond,info)), cmod) :: rest),_,_)
      equation
        (_,mod_1) = Mod.elabMod(Env.emptyCache(), env, InnerOuter.emptyInstHierarchy, Prefix.NOPRE(), mod, true, info);
        mod_1 = Mod.merge(mods,mod_1,env,Prefix.NOPRE());
        // adrpo: this was wrong, you won't find any id modification there!!!
        // bjozac: This was right, you will find id modification unless modifers does not belong to component!
        // adrpo 2009-11-23 -> solved by selecting the full modifier if the component modifier is empty!
        compMod = Mod.lookupModificationP(mod_1,Absyn.IDENT(id));
        fullMod = mod_1;
        selectedMod = selectModifier(compMod, fullMod); // if the first one is empty use the other one.
        (_,cmod) = Mod.updateMod(Env.emptyCache(),env,InnerOuter.emptyInstHierarchy,Prefix.NOPRE(),cmod,true,info);
        selectedMod = Mod.merge(cmod,selectedMod,env,Prefix.NOPRE());
        umod = Mod.unelabMod(selectedMod);
        res = buildRecordConstructorElts(rest, mods, env);
        // - Prefixes (constant, parameter, final, discrete, input, output, ...) of the remaining record components are removed.
        // adrpo: 2010-11-09 : TODO! FIXME! why is this?? keep the variability!
        var = SCode.VAR();
        dir = Absyn.INPUT();
        vis = SCode.PUBLIC();
        f = SCode.NOT_FINAL();
      then
        (SCode.COMPONENT(id,SCode.PREFIXES(vis,redecl,f,io,repl),SCode.ATTR(d,ct,prl,var,dir),tp,umod,comment,cond,info) :: res);


    case ((((comp as
      SCode.COMPONENT(
        id,
        SCode.PREFIXES(vis, redecl, f, io, repl),
        SCode.ATTR(d,ct,prl,var as SCode.CONST(),dir),tp,mod,comment,cond,info)),cmod) :: rest),_,_)
      equation
        (_,mod_1) = Mod.elabMod(Env.emptyCache(), env, InnerOuter.emptyInstHierarchy, Prefix.NOPRE(), mod, true, info);
        mod_1 = Mod.merge(mods,mod_1,env,Prefix.NOPRE());
        // adrpo: this was wrong, you won't find any id modification there!!!
        // bjozac: This was right, you will find id modification unless modifers does not belong to component!
        // adrpo 2009-11-23 -> solved by selecting the full modifier if the component modifier is empty!
        compMod = Mod.lookupModificationP(mod_1,Absyn.IDENT(id));
        fullMod = mod_1;
        selectedMod = selectModifier(compMod, fullMod); // if the first one is empty use the other one.
        (_,cmod) = Mod.updateMod(Env.emptyCache(),env,InnerOuter.emptyInstHierarchy,Prefix.NOPRE(),cmod,true,info);
        selectedMod = Mod.merge(cmod,selectedMod,env,Prefix.NOPRE());
        umod = Mod.unelabMod(selectedMod);
        res = buildRecordConstructorElts(rest, mods, env);
        // - Prefixes (constant, parameter, final, discrete, input, output, ...) of the remaining record components are removed.
        // adrpo: 2010-11-09 : TODO! FIXME! why is this?? keep the variability!
        // mahge: 2013-01-15 : direction should be set to bidir.
        // var = SCode.VAR();
        dir = Absyn.BIDIR();
        vis = SCode.PROTECTED();
      then
        (SCode.COMPONENT(id,SCode.PREFIXES(vis,redecl,f,io,repl),SCode.ATTR(d,ct,prl,var,dir),tp,umod,comment,cond,info) :: res);

    // all others, add input see Modelica Spec 3.2, Section 12.6, Record Constructor Functions, page 140
    case ((((comp as
      SCode.COMPONENT(
        id,
        SCode.PREFIXES(vis, redecl, f, io, repl),
        SCode.ATTR(d,ct,prl,var,dir),tp,mod,comment,cond,info)),cmod) :: rest),_,_)
      equation
        (_,mod_1) = Mod.elabMod(Env.emptyCache(), env, InnerOuter.emptyInstHierarchy, Prefix.NOPRE(), mod, true, info);
        mod_1 = Mod.merge(mods,mod_1,env,Prefix.NOPRE());
        // adrpo: this was wrong, you won't find any id modification there!!!
        // bjozac: This was right, you will find id modification unless modifers does not belong to component!
        // adrpo 2009-11-23 -> solved by selecting the full modifier if the component modifier is empty!
        compMod = Mod.lookupModificationP(mod_1,Absyn.IDENT(id));
        fullMod = mod_1;
        selectedMod = selectModifier(compMod, fullMod); // if the first one is empty use the other one.
        (_,cmod) = Mod.updateMod(Env.emptyCache(),env,InnerOuter.emptyInstHierarchy,Prefix.NOPRE(),cmod,true,info);
        selectedMod = Mod.merge(cmod,selectedMod,env,Prefix.NOPRE());
        umod = Mod.unelabMod(selectedMod);
        res = buildRecordConstructorElts(rest, mods, env);
        // - Prefixes (constant, parameter, final, discrete, input, output, ...) of the remaining record components are removed.
        // adrpo: 2010-11-09 : TODO! FIXME! why is this?? keep the variability!
        var = SCode.VAR();
        vis = SCode.PUBLIC();
        f = SCode.NOT_FINAL();
        dir = Absyn.INPUT();
      then
        (SCode.COMPONENT(id,SCode.PREFIXES(vis, redecl, f, io, repl),SCode.ATTR(d,ct,prl,var,dir),tp,umod,comment,cond,info) :: res);

    case ((comp,cmod)::_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Lookup.buildRecordConstructorElts failed " +& SCodeDump.printElementStr(comp) +& " with mod: " +& Mod.printModStr(cmod) +& " and: " +& Mod.printModStr(mods));
      then fail();
  end matchcontinue;
end buildRecordConstructorElts;

protected function buildRecordConstructorResultElt
"function: buildRecordConstructorResultElt
  This function builds the result element of a
  record constructor function, i.e. the returned variable"
  input list<SCode.Element> elts;
  input SCode.Ident id;
  input Env.Env env;
  input Absyn.Info info;
  output SCode.Element outElement;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  //print(" creating element of type: " +& id +& "\n");
  //print(" with generated mods:" +& SCode.printSubs1Str(submodlst) +& "\n");
  //print(" creating element of type: " +& id +& "\n");
  //print(" with generated mods:" +& SCode.printSubs1Str(submodlst) +& "\n");
  outElement := SCode.COMPONENT("result",SCode.defaultPrefixes,
          SCode.ATTR({},SCode.POTENTIAL(),SCode.NON_PARALLEL(),SCode.VAR(),Absyn.OUTPUT()),
          Absyn.TPATH(Absyn.IDENT(id),NONE()),
          SCode.NOMOD(),NONE(),NONE(),info);
end buildRecordConstructorResultElt;

public function isInBuiltinEnv
"class lookup
 function: isInBuiltinEnv
  Returns true if function can be found in the builtin environment."
  input Env.Cache inCache;
  input Absyn.Path inPath;
  output Env.Cache outCache;
  output Boolean outBoolean;
algorithm
  (outCache,outBoolean) := matchcontinue (inCache,inPath)
    local
      list<Env.Frame> i_env;
      Absyn.Path path;
      Env.Cache cache;
      SCode.FunctionRestriction funcRest;

    case (cache,path)
      equation
        (cache,i_env) = Builtin.initialEnv(cache);
        (cache,SCode.CLASS(restriction = SCode.R_FUNCTION(funcRest)),_) = lookupClass(cache,i_env,path,false);
        // External functions without external declaration have parts. We don't consider them builtin.
        false = SCode.isExternalFunctionRestriction(funcRest);
      then (cache,false);

    case (cache,path)
      equation
        (cache,i_env) = Builtin.initialEnv(cache);
        (cache,_::_) = lookupFunctionsInEnv2(cache,i_env,path,true,Absyn.dummyInfo);
      then
        (cache,true);
    case (cache,path) then (cache,false);
  end matchcontinue;
end isInBuiltinEnv;

protected function lookupClassInEnv
 "Helper function to lookupClass2. Searches the environment for the class.
  It first checks the current scope, and then base classes. The specification
  says that we first search elements in the current scope (+ the ones inherited
  from base classes)"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input String id;
  input list<Env.Frame> inPrevFrames;
  input Util.StatefulBoolean inState;
  input Boolean inMsg;
  output Env.Cache outCache;
  output SCode.Element outClass;
  output Env.Env outEnv;
  output list<Env.Frame> outPrevFrames;
algorithm
  (outCache,outClass,outEnv,outPrevFrames) := matchcontinue (inCache,inEnv,id,inPrevFrames,inState,inMsg)
    local
      SCode.Element c;
      list<Env.Frame> env_1,env,fs,i_env,prevFrames;
      Env.Frame frame;
      String sid,scope;
      Boolean msg,msgflag;
      Env.Cache cache;
      Env.FrameType frameTy;

    case (cache,env as (frame::_),_,prevFrames,_,msg)
      equation
        (cache,c,env_1,prevFrames) = lookupClassInFrame(cache, frame, env, id, prevFrames, inState, msg);
        Util.setStatefulBoolean(inState,true);
      then
        (cache,c,env_1,prevFrames);

    case (cache,(env as ((frame as Env.FRAME(name = SOME(sid),frameType = Env.ENCAPSULATED_SCOPE())) :: fs)),_,prevFrames,_,_)
      equation
        true = stringEq(id, sid) "Special case if looking up the class that -is- encapsulated. That must be allowed." ;
        (cache,c,env,prevFrames) = lookupClassInEnv(cache, fs, id, frame::prevFrames, inState, true);
        Util.setStatefulBoolean(inState,true);
      then
        (cache,c,env,prevFrames);

    // lookup stops at encapsulated classes except for builtin
    // scope, if not found in builtin scope, error
    case (cache,(env as (Env.FRAME(name = SOME(sid),frameType = Env.ENCAPSULATED_SCOPE()) :: fs)),_,prevFrames,_,true)
      equation
        (cache,i_env) = Builtin.initialEnv(cache);
        failure((_,_,_,_) = lookupClassInEnv(cache, i_env, id, {}, inState, false));
        scope = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_ERROR, {id,scope});
      then
        fail();

    // lookup stops at encapsulated classes, except for builtin scope
    case (cache,(Env.FRAME(frameType = Env.ENCAPSULATED_SCOPE()) :: fs),_,prevFrames,_,msgflag)
      equation
        (cache,i_env) = Builtin.initialEnv(cache);
        (cache,c,env_1,prevFrames) = lookupClassInEnv(cache, i_env, id, {}, inState, msgflag);
        Util.setStatefulBoolean(inState,true);
      then
        (cache,c,env_1,prevFrames);

    // if not found and not encapsulated, and no ident has been previously found, look in next enclosing scope
    case (cache,(frame as Env.FRAME(name = SOME(_), frameType = frameTy)) :: fs,_,prevFrames,_,msgflag)
      equation
        false = valueEq(frameTy, Env.ENCAPSULATED_SCOPE());
        false = Util.getStatefulBoolean(inState);
        (cache,c,env_1,prevFrames) = lookupClassInEnv(cache, fs, id, frame::prevFrames, inState, msgflag);
        Util.setStatefulBoolean(inState, true);
      then
        (cache,c,env_1,prevFrames);

  end matchcontinue;
end lookupClassInEnv;

protected function lookupClassInFrame "function: lookupClassInFrame
  Search for a class within one frame."
  input Env.Cache inCache;
  input Env.Frame inFrame;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  input list<Env.Frame> inPrevFrames;
  input Util.StatefulBoolean inState;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output SCode.Element outClass;
  output Env.Env outEnv;
  output list<Env.Frame> outPrevFrames;
algorithm
  (outCache,outClass,outEnv,outPrevFrames) := matchcontinue (inCache,inFrame,inEnv,inIdent,inPrevFrames,inState,inBoolean)
    local
      SCode.Element c;
      list<Env.Frame> totenv,env_1,prevFrames;
      Option<String> sid;
      Env.AvlTree ht;
      String name;
      list<Absyn.Import> imports;
      Env.ImportTable importTable;
      Env.Cache cache;
      Boolean unique;

    // Check this scope for class
    case (cache,Env.FRAME(name = sid,clsAndVars = ht),totenv,name,prevFrames,_,_)
      equation
        Env.CLASS(c,_,_) = Env.avlTreeGet(ht, name);
      then
        (cache,c,totenv,prevFrames);

    // Search among the qualified imports, e.g. import A.B; or import D=A.B;
    case (cache,Env.FRAME(name = sid,importTable = importTable),totenv,name,_,_,_)
      equation
        imports = getQualifiedImports(importTable);
        (cache,c,env_1,prevFrames) = lookupQualifiedImportedClassInFrame(cache,imports,totenv,name,inState);
      then
        (cache,c,env_1,prevFrames);

    // Search among the unqualified imports, e.g. import A.B.*;
    case (cache,Env.FRAME(name = sid,importTable = importTable),totenv,name,_,_,_)
      equation
        imports = getUnQualifiedImports(importTable);
        (cache,c,env_1,prevFrames,unique) = lookupUnqualifiedImportedClassInFrame(cache,imports,totenv,name);
        Util.setStatefulBoolean(inState,true);
        reportSeveralNamesError(unique,name);
      then
        (cache,c,env_1,prevFrames);

  end matchcontinue;
end lookupClassInFrame;

protected function lookupClassAssertClass
"Asserts that item is Class (which is returned.
 If component is found, this is reported as an error"
  input Env.Item item;
  output SCode.Element c;
algorithm
  c := matchcontinue(item)
    local String id;

    case(Env.CLASS(cls =  c)) then c;

    // Searching for class, found component
    case(Env.VAR(instantiated = DAE.TYPES_VAR(name=id)))
      equation
        Error.addMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id});
      then
        fail();
  end matchcontinue;
end lookupClassAssertClass;

protected function reportSeveralNamesError
"given a boolean, report error message of importing several names
if boolean flag is false and fail. If flag is true succeed and do nothing."
  input Boolean unique;
  input String name;
algorithm
  _ := match(unique,name)

    case(true,_) then ();

    case(false,_)
      equation
        Error.addMessage(Error.IMPORT_SEVERAL_NAMES, {name});
      then ();

  end match;
end reportSeveralNamesError;

protected function lookupVar2
"function: lookupVar2
  Helper function to lookupVarF and lookupIdent."
  input Env.Cache inCache;
  input Env.AvlTree inBinTree;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output DAE.Var outVar;
  output SCode.Element outElement;
  output DAE.Mod outMod;
  output Env.InstStatus instStatus;
  output Env.Env outEnv;
algorithm
  (outCache,outVar,outElement,outMod,instStatus,outEnv):=
  matchcontinue (inCache,inBinTree,inIdent)
    local
      DAE.Var fv;
      SCode.Element c;
      DAE.Mod m;
      Env.InstStatus i;
      list<Env.Frame> env;
      Env.AvlTree ht;
      String id, name;
      Env.Cache cache;
      SCode.Restriction r;

    case (cache, ht, id)
      equation
        Env.VAR(fv,c,m,i,env,_) = Env.avlTreeGet(ht, id);
      then
        (cache,fv,c,m,i,env);

    case (cache, ht, id)
      equation
        true = Flags.isSet(Flags.LOOKUP);
        false = Config.acceptMetaModelicaGrammar(); // MetaModelica function references generate too much failtrace...
        Env.CLASS(SCode.CLASS(name = name, restriction = r), env, _) = Env.avlTreeGet(ht, id);
        name = id +& " = " +& Env.printEnvPathStr(env) +& "." +& name;
        Debug.traceln("- Lookup.lookupVar2 failed because we find a class instead of a variable: " +& name);
      then
        fail();

  end matchcontinue;
end lookupVar2;

protected function checkSubscripts "function: checkSubscripts
  This function checks a list of subscripts agains type, and removes
  dimensions from the type according to the subscripting."
  input DAE.Type inType;
  input list<DAE.Subscript> inExpSubscriptLst;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inType,inExpSubscriptLst)
    local
      DAE.Type t,t_1;
      DAE.Dimension dim;
      DAE.TypeSource ts;
      list<DAE.Subscript> ys,s;
      Integer sz,ind,dim_int;
      list<DAE.Exp> se;
      DAE.Exp e;

    // empty case
    case (t,{}) then t;

    case (DAE.T_ARRAY(dims = {dim},ty = t,source = ts),(DAE.WHOLEDIM() :: ys))
      equation
        t_1 = checkSubscripts(t, ys);
      then
        DAE.T_ARRAY(t_1,{dim},ts);

    case (DAE.T_ARRAY(dims = {dim}, ty = t, source = ts),
          (DAE.SLICE(exp = DAE.ARRAY(array = se)) :: ys))
      equation
        sz = Expression.dimensionSize(dim);
        t_1 = checkSubscripts(t, ys);
        dim_int = listLength(se) "FIXME: Check range IMPLEMENTED 2007-05-18 BZ" ;
        true = (dim_int <= sz);
        true = checkSubscriptsRange(se,sz);
      then
        DAE.T_ARRAY(t_1,{DAE.DIM_INTEGER(dim_int)},ts);

    case (DAE.T_ARRAY(dims = {_}, ty = t, source = ts),
          (DAE.SLICE(exp = e) :: ys))
      equation
        DAE.T_ARRAY(dims={dim}) = Expression.typeof(e);
        t_1 = checkSubscripts(t, ys);
      then
        DAE.T_ARRAY(t_1, {dim}, ts);

    case (DAE.T_ARRAY(dims = {dim}, ty = t, source = ts),
          (DAE.INDEX(exp = DAE.ICONST(integer = ind)) :: ys))
      equation
        sz = Expression.dimensionSize(dim);
        (ind > 0) = true;
        (ind <= sz) = true;
        t_1 = checkSubscripts(t, ys);
      then
        t_1;

    // HJ: Subscripts needn't be constant. No range-checking can be done
    case (DAE.T_ARRAY(dims = {dim}, ty = t),
          (DAE.INDEX(exp = e) :: ys))
      equation
        true = Expression.dimensionKnown(dim);
        t_1 = checkSubscripts(t, ys);
      then
        t_1;

    case (DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()}, ty = t),
          (DAE.INDEX(exp = _) :: ys))
      equation
        t_1 = checkSubscripts(t, ys);
      then
        t_1;

    case (DAE.T_ARRAY(dims = {DAE.DIM_EXP(exp = _)}, ty = t),
          (DAE.INDEX(exp = _) :: ys))
      equation
        t_1 = checkSubscripts(t, ys);
      then
        t_1;

    case (DAE.T_ARRAY(ty = t),
          (DAE.WHOLEDIM() :: ys))
      equation
        t_1 = checkSubscripts(t, ys);
      then
        t_1;

    case (DAE.T_SUBTYPE_BASIC(complexType = t),ys)
      then checkSubscripts(t,ys);

    case(t as DAE.T_UNKNOWN(_), _) then t;

    case (t,s)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprint(Flags.FAILTRACE, "- Lookup.checkSubscripts failed (tp: ");
        Debug.fprint(Flags.FAILTRACE, Types.printTypeStr(t));
        Debug.fprint(Flags.FAILTRACE, " subs:");
        Debug.fprint(Flags.FAILTRACE, stringDelimitList(List.map(s,ExpressionDump.printSubscriptStr),","));
        Debug.fprint(Flags.FAILTRACE, ")\n");
      then
        fail();
  end matchcontinue;
end checkSubscripts;

protected function checkSubscriptsRange "
Checks that each subscript stays in the dimensional range.
"
  input list<DAE.Exp> inExpSubscriptLst;
  input Integer dimensions;
  output Boolean inRange;
algorithm
  inRange:=
  matchcontinue(inExpSubscriptLst, dimensions)
    local
      DAE.Exp exp;
      list<DAE.Exp> expl;
      Integer dims;
      Boolean res;
      String str1,str2;
    case(expl,dims)
      equation
        res = checkSubscriptsRange2(expl,dims);
      then res;
    case(expl,dims)
      equation
        str2 = intString(dims);
        exp = DAE.ARRAY(DAE.T_INTEGER_DEFAULT,false,expl);
        str1 = stringDelimitList(List.map(expl,ExpressionDump.printExpStr)," and position " );
        Error.addMessage(Error.ARRAY_INDEX_OUT_OF_BOUNDS,{str1,str2});
      then
        false;
  end matchcontinue;
end checkSubscriptsRange;

protected function checkSubscriptsRange2
""
  input list<DAE.Exp> inExpSubscriptLst;
  input Integer dimensions;
  output Boolean inRange;
algorithm
  inRange := matchcontinue(inExpSubscriptLst, dimensions)
    local
      DAE.Exp exp;
      list<DAE.Exp> expl;
      Integer x,dims;

    case({},_) then true;

    // Constant index
    case (exp :: expl, dims)
      equation
        x = Expression.expInt(exp);
        true = (x<=dims);
        true = checkSubscriptsRange2(expl,dims);
      then
        true;

    // Variable index, can't check at compile time.
    case (exp :: expl, dims)
      equation
        failure(x = Expression.expInt(exp));
        true = checkSubscriptsRange2(expl, dims);
      then
        true;

   end matchcontinue;
end checkSubscriptsRange2;

protected function lookupVarF
"function: lookupVarF
  This function looks in a frame to find a declared variable.  If
  the name being looked up is qualified, the first part of the name
  is looked up, and lookupVar2 is used to for further lookup in
  the result of that lookup.
  2007-05-29 If we can construct a expression, we do after expanding the
  subscript with dimensions to fill the Cref."
  input Env.Cache inCache;
  input Env.AvlTree inBinTree;
  input DAE.ComponentRef inComponentRef;
  output Env.Cache outCache;
  output DAE.Attributes outAttributes;
  output DAE.Type outType;
  output DAE.Binding outBinding;
  output Option<DAE.Const> constOfForIteratorRange "SOME(constant-ness) of the range if this is a for iterator, NONE() if this is not a for iterator";
  output SplicedExpData splicedExpData;
  output Env.Env outComponentEnv;
  output String name;
algorithm
  (outCache,outAttributes,outType,outBinding,constOfForIteratorRange,splicedExpData,outComponentEnv,name) :=
  matchcontinue (inCache,inBinTree,inComponentRef)
    local
      String id;
      SCode.ConnectorType ct;
      SCode.Parallelism prl;
      SCode.Variability vt,vt2;
      Absyn.Direction di;
      DAE.Type ty,ty_1,idTp;
      DAE.Binding bind,binding;
      Env.AvlTree ht;
      list<DAE.Subscript> ss;
      list<Env.Frame> componentEnv;
      DAE.ComponentRef ids;
      Env.Cache cache;
      DAE.Type ty2_2;
      Absyn.InnerOuter io;
      Option<DAE.Exp> texp;
      DAE.Type ty1,ty2;
      DAE.ComponentRef xCref,tCref,cref_;
      list<DAE.ComponentRef> ltCref;
      DAE.Exp splicedExp;
      DAE.Type eType,tty;
      Option<DAE.Const> cnstForRange;
      SCode.Visibility vis;
      DAE.Attributes attr;

    // Simple identifier
    case (cache,ht,ids as DAE.CREF_IDENT(ident = id,subscriptLst = ss) )
      equation
        (cache,DAE.TYPES_VAR(name,attr,ty,bind,cnstForRange),_,_,_,componentEnv) = lookupVar2(cache,ht, id);
        ty_1 = checkSubscripts(ty, ss);
        ss = addArrayDimensions(ty,ss);
        tty = Types.simplifyType(ty);
        cref_ = ComponentReference.makeCrefIdent(id,tty, ss);
        splicedExp = Expression.makeCrefExp(cref_,tty);
        //print("splicedExp ="+&ExpressionDump.dumpExpStr(splicedExp,0)+&"\n");
      then
        (cache,attr,ty_1,bind,cnstForRange,SPLICEDEXPDATA(SOME(splicedExp),ty),componentEnv,name);

    // Qualified variables looked up through component environment with a spliced exp
    case (cache,ht,xCref as (DAE.CREF_QUAL(ident = id,subscriptLst = ss,componentRef = ids)))
      equation
        (cache,DAE.TYPES_VAR(_,DAE.ATTR(variability = vt2),ty2,bind,cnstForRange),_,_,_,componentEnv) = lookupVar2(cache, ht, id);
        // outer variables are not local!
        // this doesn't work yet!
        // false = Absyn.isOuter(io);
        //
        (cache,DAE.ATTR(ct,prl,vt,di,io,vis),ty,binding,cnstForRange,SPLICEDEXPDATA(texp,idTp),_,componentEnv,name) = lookupVar(cache, componentEnv, ids);
        (tCref::ltCref) = elabComponentRecursive((texp));
        ty1 = checkSubscripts(ty2, ss);
        ty = sliceDimensionType(ty1,ty);
        ss = addArrayDimensions(ty2,ss);
        ty2_2 = Types.simplifyType(ty2);
        xCref = ComponentReference.makeCrefQual(id,ty2_2,ss,tCref);
        eType = Types.simplifyType(ty);
        splicedExp = Expression.makeCrefExp(xCref,eType);
        vt = SCode.variabilityOr(vt,vt2);
      then
        (cache,DAE.ATTR(ct,prl,vt,di,io,vis),ty,binding,cnstForRange,SPLICEDEXPDATA(SOME(splicedExp),idTp),componentEnv,name);

    // Qualified componentname without spliced Expression.
    case (cache,ht,xCref as (DAE.CREF_QUAL(ident = id,subscriptLst = ss,componentRef = ids)))
      equation
        (cache,DAE.TYPES_VAR(_,DAE.ATTR(variability = vt2),ty2,bind,cnstForRange),_,_,_,componentEnv) = lookupVar2(cache,ht, id);
        (cache,DAE.ATTR(ct,prl,vt,di,io,vis),ty,binding,cnstForRange,SPLICEDEXPDATA(texp,idTp),_,componentEnv,name) = lookupVar(cache, componentEnv, ids);
        {} = elabComponentRecursive((texp));
        vt = SCode.variabilityOr(vt,vt2);
      then
        (cache,DAE.ATTR(ct,prl,vt,di,io,vis),ty,binding,cnstForRange,SPLICEDEXPDATA(NONE(),idTp),componentEnv,name);
  end matchcontinue;
end lookupVarF;

protected function elabComponentRecursive "
Helper function for lookupvarF, to return an ComponentRef if there is one."
  input Option<DAE.Exp> oCref;
  output list<DAE.ComponentRef> lref;
algorithm
  lref := matchcontinue(oCref)
    local
      Option<DAE.Exp> exp;DAE.ComponentRef ecpr;

    // expression is an unqualified component reference
    case( exp as SOME(DAE.CREF(ecpr as DAE.CREF_IDENT(_,_,_),_ )))  then (ecpr::{});

    // expression is an qualified component reference
    case( exp as SOME(DAE.CREF(ecpr as DAE.CREF_QUAL(_,_,_,_),_ ))) then (ecpr::{});

    case(_) then {};
  end matchcontinue;
end elabComponentRecursive;

protected function addArrayDimensions " function addArrayDimensions
This is the function where we add arrays representing the dimension of the type.
In type {array 2[array 3 ]] Will generate 2 arrays. {1,2} and {1,2,3}"
  input DAE.Type tySub;
  input list<DAE.Subscript> ss;
  output list<DAE.Subscript> outType;
algorithm
  outType :=
  matchcontinue (tySub, ss)
    local
      list<DAE.Subscript> subs;
      DAE.Dimensions dims;
    case(_, _)
      equation
        true = Types.isArray(tySub, {});
        dims = Types.getDimensions(tySub);
        subs = List.map(dims, makeDimensionSubscript);
        subs = expandWholeDimSubScript(ss,subs);
      then subs;
    case(_,_) // non array, return
      equation then ss;
  end matchcontinue;
end addArrayDimensions;

protected function makeDimensionSubscript
  "Creates a slice with all indices of the dimension."
  input DAE.Dimension inDim;
  output DAE.Subscript outSub;
algorithm
  outSub := matchcontinue(inDim)
    local
      Integer sz;
      list<DAE.Exp> expl;
      Absyn.Path enum_name;
      list<String> l;
    // Special case when addressing array[0].
    case DAE.DIM_INTEGER(integer = 0)
      then
        DAE.SLICE(DAE.ARRAY(DAE.T_INTEGER_DEFAULT, true, {DAE.ICONST(0)}));
    // Array with integer dimension.
    case DAE.DIM_INTEGER(integer = sz)
      equation
        expl = List.map(List.intRange(sz), Expression.makeIntegerExp);
      then
        DAE.SLICE(DAE.ARRAY(DAE.T_INTEGER_DEFAULT, true, expl));
    // Array with enumeration dimension.
    case DAE.DIM_ENUM(enumTypeName = enum_name, literals = l, size = sz)
      equation
        expl = makeEnumLiteralIndices(enum_name, l, 1);
      then
        DAE.SLICE(DAE.ARRAY(DAE.T_ENUMERATION(NONE(), enum_name, l, {}, {}, DAE.emptyTypeSource), true, expl));
  end matchcontinue;
end makeDimensionSubscript;

protected function makeEnumLiteralIndices
  "Creates a list of enumeration literal expressions from an enumeration."
  input Absyn.Path enumTypeName;
  input list<String> enumLiterals;
  input Integer enumIndex;
  output list<DAE.Exp> enumIndices;
algorithm
  enumIndices := match(enumTypeName, enumLiterals, enumIndex)
    local
      String l;
      list<String> ls;
      DAE.Exp e;
      list<DAE.Exp> expl;
      Absyn.Path enum_type_name;
    case (_, {}, _) then {};
    case (_, l :: ls, _)
      equation
        enum_type_name = Absyn.joinPaths(enumTypeName, Absyn.IDENT(l));
        e = DAE.ENUM_LITERAL(enum_type_name, enumIndex);
        expl = makeEnumLiteralIndices(enumTypeName, ls, enumIndex + 1);
      then
        e :: expl;
  end match;
end makeEnumLiteralIndices;

protected function expandWholeDimSubScript " Function expandWholeDimSubScript
This function replaces Wholedim(if possible) with the expanded dimension.
If there exist a subscript, the subscript is used instead of the expanded dimension.
"
  input list<DAE.Subscript> inSubs;
  input list<DAE.Subscript> inSlice;
  output list<DAE.Subscript> outSubs;
algorithm
  outSubs :=
  matchcontinue(inSubs,inSlice)
    local
      DAE.Subscript sub1,sub2;
      list<DAE.Subscript> subs1,subs2;
    // If a for-iterator is used as subscript we get a cref subscript in inSubs,
    // but nothing in inSlice because it only contains integers (see
    // addArrayDimensions above). This case makes sure that for-iterators are
    // not lost here.
    case (((sub1 as DAE.INDEX(exp = DAE.CREF(componentRef = _))) :: subs1),
      subs2)
      equation
        subs2 = expandWholeDimSubScript(subs1, subs2);
      then
        (sub1 :: subs2);
    case(_,{}) then {};
    case({},subs2) then subs2;
    case(((sub1 as DAE.WHOLEDIM())::subs1), (sub2::subs2))
      equation
        subs2 = expandWholeDimSubScript(subs1,subs2);
      then
        (sub2::subs2);
    case((sub1::subs1), (sub2::subs2))
      equation
        subs2 = expandWholeDimSubScript(subs1,subs2);
      then
        (sub1::subs2);
  end matchcontinue;
end expandWholeDimSubScript;

protected function sliceDimensionType " function sliceDimensionType
Lifts an type to spcified dimension by type2
"
  input DAE.Type inTypeD;
  input DAE.Type inTypeL;
  output DAE.Type outType;

algorithm
  outType := match (inTypeD,inTypeL)
    local
      DAE.Type t,tOrg;
      list<Integer> dimensions;
      DAE.Dimensions dim2;
    case(t, tOrg)
      equation
        dimensions = Types.getDimensionSizes(t);
        dim2 = List.map(dimensions, Expression.intDimension);
        dim2 = listReverse(dim2);
        t = ((List.foldr(dim2,Types.liftArray, tOrg)));
      then
        t;
  end match;
end sliceDimensionType;


protected function buildMetaRecordType "common function when looking up the type of a metarecord"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.Element cdef;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output Types.Type ftype;
protected
  String id;
  Env.Env env_1,env;
  Absyn.Path utPath,path;
  Integer index;
  list<DAE.Var> varlst;
  list<SCode.Element> els;
  Boolean singleton;
  DAE.TypeSource ts;
  Env.Cache cache;
algorithm
  SCode.CLASS(name=id,restriction=SCode.R_METARECORD(utPath,index,singleton),classDef=SCode.PARTS(elementLst = els)) := cdef;
  env := Env.openScope(inEnv, SCode.NOT_ENCAPSULATED(), SOME(id), SOME(Env.CLASS_SCOPE()));
  // print("buildMetaRecordType " +& id +& " in scope " +& Env.printEnvPathStr(env) +& "\n");
  (cache,utPath) := Inst.makeFullyQualified(inCache,env,utPath);
  path := Absyn.joinPaths(utPath, Absyn.IDENT(id));
  (outCache,outEnv,_,_,_,_,_,varlst,_) := Inst.instElementList(
    cache,env,InnerOuter.emptyInstHierarchy, UnitAbsyn.noStore,
    DAE.NOMOD(),Prefix.NOPRE(),
    ClassInf.META_RECORD(Absyn.IDENT("")), List.map1(els,Util.makeTuple,DAE.NOMOD()),
    {}, false, Inst.INNER_CALL(), ConnectionGraph.EMPTY, Connect.emptySet, true);
  varlst := Types.boxVarLst(varlst);
  ts := Types.mkTypeSource(SOME(path));
  ftype := DAE.T_METARECORD(utPath,index,varlst,singleton,ts);
  // print("buildMetaRecordType " +& id +& " in scope " +& Env.printEnvPathStr(env) +& " OK " +& Types.unparseType(ftype) +&"\n");
end buildMetaRecordType;

public function splitEnv
"splits out the for loop scope envs"
  input Env.Env inEnv;
  output Env.Env outRealEnv;
  output Env.Env outForEnv;
algorithm
  (outRealEnv, outForEnv) := matchcontinue(inEnv)
    local
      Env.Env r, f,  fs;
      Env.Frame frm;

    case ({}) then ({}, {});
    case (frm::fs)
      equation
        true = frameIsImplAddedScope(frm);
        (r, f) = splitEnv(fs);
      then
        (r, frm::f);
    case (frm::fs)
      equation
        false = frameIsImplAddedScope(frm);
        (r, f) = splitEnv(fs);
      then
        (frm::r, f);
  end matchcontinue;
end splitEnv;

end Lookup;

