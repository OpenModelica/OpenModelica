/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
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
  file:	       Lookup.mo
  package:     Lookup
  description: Scoping rules

  RCS: $Id$

  This module is responsible for the lookup mechanism in Modelica.
  It is responsible for looking up classes, variables, etc. in the
  environment \'Env\' by following the lookup rules.
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

protected import Builtin;
protected import Connect;
protected import ConnectionGraph;
protected import Debug;
protected import Error;
protected import Exp;
protected import Inst;
protected import InstanceHierarchy;
protected import Mod;
protected import ModUtil;
protected import Prefix;
//protected import SCodeUtil;
protected import Static;
protected import Types;
protected import UnitAbsyn;
protected import Util;

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
        t = (DAE.T_FUNCTION({("x", (DAE.T_ANYTYPE(NONE), NONE))}, (DAE.T_BOOL({}), NONE), DAE.NO_INLINE), NONE);
      then
        (cache, t, env);

    // Special handling for MultiBody 3.x rooted() operator
    case (cache,env,Absyn.IDENT("rooted"),msg)
      equation 
        t = (DAE.T_FUNCTION({("x", (DAE.T_ANYTYPE(NONE), NONE))}, (DAE.T_BOOL({}), NONE), DAE.NO_INLINE), NONE);
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
        (cache,c,env_1) = lookupClass2(cache,env,path,false);
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
      Absyn.Path path;
      SCode.Class c;
      String id;
      SCode.Restriction restr;
      Env.Cache cache;
      list<DAE.Var> varlst;
        
    // Record constructors        
    case (cache,env_1,path,c as SCode.CLASS(name=id,restriction=SCode.R_RECORD()))
      equation
        (cache,path) = Inst.makeFullyQualified(cache,env_1,Absyn.IDENT(id));
        (cache,varlst) = buildRecordConstructorVarlst(cache,c,env_1);
        t = Types.makeFunctionType(path, varlst, Inst.isInlineFunc2(c));
      then 
        (cache,t,env_1);
        
    // lookup of an enumeration type 
    case (cache,env_1,path,c as SCode.CLASS(id,_,encflag,r as SCode.R_ENUMERATION(),_))
      local
        SCode.Restriction r; 
        list<Types.Var> types;
        list<String> names;
        ClassInf.State ci_state;
        Boolean encflag;
      equation
        env_2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(r, id);
        (cache,env_3,_,_,_,_,_,types,_,_,_,_) = 
        Inst.instClassIn(
          cache,env_2,InstanceHierarchy.emptyInstHierarchy,UnitAbsyn.noStore, 
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}, false, ConnectionGraph.EMPTY,NONE);
        // build names
        (_,names) = SCode.getClassComponents(c);
        // generate the enumeration type        
        t = (DAE.T_ENUMERATION(NONE(), path, names, types), SOME(path));
        env_3 = Env.extendFrameT(env_3, id, t);
      then
        (cache,t,env_3);        

    // Metamodelica extension, Uniontypes
    case (cache,env_1,path,c as SCode.CLASS(id,_,_,SCode.R_METARECORD(_,index),SCode.PARTS(elementLst = els))) 
      local
        Integer index;
        list<SCode.Element> els;
        list<tuple<SCode.Element,DAE.Mod>> elsModList;
      equation 
        (cache,path) = Inst.makeFullyQualified(cache,env_1,Absyn.IDENT(id));
        elsModList = Util.listMap1(els,Util.makeTuple2,DAE.NOMOD);
        (cache,env_2,_,_,_,_,_,varlst,_) = Inst.instElementList(
            cache,env_1,InstanceHierarchy.emptyInstHierarchy, UnitAbsyn.noStore,
            DAE.NOMOD,Prefix.NOPRE, Connect.emptySet, ClassInf.FUNCTION(""), elsModList, {}, false, ConnectionGraph.EMPTY);
        t = (DAE.T_METARECORD(index,varlst),SOME(path));
      then
        (cache,t,env_2);
        
    // Classes that are external objects. Implicitly instantiate to get type
    case (cache,env_1,path,c)
      local
      equation
        true = Inst.classIsExternalObject(c);
        (cache,_::env_1,_,_,_,_,_,_,_,_) = 
        Inst.instClass(
          cache,env_1,InstanceHierarchy.emptyInstHierarchy, UnitAbsyn.noStore,
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
        Inst.implicitFunctionTypeInstantiation(cache,env_1,InstanceHierarchy.emptyInstHierarchy,c);
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
	      innerTypes = Types.getAllInnerTypes(ty);
        uniontypeTypes = Util.listFilter(innerTypes, Types.uniontypeFilter);
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

public function lookupClass "
Tries to find a specified class in an environment
  
  Arg1: The enviroment where to look
  Arg2: The path for the class
  Arg3: A Bool to control the output of error-messages. If it is true
        then it outputs a error message if the class is not found."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv;
protected
  Real t1,t2,time;
  Boolean b;
  String s,s2;
algorithm 
  (outCache,outClass,outEnv) := lookupClass2(inCache,inEnv, inPath, inBoolean);
end lookupClass;
    
public function lookupClass2 "help function to lookupClass, does all the work."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm 
  (inCache,outClass,outEnv) := matchcontinue (inCache,inEnv,inPath,inBoolean)
    local
      Env.Frame f;
      Env.Cache cache;
      SCode.Class c,c_1;
      list<Env.Frame> env,env_1,env2,env_2,env_3,env1,env4,env5,fs;
      Absyn.Path path,ep,packp,p,scope,restPath;
      String id,s,name,pack;
      Boolean msg,encflag,msgflag;
      SCode.Restriction restr;
      ClassInf.State ci_state,cistate1;
    
    /* First look in cache for environment. If found look up class in that environment */
    case (cache,env,path,msg)
      equation        
        SOME(scope) = Env.getEnvPath(env);
        f::fs = Env.cacheGet(scope,path,cache);
        id = Absyn.pathLastIdent(path);
        (cache,c,env) = lookupClassInEnv(cache,fs,Absyn.IDENT(id),msg); 
        //print("HIT:");print(Absyn.pathString(path));print(" scope");print(Absyn.pathString(scope));print("\n");
        //print(Env.printCacheStr(cache));       
      then
        (cache,c,env);
      
    // Fully qualified names are looked up in top scope.
    case (cache,env,Absyn.FULLYQUALIFIED(path),msg) 
      equation
        f = Env.topFrame(env);
        (cache,c,env_1) = lookupClass2(cache,{f},path,msg);
      then       
        (cache,c,env_1);
              
    // Qualified names first identifier cached
    case (cache,env,(p as Absyn.QUALIFIED(name = pack,path = path)),msgflag) 
      equation 
        //s = Absyn.pathString(path);
        SOME(scope) = Env.getEnvPath(env);
        env_1 = Env.cacheGet(scope,Absyn.IDENT(pack),cache);
        (cache,c_1,env_2) = lookupClass2(cache,env_1,path,msgflag);
        //print("Qualified cache hit on ");print(Absyn.pathString(p));print("\n");
      then
        (cache,c_1,env_2);     
            
    // Simple names
    case (cache,env,(path as Absyn.IDENT(name = name)),msgflag)
      equation 
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClassInEnv(cache,env, path, msgflag);
      then
        (cache,c,env_1);       
        
    // Qualified names
                       
    // If we search for A1.A2....An.x while in scope A1.A2...An, 
    // just search for x. Must do like this to ensure finite recursion (x can be both qualified or simple)  
    case (cache,env,(p as Absyn.QUALIFIED(name = _)),msgflag)
      equation 
        (true,p) = scopePrefixOf(env,p);
        (cache,c,env_1) = lookupClass2(cache,env, p, msgflag);
      then
        (cache,c,env_1); 
        
    // Qualified names in package  
    case (cache,env,(p as Absyn.QUALIFIED(name = pack,path = path)),msgflag) 
      equation 
        (false,_) = scopePrefixOf(env,p);
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env1) = lookupClass2(cache,env, Absyn.IDENT(pack), msgflag);
        env2 = Env.openScope(env1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        (cache,env4,_,cistate1) = 
        Inst.partialInstClassIn(
          cache,env2,InstanceHierarchy.emptyInstHierarchy, 
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}); 
         ClassInf.valid(cistate1, SCode.R_PACKAGE());
        (cache,c_1,env5) = lookupClass2(cache,env4, path, msgflag) "Has NOT to do additional check for encapsulated classes, see rule above" ;
      then
        (cache,c_1,env5);
        
    // Qualified names in non package 
    case (cache,env,(p as Absyn.QUALIFIED(name = pack,path = path)),msgflag) 
      equation 
        (false,_) = scopePrefixOf(env,p);
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass2(cache,env, Absyn.IDENT(pack), msgflag);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        (cache,env_2,_,cistate1) = 
        Inst.partialInstClassIn(
          cache,env2,InstanceHierarchy.emptyInstHierarchy,
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}); 
        failure(ClassInf.valid(cistate1, SCode.R_PACKAGE()));
        (cache,c_1,env_3) = lookupClass2(cache,env_2, path, msgflag) "Has to do additional check for encapsulated classes, see rule below" ;
      then
        (cache,c_1,env_3);
        
    case (cache,env,path,true)
      equation 
        /*s = Absyn.pathString(path) ;
        Debug.fprint("failtrace", "- lookup_class failed\n  - looked for ") ;
        //print("lookup class ");print(s);print("failed\n");
        Debug.fprint("failtrace", s);
        Debug.fprint("failtrace", "\n env:");
        s = Env.printEnvStr(env); 
        //print("env:");print(s);
        //print("Cache:");print(Env.printCacheStr(cache));print("\n");
        Debug.fprint("failtrace", s);
        Debug.fprint("failtrace", "\n");
        */
        //print("lookupClass2(");print(Absyn.pathString(path));print(",msg=false failed, env:\n");
      then
        fail();
        
    case (cache,env,path,false)
      equation 
        //print("lookupClass2(");print(Absyn.pathString(path));print(",msg=false failed, env:");
        //print(Env.printEnvStr(env));print("\n");
      then
        fail();
  end matchcontinue;
end lookupClass2;

protected function scopePrefixOf " Help function to lookupClass2.
returns true if scope in environment is a prefix of the path given as second argument.
In that case, the scope-prefix is removed from the path and returned.

