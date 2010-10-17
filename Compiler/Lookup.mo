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

package Lookup
"
  file:         Lookup.mo
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
public import RTOpts;
public import SCode;
public import Util;
public import Types;

protected import Builtin;
protected import Connect;
protected import ConnectionGraph;
protected import Debug;
protected import Error;
protected import Exp;
protected import Inst;
protected import InstExtends;
protected import InnerOuter;
protected import Mod;
protected import Prefix;
protected import Static;
protected import UnitAbsyn;
protected import DAEUtil;
// protected import ModUtil;

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
  input Boolean inBoolean "Messaage flag, true outputs lookup error messages";
  output Env.Cache outCache;
  output DAE.Type outType "the found type";
  output Env.Env outEnv "The environment the type was found in";
algorithm
  (outCache,outType,outEnv):=
  matchcontinue (inCache,inEnv,inPath,inBoolean)
    local
      DAE.Type t;
      list<Env.Frame> env_1,env,env_2;
      Absyn.Path path;
      SCode.Class c;
      Boolean msg;
      String classname,scope;
      Env.Cache cache;

    // Special handling for Connections.isRoot
    case (cache,env,Absyn.QUALIFIED("Connections", Absyn.IDENT("isRoot")),msg)
      equation
        t = (DAE.T_FUNCTION({("x", (DAE.T_ANYTYPE(NONE), NONE))}, DAE.T_BOOL_DEFAULT, DAE.NO_INLINE), NONE);
      then
        (cache, t, env);

    // Special handling for MultiBody 3.x rooted() operator
    case (cache,env,Absyn.IDENT("rooted"),msg)
      equation
        t = (DAE.T_FUNCTION({("x", (DAE.T_ANYTYPE(NONE), NONE))}, DAE.T_BOOL_DEFAULT, DAE.NO_INLINE), NONE);
      then
        (cache, t, env);

      // For simple names
    case (cache,env,(path as Absyn.IDENT(name = _)),msg)
      equation
        (cache,t,env_1) = lookupTypeInEnv(cache,env,path);
      then
        (cache,t,env_1);

      // Special classes (function, record, metarecord, external object)
    case (cache,env,path,msg) local String ident,s;
      equation
        (cache,c,env_1) = lookupClass(cache,env,path,false);
        (cache,t,env_2) = lookupType2(cache,env_1,path,c);
      then
        (cache,t,env_2);

       // Error for type not found
    case (cache,env,path,true)
      equation
        classname = Absyn.pathString(path);
        classname = stringAppend(classname," (its type) ");
        scope = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_ERROR, {classname,scope});
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
  input SCode.Class inClass "the class lookupType found";
  output Env.Cache outCache;
  output DAE.Type outType "the found type";
  output Env.Env outEnv "The environment the type was found in";
algorithm
  (outCache,outType,outEnv) := matchcontinue (inCache,inEnv,inPath,inClass)
    local
      DAE.Type t;
      list<Env.Frame> env_1,env_2,env_3;
      Absyn.Path path,utPath;
      SCode.Class c;
      String id;
      SCode.Restriction restr;
      Env.Cache cache;
      list<DAE.Var> varlst;

    // Record constructors
    case (cache,env_1,path,c as SCode.CLASS(name=id,restriction=SCode.R_RECORD()))
      equation
        (cache,env_1,t) = buildRecordType(cache,env_1,c);
      then
        (cache,t,env_1);

    // lookup of an enumeration type
    case (cache,env_1,path,c as SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=r as SCode.R_ENUMERATION()))
      local
        SCode.Restriction r;
        list<Types.Var> types;
        list<String> names;
        ClassInf.State ci_state;
        Boolean encflag;
      equation
        env_2 = Env.openScope(env_1, encflag, SOME(id), SOME(Env.CLASS_SCOPE));
        ci_state = ClassInf.start(r, Env.getEnvName(env_2));
        (cache,env_3,_,_,_,_,_,types,_,_,_,_) =
        Inst.instClassIn(
          cache,env_2,InnerOuter.emptyInstHierarchy,UnitAbsyn.noStore,
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet,
          ci_state, c, false, {}, false, ConnectionGraph.EMPTY,NONE);
        // build names
        (_,names) = SCode.getClassComponents(c);
        // generate the enumeration type
        t = (DAE.T_ENUMERATION(NONE, path, names, types, {}), SOME(path));
        env_3 = Env.extendFrameT(env_3, id, t);
      then
        (cache,t,env_3);

    // Metamodelica extension, Uniontypes
    case (cache,env_1,path,c as SCode.CLASS(name=id,restriction=SCode.R_METARECORD(utPath,index),classDef=SCode.PARTS(elementLst = els)))
      local
        Integer index;
        list<SCode.Element> els;
        list<tuple<SCode.Element,DAE.Mod>> elsModList;
      equation
        (cache,utPath) = Inst.makeFullyQualified(cache,env_1,utPath);
        path = Absyn.joinPaths(utPath, Absyn.IDENT(id));
        elsModList = Util.listMap1(els,Util.makeTuple2,DAE.NOMOD);
        (cache,env_2,_,_,_,_,_,varlst,_) = Inst.instElementList(
            cache,env_1,InnerOuter.emptyInstHierarchy, UnitAbsyn.noStore,
            DAE.NOMOD,Prefix.NOPRE, Connect.emptySet, ClassInf.FUNCTION(Absyn.IDENT("")), elsModList, {}, false, ConnectionGraph.EMPTY);
        t = (DAE.T_METARECORD(utPath,index,varlst),SOME(path));
      then
        (cache,t,env_2);

    // Classes that are external objects. Implicitly instantiate to get type
    case (cache,env_1,path,c)
      local
      equation
        true = Inst.classIsExternalObject(c);
        (cache,_::env_1,_,_,_,_,_,_,_,_) =
        Inst.instClass(
          cache,env_1,InnerOuter.emptyInstHierarchy, UnitAbsyn.noStore,
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c,
          {}, false, Inst.TOP_CALL(), ConnectionGraph.EMPTY);
        SCode.CLASS(name=id) = c;
        (cache,t,env_2) = lookupTypeInEnv(cache,env_1,Absyn.IDENT(id));
      then
        (cache,t,env_2);

    // If we find a class definition that is a function or external function
    // with the same name then we implicitly instantiate that function, look
    // up the type.
    case (cache,env_1,path,c as SCode.CLASS(name = id,restriction=restr))
      equation
        true = SCode.isFunctionOrExtFunction(restr);
        (cache,env_2,_) =
        Inst.implicitFunctionTypeInstantiation(cache,env_1,InnerOuter.emptyInstHierarchy,c);
        (cache,t,env_3) = lookupTypeInEnv(cache,env_2,Absyn.IDENT(id));
      then
        (cache,t,env_3);
  end matchcontinue;
end lookupType2;

protected function lookupTypeList
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Path> paths;
  input Boolean bool;
  output Env.Cache outCache;
  output list<DAE.Type> types;
algorithm
  (outCache,types) := matchcontinue (inCache, inEnv, paths, bool)
    local
      Env.Cache cache;
      Env.Env env;
      Absyn.Path first;
      list<Absyn.Path> rest;
      DAE.Type ty;
      list<DAE.Type> tys;
    case (cache, env, {}, _) then (cache,{});
    case (cache, env, first::rest, bool)
      equation
        (cache, ty, _) = lookupType(cache, env, first, bool);
        (cache, tys) = lookupTypeList(cache, env, rest, bool);
      then (cache,ty::tys);
  end matchcontinue;
end lookupTypeList;

public function lookupMetarecordsRecursive
"Takes a list of paths to Uniontypes. Use this list to create a list of T_METARECORD.
The function is guarded against recursive definitions by accumulating all paths it
starts to traverse."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Path> inUniontypePaths;
  input list<Absyn.Path> inAcc;
  output Env.Cache outCache;
  output list<DAE.Type> outMetarecordTypes;
algorithm
  (outCache,outMetarecordTypes) := matchcontinue (inCache, inEnv, inUniontypePaths, inAcc)
    local
      Env.Cache cache;
      Env.Env env;
      Absyn.Path first;
      list<Absyn.Path> metarecordPaths, rest, acc;
      list<DAE.Type> metarecordTypes, metarecordTypes1, metarecordTypes2, uniontypeTypes, innerTypes;
      list<list<Absyn.Path>> uniontypePaths;
      DAE.Type ty;
    case (cache, _, {}, _) then (cache, {});
    case (cache, env, first::rest, acc)
      equation
        false = listMember(first, acc);
        acc = first::acc;
        (cache, ty, _) = lookupType(cache, env, first, true);
        uniontypeTypes = Types.getAllInnerTypesOfType(ty, Types.uniontypeFilter);
        uniontypePaths =  Util.listMap(uniontypeTypes, Types.getUniontypePaths);
        rest = Util.listFlatten(rest :: uniontypePaths);
        (cache, metarecordTypes2) = lookupMetarecordsRecursive(cache, env, rest, acc);
        metarecordTypes = ty :: metarecordTypes2;
      then (cache, metarecordTypes);
    case (cache, env, first::rest, acc)
      equation
        true = listMember(first, acc);
        (cache, metarecordTypes) = lookupMetarecordsRecursive(cache, env, rest, acc);
      then (cache, metarecordTypes);
    case (_, _, _, _)
      equation
        Debug.fprintln("failtrace", "- Lookup.lookupMetarecordsRecursive failed");
      then fail();
  end matchcontinue;
end lookupMetarecordsRecursive;

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
  output SCode.Class outClass;
  output Env.Env outEnv;
protected
  Real t1,t2,time;
  Boolean b;
  String s,s2;
algorithm
  (outCache,outClass,outEnv,_) := lookupClass2(inCache,inEnv, inPath, {}, Util.makeStatefulBoolean(false), msg);
end lookupClass;

protected function lookupClass2 "help function to lookupClass, does all the work."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath "The path of the class to lookup";
  input list<Env.Frame> inPrevFrames "Environment in reverse order. Contains frames we previously had in the scope. Will be looked up instead of the environment in order to avoid infinite recursion.";
  input Util.StatefulBoolean inState "If true, we have found a class. If the path was qualified, we should no longer look in previous frames of the environment";
  input Boolean msg "Print error messages";
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv "The environment in which the class was found (not the environment inside the class)";
  output list<Env.Frame> outPrevFrames;
algorithm
  (inCache,outClass,outEnv) := matchcontinue (inCache,inEnv,inPath,inPrevFrames,inState,msg)
    local
      Env.Frame f,frame;
      Env.Cache cache;
      SCode.Class c,c_1;
      list<Env.Frame> env,env_1,env2,env_2,env_3,env1,env4,env5,fs,prevFrames;
      Absyn.Path path,ep,packp,p,scope,restPath;
      String sid,id,s,name,pack;

    // First look in cache for environment. If found look up class in that environment.
    case (cache,env,path,prevFrames,inState,msg)
      equation        
        // Debug.traceln("lookupClass " +& Absyn.pathString(path) +& " s:" +& Env.printEnvPathStr(env));
        SOME(scope) = Env.getEnvPath(env);
        f::fs = Env.cacheGet(scope,path,cache);
        Util.setStatefulBoolean(inState,true);
        id = Absyn.pathLastIdent(path);
        (cache,c,env,prevFrames) = lookupClassInEnv(cache,fs,id,{},inState,msg);
        //print("HIT:");print(Absyn.pathString(path));print(" scope");print(Absyn.pathString(scope));print("\n");
        //print(Env.printCacheStr(cache));
      then
        (cache,c,env,prevFrames);

    // Fully qualified names are looked up in top scope. With previous frames remembered.
    case (cache,env,Absyn.FULLYQUALIFIED(path),{},inState,msg)
      equation 
        f::prevFrames = listReverse(env);
        Util.setStatefulBoolean(inState,true);
        (cache,c,env_1,prevFrames) = lookupClass2(cache,{f},path,prevFrames,inState,msg);
      then
        (cache,c,env_1,prevFrames);

    // Qualified names are handled in a special function in order to avoid infinite recursion.
    case (cache,env,(p as Absyn.QUALIFIED(name = pack,path = path)),prevFrames,inState,msg)
      local
        Option<Env.Frame> optFrame;
      equation
        (optFrame,prevFrames) = lookupPrevFrames(pack,prevFrames);
        (cache,c,env_2,prevFrames) = lookupClassQualified(cache,env,pack,path,optFrame,prevFrames,inState,msg);
      then       
        (cache,c,env_2,prevFrames);
              
    // Simple names
    case (cache,env,Absyn.IDENT(name = id),prevFrames,inState,msg)
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
  input Option<Env.Frame> optFrame;
  input list<Env.Frame> inPrevFrames "Environment in reverse order. Contains frames we previously had in the scope. Will be looked up instead of the environment in order to avoid infinite recursion.";
  input Util.StatefulBoolean inState "If true, we have found a class. If the path was qualified, we should no longer look in previous frames of the environment";
  input Boolean msg "Print error messages";
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv "The environment in which the class was found (not the environment inside the class)";
  output list<Env.Frame> outPrevFrames;
