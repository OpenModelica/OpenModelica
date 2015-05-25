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
public import FCore;
public import HashTableStringToPath;
public import InstTypes;
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
protected import FGraph;
protected import FNode;
protected import Inst;
protected import InstExtends;
protected import InstFunction;
protected import InstUtil;
protected import InnerOuter;
protected import List;
protected import Mod;
protected import Prefix;
protected import Static;
protected import UnitAbsyn;
protected import SCodeDump;
protected import ErrorExt;
protected import ValuesUtil;
protected import Values;

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
  input FCore.Cache inCache;
  input FCore.Graph inEnv "environment to search in";
  input Absyn.Path inPath "type to look for";
  input Option<SourceInfo> msg "Messaage flag, SOME() outputs lookup error messages";
  output FCore.Cache outCache;
  output DAE.Type outType "the found type";
  output FCore.Graph outEnv "The environment the type was found in";
algorithm
  (outCache,outType,outEnv):=
  matchcontinue (inCache,inEnv,inPath,msg)
    local
      DAE.Type t;
      FCore.Graph env_1,env,env_2;
      Absyn.Path path;
      SCode.Element c;
      String classname,scope;
      FCore.Cache cache;
      SourceInfo info;

    // Special handling for Connections.isRoot
    case (cache,env,Absyn.QUALIFIED("Connections", Absyn.IDENT("isRoot")),_)
      equation
        t = DAE.T_FUNCTION({DAE.FUNCARG("x", DAE.T_ANYTYPE_DEFAULT, DAE.C_VAR(), DAE.NON_PARALLEL(), NONE())}, DAE.T_BOOL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT, DAE.emptyTypeSource);
      then
        (cache, t, env);

    // Special handling for MultiBody 3.x rooted() operator
    case (cache,env,Absyn.IDENT("rooted"),_)
      equation
        t = DAE.T_FUNCTION({DAE.FUNCARG("x", DAE.T_ANYTYPE_DEFAULT, DAE.C_VAR(), DAE.NON_PARALLEL(), NONE())}, DAE.T_BOOL_DEFAULT, DAE.FUNCTION_ATTRIBUTES_DEFAULT, DAE.emptyTypeSource);
      then
        (cache, t, env);

    // Special handling for Connections.uniqueRootIndices
    case (cache,env,Absyn.QUALIFIED("Connections", Absyn.IDENT("uniqueRootIndices")),_)
      equation
        t = DAE.T_FUNCTION({
              DAE.FUNCARG("roots", DAE.T_ARRAY(DAE.T_ANYTYPE_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource), DAE.C_VAR(), DAE.NON_PARALLEL(), NONE()),
              DAE.FUNCARG("nodes", DAE.T_ARRAY(DAE.T_ANYTYPE_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource), DAE.C_VAR(), DAE.NON_PARALLEL(), NONE()),
              DAE.FUNCARG("message", DAE.T_STRING_DEFAULT, DAE.C_VAR(), DAE.NON_PARALLEL(), NONE())},
              DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource),
              DAE.FUNCTION_ATTRIBUTES_DEFAULT, DAE.emptyTypeSource);
      then
        (cache, t, env);

    // For simple names
    case (cache,env,(path as Absyn.IDENT()),_)
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
    case (_,env,path,SOME(info))
      equation
        classname = Absyn.pathString(path);
        classname = stringAppend(classname," (its type) ");
        scope = FGraph.printGraphPathStr(env);
        Error.addSourceMessage(Error.LOOKUP_ERROR, {classname,scope}, info);
      then
        fail();
  end matchcontinue;
end lookupType;

protected function lookupType2
" This function handles the case when we looked up a class, but need to
check if it is function, record, metarecord, etc.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv "environment to search in";
  input Absyn.Path inPath "type to look for";
  input SCode.Element inClass "the class lookupType found";
  output FCore.Cache outCache;
  output DAE.Type outType "the found type";
  output FCore.Graph outEnv "The environment the type was found in";
algorithm
  (outCache,outType,outEnv) := matchcontinue (inCache,inEnv,inPath,inClass)
    local
      DAE.Type t;
      FCore.Graph env_1,env_2,env_3;
      Absyn.Path path;
      SCode.Element c;
      String id;
      FCore.Cache cache;
      SCode.Restriction r;
      list<DAE.Var> types;
      list<String> names;
      ClassInf.State ci_state;
      SCode.Encapsulated encflag;
      DAE.TypeSource ts;
      DAE.Mod mod;

    // Record constructors
    case (cache,env_1,_,c as SCode.CLASS(restriction=SCode.R_RECORD(_)))
      equation
        (cache,env_1,t) = buildRecordType(cache,env_1,c);
      then
        (cache,t,env_1);

    // lookup of an enumeration type
    case (cache,env_1,path,c as SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=r as SCode.R_ENUMERATION()))
      equation
        env_2 = FGraph.openScope(env_1, encflag, SOME(id), SOME(FCore.CLASS_SCOPE()));
        ci_state = ClassInf.start(r, FGraph.getGraphName(env_2));
        // fprintln(Flags.INST_TRACE, "LOOKUP TYPE ICD: " + FGraph.printGraphPathStr(env_1) + " path:" + Absyn.pathString(path));
        mod = Mod.getClassModifier(env_1, id);
        (cache,env_3,_,_,_,_,_,types,_,_,_,_) =
        Inst.instClassIn(
          cache,env_2,InnerOuter.emptyInstHierarchy,UnitAbsyn.noStore,
          mod, Prefix.NOPRE(),
          ci_state, c, SCode.PUBLIC(), {}, false, InstTypes.INNER_CALL(),
          ConnectionGraph.EMPTY, Connect.emptySet, NONE());
        // build names
        (_,names) = SCode.getClassComponents(c);
        Types.checkEnumDuplicateLiterals(names, c.info);
        // generate the enumeration type
        path = FGraph.getGraphName(env_3);
        ts = Types.mkTypeSource(SOME(path));
        t = DAE.T_ENUMERATION(NONE(), path, names, types, {}, ts);
        env_3 = FGraph.mkTypeNode(env_3, id, t);
      then
        (cache,t,env_3);

    // Real Type
    case (cache,env_1,_,SCode.CLASS(restriction=SCode.R_TYPE(),classDef=SCode.DERIVED(typeSpec=Absyn.TPATH(path=Absyn.IDENT(name="Real")))))
      equation
        t = DAE.T_REAL({}, DAE.emptyTypeSource);
      then
        (cache,t,env_1);

    // Integer Type
    case (cache,env_1,_,SCode.CLASS(restriction=SCode.R_TYPE(),classDef=SCode.DERIVED(typeSpec=Absyn.TPATH(path=Absyn.IDENT(name="Integer")))))
      equation
        t = DAE.T_INTEGER({}, DAE.emptyTypeSource);
      then
        (cache,t,env_1);

    // Boolean Type
    case (cache,env_1,_,SCode.CLASS(restriction=SCode.R_TYPE(),classDef=SCode.DERIVED(typeSpec=Absyn.TPATH(path=Absyn.IDENT(name="Boolean")))))
      equation
        t = DAE.T_BOOL({}, DAE.emptyTypeSource);
      then
        (cache,t,env_1);

    // String Type
    case (cache,env_1,_,SCode.CLASS(restriction=SCode.R_TYPE(),classDef=SCode.DERIVED(typeSpec=Absyn.TPATH(path=Absyn.IDENT(name="String")))))
      equation
        t = DAE.T_STRING({}, DAE.emptyTypeSource);
      then
        (cache,t,env_1);

    // Metamodelica extension, Uniontypes
    case (cache,env_1,_,c as SCode.CLASS(restriction=SCode.R_METARECORD()))
      equation
        (cache,env_2,t) = buildMetaRecordType(cache,env_1,c);
      then
        (cache,t,env_2);

    // Classes that are external objects. Implicitly instantiate to get type
    case (cache,env_1,_,c)
      equation
        // fprintln(Flags.INST_TRACE, "LOOKUP TYPE ICD: " + FGraph.printGraphPathStr(env_1) + " path:" + Absyn.pathString(path));
        true = SCode.classIsExternalObject(c);
        (cache,env_1,_,_,_,_,_,_,_,_) = Inst.instClass(
          cache,env_1,InnerOuter.emptyInstHierarchy, UnitAbsyn.noStore,
          DAE.NOMOD(), Prefix.NOPRE(), c,
          {}, false, InstTypes.TOP_CALL(), ConnectionGraph.EMPTY, Connect.emptySet);
        SCode.CLASS(name=id) = c;
        (env_1, _) = FGraph.stripLastScopeRef(env_1);
        (cache,t,env_2) = lookupTypeInEnv(cache,env_1,Absyn.IDENT(id));
      then
        (cache,t,env_2);

    // If we find a class definition that is a function or external function
    // with the same name then we implicitly instantiate that function, look
    // up the type.
    case (cache,env_1,_,c as SCode.CLASS(name = id,restriction=SCode.R_FUNCTION(_)))
      equation
        // fprintln(Flags.INST_TRACE, "LOOKUP TYPE ICD: " + FGraph.printGraphPathStr(env_1) + " path:" + Absyn.pathString(path));
        (cache,env_2,_) =
        InstFunction.implicitFunctionTypeInstantiation(cache,env_1,InnerOuter.emptyInstHierarchy,c);
        (cache,t,env_3) = lookupTypeInEnv(cache,env_2,Absyn.IDENT(id));
      then
        (cache,t,env_3);
  end matchcontinue;
end lookupType2;

public function lookupMetarecordsRecursive
"Takes a list of paths to Uniontypes. Use this list to create a list of T_METARECORD.
The function is guarded against recursive definitions by accumulating all paths it
starts to traverse."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Path> inUniontypePaths;
  output FCore.Cache outCache;
  output list<DAE.Type> outMetarecordTypes;
algorithm
  (outCache,_,outMetarecordTypes) := lookupMetarecordsRecursive2(inCache, inEnv, inUniontypePaths, HashTableStringToPath.emptyHashTable(), {});
end lookupMetarecordsRecursive;

protected function lookupMetarecordsRecursive2
"Takes a list of paths to Uniontypes. Use this list to create a list of T_METARECORD.
The function is guarded against recursive definitions by accumulating all paths it
starts to traverse."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Path> inUniontypePaths;
  input HashTableStringToPath.HashTable inHt;
  input list<DAE.Type> inAcc;
  output FCore.Cache outCache;
  output HashTableStringToPath.HashTable outHt;
  output list<DAE.Type> outMetarecordTypes;
algorithm
  (outCache,outHt,outMetarecordTypes) := match (inCache, inEnv, inUniontypePaths, inHt, inAcc)
    local
      FCore.Cache cache;
      FCore.Graph env;
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path path;
  input String str;
  input HashTableStringToPath.HashTable inHt;
  input list<DAE.Type> inAcc;
  output FCore.Cache outCache;
  output HashTableStringToPath.HashTable outHt;
  output list<DAE.Type> outMetarecordTypes;
algorithm
  (outCache,outHt,outMetarecordTypes) := matchcontinue (inCache, inEnv, path, str, inHt, inAcc)
    local
      FCore.Cache cache;
      FCore.Graph env;
      list<Absyn.Path> uniontypePaths;
      list<DAE.Type>    uniontypeTypes;
      DAE.Type ty;
      list<DAE.Type> acc;
      HashTableStringToPath.HashTable ht;

    case (cache, _, _, _, ht, acc)
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

public function lookupClass "Tries to find a specified class in an environment"
  input FCore.Cache inCache;
  input FCore.Graph inEnv "Where to look";
  input Absyn.Path inPath "Path of the class to look for";
  input Boolean msg "Controls error messages";
  output FCore.Cache outCache;
  output SCode.Element outClass;
  output FCore.Graph outEnv;
algorithm
  (outCache,outClass,outEnv) := matchcontinue(inCache, inEnv, inPath, msg)
    local
      Absyn.Path p, id;
      String name, className;
      FGraph.Graph cenv;

    /*
    case (_,_,_,_)
      equation
        print("CL: " + Absyn.pathString(inPath) + " env: " + FGraph.printGraphPathStr(inEnv) + " msg: " + boolString(msg) + "\n");
      then
        fail();*/

    // see if the first path ident is a component
    // we might have a component reference, i.e. world.gravityAcceleration
    case (_,_,Absyn.QUALIFIED(name, id),_)
      equation
        ErrorExt.setCheckpoint("functionViaComponentRef2");
        (outCache,_,_,_,_,_,_,cenv,_) = lookupVar(inCache, inEnv, ComponentReference.makeCrefIdent(name, DAE.T_UNKNOWN_DEFAULT, {}));
        (outCache, outClass, outEnv) = lookupClass(outCache, cenv, id, false);
        ErrorExt.rollBack("functionViaComponentRef2");
      then
        (outCache,outClass,outEnv);

   case (_,_,Absyn.QUALIFIED(_, _),_)
     equation
       ErrorExt.rollBack("functionViaComponentRef2");
     then
       fail();

    // normal case
    case (_, _, _, _)
      equation
         (outCache,outClass,outEnv,_) = lookupClass1(inCache, inEnv, inPath, {}, Util.makeStatefulBoolean(false), msg);
         // print("CLRET: " + SCode.elementName(outClass) + " outenv: " + FGraph.printGraphPathStr(outEnv) + "\n");
      then
        (outCache,outClass,outEnv);
  end matchcontinue;
  // print("Lookup C2: " + " outenv: " + FGraph.printGraphPathStr(outEnv) + "\n");
end lookupClass;

protected function lookupClass1 "help function to lookupClass, does all the work."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath "The path of the class to lookup";
  input FCore.Scope inPrevFrames "Environment in reverse order. Contains frames we previously had in the scope. Will be looked up instead of the environment in order to avoid infinite recursion.";
  input Util.StatefulBoolean inState "If true, we have found a class. If the path was qualified, we should no longer look in previous frames of the environment";
  input Boolean msg "Print error messages";
  output FCore.Cache outCache;
  output SCode.Element outClass;
  output FCore.Graph outEnv "The environment in which the class was found (not the environment inside the class)";
  output FCore.Scope outPrevFrames;
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
        scope = FGraph.printGraphPathStr(inEnv);
        Error.addMessage(Error.LOOKUP_ERROR, {id,scope});
      then fail();
    /*case (_,_,_,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        id = Absyn.pathString(inPath);
        scope = FGraph.printGraphPathStr(inEnv);
        fprintln(Flags.FAILTRACE,  "- Lookup.lookupClass failed:\n" +
          id + " in:\n" +
          scope);
      then fail();*/
  end matchcontinue;