This is used to prevent infinite recursion when looking up classes.
"
input Env.Env env;
input Absyn.Path p;
output Boolean isPrefix;
output Absyn.Path outP;
algorithm
  (isPrefix,outP) := matchcontinue(env,p)
  local Absyn.Path ep;
    case(env,p) equation      
      SOME(ep) = Env.getEnvPath(env)  ;
      true = Absyn.pathPrefixOf(ep,p);
      p = Absyn.removePrefix(ep,p);      
    then (true,p);
    case(_,p) then (false,p); 
  end matchcontinue;
end scopePrefixOf;

protected function lookupQualifiedImportedVarInFrame "function: lookupQualifiedImportedVarInFrame
  author: PA
  
  Looking up variables (constants) imported using qualified imports, 
  i.e. import Modelica.Constants.PI;
"
	input Env.Cache inCache;
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output DAE.Attributes outAttributes;
  output DAE.Type outType;
  output DAE.Binding outBinding;
algorithm 
  (outCache,outEnv,outAttributes,outType,outBinding):=
  matchcontinue (inCache,inEnvItemLst,inEnv,inIdent)
    local
      Env.Frame fr;
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Binding bind;
      String id,id2,ident,str;
      list<Env.Item> fs;
      list<Env.Frame> env,p_env,cenv;
      DAE.ComponentRef cref;
      Absyn.Path strippath,path;
      SCode.Class c2;
      Env.Cache cache;
      
      /* For imported simple name, e.g. A, not possible to assert 
       sub-path package */ 
    case (cache,(Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = Absyn.IDENT(name = id))) :: fs),env,ident) 
      equation 
        equality(id = ident);
        fr = Env.topFrame(env);
        (cache,attr,ty,bind,_,_) = lookupVar(cache,{fr}, DAE.CREF_IDENT(ident,DAE.ET_OTHER(),{}));
      then
        (cache,{fr},attr,ty,bind);

        /* For imported qualified name, e.g. A.B.C, assert A.B is package */ 
    case (cache,(Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = path)) :: fs),env,ident) 
      equation 
        id = Absyn.pathLastIdent(path);
        equality(id = ident);
        fr = Env.topFrame(env);
        cref = Exp.pathToCref(path);       
        strippath = Absyn.stripLast(path);
        (cache,c2,cenv) = lookupClass2(cache,{fr}, strippath, true);
        assertPackage(c2,Absyn.pathString(strippath));
        
        cref = Exp.pathToCref(Absyn.pathTwoLastIdents(path));        
        (cache,p_env,attr,ty,bind) = lookupVarInPackages(cache, cenv, cref);
      then
        (cache,p_env,attr,ty,bind);

        /* importing qualified name, If not package, error */
        /* commented since MSL does not follow this rule, instead assertPackage gives warning */         
  /*  case (cache,(Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = path)) :: fs),env,ident) 
      equation 
        id = Absyn.pathLastIdent(path);
        equality(id = ident);
        fr = Env.topFrame(env);
        cref = Exp.pathToCref(path);
        (cache,p_env,attr,ty,bind) = lookupVarInPackages(cache,{fr}, cref);
        strippath = Absyn.stripLast(path);
        (cache,c2,_) = lookupClass2(cache,{fr}, strippath, true);
        failure(assertPackage(c2));
        str = Absyn.pathString(strippath);
        Error.addMessage(Error.IMPORT_PACKAGES_ONLY, {str});
      then
        fail();*/
    
        /* Named imports of simple names, e.g. import A = C; */ 
    case (cache,(Env.IMPORT(import_ = Absyn.NAMED_IMPORT(name = id,path = Absyn.IDENT(id2))) :: fs),env,ident) 
      equation 
        equality(id = ident);
        fr = Env.topFrame(env);
        cref = Exp.pathToCref(Absyn.IDENT(id2));
        (cache,p_env,attr,ty,bind) = lookupVarInPackages(cache,{fr}, cref);        
      then
        (cache,p_env,attr,ty,bind);
        
        /* Named imports, e.g. import A = B.C; */ 
    case (cache,(Env.IMPORT(import_ = Absyn.NAMED_IMPORT(name = id,path = path)) :: fs),env,ident) 
      equation 
        equality(id = ident);
        fr = Env.topFrame(env);
        cref = Exp.pathToCref(path);
        strippath = Absyn.stripLast(path);
        (cache,c2,cenv) = lookupClass2(cache,{fr}, strippath, true);
        assertPackage(c2,Absyn.pathString(strippath));
        
        cref = Exp.pathToCref(Absyn.pathTwoLastIdents(path));        
        (cache,p_env,attr,ty,bind) = lookupVarInPackages(cache,cenv, cref);        
      then
        (cache,p_env,attr,ty,bind);

        /* Error message if named import is not package. */         
        /* commented since MSL does not follow this rule, instead assertPackage gives warning */
    /*case (cache,(Env.IMPORT(import_ = Absyn.NAMED_IMPORT(name = id,path = path)) :: fs),env,ident) 
      equation 
        equality(id = ident);
        fr = Env.topFrame(env);
        cref = Exp.pathToCref(path);
        (cache,p_env,attr,ty,bind) = lookupVarInPackages(cache,{fr}, cref);
        strippath = Absyn.stripLast(path);
        (cache,c2,_) = lookupClass2(cache,{fr}, strippath, true);
        failure(assertPackage(c2));
        str = Absyn.pathString(strippath);
        Error.addMessage(Error.IMPORT_PACKAGES_ONLY, {str});
      then
        fail();*/
        
        /* Check next frame. */ 
    case (cache,(_ :: fs),env,ident) 
      equation 
        (cache,p_env,attr,ty,bind) = lookupQualifiedImportedVarInFrame(cache,fs, env, ident);
      then
        (cache,p_env,attr,ty,bind);
  end matchcontinue;
end lookupQualifiedImportedVarInFrame;

protected function moreLookupUnqualifiedImportedVarInFrame "function: moreLookupUnqualifiedImportedVarInFrame
  
  Helper function for lookup_unqualified_imported_var_in_frame. Returns 
  true if there are unqualified imports that matches a sought constant.
"
	input Env.Cache inCache;
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output Boolean outBoolean;
algorithm 
  (outCache,outBoolean) :=
  matchcontinue (inCache,inEnvItemLst,inEnv,inIdent)
    local
      Env.Frame fr,f;
      SCode.Class c;
      String id,ident;
      Boolean encflag,res;
      SCode.Restriction restr;
      list<Env.Frame> env_1,env2,env;
      ClassInf.State ci_state;
      Absyn.Path path;
      list<Env.Item> fs;
      Env.Cache cache;
    case (cache,(Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident)
           local 
        DAE.ComponentRef cr;
        Absyn.Path path,scope;
        Absyn.Ident firstIdent;
      equation 
        firstIdent = Absyn.pathFirstIdent(path);
        f::_ = Env.cacheGet(Absyn.IDENT(firstIdent),path,cache);
        (cache,_,_,_,_) = lookupVarInPackages(cache,{f}, DAE.CREF_IDENT(ident,DAE.ET_OTHER(),{}));
      then
        (cache,true);
     
      // if not found in cache , try to instantiate
    case (cache,(Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident)
      equation  
        fr = Env.topFrame(env);
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass2(cache,{fr}, path, false);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
         (cache,(f :: _),_,_) = 
         Inst.partialInstClassIn(
           cache,env2,InstanceHierarchy.emptyInstHierarchy,
           DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
           ci_state, c, false, {}); 
        (cache,_,_,_,_) = lookupVarInPackages(cache,{f}, DAE.CREF_IDENT(ident,DAE.ET_OTHER(),{}));
      then
        (cache,true);        
    case (cache,(_ :: fs),env,ident)
      equation 
        (cache,res) = moreLookupUnqualifiedImportedVarInFrame(cache,fs, env, ident);
      then
        (cache,res);
    case (cache,{},_,_) then (cache,false); 
  end matchcontinue;
end moreLookupUnqualifiedImportedVarInFrame;

protected function lookupUnqualifiedImportedVarInFrame "function: lookupUnqualifiedImportedVarInFrame
  
  Find a variable from an unqualified import locally in a frame
"
	input Env.Cache inCache;
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output DAE.Attributes outAttributes;
  output DAE.Type outType;
  output DAE.Binding outBinding;
  output Boolean outBoolean;
algorithm 
  (outCache,outEnv,outAttributes,outType,outBinding,outBoolean):=
  matchcontinue (inCache,inEnvItemLst,inEnv,inIdent)
    local
      Env.Frame fr,f;
      DAE.ComponentRef cref;
      SCode.Class c;
      String id,ident;
      Boolean encflag,more,unique;
      SCode.Restriction restr;
      list<Env.Frame> env_1,env2,env,p_env;
      ClassInf.State ci_state;
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Binding bind;
      Absyn.Path path;
      list<Env.Item> fs;
      Env.Cache cache;
      // First look in cache
    case (cache,(Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident) /* unique */ 
           local 
        DAE.ComponentRef cr;
        Absyn.Path path,scope;
        Absyn.Ident firstIdent;
      equation 
        //print("look in cache\n");
        firstIdent = Absyn.pathFirstIdent(path);
        f::_ = Env.cacheGet(Absyn.IDENT(firstIdent),path,cache);
        (cache,p_env,attr,ty,bind) = lookupVarInPackages(cache,{f}, DAE.CREF_IDENT(ident,DAE.ET_OTHER(),{}));
        (cache,more) = moreLookupUnqualifiedImportedVarInFrame(cache,fs, env, ident);
        unique = boolNot(more);
      then
        (cache,p_env,attr,ty,bind,unique);

      // if not in cache, try to instantiate
    case (cache,(Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident) /* unique */ 
       equation 
        fr = Env.topFrame(env);
        cref = Exp.pathToCref(path);
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass2(cache,{fr}, path, false);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        (cache,(f :: _),_,_,_,_,_,_,_,_,_,_) = 
        Inst.instClassIn(
          cache,env2,InstanceHierarchy.emptyInstHierarchy, UnitAbsyn.noStore,
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}, false, ConnectionGraph.EMPTY,NONE);
        (cache,p_env,attr,ty,bind) = lookupVarInPackages(cache,{f}, DAE.CREF_IDENT(ident,DAE.ET_OTHER(),{}));
        (cache,more) = moreLookupUnqualifiedImportedVarInFrame(cache,fs, env, ident);
        unique = boolNot(more);
      then
        (cache,p_env,attr,ty,bind,unique);
    case (cache,(_ :: fs),env,ident)
      equation 
        (cache,p_env,attr,ty,bind,unique) = lookupUnqualifiedImportedVarInFrame(cache,fs, env, ident);
      then
        (cache,p_env,attr,ty,bind,unique);
  end matchcontinue;
end lookupUnqualifiedImportedVarInFrame;

protected function lookupQualifiedImportedClassInFrame 
"function: lookupQualifiedImportedClassInFrame  
  Helper function to lookupQualifiedImportedClassInEnv."
	input Env.Cache inCache;
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm 
  (outCache,outClass,outEnv):=
  matchcontinue (inCache,inEnvItemLst,inEnv,inIdent)
    local
      Env.Frame fr;
      SCode.Class c,c2;
      list<Env.Frame> env_1,env;
      String id,ident,str;
      list<Env.Item> fs;
      Absyn.Path strippath,path;
      Env.Cache cache;
    case (cache,(Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = Absyn.IDENT(name = id))) :: fs),env,ident)
      equation 
        equality(id = ident) "For imported paths A, not possible to assert sub-path package" ;
        fr = Env.topFrame(env);
        (cache,c,env_1) = lookupClass2(cache,{fr}, Absyn.IDENT(id), true);
      then
        (cache,c,env_1);
    case (cache,(Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = path)) :: fs),env,ident)
      equation 
        id = Absyn.pathLastIdent(path) "For imported path A.B.C, assert A.B is package" ;
        equality(id = ident);
        fr = Env.topFrame(env);
        (cache,c,env_1) = lookupClass2(cache,{fr}, path, true);
        strippath = Absyn.stripLast(path);
        (cache,c2,_) = lookupClass2(cache,{fr}, strippath, true);
        assertPackage(c2,Absyn.pathString(strippath));
      then
        (cache,c,env_1);
        /* commented since MSL does not follow this rule, instead assertPackage gives warning */
    /*case (cache,(Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = path)) :: fs),env,ident)
      equation 
        id = Absyn.pathLastIdent(path) "If not package, error" ;
        equality(id = ident);
        fr = Env.topFrame(env);
        (cache,c,env_1) = lookupClass2(cache,{fr}, path, true);
        strippath = Absyn.stripLast(path);
        (cache,c2,_) = lookupClass2(cache,{fr}, strippath, true);
        failure(assertPackage(c2));
        str = Absyn.pathString(strippath);
        Error.addMessage(Error.IMPORT_PACKAGES_ONLY, {str});
      then
        fail();*/
    case (cache,(Env.IMPORT(import_ = Absyn.NAMED_IMPORT(name = id,path = path)) :: fs),env,ident)
      equation 
        equality(id = ident) "Named imports" ;
        fr = Env.topFrame(env);
        (cache,c,env_1) = lookupClass2(cache,{fr}, path, true);
        strippath = Absyn.stripLast(path);
        (cache,c2,_) = lookupClass2(cache,{fr}, strippath, true);
        assertPackage(c2,Absyn.pathString(strippath));
      then
        (cache,c,env_1);
        /* Error message if named import is not package */
        /* commented since MSL does not follow this rule, instead assertPackage gives warning */
    /*case (cache,(Env.IMPORT(import_ = Absyn.NAMED_IMPORT(name = id,path = path)) :: fs),env,ident)
      equation 
        equality(id = ident) "Assert package for Named imports" ;
        fr = Env.topFrame(env);
        (cache,c,env_1) = lookupClass2(cache,{fr}, path, true);
        strippath = Absyn.stripLast(path);
        (cache,c2,_) = lookupClass2(cache,{fr}, strippath, true);
        failure(assertPackage(c2));
        str = Absyn.pathString(strippath);
        Error.addMessage(Error.IMPORT_PACKAGES_ONLY, {str});
      then
        fail();*/
        
    case (cache,(_ :: fs),env,ident)
      equation 
        (cache,c,env_1) = lookupQualifiedImportedClassInFrame(cache,fs, env, ident);
      then
        (cache,c,env_1);
  end matchcontinue;