algorithm
  (outCache,outClass,outEnv,outPrevFrames) := matchcontinue (inCache,inEnv,id,path,optFrame,inPrevFrames,inState,msg)
    local
      SCode.Class c;
      Absyn.Path scope;
      Env.Cache cache;
      Env.Env env,prevFrames;
      Env.Frame frame;
    // Qualified names first identifier cached in previous frames
    case (cache,env,id,path,SOME(frame),prevFrames,inState,msg)
      equation
        Util.setStatefulBoolean(inState,true);
        env = frame::env;
        (cache,c,env,prevFrames) = lookupClass2(cache,env,path,prevFrames,inState,msg);
      then
        (cache,c,env,prevFrames);

    // Qualified names first identifier cached
    case (cache,env,id,path,NONE(),prevFrames,inState,msg)
      equation
        // false = Util.getStatefulBoolean(inState); ???
        SOME(scope) = Env.getEnvPath(env);
        env = Env.cacheGet(scope,Absyn.IDENT(id),cache);
        Util.setStatefulBoolean(inState,true);
        (cache,c,env,prevFrames) = lookupClass2(cache,env,path,{},inState,msg);
        //print("Qualified cache hit on ");print(Absyn.pathString(p));print("\n");
      then
        (cache,c,env,prevFrames);
            
    // Qualified names in package and non-package
    case (cache,env,id,path,NONE(),_,inState,msg)
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
  input SCode.Class c;
  input Option<Env.Frame> optFrame;
  input list<Env.Frame> inPrevFrames "Environment in reverse order. Contains frames we previously had in the scope. Will be looked up instead of the environment in order to avoid infinite recursion.";
  input Util.StatefulBoolean inState "If true, we have found a class. If the path was qualified, we should no longer look in previous frames of the environment";
  input Boolean msg "Print error messages";
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv "The environment in which the class was found (not the environment inside the class)";
  output list<Env.Frame> outPrevFrames;
algorithm
  (outCache,outClass,outEnv,outPrevFrames) := matchcontinue (inCache,inEnv,path,c,optFrame,inPrevFrames,inState,msg)
    local
      Env.Cache cache;
      Env.Env env,prevFrames;
      Env.Frame frame;
      SCode.Restriction restr;
      ClassInf.State ci_state,cistate1;
      Boolean encflag;
      String id;
    case (cache,env,path,_,SOME(frame),prevFrames,inState,msg)
      equation 
        env = frame::env;
        (cache,c,env,prevFrames) = lookupClass2(cache,env,path,prevFrames,inState,msg);
      then (cache,c,env,prevFrames);
    case (cache,env,path,SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr),NONE(),_,inState,msg)
      equation 
        env = Env.openScope(env, encflag, SOME(id), Env.restrictionToScopeType(restr));
        ci_state = ClassInf.start(restr, Env.getEnvName(env));
        (cache,env,_,_) =
        Inst.partialInstClassIn(
          cache,env,InnerOuter.emptyInstHierarchy,
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet,
          ci_state, c, false, {}); 
        // Was 2 cases for package/non-package - all they did was fail or succeed on this
        // If we comment it out, we get faster code, and less of it to maintain
        // ClassInf.valid(cistate1, SCode.R_PACKAGE());
        (cache,c,env,prevFrames) = lookupClass2(cache,env,path,{},inState,msg);
      then (cache,c,env,prevFrames);
  end matchcontinue;
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
    case (id,(frame as Env.FRAME(optName = SOME(sid)))::prevFrames)
      equation
        true = id ==& sid;
      then (SOME(frame),prevFrames);
    case (id,_) then (NONE(),{});
  end matchcontinue;
end lookupPrevFrames;

protected function lookupQualifiedImportedVarInFrame "function: lookupQualifiedImportedVarInFrame
  author: PA

  Looking up variables (constants) imported using qualified imports,
  i.e. import Modelica.Constants.PI;"
  input list<Env.Item> items;
  input SCode.Ident ident;
  output DAE.ComponentRef outCref;
algorithm 
  (outCref) := matchcontinue (items,ident)
    local
      Env.Frame fr;
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Binding bind;
      String id,id2,ident,str;
      list<Env.Item> fs;
      list<Env.Frame> env,p_env,cenv,prevFrames;
      DAE.ComponentRef cref;
      Absyn.Path strippath,path;
      SCode.Class c2;
      Env.Cache cache;
      Option<DAE.Const> cnstForRange;
      
      // For imported simple name, e.g. A, not possible to assert sub-path package 
    case (Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = path)) :: fs,ident) 
      equation 
        id = Absyn.pathLastIdent(path);
        true = id ==& ident;
      then Exp.pathToCref(path);

    // Named imports, e.g. import A = B.C;  
    case (Env.IMPORT(import_ = Absyn.NAMED_IMPORT(name = id,path = path)) :: fs,ident)
      equation
        true = id ==& ident;
      then Exp.pathToCref(path);

    // Check next frame.  
    case (_ :: fs,ident) then lookupQualifiedImportedVarInFrame(fs,ident);
  end matchcontinue;
end lookupQualifiedImportedVarInFrame;

protected function moreLookupUnqualifiedImportedVarInFrame "function: moreLookupUnqualifiedImportedVarInFrame
  Helper function for lookup_unqualified_imported_var_in_frame. Returns 
  true if there are unqualified imports that matches a sought constant."
  input Env.Cache inCache;
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output Boolean outBoolean;
algorithm
  (outCache,outBoolean) := matchcontinue (inCache,inEnvItemLst,inEnv,inIdent)
    local
      Env.Frame fr,f;
      SCode.Class c;
      String id,ident;
      Boolean encflag,res;
      SCode.Restriction restr;
      list<Env.Frame> env_1,env2,env,prevFrames;
      ClassInf.State ci_state;
      Absyn.Path path;
      list<Env.Item> fs;
      Env.Cache cache; 
      DAE.ComponentRef cr,cref;
      Absyn.Path path,scope;
      Absyn.Ident firstIdent;

    case (cache,(Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident)
      equation
        f::prevFrames = listReverse(env);
        cref = Exp.pathToCref(path);
        cref = Exp.joinCrefs(cref,DAE.CREF_IDENT(ident,DAE.ET_OTHER(),{}));
        (cache,_,_,_,_,_,_,_,_) = lookupVarInPackages(cache,{f},cref,prevFrames,Util.makeStatefulBoolean(false));
      then
        (cache,true);

    // look into the parent scope
    case (cache,(_ :: fs),env,ident)
      equation
        (cache,res) = moreLookupUnqualifiedImportedVarInFrame(cache, fs, env, ident);
      then
        (cache,res);

    // we reached the end, no more lookup
    case (cache,{},_,_) then (cache,false); 
  end matchcontinue;
end moreLookupUnqualifiedImportedVarInFrame;

protected function lookupUnqualifiedImportedVarInFrame "function: lookupUnqualifiedImportedVarInFrame
  Find a variable from an unqualified import locally in a frame"
  input Env.Cache inCache;
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output Env.Env outClassEnv;
  output DAE.Attributes outAttributes;
  output DAE.Type outType;
  output DAE.Binding outBinding;
  output Option<DAE.Const> constOfForIteratorRange "SOME(constant-ness) of the range if this is a for iterator, NONE if this is not a for iterator";  
  output Boolean outBoolean;
  output SplicedExpData splicedExpData;
  output Env.Env outComponentEnv;
  output String name;
algorithm
  (outCache,outClassEnv,outAttributes,outType,outBinding,constOfForIteratorRange,outBoolean,splicedExpData,outComponentEnv,name):=
  matchcontinue (inCache,inEnvItemLst,inEnv,inIdent)
    local
      Env.Frame fr,f;
      DAE.ComponentRef cr,cref;
      SCode.Class c;
      String id,ident;
      Boolean encflag,more,unique;
      SCode.Restriction restr;
      list<Env.Frame> env_1,env2,env,classEnv,componentEnv,prevFrames;
      ClassInf.State ci_state;
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Binding bind;
      Absyn.Path path;
      list<Env.Item> fs;
      Env.Cache cache; 
      Absyn.Path path,scope;
      Absyn.Ident firstIdent;
      Option<DAE.Const> cnstForRange;

    case (cache,(Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident) /* unique */ 
      equation 
        f::prevFrames = listReverse(env);
        cref = Exp.pathToCref(path);
        cref = Exp.joinCrefs(cref,DAE.CREF_IDENT(ident,DAE.ET_OTHER(),{}));
        (cache,classEnv,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name) = lookupVarInPackages(cache,{f},cref,prevFrames,Util.makeStatefulBoolean(false));
        (cache,more) = moreLookupUnqualifiedImportedVarInFrame(cache, fs, env, ident);
        unique = boolNot(more);
      then
        (cache,classEnv,attr,ty,bind,cnstForRange,unique,splicedExpData,componentEnv,name);
    // search in the parent scopes
    case (cache,(_ :: fs),env,ident)
      equation
        (cache,classEnv,attr,ty,bind,cnstForRange,unique,splicedExpData,componentEnv,name) = lookupUnqualifiedImportedVarInFrame(cache,fs, env, ident);
      then
        (cache,classEnv,attr,ty,bind,cnstForRange,unique,splicedExpData,componentEnv,name);
  end matchcontinue;
end lookupUnqualifiedImportedVarInFrame;


protected function lookupQualifiedImportedClassInFrame
"function: lookupQualifiedImportedClassInFrame
  Helper function to lookupQualifiedImportedClassInEnv."
  input Env.Cache inCache;
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  input Util.StatefulBoolean inState;
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv;
  output Env.Env outPrevFrames;
algorithm
  (outCache,outClass,outEnv,outPrevFrames) := matchcontinue (inCache,inEnvItemLst,inEnv,inIdent,inState)
    local
      Env.Frame fr;
      SCode.Class c,c2;
      list<Env.Frame> env_1,env,prevFrames;
      String id,ident,str;
      list<Env.Item> fs;
      Absyn.Path strippath,path;
      Env.Cache cache;
    case (cache,(Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = Absyn.IDENT(name = id))) :: _),env,ident,inState)
      equation
        true = id ==& ident "For imported paths A, not possible to assert sub-path package";
        Util.setStatefulBoolean(inState,true);
        fr::prevFrames = listReverse(env);
        (cache,c,env_1,prevFrames) = lookupClass2(cache,{fr},Absyn.IDENT(id),prevFrames,Util.makeStatefulBoolean(false),true);
      then
        (cache,c,env_1,prevFrames);
    case (cache,(Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = path)) :: fs),env,ident,inState)
      equation
        id = Absyn.pathLastIdent(path) "For imported path A.B.C, assert A.B is package" ;
        true = id ==& ident;
        Util.setStatefulBoolean(inState,true);

        fr::prevFrames = listReverse(env);
        // strippath = Absyn.stripLast(path);
        // (cache,c2,env_1,_) = lookupClass2(cache,{fr},strippath,prevFrames,Util.makeStatefulBoolean(false),true);
        // assertPackage(c2,Absyn.pathString(strippath));
        (cache,c,env_1,prevFrames) = lookupClass2(cache,{fr},path,prevFrames,Util.makeStatefulBoolean(false),true);
      then
        (cache,c,env_1,prevFrames);

    /* commented since MSL does not follow this rule, instead assertPackage gives warning */
    /*case (cache,(Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = path)) :: fs),env,ident)
      equation
        id = Absyn.pathLastIdent(path) "If not package, error" ;
        true = stringEqual(id, ident);
        fr = Env.topFrame(env);
        (cache,c,env_1) = lookupClass(cache,{fr}, path, true);
        strippath = Absyn.stripLast(path);
        (cache,c2,_) = lookupClass(cache,{fr}, strippath, true);
        failure(assertPackage(c2));
        str = Absyn.pathString(strippath);
        Error.addMessage(Error.IMPORT_PACKAGES_ONLY, {str});
      then
        fail();*/
    case (cache,(Env.IMPORT(import_ = Absyn.NAMED_IMPORT(name = id,path = path)) :: fs),env,ident,inState)
      equation
        true = id ==& ident "Named imports";
        Util.setStatefulBoolean(inState,true);
        fr::prevFrames = listReverse(env);
        // strippath = Absyn.stripLast(path);
        // Debug.traceln("named import " +& id +& " is " +& Absyn.pathString(path));
        // (cache,c2,env_1,prevFrames) = lookupClass2(cache,{fr},strippath,prevFrames,Util.makeStatefulBoolean(false),true);
        // assertPackage(c2,Absyn.pathString(strippath));
        (cache,c,env_1,prevFrames) = lookupClass2(cache,{fr},path,prevFrames,Util.makeStatefulBoolean(false),true);
      then
        (cache,c,env_1,prevFrames);

    /* Error message if named import is not package */
    /* commented since MSL does not follow this rule, instead assertPackage gives warning */
    /*case (cache,(Env.IMPORT(import_ = Absyn.NAMED_IMPORT(name = id,path = path)) :: fs),env,ident)
      equation
        true = stringEqual(id, ident) "Assert package for Named imports" ;
        fr = Env.topFrame(env);
        (cache,c,env_1) = lookupClass(cache,{fr}, path, true);
        strippath = Absyn.stripLast(path);
        (cache,c2,_) = lookupClass(cache,{fr}, strippath, true);
        failure(assertPackage(c2));
        str = Absyn.pathString(strippath);
        Error.addMessage(Error.IMPORT_PACKAGES_ONLY, {str});
      then
        fail();*/

    case (cache,(_ :: fs),env,ident,inState)
      equation
        (cache,c,env_1,prevFrames) = lookupQualifiedImportedClassInFrame(cache,fs,env,ident,inState);
      then
        (cache,c,env_1,prevFrames);
  end matchcontinue;
