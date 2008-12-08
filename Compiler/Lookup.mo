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

public import ClassInf;
public import Types;
public import Absyn;
public import Exp;
public import Env;
public import SCode;

protected import Debug;
protected import Inst;
protected import Mod;
protected import Prefix;
protected import Builtin;
protected import ModUtil;
protected import Static;
protected import Connect;
protected import Error;
protected import System;
protected import Util;

/*
 * - Lookup functions
 *   These functions look up class and variable names in the environment.
 *   The names are supplied as a path, and if the path is qualified, a
 *   variable named as the first part of the path is searched for, and 
 *   the name is looked for in it.
 */

public function lookupType 
"function lookupType
  This function finds a specified type in the environment.
  If it finds a function instead, this will be implicitly instantiated
  and lookup will start over.

  Arg1: Env.Env is the environment which to perform the lookup in
  Arg2: Absyn.Path is the type to look for"
  input Env.Cache inCache;
  input Env.Env inEnv "environment to search in";
  input Absyn.Path inPath "type to look for";
  input Boolean inBoolean "Messaage flag, true outputs lookup error messages";
  output Env.Cache outCache;
  output Types.Type outType "the found type";
  output Env.Env outEnv "The environment the type was found in";
algorithm
  (outCache,outType,outEnv) := matchcontinue (inCache,inEnv,inPath,inBoolean)
    local
      tuple<Types.TType, Option<Absyn.Path>> t,c_1;
      list<Env.Frame> env_1,env,env_2,env3,env2,env_3;
      Absyn.Path path,p;
      Boolean msg,encflag;
      SCode.Class c;
      String id,pack,classname,scope;
      SCode.Restriction restr;
      ClassInf.State ci_state,cistate1;
      Env.Cache cache;

    /*For simple names */
    case (cache,env,(path as Absyn.IDENT(name = _)),msg/* message flag*/)
      equation
        (cache,t,env_1) = lookupTypeInEnv(cache,env, path);
      then
        (cache,t,env_1);

    /* Classes that are external objects. Implicityly instantiate to get type */
    case (cache,env,path ,msg) local String ident,s;
      equation
        (cache,c ,env_1) = lookupClass2(cache,env, path, false);
        true = Inst.classIsExternalObject(c);
        (cache,_,_::env_1,_,_,_) = Inst.instClass(cache,env_1, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c,
          {}, false, Inst.TOP_CALL());
        ident = Absyn.pathLastIdent(path); /* Once class has instantiated we only need to look up the last
        	part of the name as a type */
        (cache,t,env_2) = lookupTypeInEnv(cache,env_1, Absyn.IDENT(ident));
      then
        (cache,t,env_2);

    /* If we find a class definition that is a function or external function with 
     * the same name then we implicitly instantiate that function, look up the type. 
     */
    case (cache,env,path,msg)
      local String s,ident;
      SCode.Restriction restr;
      equation
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass2(cache,env, path, false);
        true = SCode.isFunctionOrExtFunction(restr);
        (cache,env_2) = Inst.implicitFunctionTypeInstantiation(cache,env_1, c);
        ident = Absyn.pathLastIdent(path);
        (cache,t,env3) = lookupTypeInEnv(cache,env_2, Absyn.IDENT(ident));
      then
        (cache,t,env3);

   	/* Error for type not found */
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

protected function isPrimitive 
"function: isPrimitive
  author: PA
  Returns true if classname is any of the builtin classes:
  Real, Integer, String, Boolean"
  input Absyn.Path inPath;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inPath)
    case (Absyn.IDENT(name = "Integer")) then true;
    case (Absyn.IDENT(name = "Real")) then true;
    case (Absyn.IDENT(name = "Boolean")) then true;
    case (Absyn.IDENT(name = "String")) then true;
    case (_) then false;
  end matchcontinue;
end isPrimitive;

public function lookupClass 
"Tries to find a specified class in an environment
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
  //t1:= clock();
  (outCache,outClass,outEnv) := lookupClass2(inCache,inEnv, inPath, inBoolean);
  /*t2 := clock();
  time := t2 -. t1;
  b:=realGt(time,0.05);
  s := realString(time);
  s2 := Absyn.pathString(inPath);
  s:=Util.stringAppendList({"lookupClass ",s2," ",s," s\n"});
  //print(Util.if_(b,s,""));*/
end lookupClass;

public function lookupClass2 
"function lookupClass2
  Help function to lookupClass, does all the work."
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
        //print("HIT:");print(Absyn.pathString(path));print(" scope"); print(Absyn.pathString(scope));print("\n");
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
        SOME(scope) = Env.getEnvPath(env);
        env_1 = Env.cacheGet(scope,Absyn.IDENT(pack),cache);
        (cache,c_1,env_2) = lookupClass2(cache,env_1,path,msgflag);
        //print("Qualified cache hit on ");print(Absyn.pathString(p));print("\n");
      then
        (cache,c_1,env_2);

    /* Builtin classes Integer, Real, String, Boolean 
     * can not be overridden search top environment directly. 
     */
    case (cache,env,(path as Absyn.IDENT(name = id)),msg)
      equation
        true = isPrimitive(path);
        f = Env.topFrame(env);
        (cache,c,env) = lookupClassInFrame(cache,f, {f}, id, msg);
      then
        (cache,c,env);

    // Simple names
    case (cache,env,(path as Absyn.IDENT(name = name)),msgflag)
      equation
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClassInEnv(cache,env, path, msgflag);
      then
        (cache,c,env_1);

    // Qualified names
    /* If we search for A1.A2....An.x while in scope A1.A2...An,
     * just search for x. Must do like this to ensure finite recursion 
     */
    case (cache,env,(p as Absyn.QUALIFIED(name = _)),msgflag)
      equation
        SOME(ep) = Env.getEnvPath(env)  ;
        packp = Absyn.stripLast(p);
        true = ModUtil.pathEqual(ep, packp);
        id = Absyn.pathLastIdent(p);
        (cache,c,env_1) = lookupClass2(cache,env, Absyn.IDENT(id), msgflag);
      then
        (cache,c,env_1);

    // Qualified names in package
    case (cache,env,(p as Absyn.QUALIFIED(name = pack,path = path)),msgflag)
      equation
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env1) = lookupClass2(cache,env, Absyn.IDENT(pack), msgflag);
        env2 = Env.openScope(env1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);        
        (cache,env4,cistate1) = Inst.partialInstClassIn(cache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, ci_state, c, false, {});
        ClassInf.valid(cistate1, SCode.R_PACKAGE());
        (cache,c_1,env5) = lookupClass2(cache,env4, path, msgflag) "Has NOT to do additional check for encapsulated classes, see rule above" ;
      then
        (cache,c_1,env5);

    // Qualified names in non package
    case (cache,env,(p as Absyn.QUALIFIED(name = pack,path = path)),msgflag)
      equation
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass2(cache,env, Absyn.IDENT(pack), msgflag);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        (cache,env_2,cistate1) = Inst.partialInstClassIn(cache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, ci_state, c, false, {});
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