end lookupQualifiedImportedClassInFrame;

protected function moreLookupUnqualifiedImportedClassInFrame "function: moreLookupUnqualifiedImportedClassInFrame
  
  Helper function for lookup_unqualified_imported_class_in_frame
"
 	input Env.Cache inCache;
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;  
	output Env.Cache outCache;
  output Boolean outBoolean;
algorithm 
  (outCache,outBoolean) :=
  matchcontinue (inCache,inEnvItemLst,inEnv,inIdent)
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
        (cache,_,_) = lookupClass2(cache,{f}, Absyn.IDENT(ident), false);
      then
        (cache,true);
        
        // Not found, instantiate
    case (cache,(Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident)
      equation 
        fr = Env.topFrame(env);
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass2(cache,{fr}, path, false);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
       (cache,(f :: _),_,_) = 
       Inst.partialInstClassIn(
          cache,env2,InstanceHierarchy.emptyInstHierarchy,
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
        (cache,_,_) = lookupClass2(cache,{f}, Absyn.IDENT(ident), false);
      then
        (cache,true);
    case (cache,(_ :: fs),env,ident)
      equation 
        (cache,res) = moreLookupUnqualifiedImportedClassInFrame(cache,fs, env, ident);
      then
        (cache,res);
    case (cache,{},_,_) then (cache,false); 
  end matchcontinue;
end moreLookupUnqualifiedImportedClassInFrame;

protected function lookupUnqualifiedImportedClassInFrame "function: lookupUnqualifiedImportedClassInFrame
  
  Finds a class from an unqualified import locally in a frame
"
	input Env.Cache inCache;
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv;
  output Boolean outBoolean;
algorithm 
  (outCache,outClass,outEnv,outBoolean):=
  matchcontinue (inCache,inEnvItemLst,inEnv,inIdent)
    local
      Env.Frame fr,f,f_1;
      SCode.Class c,c_1;
      String id,ident;
      Boolean encflag,more,unique;
      SCode.Restriction restr;
      list<Env.Frame> env_1,env2,fs_1,env;
      ClassInf.State ci_state,cistate1;
      Absyn.Path path;
      list<Env.Item> fs;
      Env.Cache cache;
      Absyn.Ident firstIdent;
      // Look in cache
    case (cache,(Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident) /* unique */ 
      equation
        firstIdent = Absyn.pathFirstIdent(path);
        f::fs_1 = Env.cacheGet(Absyn.IDENT(firstIdent),path,cache);
        (cache,c_1,(f_1 :: _)) = lookupClass2(cache,{f}, Absyn.IDENT(ident), false) "Restrict import to the imported scope only, not its parents..." ;
        (cache,more) = moreLookupUnqualifiedImportedClassInFrame(cache,fs, env, ident);
        unique = boolNot(more);
      then
        (cache,c_1,(f_1 :: fs_1),unique);
        
        // Not in cache, instantiate.
    case (cache,(Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident) /* unique */ 
      equation 
        fr = Env.topFrame(env);
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass2(cache,{fr}, path, false);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        (cache,(f :: fs_1),_,cistate1) = 
        Inst.partialInstClassIn(
          cache,env2,InstanceHierarchy.emptyInstHierarchy,
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}); 
        // Restrict import to the imported scope only, not its parents, thus {f} below
        (cache,c_1,(f_1 :: _)) = lookupClass2(cache,{f}, Absyn.IDENT(ident), false) "Restrict import to the imported scope only, not its parents..." ;
        (cache,more) = moreLookupUnqualifiedImportedClassInFrame(cache,fs, env, ident);
        unique = boolNot(more);
      then
        (cache,c_1,(f_1 :: fs_1),unique);
    case (cache,(_ :: fs),env,ident)
      equation 
        (cache,c,env_1,unique) = lookupUnqualifiedImportedClassInFrame(cache,fs, env, ident);
      then
        (cache,c,env_1,unique);
  end matchcontinue;
end lookupUnqualifiedImportedClassInFrame;

public function lookupRecordConstructorClass "function: lookupRecordConstructorClass
  
  Searches for a record constructor implicitly 
  defined by a record class.
"
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm 
  (outClass,outEnv):=
  matchcontinue (inEnv,inPath)
    local
      SCode.Class c;
      list<Env.Frame> env,env_1,env_2,env_3;
      Absyn.Path path;
      String name;
    case (env,path)
      equation 
        (_,c as SCode.CLASS(name = name, restriction=SCode.R_RECORD()) ,env_1) = lookupClass2(Env.emptyCache(),env, path, false);
        c = buildRecordConstructorClass(c, env_1);
      then
        (c,env_1);
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
  (outCache,attr,tp):=matchcontinue(cache,env,cr)
  local DAE.ComponentRef cr1;
      Boolean f,streamPrefix;
      SCode.Variability var; SCode.Accessibility acc;
      Absyn.Direction dir;
      Absyn.InnerOuter io;
      DAE.Type ty1;
      DAE.Attributes attr1;
    case(cache,env,cr as DAE.CREF_IDENT(ident=_)) equation
      (cache,attr1,ty1,_) = lookupVarLocal(cache,env,cr);
    then (cache,attr1,ty1);
    case(cache,env,cr as DAE.CREF_QUAL(ident=_)) equation
       (cache,attr1 as DAE.ATTR(f,streamPrefix,acc,var,dir,_),ty1,_) = lookupVarLocal(cache,env,cr);
      cr1 = Exp.crefStripLastIdent(cr);
      /* Find innerOuter attribute from "parent" */
      (cache,DAE.ATTR(innerOuter=io),_,_) = lookupVarLocal(cache,env,cr1);
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

lookup_var is modified to implement 2. Is this correct?

old lookup_var is changed to lookup_var_internal and a new lookup_var
is written, that first tests the old lookup_var, and if not found
looks in the types

  function: lookupVar
 
  This function tries to finds a variable in the environment
  
  Arg1: The environment to search in
  Arg2: The variable to search for
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
  output Env.Cache outCache;
  output DAE.Attributes outAttributes;
  output DAE.Type outType;
  output DAE.Binding outBinding;
  output Option<DAE.Exp> outOptExp;
  output Env.Env outEnv"only used for package constants";
algorithm 
  (outCache,outAttributes,outType,outBinding,outEnv):=
  matchcontinue (inCache,inEnv,inComponentRef)
    local
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Binding binding;
      list<Env.Frame> env,p_env;
      DAE.ComponentRef cref;
      Env.Cache cache;
      Option<DAE.Exp> splicedExp;
    case (cache,env,cref) /* try the old lookup_var */ 
      equation 
        (cache,attr,ty,binding,splicedExp) = lookupVarInternal(cache,env, cref);
        // optional exp.exp to return
      then
        (cache,attr,ty,binding,splicedExp,{});
        
    case (cache,env,cref) /* then look in classes (implicitly instantiated packages) */ 
      equation 
        (cache,p_env,attr,ty,binding) = lookupVarInPackages(cache,env, cref);
        checkPackageVariableConstant(p_env,attr,ty,cref);
        // optional exp.exp to return
      then
        (cache,attr,ty,binding,NONE,p_env);
    case (_,env,cref) equation
      /* Debug.fprint(\"failtrace\",  \"- lookup_var failed\\n\") */  then fail(); 
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
   local Absyn.Path path;
     case (env, DAE.ATTR(parameter_= SCode.CONST()),_,cref)
       then ();
     case (env,attr,tp,cref) local String s1,s2;
       equation
       s1=Exp.printComponentRefStr(cref);
       s2 = Env.printEnvPathStr(env);
       Error.addMessage(Error.PACKAGE_VARIABLE_NOT_CONSTANT,{s1,s2});
       then fail();
   end matchcontinue;
end checkPackageVariableConstant;

public function lookupVarInternal "function: lookupVarInternal 
  Helper function to lookupVar. Searches the frames for variables."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
	output Env.Cache outCache;
  output DAE.Attributes outAttributes;
  output DAE.Type outType;
  output DAE.Binding outBinding;
  output Option<DAE.Exp> outOptExp;
algorithm 
  (outCache,outAttributes,outType,outBinding) :=
  matchcontinue (inCache,inEnv,inComponentRef)
    local
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Binding binding;
      Option<String> sid;
      Env.AvlTree ht;
      list<Env.Item> imps;
      list<Env.Frame> fs;
      Env.Frame frame;
      DAE.ComponentRef ref;
      Env.Cache cache;
      Option<DAE.Exp> splicedExp;
    case (cache,((frame as Env.FRAME(optName = sid,clsAndVars = ht,imports = imps)) :: fs),ref)
      equation 
          (cache,attr,ty,binding,splicedExp ) = lookupVarF(cache,ht, ref);
      then
        (cache,attr,ty,binding,splicedExp);
    case (cache,(_ :: fs),ref)
      equation 
        (cache,attr,ty,binding, _) = lookupVarInternal(cache,fs, ref);
      then
        (cache,attr,ty,binding,NONE);
  end matchcontinue;
end lookupVarInternal;


public function lookupVarInPackages "function: lookupVarInPackages
 
  This function is called when a lookup of a variable with qualified names
  does not have the first element as a component, e.g. A.B.C is looked up 
  where A is not a component. This implies that A is a class, and this 
  class should be temporary instantiated, and the lookup should 
  be performed within that class. I.e. the function performs lookup of 
  variables in the class hierarchy.
 
  Arg1: The environment to search in
  Arg2: The variable to search for
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output DAE.Attributes outAttributes;
  output DAE.Type outType;
  output DAE.Binding outBinding;
algorithm 
  (outCache,outEnv,outAttributes,outType,outBinding):=
  matchcontinue (inCache,inEnv,inComponentRef)
    local
      SCode.Class c;
      String n,id1,id;
      Boolean encflag;
      SCode.Restriction r;
      list<Env.Frame> env2,env3,env5,env,fs,bcframes,p_env;
      ClassInf.State ci_state;
      list<DAE.Var> types;
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Binding bind;
      DAE.ComponentRef id2,cref,cr;
      list<DAE.Subscript> sb;
      Option<String> sid;
      list<Env.Item> items;
      Env.Frame f;
      Env.Cache cache;
      // Lookup of enumeration variables
    case (cache,env,DAE.CREF_QUAL(ident = id1,subscriptLst = {},componentRef = (id2 as DAE.CREF_IDENT(ident = _))))
      equation 
        (cache,(c as SCode.CLASS(n,_,encflag,(r as SCode.R_ENUMERATION()),_)),env2) 
        	= lookupClass2(cache,env, Absyn.IDENT(id1), false) "Special case for looking up enumerations" ;
        env3 = Env.openScope(env2, encflag, SOME(n));
        ci_state = ClassInf.start(r, n);
        (cache,env5,_,_,_,_,_,types,_,_,_,_) = 
        Inst.instClassIn(
          cache,env3,InstanceHierarchy.emptyInstHierarchy,UnitAbsyn.noStore, 
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}, false, ConnectionGraph.EMPTY,NONE);
 //       (cache,env5,_,_,_,_,_,_,_,_) = 
//        Inst.instClass(cache,env3,InstanceHierarchy.emptyInstHierarchy,UnitAbsyn.noStore,DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c,{},false, Inst.TOP_CALL() ,ConnectionGraph.EMPTY);
        (cache,p_env,attr,ty,bind) = lookupVarInPackages(cache,env5, id2);
      then
        (cache,p_env,attr,ty,bind);

       // lookup of constants on form A.B in packages. First look in cache.
    case (cache,env,cr as DAE.CREF_QUAL(ident = id,subscriptLst = {},componentRef = cref)) /* First part of name is a class. */ 
      local 
        DAE.ComponentRef cr;
        Absyn.Path path,scope;
      equation 
        SOME(scope) = Env.getEnvPath(env);
        path = Exp.crefToPath(cr);
        id = Absyn.pathLastIdent(path);
        path = Absyn.stripLast(path);
        f::fs = Env.cacheGet(scope,path,cache);
        (cache,attr,ty,bind) = lookupVarLocal(cache,f::fs, DAE.CREF_IDENT(id,DAE.ET_OTHER(),{}));
        //print("found ");print(Exp.printComponentRefStr(cr));print(" in cache\n");
        then
        (cache,f::fs,attr,ty,bind);
        
    /* If we search for A1.A2....An.x while in scope A1.A2...An, just search for x. 
       Must do like this to ensure finite recursion */
    case (cache,env,cr as DAE.CREF_QUAL(ident = id,subscriptLst = {},componentRef = cref))
      local Absyn.Path ep,p,packp;
      equation 
        p = Exp.crefToPath(cr);
        SOME(ep) = Env.getEnvPath(env);
        packp = Absyn.stripLast(p);
        true = ModUtil.pathEqual(ep, packp);
        id = Absyn.pathLastIdent(p);
        (cache,p_env,attr,ty,bind) = lookupVarInPackages(cache,env, DAE.CREF_IDENT(id,DAE.ET_OTHER(),{}));
      then
        (cache,p_env,attr,ty,bind);

      // lookup of constants on form A.B in packages. instantiate package and look inside.
    case (cache,env,cr as DAE.CREF_QUAL(ident = id,subscriptLst = {},componentRef = cref)) /* First part of name is a class. */
      local Option<DAE.ComponentRef> filterCref; 
      equation 
        (cache,(c as SCode.CLASS(n,_,encflag,r,_)),env2) = lookupClass2(cache,env, Absyn.IDENT(id), false);
        env3 = Env.openScope(env2, encflag, SOME(n));
        ci_state = ClassInf.start(r, n);
        filterCref = makeOptIdentOrNone(cref);
        (cache,env5,_,_,_,_,_,types,_,_,_,_) = 
        Inst.instClassIn(
          cache,env3,InstanceHierarchy.emptyInstHierarchy,UnitAbsyn.noStore, 
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}, /*true*/false, ConnectionGraph.EMPTY, filterCref);
        (cache,p_env,attr,ty,bind) = lookupVarInPackages(cache, env5, cref);
      then
        (cache,p_env,attr,ty,bind);
        
       /* Why is this done? It is already done done in lookupVar 
          BZ: This is due to recursive call when it might become DAE.CREF_IDENT calls.
       */ 
    case (cache,env,(cr as DAE.CREF_IDENT(ident = id,subscriptLst = sb))) local String str;
      equation 
        (cache,attr,ty,bind) = lookupVarLocal(cache, env, cr);
      then
        (cache,env,attr,ty,bind);
        
        /* Search base classes */
    case (cache,Env.FRAME(inherited = (bcframes as (_ :: _)))::fs,cref)
       local
         Env.Env dbgEnv; // BZ: Added(2008-11), did not affect test suite. Added duo to correctness.
      equation 
        (cache,attr,ty,bind,_,dbgEnv) = lookupVar(cache,bcframes, cref);
      then
        (cache,dbgEnv,attr,ty,bind);

        /* Search among qualified imports, e.g. import A.B; or import D=A.B; */
    case (cache,(env as (Env.FRAME(optName = sid,imports = items) :: _)),(cr as DAE.CREF_IDENT(ident = id,subscriptLst = sb)))
      equation 
        (cache,p_env,attr,ty,bind) = lookupQualifiedImportedVarInFrame(cache,items, env, id);
      then
        (cache,p_env,attr,ty,bind);
        
        /* Search among unqualified imports, e.g. import A.B.* */
    case (cache,(env as (Env.FRAME(optName = sid,imports = items) :: _)),(cr as DAE.CREF_IDENT(ident = id,subscriptLst = sb)))
      local Boolean unique;
      equation 
        (cache,p_env,attr,ty,bind,unique) = lookupUnqualifiedImportedVarInFrame(cache,items, env, id);
        reportSeveralNamesError(unique,id);
      then
        (cache,p_env,attr,ty,bind); 
        
    case (cache,(f :: fs),cr) /* Search parent scopes */ 
      equation 
         (cache,p_env,attr,ty,bind) = lookupVarInPackages(cache,fs, cr);
      then
        (cache,p_env,attr,ty,bind);

    case (cache,env,cr) 
      /* Debug.fprint(\"failtrace\",  \"lookup_var_in_packages failed\\n exp:\" ) &
	Debug.fcall(\"failtrace\", Exp.print_component_ref, cr) &
	Debug.fprint(\"failtrace\", \"\\n\") */  then fail(); 
  end matchcontinue;
end lookupVarInPackages;

protected function makeOptIdentOrNone "
Author: BZ, 2009-04
Helper function for lookupVarInPackages
Makes an optional DAE.ComponentRef if the input DAE.ComponentRef is a DAE.CREF_IDENT otherwise
'NONE' is returned
"
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
  Arg2: The variable to search for
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
  output Env.Cache outCache;
  output DAE.Attributes outAttributes;
  output DAE.Type outType;
  output DAE.Binding outBinding;
algorithm 
  (outCache,outAttributes,outType,outBinding):=
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
      /* Lookup in frame */
    case (cache,(Env.FRAME(optName = sid,clsAndVars = ht) :: fs),cref)
      equation 
        (cache,attr,ty,binding,_) = lookupVarF(cache,ht, cref);
      then
        (cache,attr,ty,binding);
        
    case (cache,(Env.FRAME(optName = SOME("$for loop scope$")) :: env),cref)
      equation 
        (cache,attr,ty,binding) = lookupVarLocal(cache,env, cref) "Exception, when in for loop scope allow search of next scope" ;
      then
        (cache,attr,ty,binding);
  end matchcontinue;
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
  output Env.Env outEnv;
algorithm 
  (outCache,outVar,outTplSCodeElementTypesModOption,instStatus,outEnv):=
  matchcontinue (inCache,inEnv,inIdent)
    local
      DAE.Var fv;
      Option<tuple<SCode.Element, DAE.Mod>> c;
      Env.InstStatus i;
      list<Env.Frame> env,fs;
      Option<String> sid;
      Env.AvlTree ht;
      String id;
      Env.Cache cache;
    case (cache,env as (Env.FRAME(optName = sid, clsAndVars = ht) :: fs),id) /* component environment */ 
      equation 
        (cache,fv,c,i,env) = lookupVar2(cache, ht, id);
      then
        (cache,fv,c,i,env);
  end matchcontinue;
end lookupIdentLocal;

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
    local	Env.Cache cache;
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
        (cache,(c as SCode.CLASS(cn2,_,enc2,r,_)),cenv) = lookupClass2(cache,env,path,msg);
        SOME(scope) = Env.getEnvPath(cenv);
        ident = Absyn.pathLastIdent(path);
       classEnv = Env.cacheGet(scope,Absyn.IDENT(ident),cache);
      then (cache,classEnv);

      // Not found in cache, lookup and instantiate.
    case(cache,env,path,mod,msg)
      equation
        (cache,(c as SCode.CLASS(cn2,_,enc2,r,_)),cenv) = lookupClass2(cache,env, path, msg);
        cenv_2 = Env.openScope(cenv, enc2, SOME(cn2));
        new_ci_state = ClassInf.start(r, cn2);
        dmod = Mod.elabUntypedMod(mod,env,Prefix.NOPRE());
        (cache,classEnv,_,_) = 
        Inst.partialInstClassIn(
          cache,cenv_2,InstanceHierarchy.emptyInstHierarchy,
          dmod, Prefix.NOPRE(), Connect.emptySet, 
          new_ci_state, c, false, {});
      then (cache,classEnv);
    case(cache,env,path,mod,msg)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln( "- Lookup.lookupAndInstantiate failed " +&  Absyn.pathString(path) +& " with mod: " +& SCode.printModStr(mod) +& " in scope " +& Env.printEnvPathStr(env));
     then fail();
  end matchcontinue;
end lookupAndInstantiate;

public function lookupIdent "function: lookupIdent
 
  Same as lookup_ident_local, except check all frames 
 
"
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
        (cache,fv,c,i,_) = lookupVar2(cache,ht, id);
      then
        (cache,fv,c,i);
    case (cache,(_ :: rest),id)
      equation 
        (cache,fv,c,i) = lookupIdent(cache,rest, id);
      then
        (cache,fv,c,i);
  end matchcontinue;
end lookupIdent;

// Function lookup

public function lookupFunctionsInEnv 
"function: lookupFunctionsInEnv 
  Returns a list of types that the function has."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output Env.Cache outCache;
  output list<DAE.Type> outTypesTypeLst;
algorithm 
  (outCache,outTypesTypeLst) := matchcontinue (inCache,inEnv,inPath)
    local
      Absyn.Path id,iid,path;
      Option<String> sid;
      Env.AvlTree httypes;
      Env.AvlTree ht;
      list<tuple<DAE.TType, Option<Absyn.Path>>> reslist,c1,c2,res;
      list<Env.Frame> env,fs,env_1,env2,env_2;
      String pack;
      SCode.Class c;
      Boolean encflag;
      SCode.Restriction restr;
      ClassInf.State ci_state,cistate1;
      Env.Frame f;
      Env.Cache cache;
    case (cache,{},id) then (cache,{}); 
      
    /* Builtin operators are looked up in top frame directly */
    case (cache,env,(iid as Absyn.IDENT(name = id)))
      local String id;
      equation 
        _ = Static.elabBuiltinHandler(id) "Check for builtin operators" ;
        Env.FRAME(clsAndVars = ht,types = httypes) = Env.topFrame(env);
        (cache,reslist) = lookupFunctionsInFrame(cache, ht, httypes, env, id);
      then
        (cache,reslist);
        
    /* Check for special builtin operators that can not be represented in environment like for instance cardinality.*/
    case (cache,env,(iid as Absyn.IDENT(name = id)))
      local String id;
      equation 
        _ = Static.elabBuiltinHandlerGeneric(id)  ;
        reslist = createGenericBuiltinFunctions(env, id);
      then
        (cache,reslist);

    /* Simple name, search frame */
    case (cache,(env as (Env.FRAME(optName = sid,clsAndVars = ht,types = httypes) :: fs)),(iid as Absyn.IDENT(name = id)))
      local String id,s;
      equation 
        (cache,c1 as _::_)= lookupFunctionsInFrame(cache, ht, httypes, env, id);
      then
        (cache,c1);
      
    /* Simple name, if class with restriction function found in frame instantiate to get type. */
    case (cache, f::fs, (iid as Absyn.IDENT(name = id)))
      local String id,s;
      equation 
        // adrpo: do not search in the entire environment as we anyway recurse with the fs argument!
        //        just search in {f} not f::fs as otherwise we might get us in an infinite loop
        // Bjozac: Readded the f::fs search frame, otherwise we might get caught in a inifinite loop! 
        //           Did not investigate this further then that it can crasch the kernel.
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass2(cache,f::fs, iid, false);
        true = SCode.isFunctionOrExtFunction(restr);
        (cache,(env_2 as (Env.FRAME(optName = sid,clsAndVars = ht,types = httypes)::_)),_) 
           = Inst.implicitFunctionTypeInstantiation(cache,env_1,InstanceHierarchy.emptyInstHierarchy, c);
        (cache,c1 as _::_)= lookupFunctionsInFrame(cache, ht, httypes, env_2, id);
      then
        (cache,c1);

    /* For qualified function names, e.g. Modelica.Math.sin */  
    case (cache,(env as (Env.FRAME(optName = sid,clsAndVars = ht,types = httypes) :: fs)),(iid as Absyn.QUALIFIED(name = pack,path = path)))
      local String id,s;
      equation 
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass2(cache, env, Absyn.IDENT(pack), false) ;
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        
        //(cache,_,env_2,_,_,_,_,_,_) = Inst.instClassIn(cache,env2, DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet,
        //   ci_state, c, false/*FIXME:prot*/, {}, false, ConnectionGraph.EMPTY);
        (cache,env_2,_,cistate1) = 
        Inst.partialInstClassIn(
          cache, env2, InstanceHierarchy.emptyInstHierarchy,
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
        (cache,reslist) = lookupFunctionsInEnv(cache, env_2, path);
      then 
        (cache,reslist);

    /* Did not match. Search next frame. */ 
    case (cache,(f :: fs),id) 
      local list<tuple<DAE.TType, Option<Absyn.Path>>> c;
      equation 
        (cache,c) = lookupFunctionsInEnv(cache, fs, id);
      then
        (cache,c);

    case (_,_,id)
      equation 
				true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "lookupFunctionsInEnv failed on: " +& Absyn.pathString(id));
      then
        fail();
  end matchcontinue;
end lookupFunctionsInEnv;

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
      then {(DAE.T_FUNCTION({("x",(DAE.T_COMPLEX(ClassInf.CONNECTOR("$$",false),{},NONE,NONE),NONE))},
                              (DAE.T_INTEGER({}),NONE),DAE.NO_INLINE),NONE),
            (DAE.T_FUNCTION({("x",(DAE.T_COMPLEX(ClassInf.CONNECTOR("$$",true),{},NONE,NONE),NONE))},
                              (DAE.T_INTEGER({}),NONE),DAE.NO_INLINE),NONE)};
                             
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
    case (cache,(env as (Env.FRAME(optName = sid,clsAndVars = ht,types = httypes) :: fs)),Absyn.IDENT(name = id))
      equation 
        (cache,c,env_1) = lookupTypeInFrame(cache,ht, httypes, env, id);
      then
        (cache,c,env_1);
    case (cache,(f :: fs),id)
      local Absyn.Path id;
      equation 
        (cache,c,env_1) = lookupTypeInEnv(cache,fs, id);
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
    case (cache,Env.CLASS((cdef as SCode.CLASS(n,_,_,SCode.R_RECORD(),_)),_),env,id)
      equation 
        /*Each time a record constructor function is looked up, this rule will create the function. An improvement (perhaps needing lot of code) is to add the function to the environment, which is returned from this function.*/
        (cache,fpath) = Inst.makeFullyQualified(cache,env, Absyn.IDENT(n));
        (cache,varlst) = buildRecordConstructorVarlst(cache,cdef, env);
        ftype = Types.makeFunctionType(fpath, varlst, Inst.isInlineFunc2(cdef));
      then
        (cache,ftype,env);

        /* Found function */
    case (cache,Env.CLASS((cdef as SCode.CLASS(_,_,_,restr,_)),cenv),env,id)
      local SCode.Restriction restr;
      equation 
        true = SCode.isFunctionOrExtFunction(restr);
        (cache,env_1,_,_) = 
        Inst.implicitFunctionInstantiation(
          cache,cenv,InstanceHierarchy.emptyInstHierarchy,
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
      list<Env.Frame> env,cenv,env_1;
      String id,n;
      SCode.Class cdef;
      list<DAE.Var> varlst;
      Absyn.Path fpath;
      tuple<DAE.TType, Option<Absyn.Path>> ftype,t;
      DAE.TType tty;
      Env.Cache cache;

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
        Env.CLASS((cdef as SCode.CLASS(n,_,_,SCode.R_RECORD(),_)),cenv) = Env.avlTreeGet(ht, id);
        (cache,varlst) = buildRecordConstructorVarlst(cache, cdef, env);
        (cache,fpath) = Inst.makeFullyQualified(cache, cenv, Absyn.IDENT(n));
        ftype = Types.makeFunctionType(fpath, varlst, Inst.isInlineFunc2(cdef));
      then
        (cache,{ftype});
        
    /* Found class that is function, instantiate to get type*/
    case (cache,ht,httypes,env,id) local SCode.Restriction restr;
      equation 
        Env.CLASS((cdef as SCode.CLASS(_,_,_,restr,_)),cenv) = Env.avlTreeGet(ht, id);        
        true = SCode.isFunctionOrExtFunction(restr) "If found class that is function.";
        (cache,env_1,_) = 
        Inst.implicitFunctionTypeInstantiation(cache,cenv,InstanceHierarchy.emptyInstHierarchy,cdef);
        (cache,tps) = lookupFunctionsInEnv(cache,env_1, Absyn.IDENT(id));
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
	          cache,cenv,InstanceHierarchy.emptyInstHierarchy,UnitAbsyn.noStore,
	          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, cdef, 
         	  {}, false, Inst.TOP_CALL(), ConnectionGraph.EMPTY);
          (cache,t,_) = lookupTypeInEnv(cache,env_1, Absyn.IDENT(id));
           //s = Types.unparseType(t);
         	 //print("type :");print(s);print("\n");
       then
        (cache,{t});  
  end matchcontinue;
end lookupFunctionsInFrame;

protected function lookupRecconstInEnv 
"function: lookupRecconstInEnv  
  Helper function to lookup_record_constructor_class. Searches
  The environment for record constructors."
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm 
  (outClass,outEnv):=
  matchcontinue (inEnv,inPath)
    local
      SCode.Class c;
      list<Env.Frame> env,fs;
      Option<String> sid;
      Env.AvlTree ht;
      list<Env.Item> imps;
      String id;
      Env.Frame f;
    case ((env as (Env.FRAME(optName = sid,clsAndVars = ht,imports = imps) :: fs)),Absyn.IDENT(name = id))
      equation 
        (c,_) = lookupRecconstInFrame(ht, env, id);
      then
        (c,env);
    case ((f :: fs),id)
      local Absyn.Path id;
      equation 
        (c,_) = lookupRecconstInEnv(fs, id);
      then
        (c,(f :: fs));
  end matchcontinue;
end lookupRecconstInEnv;

protected function lookupRecconstInFrame 
"function: lookupRecconstInFrame 
  This function lookups the implicit record constructor class (function) 
  of a record in a frame"
  input Env.AvlTree inBinTree;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm 
  (outClass,outEnv):=
  matchcontinue (inBinTree,inEnv,inIdent)
    local
      Env.AvlTree ht;
      list<Env.Frame> env;
      String id;
      SCode.Class cdef;
    case (ht,env,id)
      equation 
        Env.VAR(_,_,_,_) = Env.avlTreeGet(ht, id);
        Error.addMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id});
      then
        fail();
    case (ht,env,id)
      equation 
        Env.CLASS((cdef as SCode.CLASS(_,_,_,SCode.R_RECORD(),_)),_) = Env.avlTreeGet(ht, id);
        cdef = buildRecordConstructorClass(cdef, env);
      then
        (cdef,env);
  end matchcontinue;