end lookupQualifiedImportedClassInFrame;

protected function moreLookupUnqualifiedImportedClassInFrame "function: moreLookupUnqualifiedImportedClassInFrame  
  Helper function for lookupUnqualifiedImportedClassInFrame"
  input Env.Cache inCache;
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output Boolean outBoolean;
algorithm
  (outCache,outBoolean) := matchcontinue (inCache,inEnvItemLst,inEnv,inIdent)
    local
      Env.Frame fr,f;
      SCode.Class c;
      String id,ident;
      Boolean encflag,res;
      SCode.Restriction restr;
      list<Env.Frame> env_1,env2,env;
      ClassInf.State ci_state;
      Absyn.Path path;
      Absyn.Ident firstIdent;
      list<Env.Item> fs;
      Env.Cache cache;

    // Look in cache
    case (cache,(Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident)
      equation
        firstIdent = Absyn.pathFirstIdent(path);
          f::_= Env.cacheGet(Absyn.IDENT(firstIdent),path,cache);
        (cache,_,_) = lookupClass(cache,{f}, Absyn.IDENT(ident), false);
      then
        (cache,true);

    // Not found, instantiate
    case (cache,(Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident)
      equation
        fr = Env.topFrame(env);
        (cache,(c as SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr)),env_1) = lookupClass(cache,{fr}, path, false);
        env2 = Env.openScope(env_1, encflag, SOME(id), Env.restrictionToScopeType(restr));
        ci_state = ClassInf.start(restr, Env.getEnvName(env2));
       (cache,(f :: _),_,_) =
       Inst.partialInstClassIn(
          cache,env2,InnerOuter.emptyInstHierarchy,
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet,
          ci_state, c, false, {});
        (cache,_,_) = lookupClass(cache,{f}, Absyn.IDENT(ident), false);
      then
        (cache,true);

    // look in the parent scope
    case (cache,(_ :: fs),env,ident)
      equation
        (cache,res) = moreLookupUnqualifiedImportedClassInFrame(cache,fs, env, ident);
      then
        (cache,res);
    case (cache,{},_,_) then (cache,false);
  end matchcontinue;
end moreLookupUnqualifiedImportedClassInFrame;

protected function lookupUnqualifiedImportedClassInFrame "function: lookupUnqualifiedImportedClassInFrame  
  Finds a class from an unqualified import locally in a frame"
  input Env.Cache inCache;
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv;
  output Env.Env outPrevFrames;
  output Boolean outBoolean;
algorithm
  (outCache,outClass,outEnv,outPrevFrames,outBoolean) := matchcontinue (inCache,inEnvItemLst,inEnv,inIdent)
    local
      Env.Frame fr,f,f_1;
      SCode.Class c,c_1;
      String id,ident;
      Boolean encflag,more,unique;
      SCode.Restriction restr;
      list<Env.Frame> env_1,env2,fs_1,env,prevFrames;
      ClassInf.State ci_state,cistate1;
      Absyn.Path path;
      list<Env.Item> fs;
      Env.Cache cache;
      Absyn.Ident firstIdent;

    // Look in cache
    case (cache,(Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident) /* unique */
      equation
        firstIdent = Absyn.pathFirstIdent(path);
        env2 = Env.cacheGet(Absyn.IDENT(firstIdent),path,cache);
        (cache,c_1,env2,prevFrames) = lookupClass2(cache,env,Absyn.IDENT(ident),{},Util.makeStatefulBoolean(true),false) "Restrict import to the imported scope only, not its parents..." ;
        (cache,more) = moreLookupUnqualifiedImportedClassInFrame(cache,fs, env, ident);
        unique = boolNot(more);
      then
        (cache,c_1,env2,prevFrames,unique);

    // Not in cache, instantiate.
    case (cache,(Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident) /* unique */
      equation
        fr::prevFrames = listReverse(env);
        (cache,(c as SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr)),env_1,prevFrames) = lookupClass2(cache,{fr},path,prevFrames,Util.makeStatefulBoolean(false),false);
        env2 = Env.openScope(env_1, encflag, SOME(id), Env.restrictionToScopeType(restr));
        ci_state = ClassInf.start(restr, Env.getEnvName(env2));
        (cache,env2,_,cistate1) =
        Inst.partialInstClassIn(
          cache,env2,InnerOuter.emptyInstHierarchy,
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet,
          ci_state, c, false, {}); 
        // Restrict import to the imported scope only, not its parents, thus {f} below
        (cache,c_1,env2,prevFrames) = lookupClass2(cache,env2,Absyn.IDENT(ident),prevFrames,Util.makeStatefulBoolean(true),false) "Restrict import to the imported scope only, not its parents..." ;
        (cache,more) = moreLookupUnqualifiedImportedClassInFrame(cache,fs, env, ident);
        unique = boolNot(more);
      then
        (cache,c_1,env2,prevFrames,unique);

    // look in the parent scope
    case (cache,(_ :: fs),env,ident)
      equation
        (cache,c,env_1,prevFrames,unique) = lookupUnqualifiedImportedClassInFrame(cache,fs, env, ident);
      then
        (cache,c,env_1,prevFrames,unique);
  end matchcontinue;
end lookupUnqualifiedImportedClassInFrame;

public function lookupRecordConstructorClass "function: lookupRecordConstructorClass  
  Searches for a record constructor implicitly defined by a record class."
  input Env.Cache cache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm
  (outCache,outClass,outEnv) := matchcontinue (cache,inEnv,inPath)
    local
      SCode.Class c;
      list<Env.Frame> env,env_1,env_2,env_3;
      Absyn.Path path;
      String name;
      SCode.Restriction re;
      Env.Cache cache;
    case (cache,env,path)
      equation
        (cache,c,env_1) = lookupClass(cache,env, path, false);
        SCode.CLASS(name = name, restriction=SCode.R_RECORD()) = c;
        (cache,_,c) = buildRecordConstructorClass(cache,env_1,c);
      then
        (cache,c,env_1);
  end matchcontinue;
end lookupRecordConstructorClass;

public function lookupConnectorVar "looks up a connector variable, but takes InnerOuter attribute from component if
inside connector, i.e. for connector reference a.b the innerOuter attribute is fetched from a."
  input Env.Cache cache;
  input Env.Env env;
  input DAE.ComponentRef cr;
  output Env.Cache outCache;
  output DAE.Attributes attr;
  output DAE.Type tp;
algorithm
  (outCache,attr,tp) := matchcontinue(cache,env,cr)
    local 
      DAE.ComponentRef cr1;
      Boolean f,streamPrefix;
      SCode.Variability var; SCode.Accessibility acc;
      Absyn.Direction dir;
      Absyn.InnerOuter io;
      DAE.Type ty1;
      DAE.Attributes attr1;
    // unqualified component reference
    case(cache,env,cr as DAE.CREF_IDENT(ident=_)) equation
      (cache,attr1,ty1,_,_,_,_,_,_) = lookupVarLocal(cache,env,cr);
    then (cache,attr1,ty1);

    // qualified component reference
    case(cache,env,cr as DAE.CREF_QUAL(ident=_)) equation
       (cache,attr1 as DAE.ATTR(f,streamPrefix,acc,var,dir,_),ty1,_,_,_,_,_,_) = lookupVarLocal(cache,env,cr);
      cr1 = Exp.crefStripLastIdent(cr);
      /* Find innerOuter attribute from "parent" */
      (cache,DAE.ATTR(innerOuter=io),_,_,_,_,_,_,_) = lookupVarLocal(cache,env,cr1);
    then (cache,DAE.ATTR(f,streamPrefix,acc,var,dir,io),ty1);
  end matchcontinue;
end lookupConnectorVar;

public function lookupVar "LS: when looking up qualified component reference, lookupVar only
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
  output Option<DAE.Const> constOfForIteratorRange "SOME(constant-ness) of the range if this is a for iterator, NONE if this is not a for iterator";
  output SplicedExpData outSplicedExpData;
  output Env.Env outClassEnv "only used for package constants";
  output Env.Env outComponentEnv "only used for package constants";
  output String name "so the FQ path can be constructed";
algorithm
  (outCache,outAttributes,outType,outBinding,constOfForIteratorRange,outSplicedExpData,outClassEnv,outComponentEnv) :=
  matchcontinue (inCache,inEnv,inComponentRef)
    local
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Binding binding;
      list<Env.Frame> env, componentEnv, classEnv;
      DAE.ComponentRef cref;
      Env.Cache cache;
      SplicedExpData splicedExpData;
      Option<DAE.Const> cnstForRange;
      Boolean mustBeConstant;
    
    /*
    case (cache,env,cref)
      equation
        true = RTOpts.debugFlag("lookup");
        Debug.traceln("lookupVar: " +& 
          Exp.printComponentRefStr(cref) +& 
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
        // optional exp.exp to return
      then
        (cache,attr,ty,binding,cnstForRange,splicedExpData,classEnv,componentEnv,name);

    // fail if we couldn't find it
    case (_,env,cref) 
      equation
        //Debug.fprintln("failtrace",  "- Lookup.lookupVar failed " +& Exp.printComponentRefStr(cref) +& " in " +& Env.printEnvPathStr(env));  
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
      Absyn.Path path;
      String s1,s2;
    
    // do not fail if is a constant
    case (_,DAE.ATTR(parameter_= SCode.CONST()),_,_) then ();
    
    // fail if is not a constant
    case (env,attr,tp,cref)
      equation
        s1=Exp.printComponentRefStr(cref);
        s2 = Env.printEnvPathStr(env);
        Error.addMessage(Error.PACKAGE_VARIABLE_NOT_CONSTANT,{s1,s2});
        Debug.fprintln("failtrace", "- Lookup.checkPackageVariableConstant failed: " +& s1 +& " in " +& s2);
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
  output Option<DAE.Const> constOfForIteratorRange "SOME(constant-ness) of the range if this is a for iterator, NONE if this is not a for iterator";  
  output SplicedExpData splicedExpData;
  output Env.Env outClassEnv "the environment of the variable, typically the same as input, but e.g. for loop scopes can be 'stripped'";
  output Env.Env outComponentEnv "the component environment of the variable";  
  output String name;
algorithm
  (outCache,outAttributes,outType,outBinding,constOfForIteratorRange,splicedExpData,outClassEnv,outComponentEnv,name) :=
  matchcontinue (inCache,inEnv,inComponentRef,searchStrategy)
    local
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Binding binding;
      Option<String> sid;
      Env.AvlTree ht;
      list<Env.Item> imps;
      list<Env.Frame> fs;      
      Env.Frame frame,f;
      DAE.ComponentRef ref;
      Env.Cache cache;
      Option<DAE.Exp> splicedExp;
      Option<DAE.Const> cnstForRange;
      Env.Env env,componentEnv;
    
    // look into the current frame  
    case (cache,env as ((frame as Env.FRAME(optName = sid,clsAndVars = ht,imports = imps)) :: fs),ref,searchStrategy)
      equation
          (cache,attr,ty,binding,cnstForRange,splicedExpData,componentEnv,name) = lookupVarF(cache, ht, ref);
      then
        (cache,attr,ty,binding,cnstForRange,splicedExpData,env,componentEnv,name);

    // look in the next frame, only if current frame is a for loop scope.
    case (cache,(f :: fs),ref,searchStrategy)
      equation
        true = frameIsImplAddedScope(f);
        (cache,attr,ty,binding,cnstForRange,splicedExpData,env,componentEnv,name) = lookupVarInternal(cache, fs, ref,searchStrategy);
      then
        (cache,attr,ty,binding,cnstForRange,splicedExpData,env,componentEnv,name);
    
    // If not in top scope, look in top scope for builtin variables, e.g. time.
    case (cache,fs as _::_::_,ref,SEARCH_ALSO_BUILTIN())
      equation
        true = Builtin.variableIsBuiltin(ref);
        (f as Env.FRAME(clsAndVars = ht)) = Env.topFrame(fs);
        (cache,attr,ty,binding,cnstForRange,splicedExpData,componentEnv,name) = lookupVarF(cache, ht, ref);
      then
        (cache,attr,ty,binding,cnstForRange,splicedExpData,{f},componentEnv,name);
  end matchcontinue;
end lookupVarInternal;

protected function frameIsImplAddedScope "returns true if the frame is a for-loop scope or
a valueblock scope.
This is indicated by the name of the frame which should be 
Env.forScopeName or Env.valueBlockScopeName"
  input Env.Frame f;
  output Boolean b;
algorithm
  b := matchcontinue(f)
    local String name;
    case(Env.FRAME(optName=SOME(name))) equation
      true = name ==& Env.forScopeName or name ==& Env.valueBlockScopeName or name ==& Env.forIterScopeName;
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

  Arg1: The environment to search in
  Arg2: The variable to search for
  
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
  output Option<DAE.Const> constOfForIteratorRange "SOME(constant-ness) of the range if this is a for iterator, NONE if this is not a for iterator";
  output SplicedExpData splicedExpData "currently not relevant for constants, but might be used in the future";
  output Env.Env outComponentEnv;
  output String name "We only return the environment the component was found in; not its FQ name.";
algorithm 
  (outCache,outClassEnv,outAttributes,outType,outBinding,constOfForIteratorRange,splicedExpData,outComponentEnv) :=
  matchcontinue (inCache,inEnv,inComponentRef,inPrevFrames,inState)
    local
      SCode.Class c;
      String n,id1,id,str;
      Boolean encflag;
      SCode.Restriction r;
      list<Env.Frame> env2,env3,env5,env,fs,p_env,prevFrames, classEnv, componentEnv;
      ClassInf.State ci_state;
      list<DAE.Var> types;
      DAE.Attributes attr;
      DAE.Type ty;
      DAE.Binding bind;
      DAE.ComponentRef id2,cref,cr;
      list<DAE.Subscript> sb;
      Option<String> sid;
      list<Env.Item> items;
      Env.Frame f;
      Env.Cache cache;
      Option<DAE.Const> cnstForRange; 
      SplicedExpData splicedExpData;
      DAE.ComponentRef cr,cr1,cr2;
      Absyn.Path path,scope,ep,p,packp;
      Option<DAE.ComponentRef> filterCref;
      Env.Env dbgEnv;
      Boolean unique;

      // If we search for A1.A2....An.x while in scope A1.A2...An, just search for x. 
      // Must do like this to ensure finite recursion 
    case (cache,env,cr as DAE.CREF_QUAL(ident = id,subscriptLst = {},componentRef = cref),prevFrames,inState) /* First part of name is a previous frame */
      equation
        (SOME(f),prevFrames) = lookupPrevFrames(id,prevFrames);
        Util.setStatefulBoolean(inState,true);
        (cache,classEnv,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name) = lookupVarInPackages(cache,f::env,cref,prevFrames,inState);
      then
        (cache,classEnv,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name);

    // lookup of constants on form A.B in packages. First look in cache.
    case (cache,env,cr as DAE.CREF_QUAL(ident = id,subscriptLst = {},componentRef = cref),prevFrames,inState) /* First part of name is a class. */ 
      equation
        (NONE(),prevFrames) = lookupPrevFrames(id,prevFrames);
        SOME(scope) = Env.getEnvPath(env);
        path = Exp.crefToPath(cr);
        id = Absyn.pathLastIdent(path);
        path = Absyn.stripLast(path);
        f::fs = Env.cacheGet(scope,path,cache);
        Util.setStatefulBoolean(inState,true);
        (cache,attr,ty,bind,cnstForRange,splicedExpData,classEnv,componentEnv,name) = lookupVarLocal(cache,f::fs, DAE.CREF_IDENT(id,DAE.ET_OTHER(),{}));
        //print("found ");print(Exp.printComponentRefStr(cr));print(" in cache\n");
      then
        (cache,f::fs,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name);
        
    // lookup of constants on form A.B in packages. instantiate package and look inside.
    case (cache,env,cr as DAE.CREF_QUAL(ident = id,subscriptLst = {},componentRef = cref),prevFrames,inState) /* First part of name is a class. */ 
      equation 
        (NONE(),prevFrames) = lookupPrevFrames(id,prevFrames);
        (cache,(c as SCode.CLASS(name=n,encapsulatedPrefix=encflag,restriction=r)),env2,prevFrames) = lookupClass2(cache,env,Absyn.IDENT(id),prevFrames,Util.makeStatefulBoolean(true) /* In order to use the prevFrames, we need to make sure we can't instantiate one of the classes too soon! */,false);
        Util.setStatefulBoolean(inState,true);
        env3 = Env.openScope(env2, encflag, SOME(n), Env.restrictionToScopeType(r));
        ci_state = ClassInf.start(r, Env.getEnvName(env3));
        filterCref = makeOptIdentOrNone(cref);
        (cache,env5,_,_,_,_,_,_,_,_,_,_) =
        Inst.instClassIn(
          cache,env3,InnerOuter.emptyInstHierarchy,UnitAbsyn.noStore,
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet,
          ci_state, c, false, {}, /*true*/false, ConnectionGraph.EMPTY, filterCref);
        (cache,p_env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name) = lookupVarInPackages(cache,env5,cref,prevFrames,inState);
      then
        (cache,p_env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name);
        
    // Why is this done? It is already done done in lookupVar! 
    // BZ: This is due to recursive call when it might become DAE.CREF_IDENT calls. 
    case (cache,env,(cr as DAE.CREF_IDENT(ident = id,subscriptLst = sb)),prevFrames,inState)
      equation
        (cache,attr,ty,bind,cnstForRange,splicedExpData,classEnv,componentEnv,name) = lookupVarLocal(cache, env, cr);
        Util.setStatefulBoolean(inState,true);
      then
        (cache,env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name);

    // Search among qualified imports, e.g. import A.B; or import D=A.B; 
    case (cache,(env as (Env.FRAME(optName = sid,imports = items) :: _)),DAE.CREF_IDENT(ident = id,subscriptLst = sb),prevFrames,inState)
      equation
        cr = lookupQualifiedImportedVarInFrame(items, id);
        Util.setStatefulBoolean(inState,true);
        f::prevFrames = listReverse(env);
        (cache,p_env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name) = lookupVarInPackages(cache,{f},cr,prevFrames,inState);
      then
        (cache,p_env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name);

    // Search among unqualified imports, e.g. import A.B.* 
    case (cache,(env as (Env.FRAME(optName = sid,imports = items) :: _)),(cr as DAE.CREF_IDENT(ident = id,subscriptLst = sb)),prevFrames,inState)
      equation
        (cache,p_env,attr,ty,bind,cnstForRange,unique,splicedExpData,componentEnv,name) = lookupUnqualifiedImportedVarInFrame(cache,items, env, id);
        reportSeveralNamesError(unique,id);
        Util.setStatefulBoolean(inState,true);
      then
        (cache,p_env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name);
        
     // Search parent scopes
    case (cache,((f as Env.FRAME(optName = SOME(id))):: fs),cr,prevFrames,inState)
      equation
        false = Util.getStatefulBoolean(inState);
        (cache,p_env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name) = lookupVarInPackages(cache,fs,cr,f::prevFrames,inState);
      then
        (cache,p_env,attr,ty,bind,cnstForRange,splicedExpData,componentEnv,name);

    case (cache,env,cr,prevFrames,inState)
      equation
        //true = RTOpts.debugFlag("failtrace");
        //Debug.traceln("- Lookup.lookupVarInPackages failed on exp:" +& Exp.printComponentRefStr(cr) +& " in scope: " +& Env.printEnvPathStr(env));
      then 
        fail(); 
  end matchcontinue;
end lookupVarInPackages;

protected function makeOptIdentOrNone "
Author: BZ, 2009-04
Helper function for lookupVarInPackages
Makes an optional DAE.ComponentRef if the input DAE.ComponentRef is a DAE.CREF_IDENT otherwise
'NONE' is returned"
  input DAE.ComponentRef incr;
  output Option<DAE.ComponentRef> ocR;
algorithm ocR := matchcontinue(incr)
  case(incr as DAE.CREF_IDENT(_,_,_)) then SOME(incr);
  case(_) then NONE;
  end matchcontinue;
end makeOptIdentOrNone;

public function lookupVarLocal "function: lookupVarLocal

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
  output Option<DAE.Const> constOfForIteratorRange "SOME(constant-ness) of the range if this is a for iterator, NONE if this is not a for iterator";  
  output SplicedExpData splicedExpData;
  output Env.Env outClassEnv;
  output Env.Env outComponentEnv;
  output String name;
algorithm
  // adrpo: use lookupVarInternal as is the SAME but it doesn't search in the builtin scope!
  (outCache,outAttributes,outType,outBinding,constOfForIteratorRange,splicedExpData,outClassEnv,outComponentEnv,name) :=
  lookupVarInternal(inCache, inEnv, inComponentRef, SEARCH_LOCAL_ONLY());
  /* adrpo: remove this if no new problems appear!
  (outCache,outAttributes,outType,outBinding,constOfForIteratorRange,splicedExpData):=
  matchcontinue (inCache,inEnv,inComponentRef)
    local
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Binding binding;
      Option<String> sid;
      Env.AvlTree ht;
      list<Env.Frame> fs,env,bcframes;
      DAE.ComponentRef cref;
      Env.Cache cache;
      Option<DAE.Const> cnstForRange;
      SplicedExpData splicedExpData;
      
    // Lookup in frame
    case (cache,(Env.FRAME(optName = sid,clsAndVars = ht) :: fs),cref)
      equation
        (cache,attr,ty,binding,cnstForRange,splicedExpData) = lookupVarF(cache,ht, cref);
      then
        (cache,attr,ty,binding,cnstForRange,splicedExpData);

    // Exception, when in for loop scope allow search of next scope
    case (cache,(Env.FRAME(optName = SOME("$for loop scope$")) :: env),cref)
      equation
        (cache,attr,ty,binding,cnstForRange,splicedExpData) = lookupVarLocal(cache,env, cref) "Exception, when in for loop scope allow search of next scope" ;
      then
        (cache,attr,ty,binding,cnstForRange,splicedExpData);
  end matchcontinue;
  */
end lookupVarLocal;

public function lookupIdentLocal "function: lookupIdentLocal
  Searches for a variable in the local scope."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output DAE.Var outVar;
  output Option<tuple<SCode.Element, DAE.Mod>> outTplSCodeElementTypesModOption;
  output Env.InstStatus instStatus;
  output Env.Env outComponentEnv;
algorithm
  (outCache,outVar,outTplSCodeElementTypesModOption,instStatus,outComponentEnv):=
  matchcontinue (inCache,inEnv,inIdent)
    local
      DAE.Var fv;
      Option<tuple<SCode.Element, DAE.Mod>> c;
      Env.InstStatus i;
      list<Env.Frame> env,fs,componentEnv;
      Option<String> sid;
      Env.AvlTree ht;
      String id;
      Env.Cache cache;
      
    case (cache,env as (Env.FRAME(optName = sid, clsAndVars = ht) :: fs),id) /* component environment */
      equation
        (cache,fv,c,i,componentEnv) = lookupVar2(cache, ht, id);
      then
        (cache,fv,c,i,componentEnv);

  end matchcontinue;
end lookupIdentLocal;

public function lookupClassLocal "function: lookupClassLocal
  Searches for a class definition in the local scope."
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm
  (outCache,outVar,outTplSCodeElementTypesModOption,instStatus,outEnv):=
  matchcontinue (inEnv,inIdent)
    local
      SCode.Class cl;
      list<Env.Frame> env;
      Option<String> sid;
      Env.AvlTree ht;
      String id;
      Env.Cache cache;
    case (env as (Env.FRAME(optName = sid, clsAndVars = ht) :: _),id) /* component environment */
      equation
        Env.CLASS(cl,env) = Env.avlTreeGet(ht, id);
      then
        (cl,env);
  end matchcontinue;
end lookupClassLocal;

public function lookupAndInstantiate "performs a lookup of a class and then instantiate that class to
return its environment. Helper function used e.g by Inst.mo"
  input Env.Cache inCache;
  input Env.Env env;
  input Absyn.Path path;
  input SCode.Mod mod;
  input Boolean msg;
  output Env.Cache outCache;
  output Env.Env classEnv;
algorithm
  (outCache,classEnv) := matchcontinue(cache,env,path,mod,msg)
    local  Env.Cache cache;
      String cn2;
      Boolean enc2,enc;
      SCode.Restriction r;
      ClassInf.State new_ci_state;
      Env.Env cenv,cenv_2;
      Absyn.Path scope;
      SCode.Class c;
      Absyn.Ident ident;
      DAE.Mod dmod;

      // Try to find in cache.
    case(cache,env,path,mod,msg) /* Should we only lookup if it is SCode.NOMOD? */
      equation
        (cache,(c as SCode.CLASS(name=cn2,encapsulatedPrefix=enc2,restriction=r)),cenv) = lookupClass(cache,env,path,msg);
        SOME(scope) = Env.getEnvPath(cenv);
        ident = Absyn.pathLastIdent(path);
       classEnv = Env.cacheGet(scope,Absyn.IDENT(ident),cache);
      then (cache,classEnv);

      // Not found in cache, lookup and instantiate.
    case(cache,env,path,mod,msg)
      equation
        // Debug.traceln("lookupAndInstantiate " +& Absyn.pathString(path) +& ", s:" +& Env.printEnvPathStr(env) +& "m:" +& SCode.printModStr(mod));
        (cache,(c as SCode.CLASS(name=cn2,encapsulatedPrefix=enc2,restriction=r)),cenv) = lookupClass(cache, env, path, msg);
        cenv_2 = Env.openScope(cenv, enc2, SOME(cn2), Env.restrictionToScopeType(r));
        new_ci_state = ClassInf.start(r, Env.getEnvName(cenv_2));
        dmod = Mod.elabUntypedMod(mod,env,Prefix.NOPRE());
        //(cache,dmod,_ /* Return fn's here */) = Mod.elabMod(cache,env,Prefix.NOPRE(),mod,true); - breaks things but is needed for other things... bleh
        // Debug.traceln("dmod: " +& Mod.printModStr(dmod));
        (cache,classEnv,_,_) =
        Inst.partialInstClassIn(
          cache,cenv_2,InnerOuter.emptyInstHierarchy,
          dmod, Prefix.NOPRE(), Connect.emptySet,
          new_ci_state, c,
          false, {});
      then (cache,classEnv);
    case(cache,env,path,mod,msg)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln( "- Lookup.lookupAndInstantiate failed " +&  Absyn.pathString(path) +& " with mod: " +& SCode.printModStr(mod) +& " in scope " +& Env.printEnvPathStr(env));
     then fail();
  end matchcontinue;
end lookupAndInstantiate;

public function lookupIdent "function: lookupIdent
  Same as lookupIdentLocal, except check all frames"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output DAE.Var outVar;
  output Option<tuple<SCode.Element, DAE.Mod>> outTplSCodeElementTypesModOption;
  output Env.InstStatus instStatus;
algorithm
  (outCache,outVar,outTplSCodeElementTypesModOption,instStatus):=
  matchcontinue (outCache,inEnv,inIdent)
    local
      DAE.Var fv;
      Option<tuple<SCode.Element, DAE.Mod>> c;
      Env.InstStatus i;
      Option<String> sid;
      Env.AvlTree ht;
      String id;
      list<Env.Frame> rest;
      Env.Cache cache;

    case (cache,(Env.FRAME(optName = sid,clsAndVars = ht) :: _),id)
      equation
        (cache,fv,c,i,_) = lookupVar2(cache, ht, id);
      then
        (cache,fv,c,i);
    
    case (cache,(_ :: rest),id)
      equation
        (cache,fv,c,i) = lookupIdent(cache, rest, id);
      then
        (cache,fv,c,i);
  end matchcontinue;
end lookupIdent;

// Function lookup
public function lookupFunctionsInEnv
"function: lookupFunctionsInEnv
  Returns a list of types that the function has."
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.Path id;
  output Env.Cache outCache;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  (outCache,outTypesTypeLst) := matchcontinue (cache,env,id)
    local
      Env.Frame f;
      list<DAE.Type> res;
      DAE.DAElist dae;
      Env.AvlTree httypes;
      Env.AvlTree ht;
      String str;
      
    /* Builtin operators are looked up in top frame directly */
    case (cache,env,(id as Absyn.IDENT(name = str)))
      equation
        _ = Static.elabBuiltinHandler(str) "Check for builtin operators" ;
        (cache,env as {Env.FRAME(clsAndVars = ht,types = httypes)}) = Builtin.initialEnv(cache);
        (cache,res) = lookupFunctionsInFrame(cache, ht, httypes, env, str);
      then
        (cache,res);

    /* Check for special builtin operators that can not be represented in environment like for instance cardinality.*/
    case (cache,_,id as Absyn.IDENT(name = str))
      equation
        _ = Static.elabBuiltinHandlerGeneric(str);
        (cache,env) = Builtin.initialEnv(cache);
        res = createGenericBuiltinFunctions(env, str);
      then
        (cache,res);

    case (cache,env,id)
      equation
        failure(Absyn.FULLYQUALIFIED(_) = id);
        (cache,res) = lookupFunctionsInEnv2(cache,env,id,false);
      then (cache,res);

    case (cache,env,Absyn.FULLYQUALIFIED(id))
      equation
        f = Env.topFrame(env);
        (cache,res) = lookupFunctionsInEnv2(cache,{f},id,true);
      then (cache,res);

    case (cache,_,_) then (cache,{});
    case (_,_,id)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "lookupFunctionsInEnv failed on: " +& Absyn.pathString(id));
      then
        fail();
  end matchcontinue;
end lookupFunctionsInEnv;

protected function lookupFunctionsInEnv2
"function: lookupFunctionsInEnv
  Returns a list of types that the function has."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input Boolean followedQual "cannot pop frames if we followed a qualified path at any point";
  output Env.Cache outCache;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  (outCache,outTypesTypeLst) := matchcontinue (inCache,inEnv,inPath,followedQual)
    local
      Absyn.Path id,iid,path;
      Option<String> sid;
      Env.AvlTree httypes;
      Env.AvlTree ht;
      list<tuple<DAE.TType, Option<Absyn.Path>>> reslist,c1,c2,res;
      list<Env.Frame> env,fs,env_1,env2,env_2;
      String pack,str;
      SCode.Class c;
      Boolean encflag;
      SCode.Restriction restr;
      ClassInf.State ci_state,cistate1;
      Env.Frame f;
      Env.Cache cache;
      DAE.DAElist dae;
      
    /* Simple name, search frame */
    case (cache,(env as (Env.FRAME(optName = sid,clsAndVars = ht,types = httypes) :: fs)),id as Absyn.IDENT(name = str),followedQual)
      equation
        (cache,res as _::_)= lookupFunctionsInFrame(cache, ht, httypes, env, str);
      then
        (cache,res);

    /* Simple name, if class with restriction function found in frame instantiate to get type. */
    case (cache, f::fs, id as Absyn.IDENT(name = str),followedQual)
      equation
        // adrpo: do not search in the entire environment as we anyway recurse with the fs argument!
        //        just search in {f} not f::fs as otherwise we might get us in an infinite loop
        // Bjozac: Readded the f::fs search frame, otherwise we might get caught in a inifinite loop!
        //           Did not investigate this further then that it can crasch the kernel.
        (cache,(c as SCode.CLASS(name=str,encapsulatedPrefix=encflag,restriction=restr)),env_1) = lookupClass(cache,f::fs, id, false);
        true = SCode.isFunctionOrExtFunction(restr);
        // get function dae from instantiation
        (cache,(env_2 as (Env.FRAME(optName = sid,clsAndVars = ht,types = httypes)::_)),_)
           = Inst.implicitFunctionTypeInstantiation(cache,env_1,InnerOuter.emptyInstHierarchy, c);
         
        (cache,res as _::_)= lookupFunctionsInFrame(cache, ht, httypes, env_2, str);
      then
        (cache,res);

    /* For qualified function names, e.g. Modelica.Math.sin */
    case (cache,(env as (Env.FRAME(optName = sid,clsAndVars = ht,types = httypes) :: fs)),id as Absyn.QUALIFIED(name = pack,path = path),followedQual)
      equation
        (cache,(c as SCode.CLASS(name=str,encapsulatedPrefix=encflag,restriction=restr)),env_1) = lookupClass(cache, env, Absyn.IDENT(pack), false) ;
        env2 = Env.openScope(env_1, encflag, SOME(str), Env.restrictionToScopeType(restr));
        ci_state = ClassInf.start(restr, Env.getEnvName(env2));

        //(cache,_,env_2,_,_,_,_,_,_) = Inst.instClassIn(cache,env2, DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet,
        //   ci_state, c, false/*FIXME:prot*/, {}, false, ConnectionGraph.EMPTY);
        (cache,env_2,_,cistate1) =
        Inst.partialInstClassIn(
          cache, env2, InnerOuter.emptyInstHierarchy,
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet,
          ci_state, c, false, {});
        (cache,res) = lookupFunctionsInEnv2(cache, env_2, path, true);
      then
        (cache,res);

    /* Did not match. Search next frame. */
    case (cache,Env.FRAME(isEncapsulated = false)::fs,id,false)
      equation
        (cache,res) = lookupFunctionsInEnv2(cache, fs, id, false);
      then
        (cache,res);
    
    case (cache,Env.FRAME(isEncapsulated = true)::env,id as Absyn.IDENT(name = str),false)
      equation
        (cache,env) = Builtin.initialEnv(cache);
        (cache,res) = lookupFunctionsInEnv2(cache, env, id, true);
      then
        (cache,res);

  end matchcontinue;
end lookupFunctionsInEnv2;

protected function createGenericBuiltinFunctions "function: createGenericBuiltinFunctions
  author: PA

  This function creates function types on-the-fly for special builtin
  operators/functions which can not be represented in the builtin
  environment.
"
  input Env.Env inEnv;
  input String inString;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  outTypesTypeLst:=
  matchcontinue (inEnv,inString)
    local list<Env.Frame> env;
    /* function_name cardinality */
    case (env,"cardinality")
      then {(DAE.T_FUNCTION({("x",(DAE.T_COMPLEX(ClassInf.CONNECTOR(Absyn.IDENT("$$"),false),{},NONE,NONE),NONE))},
                              DAE.T_INTEGER_DEFAULT,DAE.NO_INLINE),NONE),
            (DAE.T_FUNCTION({("x",(DAE.T_COMPLEX(ClassInf.CONNECTOR(Absyn.IDENT("$$"),true),{},NONE,NONE),NONE))},
                              DAE.T_INTEGER_DEFAULT,DAE.NO_INLINE),NONE)};

  end matchcontinue;
end createGenericBuiltinFunctions;

protected function lookupTypeInEnv "- Internal functions
  Type lookup
  function: lookupTypeInEnv

"
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
      tuple<DAE.TType, Option<Absyn.Path>> c;
      list<Env.Frame> env_1,env,fs;
      Option<String> sid;
      Env.AvlTree httypes;
      Env.AvlTree ht;
      String id;
      Env.Frame f;
      Env.Cache cache;
      Absyn.Path path;
    case (cache,(env as (Env.FRAME(optName = sid,clsAndVars = ht,types = httypes) :: fs)),Absyn.IDENT(name = id))
      equation
        (cache,c,env_1) = lookupTypeInFrame(cache,ht, httypes, env, id);
      then
        (cache,c,env_1);
    case (cache,f::fs,path)
      equation
        (cache,c,env_1) = lookupTypeInEnv(cache,fs,path);
      then
        (cache,c,(f :: env_1));
  end matchcontinue;
end lookupTypeInEnv;

protected function lookupTypeInFrame "function: lookupTypeInFrame

  Searches a frame for a type.
"
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
  matchcontinue (inCache,inBinTree1,inBinTree2,inEnv3,inIdent4)
    local
      tuple<DAE.TType, Option<Absyn.Path>> t,ftype,ty;
      Env.AvlTree httypes;
      Env.AvlTree ht;
      list<Env.Frame> env,cenv,env_1,env_2,env_3;
      String id,n;
      Env.Cache cache;
      Env.Item item;
    case (cache,ht,httypes,env,id)
      equation
        item = Env.avlTreeGet(httypes, id);
        (cache,t,env) = lookupTypeInFrame2(cache,item,env,id);
      then
        (cache,t,env);
  end matchcontinue;
end lookupTypeInFrame;

protected function lookupTypeInFrame2 "function: lookupTypeInFrame

  Searches a frame for a type.
"
  input Env.Cache inCache;
  input Env.Item item;
  input Env.Env inEnv3;
  input SCode.Ident inIdent4;
  output Env.Cache outCache;
  output DAE.Type outType;
  output Env.Env outEnv;
algorithm
  (outCache,outType,outEnv):=
  matchcontinue (inCache,item,inEnv3,inIdent4)
    local
      tuple<DAE.TType, Option<Absyn.Path>> t,ftype,ty;
      Env.AvlTree httypes;
      Env.AvlTree ht;
      list<Env.Frame> env,cenv,env_1,env_2,env_3;
      String id,n;
      SCode.Class cdef;
      Absyn.Path fpath;
      list<DAE.Var> varlst;
      Env.Cache cache;

    case (cache,Env.TYPE((t :: _)),env,id) then (cache,t,env);
    case (cache,Env.VAR(_,_,_,_),env,id)
      equation
        Error.addMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id});
      then
        fail();
        /* Record constructor function*/
    case (cache,Env.CLASS((cdef as SCode.CLASS(name=n,restriction=SCode.R_RECORD())),cenv),env,id)
      equation
        (cache,env_3,ty) = buildRecordType(cache,env,cdef);
      then
        (cache,ty,env_3);

        /* Found function */
    case (cache,Env.CLASS((cdef as SCode.CLASS(restriction=restr)),cenv),env,id)
      local SCode.Restriction restr; Env.Cache garbageCache;
      equation
        true = SCode.isFunctionOrExtFunction(restr);

        /* Since function is added to cache, but dae here is not propagated, throw away cache from this call */
        (garbageCache ,env_1,_) =
        Inst.implicitFunctionInstantiation(
          cache,cenv,InnerOuter.emptyInstHierarchy,
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, cdef, {});
        (cache,ty,env_3) = lookupTypeInEnv(cache,env_1, Absyn.IDENT(id));
      then
        (cache,ty,env_3);
  end matchcontinue;
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
  output Env.Cache outCache;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  (outCache,outTypesTypeLst):=
  matchcontinue (inCache,inBinTree1,inBinTree2,inEnv3,inIdent4)
    local
      list<tuple<DAE.TType, Option<Absyn.Path>>> tps;
      Env.AvlTree httypes;
      Env.AvlTree ht;
      list<Env.Frame> env,cenv,env_1,env_3;
      String id,n;
      SCode.Class cdef;
      list<DAE.Var> varlst;
      Absyn.Path fpath;
      tuple<DAE.TType, Option<Absyn.Path>> ftype,t;
      DAE.TType tty;
      Env.Cache cache;
      DAE.DAElist dae;

    case (cache,ht,httypes,env,id) /* Classes and vars Types */
      equation
        Env.TYPE(tps) = Env.avlTreeGet(httypes, id);
      then
        (cache,tps);

    case (cache,ht,httypes,env,id) /* MetaModelica Partial Function. sjoelund */
      equation
        Env.VAR(instantiated = DAE.TYPES_VAR(type_ = (tty as DAE.T_FUNCTION(_,_,_),_))) = Env.avlTreeGet(ht, id);
      then
        (cache,{(tty, SOME(Absyn.IDENT(id)))});

    case (cache,ht,httypes,env,id)
      equation
        Env.VAR(_,_,_,_) = Env.avlTreeGet(ht, id);
        Error.addMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id});
      then
        fail();

    /* Records, create record constructor function*/
    case (cache,ht,httypes,env,id)
      equation
        Env.CLASS((cdef as SCode.CLASS(name=n,restriction=SCode.R_RECORD())),cenv) = Env.avlTreeGet(ht, id);
        (cache,_,ftype) = buildRecordType(cache,env,cdef);
      then
        (cache,{ftype});

    /* Found class that is function, instantiate to get type*/
    case (cache,ht,httypes,env,id) local SCode.Restriction restr;
      equation
        Env.CLASS((cdef as SCode.CLASS(restriction=restr)),cenv) = Env.avlTreeGet(ht, id);
        true = SCode.isFunctionOrExtFunction(restr) "If found class that is function.";
        //function dae collected from instantiation
        (cache,env_1,_) =
        Inst.implicitFunctionTypeInstantiation(cache,cenv,InnerOuter.emptyInstHierarchy,cdef) ;
        
        (cache,tps) = lookupFunctionsInEnv2(cache,env_1,Absyn.IDENT(id),true);
      then
        (cache,tps);

     /* Found class that is is external object*/
     case (cache,ht,httypes,env,id)
        local String s;
        equation
          Env.CLASS(cdef,cenv) = Env.avlTreeGet(ht, id);
          true = Inst.classIsExternalObject(cdef);
          (cache,env_1,_,_,_,_,t,_,_,_) = 
          Inst.instClass(
            cache,cenv,InnerOuter.emptyInstHierarchy,UnitAbsyn.noStore,
            DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, cdef, 
             {}, false, Inst.TOP_CALL(), ConnectionGraph.EMPTY);
          (cache,t,_) = lookupTypeInEnv(cache,env_1, Absyn.IDENT(id));
           //s = Types.unparseType(t);
            //print("type :");print(s);print("\n");
       then
        (cache,{t});
  end matchcontinue;