end lookupClass1;

protected function lookupClass2 "help function to lookupClass, does all the work."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath "The path of the class to lookup";
  input FCore.Scope inPrevFrames "Environment in reverse order. Contains frames we previously had in the scope. Will be looked up instead of the environment in order to avoid infinite recursion.";
  input Util.StatefulBoolean inState "If true, we have found a class. If the path was qualified, we should no longer look in previous frames of the environment";
  input Boolean msg "Print error messages";
  output FCore.Cache outCache;
  output SCode.Element outClass;
  output FCore.Graph outEnv "The environment in which the class was found (not the environment inside the class)";
  output FCore.Scope outPrevFrames;
algorithm
  (outCache,outClass,outEnv,outPrevFrames) := match (inCache,inEnv,inPath,inPrevFrames,inState,msg)
    local
      FCore.Node f;
      FCore.Ref r;
      FCore.Cache cache;
      SCode.Element c;
      FCore.Graph env,env_1,env_2,fs;
      FCore.Scope prevFrames;
      Absyn.Path path,p,scope;
      String id,pack;
      Option<FCore.Ref> optFrame;

    // Fully qualified names are looked up in top scope. With previous frames remembered.
    case (cache,env,Absyn.FULLYQUALIFIED(path),{},_,_)
      equation
        r::prevFrames = listReverse(FGraph.currentScope(env));
        Util.setStatefulBoolean(inState,true);
        env = FGraph.setScope(env, {r});
        (cache,c,env_1,prevFrames) = lookupClass2(cache,env,path,prevFrames,inState,msg);
      then
        (cache,c,env_1,prevFrames);

    // Qualified names are handled in a special function in order to avoid infinite recursion.
    case (cache,env,(Absyn.QUALIFIED(name = pack,path = path)),prevFrames,_,_)
      equation
        (optFrame,prevFrames) = lookupPrevFrames(pack,prevFrames);
        (cache,c,env_2,prevFrames) = lookupClassQualified(cache,env,pack,path,optFrame,prevFrames,inState,msg);
      then
        (cache,c,env_2,prevFrames);

    // Simple names
    case (cache,env,Absyn.IDENT(name = id),prevFrames,_,_)
      equation
        (cache,c,env_1,prevFrames) = lookupClassInEnv(cache, env, id, prevFrames, inState, msg);
      then
        (cache,c,env_1,prevFrames);

    /*
    case (cache,env,p,_,_,_)
      equation
        Debug.traceln("lookupClass failed " + Absyn.pathString(p) + " " + FGraph.printGraphPathStr(env));
      then fail();
    */
  end match;
end lookupClass2;

protected function lookupClassQualified
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input String id;
  input Absyn.Path path;
  input Option<FCore.Ref> inOptFrame;
  input FCore.Scope inPrevFrames "Environment in reverse order. Contains frames we previously had in the scope. Will be looked up instead of the environment in order to avoid infinite recursion.";
  input Util.StatefulBoolean inState "If true, we have found a class. If the path was qualified, we should no longer look in previous frames of the environment";
  input Boolean msg "Print error messages";
  output FCore.Cache outCache;
  output SCode.Element outClass;
  output FCore.Graph outEnv "The environment in which the class was found (not the environment inside the class)";
  output FCore.Scope outPrevFrames;
algorithm
  (outCache,outClass,outEnv,outPrevFrames) := match (inCache,inEnv,id,path,inOptFrame,inPrevFrames,inState,msg)
    local
      SCode.Element c;
      Absyn.Path scope;
      FCore.Cache cache;
      FCore.Graph env;
      FCore.Scope prevFrames;
      FCore.Ref frame;
      Option<FCore.Ref> optFrame;

    // Qualified names first identifier cached in previous frames
    case (cache,env,_,_,SOME(frame),prevFrames,_,_)
      equation
        Util.setStatefulBoolean(inState,true);
        env = FGraph.pushScopeRef(env, frame);
        (cache,c,env,prevFrames) = lookupClass2(cache,env,path,prevFrames,inState,msg);
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

  end match;
end lookupClassQualified;

protected function lookupClassQualified2
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path path;
  input SCode.Element inC;
  input Option<FCore.Ref> optFrame;
  input FCore.Scope inPrevFrames "Environment in reverse order. Contains frames we previously had in the scope. Will be looked up instead of the environment in order to avoid infinite recursion.";
  input Util.StatefulBoolean inState "If true, we have found a class. If the path was qualified, we should no longer look in previous frames of the environment";
  input Boolean msg "Print error messages";
  output FCore.Cache outCache;
  output SCode.Element outClass;
  output FCore.Graph outEnv "The environment in which the class was found (not the environment inside the class)";
  output FCore.Scope outPrevFrames;
algorithm
  (outCache,outClass,outEnv,outPrevFrames) := matchcontinue (inCache,inEnv,path,inC,optFrame,inPrevFrames,inState,msg)
    local
      FCore.Cache cache;
      FCore.Graph env;
      FCore.Scope prevFrames;
      FCore.Ref frame;
      SCode.Restriction restr;
      ClassInf.State ci_state;
      SCode.Encapsulated encflag;
      String id;
      SCode.Element c;
      FCore.Ref r;
      DAE.Mod mod;

    case (cache,env,_,_,SOME(frame),prevFrames,_,_)
      equation
        env = FGraph.pushScopeRef(env, frame);
        (cache,c,env,prevFrames) = lookupClass2(cache,env,path,prevFrames,inState,msg);
        // fprintln(Flags.INST_TRACE, "LOOKUP CLASS QUALIFIED FRAME: " + FGraph.printGraphPathStr(env) + " path: " + Absyn.pathString(path) + " class: " + SCodeDump.shortElementStr(c));
      then (cache,c,env,prevFrames);

    // class is an instance of a component
    case (cache,env,_,SCode.CLASS(name=id),NONE(),_,_,_)
      equation
        r = FNode.child(FGraph.lastScopeRef(env), id);
        FCore.CL(status = FCore.CLS_INSTANCE(_)) = FNode.refData(r);
        // fetch the env
        (cache, env) = Inst.getCachedInstance(cache, env, id, r);
        (cache,c,env,prevFrames) = lookupClass2(cache,env,path,{},inState,msg);
      then (cache,c,env,prevFrames);

    case (cache,env,_,SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr),NONE(),_,_,_)
      equation
        env = FGraph.openScope(env, encflag, SOME(id), FGraph.restrictionToScopeType(restr));
        ci_state = ClassInf.start(restr, FGraph.getGraphName(env));
        // fprintln(Flags.INST_TRACE, "LOOKUP CLASS QUALIFIED PARTIALICD: " + FGraph.printGraphPathStr(env) + " path: " + Absyn.pathString(path) + " class: " + SCodeDump.shortElementStr(c));
        mod = Mod.getClassModifier(inEnv, id);
        (cache,env,_,_,_) =
        Inst.partialInstClassIn(
          cache,env,InnerOuter.emptyInstHierarchy,
          mod, Prefix.NOPRE(),
          ci_state, inC, SCode.PUBLIC(), {}, 0);
        // Was 2 cases for package/non-package - all they did was fail or succeed on this
        // If we comment it out, we get faster code, and less of it to maintain
        // ClassInf.valid(cistate1, SCode.R_PACKAGE());
        (cache,c,env,prevFrames) = lookupClass2(cache,env,path,{},inState,msg);
      then (cache,c,env,prevFrames);

  end matchcontinue;
end lookupClassQualified2;

protected function lookupPrevFrames
  input String id;
  input FCore.Scope inPrevFrames;
  output Option<FCore.Ref> outFrame;
  output FCore.Scope outPrevFrames;
algorithm
  (outFrame,outPrevFrames) := matchcontinue (id,inPrevFrames)
    local
      String sid;
      FCore.Scope prevFrames;
      FCore.Ref ref;

    case (_, ref::prevFrames)
      equation
        false = FNode.isRefTop(ref);
        sid = FNode.refName(ref);
        true = id == sid;
      then
        (SOME(ref),prevFrames);

    else (NONE(), {});

  end matchcontinue;
end lookupPrevFrames;

protected function lookupQualifiedImportedVarInFrame
"author: PA
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
    case (Absyn.QUAL_IMPORT(path = path) :: _, _)
      equation
        id = Absyn.pathLastIdent(path);
        true = id == ident;
      then ComponentReference.pathToCref(path);

    // Named imports, e.g. import A = B.C;
    case (Absyn.NAMED_IMPORT(name = id,path = path) :: _, _)
      equation
        true = id == ident;
      then ComponentReference.pathToCref(path);

    // Check next frame.
    case (_ :: rest, _) then lookupQualifiedImportedVarInFrame(rest, ident);
  end matchcontinue;
end lookupQualifiedImportedVarInFrame;

protected function moreLookupUnqualifiedImportedVarInFrame
"Helper function for lookup_unqualified_imported_var_in_frame. Returns
  true if there are unqualified imports that matches a sought constant."
  input FCore.Cache inCache;
  input list<Absyn.Import> inImports;
  input FCore.Graph inEnv;
  input SCode.Ident inIdent;
  output FCore.Cache outCache;
  output Boolean outBoolean;
algorithm
  (outCache,outBoolean) := matchcontinue (inCache,inImports,inEnv,inIdent)
    local
      FCore.Ref f;
      String ident;
      Boolean res;
      FCore.Graph env;
      FCore.Scope prevFrames;
      list<Absyn.Import> rest;
      FCore.Cache cache;
      DAE.ComponentRef cref;
      Absyn.Path path;

    case (cache,Absyn.UNQUAL_IMPORT(path = path) :: _,env,ident)
      equation
        f::prevFrames = listReverse(FGraph.currentScope(env));
        cref = ComponentReference.pathToCref(path);
        cref = ComponentReference.crefPrependIdent(cref,ident,{},DAE.T_UNKNOWN_DEFAULT);
        env = FGraph.setScope(env, {f});
        (cache,_,_,_,_,_,_,_,_) = lookupVarInPackages(cache,env,cref,prevFrames,Util.makeStatefulBoolean(false));
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

protected function lookupUnqualifiedImportedVarInFrame "Find a variable from an unqualified import locally in a frame"
  input FCore.Cache inCache;
  input list<Absyn.Import> inImports;
  input FCore.Graph inEnv;
  input SCode.Ident inIdent;
  output FCore.Cache outCache;
  output FCore.Graph outClassEnv;
  output DAE.Attributes outAttributes;
  output DAE.Type outType;
  output DAE.Binding outBinding;
  output Option<DAE.Const> constOfForIteratorRange "SOME(constant-ness) of the range if this is a for iterator, NONE() if this is not a for iterator";
  output Boolean outBoolean;
  output InstTypes.SplicedExpData splicedExpData;
  output FCore.Graph outComponentEnv;
  output String name;
algorithm
  (outCache,outClassEnv,outAttributes,outType,outBinding,constOfForIteratorRange,outBoolean,splicedExpData,outComponentEnv,name):=
  matchcontinue (inCache,inImports,inEnv,inIdent)
    local
      FCore.Ref f;
      DAE.ComponentRef cref;
      String ident;
      Boolean more,unique;
      FCore.Graph env,classEnv,componentEnv,env2;
      FCore.Scope prevFrames;
      DAE.Attributes attr;
      DAE.Type ty;
      DAE.Binding bind;
      list<Absyn.Import> rest;
      FCore.Cache cache;
      Absyn.Path path;
      Option<DAE.Const> cnstForRange;

    // unique
    case (cache,Absyn.UNQUAL_IMPORT(path = path) :: rest,env,ident)
      equation
        f::prevFrames = listReverse(FGraph.currentScope(env));
        cref = ComponentReference.pathToCref(path);
        cref = ComponentReference.crefPrependIdent(cref,ident,{},DAE.T_UNKNOWN_DEFAULT);
        env2 = FGraph.setScope(env, {f});
        (cache,classEnv,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name) = lookupVarInPackages(cache,env2,cref,prevFrames,Util.makeStatefulBoolean(false));
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
"Helper function to lookupQualifiedImportedClassInEnv."
  input FCore.Cache inCache;
  input list<Absyn.Import> inImport;
  input FCore.Graph inEnv;
  input SCode.Ident inIdent;
  input Util.StatefulBoolean inState;
  output FCore.Cache outCache;
  output SCode.Element outClass;
  output FCore.Graph outEnv;
  output FCore.Scope outPrevFrames;
algorithm
  (outCache,outClass,outEnv,outPrevFrames) := matchcontinue (inCache,inImport,inEnv,inIdent,inState)
    local
      FCore.Node fr;
      FCore.Ref r;
      SCode.Element c;
      FCore.Graph env_1,env;
      FCore.Scope prevFrames;
      String id,ident;
      list<Absyn.Import> rest;
      Absyn.Path path;
      FCore.Cache cache;

    case (cache,Absyn.QUAL_IMPORT(path = Absyn.IDENT(name = id)) :: _,env,ident,_)
      equation
        true = id == ident "For imported paths A, not possible to assert sub-path package";
        Util.setStatefulBoolean(inState,true);
        r::prevFrames = listReverse(FGraph.currentScope(env));
        env = FGraph.setScope(env, {r});
        (cache,c,env_1,prevFrames) = lookupClass2(cache,env,Absyn.IDENT(id),prevFrames,Util.makeStatefulBoolean(false),true);
      then
        (cache,c,env_1,prevFrames);

    case (cache,Absyn.QUAL_IMPORT(path = path) :: _,env,ident,_)
      equation
        id = Absyn.pathLastIdent(path) "For imported path A.B.C, assert A.B is package" ;
        true = id == ident;
        Util.setStatefulBoolean(inState,true);

        r::prevFrames = listReverse(FGraph.currentScope(env));
        env = FGraph.setScope(env, {r});
        // strippath = Absyn.stripLast(path);
        // (cache,c2,env_1,_) = lookupClass2(cache,{fr},strippath,prevFrames,Util.makeStatefulBoolean(false),true);
        (cache,c,env_1,prevFrames) = lookupClass2(cache,env,path,prevFrames,Util.makeStatefulBoolean(false),true);
      then
        (cache,c,env_1,prevFrames);

    case (cache,Absyn.NAMED_IMPORT(name = id,path = path) :: _,env,ident,_)
      equation
        true = id == ident "Named imports";
        Util.setStatefulBoolean(inState,true);

        r::prevFrames = listReverse(FGraph.currentScope(env));
        env = FGraph.setScope(env, {r});
        // strippath = Absyn.stripLast(path);
        // Debug.traceln("named import " + id + " is " + Absyn.pathString(path));
        // (cache,c2,env_1,prevFrames) = lookupClass2(cache,{fr},strippath,prevFrames,Util.makeStatefulBoolean(false),true);
        (cache,c,env_1,prevFrames) = lookupClass2(cache,env,path,prevFrames,Util.makeStatefulBoolean(false),true);
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
"Helper function for lookupUnqualifiedImportedClassInFrame"
  input FCore.Cache inCache;
  input list<Absyn.Import> inImports;
  input FCore.Graph inEnv;
  input SCode.Ident inIdent;
  output FCore.Cache outCache;
  output Boolean outBoolean;