end lookupRecconstInFrame;

protected function buildRecordConstructorClass 
"function: buildRecordConstructorClass
  
  Creates the record constructor class, i.e. a function, from the record
  class given as argument."
  input SCode.Class inClass;
  input Env.Env inEnv;
  output SCode.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inClass,inEnv)
    local
      list<SCode.Element> funcelts,elts;
      SCode.Element reselt;
      SCode.Class cl;
      String id;
      SCode.Restriction restr;
      list<Env.Frame> env;
    case (cl as SCode.CLASS(name=id),env) /* record class function class */ 
      local
        list<SCode.Algorithm> initStmts;
        list<Absyn.Algorithm> initAbsynStmts;
      equation 
        (funcelts,elts) = buildRecordConstructorClass2(cl,DAE.NOMOD(),env);
        reselt = buildRecordConstructorResultElt(funcelts, id, env);
      then
        SCode.CLASS(id,false,false,SCode.R_FUNCTION(),
          SCode.PARTS((reselt :: funcelts),{},{},{},{},NONE,{},NONE));
    case (cl,env) equation
      print("buildRecordConstructorClass failed\n");
      then fail();
  end matchcontinue;
end buildRecordConstructorClass;

protected function buildRecordConstructorClass2 "help function to buildRecordConstructorClass"
  input SCode.Class cl;
  input DAE.Mod mods;
  input Env.Env env;
  output list<SCode.Element> funcelts;
  output list<SCode.Element> elts;  