end lookupFunctionsInFrame;

protected function buildRecordType ""
  input Env.Cache cache;
  input Env.Env env;
  input SCode.Class cdef;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output Types.Type ftype;
protected
  String name;
  Env.Env env_1;
algorithm
  (outCache,_,cdef) := buildRecordConstructorClass(cache,env,cdef);
  (outCache,outEnv,_) := Inst.implicitFunctionTypeInstantiation(
     outCache,env,InnerOuter.emptyInstHierarchy, cdef);
  name := SCode.className(cdef);
  (outCache,ftype,_) := lookupTypeInEnv(outCache,outEnv,Absyn.IDENT(name));
end buildRecordType;

public function buildRecordConstructorClass
"function: buildRecordConstructorClass

  Creates the record constructor class, i.e. a function, from the record
  class given as argument."
  input Env.Cache cache;
  input Env.Env inEnv;
  input SCode.Class inClass;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output SCode.Class outClass;
algorithm
  (outCache,outEnv,outCache,outClass) :=
  matchcontinue (cache,inEnv,inClass)
    local
      Env.Cache cache;
      list<SCode.Element> funcelts,elts;
      SCode.Element reselt;
      SCode.Class cl;
      String id;
      SCode.Restriction restr;
      list<Env.Frame> env;
      list<SCode.AlgorithmSection> initStmts;
      list<Absyn.Algorithm> initAbsynStmts;
      Absyn.Info info;

    case (cache,env,cl as SCode.CLASS(name=id,info=info))
      equation
        (cache,env,funcelts,elts) = buildRecordConstructorClass2(cache,env,cl,DAE.NOMOD());
        reselt = buildRecordConstructorResultElt(funcelts,id,env);
        cl = SCode.CLASS(id,false,false,SCode.R_FUNCTION(),SCode.PARTS((reselt :: funcelts),{},{},{},{},NONE,{},NONE),info);
      then
        (cache,env,cl);
    case (cache,env,cl)
      equation
        Debug.fprintln("failtrace","buildRecordConstructorClass failed");
      then fail();
  end matchcontinue;