algorithm
  (outCache,outBoolean) := matchcontinue (inCache,inImports,inEnv,inIdent)
    local
      FCore.Node fr,f;
      SCode.Element c;
      String id,ident;
      SCode.Encapsulated encflag;
      Boolean res;
      SCode.Restriction restr;
      FCore.Graph env_1,env2,env;
      ClassInf.State ci_state;
      Absyn.Path path;
      Absyn.Ident firstIdent;
      list<Absyn.Import> rest;
      FCore.Cache cache;
      FCore.Ref r;
      DAE.Mod mod;

    // Not found, instantiate
    case (cache,Absyn.UNQUAL_IMPORT(path = path) :: _,env,ident)
      equation
        env = FGraph.topScope(env);
        (cache,(c as SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr)),env_1) = lookupClass(cache, env, path, false);
        env2 = FGraph.openScope(env_1, encflag, SOME(id), FGraph.restrictionToScopeType(restr));
        ci_state = ClassInf.start(restr, FGraph.getGraphName(env2));
        // fprintln(Flags.INST_TRACE, "LOOKUP MORE UNQUALIFIED IMPORTED ICD: " + FGraph.printGraphPathStr(env) + "." + ident);
        mod = Mod.getClassModifier(env_1, id);
        (cache, env, _,_,_) = Inst.partialInstClassIn(cache, env2, InnerOuter.emptyInstHierarchy, mod, Prefix.NOPRE(), ci_state, c, SCode.PUBLIC(), {}, 0);
        r = FGraph.lastScopeRef(env);
        env = FGraph.setScope(env, {r});
        (cache,_,_) = lookupClass(cache, env, Absyn.IDENT(ident), false);
      then
        (cache, true);

    // Look in the parent scope
    case (cache,_ :: rest,env,ident)
      equation
        (cache, res) = moreLookupUnqualifiedImportedClassInFrame(cache, rest, env, ident);
      then
        (cache, res);

    case (cache,{},_,_) then (cache,false);

  end matchcontinue;
end moreLookupUnqualifiedImportedClassInFrame;

protected function lookupUnqualifiedImportedClassInFrame
"Finds a class from an unqualified import locally in a frame"
  input FCore.Cache inCache;
  input list<Absyn.Import> inImports;
  input FCore.Graph inEnv;
  input SCode.Ident inIdent;
  output FCore.Cache outCache;
  output SCode.Element outClass;
  output FCore.Graph outEnv;
  output FCore.Scope outPrevFrames;
  output Boolean outBoolean;
algorithm
  (outCache,outClass,outEnv,outPrevFrames,outBoolean) := matchcontinue (inCache,inImports,inEnv,inIdent)
    local
      FCore.Node fr;
      FCore.Ref r;
      SCode.Element c,c_1;
      String id,ident;
      SCode.Encapsulated encflag;
      Boolean more,unique;
      SCode.Restriction restr;
      FCore.Graph env_1,env2,env, env3;
      FCore.Scope prevFrames;
      ClassInf.State ci_state,cistate1;
      Absyn.Path path;
      list<Absyn.Import> rest;
      FCore.Cache cache;
      Absyn.Ident firstIdent;
      DAE.Mod mod;

    // Not in cache, instantiate, unique
    case (cache,Absyn.UNQUAL_IMPORT(path = path) :: rest,env,ident)
      equation
        r::prevFrames = listReverse(FGraph.currentScope(env));
        env3 = FGraph.setScope(env, {r});
        (cache,(c as SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr)),env_1,prevFrames) = lookupClass2(cache,env3,path,prevFrames,Util.makeStatefulBoolean(false),false);
        env2 = FGraph.openScope(env_1, encflag, SOME(id), FGraph.restrictionToScopeType(restr));
        ci_state = ClassInf.start(restr, FGraph.getGraphName(env2));
        // fprintln(Flags.INST_TRACE, "LOOKUP UNQUALIFIED IMPORTED ICD: " + FGraph.printGraphPathStr(env) + "." + ident);
        mod = Mod.getClassModifier(env_1, id);
        (cache,env2,_,_,_) =
        Inst.partialInstClassIn(cache, env2, InnerOuter.emptyInstHierarchy,
          mod, Prefix.NOPRE(), ci_state, c, SCode.PUBLIC(), {}, 0);
        // Restrict import to the imported scope only, not its parents, thus {f} below
        (cache,c_1,env2,prevFrames) = lookupClass2(cache,env2,Absyn.IDENT(ident),prevFrames,Util.makeStatefulBoolean(true),false) "Restrict import to the imported scope only, not its parents..." ;
        (cache,more) = moreLookupUnqualifiedImportedClassInFrame(cache, rest, env, ident);
        unique = boolNot(more);
      then
        (cache,c_1,env2,prevFrames,unique);

    // Look in the parent scope
    case (cache,_ :: rest,env,ident)
      equation
        (cache,c,env_1,prevFrames,unique) = lookupUnqualifiedImportedClassInFrame(cache, rest, env, ident);
      then
        (cache,c,env_1,prevFrames,unique);

  end matchcontinue;
end lookupUnqualifiedImportedClassInFrame;

public function lookupRecordConstructorClass
"Searches for a record constructor implicitly defined by a record class."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  output FCore.Cache outCache;
  output SCode.Element outClass;
  output FCore.Graph outEnv;
algorithm
  (outCache,outClass,outEnv) := match (inCache,inEnv,inPath)
    local
      SCode.Element c;
      FCore.Graph env,env_1;
      Absyn.Path path;
      String name;
      FCore.Cache cache;

    case (cache,env,path)
      equation
        (cache,c,env_1) = lookupClass(cache,env, path, false);
        SCode.CLASS( restriction=SCode.R_RECORD(_)) = c;
        (cache,_,c) = buildRecordConstructorClass(cache,env_1,c);
      then
        (cache,c,env_1);
  end match;
end lookupRecordConstructorClass;

public function lookupConnectorVar
"looks up a connector variable, but takes InnerOuter attribute from component if
 inside connector, i.e. for connector reference a.b the innerOuter attribute is
 fetched from a."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.ComponentRef cr;
  output FCore.Cache outCache;
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
      FCore.Cache cache;
      FCore.Graph env;
      SCode.Visibility vis;

    // unqualified component reference
    case(cache,env,DAE.CREF_IDENT())
      equation
        (cache,attr1,ty1,_,_,_,_,_,_) = lookupVarLocal(cache,env,cr);
      then
        (cache,attr1,ty1);

    // qualified component reference
    case(cache,env,DAE.CREF_QUAL())
      equation
        (cache,DAE.ATTR(ct,prl,var,dir,_,vis),ty1,_,_,_,_,_,_) = lookupVarLocal(cache,env,cr);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.ComponentRef inComponentRef;
  output FCore.Cache outCache;
  output DAE.Attributes outAttributes;
  output DAE.Type outType;
  output DAE.Binding outBinding;
  output Option<DAE.Const> constOfForIteratorRange "SOME(constant-ness) of the range if this is a for iterator, NONE() if this is not a for iterator";
  output InstTypes.SplicedExpData outSplicedExpData;
  output FCore.Graph outClassEnv "only used for package constants";
  output FCore.Graph outComponentEnv "only used for package constants";
  output String name "so the FQ path can be constructed";
algorithm
  (outCache,outAttributes,outType,outBinding,constOfForIteratorRange,outSplicedExpData,outClassEnv,outComponentEnv,name) :=
  matchcontinue (inCache,inEnv,inComponentRef)
    local
      DAE.Attributes attr;
      DAE.Type ty;
      DAE.Binding binding;
      FCore.Graph env, componentEnv, classEnv;
      DAE.ComponentRef cref;
      FCore.Cache cache;
      InstTypes.SplicedExpData splicedExpData;
      Option<DAE.Const> cnstForRange;

    /*/ debugging
    case (cache,env,cref)
      equation
        print("CO: " + ComponentReference.printComponentRefStr(cref) + " env: " + FGraph.printGraphPathStr(env) + "\n");
      then
        fail();*/

    // try the old lookupVarInternal
    case (cache,env,cref)
      equation
        (cache,attr,ty,binding,cnstForRange,splicedExpData,classEnv,componentEnv,name) = lookupVarInternal(cache, env, cref, InstTypes.SEARCH_ALSO_BUILTIN());
      then
        (cache,attr,ty,binding,cnstForRange,splicedExpData,classEnv,componentEnv,name);

    // then look in classes (implicitly instantiated packages)
    case (cache,env,cref)
      equation
        (cache,classEnv,attr,ty,binding,cnstForRange,splicedExpData,componentEnv,name) = lookupVarInPackages(cache,env,cref,{},Util.makeStatefulBoolean(false));
        checkPackageVariableConstant(env,classEnv,componentEnv,attr,ty,cref);
        // optional Expression.exp to return
      then
        (cache,attr,ty,binding,cnstForRange,splicedExpData,classEnv,componentEnv,name);

    /*/ fail if we couldn't find it
    case (_,env,cref)
      equation
        fprintln(Flags.FAILTRACE,  "- Lookup.lookupVar failed:\n" +
          ComponentReference.printComponentRefStr(cref) + " in:\n" +
          FGraph.printGraphPathStr(env));
      then fail();*/
  end matchcontinue;
end lookupVar;

protected function checkPackageVariableConstant "
Variables in packages must be constant. This function produces an error message and fails
if variable is not constant."
  input FCore.Graph parentEnv;
  input FCore.Graph classEnv;
  input FCore.Graph componentEnv;
  input DAE.Attributes attr;
  input DAE.Type tp;
  input DAE.ComponentRef cref;
algorithm
  _ := matchcontinue(parentEnv,classEnv,componentEnv,attr,tp,cref)
    local
      String s1,s2;
      SCode.Element cl;

    // do not fail if is a constant
    case (_, _, _,DAE.ATTR(variability = SCode.CONST()),_,_) then ();

    /*/ do not fail if is a parameter in non-package
    case (_, _, _,DAE.ATTR(variability = SCode.PARAM()),_,_)
      equation
        FCore.CL(e = cl) = FNode.refData(FGraph.lastScopeRef(classEnv));
        false = SCode.isPackage(cl);
        // print("cref:  " + ComponentReference.printComponentRefStr(cref) + "\nprenv: " + FGraph.getGraphNameStr(parentEnv) + "\nclenv: " + FGraph.getGraphNameStr(classEnv) + "\ncoenv: " + FGraph.getGraphNameStr(componentEnv) + "\n");
      then
        ();*/

    // fail if is not a constant
    else
      equation
        s1 = ComponentReference.printComponentRefStr(cref);
        s2 = FGraph.printGraphPathStr(classEnv);
        Error.addMessage(Error.PACKAGE_VARIABLE_NOT_CONSTANT,{s1,s2});
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Lookup.checkPackageVariableConstant failed: " + s1 + " in " + s2);
      then fail();
  end matchcontinue;
end checkPackageVariableConstant;

public function lookupVarInternal "Helper function to lookupVar. Searches the frames for variables."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.ComponentRef inComponentRef;
  input InstTypes.SearchStrategy searchStrategy "if SEARCH_LOCAL_ONLY it won't search in the builtin scope";
  output FCore.Cache outCache;
  output DAE.Attributes outAttributes;
  output DAE.Type outType;
  output DAE.Binding outBinding;
  output Option<DAE.Const> constOfForIteratorRange "SOME(constant-ness) of the range if this is a for iterator, NONE() if this is not a for iterator";
  output InstTypes.SplicedExpData splicedExpData;
  output FCore.Graph outClassEnv "the environment of the variable, typically the same as input, but e.g. for loop scopes can be 'stripped'";
  output FCore.Graph outComponentEnv "the component environment of the variable";
  output String name;
algorithm
  (outCache,outAttributes,outType,outBinding,constOfForIteratorRange,splicedExpData,outClassEnv,outComponentEnv,name) :=
  matchcontinue (inCache,inEnv,inComponentRef,searchStrategy)
    local
      DAE.Attributes attr;
      DAE.Type ty;
      DAE.Binding binding;
      Option<String> sid;
      FCore.Children ht;
      DAE.ComponentRef ref;
      FCore.Cache cache;
      Option<DAE.Const> cnstForRange;
      FCore.Graph env,componentEnv;
      FCore.Ref r;
      FCore.Scope rs;

    // look into the current frame
    case (cache, FCore.G(scope = r :: _), ref, _)
      equation
        ht = FNode.children(FNode.fromRef(r));
        (cache,attr,ty,binding,cnstForRange,splicedExpData,componentEnv,name) = lookupVarF(cache, ht, ref, inEnv);
      then
        (cache,attr,ty,binding,cnstForRange,splicedExpData,inEnv,componentEnv,name);

    // look in the next frame, only if current frame is a for loop scope.
    case (cache, FCore.G(scope = r :: _), ref, _)
      equation
        true = FNode.isImplicitRefName(r);
        (env, _) = FGraph.stripLastScopeRef(inEnv);
        (cache,attr,ty,binding,cnstForRange,splicedExpData,env,componentEnv,name) = lookupVarInternal(cache, env, ref, searchStrategy);
      then
        (cache,attr,ty,binding,cnstForRange,splicedExpData,env,componentEnv,name);

    // If not in top scope, look in top scope for builtin variables, e.g. time.
    case (cache, FCore.G(scope = _::_::_), ref, InstTypes.SEARCH_ALSO_BUILTIN())
      equation
        true = Builtin.variableIsBuiltin(ref, Config.acceptOptimicaGrammar());
        env = FGraph.topScope(inEnv);
        ht = FNode.children(FNode.fromRef(FGraph.lastScopeRef(env)));
        (cache,attr,ty,binding,cnstForRange,splicedExpData,componentEnv,name) = lookupVarF(cache, ht, ref, env);
      then
        (cache,attr,ty,binding,cnstForRange,splicedExpData,env,componentEnv,name);

  end matchcontinue;
end lookupVarInternal;