algorithm
  (funcelts,elts) := matchcontinue(cl,mods,env)
    local 
      list<SCode.Element> elts,cdefelts,restElts; Env.Env env1;
    /* a class with parts */
    case(SCode.CLASS(classDef = SCode.PARTS(elementLst = elts)),mods,env)
      equation
        (cdefelts,restElts) = Inst.classdefAndImpElts(elts);
        (env1,_) = Inst.addClassdefsToEnv(env,InstanceHierarchy.emptyInstHierarchy,cdefelts,false,NONE);
        funcelts = buildRecordConstructorElts(restElts,mods,env1);
      then (funcelts,elts);
    /* adrpo: TODO! handle also the case model extends x end x; */
    case(SCode.CLASS(classDef = SCode.CLASS_EXTENDS(elementLst = elts)),mods,env)
      equation
        (cdefelts,restElts) = Inst.classdefAndImpElts(elts);
        (env1,_) = Inst.addClassdefsToEnv(env,InstanceHierarchy.emptyInstHierarchy,cdefelts,false,NONE);
        funcelts = buildRecordConstructorElts(restElts,mods,env1);
      then (funcelts,elts);
    // fail
    case(cl,mods,env) equation
      print("buildRecordConstructorClass2 failed, cl:"+&SCode.printClassStr(cl)+&"\n");
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
  input list<SCode.Element> inSCodeElementLst;
  input DAE.Mod mods;
  input Env.Env env;
  output list<SCode.Element> outSCodeElementLst;