end buildRecordConstructorClass;

protected function buildRecordConstructorClass2
  input Env.Cache cache;
  input Env.Env env;
  input SCode.Class cl;
  input DAE.Mod mods;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output list<SCode.Element> funcelts;
  output list<SCode.Element> elts;
algorithm
  (outCache,outEnv,funcelts,elts) := matchcontinue(cache,env,cl,mods)
    local
      list<SCode.Element> elts,cdefelts,restElts,classExtendsElts,extendsElts,compElts;
      list<tuple<SCode.Element,DAE.Mod>> eltsMods;
      Env.Env env1;
      String name;
      Absyn.Path fpath;
      SCode.Class cl;

    /* a class with parts */
    case (cache,env,cl as SCode.CLASS(name = name),mods)
      equation
        (cache,env,_,elts,_,_,_,_) = InstExtends.instDerivedClasses(cache,env,InnerOuter.emptyInstHierarchy,DAE.NOMOD(),cl,true);
        env = Env.openScope(env, false, SOME(name), SOME(Env.CLASS_SCOPE));
        fpath = Env.getEnvName(env);
        (cdefelts,classExtendsElts,extendsElts,compElts) = Inst.splitElts(elts);
        (_,env,_,_,eltsMods,_,_,_,_) = InstExtends.instExtendsAndClassExtendsList(Env.emptyCache(), env, InnerOuter.emptyInstHierarchy, DAE.NOMOD(), Prefix.NOPRE(), extendsElts, classExtendsElts, ClassInf.RECORD(fpath), name, true, false);
        eltsMods = listAppend(eltsMods,Inst.addNomod(compElts));
        (env1,_) = Inst.addClassdefsToEnv(env,InnerOuter.emptyInstHierarchy,Prefix.NOPRE(),cdefelts,false,NONE);
        (_,env1,_) = Inst.addComponentsToEnv(Env.emptyCache(),env1,InnerOuter.emptyInstHierarchy,mods,Prefix.NOPRE(),Connect.emptySet,ClassInf.RECORD(fpath),eltsMods,eltsMods,{},{},true);
        funcelts = buildRecordConstructorElts(eltsMods,mods,env1);
      then (cache,env1,funcelts,elts);
    
    // fail
    case(cache,env,cl,mods) equation
      Debug.traceln("buildRecordConstructorClass2 failed, cl:"+&SCode.printClassStr(cl)+&"\n");
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
    case (DAE.NOMOD(), inModNoID) then inModNoID;
    case (inModID, _) then inModID;
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
      Boolean fl,repl,prot,f,st;
      Absyn.InnerOuter io;
      list<Absyn.Subscript> d;
      SCode.Accessibility ac;
      SCode.Variability var;
      Absyn.Direction dir;
      Absyn.TypeSpec tp;
      SCode.Mod mod;
      Option<SCode.Comment> comment;
      list<Env.Frame> env_1;
      Option<Absyn.Exp> cond;
      SCode.Class cl;
      Absyn.Path path;
      SCode.Mod mod,umod;
      DAE.Mod mod_1, compMod, fullMod, selectedMod, cmod;
      Option<Absyn.Info> nfo;
      Option<Absyn.ConstrainClass> cc;
      Absyn.Info info;

    case ({},_,_) then {};

    case ((((comp as SCode.COMPONENT( id,io,fl,repl,prot,SCode.ATTR(d,f,st,ac,var,dir),tp,mod,comment,cond,nfo,cc)),cmod) :: rest),mods,env)
      equation
        info = Util.getOptionOrDefault(nfo, Absyn.dummyInfo);
        (_,mod_1) = Mod.elabMod(Env.emptyCache(), env, InnerOuter.emptyInstHierarchy, Prefix.NOPRE(), mod, false, info);
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
        var = SCode.VAR();
        dir = Absyn.INPUT();
      then
        (SCode.COMPONENT(id,io,fl,repl,prot,SCode.ATTR(d,f,st,ac,SCode.VAR,Absyn.INPUT()),tp,umod,comment,cond,nfo,cc) :: res);

    case ((comp,cmod)::_,mods,_)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- Lookup.buildRecordConstructorElts failed " +& SCode.printElementStr(comp) +& " with mod: " +& Mod.printModStr(cmod) +& " and: " +& Mod.printModStr(mods));
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
  output SCode.Element outElement;
  list<SCode.SubMod> submodlst;