protected function frameIsImplAddedScope
"returns true if the frame is a for-loop scope or a valueblock scope.
This is indicated by the name of the frame."
  input FCore.Node f;
  output Boolean b;
algorithm
  b := match f
    local
      FCore.Name oname;
    case (FCore.N(name=oname)) then FCore.isImplicitScope(oname);
    else false;
  end match;
end frameIsImplAddedScope;

public function lookupVarInPackages "This function is called when a lookup of a variable with qualified names
  does not have the first element as a component, e.g. A.B.C is looked up
  where A is not a component. This implies that A is a class, and this
  class should be temporary instantiated, and the lookup should
  be performed within that class. I.e. the function performs lookup of
  variables in the class hierarchy.

  Note: the splicedExpData is currently not relevant, since constants are always evaluated to a value.
        However, this might change in the future since it makes more sense to calculate the constants
        during setup in runtime (to gain precision and postpone choice of precision to runtime)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.ComponentRef inComponentRef;
  input FCore.Scope inPrevFrames "Environment in reverse order. Contains frames we previously had in the scope. Will be looked up instead of the environment in order to avoid infinite recursion.";
  input Util.StatefulBoolean inState "If true, we have found a class. If the path was qualified, we should no longer look in a lower scope.";
  output FCore.Cache outCache;
  output FCore.Graph outClassEnv;
  output DAE.Attributes outAttributes;
  output DAE.Type outType;
  output DAE.Binding outBinding;
  output Option<DAE.Const> constOfForIteratorRange "SOME(constant-ness) of the range if this is a for iterator, NONE() if this is not a for iterator";
  output InstTypes.SplicedExpData splicedExpData "currently not relevant for constants, but might be used in the future";
  output FCore.Graph outComponentEnv;
  output String name "We only return the environment the component was found in; not its FQ name.";
algorithm
  (outCache,outClassEnv,outAttributes,outType,outBinding,constOfForIteratorRange,splicedExpData,outComponentEnv,name) :=
  matchcontinue (inCache,inEnv,inComponentRef,inPrevFrames,inState)
    local
      SCode.Element c;
      String n,id;
      SCode.Encapsulated encflag;
      SCode.Restriction r;
      FCore.Graph env2,env3,env5,env,p_env,classEnv, componentEnv;
      FCore.Scope prevFrames, fs;
      FCore.Node node;
      ClassInf.State ci_state;
      DAE.Attributes attr;
      DAE.Type ty;
      DAE.Binding bind;
      DAE.ComponentRef cref,cr;
      list<DAE.Subscript> sb;
      Option<String> sid;
      FCore.Ref f, rr;
      Option<FCore.Ref> of;
      FCore.Cache cache;
      Option<DAE.Const> cnstForRange;
      Absyn.Path path,scope;
      Boolean unique;
      FCore.Children ht;
      list<Absyn.Import> qimports, uqimports;
      DAE.Mod mod;

    // If we search for A1.A2....An.x while in scope A1.A2...An, just search for x.
    // Must do like this to ensure finite recursion
    case (cache,env,DAE.CREF_QUAL(ident = id,subscriptLst = {},componentRef = cref),prevFrames,_)
      equation
        (of,prevFrames) = lookupPrevFrames(id,prevFrames);
        _ = match(of)
          // first part of name is a previous frame
          case (SOME(f))
            equation
              Util.setStatefulBoolean(inState,true);
              env5 = FGraph.pushScopeRef(env, f);
            then
              ();
          // no prev frame
          case (NONE())
            equation
              (cache,(c as SCode.CLASS(name=n,encapsulatedPrefix=encflag,restriction=r)),env2,prevFrames) =
                lookupClass2(cache,
                             env,
                             Absyn.IDENT(id),
                             prevFrames,
                             Util.makeStatefulBoolean(true), // In order to use the prevFrames, we need to make sure we can't instantiate one of the classes too soon!
                             false);
              Util.setStatefulBoolean(inState,true);
              // see if we have an instance of a component!
              rr = FNode.child(FGraph.lastScopeRef(env2), id);
              if FNode.isRefInstance(rr) // is an instance, use it
              then
                (cache, env5) = Inst.getCachedInstance(cache, env2, id, rr);
              else // not an instance, instantiate it - lookup of constants on form A.B in packages. instantiate package and look inside.
                env3 = FGraph.openScope(env2, encflag, SOME(n), FGraph.restrictionToScopeType(r));
                ci_state = ClassInf.start(r, FGraph.getGraphName(env3));
                // fprintln(Flags.INST_TRACE, "LOOKUP VAR IN PACKAGES ICD: " + FGraph.printGraphPathStr(env3) + " var: " + ComponentReference.printComponentRefStr(cref));
                mod = Mod.getClassModifier(env2, n);
                (cache,env5,_,_,_,_,_,_,_,_,_,_) =
                  Inst.instClassIn(cache,env3,InnerOuter.emptyInstHierarchy,UnitAbsyn.noStore,
                    mod, Prefix.NOPRE(), ci_state, c, SCode.PUBLIC(), {},
                    /*true*/false, InstTypes.INNER_CALL(), ConnectionGraph.EMPTY,
                    Connect.emptySet, NONE());
              end if;
            then ();
        end match;
        (cache,p_env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name) = lookupVarInPackages(cache,env5,cref,prevFrames,inState);
      then
        (cache,p_env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name);

    // Why is this done? It is already done done in lookupVar!
    // BZ: This is due to recursive call when it might become DAE.CREF_IDENT calls.
    case (cache,env,(cr as DAE.CREF_IDENT()),_,_)
      equation
        (cache,attr,ty,bind,cnstForRange,splicedExpData,_,componentEnv,name) = lookupVarLocal(cache, env, cr);
        Util.setStatefulBoolean(inState,true);
      then
        (cache,env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name);

    // Lookup where the first identifier is a component.
    case (cache, env, cr, _, _)
      equation
        ht = FNode.children(FNode.fromRef(FGraph.lastScopeRef(env)));
        (cache, attr, ty, bind, cnstForRange, splicedExpData, componentEnv, name) = lookupVarF(cache, ht, cr, env);
      then
        (cache, env, attr, ty, bind, cnstForRange, splicedExpData, componentEnv, name);

    // Search among imports
    case (cache,env,DAE.CREF_IDENT(ident = id),prevFrames,_)
      equation
        node = FNode.fromRef(FGraph.lastScopeRef(env));
        (qimports, uqimports) = FNode.imports(node);
        _ = matchcontinue(qimports, uqimports)
          // Search among qualified imports, e.g. import A.B; or import D=A.B;
          case (_::_, _)
            equation
              cr = lookupQualifiedImportedVarInFrame(qimports, id);
              Util.setStatefulBoolean(inState,true);
              f::prevFrames = listReverse(FGraph.currentScope(env));
              env = FGraph.setScope(env, {f});
              (cache,p_env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name) = lookupVarInPackages(cache,env,cr,prevFrames,inState);
            then ();
          // Search among unqualified imports, e.g. import A.B.*
          case (_, _::_)
            equation
              (cache,p_env,attr,ty,bind,cnstForRange,unique,splicedExpData,componentEnv,name) = lookupUnqualifiedImportedVarInFrame(cache, uqimports, env, id);
              reportSeveralNamesError(unique,id);
              Util.setStatefulBoolean(inState,true);
            then ();
        end matchcontinue;
      then
        (cache,p_env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name);

     // Search parent scopes
    case (cache,FCore.G(scope = f::fs),cr,prevFrames,_)
      equation
        false = Util.getStatefulBoolean(inState);
        env = FGraph.setScope(inEnv, fs);
        (cache,p_env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name) = lookupVarInPackages(cache,env,cr,f::prevFrames,inState);
      then
        (cache,p_env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name);

    else
      equation
        //true = Flags.isSet(Flags.FAILTRACE);
        //Debug.traceln("- Lookup.lookupVarInPackages failed on exp:" + ComponentReference.printComponentRefStr(cr) + " in scope: " + FGraph.printGraphPathStr(env));
      then
        fail();
  end matchcontinue;
end lookupVarInPackages;

public function lookupVarLocal
"This function is very similar to `lookup_var\', but it only looks
  in the topmost environment frame, which means that it only finds
  names defined in the local scope.
  ----EXCEPTION---: When the topmost scope is the scope of a for loop, the lookup
  continues on the next scope. This to allow variables in the local scope to
  also be found even if inside a for scope.
  Arg1: The environment to search in
  Arg2: The variable to search for."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.ComponentRef inComponentRef;
  output FCore.Cache outCache;
  output DAE.Attributes outAttributes;
  output DAE.Type outType;
  output DAE.Binding outBinding;
  output Option<DAE.Const> constOfForIteratorRange "SOME(constant-ness) of the range if this is a for iterator, NONE() if this is not a for iterator";
  output InstTypes.SplicedExpData splicedExpData;
  output FCore.Graph outClassEnv;
  output FCore.Graph outComponentEnv;
  output String name;
algorithm
  // adrpo: use lookupVarInternal as is the SAME but it doesn't search in the builtin scope!
  (outCache,outAttributes,outType,outBinding,constOfForIteratorRange,splicedExpData,outClassEnv,outComponentEnv,name) :=
    lookupVarInternal(inCache, inEnv, inComponentRef, InstTypes.SEARCH_LOCAL_ONLY());
end lookupVarLocal;

public function lookupIdentLocal "Searches for a variable in the local scope."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.Ident inIdent;
  output FCore.Cache outCache;
  output DAE.Var outVar;
  output SCode.Element outElement;
  output DAE.Mod outMod;
  output FCore.Status instStatus;
  output FCore.Graph outComponentEnv;
algorithm
  (outCache,outVar,outElement,outMod,instStatus,outComponentEnv):=
  matchcontinue (inCache,inEnv,inIdent)
    local
      DAE.Var fv;
      SCode.Element c;
      DAE.Mod m;
      FCore.Status i;
      FCore.Ref r;
      FCore.Scope rs;
      FCore.Graph env,componentEnv;
      Option<String> sid;
      FCore.Children ht;
      String id;
      FCore.Cache cache;

    // component environment
    case (cache, FCore.G(scope = r::_), id)
      equation
        ht = FNode.children(FNode.fromRef(r));
        (fv,c,m,i,componentEnv) = lookupVar2(ht, id, inEnv);
      then
        (cache,fv,c,m,i,componentEnv);

    // Look in the next frame, if the current frame is a for loop scope.
    case (cache, FCore.G(scope = r::_), id)
      equation
        true = FNode.isImplicitRefName(r);
        (env, _) = FGraph.stripLastScopeRef(inEnv);
        (cache,fv,c,m,i,componentEnv) = lookupIdentLocal(cache, env, id);
      then
        (cache,fv,c,m,i,componentEnv);

  end matchcontinue;
end lookupIdentLocal;

public function lookupClassLocal "Searches for a class definition in the local scope."
  input FCore.Graph inEnv;
  input SCode.Ident inIdent;
  output SCode.Element outClass;
  output FCore.Graph outEnv;
algorithm
  (outClass,outEnv) := match(inEnv,inIdent)
    local
      SCode.Element cl;
      FCore.Graph env;
      Option<String> sid;
      FCore.Children ht;
      String id;
      FCore.Ref r;

    case (env as FCore.G(scope = r::_),id)
      equation
        ht = FNode.children(FNode.fromRef(r));
        r = FNode.avlTreeGet(ht, id);
        FCore.N(data = FCore.CL(e = cl)) = FNode.fromRef(r);
      then
        (cl,env);
  end match;
end lookupClassLocal;

public function lookupIdent
"Same as lookupIdentLocal, except check all frames"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.Ident inIdent;
  output FCore.Cache outCache;
  output DAE.Var outVar;
  output SCode.Element outElement;
  output DAE.Mod outMod;
  output FCore.Status instStatus;
  output FCore.Graph outEnv "the env where we found the ident";
algorithm
  (outCache,outVar,outElement,outMod,instStatus,outEnv):=
  matchcontinue (inCache,inEnv,inIdent)
    local
      DAE.Var fv;
      SCode.Element c;
      DAE.Mod m;
      FCore.Status i;
      Option<String> sid;
      FCore.Children ht;
      String id;
      FCore.Graph e;
      FCore.Cache cache;
      FCore.Ref r;
      FCore.Scope rs;

    case (cache,FCore.G(scope = r::_),id)
      equation
        ht = FNode.children(FNode.fromRef(r));
        (fv,c,m,i,_) = lookupVar2(ht, id, inEnv);
      then
        (cache,fv,c,m,i,inEnv);

    case (cache, FCore.G(scope = _::_),id)
      equation
        (e, _) = FGraph.stripLastScopeRef(inEnv);
        (cache,fv,c,m,i,e) = lookupIdent(cache, e, id);
      then
        (cache,fv,c,m,i,e);

  end matchcontinue;
end lookupIdent;