protected function lookupQualifiedImportedVarInFrame 
"function: lookupQualifiedImportedVarInFrame
  author: PA
  Looking up variables (constants) imported using 
  qualified imports, i.e. import Modelica.Constants.PI;"
	input Env.Cache inCache;
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
algorithm
  (outCache,outEnv,outAttributes,outType,outBinding) := matchcontinue (inCache,inEnvItemLst,inEnv,inIdent)
    local
      Env.Frame fr;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Binding bind;
      String id,ident,str;
      list<Env.Item> fs;
      list<Env.Frame> env,p_env;
      Exp.ComponentRef cref;
      Absyn.Path strippath,path;
      SCode.Class c2;
      Env.Cache cache;

    /* For imported simple name, e.g. A, not possible to assert sub-path package */
    case (cache,(Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = Absyn.IDENT(name = id))) :: fs),env,ident)
      equation
        equality(id = ident);
        fr = Env.topFrame(env);
        (cache,attr,ty,bind) = lookupVar(cache,{fr}, Exp.CREF_IDENT(ident,{}));
      then
        (cache,{fr},attr,ty,bind);

    /* For imported qualified name, e.g. A.B.C, assert A.B is package */
    case (cache,(Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = path)) :: fs),env,ident)
      equation
        id = Absyn.pathLastIdent(path);
        equality(id = ident);
        fr = Env.topFrame(env);
        cref = Exp.pathToCref(path);
        (cache,p_env,attr,ty,bind) = lookupVarInPackages(cache,{fr}, cref);
        strippath = Absyn.stripLast(path);
        (cache,c2,_) = lookupClass2(cache,{fr}, strippath, true);
        assertPackage(c2);
      then
        (cache,p_env,attr,ty,bind);

    /* importing qualified name, If not package, error */
    case (cache,(Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = path)) :: fs),env,ident)
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
        fail();

    /* Named imports, e.g. import A = B.C; */
    case (cache,(Env.IMPORT(import_ = Absyn.NAMED_IMPORT(name = id,path = path)) :: fs),env,ident)
      equation
        equality(id = ident);
        fr = Env.topFrame(env);
        cref = Exp.pathToCref(path);
        (cache,p_env,attr,ty,bind) = lookupVarInPackages(cache,{fr}, cref);
        strippath = Absyn.stripLast(path);
        (cache,c2,_) = lookupClass2(cache,{fr}, strippath, true);
        assertPackage(c2);
      then
        (cache,p_env,attr,ty,bind);

    /* Error message if named import is not package. */
    case (cache,(Env.IMPORT(import_ = Absyn.NAMED_IMPORT(name = id,path = path)) :: fs),env,ident)
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
        fail();

    /* Check next frame. */
    case (cache,(_ :: fs),env,ident)
      equation
        (cache,p_env,attr,ty,bind) = lookupQualifiedImportedVarInFrame(cache,fs, env, ident);
      then
        (cache,p_env,attr,ty,bind);
  end matchcontinue;
end lookupQualifiedImportedVarInFrame;

