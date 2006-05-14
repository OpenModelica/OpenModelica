package Lookup "
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

 Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

 Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

 Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  
  file:	 Lookup.rml
  module:      Lookup
  description: Scoping rules
 
  RCS: $Id$
 

  This module is responsible for the lookup mechanism in Modelica.
  It is responsible for looking up classes, variables, etc. in the
  environment \'Env\' by following the lookup rules.
  The most important functions are:
  lookup_class - to find a class 
  lookup_type - to find types (e.g. functions, types, etc.)
  lookup_var - to find a variable in the instance hierarchy.
"

public import OpenModelica.Compiler.ClassInf;

public import OpenModelica.Compiler.Types;

public import OpenModelica.Compiler.Absyn;

public import OpenModelica.Compiler.Exp;

public import OpenModelica.Compiler.Env;

public import OpenModelica.Compiler.SCode;

protected import OpenModelica.Compiler.Debug;

protected import OpenModelica.Compiler.Inst;

protected import OpenModelica.Compiler.Mod;

protected import OpenModelica.Compiler.Prefix;

protected import OpenModelica.Compiler.Builtin;

protected import OpenModelica.Compiler.ModUtil;

protected import OpenModelica.Compiler.Static;

protected import OpenModelica.Compiler.Connect;

protected import OpenModelica.Compiler.Error;

public function lookupType "adrpo -- not used
with \"Util.rml\"
with \"Print.rml\"
with \"Parser.rml\"
with \"Dump.rml\"

  
  - Lookup functions
 
  These functions look up class and variable names in the environment.
  The names are supplied as a path, and if the path is qualified, a
  variable named as the first part of the path is searched for, and the
  name is looked for in it.
 
  function: lookupType
  
  This function finds a specified type in the environment. 
  If it finds a function instead, this will be implicitly instantiated 
  and lookup will start over. 
 
  Arg1: Env.Env is the environment which to perform the lookup in
  Arg2: Absyn.Path is the type to look for
"
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input Boolean inBoolean;
  output Types.Type outType;
  output Env.Env outEnv;