// Function lookup
public function lookupFunctionsInEnv
"Returns a list of types that the function has."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inId;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  (outCache,outTypesTypeLst) := matchcontinue (inCache,inEnv,inId,inInfo)
    local
      FCore.Graph env_1, cenv, env, fs;
      FCore.Node f;
      list<DAE.Type> res;
      list<Absyn.Path> names;
      FCore.Children httypes;
      FCore.Children ht;
      String str, name;
      FCore.Cache cache;
      Absyn.Path id, scope;
      SourceInfo info;

    /*
    case (cache,env,id,info)
      equation
        print("Looking up: " + Absyn.pathString(id) + " in env: " + FGraph.printGraphPathStr(env) + "\n");
      then
        fail();*/

    /*/ strip env if path is fully qualified in env
    case (cache,env,id,info)
      equation
        id = Env.pathStripEnvIfFullyQualifedInEnv(id, env);
        (cache,res) = lookupFunctionsInEnv(cache,env,id,info);
      then
        (cache,res);*/

    // we might have a component reference, i.e. world.gravityAcceleration
    case (cache,env,Absyn.QUALIFIED(name, id),info)
      equation
        ErrorExt.setCheckpoint("functionViaComponentRef");
        (cache,_,_,_,_,_,_,cenv,_) = lookupVar(cache, env, ComponentReference.makeCrefIdent(name, DAE.T_UNKNOWN_DEFAULT, {}));
        (cache, res) = lookupFunctionsInEnv(cache, cenv, id, info);
        ErrorExt.rollBack("functionViaComponentRef");
      then
        (cache,res);

   case (_,_,Absyn.QUALIFIED(_, _),_)
     equation
       ErrorExt.rollBack("functionViaComponentRef");
     then
       fail();

    // here we do some bad things which unfortunately are needed for some MSL models (MoistAir1)
    // we search the environment in reverse instead of finding out where the first id of the path is
    case (cache,env,id,_)
      equation
        env = FGraph.selectScope(env, id);
        name = Absyn.pathLastIdent(id);
        (cache, res) = lookupFunctionsInEnv(cache, env, Absyn.IDENT(name), inInfo);
      then
        (cache,res);

    // Builtin operators are looked up in top frame directly
    case (cache,env,(Absyn.IDENT(name = str)),info)
      equation
        _ = Static.elabBuiltinHandler(str) "Check for builtin operators";
        env = FGraph.topScope(env);
        ht = FNode.children(FNode.fromRef(FGraph.lastScopeRef(env)));
        httypes = getHtTypes(FGraph.lastScopeRef(env));
        (cache,res) = lookupFunctionsInFrame(cache, ht, httypes, env, str, info);
      then
        (cache,res);

    // Check for cardinality that can not be represented in the environment.
    case (cache,env,Absyn.IDENT(name = str as "cardinality"),_)
      equation
        env = FGraph.topScope(env);
        res = createGenericBuiltinFunctions(env, str);
      then
        (cache,res);

    // not fully qualified!
    case (cache,env,id,info)
      equation
        failure(Absyn.FULLYQUALIFIED(_) = id);
        (cache,res) = lookupFunctionsInEnv2(cache,env,id,false,info);
      then
        (cache,res);

    // fullyqual
    case (cache,env,Absyn.FULLYQUALIFIED(id),info)
      equation
        env = FGraph.topScope(env);
        (cache,res) = lookupFunctionsInEnv2(cache,env,id,true,info);
      then
        (cache,res);

    case (cache,env,id,_)
      equation
        (cache,SCode.CLASS(classDef=SCode.OVERLOAD(pathLst=names),info=info),env_1) = lookupClass(cache,env,id,false);
        (cache,res) = lookupFunctionsListInEnv(cache,env_1,names,info,{});
        // print(stringDelimitList(List.map(res,Types.unparseType),"\n###\n"));
      then (cache,res);

    case (cache,_,_,_) then (cache,{});

    case (_,_,id,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("lookupFunctionsInEnv failed on: " + Absyn.pathString(id));
      then
        fail();

  end matchcontinue;
end lookupFunctionsInEnv;

public function lookupFunctionsListInEnv
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Path> inIds;
  input SourceInfo info;
  input list<DAE.Type> inAcc;
  output FCore.Cache outCache;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  (outCache,outTypesTypeLst) := matchcontinue (inCache,inEnv,inIds,info,inAcc)
    local
      Absyn.Path id;
      list<DAE.Type> res;
      String str;
      FCore.Cache cache;
      FCore.Graph env;
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
        str = Absyn.pathString(id) + " not found in scope: " + FGraph.printGraphPathStr(env);
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, info);
      then fail();
  end matchcontinue;
end lookupFunctionsListInEnv;

protected function lookupFunctionsInEnv2
"Returns a list of types that the function has."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  input Boolean followedQual "cannot pop frames if we followed a qualified path at any point";
  input SourceInfo info;
  output FCore.Cache outCache;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  (outCache,outTypesTypeLst) := matchcontinue (inCache,inEnv,inPath,followedQual,info)
    local
      Absyn.Path id,path;
      Option<String> sid;
      FCore.Children httypes;
      FCore.Children ht;
      list<DAE.Type> res;
      FCore.Graph env,fs,env_1,env2,env_2;
      String pack,str;
      SCode.Element c;
      SCode.Encapsulated encflag;
      SCode.Restriction restr;
      ClassInf.State ci_state,cistate1;
      FCore.Ref r;
      FCore.Scope rs;
      FCore.Cache cache;
      DAE.Mod mod;

    // Simple name, search frame
    case (cache, FCore.G(scope = r::_),Absyn.IDENT(name = str),_,_)
      equation
        ht = FNode.children(FNode.fromRef(r));
        httypes = getHtTypes(r);
        (cache,res as _::_)= lookupFunctionsInFrame(cache, ht, httypes, inEnv, str, info);
      then
        (cache,res);

    // Simple name, if class with restriction function found in frame instantiate to get type.
    case (cache, FCore.G(scope = r::_), id as Absyn.IDENT(),_,_)
      equation
        // adrpo: do not search in the entire environment as we anyway recurse with the fs argument!
        //        just search in {f} not f::fs as otherwise we might get us in an infinite loop
        // Bjozac: Readded the f::fs search frame, otherwise we might get caught in a inifinite loop!
        //           Did not investigate this further then that it can crasch the kernel.
        (cache,(c as SCode.CLASS(name=str,restriction=restr)),env_1) = lookupClass(cache, inEnv, id, false);
        true = SCode.isFunctionRestriction(restr);
        // get function dae from instantiation
        // fprintln(Flags.INST_TRACE, "LOOKUP FUNCTIONS IN ENV ID ICD: " + FGraph.printGraphPathStr(env_1) + "." + str);
        (cache,env_2 as FCore.G(scope = r::_),_)
           = InstFunction.implicitFunctionTypeInstantiation(cache,env_1,InnerOuter.emptyInstHierarchy, c);
        ht = FNode.children(FNode.fromRef(r));
        httypes = getHtTypes(r);
        (cache,res as _::_)= lookupFunctionsInFrame(cache, ht, httypes, env_2, str, info);
      then
        (cache,res);

    // For qualified function names, e.g. Modelica.Math.sin
    case (cache, FCore.G(scope = r::_),Absyn.QUALIFIED(name = pack,path = path),_,_)
      equation
        (cache,(c as SCode.CLASS(name=str,encapsulatedPrefix=encflag,restriction=restr)),env_1) = lookupClass(cache, inEnv, Absyn.IDENT(pack), false);

        r = FNode.child(FGraph.lastScopeRef(env_1), str);
        if FNode.isRefInstance(r) // we have an instance of a component
        then
          (cache, env2) = Inst.getCachedInstance(cache, env_1, str, r);
        else
          env2 = FGraph.openScope(env_1, encflag, SOME(str), FGraph.restrictionToScopeType(restr));
          ci_state = ClassInf.start(restr, FGraph.getGraphName(env2));
          // fprintln(Flags.INST_TRACE, "LOOKUP FUNCTIONS IN ENV QUAL ICD: " + FGraph.printGraphPathStr(env2) + "." + str);
          mod = Mod.getClassModifier(env_1, str);
          (cache,env2,_,_,_) =
            Inst.partialInstClassIn(
              cache, env2, InnerOuter.emptyInstHierarchy,
              mod, Prefix.NOPRE(),
              ci_state, c, SCode.PUBLIC(), {}, 0);
        end if;
        (cache,res) = lookupFunctionsInEnv2(cache, env2, path, true, info);
      then
        (cache,res);

    // Did not match. Search next frame.
    case (cache,FCore.G(scope = r::_),id,false,_)
      equation
        false = FNode.isEncapsulated(FNode.fromRef(r));
        (env, _) = FGraph.stripLastScopeRef(inEnv);
        (cache,res) = lookupFunctionsInEnv2(cache, env, id, false, info);
      then
        (cache,res);

    case (cache, FCore.G(scope = r::_),id as Absyn.IDENT(),false,_)
      equation
        true = FNode.isEncapsulated(FNode.fromRef(r));
        env = FGraph.topScope(inEnv); // (cache,env) = Builtin.initialGraph(cache);
        (cache,res) = lookupFunctionsInEnv2(cache, env, id, true, info);
      then
        (cache,res);

  end matchcontinue;
end lookupFunctionsInEnv2;