protected function moreLookupUnqualifiedImportedVarInFrame 
"function: moreLookupUnqualifiedImportedVarInFrame
  Helper function for lookupUnqualifiedImportedVarInFrame. 
  Returns true if there are unqualified imports that matches a sought constant."
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
      list<Env.Item> fs;
      Env.Cache cache;
      Exp.ComponentRef cr;
      Absyn.Path path,scope;
      Absyn.Ident firstIdent;
    
    /* see the first import */
    case (cache,(Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident)
      equation
        firstIdent = Absyn.pathFirstIdent(path);
        f::_ = Env.cacheGet(Absyn.IDENT(firstIdent),path,cache);
        (cache,_,_,_,_) = lookupVarInPackages(cache,{f}, Exp.CREF_IDENT(ident,{}));
      then
        (cache,true);

    // if not found in cache , try to instantiate
    case (cache,(Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident)
      equation
        fr = Env.topFrame(env);
        (cache,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass2(cache,{fr}, path, false);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
         (cache,(f :: _),_) = Inst.partialInstClassIn(cache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet,
          ci_state, c, false, {});
        (cache,_,_,_,_) = lookupVarInPackages(cache,{f}, Exp.CREF_IDENT(ident,{}));
      then
        (cache,true);
    
    /* move to next */
    case (cache,(_ :: fs),env,ident)
      equation
        (cache,res) = moreLookupUnqualifiedImportedVarInFrame(cache,fs, env, ident);
      then
        (cache,res);
    /* no more imports, return false */
    case (cache,{},_,_) then (cache,false);
  end matchcontinue;
end moreLookupUnqualifiedImportedVarInFrame;

protected function lookupUnqualifiedImportedVarInFrame 
"function: lookupUnqualifiedImportedVarInFrame
  Find a variable from an unqualified import locally in a frame"
	input Env.Cache inCache;
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
  output Boolean outBoolean;
algorithm
  (outCache,outEnv,outAttributes,outType,outBinding,outBoolean) := matchcontinue (inCache,inEnvItemLst,inEnv,inIdent)
    local
      Env.Frame fr,f;
      Exp.ComponentRef cref;
      SCode.Class c;
      String id,ident;
      Boolean encflag,more,unique;
      SCode.Restriction restr;
      list<Env.Frame> env_1,env2,env,p_env;
      ClassInf.State ci_state;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Binding bind;
      Absyn.Path path;
      list<Env.Item> fs;
      Env.Cache cache;
      Exp.ComponentRef cr;
      Absyn.Path path,scope;
      Absyn.Ident firstIdent;
      
    // First look in cache
    case (cache,(Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident) /* unique */
      equation
        //print("look in cache\n");
        firstIdent = Absyn.pathFirstIdent(path);
        f::_ = Env.cacheGet(Absyn.IDENT(firstIdent),path,cache);
        (cache,p_env,attr,ty,bind) = lookupVarInPackages(cache,{f}, Exp.CREF_IDENT(ident,{}));
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
        (cache,_,(f :: _),_,_,_,_) = Inst.instClassIn(cache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, ci_state, c, false, {}, false);
        (cache,p_env,attr,ty,bind) = lookupVarInPackages(cache,{f}, Exp.CREF_IDENT(ident,{}));
        (cache,more) = moreLookupUnqualifiedImportedVarInFrame(cache,fs, env, ident);
        unique = boolNot(more);
      then
        (cache,p_env,attr,ty,bind,unique);
    /* move to next */
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
  (outCache,outClass,outEnv) := matchcontinue (inCache,inEnvItemLst,inEnv,inIdent)
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
        assertPackage(c2);
      then
        (cache,c,env_1);

    case (cache,(Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = path)) :: fs),env,ident)
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
        fail();

    case (cache,(Env.IMPORT(import_ = Absyn.NAMED_IMPORT(name = id,path = path)) :: fs),env,ident)
      equation
        equality(id = ident) "Named imports" ;
        fr = Env.topFrame(env);
        (cache,c,env_1) = lookupClass2(cache,{fr}, path, true);
        strippath = Absyn.stripLast(path);
        (cache,c2,_) = lookupClass2(cache,{fr}, strippath, true);
        assertPackage(c2);
      then
        (cache,c,env_1);

    /* Error message if named import is not package */
    case (cache,(Env.IMPORT(import_ = Absyn.NAMED_IMPORT(name = id,path = path)) :: fs),env,ident)
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
        fail();

    case (cache,(_ :: fs),env,ident)
      equation
        (cache,c,env_1) = lookupQualifiedImportedClassInFrame(cache,fs, env, ident);
      then
        (cache,c,env_1);
  end matchcontinue;
end lookupQualifiedImportedClassInFrame;

protected function moreLookupUnqualifiedImportedClassInFrame 
"function: moreLookupUnqualifiedImportedClassInFrame
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
        (cache,(f :: _),_) = Inst.partialInstClassIn(cache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, ci_state, c, false, {});
        (cache,_,_) = lookupClass2(cache,{f}, Absyn.IDENT(ident), false);
      then
        (cache,true);
    /* move to next */
    case (cache,(_ :: fs),env,ident)
      equation
        (cache,res) = moreLookupUnqualifiedImportedClassInFrame(cache,fs, env, ident);
      then
        (cache,res);
    /* no more imports, return false */
    case (cache,{},_,_) then (cache,false);
  end matchcontinue;
end moreLookupUnqualifiedImportedClassInFrame;

protected function lookupUnqualifiedImportedClassInFrame 
"function: lookupUnqualifiedImportedClassInFrame
  Finds a class from an unqualified import locally in a frame"
	input Env.Cache inCache;
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv;
  output Boolean outBoolean;
algorithm
  (outCache,outClass,outEnv,outBoolean) := matchcontinue (inCache,inEnvItemLst,inEnv,inIdent)
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
        (cache,(f :: fs_1),cistate1) = Inst.partialInstClassIn(cache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet,
          ci_state, c, false, {});
        // Restrict import to the imported scope only, not its parents, thus {f} below
        (cache,c_1,(f_1 :: _)) = lookupClass2(cache,{f}, Absyn.IDENT(ident), false) "Restrict import to the imported scope only, not its parents..." ;
        (cache,more) = moreLookupUnqualifiedImportedClassInFrame(cache,fs, env, ident);
        unique = boolNot(more);
      then
        (cache,c_1,(f_1 :: fs_1),unique);
    // move to next
    case (cache,(_ :: fs),env,ident)
      equation
        (cache,c,env_1,unique) = lookupUnqualifiedImportedClassInFrame(cache,fs, env, ident);
      then
        (cache,c,env_1,unique);
  end matchcontinue;
end lookupUnqualifiedImportedClassInFrame;

public function lookupRecordConstructorClass 
"function: lookupRecordConstructorClass
  Searches for a record constructor implicitly defined by a record class."
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm
  (outClass,outEnv) := matchcontinue (inEnv,inPath)
    local
      SCode.Class c;
      list<Env.Frame> env_1,env;
      Absyn.Path path;
    case (env,path)
      equation
        (c,env_1) = lookupRecconstInEnv(env, path);
      then
        (c,env_1);
  end matchcontinue;
end lookupRecordConstructorClass;

public function lookupVar 
"LS: when looking up qualified component reference, lookupVar only
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
  Arg2: The variable to search for"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
  output Env.Cache outCache;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
algorithm
  (outCache,outAttributes,outType,outBinding) := matchcontinue (inCache,inEnv,inComponentRef)
    local
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Binding binding;
      list<Env.Frame> env,p_env;
      Exp.ComponentRef cref;
      Env.Cache cache;
    case (cache,env,cref) /* try the old lookup_var */
      equation
        // Debug.fprintln("lookup", "Lookup.lookupVar - case 1: " +& Exp.crefStr(cref));
        (cache,attr,ty,binding) = lookupVarInternal(cache, env, cref);
      then
        (cache,attr,ty,binding);
    case (cache,env,cref) /* then look in classes (implicitly instantiated packages) */      
      equation
        // Debug.fprintln("lookup", "Lookup.lookupVar - case 2: " +& Exp.crefStr(cref));
        (cache,p_env,attr,ty,binding) = lookupVarInPackages(cache, env, cref);
        checkPackageVariableConstant(p_env,attr,ty,cref);
      then
        (cache,attr,ty,binding);
    case (_,env,cref) equation
      // Debug.fprintln("failtrace", "Lookup.lookupVar - case 3: " +& Exp.crefStr(cref));
      /* Debug.fprint(\"failtrace\",  \"- lookup_var failed\\n\") */  then fail();
  end matchcontinue;
end lookupVar;

protected function checkPackageVariableConstant 
"function checkPackageVariableConstant
  Variables in packages must be constant. 
  This function produces an error message and fails if variable is not constant."
  input Env.Env env;
	input Types.Attributes attr;
	input Types.Type tp;
	input Exp.ComponentRef cref;
algorithm
  _ := matchcontinue(env,attr,tp,cref)
    local Absyn.Path path;
    case (env, Types.ATTR(parameter_= SCode.CONST()),_,cref) then ();
    case (env,attr,tp,cref) local String s1,s2;
      equation
        s1=Exp.printComponentRefStr(cref);
        s2 = Env.printEnvPathStr(env);
        Error.addMessage(Error.PACKAGE_VARIABLE_NOT_CONSTANT,{s1,s2});
      then fail();
  end matchcontinue;
end checkPackageVariableConstant;

protected function lookupVarInternal 
"function: lookupVarInternal
  Helper function to lookupVar. Searches the frames for variables."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
	output Env.Cache outCache;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
algorithm
  (outCache,outAttributes,outType,outBinding) := matchcontinue (inCache,inEnv,inComponentRef)
    local
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Binding binding;
      Option<String> sid;
      Env.BinTree ht;
      list<Env.Item> imps;
      list<Env.Frame> fs;
      Env.Frame frame;
      Exp.ComponentRef ref;
      Env.Cache cache;
    case (cache,((frame as Env.FRAME(optName = sid,clsAndVars = ht,imports = imps)) :: fs),ref)
      equation
        (cache,attr,ty,binding) = lookupVarF(cache,ht, ref);
      then
        (cache,attr,ty,binding);
    case (cache,(_ :: fs),ref)
      equation
        (cache,attr,ty,binding) = lookupVarInternal(cache,fs, ref);
      then
        (cache,attr,ty,binding);
  end matchcontinue;
end lookupVarInternal;


protected function lookupVarInPackages 
"function: lookupVarInPackages
  This function is called when a lookup of a variable with qualified names
  does not have the first element as a component, e.g. A.B.C is looked up
  where A is not a component. This implies that A is a class, and this
  class should be temporary instantiated, and the lookup should
  be performed within that class. I.e. the function performs lookup 
  of variables in the class hierarchy.
  Arg1: The environment to search in
  Arg2: The variable to search for"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
algorithm
  (outCache,outEnv,outAttributes,outType,outBinding) := matchcontinue (inCache,inEnv,inComponentRef)
    local
      SCode.Class c;
      String n,id1,id;
      Boolean encflag;
      SCode.Restriction r;
      list<Env.Frame> env2,env3,env5,env,fs,bcframes,p_env;
      ClassInf.State ci_state;
      list<Types.Var> types;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Binding bind;
      Exp.ComponentRef id2,cref,cr;
      list<Exp.Subscript> sb;
      Option<String> sid;
      list<Env.Item> items;
      Env.Frame f;
      Env.Cache cache;
      Absyn.Path path,scope,ep,p,packp;
      Boolean unique;
      String str;      

    // Lookup of enumeration variables
    case (cache,env,cr as Exp.CREF_QUAL(ident = id1,subscriptLst = {},componentRef = (id2 as Exp.CREF_IDENT(ident = _))))
      local list<String> strLst;
      equation
        // Debug.fprintln("lookup", "Lookup.lookupVarInPackages -> enumerations: " +& Exp.printComponentRefStr(cr));
        (cache,(c as SCode.CLASS(n,_,encflag,(r as SCode.R_ENUMERATION()),_)),env2)
          = lookupClass2(cache, env, Absyn.IDENT(id1), false) "Special case for looking up enumerations" ;
        env3 = Env.openScope(env2, encflag, SOME(n));
        ci_state = ClassInf.start(r, n);
        (cache,_,env5,_,_,types,_) = Inst.instClassIn(cache, env3, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, ci_state, c, false, {}, false);
        strLst = Util.listMap(types, Types.unparseVar);
        // Debug.fprintln("lookup", "Enum Types:\n" +& Util.stringDelimitList(strLst, "\n"));
        (cache,p_env,attr,ty,bind) = lookupVarInPackages(cache, env5, id2);
        // Debug.fprintln("lookup", "Found variable: " +& Exp.printComponentRefStr(id2) +& " type: " +& 
        //   Types.unparseType(ty) +& " binding: " +&
        //   Types.printBindingStr(bind)); 
      then
        (cache,p_env,attr,ty,bind);

    // lookup of constants on form A.B in packages. First look in cache.
    case (cache,env,cr as Exp.CREF_QUAL(ident = id,subscriptLst = {},componentRef = cref)) /* First part of name is a class. */
      equation
        // Debug.fprintln("lookup", "Lookup.lookupVarInPackages -> constants A.B in cache: " +& Exp.printComponentRefStr(cr));
        SOME(scope) = Env.getEnvPath(env);
        path = Exp.crefToPath(cr);
        id = Absyn.pathLastIdent(path);
        path = Absyn.stripLast(path);
        f::fs = Env.cacheGet(scope,path,cache);
        (cache,attr,ty,bind) = lookupVarLocal(cache,f::fs, Exp.CREF_IDENT(id,{}));
        // Debug.fprintln("lookup", "Found variable: " +& id +& " type: " +& 
        //  Types.unparseType(ty) +& " binding: " +&
        //  Types.printBindingStr(bind));        
        //print("found ");print(Exp.printComponentRefStr(cr));print(" in cache\n");
      then
        (cache,f::fs,attr,ty,bind);

    /* If we search for A1.A2....An.x while in scope A1.A2...An, just search for x.
     * Must do like this to ensure finite recursion 
     */
    case (cache,env,cr as Exp.CREF_QUAL(ident = id,subscriptLst = {},componentRef = cref)) 
      equation
        // Debug.fprintln("lookup", "Lookup.lookupVarInPackages -> avoid recursion: " +& Exp.printComponentRefStr(cr));
        p = Exp.crefToPath(cr);
        SOME(ep) = Env.getEnvPath(env);
        packp = Absyn.stripLast(p);
        true = ModUtil.pathEqual(ep, packp);
        id = Absyn.pathLastIdent(p);
        (cache,p_env,attr,ty,bind) = lookupVarInPackages(cache,env, Exp.CREF_IDENT(id,{}));
        // Debug.fprintln("lookup", "Found variable: " +& id +& " type: " +& 
        //   Types.unparseType(ty) +& " binding: " +&
        //   Types.printBindingStr(bind));        
      then
        (cache,p_env,attr,ty,bind);

    // lookup of constants on form A.B in packages. instantiate package and look inside.
    case (cache,env,cr as Exp.CREF_QUAL(ident = id,subscriptLst = {},componentRef = cref)) /* First part of name is a class. */
      equation
        // Debug.fprintln("lookup", "Lookup.lookupVarInPackages -> constants A.B instantiate A: " +& Exp.printComponentRefStr(cr));
        (cache,(c as SCode.CLASS(n,_,encflag,r,_)),env2) = lookupClass2(cache, env, Absyn.IDENT(id), false);
        env3 = Env.openScope(env2, encflag, SOME(n));
        ci_state = ClassInf.start(r, n);
        (cache,_,env5,_,_,types,_) = Inst.instClassIn(cache, env3, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, ci_state, c, false, {}, /*true*/false);
        (cache,p_env,attr,ty,bind) = lookupVarInPackages(cache, env5, cref);
        // Debug.fprintln("lookup", "Found variable: " +& Exp.printComponentRefStr(cref) +& " type: " +& 
        //   Types.unparseType(ty) +& " binding: " +&
        //   Types.printBindingStr(bind));        
      then
        (cache,p_env,attr,ty,bind);

    case (cache,env,(cr as Exp.CREF_IDENT(ident = id,subscriptLst = sb)))
      equation
        // Debug.fprintln("lookup", "Lookup.lookupVarInPackages -> local variables: " +& Exp.printComponentRefStr(cr));        
        (cache,attr,ty,bind) = lookupVarLocal(cache, env, cr);
        // Debug.fprintln("lookup", "Found variable: " +& Exp.printComponentRefStr(cr) +& " type: " +& 
        //   Types.unparseType(ty) +& " binding: " +&
        //   Types.printBindingStr(bind));        
      then
        (cache,env,attr,ty,bind);

    /* Search base classes */
    case (cache,Env.FRAME(inherited = (bcframes as (_ :: _)))::fs,cr)
      equation
        //print("searching base classes for ");print(Exp.printComponentRefStr(cref));print("\n");
        // Debug.fprintln("lookup", "Lookup.lookupVarInPackages -> search base classes: " +& Exp.printComponentRefStr(cr));
        (cache,attr,ty,bind) = lookupVar(cache, bcframes, cr);
        // Debug.fprintln("lookup", "Found variable: " +& Exp.printComponentRefStr(cr) +& " type: " +& 
        //   Types.unparseType(ty) +& " binding: " +&
        //   Types.printBindingStr(bind));
        //print("found in baseclass\n");
      then
        (cache,bcframes,attr,ty,bind);
        
    /* Search among qualified imports, e.g. import A.B; or import D=A.B; */
    case (cache,(env as (Env.FRAME(optName = sid,imports = items) :: _)),(cr as Exp.CREF_IDENT(ident = id,subscriptLst = sb)))
      equation
        // Debug.fprintln("lookup", "Lookup.lookupVarInPackages -> qualified imports: " +& Exp.printComponentRefStr(cr));        
        (cache,p_env,attr,ty,bind) = lookupQualifiedImportedVarInFrame(cache, items, env, id);
        // Debug.fprintln("lookup", "Found variable: " +& id +& " type: " +& 
        //   Types.unparseType(ty) +& " binding: " +&
        //   Types.printBindingStr(bind));        
      then
        (cache,p_env,attr,ty,bind);

    /* Search among unqualified imports, e.g. import A.B.* */
    case (cache,(env as (Env.FRAME(optName = sid,imports = items) :: _)),(cr as Exp.CREF_IDENT(ident = id,subscriptLst = sb)))
      equation
        // Debug.fprintln("lookup", "Lookup.lookupVarInPackages -> unqualified imports: " +& Exp.printComponentRefStr(cr));        
        (cache,p_env,attr,ty,bind,unique) = lookupUnqualifiedImportedVarInFrame(cache, items, env, id);
        reportSeveralNamesError(unique,id);
        // Debug.fprintln("lookup", "Found variable: " +& id +& " type: " +& 
        //   Types.unparseType(ty) +& " binding: " +&
        //   Types.printBindingStr(bind));        
      then
        (cache,p_env,attr,ty,bind);

    case (cache,(f :: fs),cr) /* Search parent scopes */
      equation
        // Debug.fprintln("lookup", "Lookup.lookupVarInPackages -> parent scope: " +& Exp.printComponentRefStr(cr));
          //print("searching parent scope of ");print(Env.printEnvPathStr(fs));print("\n");
        (cache,p_env,attr,ty,bind) = lookupVarInPackages(cache,fs, cr);
        // Debug.fprintln("lookup", "Found variable: " +& Exp.printComponentRefStr(cr) +& " type: " +& 
        //   Types.unparseType(ty) +& " binding: " +&
        //   Types.printBindingStr(bind));        
      then
        (cache,p_env,attr,ty,bind);

    case (cache,env,cr)
      equation
        Debug.fprintln("failtrace", "Lookup.lookupVarInPackages failed:" +& Exp.printComponentRefStr(cr));
      then fail();
  end matchcontinue;
end lookupVarInPackages;

public function lookupVarLocal 
"function: lookupVarLocal
  This function is very similar to lookupVar, but it only looks
  in the topmost environment frame, which means that it only finds
  names defined in the local scope.

  ----EXCEPTION---: 
    When the topmost scope is the scope of a for loop, the lookup continues on the next scope. 
    This to allow variables in the local scope to also be found even if inside a for scope.

  Arg1: The environment to search in
  Arg2: The variable to search for"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
  output Env.Cache outCache;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
algorithm
  (outCache,outAttributes,outType,outBinding) := matchcontinue (inCache,inEnv,inComponentRef)
    local
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Binding binding;
      Option<String> sid;
      Env.BinTree ht;
      list<Env.Frame> fs,env,bcframes;
      Exp.ComponentRef cref;
      Env.Cache cache;
    /* Lookup in frame */
    case (cache,(Env.FRAME(optName = sid,clsAndVars = ht) :: fs),cref)
      equation
        (cache,attr,ty,binding) = lookupVarF(cache,ht, cref);
      then
        (cache,attr,ty,binding);
    /* lookup for loop scope */
    case (cache,(Env.FRAME(optName = SOME("$for loop scope$")) :: env),cref)
      equation
        (cache,attr,ty,binding) = lookupVarLocal(cache,env, cref) "Exception, when in for loop scope allow search of next scope" ;
      then
        (cache,attr,ty,binding);
  end matchcontinue;
end lookupVarLocal;

public function lookupIdentLocal 
"function: lookupIdentLocal
  Searches for a variable in the local scope."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output Types.Var outVar;
  output Option<tuple<SCode.Element, Types.Mod>> outTplSCodeElementTypesModOption;
  output Env.InstStatus instStatus;
  output Env.Env outEnv;
algorithm
  (outCache,outVar,outTplSCodeElementTypesModOption,instStatus,outEnv) := matchcontinue (inCache,inEnv,inIdent)
    local
      Types.Var fv;
      Option<tuple<SCode.Element, Types.Mod>> c;
      Env.InstStatus i;
      list<Env.Frame> env,fs;
      Option<String> sid;
      Env.BinTree ht;
      String id;
      Env.Cache cache;
    /* component environment */
    case (cache,env as (Env.FRAME(optName = sid,clsAndVars = ht) :: fs),id) 
      equation
        //print("lookupIdentLocal ");print(id);print(" , fs =");print(Env.printEnvStr(env));print("\n");
        (cache,fv,c,i,env) = lookupVar2(cache,ht, id);
      then
        (cache,fv,c,i,env);
  end matchcontinue;
end lookupIdentLocal;

public function lookupAndInstantiate 
"function lookupAndInstantiate
  Performs a lookup of a class and then instantiate that class 
  to return its environment. Helper function used e.g by Inst.mo"
  input Env.Cache inCache;
  input Env.Env env;
  input Absyn.Path path;
  input Boolean msg;
  output Env.Cache outCache;
  output Env.Env classEnv;
algorithm
  (outCache,classEnv) := matchcontinue(cache,env,path,msg)
    local	Env.Cache cache;
      String cn2;
      Boolean enc2,enc;
      SCode.Restriction r;
      ClassInf.State new_ci_state;
      Env.Env cenv,cenv_2;
      Absyn.Path scope;
      SCode.Class c;
      Absyn.Ident ident;
    // Try to find in cache.
    case(cache,env,path,msg)
      equation
        (cache,(c as SCode.CLASS(cn2,_,enc2,r,_)),cenv) = lookupClass2(cache,env, path, msg);
        SOME(scope) = Env.getEnvPath(cenv);
        ident = Absyn.pathLastIdent(path);
        classEnv = Env.cacheGet(scope,Absyn.IDENT(ident),cache);
      then (cache,classEnv);
    // Not found in cache, lookup and instantiate.
    case(cache,env,path,msg)
      equation
        (cache,(c as SCode.CLASS(cn2,_,enc2,r,_)),cenv) = lookupClass2(cache,env, path, msg);
        cenv_2 = Env.openScope(cenv, enc2, SOME(cn2));
        new_ci_state = ClassInf.start(r, cn2);
        (cache,classEnv,_) = Inst.partialInstClassIn(cache,cenv_2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, new_ci_state, c, false, {});
      then (cache,classEnv);
    // failing
    case(cache,env,path,msg)
      equation
        Debug.fprint("failtrace", "-Lookup.lookupAndInstantiate failed\n");
     then fail();
  end matchcontinue;
end lookupAndInstantiate;

public function lookupIdent 
"function: lookupIdent
  Same as lookupIdentLocal, except check all frames."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output Types.Var outVar;
  output Option<tuple<SCode.Element, Types.Mod>> outTplSCodeElementTypesModOption;
  output Env.InstStatus instStatus;
algorithm
  (outCache,outVar,outTplSCodeElementTypesModOption,instStatus) := matchcontinue (outCache,inEnv,inIdent)
    local
      Types.Var fv;
      Option<tuple<SCode.Element, Types.Mod>> c;
      Env.InstStatus i;
      Option<String> sid;
      Env.BinTree ht;
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
        (cache,fv,c,i) = lookupIdent(cache, rest, id);
      then
        (cache,fv,c,i);
  end matchcontinue;
end lookupIdent;

/* Function lookup */
public function lookupFunctionsInEnv 
"function: lookupFunctionsInEnv
  Returns a list of types that the function has."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output Env.Cache outCache;
  output list<Types.Type> outTypesTypeLst;
algorithm
  (outCache,outTypesTypeLst) := matchcontinue (inCache,inEnv,inPath)
    local
      Absyn.Path id,iid,path;
      Option<String> sid;
      Env.BinTree ht,httypes;
      list<tuple<Types.TType, Option<Absyn.Path>>> reslist,c1,c2,res,cc;
      list<Env.Frame> env,fs,env_1,env2,env_2;
      String pack;
      SCode.Class c;
      Boolean encflag;
      SCode.Restriction restr;
      ClassInf.State ci_state,cistate1;
      Env.Frame f;
      Env.Cache cache;
      String strId,s;
      
    /* nothing in the environment */
    case (cache,{},id) then (cache,{});
    /* Builtin operators are looked up in top frame directly */
    case (cache,env,(iid as Absyn.IDENT(name = strId)))
      equation
        _ = Static.elabBuiltinHandler(strId) "Check for builtin operators" ;
        Env.FRAME(sid,ht,httypes,_,_,_,_) = Env.topFrame(env);
        (cache,reslist) = lookupFunctionsInFrame(cache,ht, httypes, env, strId);
      then
        (cache,reslist);
    /* Check for special builtin ops that can not be represented in environment like for instance cardinality.*/
    case (cache,env,(iid as Absyn.IDENT(name = strId)))
      equation
        _ = Static.elabBuiltinHandlerGeneric(strId);
        reslist = createGenericBuiltinFunctions(env, strId);
      then
        (cache,reslist);
    /* Simple name, search frame */
    case (cache,(env as (Env.FRAME(optName = sid,clsAndVars = ht,types = httypes) :: fs)),(iid as Absyn.IDENT(name = strId)))
      equation
        (cache,c1 as _::_)= lookupFunctionsInFrame(cache, ht, httypes, env, strId);
      then
        (cache,c1);
    /* Simple name, if class  with restriction function found in frame instantiate to get type. */
    case (cache,f::fs ,(iid as Absyn.IDENT(name = strId)))
      equation
        (cache,(c as SCode.CLASS(strId,_,encflag,restr,_)),env_1) = lookupClass2(cache,f::fs, iid, false);
        true = SCode.isFunctionOrExtFunction(restr);
        (cache,(env_2 as (Env.FRAME(optName = sid,clsAndVars = ht,types = httypes)::_)))
          = Inst.implicitFunctionTypeInstantiation(cache,env_1, c);
        (cache,c1 as _::_)= lookupFunctionsInFrame(cache,ht, httypes, env_2, strId);
      then
        (cache,c1);
    /* For qualified function names, e.g. Modelica.Math.sin */
    case (cache,(env as (Env.FRAME(optName = sid,clsAndVars = ht,types = httypes) :: fs)),(iid as Absyn.QUALIFIED(name = pack,path = path)))
      equation
        (cache,(c as SCode.CLASS(strId,_,encflag,restr,_)),env_1) = lookupClass2(cache,env, Absyn.IDENT(pack), false);
        env2 = Env.openScope(env_1, encflag, SOME(strId));
        ci_state = ClassInf.start(restr, strId);
        // (cache,_,env_2,_,_,_,_) = Inst.instClassIn(cache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, ci_state, c, false/*FIXME:prot*/, {}, false);
        (cache,env_2,cistate1) = Inst.partialInstClassIn(cache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, ci_state, c, false, {});
        (cache,reslist) = lookupFunctionsInEnv(cache,env_2, path);
      then
        (cache,reslist);
    /* Did not match. Search next frame. */
    case (cache,(f :: fs),id)      
      equation
        (cache,cc) = lookupFunctionsInEnv(cache,fs, id);
      then
        (cache,cc);
    /* failing */
    case (_,_,_)
      equation
        Debug.fprint("failtrace", "lookup_functions_in_env failed\n");
      then
        fail();
  end matchcontinue;
end lookupFunctionsInEnv;

protected function createGenericBuiltinFunctions 
"function: createGenericBuiltinFunctions
  author: PA
  This function creates function types on-the-fly for special builtin
  operators/functions which can not be represented in the builtin
  environment."
  input Env.Env inEnv;
  input String inString;
  output list<Types.Type> outTypesTypeLst;
algorithm
  outTypesTypeLst := matchcontinue (inEnv,inString)
    local list<Env.Frame> env;
    case (env,"cardinality") then {
          (
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_COMPLEX(ClassInf.CONNECTOR("$$"),{},NONE),NONE))},(Types.T_INTEGER({}),NONE)),NONE)};  /* function_name cardinality */
  end matchcontinue;