algorithm 
  (outType,outEnv):=
  matchcontinue (inEnv,inPath,inBoolean)
    local
      tuple<Types.TType, Option<Absyn.Path>> t,c_1;
      list<Env.Frame> env_1,env,env_2,env3,env2,env_3;
      Absyn.Path path,p;
      Boolean msg,encflag;
      SCode.Class c;
      String id,pack,classname,scope;
      SCode.Restriction restr;
      ClassInf.State ci_state,cistate1;
      
      /*For simple names */
    case (env,(path as Absyn.IDENT(name = _)),msg) /* msg flag Lookup of simple names */ 
      equation 
        (t,env_1) = lookupTypeInEnv(env, path);
      then
        (t,env_1);
      /*If we find a class definition 
	   that is a function with the same name then we implicitly instantiate that
	  function, look up the type. */  
    case (env,(path as Absyn.IDENT(name = _)),msg) local String s;
      equation 
        ((c as SCode.CLASS(id,_,encflag,SCode.R_FUNCTION(),_)),env_1) = lookupClass(env, path, false);
        env_2 = Inst.implicitFunctionTypeInstantiation(env_1, c);
        (t,env3) = lookupTypeInEnv(env_2, path);
      then
        (t,env3);
      /* Same for external functions */  
    case (env,(path as Absyn.IDENT(name = _)),msg)
      equation 
        ((c as SCode.CLASS(id,_,encflag,SCode.R_EXT_FUNCTION(),_)),env_1) = lookupClass(env, path, msg);
        env_2 = Inst.implicitFunctionTypeInstantiation(env_1, c);
        (t,env3) = lookupTypeInEnv(env_2, path);
      then
        (t,env3);

	/* Classes that are external objects. Implicityly instantiate to get type */
 case (env,(path as Absyn.IDENT(name = _)),msg) local String s;
      equation 
        (c ,env_1) = lookupClass(env, path, false);
        true = Inst.classIsExternalObject(c);
        //print("found class that is external object\n");
       (_,env_1,_,_,_) = Inst.instClass(env_1, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, 
          {}, false, Inst.TOP_CALL());
	   		//s = Env.printEnvStr(env_1);
        //print("instantiated external object2, env:");
        //print(s);
        //print("\n");
        (t,env_2) = lookupTypeInEnv(env_1, path);
      then
        (t,env_2);

        /* Lookup of qualified name when first part of name is not a package.*/ 
    case (env,Absyn.QUALIFIED(name = pack,path = path),msg) 
      equation 
        ((c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass(env, Absyn.IDENT(pack), false);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
         (env_2,cistate1) = Inst.partialInstClassIn(env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
   
        failure(ClassInf.valid(cistate1, SCode.R_PACKAGE()));
        (t,env_3) = lookupTypeInClass(env_2, c, path, true) "Has to do additional check for encapsulated classes, see rule below" ;
      then
        (t,env_3);
   
   	/* Same as above but first part of name is a package. */
    case (env,(p as Absyn.QUALIFIED(name = pack,path = path)),msg)
      equation 
        ((c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass(env, Absyn.IDENT(pack), msg);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
         (env_2,cistate1) = Inst.partialInstClassIn(env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
        ClassInf.valid(cistate1, SCode.R_PACKAGE());
        (c_1,env_3) = lookupTypeInClass(env_2, c, path, false) "Has NOT to do additional check for encapsulated classes, see rule above" ;
      then
        (c_1,env_3);

   	/* Error for class not found */
    case (env,path,true)
      equation 
        classname = Absyn.pathString(path);
        scope = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_ERROR, {classname,scope});
      then
        fail();
  end matchcontinue;
end lookupType;

protected function isPrimitive "function: isPrimitive
  author: PA
 
  Returns true if classname is any of the builtin classes:
  Real, Integer, String, Boolean
"
  input Absyn.Path inPath;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "Integer")) then true; 
    case (Absyn.IDENT(name = "Real")) then true; 
    case (Absyn.IDENT(name = "Boolean")) then true; 
    case (Absyn.IDENT(name = "String")) then true; 
    case (_) then false; 
  end matchcontinue;
end isPrimitive;

public function lookupClass "function: lookupClass
  
  Tries to find a specified class in an environment
  
  Arg1: The enviroment where to look
  Arg2: The path for the class
  Arg3: A Bool to control the output of error-messages. If it is true
        then it outputs a error message if the class is not found.
"
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input Boolean inBoolean;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm 
  (outClass,outEnv):=
  matchcontinue (inEnv,inPath,inBoolean)
    local
      Env.Frame f;
      SCode.Class c,c_1;
      list<Env.Frame> env,env_1,env2,env_2,env_3,env1,env4,env5;
      Absyn.Path path,ep,packp,p;
      String id,s,name,pack;
      Boolean msg,encflag,msgflag;
      SCode.Restriction restr;
      ClassInf.State ci_state,cistate1;
    case (env,(path as Absyn.IDENT(name = id)),msg) /* Builtin classes Integer, Real, String, Boolean can not be overridden
	 search top environment directly. */ 
      equation 
        true = isPrimitive(path);
        f = Env.topFrame(env);
        (c,env) = lookupClassInFrame(f, {f}, id, msg);
      then
        (c,env);
    case (env,path,msg)
      equation 
        true = isPrimitive(path);
        print("ERROR, primitive class not found on top env: ");
        s = Env.printEnvStr(env);
        print(s);
      then
        fail();
    case (env,(path as Absyn.IDENT(name = name)),msgflag)
      equation 
        ((c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClassInEnv(env, path, msgflag) "print \"lookup_class \" & print name  & print \"\\nenv:\" & Env.print_env_str env => s & print s & print \"\\n\" &" ;
      then
        (c,env_1);
    case (env,(p as Absyn.QUALIFIED(name = _)),msgflag)
      equation 
        SOME(ep) = Env.getEnvPath(env) "If we search for A1.A2....An.x while in scope A1.A2...An
	 , just search for x. Must do like this to ensure finite recursion" ;
        packp = Absyn.stripLast(p);
        true = ModUtil.pathEqual(ep, packp);
        id = Absyn.pathLastIdent(p);
        (c,env_1) = lookupClass(env, Absyn.IDENT(id), msgflag);
      then
        (c,env_1);
    case (env,(p as Absyn.QUALIFIED(name = pack,path = path)),msgflag) /* Qualified name in non package */ 
      equation 
        ((c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass(env, Absyn.IDENT(pack), msgflag);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        
        (env_2,cistate1) = Inst.partialInstClassIn(env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
          /*(_,env_2,_,cistate1,_,_) = Inst.instClassIn(env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet,
           ci_state, c, false/*FIXME:prot*/, {}, false, false);*/
        failure(ClassInf.valid(cistate1, SCode.R_PACKAGE()));
        (c_1,env_3) = lookupClass(env_2, path, msgflag) "Has to do additional check for encapsulated classes, see rule below" ;
      then
        (c_1,env_3);
    case (env,(p as Absyn.QUALIFIED(name = pack,path = path)),msgflag) /* Qualified names in package */ 
      equation 
        ((c as SCode.CLASS(id,_,encflag,restr,_)),env1) = lookupClass(env, Absyn.IDENT(pack), msgflag);
        env2 = Env.openScope(env1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id); 
        
        (env4,cistate1) = Inst.partialInstClassIn(env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
          /*(_,env4,_,cistate1,_,_) = Inst.instClassIn(env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet,
           ci_state, c, false/*FIXME:prot*/, {}, false, false);*/
        ClassInf.valid(cistate1, SCode.R_PACKAGE());
        (c_1,env5) = lookupClass(env4, path, msgflag) "Has NOT to do additional check for encapsulated classes, see rule above" ;
      then
        (c_1,env5);
    case (env,path,true)
      equation 
        s = Absyn.pathString(path) "print \"-lookup_class failed \" &" ;
        Debug.fprint("failtrace", "- lookup_class failed\n  - looked for ") "print s & print \"\\n\" & 	Env.print_env_str env => s & print s & print \"\\n\" & 	Env.print_env env & 	Print.get_string => str & print \"Env: \" & print str & print \"\\n\" & 	Print.print_buf \"#Error, class \" & Print.print_buf s & 	Print.print_buf \" not found.\\n\" &" ;
        //print("lookup class ");print(s);print("failed\n");
        Debug.fprint("failtrace", s);
        Debug.fprint("failtrace", "\n env:");
        s = Env.printEnvStr(env);
        //print("env:");print(s);
        Debug.fprint("failtrace", s);
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end lookupClass;

protected function lookupQualifiedImportedClassInEnv "function: lookupQualifiedImportedClassInEnv
  
  This function looks up imported class names on the qualified form: 
  import A.B;
"
  input Env.Env inEnv1;
  input Env.Env inEnv2;
  input Absyn.Path inPath3;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm 
  (outClass,outEnv):=
  matchcontinue (inEnv1,inEnv2,inPath3)
    local
      SCode.Class c,c_1;
      list<Env.Frame> env_1,env,fs,totenv,env2,env4,env_2;
      Option<String> sid;
      list<Env.Item> items,imps;
      String name,id,pack;
      Boolean encflag;
      SCode.Restriction restr;
      ClassInf.State ci_state;
      Absyn.Path path;
      Env.Frame f;
    case ((env as (Env.FRAME(class_1 = sid,list_4 = items) :: fs)),totenv,Absyn.IDENT(name = name)) /* Simple name */ 
      equation 
        (c,env_1) = lookupQualifiedImportedClassInFrame(items, totenv, name);
      then
        (c,env_1);
    case ((env as (Env.FRAME(class_1 = sid,list_4 = imps) :: fs)),totenv,Absyn.QUALIFIED(name = pack,path = path)) /* Qualified name */ 
      equation 
        ((c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupQualifiedImportedClassInFrame(imps, totenv, pack);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        (env4,_) = Inst.partialInstClassIn(env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
        (c_1,env_2) = lookupClass(env4, path, false);
      then
        (c_1,env_2);
    case ((f :: fs),env,id) /* Search next scope */ 
      local Absyn.Path id;
      equation 
        (c,env_1) = lookupQualifiedImportedClassInEnv(fs, env, id);
      then
        (c,env_1);
  end matchcontinue;
end lookupQualifiedImportedClassInEnv;

protected function lookupQualifiedImportedVarInFrame "function: lookupQualifiedImportedVarInFrame
  author: PA
  
  Looking up variables (constants) imported using qualified imports, 
  i.e. import Modelica.Constants.PI;
"
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
algorithm 
  (outAttributes,outType,outBinding):=
  matchcontinue (inEnvItemLst,inEnv,inIdent)
    local
      Env.Frame fr;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Binding bind;
      String id,ident,str;
      list<Env.Item> fs;
      list<Env.Frame> env;
      Exp.ComponentRef cref;
      Absyn.Path strippath,path;
      SCode.Class c2;
    case ((Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = Absyn.IDENT(name = id))) :: fs),env,ident) /* For imported simple name, e.g. A, not possible to assert 
	    sub-path package */ 
      equation 
        equality(id = ident);
        fr = Env.topFrame(env);
        (attr,ty,bind) = lookupVar({fr}, Exp.CREF_IDENT(ident,{}));
      then
        (attr,ty,bind);
    case ((Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = path)) :: fs),env,ident) /* For imported qualified name, e.g. A.B.C, assert A.B is package */ 
      equation 
        id = Absyn.pathLastIdent(path);
        equality(id = ident);
        fr = Env.topFrame(env);
        cref = Exp.pathToCref(path);
        (attr,ty,bind) = lookupVarInPackages({fr}, cref);
        strippath = Absyn.stripLast(path);
        (c2,_) = lookupClass({fr}, strippath, true);
        assertPackage(c2);
      then
        (attr,ty,bind);
    case ((Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = path)) :: fs),env,ident) /* importing qualified name, If not package, error */ 
      equation 
        id = Absyn.pathLastIdent(path);
        equality(id = ident);
        fr = Env.topFrame(env);
        cref = Exp.pathToCref(path);
        (attr,ty,bind) = lookupVarInPackages({fr}, cref);
        strippath = Absyn.stripLast(path);
        (c2,_) = lookupClass({fr}, strippath, true);
        failure(assertPackage(c2));
        str = Absyn.pathString(strippath);
        Error.addMessage(Error.IMPORT_PACKAGES_ONLY, {str});
      then
        fail();
    case ((Env.IMPORT(import_ = Absyn.NAMED_IMPORT(name = id,path = path)) :: fs),env,ident) /* Named imports */ 
      equation 
        equality(id = ident);
        fr = Env.topFrame(env);
        cref = Exp.pathToCref(path);
        (attr,ty,bind) = lookupVarInPackages({fr}, cref);
        strippath = Absyn.stripLast(path);
        (c2,_) = lookupClass({fr}, strippath, true);
        assertPackage(c2);
      then
        (attr,ty,bind);
    case ((Env.IMPORT(import_ = Absyn.NAMED_IMPORT(name = id,path = path)) :: fs),env,ident) /* Assert package for Named imports */ 
      equation 
        equality(id = ident);
        fr = Env.topFrame(env);
        cref = Exp.pathToCref(path);
        (attr,ty,bind) = lookupVarInPackages({fr}, cref);
        strippath = Absyn.stripLast(path);
        (c2,_) = lookupClass({fr}, strippath, true);
        failure(assertPackage(c2));
        str = Absyn.pathString(strippath);
        Error.addMessage(Error.IMPORT_PACKAGES_ONLY, {str});
      then
        fail();
    case ((_ :: fs),env,ident) /* Check next frame. */ 
      equation 
        (attr,ty,bind) = lookupQualifiedImportedVarInFrame(fs, env, ident);
      then
        (attr,ty,bind);
  end matchcontinue;
end lookupQualifiedImportedVarInFrame;

protected function moreLookupUnqualifiedImportedVarInFrame "function: moreLookupUnqualifiedImportedVarInFrame
  
  Helper function for lookup_unqualified_imported_var_in_frame. Returns 
  true if there are unqualified imports that matches a sought constant.
"
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inEnvItemLst,inEnv,inIdent)
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
    case ((Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident)
      equation 
        fr = Env.topFrame(env);
        ((c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass({fr}, path, false);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        ((f :: _),_) = Inst.partialInstClassIn(env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
        (_,_,_) = lookupVarInPackages({f}, Exp.CREF_IDENT(ident,{}));
      then
        true;
    case ((_ :: fs),env,ident)
      equation 
        res = moreLookupUnqualifiedImportedVarInFrame(fs, env, ident);
      then
        res;
    case ({},_,_) then false; 
  end matchcontinue;
end moreLookupUnqualifiedImportedVarInFrame;

protected function lookupUnqualifiedImportedVarInFrame "function: lookupUnqualifiedImportedVarInFrame
  
  Find a variable from an unqualified import locally in a frame
"
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
  output Boolean outBoolean;
algorithm 
  (outAttributes,outType,outBinding,outBoolean):=
  matchcontinue (inEnvItemLst,inEnv,inIdent)
    local
      Env.Frame fr,f;
      Exp.ComponentRef cref;
      SCode.Class c;
      String id,ident;
      Boolean encflag,more,unique;
      SCode.Restriction restr;
      list<Env.Frame> env_1,env2,env;
      ClassInf.State ci_state;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Binding bind;
      Absyn.Path path;
      list<Env.Item> fs;
    case ((Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident) /* unique */ 
      equation 
        fr = Env.topFrame(env);
        cref = Exp.pathToCref(path);
        ((c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass({fr}, path, false);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        (_,(f :: _),_,_,_,_) = Inst.instClassIn(env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}, false);
        (attr,ty,bind) = lookupVarInPackages({f}, Exp.CREF_IDENT(ident,{}));
        more = moreLookupUnqualifiedImportedVarInFrame(fs, env, ident);
        unique = boolNot(more);
      then
        (attr,ty,bind,unique);
    case ((_ :: fs),env,ident)
      equation 
        (attr,ty,bind,unique) = lookupUnqualifiedImportedVarInFrame(fs, env, ident);
      then
        (attr,ty,bind,unique);
  end matchcontinue;
end lookupUnqualifiedImportedVarInFrame;

protected function lookupQualifiedImportedClassInFrame "function: lookupQualifiedImportedClassInFrame
  
  Helper function to lookup_qualified_imported_class_in_env.
"
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm 
  (outClass,outEnv):=
  matchcontinue (inEnvItemLst,inEnv,inIdent)
    local
      Env.Frame fr;
      SCode.Class c,c2;
      list<Env.Frame> env_1,env;
      String id,ident,str;
      list<Env.Item> fs;
      Absyn.Path strippath,path;
    case ((Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = Absyn.IDENT(name = id))) :: fs),env,ident)
      equation 
        equality(id = ident) "For imported paths A, not possible to assert sub-path package" ;
        fr = Env.topFrame(env);
        (c,env_1) = lookupClass({fr}, Absyn.IDENT(id), true);
      then
        (c,env_1);
    case ((Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = path)) :: fs),env,ident)
      equation 
        id = Absyn.pathLastIdent(path) "For imported path A.B.C, assert A.B is package" ;
        equality(id = ident);
        fr = Env.topFrame(env);
        (c,env_1) = lookupClass({fr}, path, true);
        strippath = Absyn.stripLast(path);
        (c2,_) = lookupClass({fr}, strippath, true);
        assertPackage(c2);
      then
        (c,env_1);
    case ((Env.IMPORT(import_ = Absyn.QUAL_IMPORT(path = path)) :: fs),env,ident)
      equation 
        id = Absyn.pathLastIdent(path) "If not package, error" ;
        equality(id = ident);
        fr = Env.topFrame(env);
        (c,env_1) = lookupClass({fr}, path, true);
        strippath = Absyn.stripLast(path);
        (c2,_) = lookupClass({fr}, strippath, true);
        failure(assertPackage(c2));
        str = Absyn.pathString(strippath);
        Error.addMessage(Error.IMPORT_PACKAGES_ONLY, {str});
      then
        fail();
    case ((Env.IMPORT(import_ = Absyn.NAMED_IMPORT(name = id,path = path)) :: fs),env,ident)
      equation 
        equality(id = ident) "Named imports" ;
        fr = Env.topFrame(env);
        (c,env_1) = lookupClass({fr}, path, true) "	Print.print_buf \"NAMED IMPORT, top frame:\" & 
	Env.print_env {fr} &" ;
        strippath = Absyn.stripLast(path);
        (c2,_) = lookupClass({fr}, strippath, true);
        assertPackage(c2);
      then
        (c,env_1);
    case ((Env.IMPORT(import_ = Absyn.NAMED_IMPORT(name = id,path = path)) :: fs),env,ident)
      equation 
        equality(id = ident) "Assert package for Named imports" ;
        fr = Env.topFrame(env);
        (c,env_1) = lookupClass({fr}, path, true);
        strippath = Absyn.stripLast(path);
        (c2,_) = lookupClass({fr}, strippath, true);
        failure(assertPackage(c2));
        str = Absyn.pathString(strippath);
        Error.addMessage(Error.IMPORT_PACKAGES_ONLY, {str});
      then
        fail();
    case ((_ :: fs),env,ident)
      equation 
        (c,env_1) = lookupQualifiedImportedClassInFrame(fs, env, ident);
      then
        (c,env_1);
  end matchcontinue;
end lookupQualifiedImportedClassInFrame;

protected function moreLookupUnqualifiedImportedClassInFrame "function: moreLookupUnqualifiedImportedClassInFrame
  
  Helper function for lookup_unqualified_imported_class_in_frame
"
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inEnvItemLst,inEnv,inIdent)
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
    case ((Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident)
      equation 
        fr = Env.topFrame(env);
        ((c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass({fr}, path, false);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        ((f :: _),_) = Inst.partialInstClassIn(env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
        (_,_) = lookupClass({f}, Absyn.IDENT(ident), false);
      then
        true;
    case ((_ :: fs),env,ident)
      equation 
        res = moreLookupUnqualifiedImportedClassInFrame(fs, env, ident);
      then
        res;
    case ({},_,_) then false; 
  end matchcontinue;
end moreLookupUnqualifiedImportedClassInFrame;

protected function lookupUnqualifiedImportedClassInFrame "function: lookupUnqualifiedImportedClassInFrame
  
  Finds a class from an unqualified import locally in a frame
"
  input list<Env.Item> inEnvItemLst;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output SCode.Class outClass;
  output Env.Env outEnv;
  output Boolean outBoolean;
algorithm 
  (outClass,outEnv,outBoolean):=
  matchcontinue (inEnvItemLst,inEnv,inIdent)
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
    case ((Env.IMPORT(import_ = Absyn.UNQUAL_IMPORT(path = path)) :: fs),env,ident) /* unique */ 
      equation 
        fr = Env.topFrame(env);
        ((c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass({fr}, path, false);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        ((f :: fs_1),cistate1) = Inst.partialInstClassIn(env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
        (c_1,(f_1 :: _)) = lookupClass({f}, Absyn.IDENT(ident), false) "Restrict import to the imported scope only, not its parents..." ;
        more = moreLookupUnqualifiedImportedClassInFrame(fs, env, ident);
        unique = boolNot(more);
      then
        (c_1,(f_1 :: fs_1),unique);
    case ((_ :: fs),env,ident)
      equation 
        (c,env_1,unique) = lookupUnqualifiedImportedClassInFrame(fs, env, ident);
      then
        (c,env_1,unique);
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
      list<Env.Frame> env_1,env;
      Absyn.Path path;
    case (env,path)
      equation 
        (c,env_1) = lookupRecconstInEnv(env, path);
      then
        (c,env_1);
  end matchcontinue;
end lookupRecordConstructorClass;

public function completePath "function: completePath
 
  This function takes a type name and an env and looks up the class.
  Then it determines the full path for the type, such that it can be 
  looked up from any environment.
"
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output Absyn.Path outPath;
algorithm 
  outPath:=
  matchcontinue (inEnv,inPath)
    local
      list<Env.Frame> env,env_1;
      Absyn.Path path,path1,path_1;
      String id,pack;
    case (env,path)
      equation 
        (_,(Env.FRAME(NONE,_,_,_,_,_,_) :: _)) = lookupClass(env, path, true) "Class found on top level. Nothing to complete." ;
      then
        path;
    case (env,(path as Absyn.IDENT(name = _)))
      equation 
        (SCode.CLASS(id,_,_,_,_),env_1) = lookupClass(env, path, true);
        SOME(path1) = Env.getEnvPath(env_1);
        path_1 = Absyn.joinPaths(path1, path);
      then
        path_1;
    case (env,(path as Absyn.QUALIFIED(name = pack)))
      equation 
        (_,(Env.FRAME(NONE,_,_,_,_,_,_) :: _)) = lookupClass(env, Absyn.IDENT(pack), true);
      then
        path;
    case (env,(path as Absyn.QUALIFIED(name = pack)))
      equation 
        (SCode.CLASS(id,_,_,_,_),env_1) = lookupClass(env, path, true) "Absyn.IDENT(pack)" ;
        SOME(path1) = Env.getEnvPath(env_1);
        path_1 = Absyn.joinPaths(path1, Absyn.IDENT(id));
      then
        path_1;
    case (env,path) /* Debug.fprint(\"failtrace\", \"-complete_path failed\\n env=\") &
	Debug.fcall(\"failtrace\", Env.print_env, env) & 
	Debug.fprint(\"failtrace\", \"\\ntype: \")  &
	Absyn.path_string path => str & 
	Debug.fprint(\"failtrace\", str )&
	Debug.fprint(\"failtrace\", \"\\n\" ) */  then fail(); 
  end matchcontinue;
end completePath;

public function lookupVar "LS: when looking up qualified component reference, lookupVar only
checks variables when looking for the prefix, i.e. for Constants.PI
where Constants is a package and is implicitly instantiated, PI is not
found since Constants is not a variable (it is a type and/or class).

1) One option is to make it a variable and put it in the global frame.
2) Another option is to add a lookup rule that also looks in types.

Now implicitly instantiated packages exists both as a class and as a
type (see implicit_instantiation in Inst.rml). Is this correct?

lookup_var is modified to implement 2. Is this correct?

old lookup_var is changed to lookup_var_internal and a new lookup_var
is written, that first tests the old lookup_var, and if not found
looks in the types

  function: lookupVar
 
  This function tries to finds a variable in the environment
  
  Arg1: The environment to search in
  Arg2: The variable to search for
"
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
algorithm 
  (outAttributes,outType,outBinding):=
  matchcontinue (inEnv,inComponentRef)
    local
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Binding binding;
      list<Env.Frame> env;
      Exp.ComponentRef cref;
    case (env,cref) /* try the old lookup_var */ 
      equation 
        (attr,ty,binding) = lookupVarInternal(env, cref);
      then
        (attr,ty,binding);
    case (env,cref) /* then look in classes (implicitly instantiated packages)
	 */ 
      equation 
        (attr,ty,binding) = lookupVarInPackages(env, cref);
      then
        (attr,ty,binding);
    case (_,_) /* Debug.fprint(\"failtrace\",  \"- lookup_var failed\\n\") */  then fail(); 
  end matchcontinue;
end lookupVar;

protected function lookupVarInternal "function: lookupVarInternal
 
  Helper function to lookup_var. Searches the frames for variables.
"
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
algorithm 
  (outAttributes,outType,outBinding):=
  matchcontinue (inEnv,inComponentRef)
    local
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Binding binding;
      Option<String> sid;
      Env.BinTree ht;
      list<Env.Item> imps;
      list<Env.Frame> fs;
      Exp.ComponentRef ref;
    case ((Env.FRAME(class_1 = sid,list_2 = ht,list_4 = imps) :: fs),ref)
      equation 
        (attr,ty,binding) = lookupVarF(ht, ref);
      then
        (attr,ty,binding);
    case ((_ :: fs),ref)
      equation 
        (attr,ty,binding) = lookupVarInternal(fs, ref);
      then
        (attr,ty,binding);
  end matchcontinue;
end lookupVarInternal;

protected function lookupVarInPackages "function: lookupVarInPackages
 
  This function is called when a lookup of a variable with qualified names
  does not have the first element as a component, e.g. A.B.C is looked up 
  where A is not a component. This implies that A is a class, and this 
  class should be temporary instantiated, and the lookup should 
  be performed within that class. I.e. the function performs lookup of 
  variables in the class hierarchy.
 
  Arg1: The environment to search in
  Arg2: The variable to search for
"
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
algorithm 
  (outAttributes,outType,outBinding):=
  matchcontinue (inEnv,inComponentRef)
    local
      SCode.Class c;
      String n,id1,id;
      Boolean encflag;
      SCode.Restriction r;
      list<Env.Frame> env2,env3,env5,env,fs;
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
      // Lookup of enumeration variables
    case (env,Exp.CREF_QUAL(ident = id1,subscriptLst = {},componentRef = (id2 as Exp.CREF_IDENT(ident = _))))
      equation 
        ((c as SCode.CLASS(n,_,encflag,(r as SCode.R_ENUMERATION()),_)),env2) = lookupClass(env, Absyn.IDENT(id1), false) "Special case for looking up enumerations" ;
        env3 = Env.openScope(env2, encflag, SOME(n));
        ci_state = ClassInf.start(r, n);
        (_,env5,_,_,types,_) = Inst.instClassIn(env3, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}, false);
        (attr,ty,bind) = lookupVarInPackages(env5, id2);
      then
        (attr,ty,bind);
      // lookup of constants on form A.B in packages
    case (env,Exp.CREF_QUAL(ident = id,subscriptLst = {},componentRef = cref)) /* First part of name is a class. */ 
      equation 
        ((c as SCode.CLASS(n,_,encflag,r,_)),env2) = lookupClass(env, Absyn.IDENT(id), false);
        env3 = Env.openScope(env2, encflag, SOME(n));
        ci_state = ClassInf.start(r, n);
        (_,env5,_,_,types,_) = Inst.instClassIn(env3, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}, true);
        (attr,ty,bind) = lookupVarInPackages(env5, cref);
      then
        (attr,ty,bind);
    case (env,(cr as Exp.CREF_IDENT(ident = id,subscriptLst = sb))) local String str;
      equation 
        (attr,ty,bind) = lookupVarLocal(env, cr);
      then
        (attr,ty,bind);
    case ((env as (Env.FRAME(class_1 = sid,list_4 = items) :: _)),(cr as Exp.CREF_IDENT(ident = id,subscriptLst = sb)))
      equation 
        (attr,ty,bind) = lookupQualifiedImportedVarInFrame(items, env, id);
      then
        (attr,ty,bind);
    case ((env as (Env.FRAME(class_1 = sid,list_4 = items) :: _)),(cr as Exp.CREF_IDENT(ident = id,subscriptLst = sb)))
      equation 
        (attr,ty,bind,true) = lookupUnqualifiedImportedVarInFrame(items, env, id);
      then
        (attr,ty,bind);
    case ((env as (Env.FRAME(class_1 = sid,list_4 = items) :: _)),(cr as Exp.CREF_IDENT(ident = id,subscriptLst = sb)))
      equation 
        (attr,ty,bind,false) = lookupUnqualifiedImportedVarInFrame(items, env, id);
        Error.addMessage(Error.IMPORT_SEVERAL_NAMES, {id});
      then
        fail();
    case ((f :: fs),cr) /* Search parent scopes */ 
      equation 
         (attr,ty,bind) = lookupVarInPackages(fs, cr);
      then
        (attr,ty,bind);
    case (env,cr) /* Debug.fprint(\"failtrace\",  \"lookup_var_in_packages failed\\n exp:\" ) &
	Debug.fcall(\"failtrace\", Exp.print_component_ref, cr) &
	Debug.fprint(\"failtrace\", \"\\n\") */  then fail(); 
  end matchcontinue;
end lookupVarInPackages;

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
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
algorithm 
  (outAttributes,outType,outBinding):=
  matchcontinue (inEnv,inComponentRef)
    local
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Binding binding;
      Option<String> sid;
      Env.BinTree ht;
      list<Env.Frame> fs,env;
      Exp.ComponentRef ref;
    case ((Env.FRAME(class_1 = sid,list_2 = ht) :: fs),ref)
      equation 
        (attr,ty,binding) = lookupVarF(ht, ref);
      then
        (attr,ty,binding);
    case ((Env.FRAME(class_1 = SOME("$for loop scope$")) :: env),ref)
      equation 
        (attr,ty,binding) = lookupVarLocal(env, ref) "Exception, when in for loop scope allow search of next scope" ;
      then
        (attr,ty,binding);
  end matchcontinue;
end lookupVarLocal;

public function lookupIdentLocal "function: lookupIdentLocal
 
  Searches for a variable in the local scope.
"
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Types.Var outVar;
  output Option<tuple<SCode.Element, Types.Mod>> outTplSCodeElementTypesModOption;
  output Boolean outBoolean;
  output Env.Env outEnv;
algorithm 
  (outVar,outTplSCodeElementTypesModOption,outBoolean,outEnv):=
  matchcontinue (inEnv,inIdent)
    local
      Types.Var fv;
      Option<tuple<SCode.Element, Types.Mod>> c;
      Boolean i;
      list<Env.Frame> env;
      Option<String> sid;
      Env.BinTree ht;
      String id;
    case ((Env.FRAME(class_1 = sid,list_2 = ht) :: _),id) /* component environment */ 
      equation 
        (fv,c,i,env) = lookupVar2(ht, id);
      then
        (fv,c,i,env);
  end matchcontinue;
end lookupIdentLocal;

public function lookupIdent "function: lookupIdent
 
  Same as lookup_ident_local, except check all frames 
 
"
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output Types.Var outVar;
  output Option<tuple<SCode.Element, Types.Mod>> outTplSCodeElementTypesModOption;
  output Boolean outBoolean;
algorithm 
  (outVar,outTplSCodeElementTypesModOption,outBoolean):=
  matchcontinue (inEnv,inIdent)
    local
      Types.Var fv;
      Option<tuple<SCode.Element, Types.Mod>> c;
      Boolean i;
      Option<String> sid;
      Env.BinTree ht;
      String id;
      list<Env.Frame> rest;
    case ((Env.FRAME(class_1 = sid,list_2 = ht) :: _),id)
      equation 
        (fv,c,i,_) = lookupVar2(ht, id);
      then
        (fv,c,i);
    case ((_ :: rest),id)
      equation 
        (fv,c,i) = lookupIdent(rest, id);
      then
        (fv,c,i);
  end matchcontinue;
end lookupIdent;

public function lookupFunctionsInEnv "Function lookup
  function: lookupFunctionsInEnv
 
  Returns a list of types that the function has. 
 
"
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output list<Types.Type> outTypesTypeLst;
algorithm 
  outTypesTypeLst:=
  matchcontinue (inEnv,inPath)
    local
      Absyn.Path id,iid,path;
      Option<String> sid;
      Env.BinTree ht,httypes;
      list<tuple<Types.TType, Option<Absyn.Path>>> reslist,c1,c2,res;
      list<Env.Frame> env,fs,env_1,env2,env_2;
      String pack;
      SCode.Class c;
      Boolean encflag;
      SCode.Restriction restr;
      ClassInf.State ci_state,cistate1;
      Env.Frame f;
    case ({},id) then {}; 
    case (env,(iid as Absyn.IDENT(name = id)))
      local String id;
      equation 
        _ = Static.elabBuiltinHandler(id) "Check for builtin operators" ;
        Env.FRAME(sid,ht,httypes,_,_,_,_) = Env.topFrame(env);
        reslist = lookupFunctionsInFrame(ht, httypes, env, id);
      then
        reslist;
        
        /*Check for special builtin operators that can not be represented
	  in environment like for instance cardinality.*/
    case (env,(iid as Absyn.IDENT(name = id)))
      local String id;
      equation 
        _ = Static.elabBuiltinHandlerGeneric(id)  ;
        reslist = createGenericBuiltinFunctions(env, id);
      then
        reslist;
    case ((env as (Env.FRAME(class_1 = sid,list_2 = ht,list_3 = httypes) :: fs)),(iid as Absyn.IDENT(name = id)))
      local String id,s;
      equation 
        c1 = lookupFunctionsInFrame(ht, httypes, env, id);
        c2 = lookupFunctionsInEnv(fs, iid);
        reslist = listAppend(c1, c2);
      then
        reslist;
    case ((env as (Env.FRAME(class_1 = sid,list_2 = ht,list_3 = httypes) :: fs)),(iid as Absyn.QUALIFIED(name = pack,path = path)))
      local String id,s;
      equation 
        ((c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = lookupClass(env, Absyn.IDENT(pack), false) "For qualified function names, e.g. Modelica.Math.sin" ;
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
       (env_2,cistate1) = Inst.partialInstClassIn(env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
        reslist = lookupFunctionsInEnv(env_2, path);
      then 
        reslist;
   
    case ((f :: fs),id) /* Did not match. Continue */ 
      local list<tuple<Types.TType, Option<Absyn.Path>>> c;
      equation 
        c = lookupFunctionsInEnv(fs, id);
      then
        c;
    case (_,_)
      equation 
        Debug.fprintln("failtrace", "lookup_functions_in_env failed");
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
  output list<Types.Type> outTypesTypeLst;
algorithm 
  outTypesTypeLst:=
  matchcontinue (inEnv,inString)
    local list<Env.Frame> env;
    case (env,"cardinality") then {
          (
          Types.T_FUNCTION(
          {
          ("x",
          (Types.T_COMPLEX(ClassInf.CONNECTOR("$$"),{},NONE),NONE))},(Types.T_INTEGER({}),NONE)),NONE)};  /* function_name cardinality */ 
  end matchcontinue;
end createGenericBuiltinFunctions;

protected function lookupTypeInEnv "- Internal functions
  Type lookup
  function: lookupTypeInEnv
  
"
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output Types.Type outType;
  output Env.Env outEnv;
algorithm 
  (outType,outEnv):=
  matchcontinue (inEnv,inPath)
    local
      tuple<Types.TType, Option<Absyn.Path>> c;
      list<Env.Frame> env_1,env,fs;
      Option<String> sid;
      Env.BinTree ht,httypes;
      String id;
      Env.Frame f;
    case ((env as (Env.FRAME(class_1 = sid,list_2 = ht,list_3 = httypes) :: fs)),Absyn.IDENT(name = id))
      equation 
        (c,env_1) = lookupTypeInFrame(ht, httypes, env, id);
      then
        (c,env_1);
    case ((f :: fs),id)
      local Absyn.Path id;
      equation 
        (c,env_1) = lookupTypeInEnv(fs, id);
      then
        (c,(f :: env_1));
  end matchcontinue;
end lookupTypeInEnv;

protected function lookupTypeInFrame "function: lookupTypeInFrame
  
  Searches a frame for a type.
"
  input Env.BinTree inBinTree1;
  input Env.BinTree inBinTree2;
  input Env.Env inEnv3;
  input SCode.Ident inIdent4;
  output Types.Type outType;
  output Env.Env outEnv;
algorithm 
  (outType,outEnv):=
  matchcontinue (inBinTree1,inBinTree2,inEnv3,inIdent4)
    local
      tuple<Types.TType, Option<Absyn.Path>> t,ftype,ty;
      Env.BinTree ht,httypes;
      list<Env.Frame> env,cenv,env_1,env_2;
      String id,n;
      SCode.Class cdef;
      Absyn.Path fpath;
      list<Types.Var> varlst;
    case (ht,httypes,env,id) /* Classes and vars types */ 
      equation 
        Env.TYPE((t :: _)) = Env.treeGet(httypes, id, Env.myhash);
      then
        (t,env);
    case (ht,httypes,env,id)
      equation 
        Env.VAR(_,_,_,_) = Env.treeGet(ht, id, Env.myhash);
        Error.addMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id});
      then
        fail();
        /* Record constructor function*/
    case (ht,httypes,env,id)
      equation 
        Env.CLASS((cdef as SCode.CLASS(n,_,_,SCode.R_RECORD(),_)),_) = Env.treeGet(ht, id, Env.myhash) "Each time a record constructor function is looked up, this rule will create the function. An improvement (perhaps needing lot of code) is to add the function to the environment, which is returned from this function." ;
        fpath = Inst.makeFullyQualified(env, Absyn.IDENT(n));
        varlst = buildRecordConstructorVarlst(cdef, env);
        ftype = Types.makeFunctionType(fpath, varlst);
      then
        (ftype,env);
        /* Found function, instantiate to get type */
    case (ht,httypes,env,id)
      equation 
        Env.CLASS((cdef as SCode.CLASS(_,_,_,SCode.R_FUNCTION(),_)),cenv) = Env.treeGet(ht, id, Env.myhash);
        (env_1,_) = Inst.implicitFunctionInstantiation(cenv, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          cdef, {});
        (ty,env_2) = lookupTypeInEnv(env_1, Absyn.IDENT(id));
      then
        (ty,env_2);
        
        /* Found external function, instantiate to get type */
    case (ht,httypes,env,id)
      equation 
        Env.CLASS((cdef as SCode.CLASS(_,_,_,SCode.R_EXT_FUNCTION(),_)),cenv) = Env.treeGet(ht, id, Env.myhash) "If we found class that is external function" ;
        env_1 = Inst.implicitFunctionTypeInstantiation(cenv, cdef);
        (ty,env_2) = lookupTypeInEnv(env_1, Absyn.IDENT(id));
      then
        (ty,env_2);
  end matchcontinue;
end lookupTypeInFrame;

protected function lookupFunctionsInFrame "function: lookupFunctionsInFrame
  
  This actually only looks up the function name and find all
  corresponding types that have this function name.
  
"
  input Env.BinTree inBinTree1;
  input Env.BinTree inBinTree2;
  input Env.Env inEnv3;
  input SCode.Ident inIdent4;
  output list<Types.Type> outTypesTypeLst;
algorithm 
  outTypesTypeLst:=
  matchcontinue (inBinTree1,inBinTree2,inEnv3,inIdent4)
    local
      list<tuple<Types.TType, Option<Absyn.Path>>> tps;
      Env.BinTree ht,httypes;
      list<Env.Frame> env,cenv,env_1;
      String id,n;
      SCode.Class cdef;
      list<Types.Var> varlst;
      Absyn.Path fpath;
      tuple<Types.TType, Option<Absyn.Path>> ftype,t;
    case (ht,httypes,env,id) /* Classes and vars Types */ 
      equation 
        Env.TYPE(tps) = Env.treeGet(httypes, id, Env.myhash);
      then
        tps;
    case (ht,httypes,env,id)
      equation 
        Env.VAR(_,_,_,_) = Env.treeGet(ht, id, Env.myhash);
        Error.addMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id});
      then
        fail();
        
        /* Records, create record constructor function*/
    case (ht,httypes,env,id) 
      equation 
        Env.CLASS((cdef as SCode.CLASS(n,_,_,SCode.R_RECORD(),_)),cenv) = Env.treeGet(ht, id, Env.myhash);
        varlst = buildRecordConstructorVarlst(cdef, env);
        fpath = Inst.makeFullyQualified(cenv, Absyn.IDENT(n));
        ftype = Types.makeFunctionType(fpath, varlst);
      then
        {ftype};
        
        /* Found class that is function, instantiate to get type*/
    case (ht,httypes,env,id) local String s;
      equation 
        Env.CLASS((cdef as SCode.CLASS(_,_,_,SCode.R_FUNCTION(),_)),cenv) = Env.treeGet(ht, id, Env.myhash) "If found class that is function." ;
        env_1 = Inst.implicitFunctionTypeInstantiation(cenv, cdef);
        tps = lookupFunctionsInEnv(env_1, Absyn.IDENT(id)); 
      then
        tps;
        
        /* Found class that is external function, instantiate to get type */
    case (ht,httypes,env,id)
      equation 
        Env.CLASS((cdef as SCode.CLASS(_,_,_,SCode.R_EXT_FUNCTION(),_)),cenv) = Env.treeGet(ht, id, Env.myhash) "If found class that is external function." ;
        env_1 = Inst.implicitFunctionTypeInstantiation(cenv, cdef);
        tps = lookupFunctionsInEnv(env_1, Absyn.IDENT(id));
      then
        tps;
        
     /* Found class that is is external object*/
     case (ht,httypes,env,id)  
        local String s;
        equation
          Env.CLASS(cdef,cenv) = Env.treeGet(ht, id, Env.myhash);
	        true = Inst.classIsExternalObject(cdef);
	        //print("found class that is external object\n");
	        (_,env_1,_,t,_) = Inst.instClass(cenv, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, cdef, 
         	 {}, false, Inst.TOP_CALL());
          (t,_) = lookupTypeInEnv(env_1, Absyn.IDENT(id));
           //s = Types.unparseType(t);
         	 //print("type :");print(s);print("\n");
       then
        {t};  
  end matchcontinue;
end lookupFunctionsInFrame;

protected function lookupRecconstInEnv "function: lookupRecconstInEnv
  
  Helper function to lookup_record_constructor_class. Searches
  The environment for record constructors.
  
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
      list<Env.Frame> env,fs;
      Option<String> sid;
      Env.BinTree ht;
      list<Env.Item> imps;
      String id;
      Env.Frame f;
    case ((env as (Env.FRAME(class_1 = sid,list_2 = ht,list_4 = imps) :: fs)),Absyn.IDENT(name = id))
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

protected function lookupRecconstInFrame "function: lookupRecconstInFrame
 
  This function lookups the implicit record constructor class (function) 
  of a record in a frame
"
  input Env.BinTree inBinTree;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm 
  (outClass,outEnv):=
  matchcontinue (inBinTree,inEnv,inIdent)
    local
      Env.BinTree ht;
      list<Env.Frame> env;
      String id;
      SCode.Class cdef;
    case (ht,env,id)
      equation 
        Env.VAR(_,_,_,_) = Env.treeGet(ht, id, Env.myhash);
        Error.addMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id});
      then
        fail();
    case (ht,env,id)
      equation 
        Env.CLASS((cdef as SCode.CLASS(_,_,_,SCode.R_RECORD(),_)),_) = Env.treeGet(ht, id, Env.myhash);
        cdef = buildRecordConstructorClass(cdef, env);
      then
        (cdef,env);
  end matchcontinue;
end lookupRecconstInFrame;

protected function buildRecordConstructorClass "function: buildRecordConstructorClass
  
  Creates the record constructor class, i.e. a function, from the record
  class given as argument.
"
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
    case ((cl as SCode.CLASS(name = id,restricion = restr,parts = SCode.PARTS(elementLst = elts))),env) /* record class function class */ 
      equation 
        funcelts = buildRecordConstructorElts(elts, env);
        reselt = buildRecordConstructorResultElt(elts, id, env);
      then
        SCode.CLASS(id,false,false,SCode.R_FUNCTION(),
          SCode.PARTS((reselt :: funcelts),{},{},{},{},NONE));
  end matchcontinue;
end buildRecordConstructorClass;

protected function buildRecordConstructorElts "function: buildRecordConstructorElts
  
  Helper function to build_record_constructor_class. Creates the elements
  of the function class.
"
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
      Boolean fl,repl,prot,f;
      list<Absyn.Subscript> d;
      SCode.Accessibility ac;
      SCode.Variability var;
      Absyn.Direction dir;
      Absyn.Path tp;
      SCode.Mod mod;
      Option<Absyn.Path> bc;
      Option<Absyn.Comment> comment;
      list<Env.Frame> env;
    case (((comp as SCode.COMPONENT(component = id,final_ = fl,replaceable_ = repl,protected_ = prot,attributes = SCode.ATTR(arrayDim = d,flow_ = f,RW = ac,parameter_ = var,input_ = dir),type_ = tp,mod = mod,baseclass = bc,this = comment)) :: rest),env)
      equation 
        res = buildRecordConstructorElts(rest, env);
      then
        (SCode.COMPONENT(id,fl,repl,prot,SCode.ATTR(d,f,ac,var,Absyn.INPUT()),tp,
          mod,bc,comment) :: res);
    case ({},_) then {}; 
  end matchcontinue;
end buildRecordConstructorElts;

protected function buildRecordConstructorResultElt "function: buildRecordConstructorResultElt
  
  This function builds the result element of a record constructor function, 
  i.e. the returned variable
  
"
  input list<SCode.Element> elts;
  input SCode.Ident id;
  input Env.Env env;
  output SCode.Element outElement;
  list<SCode.SubMod> submodlst;
algorithm 
  submodlst := buildRecordConstructorResultMod(elts);
  outElement := SCode.COMPONENT("result",false,false,false,
          SCode.ATTR({},false,SCode.RW(),SCode.VAR(),Absyn.OUTPUT()),Absyn.IDENT(id),SCode.MOD(false,Absyn.NON_EACH(),submodlst,NONE),
          NONE,NONE);
end buildRecordConstructorResultElt;

protected function buildRecordConstructorResultMod "function: buildRecordConstructorResultMod
 
  This function builds up the modification list for the output element of a record constructor.
  Example: 
    record foo
       Real x;
       String y;
       end foo;
   => modifier list become \'result.x=x, result.y=y\'
"
  input list<SCode.Element> inSCodeElementLst;
  output list<SCode.SubMod> outSCodeSubModLst;
algorithm 
  outSCodeSubModLst:=
  matchcontinue (inSCodeElementLst)
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
          SOME(Absyn.CREF(Absyn.CREF_IDENT(id,{})))))},NONE)) :: restmod);
    case ({}) then {}; 
  end matchcontinue;