protected function createGenericBuiltinFunctions
"author: PA
  This function creates function types on-the-fly for special builtin
  operators/functions which can not be represented in the builtin
  environment."
  input FCore.Graph inEnv;
  input String inString;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  outTypesTypeLst := match (inEnv,inString)
    local FCore.Graph env;

    // function_name cardinality
    case (_,"cardinality")
      then {DAE.T_FUNCTION(
              {DAE.FUNCARG("x",DAE.T_COMPLEX(ClassInf.CONNECTOR(Absyn.IDENT("$$"),false),{},NONE(),DAE.emptyTypeSource),DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
              DAE.T_INTEGER_DEFAULT,
              DAE.FUNCTION_ATTRIBUTES_DEFAULT,
              DAE.emptyTypeSource),
            DAE.T_FUNCTION(
              {DAE.FUNCARG("x",DAE.T_COMPLEX(ClassInf.CONNECTOR(Absyn.IDENT("$$"),true),{},NONE(),DAE.emptyTypeSource),DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
              DAE.T_INTEGER_DEFAULT,
              DAE.FUNCTION_ATTRIBUTES_DEFAULT,
              DAE.emptyTypeSource)};

  end match;
end createGenericBuiltinFunctions;

// - Internal functions
//   Type lookup

protected function lookupTypeInEnv
"function: lookupTypeInEnv"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  output FCore.Cache outCache;
  output DAE.Type outType;
  output FCore.Graph outEnv;
algorithm
  (outCache,outType,outEnv):=
  matchcontinue (inCache,inEnv,inPath)
    local
      DAE.Type c;
      FCore.Graph env_1,env,fs;
      Option<String> sid;
      FCore.Children httypes;
      FCore.Children ht;
      String id;
      FCore.Cache cache;
      Absyn.Path path;
      FCore.Ref r;

    case (cache, env as FCore.G(scope = r::_), Absyn.IDENT(name = id))
      equation
        ht = FNode.children(FNode.fromRef(r));
        httypes = getHtTypes(r);
        (cache,c,env_1) = lookupTypeInFrame(cache, ht, httypes, env, id);
      then
        (cache,c,env_1);

    case (cache,env as FCore.G(scope = r::_),path)
      equation
        (env, _) = FGraph.stripLastScopeRef(env);
        (cache,c,env_1) = lookupTypeInEnv(cache,env,path);
        env_1 = FGraph.pushScopeRef(env_1, r);
      then
        (cache,c,env_1);
  end matchcontinue;
end lookupTypeInEnv;

protected function getHtTypes
  input FCore.Ref inParentRef;
  output FCore.Children ht;
algorithm
  ht := matchcontinue(inParentRef)
    local FCore.Ref r;

    // there is a ty node
    case _
      equation
        r = FNode.child(inParentRef, FNode.tyNodeName);
        ht = FNode.children(FNode.fromRef(r));
      then
        ht;

    // no ty node
    else FCore.emptyCAvlTree;
  end matchcontinue;
end getHtTypes;

protected function lookupTypeInFrame
"Searches a frame for a type."
  input FCore.Cache inCache;
  input FCore.Children inBinTree1;
  input FCore.Children inBinTree2;
  input FCore.Graph inEnv3;
  input SCode.Ident inIdent4;
  output FCore.Cache outCache;
  output DAE.Type outType;
  output FCore.Graph outEnv;
algorithm
  (outCache,outType,outEnv):=
  match (inCache,inBinTree1,inBinTree2,inEnv3,inIdent4)
    local
      DAE.Type t;
      FCore.Children httypes;
      FCore.Children ht;
      FCore.Graph env;
      String id;
      FCore.Cache cache;
      FCore.Node item;

    case (cache,_,httypes,env,id)
      equation
        item = FNode.fromRef(FNode.avlTreeGet(httypes, id));
        (cache,t,env) = lookupTypeInFrame2(cache,item,env,id);
      then
        (cache,t,env);
  end match;
end lookupTypeInFrame;

protected function lookupTypeInFrame2
"Searches a frame for a type."
  input FCore.Cache inCache;
  input FCore.Node item;
  input FCore.Graph inEnv3;
  input SCode.Ident inIdent4;
  output FCore.Cache outCache;
  output DAE.Type outType;
  output FCore.Graph outEnv;
algorithm
  (outCache,outType,outEnv):=
  match (inCache,item,inEnv3,inIdent4)
    local
      DAE.Type t,ty;
      FCore.Graph env,cenv,env_1,env_3;
      String id,n;
      SCode.Element cdef, comp;
      FCore.Cache cache;
      SourceInfo info;

    case (cache,FCore.N(data = FCore.FT(t :: _)),env,_) then (cache,t,env);

    case (_,FCore.N(data = FCore.CO(e = comp)),_,id)
      equation
        info = SCode.elementInfo(comp);
        Error.addSourceMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id}, info);
      then
        fail();

    // Record constructor function
    case (cache,FCore.N(data = FCore.CL(e = cdef as SCode.CLASS(restriction=SCode.R_RECORD(_)))),env,_)
      equation
        (cache,env_3,ty) = buildRecordType(cache,env,cdef);
      then
        (cache,ty,env_3);

    case (cache,FCore.N(data = FCore.CL(e = cdef as SCode.CLASS(restriction=SCode.R_METARECORD()))),env,_)
      equation
        (cache,env_3,ty) = buildMetaRecordType(cache,env,cdef);
      then
        (cache,ty,env_3);

    // Found function
    case (cache,FCore.N(data = FCore.CL(e = cdef as SCode.CLASS(restriction=SCode.R_FUNCTION(_)))),env,id)
      equation
        // fprintln(Flags.INST_TRACE, "LOOKUP TYPE IN FRAME ICD: " + FGraph.printGraphPathStr(env) + " id:" + id);

        // select the env if is the same as cenv as is updated!
        cenv = env; // selectUpdatedEnv(env, cenv);

        (cache ,env_1,_) = InstFunction.implicitFunctionInstantiation(
          cache,cenv,InnerOuter.emptyInstHierarchy,
          DAE.NOMOD(), Prefix.NOPRE(), cdef, {});

        (cache,ty,env_3) = lookupTypeInEnv(cache, env_1, Absyn.IDENT(id));
      then
        (cache,ty,env_3);

  end match;
end lookupTypeInFrame2;

protected function lookupFunctionsInFrame
  "This actually only looks up the function name and find all
   corresponding types that have this function name."
  input FCore.Cache inCache;
  input FCore.Children inClasses;
  input FCore.Children inFuncTypes;
  input FCore.Graph inEnv;
  input SCode.Ident inFuncName;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output list<DAE.Type> outFuncTypes;
protected
  FCore.Ref r;
  FNode.Data data;
  DAE.Type ty;
algorithm
  try // Try to look up the function among the function types first.
    r := FNode.avlTreeGet(inFuncTypes, inFuncName);
    FCore.N(data = FCore.FT(outFuncTypes)) := FNode.fromRef(r);
    outCache := inCache;
  else // If not found, try to look the function up in the environment instead.
    r := FNode.avlTreeGet(inClasses, inFuncName);
    FCore.N(data = data) := FNode.fromRef(r);

    (outCache, outFuncTypes) := matchcontinue(data)
      local
        SCode.Element cl;
        list<DAE.Type> tps;
        FCore.Cache cache;
        FCore.Graph env;

      // MetaModelica partial functions.
      case _
        algorithm
          DAE.TYPES_VAR(ty = ty as DAE.T_FUNCTION(__)) := FNode.refInstVar(r);
          ty := Types.setTypeSource(ty, Types.mkTypeSource(SOME(Absyn.IDENT(inFuncName))));
        then
          (inCache, {ty});

      // Found a component, print an error.
      case FCore.CO(__)
        algorithm
          Error.addSourceMessage(Error.LOOKUP_TYPE_FOUND_COMP, {inFuncName}, inInfo);
        then
          fail();

      // A record, create a record constructor.
      case FCore.CL(e = cl as SCode.CLASS(restriction = SCode.R_RECORD(__)))
        algorithm
          (cache, _, ty) := buildRecordType(inCache, inEnv, cl);
        then
          (cache, {ty});

      // A function, instantiate to get the type.
      case FCore.CL(e = cl) guard(SCode.isFunction(cl))
        algorithm
          (cache, env) := InstFunction.implicitFunctionTypeInstantiation(
            inCache, inEnv, InnerOuter.emptyInstHierarchy, cl);
          (cache, tps) := lookupFunctionsInEnv2(cache, env,
            Absyn.IDENT(inFuncName), true, inInfo);
        then
          (cache, tps);

      // An external object.
      case FCore.CL(e = cl) guard(SCode.classIsExternalObject(cl))
        algorithm
          (cache, env) := Inst.instClass(inCache, inEnv,
            InnerOuter.emptyInstHierarchy, UnitAbsyn.noStore, DAE.NOMOD(),
            Prefix.NOPRE(), cl, {}, false, InstTypes.TOP_CALL(),
            ConnectionGraph.EMPTY, Connect.emptySet);
          (cache, ty) := lookupTypeInEnv(cache, env, Absyn.IDENT(inFuncName));
        then
          (cache, {ty});

    end matchcontinue;
  end try;
end lookupFunctionsInFrame;

public function selectUpdatedEnv
  input FCore.Graph inNewEnv;
  input FCore.Graph inOldEnv;
  output FCore.Graph outEnv;
algorithm
  outEnv := matchcontinue(inNewEnv, inOldEnv)
    // return old if is top scope!
    case (_, _)
      equation
        true = FGraph.isTopScope(inNewEnv);
      then
        inOldEnv;
    // if they point to the same env, return the new one
    case (_, _)
      equation
        true = stringEq(FGraph.getGraphNameStr(inNewEnv),
                        FGraph.getGraphNameStr(inOldEnv));
      then
        inNewEnv;

    else inOldEnv;
  end matchcontinue;
end selectUpdatedEnv;

protected function buildRecordType ""
  input FCore.Cache cache;
  input FCore.Graph env;
  input SCode.Element icdef;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output DAE.Type ftype;
protected
  String name;
  FCore.Graph env_1;
  SCode.Element cdef;
algorithm
  (outCache,_,cdef) := buildRecordConstructorClass(cache,env,icdef);
  name := SCode.className(cdef);
  // fprintln(Flags.INST_TRACE", "LOOKUP BUILD RECORD TY ICD: " + FGraph.printGraphPathStr(env) + "." + name);
  (outCache,outEnv,_) := InstFunction.implicitFunctionTypeInstantiation(
     outCache,env,InnerOuter.emptyInstHierarchy, cdef);
  (outCache,ftype,_) := lookupTypeInEnv(outCache,outEnv,Absyn.IDENT(name));
end buildRecordType;

protected function buildRecordConstructorClass
"
  Creates the record constructor class, i.e. a function, from the record
  class given as argument."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.Element inClass;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output SCode.Element outClass;
algorithm
  (outCache,outEnv,outClass) :=
  matchcontinue (inCache,inEnv,inClass)
    local
      list<SCode.Element> funcelts,elts;
      SCode.Element reselt;
      SCode.Element cl;
      String id;
      SourceInfo info;
      FCore.Cache cache;
      FCore.Graph env;

    case (cache,env,cl as SCode.CLASS(name=id,info=info))
      equation
        (cache,env,funcelts,_) = buildRecordConstructorClass2(cache,env,cl,DAE.NOMOD());
        reselt = buildRecordConstructorResultElt(funcelts,id,env,info);
        cl = SCode.CLASS(id,SCode.defaultPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_FUNCTION(SCode.FR_RECORD_CONSTRUCTOR()),SCode.PARTS((reselt :: funcelts),{},{},{},{},{},{},NONE()),SCode.noComment,info);
      then
        (cache,env,cl);
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("buildRecordConstructorClass failed\n");
      then fail();
  end matchcontinue;
end buildRecordConstructorClass;

protected function buildRecordConstructorClass2
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.Element cl;
  input DAE.Mod mods;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output list<SCode.Element> funcelts;
  output list<SCode.Element> elts;
algorithm
  (outCache,outEnv,funcelts,elts) := matchcontinue(inCache,inEnv,cl,mods)
    local
      list<SCode.Element> cdefelts,classExtendsElts,extendsElts,compElts;
      list<tuple<SCode.Element,DAE.Mod>> eltsMods;
      String name;
      Absyn.Path fpath;
      SourceInfo info;
      FCore.Cache cache;
      FCore.Graph env,env1;

    // a class with parts
    case (cache,env,SCode.CLASS(name = name,info = info),_)
      equation
        (cache,env,_,elts,_,_,_,_,_) = InstExtends.instDerivedClasses(cache,env,InnerOuter.emptyInstHierarchy,DAE.NOMOD(),Prefix.NOPRE(),cl,true,info);
        env = FGraph.openScope(env, SCode.NOT_ENCAPSULATED(), SOME(name), SOME(FCore.CLASS_SCOPE()));
        fpath = FGraph.getGraphName(env);
        (cdefelts,classExtendsElts,extendsElts,compElts) = InstUtil.splitElts(elts);
        (cache,env,_,_,eltsMods,_,_,_,_) = InstExtends.instExtendsAndClassExtendsList(cache, env, InnerOuter.emptyInstHierarchy, DAE.NOMOD(), Prefix.NOPRE(), extendsElts, classExtendsElts, elts, ClassInf.RECORD(fpath), name, true, false);
        eltsMods = listAppend(eltsMods,InstUtil.addNomod(compElts));
        // print("Record Elements: " +
        //   stringDelimitList(
        //     List.map(
        //       List.map(
        //         eltsMods,
        //         Util.tuple21),
        //       SCodeDump.printElementStr), "\n"));
        (cache, env1, _) = InstUtil.addClassdefsToEnv(cache, env, InnerOuter.emptyInstHierarchy, Prefix.NOPRE(), cdefelts, false, NONE());
        (cache, env1, _) = InstUtil.addComponentsToEnv(cache, env1, InnerOuter.emptyInstHierarchy, mods, Prefix.NOPRE(), ClassInf.RECORD(fpath), eltsMods, eltsMods, {}, {}, true);
        (cache, env1, funcelts) = buildRecordConstructorElts(cache,env1,eltsMods,mods);
      then (cache,env1,funcelts,elts);

    // fail
    else equation
      Debug.traceln("buildRecordConstructorClass2 failed, cl:"+SCodeDump.unparseElementStr(cl,SCodeDump.defaultOptions)+"\n");
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
    else inModID;
  end matchcontinue;
end selectModifier;

protected function buildRecordConstructorElts
"Helper function to build_record_constructor_class. Creates the elements
  of the function class.

  TODO: This function should be replaced by a proper instantiation using instClassIn instead, followed by a
  traversal of the DAE.Var changing direction to input.
  Reason for not doing that now: records can contain arrays with unknown dimensions."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<tuple<SCode.Element,DAE.Mod>> inSCodeElementLst;
  input DAE.Mod mods;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output list<SCode.Element> outSCodeElementLst;
algorithm
  (outCache, outEnv, outSCodeElementLst) := matchcontinue (inCache,inEnv,inSCodeElementLst,mods)
    local
      FCore.Cache cache;
      FCore.Graph env;
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
      SCode.Comment comment;
      Option<Absyn.Exp> cond;
      SCode.Mod mod,umod;
      DAE.Mod mod_1, compMod, fullMod, selectedMod, cmod;
      SourceInfo info;

    case (cache,env,{},_) then (cache,env,{});

    // final becomes protected, Modelica Spec 3.2, Section 12.6, Record Constructor Functions, page 140
    case (cache, env, (((      SCode.COMPONENT(
        id,
        SCode.PREFIXES(_, redecl, f as SCode.FINAL(), io, repl),
        SCode.ATTR(d,ct,prl,var,_),tp,mod,comment,cond,info)),cmod) :: rest), _)
      equation
        (cache,mod_1) = Mod.elabMod(cache, env, InnerOuter.emptyInstHierarchy, Prefix.NOPRE(), mod, true, Mod.COMPONENT(id), info);
        mod_1 = Mod.merge(mods,mod_1,env,Prefix.NOPRE());
        // adrpo: this was wrong, you won't find any id modification there!!!
        // bjozac: This was right, you will find id modification unless modifers does not belong to component!
        // adrpo 2009-11-23 -> solved by selecting the full modifier if the component modifier is empty!
        compMod = Mod.lookupModificationP(mod_1,Absyn.IDENT(id));
        fullMod = mod_1;
        selectedMod = selectModifier(compMod, fullMod); // if the first one is empty use the other one.
        (cache,cmod) = Mod.updateMod(cache,env,InnerOuter.emptyInstHierarchy,Prefix.NOPRE(),cmod,true,info);
        selectedMod = Mod.merge(cmod,selectedMod,env,Prefix.NOPRE());
        umod = Mod.unelabMod(selectedMod);
        (cache, env, res) = buildRecordConstructorElts(cache, env, rest, mods);
        // - Prefixes (constant, parameter, final, discrete, input, output, ...) of the remaining record components are removed.
        // adrpo: 2010-11-09 : TODO! FIXME! why is this?? keep the variability!
        // mahge: 2013-01-15 : direction should be set to bidir.
        // var = SCode.VAR();
        dir = Absyn.BIDIR();
        vis = SCode.PROTECTED();
      then
        (cache, env, SCode.COMPONENT(id,SCode.PREFIXES(vis,redecl, f,io,repl),SCode.ATTR(d,ct,prl,var,dir),tp,umod,comment,cond,info) :: res);

    // constants become protected, Modelica Spec 3.2, Section 12.6, Record Constructor Functions, page 140
    // mahge: 2013-01-15 : only if they have bindings. otherwise they are still modifiable.
    case (cache, env, (((      SCode.COMPONENT(
        id,
        SCode.PREFIXES(vis, redecl, _, io, repl),
        SCode.ATTR(d,ct,prl,SCode.CONST(),_),tp,mod as SCode.NOMOD(),comment,cond,info)), cmod) :: rest),_)
      equation
        (cache,mod_1) = Mod.elabMod(cache, env, InnerOuter.emptyInstHierarchy, Prefix.NOPRE(), mod, true, Mod.COMPONENT(id), info);
        mod_1 = Mod.merge(mods,mod_1,env,Prefix.NOPRE());
        // adrpo: this was wrong, you won't find any id modification there!!!
        // bjozac: This was right, you will find id modification unless modifers does not belong to component!
        // adrpo 2009-11-23 -> solved by selecting the full modifier if the component modifier is empty!
        compMod = Mod.lookupModificationP(mod_1,Absyn.IDENT(id));
        fullMod = mod_1;
        selectedMod = selectModifier(compMod, fullMod); // if the first one is empty use the other one.
        (cache,cmod) = Mod.updateMod(cache,env,InnerOuter.emptyInstHierarchy,Prefix.NOPRE(),cmod,true,info);
        selectedMod = Mod.merge(cmod,selectedMod,env,Prefix.NOPRE());
        umod = Mod.unelabMod(selectedMod);
        (cache, env, res) = buildRecordConstructorElts(cache, env, rest, mods);
        // - Prefixes (constant, parameter, final, discrete, input, output, ...) of the remaining record components are removed.
        // adrpo: 2010-11-09 : TODO! FIXME! why is this?? keep the variability!
        var = SCode.VAR();
        dir = Absyn.INPUT();
        vis = SCode.PUBLIC();
        f = SCode.NOT_FINAL();
      then
        (cache, env, SCode.COMPONENT(id,SCode.PREFIXES(vis,redecl,f,io,repl),SCode.ATTR(d,ct,prl,var,dir),tp,umod,comment,cond,info) :: res);


    case (cache, env, (((      SCode.COMPONENT(
        id,
        SCode.PREFIXES(_, redecl, f, io, repl),
        SCode.ATTR(d,ct,prl,var as SCode.CONST(),_),tp,mod,comment,cond,info)),cmod) :: rest), _)
      equation
        (cache,mod_1) = Mod.elabMod(cache, env, InnerOuter.emptyInstHierarchy, Prefix.NOPRE(), mod, true, Mod.COMPONENT(id), info);
        mod_1 = Mod.merge(mods,mod_1,env,Prefix.NOPRE());
        // adrpo: this was wrong, you won't find any id modification there!!!
        // bjozac: This was right, you will find id modification unless modifers does not belong to component!
        // adrpo 2009-11-23 -> solved by selecting the full modifier if the component modifier is empty!
        compMod = Mod.lookupModificationP(mod_1,Absyn.IDENT(id));
        fullMod = mod_1;
        selectedMod = selectModifier(compMod, fullMod); // if the first one is empty use the other one.
        (cache,cmod) = Mod.updateMod(cache,env,InnerOuter.emptyInstHierarchy,Prefix.NOPRE(),cmod,true,info);
        selectedMod = Mod.merge(cmod,selectedMod,env,Prefix.NOPRE());
        umod = Mod.unelabMod(selectedMod);
        (cache, env, res) = buildRecordConstructorElts(cache, env, rest, mods);
        // - Prefixes (constant, parameter, final, discrete, input, output, ...) of the remaining record components are removed.
        // adrpo: 2010-11-09 : TODO! FIXME! why is this?? keep the variability!
        // mahge: 2013-01-15 : direction should be set to bidir.
        // var = SCode.VAR();
        dir = Absyn.BIDIR();
        vis = SCode.PROTECTED();
      then
        (cache, env, SCode.COMPONENT(id,SCode.PREFIXES(vis,redecl,f,io,repl),SCode.ATTR(d,ct,prl,var,dir),tp,umod,comment,cond,info) :: res);

    // all others, add input see Modelica Spec 3.2, Section 12.6, Record Constructor Functions, page 140
    case (cache, env, (((      SCode.COMPONENT(
        id,
        SCode.PREFIXES(_, redecl, _, io, repl),
        SCode.ATTR(d,ct,prl,_,_),tp,mod,comment,cond,info)),cmod) :: rest), _)
      equation
        (cache,mod_1) = Mod.elabMod(cache, env, InnerOuter.emptyInstHierarchy, Prefix.NOPRE(), mod, true, Mod.COMPONENT(id), info);
        mod_1 = Mod.merge(mods,mod_1,env,Prefix.NOPRE());
        // adrpo: this was wrong, you won't find any id modification there!!!
        // bjozac: This was right, you will find id modification unless modifers does not belong to component!
        // adrpo 2009-11-23 -> solved by selecting the full modifier if the component modifier is empty!
        compMod = Mod.lookupModificationP(mod_1,Absyn.IDENT(id));
        fullMod = mod_1;
        selectedMod = selectModifier(compMod, fullMod); // if the first one is empty use the other one.
        (cache,cmod) = Mod.updateMod(cache,env,InnerOuter.emptyInstHierarchy,Prefix.NOPRE(),cmod,true,info);
        selectedMod = Mod.merge(cmod,selectedMod,env,Prefix.NOPRE());
        umod = Mod.unelabMod(selectedMod);
        (cache, env, res) = buildRecordConstructorElts(cache, env, rest, mods);
        // - Prefixes (constant, parameter, final, discrete, input, output, ...) of the remaining record components are removed.
        // adrpo: 2010-11-09 : TODO! FIXME! why is this?? keep the variability!
        var = SCode.VAR();
        vis = SCode.PUBLIC();
        f = SCode.NOT_FINAL();
        dir = Absyn.INPUT();
      then
        (cache, env, SCode.COMPONENT(id,SCode.PREFIXES(vis, redecl, f, io, repl),SCode.ATTR(d,ct,prl,var,dir),tp,umod,comment,cond,info) :: res);

    case (_, _, (comp,cmod)::_, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Lookup.buildRecordConstructorElts failed " + SCodeDump.unparseElementStr(comp,SCodeDump.defaultOptions) + " with mod: " + Mod.printModStr(cmod) + " and: " + Mod.printModStr(mods));
      then fail();
  end matchcontinue;
end buildRecordConstructorElts;

protected function buildRecordConstructorResultElt
"This function builds the result element of a
  record constructor function, i.e. the returned variable"
  input list<SCode.Element> elts;
  input SCode.Ident id;
  input FCore.Graph env;
  input SourceInfo info;
  output SCode.Element outElement;
algorithm
  //print(" creating element of type: " + id + "\n");
  //print(" with generated mods:" + SCode.printSubs1Str(submodlst) + "\n");
  //print(" creating element of type: " + id + "\n");
  //print(" with generated mods:" + SCode.printSubs1Str(submodlst) + "\n");
  outElement := SCode.COMPONENT("result",SCode.defaultPrefixes,
          SCode.ATTR({},SCode.POTENTIAL(),SCode.NON_PARALLEL(),SCode.VAR(),Absyn.OUTPUT()),
          Absyn.TPATH(Absyn.IDENT(id),NONE()),
          SCode.NOMOD(),SCode.noComment,NONE(),info);
  annotation(__OpenModelica_EarlyInline = true);
end buildRecordConstructorResultElt;

protected function lookupClassInEnv
 "Helper function to lookupClass2. Searches the environment for the class.
  It first checks the current scope, and then base classes. The specification
  says that we first search elements in the current scope (+ the ones inherited
  from base classes)"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input String id;
  input FCore.Scope inPrevFrames;
  input Util.StatefulBoolean inState;
  input Boolean inMsg;
  output FCore.Cache outCache;
  output SCode.Element outClass;
  output FCore.Graph outEnv;
  output FCore.Scope outPrevFrames;
algorithm
  (outCache,outClass,outEnv,outPrevFrames) := matchcontinue (inCache,inEnv,id,inPrevFrames,inState,inMsg)
    local
      SCode.Element c;
      FCore.Graph env_1,env,fs,i_env;
      FCore.Scope prevFrames;
      FCore.Node frame;
      FCore.Ref r;
      FCore.Scope rs;
      String sid,scope;
      Boolean msg,msgflag;
      FCore.Cache cache;

    case (cache,env as FCore.G(scope = r::_),_,prevFrames,_,msg)
      equation
        frame = FNode.fromRef(r);
        (cache,c,env_1,prevFrames) = lookupClassInFrame(cache, frame, env, id, prevFrames, inState, msg);
        Util.setStatefulBoolean(inState,true);
      then
        (cache,c,env_1,prevFrames);

    case (cache,env as FCore.G(scope = r :: _),_,prevFrames,_,_)
      equation
        false = FNode.isRefTop(r);
        frame = FNode.fromRef(r);
        sid = FNode.refName(r);
        true = FNode.isEncapsulated(frame);
        true = stringEq(id, sid) "Special case if looking up the class that -is- encapsulated. That must be allowed." ;
        (env, _) = FGraph.stripLastScopeRef(env);
        (cache,c,env,prevFrames) = lookupClassInEnv(cache, env, id, r::prevFrames, inState, true);
        Util.setStatefulBoolean(inState,true);
      then
        (cache,c,env,prevFrames);

    // lookup stops at encapsulated classes except for builtin
    // scope, if not found in builtin scope, error
    case (cache,env as FCore.G(scope = r :: _),_,_,_,true)
      equation
        false = FNode.isRefTop(r);
        frame = FNode.fromRef(r);
        true = FNode.isEncapsulated(frame);
        i_env = FGraph.topScope(env);
        failure((_,_,_,_) = lookupClassInEnv(cache, i_env, id, {}, inState, false));
        scope = FGraph.printGraphPathStr(env);
        Error.addMessage(Error.LOOKUP_ERROR, {id,scope});
      then
        fail();

    // lookup stops at encapsulated classes, except for builtin scope
    case (cache, env as FCore.G(scope = r::_),_,prevFrames,_,msgflag)
      equation
        frame = FNode.fromRef(r);
        true = FNode.isEncapsulated(frame);
        i_env = FGraph.topScope(env);
        (cache,c,env_1,prevFrames) = lookupClassInEnv(cache, i_env, id, {}, inState, msgflag);
        Util.setStatefulBoolean(inState,true);
      then
        (cache,c,env_1,prevFrames);

    // if not found and not encapsulated, and no ident has been previously found, look in next enclosing scope
    case (cache,env as FCore.G(scope = r::_),_,prevFrames,_,msgflag)
      equation
        false = FNode.isRefTop(r);
        frame = FNode.fromRef(r);
        false = FNode.isEncapsulated(frame);
        false = Util.getStatefulBoolean(inState);
        (env, _) = FGraph.stripLastScopeRef(env);
        (cache,c,env_1,prevFrames) = lookupClassInEnv(cache, env, id, r::prevFrames, inState, msgflag);
        Util.setStatefulBoolean(inState, true);
      then
        (cache,c,env_1,prevFrames);

  end matchcontinue;
end lookupClassInEnv;

protected function lookupClassInFrame "Search for a class within one frame."
  input FCore.Cache inCache;
  input FCore.Node inFrame;
  input FCore.Graph inEnv;
  input SCode.Ident inIdent;
  input FCore.Scope inPrevFrames;
  input Util.StatefulBoolean inState;
  input Boolean inBoolean;
  output FCore.Cache outCache;
  output SCode.Element outClass;
  output FCore.Graph outEnv;
  output FCore.Scope outPrevFrames;
algorithm
  (outCache,outClass,outEnv,outPrevFrames) := matchcontinue (inCache,inFrame,inEnv,inIdent,inPrevFrames,inState,inBoolean)
    local
      SCode.Element c;
      FCore.Graph totenv,env_1;
      FCore.Scope prevFrames;
      FCore.Ref r;
      Option<String> sid;
      FCore.Children ht;
      String name;
      list<Absyn.Import> qimports, uqimports;
      FCore.Cache cache;
      Boolean unique;

    // Check this scope for class
    case (cache,FCore.N(children = ht),totenv,name,prevFrames,_,_)
      equation
        r = FNode.avlTreeGet(ht, name);
        FCore.N(data = FCore.CL(e = c)) = FNode.fromRef(r);
      then
        (cache,c,totenv,prevFrames);

    // Search in imports
    case (cache,_,totenv,name,_,_,_)
      equation
        (qimports, uqimports) = FNode.imports(inFrame);
        _ = matchcontinue (qimports, uqimports)
          // Search among the qualified imports, e.g. import A.B; or import D=A.B;
          case (_::_, _)
            equation
              (cache,c,env_1,prevFrames) = lookupQualifiedImportedClassInFrame(cache,qimports,totenv,name,inState);
            then ();
          // Search among the unqualified imports, e.g. import A.B.*;
          case (_, _::_)
            equation
              (cache,c,env_1,prevFrames,unique) = lookupUnqualifiedImportedClassInFrame(cache,uqimports,totenv,name);
              Util.setStatefulBoolean(inState,true);
              reportSeveralNamesError(unique,name);
            then ();
        end matchcontinue;
      then
        (cache,c,env_1,prevFrames);

  end matchcontinue;
end lookupClassInFrame;

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
"Helper function to lookupVarF and lookupIdent."
  input FCore.Children inBinTree;
  input SCode.Ident inIdent;
  input FCore.Graph inGraph;
  output DAE.Var outVar;
  output SCode.Element outElement;
  output DAE.Mod outMod;
  output FCore.Status instStatus;
  output FCore.Graph outEnv;
protected
  FCore.Ref r;
  FCore.Scope s;
  FCore.Node n;
  String name;
algorithm
  r := FNode.avlTreeGet(inBinTree, inIdent);
  outVar := FNode.refInstVar(r);
  s := FNode.refRefTargetScope(r);
  n := FNode.fromRef(r);

  if not FNode.isComponent(n) and Flags.isSet(Flags.LOOKUP) then
    // MetaModelica function references generate too much failtrace...
    false := Config.acceptMetaModelicaGrammar();
    FCore.N(data = FCore.CL(e = SCode.CLASS(name = name))) := n;
    name := inIdent + " = " + FGraph.printGraphPathStr(inGraph) + "." + name;
    Debug.traceln("- Lookup.lookupVar2 failed because we found a class instead of a variable: " + name);
    fail();
  end if;

  FCore.N(data = FCore.CO(outElement, outMod, _, instStatus)) := n;
  outEnv := FGraph.setScope(inGraph, s);
end lookupVar2;

protected function checkSubscripts "This function checks a list of subscripts agains type, and removes
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
        _ = Expression.dimensionSize(dim);
        t_1 = checkSubscripts(t, ys);
        dim_int = listLength(se) "FIXME: Check range IMPLEMENTED 2007-05-18 BZ" ;
      then
        DAE.T_ARRAY(t_1,{DAE.DIM_INTEGER(dim_int)},ts);

    case (DAE.T_ARRAY(dims = {_}, ty = t, source = ts),
          (DAE.SLICE(exp = e) :: ys))
      equation
        DAE.T_ARRAY(dims={dim}) = Expression.typeof(e);
        t_1 = checkSubscripts(t, ys);
      then
        DAE.T_ARRAY(t_1, {dim}, ts);

    case (DAE.T_ARRAY(dims = {dim}, ty = t),
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
          (DAE.INDEX() :: ys))
      equation
        true = Expression.dimensionKnown(dim);
        t_1 = checkSubscripts(t, ys);
      then
        t_1;

    case (DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()}, ty = t),
          (DAE.INDEX() :: ys))
      equation
        t_1 = checkSubscripts(t, ys);
      then
        t_1;

    case (DAE.T_ARRAY(dims = {DAE.DIM_EXP()}, ty = t),
          (DAE.INDEX() :: ys))
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

    case (DAE.T_METAARRAY(), {DAE.INDEX()}) then inType.ty;
    case (DAE.T_METAARRAY(), {_}) then inType;

    case (t,s)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Lookup.checkSubscripts failed (tp: ");
        Debug.trace(Types.printTypeStr(t));
        Debug.trace(" subs:");
        Debug.trace(stringDelimitList(List.map(s,ExpressionDump.printSubscriptStr),","));
        Debug.trace(")\n");
      then
        fail();
  end matchcontinue;
end checkSubscripts;

protected function lookupVarF
"This function looks in a frame to find a declared variable.  If
  the name being looked up is qualified, the first part of the name
  is looked up, and lookupVar2 is used to for further lookup in
  the result of that lookup.
  2007-05-29 If we can construct a expression, we do after expanding the
  subscript with dimensions to fill the Cref."
  input FCore.Cache inCache;
  input FCore.Children inBinTree;
  input DAE.ComponentRef inComponentRef;
  input FCore.Graph inEnv;
  output FCore.Cache outCache;
  output DAE.Attributes outAttributes;
  output DAE.Type outType;
  output DAE.Binding outBinding;
  output Option<DAE.Const> constOfForIteratorRange "SOME(constant-ness) of the range if this is a for iterator, NONE() if this is not a for iterator";
  output InstTypes.SplicedExpData splicedExpData;
  output FCore.Graph outComponentEnv;
  output String name;
algorithm
  (outCache,outAttributes,outType,outBinding,constOfForIteratorRange,splicedExpData,outComponentEnv,name) :=
  matchcontinue (inCache,inBinTree,inComponentRef,inEnv)
    local
      String id,id2;
      SCode.ConnectorType ct;
      SCode.Parallelism prl;
      SCode.Variability vt,vt2;
      Absyn.Direction di;
      DAE.Type ty,ty_1,idTp,ty2_2, tyParent, tyChild, ty1,ty2;
      DAE.Binding bind,binding, parentBinding;
      FCore.Children ht;
      list<DAE.Subscript> ss;
      FCore.Graph componentEnv;
      DAE.ComponentRef ids;
      FCore.Cache cache;
      Absyn.InnerOuter io;
      Option<DAE.Exp> texp;
      DAE.ComponentRef xCref,tCref,cref_;
      list<DAE.ComponentRef> ltCref;
      DAE.Exp splicedExp;
      DAE.Type eType,tty;
      Option<DAE.Const> cnstForRange;
      SCode.Visibility vis;
      DAE.Attributes attr;
      list<DAE.Var> fields;
      Option<DAE.Exp> oSplicedExp;

    // Simple identifier
    case (cache,ht,DAE.CREF_IDENT(ident = id,subscriptLst = ss),_)
      equation
        (DAE.TYPES_VAR(name,attr,ty,bind,cnstForRange),_,_,_,componentEnv) = lookupVar2(ht, id, inEnv);
        ty_1 = checkSubscripts(ty, ss);
        tty = Types.simplifyType(ty);
        ss = addArrayDimensions(tty,ss);
        cref_ = ComponentReference.makeCrefIdent(id,tty, ss);
        splicedExp = Expression.makeCrefExp(cref_,tty);
        //print("splicedExp ="+ExpressionDump.dumpExpStr(splicedExp,0)+"\n");
      then
        (cache,attr,ty_1,bind,cnstForRange,InstTypes.SPLICEDEXPDATA(SOME(splicedExp),ty),componentEnv,name);

    // Qualified variables looked up through component environment with or without spliced exp
    case (cache,ht,DAE.CREF_QUAL(ident = id,subscriptLst = ss,componentRef = ids), _)
      equation
        (DAE.TYPES_VAR(_,DAE.ATTR(variability = vt2),tyParent,parentBinding,_),_,_,_,componentEnv) = lookupVar2(ht, id, inEnv);

        // leave just the last scope from component env as it SHOULD BE ONLY THERE, i.e. don't go on searching the parents!
        // componentEnv = FGraph.setScope(componentEnv, List.create(FGraph.lastScopeRef(componentEnv)));

        (cache,DAE.ATTR(ct,prl,vt,di,io,vis),tyChild,binding,cnstForRange,InstTypes.SPLICEDEXPDATA(texp,idTp),_,componentEnv,name) = lookupVar(cache, componentEnv, ids);

        ltCref = elabComponentRecursive((texp));
        _ = match ltCref
          case (tCref::_) // with a spliced exp
            equation
             ty = if Types.isBoxedType(tyParent) and not Types.isUnknownType(tyParent)
                  then Types.boxIfUnboxedType(tyChild)
                  else tyChild "The internal types in a metarecord are lookup up in a clean environment, so we have to box them";
             ty1 = checkSubscripts(tyParent, ss);
             ty = sliceDimensionType(ty1,ty);
             ty2_2 = Types.simplifyType(tyParent);
             ss = addArrayDimensions(ty2_2,ss);
             xCref = ComponentReference.makeCrefQual(id,ty2_2,ss,tCref);
             eType = Types.simplifyType(ty);
             splicedExp = Expression.makeCrefExp(xCref,eType);
             oSplicedExp = SOME(splicedExp);
           then ();
          case ({}) // without spliced Expression
            equation
              oSplicedExp = NONE();
             then ();
        end match;
        vt = SCode.variabilityOr(vt,vt2);
        binding = lookupBinding(inComponentRef, tyParent, ty, parentBinding, binding);
      then
        (cache,DAE.ATTR(ct,prl,vt,di,io,vis),ty,binding,cnstForRange,InstTypes.SPLICEDEXPDATA(oSplicedExp,idTp),componentEnv,name);

    // MetaModelica meta-records
    case (cache,ht,(DAE.CREF_QUAL(ident = id,subscriptLst = {},componentRef = DAE.CREF_IDENT(ident=id2,subscriptLst={}))), _)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (DAE.TYPES_VAR(ty=DAE.T_METARECORD(fields=fields)),_,_,_,componentEnv) = lookupVar2(ht, id, inEnv);
        DAE.TYPES_VAR(name,attr,ty,binding,cnstForRange) = listGet(fields,Types.findVarIndex(id2,fields)+1);
      then
        (cache,attr,ty,binding,cnstForRange,InstTypes.SPLICEDEXPDATA(NONE(),ty),componentEnv,name);

  end matchcontinue;
end lookupVarF;

protected function lookupBinding
"@author: adrpo
 this function uses the binding of the parent
 if the parent is an array of records"
  input DAE.ComponentRef inCref;
  input DAE.Type inParentType;
  input DAE.Type inChildType;
  input DAE.Binding inParentBinding;
  input DAE.Binding inChildBinding;
  output DAE.Binding outBinding;
algorithm
  outBinding := matchcontinue(inCref, inParentType, inChildType, inParentBinding, inChildBinding)
    local
      DAE.Type tyElement;
      DAE.Binding b;
      DAE.Exp e;
      Option<Values.Value> ov;
      Values.Value v;
      DAE.Const c;
      DAE.BindingSource s;
      list<DAE.Subscript> ss;
      DAE.ComponentRef rest;
      String id, cId;
      list<DAE.Exp> exps;
      list<String> comp;

    case (DAE.CREF_QUAL(_, _, ss, DAE.CREF_IDENT(cId, _, {})), _, _, DAE.EQBOUND(e, _, c, s), _)
      equation
        true = Types.isArray(inParentType);
        tyElement = Types.arrayElementType(inParentType);
        true = Types.isRecord(tyElement);

        // print("CREF EB: " + ComponentReference.printComponentRefStr(inCref) + "\nTyParent: " + Types.printTypeStr(inParentType) + "\nParent:\n" + Types.printBindingStr(inParentBinding) + "\nChild:\n" + Types.printBindingStr(inChildBinding) + "\n");

        DAE.RECORD(_, exps, comp, _) = Expression.subscriptExp(e, ss);

        e = listGet(exps, List.position(cId, comp));
        b = DAE.EQBOUND(e, NONE(), c, s);

        // print("CREF EB RESULT: " + ComponentReference.printComponentRefStr(inCref) + "\nBinding:\n" + Types.printBindingStr(b) + "\n");
      then
        b;

    /*
    case (DAE.CREF_QUAL(id, _, ss, DAE.CREF_IDENT(cId, _, {})), _, _, DAE.EQBOUND(e, ov, c, s), _)
      equation
        true = Types.isArray(inParentType);
        tyElement = Types.arrayElementType(inParentType);
        true = Types.isRecord(tyElement);
        // e = Expression.makeCrefExp(inCref, Expression.typeof(e));
        // b = DAE.EQBOUND(e, NONE(), c, s);
      then
        inChildBinding;*/

    case (DAE.CREF_QUAL(_, _, ss, DAE.CREF_IDENT(cId, _, {})), _, _, DAE.VALBOUND(v, s), _)
      equation
        true = Types.isArray(inParentType);
        tyElement = Types.arrayElementType(inParentType);
        true = Types.isRecord(tyElement);
        // print("CREF VB: " + ComponentReference.printComponentRefStr(inCref) + "\nTyParent: " + Types.printTypeStr(inParentType) + "\nParent:\n" + Types.printBindingStr(inParentBinding) + "\nChild:\n" + Types.printBindingStr(inChildBinding) + "\n");
        e = ValuesUtil.valueExp(v);
        DAE.RECORD(_, exps, comp, _) = Expression.subscriptExp(e, ss);

        e = listGet(exps, List.position(cId, comp));

        b = DAE.EQBOUND(e, NONE(), DAE.C_CONST(), s);
        // print("CREF VB RESULT: " + ComponentReference.printComponentRefStr(inCref) + "\nBinding:\n" + Types.printBindingStr(b) + "\n");
      then
        b;

    /*
    case (DAE.CREF_QUAL(id, _, ss, DAE.CREF_IDENT(cId, _, {})), _, _, DAE.VALBOUND(v, s), _)
      equation
        true = Types.isArray(inParentType);
        tyElement = Types.arrayElementType(inParentType);
        true = Types.isRecord(tyElement);
        //e = Expression.makeCrefExp(inCref, inChildType);
        //b = DAE.EQBOUND(e, NONE(), DAE.C_CONST(), s);
      then
        inChildBinding;*/

    else inChildBinding;

  end matchcontinue;
end lookupBinding;

protected function elabComponentRecursive "
Helper function for lookupvarF, to return an ComponentRef if there is one."
  input Option<DAE.Exp> oCref;
  output list<DAE.ComponentRef> lref;
algorithm
  lref := match(oCref)
    local
      Option<DAE.Exp> exp;DAE.ComponentRef ecpr;

    // expression is an unqualified component reference
    case( SOME(DAE.CREF(ecpr as DAE.CREF_IDENT(_,_,_),_ )))  then (ecpr::{});

    // expression is an qualified component reference
    case( SOME(DAE.CREF(ecpr as DAE.CREF_QUAL(_,_,_,_),_ ))) then (ecpr::{});

    else {};
  end match;
end elabComponentRecursive;

protected function addArrayDimensions "This is the function where we add arrays representing the dimension of the type.
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
        true = Types.isArray(tySub);
        dims = Types.getDimensions(tySub);
        subs = List.map(dims, makeDimensionSubscript);
        subs = expandWholeDimSubScript(ss,subs);
      then subs;
    else ss; // non array, return
  end matchcontinue;
end addArrayDimensions;

protected function makeDimensionSubscript
  "Creates a slice with all indices of the dimension."
  input DAE.Dimension inDim;
  output DAE.Subscript outSub;
algorithm
  outSub := match(inDim)
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

    // Array with boolean dimension.
    case DAE.DIM_BOOLEAN()
      equation
        expl = {DAE.BCONST(false), DAE.BCONST(true)};
      then
        DAE.SLICE(DAE.ARRAY(DAE.T_BOOL_DEFAULT, true, expl));

    // Array with enumeration dimension.
    case DAE.DIM_ENUM(enumTypeName = enum_name, literals = l)
      equation
        expl = makeEnumLiteralIndices(enum_name, l, 1);
      then
        DAE.SLICE(DAE.ARRAY(DAE.T_ENUMERATION(NONE(), enum_name, l, {}, {}, DAE.emptyTypeSource), true, expl));
  end match;
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
    case (((sub1 as DAE.INDEX(exp = DAE.CREF())) :: subs1),
      subs2)
      equation
        subs2 = expandWholeDimSubScript(subs1, subs2);
      then
        (sub1 :: subs2);
    case(_,{}) then {};
    case({},subs2) then subs2;
    case(((DAE.WHOLEDIM())::subs1), (sub2::subs2))
      equation
        subs2 = expandWholeDimSubScript(subs1,subs2);
      then
        (sub2::subs2);
    case((sub1::subs1), (_::subs2))
      equation
        subs2 = expandWholeDimSubScript(subs1,subs2);
      then
        (sub1::subs2);
  end matchcontinue;
end expandWholeDimSubScript;

protected function sliceDimensionType "Lifts an type to spcified dimension by type2
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.Element cdef;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output DAE.Type ftype;
protected
  String id;
  FCore.Graph env_1,env;
  Absyn.Path utPath,path;
  Integer index;
  list<DAE.Var> varlst;
  list<SCode.Element> els;
  Boolean singleton;
  DAE.TypeSource ts;
  FCore.Cache cache;
algorithm
  SCode.CLASS(name=id,restriction=SCode.R_METARECORD(utPath,index,singleton),classDef=SCode.PARTS(elementLst = els)) := cdef;
  env := FGraph.openScope(inEnv, SCode.NOT_ENCAPSULATED(), SOME(id), SOME(FCore.CLASS_SCOPE()));
  // print("buildMetaRecordType " + id + " in scope " + FGraph.printGraphPathStr(env) + "\n");
  (cache,utPath) := Inst.makeFullyQualified(inCache,env,utPath);
  path := Absyn.joinPaths(utPath, Absyn.IDENT(id));
  (outCache,outEnv,_,_,_,_,_,varlst,_) := Inst.instElementList(
    cache,env,InnerOuter.emptyInstHierarchy, UnitAbsyn.noStore,
    DAE.NOMOD(),Prefix.NOPRE(),
    ClassInf.META_RECORD(Absyn.IDENT("")), List.map1(els,Util.makeTuple,DAE.NOMOD()),
    {}, false, InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, Connect.emptySet, true);
  varlst := Types.boxVarLst(varlst);
  ts := Types.mkTypeSource(SOME(path));
  ftype := DAE.T_METARECORD(utPath,index,varlst,singleton,ts);
  // print("buildMetaRecordType " + id + " in scope " + FGraph.printGraphPathStr(env) + " OK " + Types.unparseType(ftype) +"\n");
end buildMetaRecordType;

public function isIterator
  "Looks up a cref and returns SOME(true) if it references an iterator,
   SOME(false) if it references an element in the current scope, and NONE() if
   the name couldn't be found in the current scope at all."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.ComponentRef inCref;
  output Option<Boolean> outIsIterator;
  output FCore.Cache outCache;
algorithm
  (outIsIterator, outCache) := matchcontinue(inCache, inEnv, inCref)
    local
      String id;
      FCore.Cache cache;
      FCore.Graph env;
      FCore.Children ht;
      Option<Boolean> res;
      Option<DAE.Const> ic;
      FCore.Ref ref;
      Boolean b;

    // Look in the current scope.
    case (cache, FCore.G(scope = ref::_), _)
      algorithm
        ht := FNode.children(FNode.fromRef(ref));
        // Only look up the first part of the cref, we're only interested in if
        // it exists and if it's an iterator or not.
        id := ComponentReference.crefFirstIdent(inCref);
        (DAE.TYPES_VAR(constOfForIteratorRange = ic),_,_,_,_) := lookupVar2(ht, id, inEnv);
        b := Util.isSome(ic);
      then
        (SOME(b), cache);

    // If not found, look in the next scope only if the current scope is implicit.
    case (cache, FCore.G(scope = ref::_), _)
      algorithm
        true := frameIsImplAddedScope(FNode.fromRef(ref));
        (env, _) := FGraph.stripLastScopeRef(inEnv);
        (res, cache) := isIterator(cache, env, inCref);
      then
        (res, cache);

    else (NONE(), inCache);

  end matchcontinue;
end isIterator;

public function isFunctionCallViaComponent
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  output Boolean yes;
algorithm
  yes := matchcontinue(inCache, inEnv, inPath)
    local
      Absyn.Ident name;
    // see if the first path ident is a component
    // we might have a component reference, i.e. world.gravityAcceleration
    case (_, _, Absyn.QUALIFIED(name, _))
      equation
        ErrorExt.setCheckpoint("functionViaComponentRef10");
        (_,_,_,_,_,_,_,_,_) = lookupVar(inCache, inEnv, ComponentReference.makeCrefIdent(name, DAE.T_UNKNOWN_DEFAULT, {}));
        ErrorExt.rollBack("functionViaComponentRef10");
      then
        true;

    case (_, _, Absyn.QUALIFIED(_, _))
      equation
        ErrorExt.rollBack("functionViaComponentRef10");
      then
        fail();

    else false;

  end matchcontinue;
end isFunctionCallViaComponent;

annotation(__OpenModelica_Interface="frontend");
end Lookup;