algorithm
  //print(" creating element of type: " +& id +& "\n");
  //print(" with generated mods:" +& SCode.printSubs1Str(submodlst) +& "\n");
  //print(" creating element of type: " +& id +& "\n");
  //print(" with generated mods:" +& SCode.printSubs1Str(submodlst) +& "\n");
  outElement := SCode.COMPONENT("result",Absyn.UNSPECIFIED(),false,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.VAR(),Absyn.OUTPUT()),
          Absyn.TPATH(Absyn.IDENT(id),NONE),
          SCode.NOMOD(),NONE,NONE,NONE,NONE);
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
  (outCache,outBoolean):=
  matchcontinue (inCache,inPath)
    local
      list<Env.Frame> i_env;
      Absyn.Path path;
      Env.Cache cache;
    case (cache,path)
      equation
        (cache,i_env) = Builtin.initialEnv(cache);
        (cache,_::_) = lookupFunctionsInEnv2(cache,i_env,path,true);
      then
        (cache,true);
    case (cache,path) then (cache,false);
  end matchcontinue;
end isInBuiltinEnv;

protected function lookupClassInEnv "
  Helper function to lookupClass2. Searches the environment for the class.
  It first checks the current scope, and then base classes. The specification
  says that we first search elements in the current scope (+ the ones inherited
  from base classes)
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input String id;
  input list<Env.Frame> inPrevFrames;
  input Util.StatefulBoolean inState;
  input Boolean inMsg;
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv;
  output list<Env.Frame> outPrevFrames;