end buildRecordConstructorResultMod;

protected function buildRecordConstructorVarlst "function: buildRecordConstructorVarlst
 
  This function takes a class  (`SCode.Class\') which holds a definition 
  of a record and builds a list of variables of the record used for 
  constructing a record constructor function.
"
  input SCode.Class inClass;
  input Env.Env inEnv;
  output list<Types.Var> outTypesVarLst;
algorithm 
  outTypesVarLst:=
  matchcontinue (inClass,inEnv)
    local
      list<Types.Var> inputvarlst;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      SCode.Class cl;
      list<SCode.Element> elts;
      list<Env.Frame> env;
    case ((cl as SCode.CLASS(parts = SCode.PARTS(elementLst = elts))),env)
      equation 
        inputvarlst = buildVarlstFromElts(elts, env);
        (_,_,_,ty,_) = Inst.instClass(env, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, cl, 
          {}, true, Inst.TOP_CALL()) "FIXME: impl" ;
      then
        (Types.VAR("result",
          Types.ATTR(false,SCode.RW(),SCode.VAR(),Absyn.OUTPUT()),false,ty,Types.UNBOUND()) :: inputvarlst);
    case (_,_)
      equation 
        Debug.fprint("failtrace", "build_record_constructor_varlst failed\n");
      then
        fail();
  end matchcontinue;
end buildRecordConstructorVarlst;

protected function buildVarlstFromElts "function: buildVarlstFromElts
  
  Helper function to build_record_constructor_varlst
"
  input list<SCode.Element> inSCodeElementLst;
  input Env.Env inEnv;
  output list<Types.Var> outTypesVarLst;
algorithm 
  outTypesVarLst:=
  matchcontinue (inSCodeElementLst,inEnv)
    local
      list<Types.Var> vars;
      Types.Var var;
      SCode.Element comp;
      list<SCode.Element> rest;
      list<Env.Frame> env;
    case (((comp as SCode.COMPONENT(component = _)) :: rest),env)
      equation 
        vars = buildVarlstFromElts(rest, env);
        var = Inst.instRecordConstructorElt(env, comp, true) "P.A Here we need to do a lookup of the type. Therefore we need the env passed along from lookup_xxxx function. FIXME: impl" ;
      then
        (var :: vars);
    case ({},_) then {}; 
    case (_,_) /* Debug.fprint(\"failtrace\", \"- build_varlst_from_elts failed!\\n\") */  then fail(); 
  end matchcontinue;
end buildVarlstFromElts;

public function isInBuiltinEnv "Class lookup
  function: isInBuiltinEnv
 
  Returns true if function can be found in the builtin environment.
"
  input Absyn.Path inPath;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inPath)
    local
      list<Env.Frame> i_env;
      Absyn.Path path;
    case (path)
      equation 
        i_env = Builtin.initialEnv();
        {} = lookupFunctionsInEnv(i_env, path);
      then
        false;
    case (path)
      equation 
        i_env = Builtin.initialEnv();
        _ = lookupFunctionsInEnv(i_env, path);
      then
        true;
    case (path)
      equation 
        Debug.fprintln("failtrace", "is_in_builtin_env failed");
      then
        fail();
  end matchcontinue;
end isInBuiltinEnv;

protected function lookupClassInEnv "function: lookupClassInEnv
  
  Helper function to lookup_class. Searches the environment for the class.
"
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input Boolean inBoolean;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm 
  (outClass,outEnv):=
  matchcontinue (inEnv,inPath,inBoolean)
    local
      SCode.Class c;
      list<Env.Frame> env_1,env,fs,i_env;
      Env.Frame frame,f;
      String id,sid,scope;
      Boolean msg,msgflag;
      Absyn.Path aid;
    case ((env as (frame :: fs)),Absyn.IDENT(name = id),msg) /* msg */ 
      equation 
        (c,env_1) = lookupClassInFrame(frame, (frame :: fs), id, msg) "print \"looking in env for \" & print id & print \"\\n\" &" ;
      then
        (c,env_1);
    case ((env as (Env.FRAME(class_1 = SOME(sid),encapsulated_7 = true) :: fs)),(aid as Absyn.IDENT(name = id)),_)
      equation 
        equality(id = sid) "Special case if looking up the class that -is- encapsulated. That must be allowed." ;
        (c,env) = lookupClassInEnv(fs, aid, true);
      then
        (c,env);
    case ((env as (Env.FRAME(class_1 = SOME(sid),encapsulated_7 = true) :: fs)),(aid as Absyn.IDENT(name = id)),true) /* lookup stops at encapsulated classes except for builtin
	    scope, if not found in builtin scope, error */ 
      equation 
        i_env = Builtin.initialEnv();
        failure((_,_) = lookupClassInEnv(i_env, aid, false));
        scope = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_ERROR, {id,scope});
      then
        fail();
    case ((Env.FRAME(class_1 = sid,encapsulated_7 = true) :: fs),(aid as Absyn.IDENT(name = id)),false) /* no error msg if msg = false */ 
      local Option<String> sid;
      equation 
        i_env = Builtin.initialEnv();
        failure((_,_) = lookupClassInEnv(i_env, aid, false));
      then
        fail();
    case ((Env.FRAME(class_1 = sid,encapsulated_7 = true) :: fs),(aid as Absyn.IDENT(name = id)),msgflag) /* lookup stops at encapsulated classes, except for builtin scope */ 
      local Option<String> sid;
      equation 
        i_env = Builtin.initialEnv();
        (c,env_1) = lookupClassInEnv(i_env, aid, msgflag);
      then
        (c,env_1);
    case (((f as Env.FRAME(class_1 = sid,encapsulated_7 = false)) :: fs),id,msgflag) /* if not found and not encapsulated, look in next enclosing scope */ 
      local
        Option<String> sid;
        Absyn.Path id;
      equation 
        (c,env_1) = lookupClassInEnv(fs, id, msgflag);
      then
        (c,env_1);
  end matchcontinue;
end lookupClassInEnv;

protected function lookupTypeInClass "function: lookupTypeInClass
 
  This function looks up an type inside a class. The outer class can be 
  a package. Environment is passed along in case it needs to be modified.
  bool determines whether we restrict lookup for encapsulated class (true).
   
"
  input Env.Env inEnv;
  input SCode.Class inClass;
  input Absyn.Path inPath;
  input Boolean inBoolean;
  output Types.Type outType;
  output Env.Env outEnv;
algorithm 
  (outType,outEnv):=
  matchcontinue (inEnv,inClass,inPath,inBoolean)
    local
      tuple<Types.TType, Option<Absyn.Path>> tp,t;
      list<Env.Frame> env_1,env,env_2,env3,env2,env5,env1,env4;
      SCode.Class cdef,c;
      Absyn.Path classname,p1,path;
      String id,c1,str,cname;
      Boolean encflag;
      SCode.Restriction restr;
      ClassInf.State ci_state;
    case (env,cdef,(classname as Absyn.IDENT(name = _)),_)
      equation 
        (tp,env_1) = lookupTypeInEnv(env, classname) ", true" ;
         /* , true encapsulated does not matter, _ */ 
      then
        (tp,env_1);
    case (env,cdef,(classname as Absyn.IDENT(name = _)),_) local String s;
      equation 
        ((c as SCode.CLASS(_,_,_,SCode.R_FUNCTION(),_)),env_1) = lookupClassInEnv(env, classname, false) "If not found, look for classdef that is function and instantiate." ;
        env_2 = Inst.implicitFunctionTypeInstantiation(env_1, c);
        //s = Env.printEnvStr(env_2);
        //print("env=");print(s);print("\n");
        (t,env3) = lookupTypeInEnv(env_2, classname);
        
      then
        (t,env3);
    case (env,cdef,(classname as Absyn.IDENT(name = _)),_)
      equation 
        ((c as SCode.CLASS(_,_,_,SCode.R_EXT_FUNCTION(),_)),env_1) = lookupClassInEnv(env, classname, false) "If not found, look for classdef that is external function and instantiate." ;
        env_2 = Inst.implicitFunctionTypeInstantiation(env_1, c);
        (t,env3) = lookupTypeInEnv(env_2, classname);
       then
        (t,env3);
    case (env,cdef,Absyn.QUALIFIED(name = c1,path = p1),true /* true means here encapsulated */)
      equation 
        ((c as SCode.CLASS(id,_,(encflag as true),restr,_)),env) = lookupClassInEnv(env, Absyn.IDENT(c1), false) "Restrict lookup to encapsulated elements only" ;
        env2 = Env.openScope(env, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        (_,env3,_,_,_,_) = Inst.instClassIn(env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}, true);
        (t,env5) = lookupTypeInClass(env3, c, p1, false);
      then
        (t,env5);
    case (env,cdef,(path as Absyn.QUALIFIED(name = c1,path = p1)),true)
      equation 
        ((c as SCode.CLASS(id,_,(encflag as false),restr,_)),env) = lookupClassInEnv(env, Absyn.IDENT(c1), false) "Restrict lookup to encapsulated elements only" ;
        str = Absyn.pathString(path);
        Error.addMessage(Error.LOOKUP_ENCAPSULATED_RESTRICTION_VIOLATION, {str});
      then
        fail();
    case (env,cdef,Absyn.QUALIFIED(name = c1,path = p1),false)
      equation 
        ((c as SCode.CLASS(id,_,encflag,restr,_)),env1) = lookupClassInEnv(env, Absyn.IDENT(c1), false) "Lookup not restricted to encapsulated elts. only" ;
        env2 = Env.openScope(env1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        (_,env4,_,_,_,_) = Inst.instClassIn(env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}, true) "	Print.print_buf \"instanitating class \" &
	Print.print_buf id &
	Print.print_buf \" in envpath:\\n\" &
	Env.print_env_path(env2\') &
	Print.print_buf \"\\n\" &" ;
        (t,env5) = lookupTypeInClass(env4, c, p1, false);
      then
        (t,env5);
    case (_,SCode.CLASS(name = cname),path,_) /* Debug.fprint(\"failtrace\",cname) &
	Debug.fprint(\"failtrace\", \"\\n  - looked for: \") & Absyn.path_string path => s & 
	Debug.fprint(\"failtrace\", s) & 
	Debug.fprint(\"failtrace\", \"\\n\") */  then fail(); 
  end matchcontinue;
end lookupTypeInClass;

protected function lookupClassInFrame "function: lookupClassInFrame
  
  Search for a class within one frame. 
"
  input Env.Frame inFrame;
  input Env.Env inEnv;
  input SCode.Ident inIdent;
  input Boolean inBoolean;
  output SCode.Class outClass;
  output Env.Env outEnv;
algorithm 
  (outClass,outEnv):=
  matchcontinue (inFrame,inEnv,inIdent,inBoolean)
    local
      SCode.Class c;
      list<Env.Frame> env,totenv,bcframes,env_1;
      Option<String> sid;
      Env.BinTree ht;
      String id,name;
      list<Env.Item> items;
    case (Env.FRAME(class_1 = sid,list_2 = ht),totenv,id,_)
      equation 
        Env.CLASS(c,env) = Env.treeGet(ht, id, Env.myhash) "print \"looking for class \" & print id & print \" in frame\\n\" & 	& print \"found \" & print id & print \"\\n\"" ;
      then
        (c,totenv);
    case (Env.FRAME(class_1 = sid,list_2 = ht),_,id,true)
      equation 
        Env.VAR(_,_,_,_) = Env.treeGet(ht, id, Env.myhash);
        Error.addMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id});
      then
        fail();
    case (Env.FRAME(list_5 = (bcframes as (_ :: _))),totenv,name,_) /* Search base classes */ 
      equation 
        (c,env) = lookupClass(bcframes, Absyn.IDENT(name), false) "print \"Searching baseclasses for \" & print name & print \"\\n\" & 
	Env.print_env_str bcframes => s & print \"env:\" & print s & print \"\\n\" &" ;
      then
        (c,env);
    case (Env.FRAME(class_1 = sid,list_4 = items),totenv,name,_)
      equation 
        (c,env_1) = lookupQualifiedImportedClassInFrame(items, totenv, name);
      then
        (c,env_1);
    case (Env.FRAME(class_1 = sid,list_4 = items),totenv,name,_)
      equation 
        (c,env_1,true) = lookupUnqualifiedImportedClassInFrame(items, totenv, name) "unique" ;
      then
        (c,env_1);
    case (Env.FRAME(class_1 = sid,list_4 = items),totenv,name,_)
      equation 
        (c,env_1,false) = lookupUnqualifiedImportedClassInFrame(items, totenv, name) "unique" ;
        Error.addMessage(Error.IMPORT_SEVERAL_NAMES, {name});
      then
        fail();
  end matchcontinue;
end lookupClassInFrame;

protected function lookupVar2 "function: lookupVar2
  
  Helper function to lookup_var_f and lookup_ident.
  
"
  input Env.BinTree inBinTree;
  input SCode.Ident inIdent;
  output Types.Var outVar;
  output Option<tuple<SCode.Element, Types.Mod>> outTplSCodeElementTypesModOption;
  output Boolean outBoolean;
  output Env.Env outEnv;
algorithm 
  (outVar,outTplSCodeElementTypesModOption,outBoolean,outEnv):=
  matchcontinue (inBinTree,inIdent)
    local
      Types.Var fv;
      Option<tuple<SCode.Element, Types.Mod>> c;
      Boolean i;
      list<Env.Frame> env;
      Env.BinTree ht;
      String id;
    case (ht,id)
      equation 
        Env.VAR(fv,c,i,env) = Env.treeGet(ht, id, Env.myhash);
      then
        (fv,c,i,env);
  end matchcontinue;
end lookupVar2;

protected function checkSubscripts "function: checkSubscripts
 
  This function checks a list of subscripts agains type, and removes
  dimensions from the type according to the subscripting.
"
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
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(sz)),arrayType = t),_),(Exp.INDEX(exp = _) :: ys)) /* HJ: Subscrits needn\'t be constant. No range-checking can
	       be done */ 
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
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(sz)),arrayType = t),_),(Exp.SLICE(exp = _) :: ys))
      equation 
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = NONE),arrayType = t),_),(Exp.SLICE(exp = _) :: ys))
      equation 
        t_1 = checkSubscripts(t, ys);
      then
        t_1;
    case (t,s)
      equation 
        Debug.fprint("failtrace", "- check_subscripts failed ( ");
        Debug.fcall("failtrace", Types.printType, t);
        Debug.fprint("failtrace", ")\n");
      then
        fail();
  end matchcontinue;
end checkSubscripts;

protected function lookupInVar "function: lookupInVar
  
  Searches for the rest of a qualified variable when first part of
  variable name has been found.
"
  input Types.Type inType;
  input Exp.ComponentRef inComponentRef;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
algorithm 
  (outAttributes,outType,outBinding):=
  matchcontinue (inType,inComponentRef)
    local
      Boolean fl;
      SCode.Accessibility acc;
      SCode.Variability vt;
      Absyn.Direction di;
      tuple<Types.TType, Option<Absyn.Path>> ty_1,ty_2,ty,ty_3;
      Types.Binding binding;
      String id;
      list<Exp.Subscript> ss;
      Types.Attributes attr;
      Exp.ComponentRef vs;
    case (ty,Exp.CREF_IDENT(ident = id,subscriptLst = ss)) /* Public components */ 
      equation 
        (Types.VAR(_,Types.ATTR(fl,acc,vt,di),false,ty_1,binding)) = Types.lookupComponent(ty, id);
        ty_2 = checkSubscripts(ty_1, ss);
      then
        (Types.ATTR(fl,acc,vt,di),ty_2,binding);
    case (ty,Exp.CREF_IDENT(ident = id,subscriptLst = ss)) /* Protected components */ 
      equation 
        (Types.VAR(_,_,true,_,_)) = Types.lookupComponent(ty, id);
        Error.addMessage(Error.REFERENCE_PROTECTED, {id});
      then
        fail();
    case (ty,Exp.CREF_QUAL(ident = id,subscriptLst = ss,componentRef = vs))
      equation 
        (Types.VAR(_,Types.ATTR(fl,acc,vt,di),_,ty_1,_)) = Types.lookupComponent(ty, id);
        ty_2 = checkSubscripts(ty_1, ss);
        (attr,ty_3,binding) = lookupInVar(ty_2, vs);
      then
        (attr,ty_3,binding);
    case (_,_) /* Debug.fprint(\"failtrace\", \"- lookup_in_var failed\\n\") */  then fail(); 
  end matchcontinue;
end lookupInVar;

protected function lookupVarF "function: lookupVarF
 
  This function looks in a frame to find a declared variable.  If
  the name being looked up is qualified, the first part of the name
  is looked up, and `lookup_in_var\' is used to for further lookup in
  the result of that lookup.
"
  input Env.BinTree inBinTree;
  input Exp.ComponentRef inComponentRef;
  output Types.Attributes outAttributes;
  output Types.Type outType;
  output Types.Binding outBinding;
algorithm 
  (outAttributes,outType,outBinding):=
  matchcontinue (inBinTree,inComponentRef)
    local
      String n,id;
      Boolean f;
      SCode.Accessibility acc;
      SCode.Variability vt;
      Absyn.Direction di;
      tuple<Types.TType, Option<Absyn.Path>> ty,ty_1;
      Types.Binding bind,binding;
      Env.BinTree ht;
      list<Exp.Subscript> ss;
      list<Env.Frame> compenv;
      Types.Attributes attr;
      Exp.ComponentRef ids;
    case (ht,Exp.CREF_IDENT(ident = id,subscriptLst = ss))
      equation 
        (Types.VAR(n,Types.ATTR(f,acc,vt,di),_,ty,bind),_,_,_) = lookupVar2(ht, id);
        ty_1 = checkSubscripts(ty, ss);
      then
        (Types.ATTR(f,acc,vt,di),ty_1,bind);
    case (ht,Exp.CREF_QUAL(ident = id,subscriptLst = ss,componentRef = ids)) /* Qualified variables looked up through component environment. */ 
      equation 
        (Types.VAR(n,Types.ATTR(f,acc,vt,di),_,ty,bind),_,_,compenv) = lookupVar2(ht, id);
        (attr,ty,binding) = lookupVar(compenv, ids);
      then
        (attr,ty,binding);
  end matchcontinue;
end lookupVarF;

protected function assertPackage "function: assertPackage
  
  This function checks that a class definition is a package.  This
  breaks the everything-can-be-generalized-to-class principle, since
  it requires that the keyword `package\' is used in the package file.
"
  input SCode.Class inClass;
algorithm 
  _:=
  matchcontinue (inClass)
    case SCode.CLASS(restricion = SCode.R_PACKAGE()) then ();  /* Break the generalize-to-class rule */ 
  end matchcontinue;
end assertPackage;
end Lookup;