algorithm 
  outSCodeElementLst := matchcontinue (inSCodeElementLst,mods,env)
    local
      list<SCode.Element> res,rest,res1,res2;
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
      SCode.OptBaseClass bc;
      Option<SCode.Comment> comment;
      list<Env.Frame> env_1;
      Option<Absyn.Exp> cond; 
      SCode.Class cl;
      Absyn.Path path;
      SCode.Mod mod,umod;
      DAE.Mod mod_1, compMod, fullMod, selectedMod;
      Option<Absyn.Info> nfo;
      Option<Absyn.ConstrainClass> cc;
      
    case (((comp as SCode.COMPONENT( id,io,fl,repl,prot,SCode.ATTR(d,f,st,ac,var,dir),tp,mod,bc,comment,cond,nfo,cc)) :: rest),mods,env)
      equation 
        (_,mod_1) = Mod.elabMod(Env.emptyCache(), env, Prefix.NOPRE(), mod, false);
        mod_1 = Mod.merge(mods,mod_1,env,Prefix.NOPRE());
        // adrpo: this was wrong, you won't find any id modification there!!!
        // bjozac: This was right, you will find id modification unless modifers does not belong to component!
        // adrpo 2009-11-23 -> solved by selecting the full modifier if the component modifier is empty! 
        compMod = Mod.lookupModificationP(mod_1,Absyn.IDENT(id));
        fullMod = mod_1;
        selectedMod = selectModifier(compMod, fullMod); // if the first one is empty use the other one.
        umod = Mod.unelabMod(selectedMod);
        res = buildRecordConstructorElts(rest, mods, env);
        // - Prefixes (constant, parameter, final, discrete, input, output, ...) of the remaining record components are removed.
        var = SCode.VAR();
        dir = Absyn.INPUT();
      then
        (SCode.COMPONENT(id,io,fl,repl,prot,SCode.ATTR(d,f,st,ac,SCode.VAR,Absyn.INPUT()),tp,
          umod,bc,comment,cond,nfo,cc) :: res);

    case (SCode.EXTENDS(path,mod,_) :: rest,mods,env)
      equation 
        (_,mod_1) = Mod.elabMod(Env.emptyCache(),env, Prefix.NOPRE(), mod, false);
        mod_1 = Mod.merge(mods,mod_1,env,Prefix.NOPRE());
        (_,cl,env_1) = lookupClass(Env.emptyCache(),env, path, false);
        res1 = buildRecordConstructorElts(rest,mods, env);
        (res2,_) = buildRecordConstructorClass2(cl,mod_1,env_1);
        res = listAppend(res2,res1);
      then
        res;

    case ({},_,_) then {}; 
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
          SCode.NOMOD,
          NONE,NONE,NONE,NONE,NONE);
end buildRecordConstructorResultElt;