algorithm
  (outCache,outClass,outEnv,outPrevFrames) := matchcontinue (inCache,inEnv,id,inPrevFrames,inState,inMsg)
    local
      SCode.Class c;
      list<Env.Frame> env_1,env,fs,i_env,prevFrames;
      Env.Frame frame,f;
      String id,sid,scope;
      Boolean msg,msgflag;
      Absyn.Path aid,path;
      Env.Cache cache;
            
    case (cache,env as (frame::_),id,prevFrames,inState,msg) /* msg */ 
      equation 
        (cache,c,env_1,prevFrames) = lookupClassInFrame(cache,frame,env,id,prevFrames,inState,msg);
        Util.setStatefulBoolean(inState,true);
      then
        (cache,c,env_1,prevFrames);
    
    case (cache,(env as ((frame as Env.FRAME(optName = SOME(sid),isEncapsulated = true)) :: fs)),id,prevFrames,inState,_)
      equation
        true = stringEqual(id, sid) "Special case if looking up the class that -is- encapsulated. That must be allowed." ;
        (cache,c,env,prevFrames) = lookupClassInEnv(cache, fs, id, frame::prevFrames, inState, true);
        Util.setStatefulBoolean(inState,true);
      then
        (cache,c,env,prevFrames);

      /* lookup stops at encapsulated classes except for builtin
	       scope, if not found in builtin scope, error */
    case (cache,(env as (Env.FRAME(optName = SOME(sid),isEncapsulated = true) :: fs)),id,prevFrames,inState,true)
      equation
        (cache,i_env) = Builtin.initialEnv(cache);
        failure((_,_,_,_) = lookupClassInEnv(cache,i_env, id, {}, inState, false));
        scope = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_ERROR, {id,scope});
      then
        fail();

    case (cache,(Env.FRAME(optName = sid,isEncapsulated = true) :: fs),id,prevFrames,inState,msgflag) /* lookup stops at encapsulated classes, except for builtin scope */
      local
        Option<String> sid;
      equation
        (cache,i_env) = Builtin.initialEnv(cache);
        (cache,c,env_1,prevFrames) = lookupClassInEnv(cache,i_env, id, {}, inState, msgflag);
        Util.setStatefulBoolean(inState,true);
      then
        (cache,c,env_1,prevFrames);

    case (cache,(frame as Env.FRAME(optName = SOME(_), isEncapsulated = false)) :: fs,id,prevFrames,inState,msgflag) /* if not found and not encapsulated, and no ident has been previously found, look in next enclosing scope */
      equation
        false = Util.getStatefulBoolean(inState);
        (cache,c,env_1,prevFrames) = lookupClassInEnv(cache,fs, id, frame::prevFrames, inState, msgflag);
        Util.setStatefulBoolean(inState,true);
      then
        (cache,c,env_1,prevFrames);

  end matchcontinue;
end lookupClassInEnv;

protected function lookupClassInFrame "function: lookupClassInFrame

  Search for a class within one frame.
"
  input Env.Cache inCache;
  input Env.Frame inFrame;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  input list<Env.Frame> inPrevFrames;
  input Util.StatefulBoolean inState;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv;
  output list<Env.Frame> outPrevFrames;
algorithm
  (outCache,outClass,outEnv,outPrevFrames) := matchcontinue (inCache,inFrame,inEnv,inIdent,inPrevFrames,inState,inBoolean)
    local
      SCode.Class c;
      list<Env.Frame> bcenv,env,totenv,env_1,prevFrames;
      Option<String> sid;
      Env.AvlTree ht;
      String id,name;
      list<Env.Item> items;
      Env.Cache cache;
      Env.Item item;

      /* Check this scope for class */
    case (cache,Env.FRAME(optName = sid,clsAndVars = ht),totenv,name,prevFrames,inState,_)
      equation
        Env.CLASS(c,_) = Env.avlTreeGet(ht, name);
      then
        (cache,c,totenv,prevFrames);

        /* Search among the qualified imports, e.g. import A.B; or import D=A.B; */
    case (cache,Env.FRAME(optName = sid,imports = items),totenv,name,_,inState,_)
      equation 
        (cache,c,env_1,prevFrames) = lookupQualifiedImportedClassInFrame(cache,items,totenv,name,inState);
      then
        (cache,c,env_1,prevFrames);

        /* Search among the unqualified imports, e.g. import A.B.*; */
    case (cache,Env.FRAME(optName = sid,imports = items),totenv,name,_,inState,_)
      local Boolean unique;
      equation
        (cache,c,env_1,prevFrames,unique) = lookupUnqualifiedImportedClassInFrame(cache,items,totenv,name) "unique";
        Util.setStatefulBoolean(inState,true);
        reportSeveralNamesError(unique,name);
      then
        (cache,c,env_1,prevFrames);
  end matchcontinue;
end lookupClassInFrame;

protected function lookupClassAssertClass "Asserts that item is Class (which is returned.
If component is found, this is reported as an error"
  input Env.Item item;
  output SCode.Class c;
algorithm
  c := matchcontinue(item)
 local String id;
    case(Env.CLASS(class_=c)) then c;
  /* Searching for class, found component*/
    case(Env.VAR(DAE.TYPES_VAR(name=id),_,_,_)) equation
      Error.addMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id});
    then fail();
  end matchcontinue;
end lookupClassAssertClass;

protected function reportSeveralNamesError "given a boolean, report error message of importing several names
if boolean flag is false and fail. If flag is true succeed and do nothing."
  input Boolean unique;
  input String name;
algorithm
  _ := matchcontinue(unique,name)
    case(true,_) then ();
    case(false,name)
      equation
      Error.addMessage(Error.IMPORT_SEVERAL_NAMES, {name});
      then ();
  end matchcontinue;
end reportSeveralNamesError;

protected function lookupVar2 "function: lookupVar2
  Helper function to lookupVarF and lookupIdent."
  input Env.Cache inCache;
  input Env.AvlTree inBinTree;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output DAE.Var outVar;
  output Option<tuple<SCode.Element, DAE.Mod>> outTplSCodeElementTypesModOption;
  output Env.InstStatus instStatus;
  output Env.Env outEnv;
algorithm
  (outCache,outVar,outTplSCodeElementTypesModOption,instStatus,outEnv):=
  matchcontinue (inCache,inBinTree,inIdent)
    local
      DAE.Var fv;
      Option<tuple<SCode.Element, DAE.Mod>> c;
      Env.InstStatus i;
      list<Env.Frame> env;
      Env.AvlTree ht;
      String id, name;
      Env.Cache cache;
      SCode.Restriction r;

    case (cache,ht,id)
      equation
        Env.VAR(fv,c,i,env) = Env.avlTreeGet(ht, id);
      then
        (cache,fv,c,i,env);
    
    /* TODO! FIXME!
    // adrpo: we should check if we get a class when searching for a var!
    //        unfortunately this does not work as in Inst.instElement we
    //        do Lookup.lookupIdentLocal(A_CLASS_NAME) to check if a class
    //        is redeclared as variable.
    case (cache,ht,id)
      equation
        Env.CLASS(SCode.CLASS(name = name, restriction = r), env) = Env.avlTreeGet(ht, id);
        failure(equality(r = SCode.R_ENUMERATION())); // filter out enumerations as StateSelect is both a type and a component!
        failure(equality(r = SCode.R_PACKAGE())); // filter out packages!        
        name = id +& " = " +& Env.printEnvPathStr(env) +& "." +& name;
        Error.addMessage(Error.LOOKUP_COMP_FOUND_TYPE, {name});
      then
        fail();*/
    case (cache,ht,id)
      equation
        true = RTOpts.debugFlag("failtrace");
        Env.CLASS(SCode.CLASS(name = name, restriction = r), env) = Env.avlTreeGet(ht, id);
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
  outType:=
  matchcontinue (inType,inExpSubscriptLst)
    local
      tuple<DAE.TType, Option<Absyn.Path>> t,t_1;
      DAE.Dimension dim;
      Option<Absyn.Path> p;
      list<DAE.Subscript> ys,s;
      Integer sz,ind;
      list<DAE.Exp> se;
    case (t,{}) then t;
    case ((DAE.T_ARRAY(arrayDim = dim,arrayType = t),p),(DAE.WHOLEDIM() :: ys))
      equation
        t_1 = checkSubscripts(t, ys);
      then
        ((DAE.T_ARRAY(dim,t_1),p));
    case ((DAE.T_ARRAY(arrayDim = dim,arrayType = t),p),
          (DAE.SLICE(exp = DAE.ARRAY(array = se)) :: ys))
      local Integer dim_int;
      equation
        sz = Exp.dimensionSize(dim);
        t_1 = checkSubscripts(t, ys);
        dim_int = listLength(se) "FIXME: Check range IMPLEMENTED 2007-05-18 BZ" ;
        true = (dim_int <= sz);
        true = checkSubscriptsRange(se,sz);
      then
        ((DAE.T_ARRAY(DAE.DIM_INTEGER(dim_int),t_1),p));
    case ((DAE.T_ARRAY(arrayDim = dim,arrayType = t),_),
          (DAE.INDEX(exp = DAE.ICONST(integer = ind)) :: ys))
      equation
        sz = Exp.dimensionSize(dim);
        (ind > 0) = true;
        (ind <= sz) = true;
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    /* HJ: Subscripts needn't be constant. No range-checking can be done */
    case ((DAE.T_ARRAY(arrayDim = dim,arrayType = t),_),
          (DAE.INDEX(exp = e) :: ys)) 
      local DAE.Exp e;
      equation
        true = Exp.dimensionKnown(dim);
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM_UNKNOWN,arrayType = t),_),
          (DAE.INDEX(exp = _) :: ys))
      equation
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM_EXP(exp = _), arrayType = t), _),
          (DAE.INDEX(exp = _) :: ys))
      equation
        t_1 = checkSubscripts(t, ys);
      then
        t_1;  
    case ((DAE.T_ARRAY(arrayDim = dim,arrayType = t),_),
          (DAE.WHOLEDIM() :: ys))
      equation
        true = Exp.dimensionKnown(dim);
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM_UNKNOWN,arrayType = t),_),
          (DAE.WHOLEDIM() :: ys))
      equation
        t_1 = checkSubscripts(t, ys);
      then
        t_1;

    // If slicing with integer array of VAR variability, i.e. index changing during runtime.
    // => resulting ARRAY type has no specified dimension size.
    case ((DAE.T_ARRAY(arrayDim = dim,arrayType = t),p),
          (DAE.SLICE(exp = e) :: ys))
      local DAE.Exp e;
      equation
        5 = Exp.dimensionSize(dim);
        false = Exp.isArray(e);
        // we check so that e is not an array, if so the range check is useless in the function above.

        t_1 = checkSubscripts(t, ys);
      then
       ((DAE.T_ARRAY(DAE.DIM_UNKNOWN,t_1),p));
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM_UNKNOWN,arrayType = t),p),
          (DAE.SLICE(exp = _) :: ys))
      equation
        t_1 = checkSubscripts(t, ys);
      then
        ((DAE.T_ARRAY(DAE.DIM_UNKNOWN,t_1),p));

    case ((DAE.T_ARRAY(arrayDim = dim as DAE.DIM_EXP(exp = _), arrayType = t), p),
          (DAE.SLICE(exp = _) :: ys))
      equation
        t_1 = checkSubscripts(t, ys);
      then
        ((DAE.T_ARRAY(dim, t_1), p));
    case ((DAE.T_COMPLEX(_,_,SOME(t),_),_),ys)
      then checkSubscripts(t,ys);
    case(t as (DAE.T_NOTYPE(),_),_) then t;
    case (t,s)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "- Lookup.checkSubscripts failed (tp: ");
        Debug.fprint("failtrace", Types.printTypeStr(t));
        Debug.fprint("failtrace", " subs:");
        Debug.fprint("failtrace", Util.stringDelimitList(Util.listMap(s,Exp.printSubscriptStr),","));
        Debug.fprint("failtrace", ")\n");
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
      Integer x,dims;
      Boolean res;
    case(expl,dims)
      equation
        res = checkSubscriptsRange2(expl,dims);
      then res;
    case(expl,dims)
      local
        String str1,str2;
      equation
        str2 = intString(dims);
        exp = DAE.ARRAY(DAE.ET_INT(),false,expl);
        str1 = Util.stringDelimitList(Util.listMap(expl,Exp.printExpStr)," and position " );
        Error.addMessage(Error.ARRAY_INDEX_OUT_OF_BOUNDS,{str1,str2});
      then
        fail();
  end matchcontinue;