end createGenericBuiltinFunctions;

/*
 * - Internal functions
 *   Type lookup
 */

protected function lookupTypeInEnv 
"function: lookupTypeInEnv
 "
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output Env.Cache outCache;
  output Types.Type outType;
  output Env.Env outEnv;
algorithm
  (outCache,outType,outEnv) := matchcontinue (inCache,inEnv,inPath)
    local
      tuple<Types.TType, Option<Absyn.Path>> c;
      list<Env.Frame> env_1,env,fs;
      Option<String> sid;
      Env.BinTree ht,httypes;
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

protected function lookupTypeInFrame 
"function: lookupTypeInFrame
  Searches a frame for a type."
  input Env.Cache inCache;
  input Env.BinTree inBinTree1;
  input Env.BinTree inBinTree2;
  input Env.Env inEnv3;
  input SCode.Ident inIdent4;
  output Env.Cache outCache;
  output Types.Type outType;
  output Env.Env outEnv;
algorithm
  (outCache,outType,outEnv):=
  matchcontinue (inCache,inBinTree1,inBinTree2,inEnv3,inIdent4)
    local
      tuple<Types.TType, Option<Absyn.Path>> t,ftype,ty;
      Env.BinTree ht,httypes;
      list<Env.Frame> env,cenv,env_1,env_2;
      String id,n;
      SCode.Class cdef;
      Absyn.Path fpath;
      list<Types.Var> varlst;
      Env.Cache cache;
    case (cache,ht,httypes,env,id) /* Classes and vars types */
      equation
        Env.TYPE((t :: _)) = Env.treeGet(httypes, id, System.hash);
      then
        (cache,t,env);
    case (cache,ht,httypes,env,id)
      equation
        Env.VAR(_,_,_,_) = Env.treeGet(ht, id, System.hash);
        Error.addMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id});
      then
        fail();
        /* Record constructor function*/
    case (cache,ht,httypes,env,id)
      equation
        Env.CLASS((cdef as SCode.CLASS(n,_,_,SCode.R_RECORD(),_)),_) = Env.treeGet(ht, id, System.hash) "Each time a record constructor function is looked up, this rule will create the function. An improvement (perhaps needing lot of code) is to add the function to the environment, which is returned from this function." ;
        (cache,fpath) = Inst.makeFullyQualified(cache,env, Absyn.IDENT(n));
        (cache,varlst) = buildRecordConstructorVarlst(cache,cdef, env);
        ftype = Types.makeFunctionType(fpath, varlst);
      then
        (cache,ftype,env);
        /* Found function */
    case (cache,ht,httypes,env,id)
      local SCode.Restriction restr;
      equation
        Env.CLASS((cdef as SCode.CLASS(_,_,_,restr,_)),cenv) = Env.treeGet(ht, id, System.hash);
        true = SCode.isFunctionOrExtFunction(restr);
        (cache,env_1,_) = Inst.implicitFunctionInstantiation(cache,cenv, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet,
          cdef, {});
        (cache,ty,env_2) = lookupTypeInEnv(cache,env_1, Absyn.IDENT(id));
      then
        (cache,ty,env_2);
  end matchcontinue;