protected function buildRecordConstructorVarlst 
"function: buildRecordConstructorVarlst 
  This function takes a class  (`SCode.Class\') which holds a definition 
  of a record and builds a list of variables of the record used for 
  constructing a record constructor function."
	input Env.Cache inCache;
  input SCode.Class inClass;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output list<DAE.Var> outTypesVarLst;
algorithm 
  (outCache,outTypesVarLst) := matchcontinue (inCache,inClass,inEnv)
    local
      list<DAE.Var> inputvarlst;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      SCode.Class cl;
      list<SCode.Element> elts,cdefelts,restElts;
      list<Env.Frame> env,env1;
      Env.Cache cache;

    case (cache,(cl as SCode.CLASS(classDef = SCode.PARTS(elementLst = elts))),env)
      equation 
        (cdefelts,restElts) = Inst.classdefAndImpElts(elts);
        (env1,_) = Inst.addClassdefsToEnv(env,InstanceHierarchy.emptyInstHierarchy,cdefelts,false,NONE);
        (cache,inputvarlst) = buildVarlstFromElts(cache,restElts, DAE.NOMOD(),env1);        
        (cache,_,_,_,_,_,ty,_,_,_) = 
        Inst.instClass(
          cache,env1,InstanceHierarchy.emptyInstHierarchy,UnitAbsyn.noStore,
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, cl, 
          {}, true, Inst.TOP_CALL(), ConnectionGraph.EMPTY) "FIXME: impl" ;
      then
        (cache,DAE.TYPES_VAR("result",
          DAE.ATTR(false,false,SCode.RW(),SCode.VAR(),Absyn.OUTPUT(),Absyn.UNSPECIFIED()),false,ty,DAE.UNBOUND()) :: inputvarlst);

     /* adrpo: TODO! handle also the case model extends x end x; */          
    case (cache,(cl as SCode.CLASS(classDef = SCode.CLASS_EXTENDS(elementLst = elts))),env)
      equation 
        (cdefelts,restElts) = Inst.classdefAndImpElts(elts);
        (env1,_) = Inst.addClassdefsToEnv(env,InstanceHierarchy.emptyInstHierarchy,cdefelts,false,NONE);
        (cache,inputvarlst) = buildVarlstFromElts(cache,restElts, DAE.NOMOD(),env1);        
        (cache,_,_,_,_,_,ty,_,_,_) = 
        Inst.instClass(
          cache,env1,InstanceHierarchy.emptyInstHierarchy,UnitAbsyn.noStore,
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, cl, 
          {}, true, Inst.TOP_CALL(), ConnectionGraph.EMPTY) "FIXME: impl" ;
      then
        (cache,DAE.TYPES_VAR("result",
          DAE.ATTR(false,false,SCode.RW(),SCode.VAR(),Absyn.OUTPUT(),Absyn.UNSPECIFIED()),false,ty,DAE.UNBOUND()) :: inputvarlst);
          
    case (_,cl,_)
      local
        String str;
      equation
				true = RTOpts.debugFlag("failtrace");
        str = SCode.printClassStr(cl); 
        Debug.fprintln("failtrace", "- Lookup.buildRecordConstructorVarlst failed on:\n" +& str +& "\n");
      then
        fail();
  end matchcontinue;
end buildRecordConstructorVarlst;

protected function buildVarlstFromElts 
"function: buildVarlstFromElts  
  Helper function to buildRecordConstructorVarlst"
	input Env.Cache inCache;
  input list<SCode.Element> inSCodeElementLst;
  input DAE.Mod mods;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output list<DAE.Var> outTypesVarLst;
algorithm 
  (outCache,outTypesVarLst) :=
  matchcontinue (inCache,inSCodeElementLst,mods,inEnv)
    local
      list<DAE.Var> vars,vars1,vars2;
      DAE.Var var;
      SCode.Element comp;
      list<SCode.Element> rest;
      list<Env.Frame> env,env_1;
      Env.Cache cache;
      SCode.Class cl;
      SCode.Mod mod;
      Absyn.Path path;
      String n;
      DAE.Mod compMod,mod2;
    case (cache,((comp as SCode.COMPONENT(component = n)) :: rest),mods,env)
      equation 
        (cache,vars) = buildVarlstFromElts(cache,rest, mods,env);
        compMod = Mod.lookupModificationP(mods,Absyn.IDENT(n));
        (cache,_,var) = 
        Inst.instRecordConstructorElt(cache,env,InstanceHierarchy.emptyInstHierarchy, comp,compMod, true) 
        "P.A Here we need to do a lookup of the type. 
         Therefore we need the env passed along from 
         lookup_xxxx function. FIXME: impl" ;
      then
        (cache,var :: vars);

    case (cache,((SCode.EXTENDS(path,mod,_)) :: rest),mods,env)
      equation 
        (_,cl,env_1) = lookupClass(cache,env, path, true);
        (cache,mod2) = Mod.elabMod(cache,env_1, Prefix.NOPRE(), mod, false);
        mod2 = Mod.merge(mods,mod2,env_1,Prefix.NOPRE());                  
       (cache,vars1) = buildVarlstFromElts2(cache,env_1,cl,mod2);
        (cache,vars2) = buildVarlstFromElts(cache,rest, mods,env);
        vars = listAppend(vars1,vars2);
      then
        (cache,vars);        
    case (cache,{},_,_) then (cache,{}); 
    case (_,rest,_,_) equation 
			true = RTOpts.debugFlag("failtrace");
      Debug.fprintln("failtrace", "- Lookup.buildVarlstFromElts failed on elts: " +& Util.stringDelimitList(Util.listMap(rest,SCode.printElementStr),"\n"));            
    then fail(); 
  end matchcontinue;
end buildVarlstFromElts;

protected function buildVarlstFromElts2 
"Help function to buildVarlstFromElts"
  input Env.Cache cache;
  input Env.Env env;
  input SCode.Class cl;
  input DAE.Mod mods;
  output Env.Cache outCache;
  output list<DAE.Var> vLst;
algorithm
  (outCache,vLst) := matchcontinue(cache,env,cl,mods)
  local list<SCode.Element> elts,cdefelts,restElts;
    Env.Env env1;
    case(cache,env,SCode.CLASS(classDef = SCode.PARTS(elementLst = elts)),mods)
      equation
        (cdefelts,restElts) = Inst.classdefAndImpElts(elts);
        (env1,_) = Inst.addClassdefsToEnv(env, InstanceHierarchy.emptyInstHierarchy, cdefelts, false, NONE);        
        (outCache,vLst) = buildVarlstFromElts(cache,restElts,mods,env1);
      then (outCache,vLst);
    /* adrpo: TODO! handle also model extends x end x; */
    case(cache,env,SCode.CLASS(classDef = SCode.CLASS_EXTENDS(elementLst = elts)),mods)
      equation
        (cdefelts,restElts) = Inst.classdefAndImpElts(elts);
        (env1,_) = Inst.addClassdefsToEnv(env, InstanceHierarchy.emptyInstHierarchy, cdefelts, false, NONE);        
        (outCache,vLst) = buildVarlstFromElts(cache,restElts,mods,env1);
      then (outCache,vLst);        
    case(_,_,cl,mods) equation
			true = RTOpts.debugFlag("failtrace");
      Debug.fprint("failtrace", "- buildVarlstFromElts2 failed!\n class:"+&SCode.printClassStr(cl));
    then fail();
  end matchcontinue;
end buildVarlstFromElts2;

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
        (cache,{}) = lookupFunctionsInEnv(cache,i_env, path);
      then
        (cache,false);
    case (cache,path)
      equation 
        (cache,i_env) = Builtin.initialEnv(cache);
        (cache,_) = lookupFunctionsInEnv(cache,i_env, path);
      then
        (cache,true);
    case (cache,path)
      equation 
        Debug.fprintln("failtrace", "is_in_builtin_env failed");
      then
        fail();
  end matchcontinue;
end isInBuiltinEnv;

protected function lookupClassInEnv "function: lookupClassInEnv
  
  Helper function to lookup_class. Searches the environment for the class.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm 
  (outCache,outClass,outEnv):=
  matchcontinue (inCache,inEnv,inPath,inBoolean)
    local
      SCode.Class c;
      list<Env.Frame> env_1,env,fs,i_env;
      Env.Frame frame,f;
      String id,sid,scope;
      Boolean msg,msgflag;
      Absyn.Path aid,path;
      Env.Cache cache;
            
    case (cache,(env as (frame :: fs)),Absyn.IDENT(name = id),msg) /* msg */ 
      equation 
        (cache,c,env_1) = lookupClassInFrame(cache,frame, (frame :: fs), id, msg);
      then
        (cache,c,env_1);
    case (cache,(env as (Env.FRAME(optName = SOME(sid),isEncapsulated = true) :: fs)),(aid as Absyn.IDENT(name = id)),_)
      equation 
        equality(id = sid) "Special case if looking up the class that -is- encapsulated. That must be allowed." ;
        (cache,c,env) = lookupClassInEnv(cache,fs, aid, true);
      then
        (cache,c,env);
        
        /* lookup stops at encapsulated classes except for builtin
	    scope, if not found in builtin scope, error */ 
    case (cache,(env as (Env.FRAME(optName = SOME(sid),isEncapsulated = true) :: fs)),(aid as Absyn.IDENT(name = id)),true) 
      equation 
        (cache,i_env) = Builtin.initialEnv(cache);
        failure((_,_,_) = lookupClassInEnv(cache,i_env, aid, false));
        scope = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_ERROR, {id,scope});
      then
        fail();
   
    case (cache,(Env.FRAME(optName = sid,isEncapsulated = true) :: fs),(aid as Absyn.IDENT(name = id)),msgflag) /* lookup stops at encapsulated classes, except for builtin scope */ 
      local Option<String> sid;
      equation 
        (cache,i_env) = Builtin.initialEnv(cache);
        (cache,c,env_1) = lookupClassInEnv(cache,i_env, aid, msgflag);
      then
        (cache,c,env_1);
    /*case (cache,((f as Env.FRAME(optName = sid,isEncapsulated = false)) :: fs),id,msgflag)  
      local
        Option<String> sid;
        Absyn.Path id;
      equation 
        "thermoRoot_der" =Absyn.pathString(id);
        ("Utilities"::_) = Env.getScopeNames(fs);
        print(" looking for: " +& Absyn.pathString(id) +& " in scope " +& Util.stringDelimitList(Env.getScopeNames(fs),", ") +& "\n");
        print("***************\n\n\n env:\n"+& Env.printEnvStr(fs) +& "\n\n**************"); 
        (cache,c,env_1) = lookupClassInEnv(cache,fs, id, msgflag);
      then
        (cache,c,env_1);
        */
    case (cache,((f as Env.FRAME(optName = sid,isEncapsulated = false)) :: fs),id,msgflag) /* if not found and not encapsulated, look in next enclosing scope */ 
      local
        Option<String> sid;
        Absyn.Path id;
      equation 
        (cache,c,env_1) = lookupClassInEnv(cache,fs, id, msgflag);
      then
        (cache,c,env_1);
  end matchcontinue;
end lookupClassInEnv;

protected function lookupClassInFrame "function: lookupClassInFrame
  
  Search for a class within one frame. 
"
  input Env.Cache inCache;
  input Env.Frame inFrame;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm 
  (outCache,outClass,outEnv):=
  matchcontinue (inCache,inFrame,inEnv,inIdent,inBoolean)
    local
      SCode.Class c;
      list<Env.Frame> env,totenv,bcframes,env_1;
      Option<String> sid;
      Env.AvlTree ht;
      String id,name;
      list<Env.Item> items;
      Env.Cache cache;
      Env.Item item;

      /* Check this scope for class */
    case (cache,Env.FRAME(optName = sid,clsAndVars = ht),totenv,id,_)
      equation 
        Env.CLASS(c,_) = Env.avlTreeGet(ht, id);               
      then
        (cache,c,totenv);            
        
        /* Search base classes */ 
    case (cache,Env.FRAME(inherited = (bcframes as (_ :: _))),totenv,name,_) 
      equation         
        (cache,c,env) = lookupClass2(cache,bcframes, Absyn.IDENT(name), false);
      then
        (cache,c,env);
        
        /* Search among the qualified imports, e.g. import A.B; or import D=A.B; */
    case (cache,Env.FRAME(optName = sid,imports = items),totenv,name,_)
      equation 
        (cache,c,env_1) = lookupQualifiedImportedClassInFrame(cache,items, totenv, name);
      then
        (cache,c,env_1);
        
        /* Search among the unqualified imports, e.g. import A.B.*; */
    case (cache,Env.FRAME(optName = sid,imports = items),totenv,name,_)
      local Boolean unique;
      equation 
        (cache,c,env_1,unique) = lookupUnqualifiedImportedClassInFrame(cache,items, totenv, name) "unique" ;
        reportSeveralNamesError(unique,name);
      then
        (cache,c,env_1);
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
      String id;
      Env.Cache cache;
    case (cache,ht,id)
      equation 
        Env.VAR(fv,c,i,env) = Env.avlTreeGet(ht, id);
      then
        (cache,fv,c,i,env);
  end matchcontinue;
end lookupVar2;

protected function checkSubscripts "function: checkSubscripts
 
  This function checks a list of subscripts agains type, and removes
  dimensions from the type according to the subscripting.
"
  input DAE.Type inType;
  input list<DAE.Subscript> inExpSubscriptLst;
  output DAE.Type outType;
algorithm 
  outType:=
  matchcontinue (inType,inExpSubscriptLst)
    local
      tuple<DAE.TType, Option<Absyn.Path>> t,t_1;
      DAE.ArrayDim dim;
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
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM(integerOption = SOME(sz)),arrayType = t),p),(DAE.SLICE(exp = DAE.ARRAY(array = se)) :: ys))
      local Integer dim;
      equation 
        t_1 = checkSubscripts(t, ys);
        dim = listLength(se) "FIXME: Check range IMPLEMENTED 2007-05-18 BZ" ; 
        true = (dim <= sz);
        true = checkSubscriptsRange(se,sz);        
      then
        ((DAE.T_ARRAY(DAE.DIM(SOME(dim)),t_1),p));
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM(integerOption = SOME(sz)),arrayType = t),_),(DAE.INDEX(exp = DAE.ICONST(integer = ind)) :: ys))
      equation 
        (ind > 0) = true;
        (ind <= sz) = true;
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM(integerOption = SOME(sz)),arrayType = t),_),(DAE.INDEX(exp = e) :: ys)) /* HJ: Subscrits needn\'t be constant. No range-checking can
	       be done */ 
	       local DAE.Exp e;
      equation 
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM(integerOption = NONE),arrayType = t),_),(DAE.INDEX(exp = _) :: ys))
      equation 
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM(integerOption = SOME(sz)),arrayType = t),_),(DAE.WHOLEDIM() :: ys))
      equation 
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM(integerOption = NONE),arrayType = t),_),(DAE.WHOLEDIM() :: ys))
      equation 
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
        
        // If slicing with integer array of VAR variability, i.e. index changing during runtime. 
        // => resulting ARRAY type has no specified dimension size.
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM(integerOption = SOME(sz)),arrayType = t),p),(DAE.SLICE(exp = e) :: ys))
      local DAE.Exp e;
      equation 
        sz = 5;
        false = Exp.isArray(e); 
        // we check so that e is not an array, if so the range check is useless in the function above.
        
        t_1 = checkSubscripts(t, ys);
      then
       ((DAE.T_ARRAY(DAE.DIM(NONE),t_1),p));
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM(integerOption = NONE),arrayType = t),p),(DAE.SLICE(exp = _) :: ys))
      equation 
        t_1 = checkSubscripts(t, ys);
      then
        ((DAE.T_ARRAY(DAE.DIM(NONE),t_1),p));
        
    case ((DAE.T_COMPLEX(_,_,SOME(t),_),_),ys)
      then checkSubscripts(t,ys); 
    case(t as (DAE.T_NOTYPE(),_),_) then t;
    case (t,s)
      equation 
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "- check_subscripts failed (tp: ");
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
  output Option<DAE.Exp> outOptExp;
algorithm 
  (outCache,outAttributes,outType,outBinding, outOptExp):=
  matchcontinue (inCache,inBinTree,inComponentRef)
    local
      String n,id;
      Boolean f,streamPrefix;
      SCode.Accessibility acc;
      SCode.Variability vt;
      Absyn.Direction di;
      tuple<DAE.TType, Option<Absyn.Path>> ty,ty_1;
      DAE.Binding bind,binding,binding2;
      Env.AvlTree ht;
      list<DAE.Subscript> ss;
      list<Env.Frame> compenv;
      DAE.Attributes attr;
      DAE.ComponentRef ids;
      Env.Cache cache;
      DAE.ExpType ty2_2;
      Absyn.InnerOuter io;
      Option<DAE.Exp> texp;
      DAE.ArrayDim dim;
      DAE.Type t,ty1,ty2;
      Option<Absyn.Path> p;
      DAE.ComponentRef xCref,tCref;
      list<DAE.ComponentRef> ltCref;
      DAE.Exp splicedExp;
      DAE.ExpType eType;

    // Simple identifier
    case (cache,ht,ids as DAE.CREF_IDENT(ident = id,subscriptLst = ss) ) 
      local
        DAE.Exp splicedExp;
        DAE.ExpType tty;
        Absyn.InnerOuter io;        
      equation 
        (cache,DAE.TYPES_VAR(n,DAE.ATTR(f,streamPrefix,acc,vt,di,io),_,ty,bind),_,_,_) = lookupVar2(cache,ht, id);
        ty_1 = checkSubscripts(ty, ss);
        ss = addArrayDimensions(ty,ty_1,ss);
        tty = Types.elabType(ty_1);     
        ty2_2 = Types.elabType(ty);
        splicedExp = DAE.CREF(DAE.CREF_IDENT(id,ty2_2, ss),tty);
      then
        (cache,DAE.ATTR(f,streamPrefix,acc,vt,di,io),ty_1,bind,SOME(splicedExp));
    
    // Qualified variables looked up through component environment with a spliced exp
    case (cache,ht,xCref as (DAE.CREF_QUAL(ident = id,subscriptLst = ss,componentRef = ids)))  
      local        
      equation 
        (cache,DAE.TYPES_VAR(n,DAE.ATTR(f,streamPrefix,acc,vt,di,io),_,ty2,bind),_,_,compenv) = lookupVar2(cache,ht, id);
        (cache,attr,ty,binding,texp,_) = lookupVar(cache,compenv, ids);
        (tCref::ltCref) = elabComponentRecursive((texp)); 
        ty1 = checkSubscripts(ty2, ss);
        ty = sliceDimensionType(ty1,ty);
        ss = addArrayDimensions(ty2,ty2,ss);
        ty2_2 = Types.elabType(ty2);
        xCref = DAE.CREF_QUAL(id,ty2_2,ss,tCref);
        eType = Types.elabType(ty);
        splicedExp = DAE.CREF(xCref,eType);
      then
        (cache,attr,ty,binding,SOME(splicedExp));
        
    // Qualified componentname without spliced exp.
    case (cache,ht,xCref as (DAE.CREF_QUAL(ident = id,subscriptLst = ss,componentRef = ids)))      
      equation 
        (cache,DAE.TYPES_VAR(n,DAE.ATTR(f,streamPrefix,acc,vt,di,io),_,ty2,bind),_,_,compenv) = lookupVar2(cache,ht, id);
        (cache,attr,ty,binding,texp,_) = lookupVar(cache,compenv, ids);
        {} = elabComponentRecursive((texp));
      then
        (cache,attr,ty,binding,NONE());
  end matchcontinue;
end lookupVarF;

protected function elabComponentRecursive "
Helper function for lookupvarF, to return an ComponentRef if there is one. 
"
  input Option<DAE.Exp> oCref;
  output list<DAE.ComponentRef> lref;
  
algorithm
  lref :=
  matchcontinue(oCref)
    local Option<DAE.Exp> exp;DAE.ComponentRef ecpr;
    case( exp as SOME(DAE.CREF(ecpr as DAE.CREF_IDENT(_,_,_),_ )))
      then
        (ecpr::{});
    case( exp as SOME(DAE.CREF(ecpr as DAE.CREF_QUAL(_,_,_,_),_ )))
      then
        (ecpr::{});
    case(_) then {};
  end matchcontinue;
end elabComponentRecursive;

protected function addArrayDimensions " function addArrayDimensions
This is the function where we add arrays representing the dimension of the type.
In type {array 2[array 3 ]] Will generate 2 arrays. {1,2} and {1,2,3}
"
  input DAE.Type tySub;
  input DAE.Type tyExpr;
  input list<DAE.Subscript> ss;
  output list<DAE.Subscript> outType;
  
algorithm 
  outType := 
  matchcontinue (tySub, tyExpr,ss)
    local 
      DAE.Type ty1,ty2,ty3;
      list<DAE.Subscript> subs1,subs2,subs3;
      list<Integer> dim1,dim2;
      Integer sslLength,expandLength;
    case( ty2, ty3, subs1) // add ss
      equation
        true = Types.isArray(ty2);
        dim2 = Types.getDimensionSizes(ty2);
        sslLength = listLength(ss);
        subs2 = makeExpIntegerArray(dim2);
        subs2 = expandWholeDimSubScript(subs1,subs2);
      then subs2;
    case(_,_,subs1) // non array, return
      equation
      then (subs1);  
  end matchcontinue;
end addArrayDimensions;

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



protected function makeExpIntegerArray " function makeExpIntegerArray
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
        tmpArray = DAE.ARRAY(DAE.ET_INT(), false, exps);
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
        list<Option <Integer>> dim2;
        DAE.TType tty;
        String str;
      equation
        dimensions = Types.getDimensionSizes(t);
        dim2 = Util.listMap(dimensions, Util.makeOption);
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