end checkSubscriptsRange;

protected function checkSubscriptsRange2 "
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
      Integer x,dims;
    case({},_) then true;
    case(((exp as DAE.ICONST(integer = x)) :: expl ),dims)
      equation
        true = (x<=dims);
        true = checkSubscriptsRange2(expl,dims);
      then
        true;
    case(_,_) then fail();
   end matchcontinue;
end checkSubscriptsRange2;

protected function lookupVarF "function: lookupVarF
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
  output Option<DAE.Const> constOfForIteratorRange "SOME(constant-ness) of the range if this is a for iterator, NONE if this is not a for iterator";
  output SplicedExpData splicedExpData;  
  output Env.Env outComponentEnv;
  output String name;
algorithm
  (outCache,outAttributes,outType,outBinding,constOfForIteratorRange,splicedExpData,outComponentEnv,name) :=
  matchcontinue (inCache,inBinTree,inComponentRef)
    local
      String n,id;
      Boolean f,streamPrefix;
      SCode.Accessibility acc;
      SCode.Variability vt,vt2;
      Absyn.Direction di;
      tuple<DAE.TType, Option<Absyn.Path>> ty,ty_1,idTp;
      DAE.Binding bind,binding,binding2;
      Env.AvlTree ht;
      list<DAE.Subscript> ss;
      list<Env.Frame> componentEnv;
      DAE.Attributes attr;
      DAE.ComponentRef ids;
      Env.Cache cache;
      DAE.ExpType ty2_2;
      Absyn.InnerOuter io;
      Option<DAE.Exp> texp;
      DAE.Type t,ty1,ty2;
      Option<Absyn.Path> p;
      DAE.ComponentRef xCref,tCref;
      list<DAE.ComponentRef> ltCref;
      DAE.Exp splicedExp;
      DAE.ExpType eType;
      DAE.Exp splicedExp;
      DAE.ExpType tty;
      Option<DAE.Const> cnstForRange;
      

    // Simple identifier
    case (cache,ht,ids as DAE.CREF_IDENT(ident = id,subscriptLst = ss) )
      equation 
        (cache,DAE.TYPES_VAR(name,DAE.ATTR(f,streamPrefix,acc,vt,di,io),_,ty,bind,cnstForRange),_,_,componentEnv) = lookupVar2(cache,ht, id);
        ty_1 = checkSubscripts(ty, ss);
        ss = addArrayDimensions(ty,ss);
        tty = Types.elabType(ty);     
        ty2_2 = Types.elabType(ty);        
        splicedExp = DAE.CREF(DAE.CREF_IDENT(id,ty2_2, ss),tty);
        //print("splicedExp ="+&Exp.dumpExpStr(splicedExp,0)+&"\n");
      then
        (cache,DAE.ATTR(f,streamPrefix,acc,vt,di,io),ty_1,bind,cnstForRange,SPLICEDEXPDATA(SOME(splicedExp),ty),componentEnv,name);

    // Qualified variables looked up through component environment with a spliced exp
    case (cache,ht,xCref as (DAE.CREF_QUAL(ident = id,subscriptLst = ss,componentRef = ids)))
      local Types.Type idTp;
      equation 
        (cache,DAE.TYPES_VAR(_,DAE.ATTR(_,_,_,vt2,_,_),_,ty2,bind,cnstForRange),_,_,componentEnv) = lookupVar2(cache,ht, id);
        // outer variables are not local!
        // this doesn't work yet!
        // false = Absyn.isOuter(io);
        //
        (cache,DAE.ATTR(f,streamPrefix,acc,vt,di,io),ty,binding,cnstForRange,SPLICEDEXPDATA(texp,idTp),_,componentEnv,name) = lookupVar(cache, componentEnv, ids);
        (tCref::ltCref) = elabComponentRecursive((texp));
        ty1 = checkSubscripts(ty2, ss);
        ty = sliceDimensionType(ty1,ty);
        ss = addArrayDimensions(ty2,ss);
        ty2_2 = Types.elabType(ty2);
        xCref = DAE.CREF_QUAL(id,ty2_2,ss,tCref);
        eType = Types.elabType(ty);
        splicedExp = DAE.CREF(xCref,eType);
        vt = SCode.variabilityOr(vt,vt2);
      then
        (cache,DAE.ATTR(f,streamPrefix,acc,vt,di,io),ty,binding,cnstForRange,SPLICEDEXPDATA(SOME(splicedExp),idTp),componentEnv,name);

    // Qualified componentname without spliced exp.
    case (cache,ht,xCref as (DAE.CREF_QUAL(ident = id,subscriptLst = ss,componentRef = ids)))
      equation
        (cache,DAE.TYPES_VAR(_,DAE.ATTR(_,_,_,vt2,_,_),_,ty2,bind,cnstForRange),_,_,componentEnv) = lookupVar2(cache,ht, id);
        (cache,DAE.ATTR(f,streamPrefix,acc,vt,di,io),ty,binding,cnstForRange,SPLICEDEXPDATA(texp,idTp),_,componentEnv,name) = lookupVar(cache, componentEnv, ids);
        {} = elabComponentRecursive((texp));
        vt = SCode.variabilityOr(vt,vt2);
      then
        (cache,DAE.ATTR(f,streamPrefix,acc,vt,di,io),ty,binding,cnstForRange,SPLICEDEXPDATA(NONE(),idTp),componentEnv,name);
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
      list<DAE.Dimension> dims;
    case(_, _)
      equation
        true = Types.isArray(tySub);
        dims = Types.getDimensions(tySub);
        subs = Util.listMap(dims, makeDimensionSubscript);
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
  outSubs := matchcontinue(inDim)
    local
      Integer sz;
      list<DAE.Exp> expl;  
    // Special case when addressing array[0].
    case DAE.DIM_INTEGER(integer = 0)
      then
        DAE.SLICE(DAE.ARRAY(DAE.ET_INT, true, {DAE.ICONST(0)}));
    // Array with integer dimension.
    case DAE.DIM_INTEGER(integer = sz)
      equation
        expl = Util.listMap(Util.listIntRange(sz), Exp.makeIntegerExp);
      then
        DAE.SLICE(DAE.ARRAY(DAE.ET_INT, true, expl));
    // Array with enumeration dimension.
    case DAE.DIM_ENUM(enumTypeName = enum_name, literals = l, size = sz)
      local
        Absyn.Path enum_name;
        list<String> l;
      equation
        expl = makeEnumLiteralIndices(enum_name, l, 1);
      then
        DAE.SLICE(DAE.ARRAY(DAE.ET_ENUMERATION(enum_name, l, {}), true, expl));
  end matchcontinue;
end makeDimensionSubscript;
          
protected function makeEnumLiteralIndices
  "Creates a list of enumeration literal expressions from an enumeration."
  input Absyn.Path enumTypeName;
  input list<String> enumLiterals;
  input Integer enumIndex;
  output list<DAE.Exp> enumIndices;
algorithm
  enumIndices := matchcontinue(enumTypeName, enumLiterals, enumIndex)
    case (_, {}, _) then {};
    case (_, l :: ls, _)
      local
        String l;
        list<String> ls;
        DAE.Exp e;
        list<DAE.Exp> expl;
        Absyn.Path enum_type_name;
      equation
        enum_type_name = Absyn.joinPaths(enumTypeName, Absyn.IDENT(l));
        e = DAE.ENUM_LITERAL(enum_type_name, enumIndex);
        expl = makeEnumLiteralIndices(enumTypeName, ls, enumIndex + 1);
      then
        e :: expl;
  end matchcontinue;
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


// BZ(2010-01-29): Changed to public to be able to vectorize crefs from other places
public function makeExpIntegerArray " function makeExpIntegerArray
takes a list of integers, each representing a dimension, eg: 2,3,4 meaning an
array[2 array[3 array[4
returns a DAE.SLICE for each dimension with a number from 1 to dimension size.
ex. Real A[2,3] ==> A[{{1,2}{1,2,3}}]
"
  input list<Integer> inInt;
  output list<DAE.Subscript> oExp;

algorithm
   oExp :=
  matchcontinue(inInt)
    case({})
    then
      {};
    case((i :: iLst))
      local
        Integer i;
        list<Integer> iLst;
        list<DAE.Subscript > expsl;
        DAE.Subscript exps;
        DAE.Exp tmpArray;

      equation
        expsl = makeExpIntegerArray(iLst);
        exps = makeExpIntegerArray2(i,1);
        tmpArray = DAE.ARRAY(DAE.ET_INT(), true/*elts are scalars*/, exps);
        exps = DAE.SLICE(tmpArray);
      then
        (exps :: expsl);
  end matchcontinue;
end makeExpIntegerArray;

protected function makeExpIntegerArray2 " function makeExpIntegerArray2
This is the actuall function where we add numbers.
There is a special case when we are declaring a dim[0] subscript.

"
  input Integer inInt;
  input Integer inIntCurr;
  output list<DAE.Exp> out;

algorithm
   out :=
   matchcontinue (inInt,inIntCurr)
     local
       Integer iMax,iCur,iTmp;
     case(iMax,iCur) // the case when we are adressing a[0] , a[1,3,4,0] ...
       equation
         true = (iMax < iCur);
       then
         {DAE.ICONST(iMax)};
     case(iMax,iCur)
       equation
         true = (iMax == iCur);
       then
         {DAE.ICONST(iCur)};
     case(iMax,iCur)
       local
         list<DAE.Exp> expli;
       equation
         expli = makeExpIntegerArray2(iMax, iCur+1);
       then
         (DAE.ICONST(iCur) :: expli);
  end matchcontinue;
end makeExpIntegerArray2;



protected function sliceDimensionType " function sliceDimensionType
Lifts an type to spcified dimension by type2
"
  input DAE.Type inTypeD;
  input DAE.Type inTypeL;
  output DAE.Type outType;

algorithm
   outType :=
  matchcontinue (inTypeD,inTypeL)
    case(t, tOrg)
      local
        DAE.Type t,tOrg;
        list<Integer> dimensions;
        list<DAE.Dimension> dim2;
        DAE.TType tty;
        String str;
      equation
        dimensions = Types.getDimensionSizes(t);
        dim2 = Util.listMap(dimensions, Exp.intDimension); 
        dim2 = listReverse(dim2);
        t = ((Util.listFoldR(dim2,Types.liftArray, tOrg)));
      then
        t;
  end matchcontinue;
end sliceDimensionType;


protected function assertPackage "function: assertPackage

  This function checks that a class definition is a package.  This
  breaks the everything-can-be-generalized-to-class principle, since
  it requires that the keyword `package\' is used in the package file.
"
  input SCode.Class inClass;
  input String className;
algorithm
  _:=
  matchcontinue (inClass,className)
    case (SCode.CLASS(restriction = SCode.R_PACKAGE()),_) then ();  /* Break the generalize-to-class rule */
    case (_,_) equation
      Error.addMessage(Error.WARNING_IMPORT_PACKAGES_ONLY,{className});
    then ();
  end matchcontinue;
end assertPackage;
end Lookup;