end lookupTypeInFrame;

protected function lookupFunctionsInFrame 
"function: lookupFunctionsInFrame
  This actually only looks up the function name and find 
  all corresponding types that have this function name."
  input Env.Cache inCache;
  input Env.BinTree inBinTree1;
  input Env.BinTree inBinTree2;
  input Env.Env inEnv3;
  input SCode.Ident inIdent4;
  output Env.Cache outCache;
  output list<Types.Type> outTypesTypeLst;
algorithm
  (outCache,outTypesTypeLst):=
  matchcontinue (inCache,inBinTree1,inBinTree2,inEnv3,inIdent4)
    local
      list<tuple<Types.TType, Option<Absyn.Path>>> tps;
      Env.BinTree ht,httypes;
      list<Env.Frame> env,cenv,env_1;
      String id,n;
      SCode.Class cdef;
      list<Types.Var> varlst;
      Absyn.Path fpath;
      tuple<Types.TType, Option<Absyn.Path>> ftype,t;
      Env.Cache cache;
    case (cache,ht,httypes,env,id) /* Classes and vars Types */
      equation
        Env.TYPE(tps) = Env.treeGet(httypes, id, System.hash);
      then
        (cache,tps);
    case (cache,ht,httypes,env,id)
      equation
        Env.VAR(_,_,_,_) = Env.treeGet(ht, id, System.hash);
        Error.addMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id});
      then
        fail();

        /* Records, create record constructor function*/
    case (cache,ht,httypes,env,id)
      equation
        Env.CLASS((cdef as SCode.CLASS(n,_,_,SCode.R_RECORD(),_)),cenv) = Env.treeGet(ht, id, System.hash);
        (cache,varlst) = buildRecordConstructorVarlst(cache,cdef, env);
        (cache,fpath) = Inst.makeFullyQualified(cache,cenv, Absyn.IDENT(n));
        ftype = Types.makeFunctionType(fpath, varlst);
      then
        (cache,{ftype});

        /* Found class that is function, instantiate to get type*/
/*    case (cache,ht,httypes,env,id) local SCode.Restriction restr;
      equation
        Env.CLASS((cdef as SCode.CLASS(_,_,_,restr,_)),cenv) = Env.treeGet(ht, id, System.hash) "If found class that is function." ;
        true = SCode.isFunctionOrExtFunction(restr);
        (cache,env_1) = Inst.implicitFunctionTypeInstantiation(cache,cenv, cdef);
        (cache,tps) = lookupFunctionsInEnv(cache,env_1, Absyn.IDENT(id));
      then
        (cache,tps);*/

     /* Found class that is is external object*/
     case (cache,ht,httypes,env,id)
        local String s;
        equation
          Env.CLASS(cdef,cenv) = Env.treeGet(ht, id, System.hash);
	        true = Inst.classIsExternalObject(cdef);
	        (cache,_,env_1,_,t,_) = Inst.instClass(cache,cenv, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, cdef,
         	 {}, false, Inst.TOP_CALL());
          (cache,t,_) = lookupTypeInEnv(cache,env_1, Absyn.IDENT(id));
           //s = Types.unparseType(t);
         	 //print("type :");print(s);print("\n");
       then
        (cache,{t});
  end matchcontinue;
end lookupFunctionsInFrame;

protected function lookupRecconstInEnv 
"function: lookupRecconstInEnv
  Helper function to lookupRecordConstructorClass. 
  Searches the environment for record constructors."
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm
  (outClass,outEnv) := matchcontinue (inEnv,inPath)
    local
      SCode.Class c;
      list<Env.Frame> env,fs;
      Option<String> sid;
      Env.BinTree ht;
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
  This function lookups the implicit record constructor 
  class (function) of a record in a frame"
  input Env.BinTree inBinTree;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm
  (outClass,outEnv) := matchcontinue (inBinTree,inEnv,inIdent)
    local
      Env.BinTree ht;
      list<Env.Frame> env;
      String id;
      SCode.Class cdef;
    case (ht,env,id)
      equation
        Env.VAR(_,_,_,_) = Env.treeGet(ht, id, System.hash);
        Error.addMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id});
      then
        fail();
    case (ht,env,id)
      equation
        Env.CLASS((cdef as SCode.CLASS(_,_,_,SCode.R_RECORD(),_)),_) = Env.treeGet(ht, id, System.hash);
        cdef = buildRecordConstructorClass(cdef, env);
      then
        (cdef,env);
  end matchcontinue;
end lookupRecconstInFrame;

protected function buildRecordConstructorClass 
"function: buildRecordConstructorClass
  Creates the record constructor class, i.e. a 
  function, from the record class given as argument."
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
    case ((cl as SCode.CLASS(name = id,restriction = restr,classDef = SCode.PARTS(elementLst = elts))),env) /* record class function class */
      equation
        funcelts = buildRecordConstructorElts(elts, env);
        reselt = buildRecordConstructorResultElt(elts, id, env);
      then
        SCode.CLASS(id,false,false,SCode.R_FUNCTION(),
          SCode.PARTS((reselt :: funcelts),{},{},{},{},NONE));
  end matchcontinue;
end buildRecordConstructorClass;

protected function buildRecordConstructorElts 
"function: buildRecordConstructorElts
  Helper function to buildRecordConstructorClass. Creates the elements of the function class."
  input list<SCode.Element> inSCodeElementLst;
  input Env.Env inEnv;
  output list<SCode.Element> outSCodeElementLst;
algorithm
  outSCodeElementLst:=
  matchcontinue (inSCodeElementLst,inEnv)
    local
      list<SCode.Element> res,rest;
      SCode.Element comp;
      String id;
      Boolean fl,repl,prot,f,s;
      Absyn.InnerOuter io;
      list<Absyn.Subscript> d;
      SCode.Accessibility ac;
      SCode.Variability var;
      Absyn.Direction dir;
      Absyn.TypeSpec tp;
      SCode.Mod mod;
      Option<Absyn.Path> bc;
      Option<Absyn.Comment> comment;
      list<Env.Frame> env;
    case (((comp as SCode.COMPONENT(component = id,innerOuter=io,finalPrefix = fl,replaceablePrefix = repl,protectedPrefix = prot,
            attributes = SCode.ATTR(arrayDims = d,flowPrefix = f,streamPrefix = s,accesibility = ac,variability = var,direction = dir),
            typeSpec = tp, modifications = mod, baseClassPath = bc, comment = comment)) :: rest),env)
      equation
        res = buildRecordConstructorElts(rest, env);
      then
        (SCode.COMPONENT(id,io,fl,repl,prot,SCode.ATTR(d,f,s,ac,var,Absyn.INPUT()),tp,mod,bc,comment) :: res);
    case ({},_) then {};
  end matchcontinue;
end buildRecordConstructorElts;

protected function buildRecordConstructorResultElt 
"function: buildRecordConstructorResultElt
  This function builds the result element of a record constructor function, i.e. the returned variable"
  input list<SCode.Element> elts;
  input SCode.Ident id;
  input Env.Env env;
  output SCode.Element outElement;
  list<SCode.SubMod> submodlst;
algorithm
  submodlst := buildRecordConstructorResultMod(elts);
  outElement := SCode.COMPONENT("result",Absyn.UNSPECIFIED(),false,false,false,
          SCode.ATTR({},false,false,SCode.RW(),SCode.VAR(),Absyn.OUTPUT()),Absyn.TPATH(Absyn.IDENT(id),NONE),SCode.MOD(false,Absyn.NON_EACH(),submodlst,NONE),
          NONE,NONE);
end buildRecordConstructorResultElt;

protected function buildRecordConstructorResultMod 
"function: buildRecordConstructorResultMod
  This function builds up the modification list for the output element of a record constructor.
  Example:
    record foo
       Real x;
       String y;
       end foo;
   => modifier list become \'result.x=x, result.y=y\'"
  input list<SCode.Element> inSCodeElementLst;
  output list<SCode.SubMod> outSCodeSubModLst;
algorithm
  outSCodeSubModLst := matchcontinue (inSCodeElementLst)
    local
      list<SCode.SubMod> restmod;
      String id;
      list<SCode.Element> rest;
    case ((SCode.COMPONENT(component = id) :: rest))
      equation
        restmod = buildRecordConstructorResultMod(rest);
      then
        (SCode.NAMEMOD("result",
          SCode.MOD(false,Absyn.NON_EACH(),
          {
          SCode.NAMEMOD(id,
          SCode.MOD(false,Absyn.NON_EACH(),{},
          SOME((Absyn.CREF(Absyn.CREF_IDENT(id,{})),false))))},NONE)) :: restmod);
    case ({}) then {};
  end matchcontinue;
end buildRecordConstructorResultMod;

protected function buildRecordConstructorVarlst 
"function: buildRecordConstructorVarlst
  This function takes a class  (`SCode.Class\') which holds a definition
  of a record and builds a list of variables of the record used for
  constructing a record constructor function."
	input Env.Cache inCache;
  input SCode.Class inClass;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output list<Types.Var> outTypesVarLst;
algorithm
  (outCache,outTypesVarLst) :=
  matchcontinue (inCache,inClass,inEnv)
    local
      list<Types.Var> inputvarlst;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      SCode.Class cl;
      list<SCode.Element> elts;
      list<Env.Frame> env;
      Env.Cache cache;
    case (cache,(cl as SCode.CLASS(classDef = SCode.PARTS(elementLst = elts))),env)
      equation
        (cache,inputvarlst) = buildVarlstFromElts(cache,elts, env);
        (cache,_,_,_,ty,_) = Inst.instClass(cache,env, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, cl, {}, true, Inst.TOP_CALL()) "FIXME: impl" ;
      then
        (cache,Types.VAR("result",
          Types.ATTR(false,false,SCode.RW(),SCode.VAR(),Absyn.OUTPUT()),false,ty,Types.UNBOUND()) :: inputvarlst);
    case (_,_,_)
      equation
        Debug.fprint("failtrace", "Lookup.buildRecordConstructorVarlst failed\n");
      then
        fail();
  end matchcontinue;
end buildRecordConstructorVarlst;

protected function buildVarlstFromElts 
"function: buildVarlstFromElts
  Helper function to build_record_constructor_varlst"
	input Env.Cache inCache;
  input list<SCode.Element> inSCodeElementLst;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output list<Types.Var> outTypesVarLst;
algorithm
  (outCache,outTypesVarLst) :=
  matchcontinue (inCache,inSCodeElementLst,inEnv)
    local
      list<Types.Var> vars;
      Types.Var var;
      SCode.Element comp;
      list<SCode.Element> rest;
      list<Env.Frame> env;
      Env.Cache cache;
    case (cache,((comp as SCode.COMPONENT(component = _)) :: rest),env)
      equation
        (cache,vars) = buildVarlstFromElts(cache,rest, env);
        (cache,var) = Inst.instRecordConstructorElt(cache,env, comp, true) 
        "P.A Here we need to do a lookup of the type. Therefore we need the env passed along from lookup_xxxx function. FIXME: impl" ;
      then
        (cache,var :: vars);
    case (cache,{},_) then (cache,{});
    case (_,_,_) /* Debug.fprint(\"failtrace\", \"- build_varlst_from_elts failed!\\n\") */  then fail();
  end matchcontinue;
end buildVarlstFromElts;

/* Class lookup */

public function isInBuiltinEnv 
"function: isInBuiltinEnv
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
        Debug.fprintln("failtrace", "Lookup.isInBuiltinEnv failed");
      then
        fail();
  end matchcontinue;
end isInBuiltinEnv;

protected function lookupClassInEnv 
"function: lookupClassInEnv
  Helper function to lookupClass. Searches the environment for the class."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm
  (outCache,outClass,outEnv) := matchcontinue (inCache,inEnv,inPath,inBoolean)
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
        (cache,c,env_1) = lookupClassInFrame(cache,frame, (frame :: fs), id, msg) "print \"looking in env for \" & print id & print \"\\n\" &" ;
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
    case (cache,((f as Env.FRAME(optName = sid,isEncapsulated = false)) :: fs),id,msgflag) /* if not found and not encapsulated, look in next enclosing scope */
      local
        Option<String> sid;
        Absyn.Path id;
      equation
        //print("searching parent scope\n");
        (cache,c,env_1) = lookupClassInEnv(cache,fs, id, msgflag);
      then
        (cache,c,env_1);
  end matchcontinue;
end lookupClassInEnv;

protected function lookupClassInFrame 
"function: lookupClassInFrame
  Search for a class within one frame."
  input Env.Cache inCache;
  input Env.Frame inFrame;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm
  (outCache,outClass,outEnv) := matchcontinue (inCache,inFrame,inEnv,inIdent,inBoolean)
    local
      SCode.Class c;
      list<Env.Frame> env,totenv,bcframes,env_1;
      Option<String> sid;
      Env.BinTree ht;
      String id,name;
      list<Env.Item> items;
      Env.Cache cache;
      /* Check this scope for class */
    case (cache,Env.FRAME(optName = sid,clsAndVars = ht),totenv,id,_)
      equation
        Env.CLASS(c,env) = Env.treeGet(ht, id, System.hash) ;
      then
        (cache,c,totenv);

        /* Searching for class, found component*/
    case (cache,Env.FRAME(optName = sid,clsAndVars = ht),_,id,true)
      equation
        Env.VAR(_,_,_,_) = Env.treeGet(ht, id, System.hash);
        Error.addMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id});
      then
        fail();

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

protected function reportSeveralNamesError 
"given a boolean, report error message of importing several names
 if boolean flag is false and fail. If flag is true succeed and do 
 nothing."
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

protected function lookupVar2 
"function: lookupVar2
  Helper function to lookupVarF and lookupIdent."
	input Env.Cache inCache;
  input Env.BinTree inBinTree;
  input SCode.Ident inIdent;
  output Env.Cache outCache;
  output Types.Var outVar;
  output Option<tuple<SCode.Element, Types.Mod>> outTplSCodeElementTypesModOption;
  output Env.InstStatus instStatus;
  output Env.Env outEnv;
algorithm
  (outCache,outVar,outTplSCodeElementTypesModOption,instStatus,outEnv) := matchcontinue (inCache,inBinTree,inIdent)
    local
      Types.Var fv;
      Option<tuple<SCode.Element, Types.Mod>> c;
      Env.InstStatus i;
      list<Env.Frame> env;
      Env.BinTree ht;
      String id;
      Env.Cache cache;
    case (cache,ht,id)
      equation
        Env.VAR(fv,c,i,env) = Env.treeGet(ht, id, System.hash);
      then
        (cache,fv,c,i,env);
  end matchcontinue;
end lookupVar2;

protected function checkSubscripts 
"function: checkSubscripts
  This function checks a list of subscripts agains type, and removes
  dimensions from the type according to the subscripting."
  input Types.Type inType;
  input list<Exp.Subscript> inExpSubscriptLst;
  output Types.Type outType;
algorithm
  outType:=
  matchcontinue (inType,inExpSubscriptLst)
    local
      tuple<Types.TType, Option<Absyn.Path>> t,t_1;
      Types.ArrayDim dim;
      Option<Absyn.Path> p;
      list<Exp.Subscript> ys,s;
      Integer sz,ind;
      list<Exp.Exp> se;
    case (t,{}) then t;
    case ((Types.T_ARRAY(arrayDim = dim,arrayType = t),p),(Exp.WHOLEDIM() :: ys))
      equation
        t_1 = checkSubscripts(t, ys);
      then
        ((Types.T_ARRAY(dim,t_1),p));
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(sz)),arrayType = t),p),(Exp.SLICE(exp = Exp.ARRAY(array = se)) :: ys))
      local Integer dim;
      equation
        t_1 = checkSubscripts(t, ys);
        dim = listLength(se) "FIXME: Check range" ;
      then
        ((Types.T_ARRAY(Types.DIM(SOME(dim)),t_1),p));
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(sz)),arrayType = t),_),(Exp.INDEX(exp = Exp.ICONST(integer = ind)) :: ys))
      equation
        (ind > 0) = true;
        (ind <= sz) = true;
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(sz)),arrayType = t),_),(Exp.INDEX(exp = e) :: ys)) /* HJ: Subscrits needn\'t be constant. No range-checking can
	       be done */
	       local Exp.Exp e;
      equation
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = NONE),arrayType = t),_),(Exp.INDEX(exp = _) :: ys))
      equation
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(sz)),arrayType = t),_),(Exp.WHOLEDIM() :: ys))
      equation
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = NONE),arrayType = t),_),(Exp.WHOLEDIM() :: ys))
      equation
        t_1 = checkSubscripts(t, ys);
      then
        t_1;

        // If slicing with integer array of VAR variability, i.e. index changing during runtime.
        // => resulting ARRAY type has no specified dimension size.
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(sz)),arrayType = t),p),(Exp.SLICE(exp = e) :: ys))
      local Exp.Exp e;
      equation
        t_1 = checkSubscripts(t, ys);
      then
       ((Types.T_ARRAY(Types.DIM(NONE),t_1),p));
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = NONE),arrayType = t),p),(Exp.SLICE(exp = _) :: ys))
      equation
        t_1 = checkSubscripts(t, ys);
      then
        ((Types.T_ARRAY(Types.DIM(NONE),t_1),p));

    case ((Types.T_COMPLEX(_,_,SOME(t)),_),ys)
      then checkSubscripts(t,ys);
    case (t,s)
      equation
        Debug.fprint("failtrace", "- check_subscripts failed ( ");
        Debug.fprint("failtrace", Types.printTypeStr(t));
        Debug.fprint("failtrace", ")\n");
      then
        fail();
  end matchcontinue;
end checkSubscripts;

protected function lookupVarF 
"function: lookupVarF
  This function looks in a frame to find a declared variable.  
  If the name being looked up is qualified, the first part of 
  the name is looked up, and lookupInVar is used to for further 
  lookup in the result of that lookup."
	input Env.Cache inCache;
  input Env.BinTree inBinTree;
  input Exp.ComponentRef inComponentRef;
  output Env.Cache outCache;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
algorithm
  (outCache,outAttributes,outType,outBinding) := matchcontinue (inCache,inBinTree,inComponentRef)
    local
      String n,id;
      Boolean f,s;
      SCode.Accessibility acc;
      SCode.Variability vt;
      Absyn.Direction di;
      tuple<Types.TType, Option<Absyn.Path>> ty,ty_1;
      Types.Binding bind,binding,binding2;
      Env.BinTree ht;
      list<Exp.Subscript> ss;
      list<Env.Frame> compenv;
      Types.Attributes attr;
      Exp.ComponentRef ids;
      Env.Cache cache;
    case (cache,ht,Exp.CREF_IDENT(ident = id,subscriptLst = ss))
      equation
        (cache,Types.VAR(n,Types.ATTR(f,s,acc,vt,di),_,ty,bind),_,_,_) = lookupVar2(cache, ht, id);
        ty_1 = checkSubscripts(ty, ss);
      then
        (cache,Types.ATTR(f,s,acc,vt,di),ty_1,bind);
    case (cache,ht,Exp.CREF_QUAL(ident = id,subscriptLst = ss,componentRef = ids)) /* Qualified variables looked up through component environment. */
      equation
        (cache,Types.VAR(n,Types.ATTR(f,s,acc,vt,di),_,ty,bind),_,_,compenv) = lookupVar2(cache, ht, id);
        (cache,attr,ty,binding) = lookupVar(cache, compenv, ids);
      then
        (cache,attr,ty,binding);
  end matchcontinue;
end lookupVarF;

protected function assertPackage 
"function: assertPackage
  This function checks that a class definition is a package.  
  This breaks the everything-can-be-generalized-to-class 
  principle, since it requires that the keyword *package* 
  is used in the package file."
  input SCode.Class inClass;
algorithm
  _ := matchcontinue (inClass)
    case SCode.CLASS(restriction = SCode.R_PACKAGE()) then ();  /* Break the generalize-to-class rule */
  end matchcontinue;
end assertPackage;

end Lookup;

