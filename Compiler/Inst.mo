package Inst "
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

  
  file:	 Inst.rml
  module:      Inst
  description: Model instantiation
 
  RCS: $Id$
 
  This module is responsible for instantiation of Modelica
   models. The instantation is the process of instantiating model
  components, flattening inheritance and generating equations from
  connect statements.
  The instantiation process takes Modelica AST as defined in SCode
  and produces variables and equations and algorithms, etc. as
  defined in DAE.
  
  This module uses \'Lookup\' to lookup classes and variables from the
  environment defined in \'Env\'. It uses \'Connect\' for generating equations from
  connect statements. The type system defined in \'Types\' is used for
  variable instantiation and type . \'Mod\' is used for modifiers and
  merging of modifiers. 
  
  There are basically four different ways/granularities of instantiation.
  1. Using partial_inst_class_in which only instantiates class definitions.
     This function is used for looking up class definitions in e.g. packages.
     For example, if looking up the class A.B.C, a new scope is opened and 
     A is partially instantiated in that scope using partial_inst_class_in.
 
  2. Function implicit instantiation. is the last argument of type bool to 
     inst_class_in. It is needed since instantiation of functions is needed 
     to generate code for functions and there are cases where such 
     instantiations differ 
     from standard function instantiation. For example
     function foo
       input Real x{:};
       ...
     end foo;
     should be possible to instantiate even though the dimension size of x is
     not known.
 
  3. Implicit instantiation controlled by the next last argument to 
     inst_class_in. 
     This is also needed, when a DAE should not be generated. 
     It is not clear when this is needed, perhaps it can be removed in the 
     future.
  4. Fu"

public import OpenModelica.Compiler.ClassInf;

public import OpenModelica.Compiler.Connect;

public import OpenModelica.Compiler.DAE;

public import OpenModelica.Compiler.Env;

public import OpenModelica.Compiler.Exp;

public import OpenModelica.Compiler.SCode;

public import OpenModelica.Compiler.Mod;

public import OpenModelica.Compiler.Prefix;

public import OpenModelica.Compiler.Types;

public import OpenModelica.Compiler.Absyn;

public 
type Prefix = Prefix.Prefix "
  These type aliases are introduced to make the code a little more
  readable.
" ;

public 
type Mod = Types.Mod;

public 
type Ident = Exp.Ident;

public 
type Env = Env.Env;

public 
uniontype CallingScope "Calling scope is used to determine when unconnected flow variables 
    should be set to zero."
  record TOP_CALL end TOP_CALL;

  record INNER_CALL end INNER_CALL;

end CallingScope;

public 
type InstDims = list<Exp.Subscript>;

public 
uniontype Initial "Intial is used in functions for instantiating equations to 
    specify if they are initial or not.
"
  record INITIAL end INITIAL;

  record NON_INITIAL end NON_INITIAL;

end Initial;

public 
uniontype DimExp
  record DIMINT
    Integer integer;
  end DIMINT;

  record DIMEXP
    Exp.Subscript subscript;
    Option<Exp.Exp> expExpOption;
  end DIMEXP;

end DimExp;

protected import OpenModelica.Compiler.System;

protected import OpenModelica.Compiler.Debug;

protected import OpenModelica.Compiler.Interactive;

protected import OpenModelica.Compiler.Util;

protected import OpenModelica.Compiler.Algorithm;

protected import OpenModelica.Compiler.Builtin;

protected import OpenModelica.Compiler.Dump;

protected import OpenModelica.Compiler.Lookup;

protected import OpenModelica.Compiler.Static;

protected import OpenModelica.Compiler.Values;

protected import OpenModelica.Compiler.Print;

protected import OpenModelica.Compiler.Ceval;

protected import OpenModelica.Compiler.Error;

protected import OpenModelica.Compiler.ErrorExt;

protected constant String forScopeName="$for loop scope$" "adrpo -- not used
with \"System.rml\"
with \"RTOpts.rml\"
with \"ModUtil.rml\"
" ;

protected function printDims "function: printDims
  
  Print DimExp list
"
  input list<DimExp> inDimExpLst;
algorithm 
  _:=
  matchcontinue (inDimExpLst)
    local
      DimExp x;
      list<DimExp> xs;
    case ((x :: xs))
      equation 
        printDim({SOME(x)});
        printDims(xs);
      then
        ();
    case ({}) then (); 
  end matchcontinue;
end printDims;

public function newIdent "function: newIdent
 
  This function creates a new, unique identifer.  The same name is
  never returned twice.
"
  output Exp.ComponentRef outComponentRef;
  Integer i;
  String is,s;
algorithm 
  i := tick();
  is := intString(i);
  s := stringAppend("__TMP__", is);
  outComponentRef := Exp.CREF_IDENT(s,{});
end newIdent;

protected function select "function: select
 
  This utility function selects one of two objects depending on a
  boolean variable.
"
  input Boolean inBoolean1;
  input Type_a inTypeA2;
  input Type_a inTypeA3;
  output Type_a outTypeA;
  replaceable type Type_a;
algorithm 
  outTypeA:=
  matchcontinue (inBoolean1,inTypeA2,inTypeA3)
    local Type_a x;
    case (true,x,_) then x; 
    case (false,_,x) then x; 
  end matchcontinue;
end select;

protected function isNotFunction "function: isNotFunction
 
  This function returns true if the Class is not a function.
"
  input SCode.Class cls;
  output Boolean res;
algorithm 
  res := SCode.isFunction(cls);
  res := boolNot(res);
end isNotFunction;

public function instantiate "function: instantiate
 
  To instantiate a Modelica program, an initial environment is
  built, containing the predefined types. Then the program is
  instantiated by the function `inst_program\'
"
  input SCode.Program inProgram;
  output DAE.DAElist outDAElist;
algorithm 
  outDAElist:=
  matchcontinue (inProgram)
    local
      list<SCode.Class> pnofunc,pfunc,p;
      list<Env.Frame> env,envimpl,envimpl_1;
      list<String> pfuncnames,pnofuncnames;
      String str1,str2;
      list<DAE.Element> lfunc,lnofunc,l;
    case (p)
      equation 
        //Debug.fprintln("insttr", "instantiate");
        pnofunc = Util.listSelect(p, isNotFunction);
        pfunc = Util.listSelect(p, SCode.isFunction);
        env = Builtin.initialEnv();
        //Debug.fprintln("insttr", "Instantiating functions");
        pfuncnames = Util.listMap(pfunc, SCode.className);
        str1 = Util.stringDelimitList(pfuncnames, ", ");
        //Debug.fprint("insttr", "Instantiating functions: ");
        //Debug.fprintln("insttr", str1);
        envimpl = Env.extendFrameClasses(env, p) "pfunc" ;
        (lfunc,envimpl_1) = instProgramImplicit(envimpl, pfunc);
        //Debug.fprint("insttr", "Instantiating other classes: ");
        pnofuncnames = Util.listMap(pnofunc, SCode.className);
        str2 = Util.stringDelimitList(pnofuncnames, ", ");
        //Debug.fprintln("insttr", str2);
        lnofunc = instProgram(envimpl_1, pnofunc);
        l = listAppend(lfunc, lnofunc);

      then
        DAE.DAE(l);
    case _
      equation 
        //Debug.fprintln("failtrace", "instantiate failed");
      then
        fail();
  end matchcontinue;
end instantiate;

public function instantiateImplicit "function: instantiateImplicit
 
  Implicit instantiation of a program can be used for e.g. code generation 
  of functions, since a function must be implicitly instantiated in order to
  generate code from it. 
"
  input SCode.Program inProgram;
  output DAE.DAElist outDAElist;
algorithm 
  outDAElist:=
  matchcontinue (inProgram)
    local
      list<Env.Frame> env,env_1;
      list<DAE.Element> l;
      list<SCode.Class> p;
    case (p)
      equation 
        //Debug.fprintln("insttr", "instantiate_implicit");
        env = Builtin.initialEnv();
        env_1 = Env.extendFrameClasses(env, p);
        (l,_) = instProgramImplicit(env_1, p);
      then
        DAE.DAE(l);
    case _
      equation 
        //Debug.fprintln("failtrace", "instantiate_implicit failed");
      then
        fail();
  end matchcontinue;
end instantiateImplicit;

public function instantiateClass "function: instantiateClass
 
  To enable interactive instantiation, an arbitrary class in the program 
  needs to be possible to instantiate. This function performs the same 
  action as `inst_program\', but given a specific class to instantiate.
  
   First, all the class definitions are added to the environment without 
  modifications, and then the specified class is instantiated in the 
  function `inst_class_in_program\'
"
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output DAE.DAElist outDAElist;
  output Env outEnv;
algorithm 
  (outDAElist,outEnv):=
  matchcontinue (inProgram,inPath)
    local
      Absyn.Path cr,path;
      list<Env.Frame> env,env_1,env_2;
      list<DAE.Element> dae1,dae;
      list<SCode.Class> cdecls;
      String name2,n,pathstr,name,cname_str;
      SCode.Class cdef;
    case ({},cr)
      equation 
        Error.addMessage(Error.NO_CLASSES_LOADED, {});
      then
        fail();
    case ((cdecls as (_ :: _)),(path as Absyn.IDENT(name = name2))) /* top level class */ 
      equation 
        env = Builtin.initialEnv();
        (env_1,dae1) = instClassDecls(env, cdecls, path);
        (dae,env_2) = instClassInProgram(env_1, cdecls, path);
      then
        (DAE.DAE({DAE.COMP(name2,DAE.DAE(dae))}),env_2);
    case ((cdecls as (_ :: _)),(path as Absyn.QUALIFIED(name = name))) /* class in package */ 
      equation 
        env = Builtin.initialEnv();
        (env_1,_) = instClassDecls(env, cdecls, path);
        ((cdef as SCode.CLASS(n,_,_,_,_)),env_2) = Lookup.lookupClass(env_1, path, true);
        (dae,env_2,_,_,_) = instClass(env_2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          cdef, {}, false, TOP_CALL()) "impl" ;
        pathstr = Absyn.pathString(path);
      then
        (DAE.DAE({DAE.COMP(pathstr,DAE.DAE(dae))}),env_2);
    case (cdecls,path) /* error instantiating */ 
      equation 
        cname_str = Absyn.pathString(path);
        Error.addMessage(Error.ERROR_FLATTENING, {cname_str});
      then
        fail();
  end matchcontinue;
end instantiateClass;

public function instantiateClassImplicit "function: instantiateClassImplicit
  author: PA
 
  Similar to instantiate_class, i.e. instantation of arbitrary classes
  but this one instantiates the class implicit, which is less costly.
"
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output DAE.DAElist outDAElist;
  output Env outEnv;
algorithm 
  (outDAElist,outEnv):=
  matchcontinue (inProgram,inPath)
    local
      Absyn.Path cr,path;
      list<Env.Frame> env,env_1,env_2;
      list<DAE.Element> dae1,dae;
      list<SCode.Class> cdecls;
      String name2,n,name;
      SCode.Class cdef;
    case ({},cr)
      equation 
        Error.addMessage(Error.NO_CLASSES_LOADED, {});
      then
        fail();
    case ((cdecls as (_ :: _)),(path as Absyn.IDENT(name = name2))) /* top level class */ 
      equation 
        env = Builtin.initialEnv(); 
        (env_1,dae1) = instClassDecls(env, cdecls, path);
        (dae,env_2) = instClassInProgramImplicit(env_1, cdecls, path);
      then
        (DAE.DAE(dae),env_2);
    case ((cdecls as (_ :: _)),(path as Absyn.QUALIFIED(name = name))) /* class in package */ 
      local String s;
      equation 
        env = Builtin.initialEnv();
        (env_1,_) = instClassDecls(env, cdecls, path);
        ((cdef as SCode.CLASS(n,_,_,_,_)),env_2) = Lookup.lookupClass(env_1, path, true);
        env_2 = Env.extendFrameC(env_2, cdef);
        (env,dae) = implicitInstantiation(env_2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          cdef, {});
      then
        (DAE.DAE(dae),env);
    case (_,_)
      equation 
        print("-instantiate_class_implicit failed\n");
      then
        fail();
  end matchcontinue; 
end instantiateClassImplicit;

public function instantiateFunctionImplicit "function: instantiateFunctionImplicit
  author: PA
 
  Similar to instantiateClassImplict, i.e. instantation of arbitrary classes
  but this one instantiates the class implicit for functions.
"
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output DAE.DAElist outDAElist;
  output Env outEnv;
algorithm 
  (outDAElist,outEnv):=
  matchcontinue (inProgram,inPath)
    local
      Absyn.Path cr,path;
      list<Env.Frame> env,env_1,env_2;
      list<DAE.Element> dae1,dae;
      list<SCode.Class> cdecls;
      String name2,n,name;
      SCode.Class cdef;
    case ({},cr)
      equation 
        Error.addMessage(Error.NO_CLASSES_LOADED, {});
      then
        fail();
    case ((cdecls as (_ :: _)),(path as Absyn.IDENT(name = name2))) /* top level class */ 
      equation 
        env = Builtin.initialEnv(); 
        (env_1,dae1) = instClassDecls(env, cdecls, path);
        (dae,env_2) = instFunctionInProgramImplicit(env_1, cdecls, path);
      then
        (DAE.DAE(dae),env_2);
    case ((cdecls as (_ :: _)),(path as Absyn.QUALIFIED(name = name))) /* class in package */ 
      local String s;
      equation 
        env = Builtin.initialEnv();
        (env_1,_) = instClassDecls(env, cdecls, path);
        ((cdef as SCode.CLASS(n,_,_,_,_)),env_2) = Lookup.lookupClass(env_1, path, true);
        env_2 = Env.extendFrameC(env_2, cdef);
        (env,dae) = implicitFunctionInstantiation(env_2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          cdef, {});
      then
        (DAE.DAE(dae),env);
    case (_,_)
      equation 
        print("-instantiateFunctionImplicit failed\n");
      then
        fail();
  end matchcontinue;
end instantiateFunctionImplicit;

protected function instClassInProgram "function: instClassInProgram
 
  Instantitates a specifc class in a Program. The class must reside on top
  level.
"
  input Env inEnv;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output list<DAE.Element> outDAEElementLst;
  output Env outEnv;
algorithm 
  (outDAEElementLst,outEnv):=
  matchcontinue (inEnv,inProgram,inPath)
    local
      list<DAE.Element> dae;
      list<Env.Frame> env_1,env;
      SCode.Class c;
      String name,name2;
      list<SCode.Class> cs;
      Absyn.Path path;
    case (env,((c as SCode.CLASS(name = name)) :: cs),Absyn.IDENT(name = name2))
      equation 
        equality(name = name2);
        (dae,env_1,_,_,_) = instClass(env, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, 
          {}, false, TOP_CALL()) "impl" ;
      then
        (dae,env_1);
    case (env,((c as SCode.CLASS(name = name)) :: cs),(path as Absyn.IDENT(name = name2)))
      equation 
        failure(equality(name = name2));
        (dae,env) = instClassInProgram(env, cs, path);
      then
        (dae,env);
    case (env,{},_) then ({},env); 
    case (env,_,_) /* //Debug.fprint(\"failtrace\", \"inst_class_in_program failed\\n\") */  then fail(); 
  end matchcontinue;
end instClassInProgram;

protected function instClassInProgramImplicit "function: instClassInProgramImplicit
 
  Instantitates a specifc class in a Program using implicit instatiation. 
  The class must reside on top level.
"
  input Env inEnv;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output list<DAE.Element> outDAEElementLst;
  output Env outEnv;
algorithm 
  (outDAEElementLst,outEnv):=
  matchcontinue (inEnv,inProgram,inPath)
    local
      list<Env.Frame> env_1,env;
      list<DAE.Element> dae;
      SCode.Class c;
      String name,name2;
      list<SCode.Class> cs;
      Absyn.Path path;
    case (env,((c as SCode.CLASS(name = name)) :: cs),Absyn.IDENT(name = name2))
      local String s;
      equation 
        equality(name = name2);
        env = Env.extendFrameC(env, c);
        (env_1,dae) = implicitInstantiation(env, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, 
          {}) ;
      then
        (dae,env_1);
    case (env,((c as SCode.CLASS(name = name)) :: cs),(path as Absyn.IDENT(name = name2)))
      equation 
        failure(equality(name = name2));
        (dae,env) = instClassInProgramImplicit(env, cs, path);
      then
        (dae,env);
    case (env,{},_) then ({},env); 
    case (env,_,_) /* //Debug.fprint(\"failtrace\", \"inst_class_in_program failed\\n\") */  then fail(); 
  end matchcontinue;
end instClassInProgramImplicit;

protected function instFunctionInProgramImplicit "function: instFunctionInProgramImplicit
 
  Instantitates a specific function in a Program using implicit instatiation. 
  The class must reside on top level.
"
  input Env inEnv;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output list<DAE.Element> outDAEElementLst;
  output Env outEnv;
algorithm 
  (outDAEElementLst,outEnv):=
  matchcontinue (inEnv,inProgram,inPath)
    local
      list<Env.Frame> env_1,env;
      list<DAE.Element> dae;
      SCode.Class c;
      String name,name2;
      list<SCode.Class> cs;
      Absyn.Path path;
    case (env,((c as SCode.CLASS(name = name)) :: cs),Absyn.IDENT(name = name2))
      local String s;
      equation 
        equality(name = name2);
        env = Env.extendFrameC(env, c);
        (env_1,dae) = implicitFunctionInstantiation(env, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, 
          {}) ;
      then
        (dae,env_1);
    case (env,((c as SCode.CLASS(name = name)) :: cs),(path as Absyn.IDENT(name = name2)))
      equation 
        failure(equality(name = name2));
        (dae,env) = instFunctionInProgramImplicit(env, cs, path);
      then
        (dae,env);
    case (env,{},_) then ({},env); 
    case (env,_,_)  then fail(); 
  end matchcontinue;
end instFunctionInProgramImplicit;

protected function instClassDecls "function: instClassDecls
 
  This function instantiated class definitions, i.e. adding the class 
  definitions to the environment. See also partial_inst_class_in.
"
  input Env inEnv;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output Env outEnv;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  (outEnv,outDAEElementLst):=
  matchcontinue (inEnv,inProgram,inPath)
    local
      list<Env.Frame> env_1,env_2,env;
      list<DAE.Element> dae1,dae2,dae;
      SCode.Class c;
      String name,name2,str;
      list<SCode.Class> cs;
      Absyn.Path ref;
    case (env,((c as SCode.CLASS(name = name)) :: cs),(ref as Absyn.IDENT(name = name2)))
      equation 
        failure(equality(name = name2));
        (env_1,dae1) = instClassDecl(env, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, {}) ;
        (env_2,dae2) = instClassDecls(env_1, cs, ref);
        dae = listAppend(dae1, dae2);
      then
        (env_2,dae);
    case (env,((c as SCode.CLASS(name = name)) :: cs),(ref as Absyn.IDENT(name = name2)))
      equation 
        equality(name = name2);
        (env_1,dae2) = instClassDecls(env, cs, ref);
      then
        (env_1,dae2);
    case (env,((c as SCode.CLASS(name = name)) :: cs),(ref as Absyn.QUALIFIED(name = name2)))
      equation 
        equality(name = name2);
        (env_1,dae1) = instClassDecl(env, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, {});
        (env_2,dae2) = instClassDecls(env_1, cs, ref);
        dae = listAppend(dae1, dae2);
      then
        (env_2,dae);
    case (env,((c as SCode.CLASS(name = name)) :: cs),(ref as Absyn.QUALIFIED(name = name2)))
      equation 
        failure(equality(name = name2));
        (env_1,dae1) = instClassDecl(env, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, {})  ;
        (env_2,dae2) = instClassDecls(env_1, cs, ref);
        dae = listAppend(dae1, dae2);
      then
        (env_2,dae);
    case (env,{},_) then (env,{}); 
    case (_,_,ref)
      equation 
        print("inst_class_decls failed\n ref =");
        str = Absyn.pathString(ref);
        print(str);
        print("\n");
      then
        fail();
  end matchcontinue;
end instClassDecls;

public function makeEnvFromProgram "function: makeEnvFromProgram
 
  This function takes a `SCode.Program\' and builds an environment, 
  excluding the class in A1.
"
  input SCode.Program prog;
  input SCode.Path c;
  output Env env_1;
  list<Env.Frame> env,env_1;
algorithm 
  env := Builtin.initialEnv();
  env_1 := addProgramToEnv(env, prog, c);
 end makeEnvFromProgram;

public function makeSimpleEnvFromProgram "function: makeSimpleEnvFromProgram
 
  Similar as to make_env_from_program, but not using the complete
  builtin environment, but a more simple one without the builtin operators.
  See Builtin.simple_initial_env.
"
  input SCode.Program prog;
  input SCode.Path c;
  output Env env_1;
  list<Env.Frame> env,env_1;
algorithm 
  env := Builtin.simpleInitialEnv();
  env_1 := addProgramToEnv(env, prog, c);
end makeSimpleEnvFromProgram;

protected function addProgramToEnv "function: addProgramToEnv
 
  Adds all classes in a Program to the environment.
"
  input Env env;
  input SCode.Program p;
  input SCode.Path path;
  output Env env_1;
  list<Env.Frame> env_1;
algorithm 
  (env_1,_) := instClassDecls(env, p, path);
end addProgramToEnv;

protected function instProgram "function: instProgram
 
  Instantiating a Modelica program is the same as instantiating the
  last class definition in the source file. First all the class
  definitions is added to the environment without modifications, and
  then the last class is instantiated in the function `inst_class\'.
  This is used when calling the compiler with a Modelica source code file.
  It is not used in the interactive environment when instantiating a class.
"
  input Env inEnv;
  input SCode.Program inProgram;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  outDAEElementLst:=
  matchcontinue (inEnv,inProgram)
    local
      list<Env.Frame> env,env_1;
      list<DAE.Element> dae,dae1,dae2;
      Connect.Sets csets;
      SCode.Class c;
      String n;
      list<SCode.Class> cs;
    case (env,{})
      equation 
        Error.addMessage(Error.NO_CLASSES_LOADED, {});
      then
        fail();
    case (env,{(c as SCode.CLASS(name = n))})
      equation 
        //Debug.fprint("insttr", "inst_program1: ");
        //Debug.fprint("insttr", n);
        //Debug.fprintln("insttr", "");
        (dae,env_1,csets,_,_) = instClass(env, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, 
          {}, false, TOP_CALL()) ;
      then
        {DAE.COMP(n,DAE.DAE(dae))};
    case (env,(c :: (cs as (_ :: _))))
      equation 
        //Debug.fprintln("insttr", "inst_program2");
        (env_1,dae1) = instClassDecl(env, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, {}) ;
        dae2 = instProgram(env_1, cs) "Env.extend_frame_c(env,c) => env\' &" ;
        dae = listAppend(dae1, dae2);
      then
        dae;
    case (_,_)
      equation 
        //Debug.fprintln("failtrace", "- inst_program failed");
      then
        fail();
  end matchcontinue;
end instProgram;

protected function instProgramImplicit "function: instProgramImplicit
 
  Instantiates a program using implicit instantiation. 
  Used when instantiating functions.
"
  input Env inEnv;
  input SCode.Program inProgram;
  output list<DAE.Element> outDAEElementLst;
  output Env outEnv;
algorithm 
  (outDAEElementLst,outEnv):=
  matchcontinue (inEnv,inProgram)
    local
      list<Env.Frame> env_1,env_2,env;
      list<DAE.Element> dae1,dae2,dae;
      SCode.Class c;
      String n;
      SCode.Restriction restr;
      list<SCode.Class> cs;
    case (env,((c as SCode.CLASS(name = n,restricion = restr)) :: cs))
      local String s;
      equation 
        //Debug.fprint("insttr", "inst_program_implicit: ");
        //Debug.fprint("insttr", n);
        //Debug.fprintln("insttr", "");
        env = Env.extendFrameC(env, c);
        (env_1,dae1) = implicitInstantiation(env, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, {});
        (dae2,env_2) = instProgramImplicit(env_1, cs);
        dae = listAppend(dae1, dae2);
      then
        (dae,env_2);
    case (env,{})
      equation 
        //Debug.fprintln("insttr", "inst_program_implicit (end)");
      then
        ({},env);
  end matchcontinue;
end instProgramImplicit;

public function instClass "function: instClass
 
  Instantiation of a class can be either implicit or \"normal\". This 
  function is used in both cases. When implicit instantiation is performed, 
  the last argument is true, otherwise it is false.
 
  Instantiating a class consists of the following steps:
 
   o Create a new frame on the environment
   o Initialize the class inference state machine
   o Instantiate all the elements and equations
   o Generate equations from the connection sets built during
     instantiation
"
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input SCode.Class inClass;
  input InstDims inInstDims;
  input Boolean inBoolean;
  input CallingScope inCallingScope;
  output list<DAE.Element> outDAEElementLst;
  output Env outEnv;
  output Connect.Sets outSets;
  output Types.Type outType;
  output ClassInf.State outState;
algorithm 
  (outDAEElementLst,outEnv,outSets,outType,outState):=
  matchcontinue (inEnv,inMod,inPrefix,inSets,inClass,inInstDims,inBoolean,inCallingScope)
    local
      list<Env.Frame> env,env_1,env_3;
      Types.Mod mod;
      Prefix.Prefix pre;
      Connect.Sets csets,csets_1;
      String n;
      Boolean partial_,impl,callscope_1,encflag;
      ClassInf.State ci_state,ci_state_1;
      list<DAE.Element> dae1,dae1_1,dae2,dae3,dae;
      list<Exp.ComponentRef> crs;
      list<Types.Var> tys;
      Option<tuple<Types.TType, Option<Absyn.Path>>> bc_ty;
      Absyn.Path fq_class,typename;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      SCode.Class c;
      SCode.Restriction r;
      InstDims inst_dims;
      CallingScope callscope;
      
      /*  Classes with the keyword partial can not be instantiated.
	 They can only be inherited */ 
    case (env,mod,pre,csets,SCode.CLASS(name = n,partial_ = (partial_ as true)),_,(impl as false),_) 
      equation 
        Error.addMessage(Error.INST_PARTIAL_CLASS, {n});
      then
        fail();
        
        /* Instantiation of a class. Create new scope and call instClassIn.
        	Then generate equations from connects.
        */
    case (env,mod,pre,csets,(c as SCode.CLASS(name = n,encapsulated_ = encflag,restricion = r)),inst_dims,impl,callscope)
      equation 
        env_1 = Env.openScope(env, encflag, SOME(n));
        ci_state = ClassInf.start(r, n);
        (dae1,env_3,(csets_1 as Connect.SETS(_,crs)),ci_state_1,tys,bc_ty) 
        			= instClassIn(env_1, mod, pre, csets, ci_state, c, false, inst_dims, impl) ;
        fq_class = makeFullyQualified(env, Absyn.IDENT(n));
        dae1_1 = DAE.setComponentType(dae1, fq_class);
        callscope_1 = isTopCall(callscope);
        dae2 = Connect.equations(csets_1);
        dae3 = Connect.unconnectedFlowEquations(csets_1, dae1, env_3, callscope_1);
        dae = Util.listFlatten({dae1_1,dae2,dae3});
        typename = makeFullyQualified(env, Absyn.IDENT(n));
        ty = mktype(typename, ci_state_1, tys, bc_ty) ;
      then
        (dae,env_3,Connect.SETS({},crs),ty,ci_state_1);

    case (_,_,_,_,SCode.CLASS(name = n),_,impl,_)
      equation 
        //Debug.fprint("failtrace", "- inst_class ");
        //Debug.fprint("failtrace", n);
        //Debug.fprint("failtrace", " failed\n");
      then
        fail();
  end matchcontinue;
end instClass;

protected function instClassBasictype "function: instClassBasictype
  author: PA
 
  This function instantiates a basictype class, e.g. Real, Integer, Real{2},
  etc. This function has the same functionality as inst_class except that
  it will create array types when needed. (inst_class never creates array 
  types). This is needed because this function is used to instantiate classes
  extending from basic types. See inst_basictype_baseclass. 
  NOTE: This function should only be called from inst_basictype_baseclass.
  This is new functionality in Modelica v 2.2.
"
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input SCode.Class inClass;
  input InstDims inInstDims;
  input Boolean inBoolean;
  input CallingScope inCallingScope;
  output list<DAE.Element> outDAEElementLst;
  output Env outEnv;
  output Connect.Sets outSets;
  output Types.Type outType;
  output ClassInf.State outState;
algorithm 
  (outDAEElementLst,outEnv,outSets,outType,outState):=
  matchcontinue (inEnv,inMod,inPrefix,inSets,inClass,inInstDims,inBoolean,inCallingScope)
    local
      list<Env.Frame> env_1,env_3,env;
      ClassInf.State ci_state,ci_state_1;
      SCode.Class c_1,c;
      list<DAE.Element> dae1,dae1_1,dae2,dae3,dae;
      Connect.Sets csets_1,csets;
      list<Exp.ComponentRef> crs;
      list<Types.Var> tys;
      Option<tuple<Types.TType, Option<Absyn.Path>>> bc_ty;
      Absyn.Path fq_class,typename;
      Boolean callscope_1,encflag,impl;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Mod mod;
      Prefix.Prefix pre;
      String n;
      SCode.Restriction r;
      InstDims inst_dims;
      CallingScope callscope;
    case (env,mod,pre,csets,(c as SCode.CLASS(name = n,encapsulated_ = encflag,restricion = r)),inst_dims,impl,callscope) /* impl */ 
      equation 
        env_1 = Env.openScope(env, encflag, SOME(n));
        ci_state = ClassInf.start(r, n);
        c_1 = SCode.classSetPartial(c, false);
        (dae1,env_3,(csets_1 as Connect.SETS(_,crs)),ci_state_1,tys,bc_ty) 
         			= instClassIn(env_1, mod, pre, csets, ci_state, c_1, false, inst_dims, impl) ;
        fq_class = makeFullyQualified(env, Absyn.IDENT(n));
        dae1_1 = DAE.setComponentType(dae1, fq_class);
        callscope_1 = isTopCall(callscope);
        dae2 = Connect.equations(csets_1);
        dae3 = Connect.unconnectedFlowEquations(csets_1, dae1, env_3, callscope_1);
        dae = Util.listFlatten({dae1_1,dae2,dae3});
        typename = makeFullyQualified(env, Absyn.IDENT(n));
        ty = mktypeWithArrays(typename, ci_state_1, tys, bc_ty);
      then
        (dae,env_3,Connect.SETS({},crs),ty,ci_state_1);
    case (_,_,_,_,SCode.CLASS(name = n),_,impl,_)
      equation 
        //Debug.fprint("failtrace", "- inst_class_basictype ");
        //Debug.fprint("failtrace", n);
        //Debug.fprint("failtrace", " failed\n");
      then
        fail();
  end matchcontinue;
end instClassBasictype;

public function instClassIn "function: instClassIn
 
  This rule instantiates the contents of a class definition, with a
  new environment already setup.
  The next last boolean indicates if the class should be instantiated 
  implicit, i.e. without generating DAE.
  The last boolean is a even stronger indication of implicit instantiation,
  used when looking up variables in packages. This must be used because 
  generation of functions in implicit instanitation (according to next last 
  boolean) can cause circular dependencies (e.g. if a function uses a
  constant in its body) 
"
  input Env inEnv1;
  input Mod inMod2;
  input Prefix inPrefix3;
  input Connect.Sets inSets4;
  input ClassInf.State inState5;
  input SCode.Class inClass6;
  input Boolean inBoolean7;
  input InstDims inInstDims8;
  input Boolean inBoolean9;
  output list<DAE.Element> outDAEElementLst;
  output Env outEnv;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output list<Types.Var> outTypesVarLst;
  output Option<Types.Type> outTypesTypeOption;
algorithm 
  (outDAEElementLst,outEnv,outSets,outState,outTypesVarLst,outTypesTypeOption):=
  matchcontinue (inEnv1,inMod2,inPrefix3,inSets4,inState5,inClass6,inBoolean7,inInstDims8,inBoolean9)
    local
      Option<tuple<Types.TType, Option<Absyn.Path>>> bc;
      list<Env.Frame> env,env_1;
      Types.Mod mods;
      Prefix.Prefix pre;
      list<Exp.ComponentRef> crs;
      ClassInf.State ci_state,ci_state_1;
      SCode.Class c,cls;
      InstDims inst_dims;
      Boolean impl,prot;
      String clsname,implstr,n;
      list<DAE.Element> l;
      Connect.Sets csets_1,csets;
      list<Types.Var> tys;
      SCode.Restriction r;
      SCode.ClassDef d;
      /*  implicit instantiation - No DAE */ 
    case (env,mods,pre,Connect.SETS(connection = crs),ci_state,(c as SCode.CLASS(name = "Real")),_,inst_dims,impl) 
      equation 
        bc = arrayBasictypeBaseclass(inst_dims, (Types.T_REAL({}),NONE));
      then
        ({},env,Connect.SETS({},crs),ci_state,{},bc);
    case (env,mods,pre,Connect.SETS(connection = crs),ci_state,(c as SCode.CLASS(name = "Integer")),_,_,impl) 
      then ({},env,Connect.SETS({},crs),ci_state,{},NONE);  /* No DAE csets should be emtpy, but crs must be propagated to \"next component\" No DAE */ 
    case (env,mods,pre,Connect.SETS(connection = crs),ci_state,(c as SCode.CLASS(name = "String")),_,_,impl) 
      then ({},env,Connect.SETS({},crs),ci_state,{},NONE);  /* No DAE No DAE */ 
    case (env,mods,pre,Connect.SETS(connection = crs),ci_state,(c as SCode.CLASS(name = "Boolean")),_,_,impl) 
      then ({},env,Connect.SETS({},crs),ci_state,{},NONE);  /* No DAE No DAE */ 
  
   	/* No DAE Ignore functions if not implicit instantiation No DAE */ 
    case (env,mods,pre,Connect.SETS(connection = crs),ci_state,cls,_,_,(impl as false)) 
      equation 
        true = SCode.isFunction(cls);
        //Debug.fprint("insttr", "Ignoring function in explicit instantiation: ");
        clsname = SCode.className(cls);
        //Debug.fprint("insttr", clsname);
        //Debug.fprint("insttr", "\n");
      then
        ({},env,Connect.SETS({},crs),ci_state,{},NONE);
    case (env,mods,pre,csets,ci_state,(c as SCode.CLASS(name = n,restricion = r,parts = d)),prot,inst_dims,impl)
      local String s;
      equation 
        clsname = SCode.className(c) "print \"inst_class_in\" & print n & print \"\\n\" &" ;
        //print("instClassIn");print(n);print("\n");
        //Debug.fprint("insttr", "Instantiating class: ");
        implstr = Util.if_(impl, " (implicit) ", " (explicit) ");
        //Debug.fprint("insttr", implstr);
        //Debug.fprint("insttr", clsname);
        //Debug.fprint("insttr", "\n");
        (l,env_1,csets_1,ci_state_1,tys,bc) = instClassdef(env, mods, pre, csets, ci_state, d, r, prot, inst_dims, impl);        
      then
        (l,env_1,csets_1,ci_state_1,tys,bc);
    case (_,_,_,csets,_,_,_,_,_)
      equation 
        //Debug.fprint("failtrace", "- inst_class_in failed\n");
      then
        fail();
  end matchcontinue;
end instClassIn;

protected function arrayBasictypeBaseclass "function: 
  author: PA
 
"
  input InstDims inInstDims;
  input Types.Type inType;
  output Option<Types.Type> outTypesTypeOption;
algorithm 
  outTypesTypeOption:=
  matchcontinue (inInstDims,inType)
    local
      tuple<Types.TType, Option<Absyn.Path>> tp,tp_1;
      list<Option<Integer>> lst;
      InstDims inst_dims;
    case ({},tp) then NONE; 
    case (inst_dims,tp)
      equation 
        lst = instdimsIntOptList(inst_dims);
        tp_1 = arrayBasictypeBaseclass2(lst, tp);
      then
        SOME(tp_1);
  end matchcontinue;
end arrayBasictypeBaseclass;

protected function instdimsIntOptList "function: 
  author: PA
 
"
  input InstDims inInstDims;
  output list<Option<Integer>> outIntegerOptionLst;
algorithm 
  outIntegerOptionLst:=
  matchcontinue (inInstDims)
    local
      list<Option<Integer>> res;
      Integer i;
      InstDims ss;
    case ({}) then {}; 
    case ((Exp.INDEX(exp = Exp.ICONST(integer = i)) :: ss))
      equation 
        res = instdimsIntOptList(ss);
      then
        (SOME(i) :: res);
  end matchcontinue;
end instdimsIntOptList;

protected function arrayBasictypeBaseclass2 "function: 
  author: PA
 
"
  input list<Option<Integer>> inIntegerOptionLst;
  input Types.Type inType;
  output Types.Type outType;
algorithm 
  outType:=
  matchcontinue (inIntegerOptionLst,inType)
    local
      tuple<Types.TType, Option<Absyn.Path>> tp,tp_1,res;
      Option<Integer> i;
      list<Option<Integer>> is;
    case ({},tp) then tp; 
    case ((i :: is),tp)
      equation 
        tp_1 = Types.liftArray(tp, i);
        res = arrayBasictypeBaseclass2(is, tp_1);
      then
        res;
  end matchcontinue;
end arrayBasictypeBaseclass2;

public function partialInstClassIn "function: partialInstClassIn
 
  This function is used when instantiating classes in lookup of other classes.
  The only work performed by this function is to instantiate local classes and
  inherited classes.
"
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.Class inClass;
  input Boolean inBoolean;
  input InstDims inInstDims;
  output Env outEnv;
  output ClassInf.State outState;
algorithm 
  (outEnv,outState):=
  matchcontinue (inEnv,inMod,inPrefix,inSets,inState,inClass,inBoolean,inInstDims)
    local
      list<Env.Frame> env,env_1;
      Types.Mod mods;
      Prefix.Prefix pre;
      Connect.Sets csets;
      ClassInf.State ci_state,ci_state_1;
      SCode.Class c;
      String n;
      SCode.Restriction r;
      SCode.ClassDef d;
      Boolean prot;
      InstDims inst_dims;
    case (env,mods,pre,csets,ci_state,(c as SCode.CLASS(name = "Real")),_,_) then (env,ci_state); 
    case (env,mods,pre,csets,ci_state,(c as SCode.CLASS(name = "Integer")),_,_) then (env,ci_state); 
    case (env,mods,pre,csets,ci_state,(c as SCode.CLASS(name = "String")),_,_) then (env,ci_state); 
    case (env,mods,pre,csets,ci_state,(c as SCode.CLASS(name = "Boolean")),_,_) then (env,ci_state); 
    case (env,mods,pre,csets,ci_state,(c as SCode.CLASS(name = n,restricion = r,parts = d)),prot,inst_dims)
      local String str,str2; Boolean b; Real t1,t2,time;
      equation 
        t1 = System.time();
        (env_1,ci_state_1) = partialInstClassdef(env, mods, pre, csets, ci_state, d, r, prot, inst_dims);
        t2 = System.time();
        time = t2 -. t1;
        str = realString(time);
        b = time >. 0.3;
        str2=Util.stringAppendList({"partialInstClassIn ",n,"  ",str,"\n"});
        str=Util.if_(b,str2,"");
        print(str);
      then
        (env_1,ci_state_1);
  end matchcontinue;
end partialInstClassIn;

protected function instClassdef "function: instClassdef
 
  There are two kinds of class definitions, either explicit
  definitions (`SCode.PARTS()\') or derived definitions
  (`SCode.DERIVED()\').
 
  When instantiating an explicit definition, the elements are first
  instantiated, using `inst_element_list\', and then the equations
  and finally the algorithms are instantiated using `inst_equation\'
  and `inst_algorithm\', respectively. The resulting lists of
  equations are concatenated to produce the result.
  The last two arguments are the same as for inst_class_in: 
  implicit instantiation and implicit package/function instantiation
"
  input Env inEnv1;
  input Mod inMod2;
  input Prefix inPrefix3;
  input Connect.Sets inSets4;
  input ClassInf.State inState5;
  input SCode.ClassDef inClassDef6;
  input SCode.Restriction inRestriction7;
  input Boolean inBoolean8;
  input InstDims inInstDims9;
  input Boolean inBoolean10;
  output list<DAE.Element> outDAEElementLst;
  output Env outEnv;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output list<Types.Var> outTypesVarLst;
  output Option<Types.Type> outTypesTypeOption;
algorithm 
  (outDAEElementLst,outEnv,outSets,outState,outTypesVarLst,outTypesTypeOption):=
  matchcontinue (inEnv1,inMod2,inPrefix3,inSets4,inState5,inClassDef6,inRestriction7,inBoolean8,inInstDims9,inBoolean10)
    local
      list<SCode.Element> cdefelts,compelts,extendselts,els;
      list<Env.Frame> env1,env2,env3,env,env4,env5,cenv,cenv_2,env_2;
      list<tuple<SCode.Element, Mod>> cdefelts_1,cdefelts_2,extcomps,compelts_1,compelts_2;
      Connect.Sets csets,csets1,csets_filtered,csets2,csets3,csets4,csets5,csets_1;
      list<DAE.Element> dae1,dae2,dae3,dae4,dae5,dae;
      ClassInf.State ci_state1,ci_state,ci_state2,ci_state3,ci_state4,ci_state5,ci_state6,new_ci_state,ci_state_1;
      list<Types.Var> tys;
      Option<tuple<Types.TType, Option<Absyn.Path>>> bc;
      Types.Mod mods,emods,m,mod_1,mods_1,mods_2;
      Prefix.Prefix pre;
      list<SCode.Equation> eqs,initeqs,eqs2,initeqs2,eqs_1,initeqs_1;
      list<SCode.Algorithm> alg,initalg,alg2,initalg2,alg_1,initalg_1;
      SCode.Restriction re,r;
      Boolean prot,impl,enc2;
      InstDims inst_dims,inst_dims2,inst_dims_1;
      String id,pre_str,cn2,cns,scope_str,s;
      SCode.Class c;
      Option<Types.EqMod> eq;
      list<DimExp> dims;
      Absyn.Path cn;
      Option<list<Absyn.Subscript>> ad;
      SCode.Mod mod;
      /* This rule describes how to instantiate a class definition
	  that extends a basic type. */ 
    case (env,mods,pre,csets,ci_state,SCode.PARTS(elementLst = els,equationLst = eqs,
      																						initialEquation = initeqs,algorithmLst = alg,initialAlgorithm = initalg)
      		,re,prot,inst_dims,impl) 
      		local String s;
      equation 
        cdefelts = classdefAndImpElts(els);
        compelts = componentElts(els) "should be empty, checked in inst_basic type below" ;
        ((extendselts as (_ :: _))) = extendsElts(els);
        env1 = addClassdefsToEnv(env, cdefelts, impl) "1. CLASSDEF & IMPORT nodes and COMPONENT nodes(add to env)" ;
        cdefelts_1 = addNomod(cdefelts) "instantiate CDEFS so redeclares are carried out" ;
        (cdefelts_2,env2,csets) = updateCompeltsMods(env1, pre, cdefelts_1, ci_state, csets, impl);
        (dae1,env3,csets1,ci_state1,tys) = instElementList(env2, mods, pre, csets, ci_state, cdefelts_2, inst_dims, 
          impl);
        bc = instBasictypeBaseclass(env3, extendselts, compelts, mods, inst_dims);
        ErrorExt.errorOn();
      then
        ({},env,Connect.emptySet,ci_state,{},bc);
        
        /* This case instantiates external objects. An external object inherits from ExternalOBject
         and have two local functions: constructor and destructor (and no other elements). */
        case (env,mods,pre,csets,ci_state,SCode.PARTS(elementLst = els, equationLst = eqs,
      																						initialEquation = initeqs,algorithmLst = alg,initialAlgorithm = initalg)
      		,re,prot,inst_dims,impl) 
      	equation
      	  	true = isExternalObject(els);
      	  	(dae,env,ci_state) = instantiateExternalObject(env,els,impl);
      	  then 
      	  (dae,env,Connect.emptySet,ci_state,{},NONE);  
        
        /* This rule describes how to instantiate an explicit class definition*/ 
    case (env,mods,pre,csets,ci_state,SCode.PARTS(elementLst = els,equationLst = eqs,initialEquation = initeqs,
      																					algorithmLst = alg,initialAlgorithm = initalg)
      	    ,re,prot,inst_dims,impl) 
      equation 
        ci_state1 = ClassInf.trans(ci_state, ClassInf.NEWDEF());
        cdefelts = classdefAndImpElts(els);
        compelts = componentElts(els);
        extendselts = extendsElts(els);
        env1 = addClassdefsToEnv(env, cdefelts, impl) "1. CLASSDEF & IMPORT nodes and COMPONENT nodes(add to env)" ;
        (env2,emods,extcomps,eqs2,initeqs2,alg2,initalg2) = instExtendsList(env1, mods, extendselts, ci_state, impl) "2. EXTENDS Nodes inst_extends_list only flatten inhteritance structure. It does not perform component instantiations." ;
        compelts_1 = addNomod(compelts) "Problem. Modifiers on inherited components are unelabed, loosing their 
	   type information. This will not work, since the modifier type can not always be found.
	   for instance. 
	   model B extends B2; end B; model B2 Integer ni=1; end B2;
	   model test
	   Integer n=2;
	   B b(ni=n);
	   end test;
	   The modifier (n=n) will be untypes when B is instantiated and the variable n can not be 
	   found, since the component b is instantiated in env of B.
	   Solution:
	   Redesign inst_extends_list to return (SCode.Element, Mod) list and
	   convert other component elements to the same format, such that inst_element can 
	   handle the new format uniformely.
	" ;
        cdefelts_1 = addNomod(cdefelts);
        compelts_1 = Util.listFlatten({extcomps,compelts_1,cdefelts_1});
        eqs_1 = listAppend(eqs, eqs2) "Add components from base classes to be instantiated in 3 as well." ;
        initeqs_1 = listAppend(initeqs, initeqs2);
        alg_1 = listAppend(alg, alg2);
        initalg_1 = listAppend(initalg, initalg2);
        csets_filtered = filterConnectionSetCrefs(csets, pre) "only keep inside connections with matching prefix for this class.
	  csets will remain unfiltered for other components in \"outer class\"" ;
        csets = addConnectionCrefs(csets, eqs_1) "Add connection crefs from equations to connection sets" ;
        csets_filtered = addConnectionCrefs(csets_filtered, eqs_1);
        env2 = addConnectionSetToEnv(csets_filtered, env2) "Add filtered connection sets to env so ceval can reach it" ;
        id = Env.printEnvPathStr(env);
        pre_str = Prefix.printPrefixStr(pre);
        env3 = addComponentsToEnv(env2, emods, pre, csets, ci_state, compelts_1, compelts_1, 
          eqs_1, inst_dims, impl) "Add variables to env, wihtout type and binding, which will be added later in inst_element_list (where update_variable is called)" ;
        (compelts_2,env4,csets) = updateCompeltsMods(env3, pre, compelts_1, ci_state, csets, impl) "Update the modifiers of elements to typed ones, needed for modifiers
	   on components that are inherited." ;
        (dae1,env5,csets1,ci_state2,tys) 
        		= instElementList(env4, mods, pre, csets, ci_state1, compelts_2, inst_dims, impl) "3. Instantiate components" ;
        (dae2,_,csets2,ci_state3) = instList(env5, mods, pre, csets1, ci_state2, instEquation, eqs_1, impl) "Instantiate equations" ;
        (dae3,_,csets3,ci_state4) = instList(env5, mods, pre, csets2, ci_state3, instInitialequation, 
          initeqs_1, impl);
        (dae4,_,csets4,ci_state5) = instList(env5, mods, pre, csets3, ci_state4, instAlgorithm, alg_1, 
          impl) "instantiate algorithms" ;
        (dae5,_,csets5,ci_state6) = instList(env5, mods, pre, csets4, ci_state5, instInitialalgorithm, 
          initalg_1, impl);
        dae = Util.listFlatten({dae1,dae2,dae3,dae4,dae5}) "collect the dae\'s" ;
      then
        (dae,env5,csets5,ci_state6,tys,NONE/* no basictype bc*/);
   
      
        /* This rule describes how to instantiate a derived class definition */ 
    case (env,mods,pre,csets,ci_state,SCode.DERIVED(short = cn,absynArrayDimOption = ad,mod = mod),re,prot,inst_dims,impl) 
      equation 
        ((c as SCode.CLASS(cn2,_,enc2,r,_)),cenv) = Lookup.lookupClass(env, cn, true);
        cenv_2 = Env.openScope(cenv, enc2, SOME(cn2));
        m = Mod.lookupModificationP(mods, cn);
        mod_1 = Mod.elabMod(env, pre, mod, impl);
        new_ci_state = ClassInf.start(r, cn2);
        mods_1 = Mod.merge(mods, m, cenv_2, pre) "merge modifiers" ;
        mods_2 = Mod.merge(mods_1, mod_1, cenv_2, pre);
        eq = Mod.modEquation(mods_2) "instantiate array dimensions" ;
        dims = elabArraydimOpt(cenv_2, Absyn.CREF_IDENT("",{}), ad, eq, impl, NONE) "owncref not valid here" ;
        inst_dims2 = instDimExpLst(dims, impl);
        inst_dims_1 = listAppend(inst_dims, inst_dims2);
        (dae,env_2,csets_1,ci_state_1,tys,bc) = instClassIn(cenv_2, mods_2, pre, csets, new_ci_state, c, prot, 
          inst_dims_1, impl) "instantiate class in opened scope. " ;
        ClassInf.assertValid(ci_state_1, re) "Check for restriction violations" ;
      then
        (dae,env_2,csets_1,ci_state_1,tys,bc);
        
        /* If the class is derived from a class that can not be found in the environment, this rule prints an error message. */ 
   
    case (env,mods,pre,csets,ci_state,SCode.DERIVED(short = cn,absynArrayDimOption = ad,mod = mod),re,prot,inst_dims,impl) 
      equation 
        failure((_,_) = Lookup.lookupClass(env, cn, false));
        cns = Absyn.pathString(cn);
        scope_str = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_ERROR, {cns,scope_str});
      then
        fail();
    case (env,_,_,_,_,_,_,_,_,_)
      equation 
        //Debug.fprint("failtrace", "- inst_classdef failed\n class :");
        s = Env.printEnvPathStr(env);
        //Debug.fprint("failtrace", s);
        //Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end instClassdef;

protected function instantiateExternalObject
" instantiate an external object. This is done by instantiating the destructor and constructor
functions and create a DAE element containing these two."
input Env.Env env "environment";
input list<SCode.Element> els "elements";
input Boolean impl;
output list<DAE.Element> dae "resulting dae";
output Env.Env outEnv;
output ClassInf.State ciState;
algorithm
  (dae,outEnv,ciState) := matchcontinue(env,els,impl) 
 	 local 
 	   SCode.Class destr,constr;
 	   DAE.Element destr_dae,constr_dae;
 	   Env.Env env1;
 	   // Explicit instantiation, generate constructor and destructor and the function type.
  case	(env,els,false) 
    local 
    	Ident className;
    	Absyn.Path classNameFQ;
    	Types.Type functp;
    	Env.Frame f;
    	list<Env.Frame> fs,fs1;
    equation
     
    destr = getExternalObjectDestructor(els);
    constr = getExternalObjectConstructor(els);
    destr_dae = instantiateExternalObjectDestructor(env,destr);
    (constr_dae,functp) = instantiateExternalObjectConstructor(env,constr);
    className=Env.getClassName(env); // The external object classname is in top frame of environment.
    SOME(classNameFQ)= Env.getEnvPath(env); // Fully qualified classname
		//Extend the frame with the type, one frame up at the same place as the class.
    f::fs = env;
    fs1 = Env.extendFrameT(fs,className,functp);
    env1 = f::fs1; 
    then ({DAE.EXTOBJECTCLASS(classNameFQ,constr_dae,destr_dae)},env1,ClassInf.EXTERNAL_OBJ(classNameFQ));
      
      // Implicit, do no instantiate constructor and destructor.
  case (env,els,true) 
    local Absyn.Path classNameFQ;
    equation 
      	SOME(classNameFQ)= Env.getEnvPath(env); // Fully qualified classname
    then ({},env,ClassInf.EXTERNAL_OBJ(classNameFQ));
  case (env,els,impl) equation
     print("instantiateExternalObject failed\n");
     then fail();
  end matchcontinue;   
end instantiateExternalObject;

protected function instantiateExternalObjectDestructor 
"instantiates the destructor function of an external object"
	input Env.Env env;
	input SCode.Class cl;
	output DAE.Element dae;
algorithm	
  dae := matchcontinue (env,cl)
  	case (env,cl) 
  	  local
  	    Env.Env env1;
  	    DAE.Element daeElt;
  	    list<DAE.Element> dae;
  	    String s;
  		equation
  		  (env1,{daeElt}) = implicitFunctionInstantiation(env, Types.NOMOD(), Prefix.NOPRE(), 
		  		  Connect.emptySet, cl, {}) ;
  	then
  	  daeElt;
  	  case (env,cl)
  	    equation
  	      print("instantiateExternalObjectDestructor failed\n");
  	  then fail();
   end matchcontinue;   	  
end instantiateExternalObjectDestructor;

protected function instantiateExternalObjectConstructor 
"instantiates the constructor function of an external object"
	input Env.Env env;
	input SCode.Class cl;
	output DAE.Element dae;
	output Types.Type tp;
algorithm	
	dae := matchcontinue (env,cl)
  	case (env,cl) 
  	  local
  	    Env.Env env1;
  	    DAE.Element daeElt;
  	    Types.Type funcTp;
  	    String s;
  		equation
  		  (env1,{daeElt as DAE.EXTFUNCTION(type_ = funcTp )}) 
  		     	= implicitFunctionInstantiation(env, Types.NOMOD(), Prefix.NOPRE(), 
		  		  Connect.emptySet, cl, {}) ;
  	then
  	  (daeElt,funcTp);
	  case (env,cl)
  	  equation
  	    print("instantiateExternalObjectConstructor failed\n");
  	then fail();
  	  end matchcontinue;
end instantiateExternalObjectConstructor;

public function classIsExternalObject 
"returns true if a Class fulfills the requirements of an external object"
	input SCode.Class cl;
	output Boolean res;
algorithm
  res := matchcontinue (cl)
  local list<SCode.Element> els;
    case SCode.CLASS(parts=SCode.PARTS(elementLst=els)) 
      equation
        res = isExternalObject(els);
     then res;       
    case (_) then false;
  end matchcontinue;
end classIsExternalObject;

protected function isExternalObject 
"Returns true if the element list fulfills the condition of an External Object.
An external object extends the builtinClass ExternalObject, and has two local 
functions, destructor and constructor. "
input  list<SCode.Element> els;
output Boolean res;
algorithm
 res := matchcontinue(els) 
 case (els)
   equation
  	true = hasExtendsOfExternalObject(els);
	  true = hasExternalObjectDestructor(els);
  	true = hasExternalObjectConstructor(els);
  	3 = listLength(els);
  then true;
  case (_) then false;
  end matchcontinue;
end isExternalObject;

protected function hasExtendsOfExternalObject 
"returns true if element list contains 'extends ExternalObject;'"
input list<SCode.Element> els;
output Boolean res;

algorithm 
  res:= matchcontinue(els)
  	case SCode.EXTENDS(path = Absyn.IDENT("ExternalObject"))::_ then true;
  	case _::els then hasExtendsOfExternalObject(els);
  	case _ then false;
  end matchcontinue; 
end hasExtendsOfExternalObject;

protected function hasExternalObjectDestructor 
"returns true if element list contains 'function destructor .. end destructor'"
input list<SCode.Element> els;
output Boolean res;

algorithm 
  res:= matchcontinue(els)
  	case SCode.CLASSDEF(class_ = SCode.CLASS(name="destructor"))::_ then true;
  	case _::els then hasExternalObjectDestructor(els);
  	case _ then false;
  end matchcontinue;
end hasExternalObjectDestructor;

protected function hasExternalObjectConstructor 
"returns true if element list contains 'function constructor ... end constructor'"
input list<SCode.Element> els;
output Boolean res;

algorithm 
  res:= matchcontinue(els)
  	case SCode.CLASSDEF(class_ = SCode.CLASS(name="constructor"))::_ then true;
  	case _::els then hasExternalObjectConstructor(els);
  	case _ then false;
  end matchcontinue;
end hasExternalObjectConstructor;

protected function getExternalObjectDestructor 
"returns the class 'function destructor .. end destructor' from element list"
input list<SCode.Element> els;
output SCode.Class cl;
algorithm 
  cl:= matchcontinue(els) local SCode.Class cl;
  	case SCode.CLASSDEF(class_ = cl as SCode.CLASS(name="destructor"))::_ then cl;
  	case _::els then getExternalObjectDestructor(els);
  end matchcontinue;
end getExternalObjectDestructor;

protected function getExternalObjectConstructor 
"returns the class 'function constructor ... end constructor' from element list"
input list<SCode.Element> els;
output SCode.Class cl;
algorithm 
  cl:= matchcontinue(els)
  	case SCode.CLASSDEF(class_ = cl as SCode.CLASS(name="constructor"))::_ then cl;
  	case _::els then getExternalObjectConstructor(els);
  end matchcontinue;
end getExternalObjectConstructor;
 
protected function printExtcomps " prints the tuple of elements and modifiers to stdout"
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst;
algorithm 
  _:=
  matchcontinue (inTplSCodeElementModLst)
    local
      String s;
      SCode.Element el;
      Types.Mod mod;
      list<tuple<SCode.Element, Mod>> els;
    case ({}) then (); 
    case (((el,mod) :: els))
      equation 
        s = SCode.printElementStr(el);
        print(s);
        print("\n");
        printExtcomps(els);
      then
        ();
  end matchcontinue;
end printExtcomps;

protected function instBasictypeBaseclass "function: instBasictypeBaseclass
 
  This function finds the type of classes that extends a basic type.
  For instance,
  connector RealSignal
    extends SignalType;
  replaceable type SignalType = Real;
  end RealSignal;
 
  Such classes can not have any other components, and can only inherit one 
  basic type.
"
  input Env inEnv1;
  input list<SCode.Element> inSCodeElementLst2;
  input list<SCode.Element> inSCodeElementLst3;
  input Mod inMod4;
  input InstDims inInstDims5;
  output Option<Types.Type> outTypesTypeOption;
algorithm 
  outTypesTypeOption:=
  matchcontinue (inEnv1,inSCodeElementLst2,inSCodeElementLst3,inMod4,inInstDims5)
    local
      Types.Mod m_1,m_2,mods;
      SCode.Class cdef,cdef_1;
      list<Env.Frame> cenv,env_1,env;
      list<DAE.Element> dae;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      ClassInf.State st;
      Boolean b1,b2;
      Absyn.Path path;
      SCode.Mod mod;
      InstDims inst_dims;
      String classname;
    case (env,{SCode.EXTENDS(path = path,mod = mod)},{},mods,inst_dims) /* Inherits baseclass -and- has components */ 
      equation 
        ErrorExt.errorOff();
        m_1 = Mod.elabMod(env, Prefix.NOPRE(), mod, true) "impl" ;
        m_2 = Mod.merge(mods, m_1, env, Prefix.NOPRE());
        (cdef,cenv) = Lookup.lookupClass(env, path, true);
        (dae,env_1,_,ty,st) = instClassBasictype(env, m_2, Prefix.NOPRE(), Connect.emptySet, cdef, 
          inst_dims, false, INNER_CALL()) "impl" ;
        b1 = Types.basicType(ty);
        b2 = Types.arrayType(ty);
        true = boolOr(b1, b2);
      then
        SOME(ty);
    case (env,{SCode.EXTENDS(path = path,mod = mod)},(_ :: _),mods,inst_dims) /* Inherits baseclass -and- has components */ 
      equation 
        ErrorExt.errorOff();
        m_1 = Mod.elabMod(env, Prefix.NOPRE(), mod, true) "impl" ;
        (cdef,cenv) = Lookup.lookupClass(env, path, true);
        cdef_1 = SCode.classSetPartial(cdef, false);
        (dae,env_1,_,ty,st) = instClass(cenv, m_1, Prefix.NOPRE(), Connect.emptySet, cdef_1, 
          inst_dims, false, INNER_CALL()) "impl" ;
        b1 = Types.basicType(ty);
        b2 = Types.arrayType(ty);
        true = boolOr(b1, b2);
        classname = Env.printEnvPathStr(env);
        ErrorExt.errorOn();
        Error.addMessage(Error.INHERIT_BASIC_WITH_COMPS, {classname});
      then
        fail();
    case (env,_,_,mods,inst_dims)
      equation 
        ErrorExt.errorOn();
      then
        fail();
  end matchcontinue;
end instBasictypeBaseclass;

protected function addConnectionSetToEnv "function: addConnectionSetToEnv
 
  Adds the connection set to the environment such that Ceval can reach it.
  It is required to evaluate cardinality
"
  input Connect.Sets inSets;
  input Env inEnv;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inSets,inEnv)
    local
      list<Exp.ComponentRef> crs;
      Option<String> n;
      Env.BinTree bt1,bt2;
      list<Env.Item> imp;
      list<Env.Frame> bc,fs;
      Boolean enc;
    case (Connect.SETS(connection = crs),(Env.FRAME(class_1 = n,list_2 = bt1,list_3 = bt2,list_4 = imp,list_5 = bc,encapsulated_7 = enc) :: fs)) then (Env.FRAME(n,bt1,bt2,imp,bc,crs,enc) :: fs); 
  end matchcontinue;
end addConnectionSetToEnv;

protected function addConnectionCrefs "function: addConnectionCrefs
  author: PA
 
  This function adds the connection component references from local
  equations to the connection sets.
"
  input Connect.Sets inSets;
  input list<SCode.Equation> inSCodeEquationLst;
  output Connect.Sets outSets;
algorithm 
  outSets:=
  matchcontinue (inSets,inSCodeEquationLst)
    local
      Connect.Sets sets,sets_1;
      Exp.ComponentRef cr1_1,cr2_1;
      list<Exp.ComponentRef> crs_1,crs;
      Absyn.ComponentRef cr1,cr2;
      list<SCode.Equation> es;
    case (sets,{}) then sets; 
    case (Connect.SETS(setLst = sets,connection = crs),(SCode.EQUATION(eEquation = SCode.EQ_CONNECT(componentRef1 = cr1,componentRef2 = cr2)) :: es))
      local list<Connect.Set> sets;
      equation 
        cr1_1 = Exp.toExpCref(cr1);
        cr2_1 = Exp.toExpCref(cr2);
        crs_1 = listAppend(crs, {cr1_1,cr2_1}) "	Exp.print_component_ref_str cr1\' => s1 &
	Exp.print_component_ref_str cr2\' => s2 &
	print \"Adding cr :\" & print s1 & print \" and cr: \" & print s2 & 
	print \"\\n\" &" ;
        sets_1 = addConnectionCrefs(Connect.SETS(sets,crs_1), es);
      then
        sets_1;
    case (sets,(_ :: es))
      equation 
        sets_1 = addConnectionCrefs(sets, es);
      then
        sets_1;
  end matchcontinue;
end addConnectionCrefs;

protected function filterConnectionSetCrefs "function: filterConnectionSetCrefs
  author: PA
 
  This function investigates Prefix and filters all connect_refs to only 
  contain references starting with actual prefix.
"
  input Connect.Sets inSets;
  input Prefix inPrefix;
  output Connect.Sets outSets;
algorithm 
  outSets:=
  matchcontinue (inSets,inPrefix)
    local
      Connect.Sets s;
      Prefix.Prefix first_pre,pre;
      Exp.ComponentRef cr;
      list<Exp.ComponentRef> crs_1,crs;
      list<Connect.Set> set;
    case (s,Prefix.NOPRE()) then s;  /* no Prexix, nothing to filter */ 
    case (Connect.SETS(setLst = set,connection = crs),pre)
      equation 
        first_pre = Prefix.prefixFirst(pre);
        cr = Prefix.prefixToCref(first_pre);
        crs_1 = Util.listSelect1R(crs, cr, Exp.crefPrefixOf);
      then
        Connect.SETS(set,crs_1);
  end matchcontinue;
end filterConnectionSetCrefs;

protected function partialInstClassdef "function: partialInstClassdef
 
  This function is used by partial_inst_class_in for instantiating local
  class definitons and inherited class definitions only.
"
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.ClassDef inClassDef;
  input SCode.Restriction inRestriction;
  input Boolean inBoolean;
  input InstDims inInstDims;
  output Env outEnv;
  output ClassInf.State outState;
algorithm 
  (outEnv,outState):=
  matchcontinue (inEnv,inMod,inPrefix,inSets,inState,inClassDef,inRestriction,inBoolean,inInstDims)
    local
      ClassInf.State ci_state1,ci_state,new_ci_state,new_ci_state_1,ci_state2;
      list<SCode.Element> cdefelts,extendselts,els,allEls;
      list<Env.Frame> env1,env2,env,cenv,cenv_2,env_2,env3;
      Types.Mod emods,mods,m,mod_1,mods_1,mods_2;
      list<tuple<SCode.Element, Mod>> extcomps,allEls2,constantEls;
      list<SCode.Equation> eqs2,initeqs2,eqs,initeqs;
      list<SCode.Algorithm> alg2,initalg2,alg,initalg;
      Prefix.Prefix pre;
      Connect.Sets csets;
      SCode.Restriction re,r;
      Boolean prot,enc2;
      InstDims inst_dims;
      SCode.Class c;
      String cn2,cns,scope_str;
      Absyn.Path cn;
      Option<list<Absyn.Subscript>> ad;
      SCode.Mod mod;
    case (env,mods,pre,csets,ci_state,SCode.PARTS(elementLst = els,equationLst = eqs,initialEquation = initeqs,
      		algorithmLst = alg,initialAlgorithm = initalg),re,prot,inst_dims)
      		  local String str,str2,str3;
      		  Real t1,t2,time; Boolean b;
      equation 
        ci_state1 = ClassInf.trans(ci_state, ClassInf.NEWDEF());
        cdefelts = classdefAndImpElts(els);
        extendselts = extendsElts(els);
        env1 = addClassdefsToEnv(env, cdefelts, true) " CLASSDEF & IMPORT nodes are added to env" ;
        (env2,emods,extcomps,eqs2,initeqs2,alg2,initalg2) = partialInstExtendsList(env1, mods, extendselts, ci_state, true) "2. EXTENDS Nodes inst_extends_list only flatten inhteritance structure. It does not perform component instantiations." ;
				allEls = listAppend(extendselts,els);
				allEls2=addNomod(allEls);
				constantEls = constantEls(allEls2) " Retrieve all constants";
				env3 = addComponentsToEnv(env2, mods, pre, csets, ci_state, constantEls, constantEls, 
          {}, inst_dims, false);
				 (_,env3,_,ci_state2,_) = instElementList(env3, mods, pre, csets, ci_state1, constantEls, inst_dims, true) "instantiate constants";
      then
        (env3,ci_state2);
    case (env,mods,pre,csets,ci_state,SCode.DERIVED(short = cn,absynArrayDimOption = ad,mod = mod),re,prot,inst_dims) /* This rule describes how to instantiate a derived class definition */ 
      equation 
        ((c as SCode.CLASS(cn2,_,enc2,r,_)),cenv) = Lookup.lookupClass(env, cn, true);
        cenv_2 = Env.openScope(cenv, enc2, SOME(cn2));
        m = Mod.lookupModificationP(mods, cn);
        mod_1 = Mod.elabMod(env, pre, mod, false) "FIXME: impl" ;
        new_ci_state = ClassInf.start(r, cn2);
        mods_1 = Mod.merge(mods, m, cenv_2, pre);
        mods_2 = Mod.merge(mods_1, mod_1, cenv_2, pre);
        (env_2,new_ci_state_1) = partialInstClassIn(cenv_2, mods_2, pre, csets, new_ci_state, c, prot, 
          inst_dims);
      then
        (env_2,new_ci_state_1);
    case (env,mods,pre,csets,ci_state,SCode.DERIVED(short = cn,absynArrayDimOption = ad,mod = mod),re,prot,inst_dims) /* If the class is derived from a class that can not be found in the environment, this rule prints an error message. */ 
      equation 
        failure((_,_) = Lookup.lookupClass(env, cn, false));
        cns = Absyn.pathString(cn);
        scope_str = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_ERROR, {cns,scope_str});
      then
        fail();
  end matchcontinue;
end partialInstClassdef;

protected function constantEls "Returns only elements that are constants.
author: PA

Used buy partialInstClassdef to instantiate constants in packages.
"
input list<tuple<SCode.Element, Mod>> elements;
output list<tuple<SCode.Element, Mod>> outElements;
algorithm 
  outElements := matchcontinue (elements) 
  local 
    SCode.Attributes attr;
    SCode.Variability vari;
    SCode.Element el;
    Types.Mod m;
    list<tuple<SCode.Element, Mod>> els,els1;
  	case	({}) then {};
  	  
 	  case	((el as SCode.COMPONENT(attributes=attr),m)::els) local String str;
 	    equation
				SCode.CONST() = SCode.attrVariability(attr);
 	      els1 = constantEls(els);
	  then ((el,m)::els1);
	    
	  case (_::els)
	    equation
	      els1 = constantEls(els);
	   then els1;
  end matchcontinue;
end constantEls;

protected function updateCompeltsMods "function: updateCompeltsMods
  author: PA
 
  This function updates component modifiers to typed modifiers.
  Typed modifiers are needed  to merge modifiers and to be able to 
  fully instantiate a component.
"
  input Env inEnv;
  input Prefix inPrefix;
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst;
  input ClassInf.State inState;
  input Connect.Sets inSets;
  input Boolean inBoolean;
  output list<tuple<SCode.Element, Mod>> outTplSCodeElementModLst;
  output Env outEnv;
  output Connect.Sets outSets;
algorithm 
  (outTplSCodeElementModLst,outEnv,outSets):=
  matchcontinue (inEnv,inPrefix,inTplSCodeElementModLst,inState,inSets,inBoolean)
    local
      list<Env.Frame> env,env2,env3;
      Prefix.Prefix pre;
      Connect.Sets csets;
      SCode.Mod umod;
      list<Absyn.ComponentRef> crefs;
      Types.Mod cmod_1,cmod;
      list<tuple<SCode.Element, Mod>> res,xs;
      SCode.Element comp;
      ClassInf.State ci_state;
      Boolean impl;
    case (env,pre,{},_,csets,_) then ({},env,csets); 
    case (env,pre,((comp,cmod) :: xs),ci_state,csets,impl)
      equation 
        umod = Mod.unelabMod(cmod);
        crefs = getCrefFromMod(umod);
        (env2,csets) = updateComponentsInEnv(cmod, crefs, env, ci_state, csets, impl);
        cmod_1 = Mod.updateMod(env2, pre, cmod, impl);
        (res,env3,csets) = updateCompeltsMods(env2, pre, xs, ci_state, csets, impl);
      then
        (((comp,cmod_1) :: res),env3,csets);
  end matchcontinue;
end updateCompeltsMods;

protected function getOptionArraydim "function: getOptionArraydim
 
  Return the Arraydim of an optional arradim. Empty list returned if no 
  arraydim present.
"
  input Option<Absyn.ArrayDim> inAbsynArrayDimOption;
  output Absyn.ArrayDim outArrayDim;
algorithm 
  outArrayDim:=
  matchcontinue (inAbsynArrayDimOption)
    local list<Absyn.Subscript> dim;
    case (SOME(dim)) then dim; 
    case (NONE) then {}; 
  end matchcontinue;
end getOptionArraydim;

protected function instExtendsList "function: instExtendsList 
  author: PA
  
  This function flattens out the inheritance structure of a class.
  It takes an SCode.Element list and flattens out the extends nodes
  of that list. The result is a list of components and lists of equations
  and algorithms.
"
  input Env inEnv;
  input Mod inMod;
  input list<SCode.Element> inSCodeElementLst;
  input ClassInf.State inState;
  input Boolean inBoolean;
  output Env outEnv1;
  output Mod outMod2;
  output list<tuple<SCode.Element, Mod>> outTplSCodeElementModLst3;
  output list<SCode.Equation> outSCodeEquationLst4;
  output list<SCode.Equation> outSCodeEquationLst5;
  output list<SCode.Algorithm> outSCodeAlgorithmLst6;
  output list<SCode.Algorithm> outSCodeAlgorithmLst7;
algorithm 
  (outEnv1,outMod2,outTplSCodeElementModLst3,outSCodeEquationLst4,outSCodeEquationLst5,outSCodeAlgorithmLst6,outSCodeAlgorithmLst7):=
  matchcontinue (inEnv,inMod,inSCodeElementLst,inState,inBoolean)
    local
      SCode.Class c;
      String cn,s,scope_str;
      Boolean encf,impl;
      SCode.Restriction r;
      list<Env.Frame> cenv,cenv1,cenv3,env2,env,env_1;
      Types.Mod outermod,mod_1,mod_2,mods,mods_1,emod_1,mod;
      list<SCode.Element> els,els_1,rest;
      list<SCode.Equation> eq1,ieq1,eq1_1,ieq1_1,eq2,ieq2,eq3,ieq3,eq,ieq,initeq2;
      list<SCode.Algorithm> alg1,ialg1,alg1_1,ialg1_1,alg2,ialg2,alg3,ialg3,alg,ialg;
      Absyn.Path tp_1,tp;
      ClassInf.State new_ci_state,ci_state;
      list<tuple<SCode.Element, Mod>> compelts1,compelts2,compelts,compelts3;
      SCode.Mod emod;
      SCode.Element elt;
    case (env,mod,(SCode.EXTENDS(path = tp,mod = emod) :: rest),ci_state,impl) /* inherited initial equations inherited algorithms inherited initial algorithms */ 
      equation 
        ((c as SCode.CLASS(cn,_,encf,r,_)),cenv) = Lookup.lookupClass(env, tp, true);
        outermod = Mod.lookupModificationP(mod, Absyn.IDENT(cn));
        (cenv1,els,eq1,ieq1,alg1,ialg1) = instDerivedClasses(cenv, outermod, c, impl);
        tp_1 = makeFullyQualified(cenv1, tp);
        els_1 = addInheritScope(els, tp_1) "Add the scope of the base class to elements" ;
        eq1_1 = addEqnInheritScope(eq1, tp_1);
        ieq1_1 = addEqnInheritScope(ieq1, tp_1);
        alg1_1 = addAlgInheritScope(alg1, tp_1);
        ialg1_1 = addAlgInheritScope(ialg1, tp_1);
        cenv3 = Env.openScope(cenv1, encf, SOME(cn));
        new_ci_state = ClassInf.start(r, cn);
        mod_1 = Mod.elabUntypedMod(emod, cenv3, Prefix.NOPRE());
        mod_2 = Mod.merge(outermod, mod_1, cenv3, Prefix.NOPRE());
        (_,mods,compelts1,eq2,ieq2,alg2,ialg2) = instExtendsList(cenv1, outermod, els_1, ci_state, impl) "recurse to fully flatten extends elements env" ;
        (env2,mods_1,compelts2,eq3,ieq3,alg3,ialg3) = instExtendsList(env, mod, rest, ci_state, impl) "continue with next element in list" ;
        emod_1 = Mod.elabUntypedMod(emod, env2, Prefix.NOPRE()) "corresponding elements. But emod is Absyn.Mod and can not Must merge(mod,emod) here and then apply the bindings to the be elaborated, because for instance extends A(x=y) can reference a variable y defined in A and will thus not be found. On the other hand: A(n=4), n might be a structural parameter that must be set to instantiate A. How could this be solved? Solution: made new function elab_untyped_mod which transforms to a Mod, but set the type information to unknown. We can then perform the merge, and update untyped modifications later (using update_mod), when we are instantiating the components." ;
        mod_1 = Mod.merge(mod, mods_1, env2, Prefix.NOPRE());
        mods_1 = Mod.merge(mod_1, emod_1, env2, Prefix.NOPRE());
        compelts = listAppend(compelts1, compelts2);
        compelts3 = updateComponents(compelts, mods_1, env2) "update components with new merged modifiers" ;
        eq = Util.listFlatten({eq1_1,eq2,eq3});
        ieq = Util.listFlatten({ieq1_1,ieq2,ieq3});
        alg = Util.listFlatten({alg1_1,alg2,alg3});
        ialg = Util.listFlatten({ialg1_1,ialg2,ialg3});
      then
        (env2,mods_1,compelts3,eq,ieq,alg,ialg);
    case (env,mod,(SCode.EXTENDS(path = tp,mod = emod) :: rest),ci_state,impl) /* base class not found */ 
      equation 
        failure(((c as SCode.CLASS(cn,_,encf,r,_)),cenv) = Lookup.lookupClass(env, tp, true));
        s = Absyn.pathString(tp);
        scope_str = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_BASECLASS_ERROR, {s,scope_str});
      then
        fail();
    case (env,mod,(SCode.EXTENDS(path = tp,mod = emod) :: rest),ci_state,impl)
      equation 
        //Debug.fprint("failtrace", "Failed inst_extends_list on EXTENDS\n env:");
        Env.printEnv(env);
      then
        fail();
    case (env,mod,(elt :: rest),ci_state,impl) /* Components that are not EXTENDS */ 
      equation 
        (env_1,mods,compelts2,eq2,initeq2,alg2,ialg2) = instExtendsList(env, mod, rest, ci_state, impl);
      then
        (env_1,mods,((elt,Types.NOMOD()) :: compelts2),eq2,initeq2,alg2,ialg2);
    case (env,mod,{},ci_state,impl) then (env,mod,{},{},{},{},{}); 
    case (_,_,_,_,_)
      equation 
        //Debug.fprint("failtrace", "- inst_extends_list failed\n");
      then
        fail();
  end matchcontinue;
end instExtendsList;

protected function partialInstExtendsList "function: partialInstExtendsList 
  author: PA
  
  This function is the same as instExtendsList, except that it does partial instantiation.
"
  input Env inEnv;
  input Mod inMod;
  input list<SCode.Element> inSCodeElementLst;
  input ClassInf.State inState;
  input Boolean inBoolean;
  output Env outEnv1;
  output Mod outMod2;
  output list<tuple<SCode.Element, Mod>> outTplSCodeElementModLst3;
  output list<SCode.Equation> outSCodeEquationLst4;
  output list<SCode.Equation> outSCodeEquationLst5;
  output list<SCode.Algorithm> outSCodeAlgorithmLst6;
  output list<SCode.Algorithm> outSCodeAlgorithmLst7;
algorithm 
  (outEnv1,outMod2,outTplSCodeElementModLst3,outSCodeEquationLst4,outSCodeEquationLst5,outSCodeAlgorithmLst6,outSCodeAlgorithmLst7):=
  matchcontinue (inEnv,inMod,inSCodeElementLst,inState,inBoolean)
    local
      SCode.Class c;
      String cn,s,scope_str;
      Boolean encf,impl;
      SCode.Restriction r;
      list<Env.Frame> cenv,cenv1,cenv3,env2,env,env_1;
      Types.Mod outermod,mod_1,mod_2,mods,mods_1,emod_1,mod;
      list<SCode.Element> els,els_1,rest;
      list<SCode.Equation> eq1,ieq1,eq1_1,ieq1_1,eq2,ieq2,eq3,ieq3,eq,ieq,initeq2;
      list<SCode.Algorithm> alg1,ialg1,alg1_1,ialg1_1,alg2,ialg2,alg3,ialg3,alg,ialg;
      Absyn.Path tp_1,tp;
      ClassInf.State new_ci_state,ci_state;
      list<tuple<SCode.Element, Mod>> compelts1,compelts2,compelts,compelts3;
      SCode.Mod emod;
      SCode.Element elt;
    case (env,mod,(SCode.EXTENDS(path = tp,mod = emod) :: rest),ci_state,impl) /* inherited initial equations inherited algorithms inherited initial algorithms */ 
      equation 
        ((c as SCode.CLASS(cn,_,encf,r,_)),cenv) = Lookup.lookupClass(env, tp, true);
        outermod = Mod.lookupModificationP(mod, Absyn.IDENT(cn));
        (cenv1,els,eq1,ieq1,alg1,ialg1) = instDerivedClasses(cenv, outermod, c, impl);
        tp_1 = makeFullyQualified(cenv1, tp);
        els_1 = addInheritScope(els, tp_1) "Add the scope of the base class to elements" ;
        cenv3 = Env.openScope(cenv1, encf, SOME(cn));
        new_ci_state = ClassInf.start(r, cn);
        mod_1 = Mod.elabUntypedMod(emod, cenv3, Prefix.NOPRE());
        mod_2 = Mod.merge(outermod, mod_1, cenv3, Prefix.NOPRE());
        (_,mods,compelts1,eq2,ieq2,alg2,ialg2) = instExtendsList(cenv1, outermod, els_1, ci_state, impl) "recurse to fully flatten extends elements env" ;
        (env2,mods_1,compelts2,eq3,ieq3,alg3,ialg3) = instExtendsList(env, mod, rest, ci_state, impl) "continue with next element in list" ;
        emod_1 = Mod.elabUntypedMod(emod, env2, Prefix.NOPRE()) "corresponding elements. But emod is Absyn.Mod and can not Must merge(mod,emod) here and then apply the bindings to the be elaborated, because for instance extends A(x=y) can reference a variable y defined in A and will thus not be found. On the other hand: A(n=4), n might be a structural parameter that must be set to instantiate A. How could this be solved? Solution: made new function elab_untyped_mod which transforms to a Mod, but set the type information to unknown. We can then perform the merge, and update untyped modifications later (using update_mod), when we are instantiating the components." ;
        mod_1 = Mod.merge(mod, mods_1, env2, Prefix.NOPRE());
        mods_1 = Mod.merge(mod_1, emod_1, env2, Prefix.NOPRE());
        compelts = listAppend(compelts2, compelts1);
        compelts3 = updateComponents(compelts, mods_1, env2) "update components with new merged modifiers" ;
      then
        (env2,mods_1,compelts3,{},{},{},{});
    case (env,mod,(SCode.EXTENDS(path = tp,mod = emod) :: rest),ci_state,impl) /* base class not found */ 
      equation 
        failure(((c as SCode.CLASS(cn,_,encf,r,_)),cenv) = Lookup.lookupClass(env, tp, true));
        s = Absyn.pathString(tp);
        scope_str = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_BASECLASS_ERROR, {s,scope_str});
      then
        fail();
    case (env,mod,(SCode.EXTENDS(path = tp,mod = emod) :: rest),ci_state,impl)
      equation 
        //Debug.fprint("failtrace", "Failed inst_extends_list on EXTENDS\n env:");
        Env.printEnv(env);
      then
        fail();
    case (env,mod,(elt :: rest),ci_state,impl) /* Components that are not EXTENDS */ 
      equation 
        (env_1,mods,compelts2,eq2,initeq2,alg2,ialg2) = instExtendsList(env, mod, rest, ci_state, impl);
      then
        (env_1,mods,((elt,Types.NOMOD()) :: compelts2),eq2,initeq2,alg2,ialg2);
    case (env,mod,{},ci_state,impl) then (env,mod,{},{},{},{},{}); 
    case (_,_,_,_,_)
      equation 
        //Debug.fprint("failtrace", "- inst_extends_list failed\n");
      then
        fail();
  end matchcontinue;
end partialInstExtendsList;


protected function addInheritScope "function: addInheritScope
  author: PA
 
  Adds the optional base class in a SCode.COMPONENTS to indicate which base 
  class the component originates from. This is needed in instantiation to 
  be able to look up classes, etc. from the scope where the component is 
  defined.
"
  input list<SCode.Element> inSCodeElementLst;
  input Absyn.Path inPath;
  output list<SCode.Element> outSCodeElementLst;
algorithm 
  outSCodeElementLst:=
  matchcontinue (inSCodeElementLst,inPath)
    local
      list<SCode.Element> res,xs;
      String a;
      Boolean b,c,d;
      SCode.Attributes e;
      Absyn.Path f,tp;
      SCode.Mod g;
      Option<Absyn.Comment> comment;
      SCode.Element x;
    case ({},_) then {}; 
    case ((SCode.COMPONENT(component = a,final_ = b,replaceable_ = c,protected_ = d,attributes = e,type_ = f,mod = g,this = comment) :: xs),tp)
      equation 
        res = addInheritScope(xs, tp);
      then
        (SCode.COMPONENT(a,b,c,d,e,f,g,SOME(tp),comment) :: res);
    case ((SCode.CLASSDEF(name = a,final_ = b,replaceable_ = c,class_ = d) :: xs),tp)
      local SCode.Class d;
      equation 
        res = addInheritScope(xs, tp);
      then
        (SCode.CLASSDEF(a,b,c,d,SOME(tp)) :: res);
    case ((x :: xs),tp)
      equation 
        res = addInheritScope(xs, tp);
      then
        (x :: res);
    case (_,_)
      equation 
        print("add_inherit_scope failed\n");
      then
        fail();
  end matchcontinue;
end addInheritScope;

protected function addEqnInheritScope "function: addEqnInheritScope
  author: PA
 
  Adds the optional base class in a SCode.EQUATION to indicate which 
  base class the equation originates from. This is needed in instantiation
  to be able to look up e.g. constants, etc. from the scope where the 
  equation  is defined.
"
  input list<SCode.Equation> inSCodeEquationLst;
  input Absyn.Path inPath;
  output list<SCode.Equation> outSCodeEquationLst;
algorithm 
  outSCodeEquationLst:=
  matchcontinue (inSCodeEquationLst,inPath)
    local
      list<SCode.Equation> res,xs;
      SCode.EEquation e;
      Absyn.Path tp;
    case ({},_) then {}; 
    case ((SCode.EQUATION(eEquation = e) :: xs),tp)
      equation 
        res = addEqnInheritScope(xs, tp);
      then
        (SCode.EQUATION(e,SOME(tp)) :: res);
  end matchcontinue;
end addEqnInheritScope;

protected function addAlgInheritScope "function: addAlgInheritScope
  author: PA
 
  Adds the optional base class in a SCode.Algorithm to indicate which 
  base class the algorithm originates from. This is needed in instantiation
  to be able to look up e.g. constants, etc. from the scope where the 
  algorithm is defined.
"
  input list<SCode.Algorithm> inSCodeAlgorithmLst;
  input Absyn.Path inPath;
  output list<SCode.Algorithm> outSCodeAlgorithmLst;
algorithm 
  outSCodeAlgorithmLst:=
  matchcontinue (inSCodeAlgorithmLst,inPath)
    local
      list<SCode.Algorithm> res,xs;
      list<Absyn.Algorithm> a;
      Absyn.Path tp;
    case ({},_) then {}; 
    case ((SCode.ALGORITHM(absynAlgorithmLst = a) :: xs),tp)
      equation 
        res = addAlgInheritScope(xs, tp);
      then
        (SCode.ALGORITHM(a,SOME(tp)) :: res);
  end matchcontinue;
end addAlgInheritScope;

public function addNomod "function: addNomod 
 
  This function takes an SCode.Element list and tranforms it into a 
  (SCode.Element Mod) list by inserting Types.NOMOD for each element.
  Used to transform elements into a uniform list 
  combined from inherited elements and ordinary elements.
"
  input list<SCode.Element> inSCodeElementLst;
  output list<tuple<SCode.Element, Mod>> outTplSCodeElementModLst;
algorithm 
  outTplSCodeElementModLst:=
  matchcontinue (inSCodeElementLst)
    local
      list<tuple<SCode.Element, Mod>> res;
      SCode.Element x;
      list<SCode.Element> xs;
    case {} then {}; 
    case ((x :: xs))
      equation 
        res = addNomod(xs);
      then
        ((x,Types.NOMOD()) :: res);
  end matchcontinue;
end addNomod;

protected function updateComponents "function: updateComponents
  author: PA
 
  This function takes a list of components and a Mod and returns a list of
  components  with the modifiers updated.  The function is used when 
  flattening the inheritance structure, resulting in a list of components 
  to insert into the class definition. For instance 
  model A 
    extends B(modifiers) 
  end A; 
  will result in a list of components 
  from B for which \'modifiers\' should be applied to.
"
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst;
  input Mod inMod;
  input Env inEnv;
  output list<tuple<SCode.Element, Mod>> outTplSCodeElementModLst;
algorithm 
  outTplSCodeElementModLst:=
  matchcontinue (inTplSCodeElementModLst,inMod,inEnv)
    local
      Types.Mod cmod2,mod_1,cmod,mod,emod;
      list<tuple<SCode.Element, Mod>> res,xs;
      SCode.Element comp,c;
      String id;
      list<Env.Frame> env;
    case ({},_,_) then {}; 
    case ((((comp as SCode.COMPONENT(component = id)),cmod) :: xs),mod,env)
      equation 
        cmod2 = Mod.lookupCompModification(mod, id);
        mod_1 = Mod.merge(cmod, cmod2, env, Prefix.NOPRE());
        res = updateComponents(xs, mod, env);
      then
        ((comp,mod_1) :: res);
    case ((((c as SCode.EXTENDS(path = _)),emod) :: xs),mod,env)
      equation 
        res = updateComponents(xs, mod, env);
      then
        ((c,emod) :: res);
    case ((((c as SCode.CLASSDEF(name = _)),cmod) :: xs),mod,env)
      equation 
        res = updateComponents(xs, mod, env);
      then
        ((c,cmod) :: res);
    case ((((c as SCode.IMPORT(import_ = _)),_) :: xs),mod,env)
      equation 
        res = updateComponents(xs, mod, env);
      then
        ((c,Types.NOMOD()) :: res);
    case (_,_,_)
      equation 
        //Debug.fprint("failtrace", "-update_components failed\n");
      then
        fail();
  end matchcontinue;
end updateComponents;

protected function noImportElements "function: noImportElements
 
  Returns all elements except imports, i.e. filter out import elements.
"
  input list<SCode.Element> inSCodeElementLst;
  output list<SCode.Element> outSCodeElementLst;
algorithm 
  outSCodeElementLst:=
  matchcontinue (inSCodeElementLst)
    local
      list<SCode.Element> elt,rest;
      SCode.Element e;
    case {} then {}; 
    case (SCode.IMPORT(import_ = _) :: rest)
      equation 
        elt = noImportElements(rest);
      then
        elt;
    case (e :: rest)
      equation 
        elt = noImportElements(rest);
      then
        (e :: elt);
  end matchcontinue;
end noImportElements;

protected function instDerivedClasses "function: instDerivedClasses
  author: PA
  
  This function takes a class definition and returns the
  elements and equations and algorithms of the class.
  If the class is derived, the class is looked up and the 
  derived class parts are fetched.
"
  input Env inEnv;
  input Mod inMod;
  input SCode.Class inClass;
  input Boolean inBoolean;
  output Env outEnv1;
  output list<SCode.Element> outSCodeElementLst2;
  output list<SCode.Equation> outSCodeEquationLst3;
  output list<SCode.Equation> outSCodeEquationLst4;
  output list<SCode.Algorithm> outSCodeAlgorithmLst5;
  output list<SCode.Algorithm> outSCodeAlgorithmLst6;
algorithm 
  (outEnv1,outSCodeElementLst2,outSCodeEquationLst3,outSCodeEquationLst4,outSCodeAlgorithmLst5,outSCodeAlgorithmLst6):=
  matchcontinue (inEnv,inMod,inClass,inBoolean)
    local
      list<SCode.Element> elt_1,elt;
      list<Env.Frame> env,cenv;
      Types.Mod mod;
      list<SCode.Equation> eq,ieq;
      list<SCode.Algorithm> alg,ialg;
      SCode.Class c;
      Absyn.Path tp;
      SCode.Mod dmod;
      Boolean impl;
    case (env,mod,SCode.CLASS(parts = SCode.PARTS(elementLst = elt,equationLst = eq,initialEquation = ieq,algorithmLst = alg,initialAlgorithm = ialg)),_)
      equation 
        elt_1 = noImportElements(elt);
      then
        (env,elt_1,eq,ieq,alg,ialg);
    case (env,mod,SCode.CLASS(parts = SCode.DERIVED(short = tp,mod = dmod)),impl)
      equation 
        (c,cenv) = Lookup.lookupClass(env, tp, true);
        (env,elt,eq,ieq,alg,ialg) = instDerivedClasses(cenv, mod, c, impl) "Mod.lookup_modification_p(mod, c) => innermod & We have to merge and apply modifications as well!" ;
      then
        (env,elt,eq,ieq,alg,ialg);
    case (_,_,_,_)
      equation 
        //Debug.fprint("failtrace", "- inst_derived_classes failed\n");
      then
        fail();
  end matchcontinue;
end instDerivedClasses;

protected function instElementList "function: instElementList
  author: PA
 
  Moved to inst_classdef, FIXME: Move commments later
  Instantiate elements one at a time, and concatenate the resulting
  lists of equations.
  P.A, Modelica1.4: (allows declare before use)
  1. \"First names of declared local classes (and components) are found. 
      Redeclarations are performed.\"
  This means that we first handle all CLASSDEF nodes and apply modifiers and 
  declarations to them and also COMPONENT nodes to add the variables to the
  environment.
  2. Second, \"base-classes are looked up, flattened and inserted into the 
             class.\"
  This means that all EXTENDS nodes are handled.
  3. Third, \"Flatten the class, apply modifiers and instantiate all local
 	    elements.\"
  This handles COMPONENT nodes.
"
  input Env inEnv1;
  input Mod inMod2;
  input Prefix inPrefix3;
  input Connect.Sets inSets4;
  input ClassInf.State inState5;
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst6;
  input InstDims inInstDims7;
  input Boolean inBoolean8;
  output list<DAE.Element> outDAEElementLst;
  output Env outEnv;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output list<Types.Var> outTypesVarLst;
algorithm 
  (outDAEElementLst,outEnv,outSets,outState,outTypesVarLst):=
  matchcontinue (inEnv1,inMod2,inPrefix3,inSets4,inState5,inTplSCodeElementModLst6,inInstDims7,inBoolean8,inBoolean9)
    local
      list<Env.Frame> env,env_1,env_2;
      Connect.Sets csets,csets_1,csets_2;
      ClassInf.State ci_state,ci_state_1,ci_state_2;
      list<DAE.Element> dae1,dae2,dae;
      list<Types.Var> tys1,tys2,tys;
      Types.Mod mod;
      Prefix.Prefix pre;
      tuple<SCode.Element, Mod> el;
      list<tuple<SCode.Element, Mod>> els;
      InstDims inst_dims;
      Boolean impl;
    case (env,_,_,csets,ci_state,{},_,_) then ({},env,csets,ci_state,{}); 
    case (env,mod,pre,csets,ci_state,(el :: els),inst_dims,impl) /* most work done in inst_element. */ 
      equation 
        (dae1,env_1,csets_1,ci_state_1,tys1) = instElement(env, mod, pre, csets, ci_state, el, inst_dims, impl);
        (dae2,env_2,csets_2,ci_state_2,tys2) = instElementList(env_1, mod, pre, csets_1, ci_state_1, els, inst_dims, impl);
        tys = listAppend(tys1, tys2);
        dae = listAppend(dae1, dae2);
      then
        (dae,env_2,csets_2,ci_state_2,tys);
    case (_,_,_,_,_,els,_,_)
      equation 
        //Debug.fprint("failtrace", "- inst_element_list failed\n");
      then
        fail();
  end matchcontinue;
end instElementList;

protected function classdefElts2 "function: classde_elts2
  author: PA
 
  This function filters out the class definitions (ElementMod) list.
"
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst;
  output list<SCode.Element> outSCodeElementLst;
algorithm 
  outSCodeElementLst:=
  matchcontinue (inTplSCodeElementModLst)
    local
      list<SCode.Element> res;
      SCode.Element cdef;
      list<tuple<SCode.Element, Mod>> xs;
    case ({}) then {}; 
    case ((((cdef as SCode.CLASSDEF(name = _)),_) :: xs))
      equation 
        res = classdefElts2(xs);
      then
        (cdef :: res);
    case ((_ :: xs))
      equation 
        res = classdefElts2(xs);
      then
        res;
  end matchcontinue;
end classdefElts2;

protected function classdefAndImpElts "function: classdefAndImpElts
  author: PA
 
  This function filters out the class definitions and import statements
  of an Element list.
"
  input list<SCode.Element> inSCodeElementLst;
  output list<SCode.Element> outSCodeElementLst;
algorithm 
  outSCodeElementLst:=
  matchcontinue (inSCodeElementLst)
    local
      list<SCode.Element> res,xs;
      SCode.Element cdef,imp;
    case ({}) then {}; 
    case (((cdef as SCode.CLASSDEF(name = _)) :: xs))
      equation 
        res = classdefAndImpElts(xs);
      then
        (cdef :: res);
    case (((imp as SCode.IMPORT(import_ = _)) :: xs))
      equation 
        res = classdefAndImpElts(xs);
      then
        (imp :: res);
    case ((_ :: xs))
      equation 
        res = classdefAndImpElts(xs);
      then
        res;
  end matchcontinue;
end classdefAndImpElts;

protected function extendsElts "function: extendsElts
  author: PA
 
  This function filters out the extends Element\'s in an Element list
"
  input list<SCode.Element> inSCodeElementLst;
  output list<SCode.Element> outSCodeElementLst;
algorithm 
  outSCodeElementLst:=
  matchcontinue (inSCodeElementLst)
    local
      list<SCode.Element> res,xs;
      SCode.Element cdef;
    case ({}) then {}; 
    case (((cdef as SCode.EXTENDS(path = _)) :: xs))
      equation 
        res = extendsElts(xs);
      then
        (cdef :: res);
    case ((_ :: xs))
      equation 
        res = extendsElts(xs);
      then
        res;
  end matchcontinue;
end extendsElts;

protected function componentElts "function: componentElts
  author: PA
 
  This function filters out the component Element\'s in an Element list
"
  input list<SCode.Element> inSCodeElementLst;
  output list<SCode.Element> outSCodeElementLst;
algorithm 
  outSCodeElementLst:=
  matchcontinue (inSCodeElementLst)
    local
      list<SCode.Element> res,xs;
      SCode.Element cdef;
    case ({}) then {}; 
    case (((cdef as SCode.COMPONENT(component = _)) :: xs))
      equation 
        res = componentElts(xs);
      then
        (cdef :: res);
    case ((_ :: xs))
      equation 
        res = componentElts(xs);
      then
        res;
  end matchcontinue;
end componentElts;

protected function addClassdefsToEnv "function: addClassdefsToEnv
  author: PA
 
  This function adds classdefinitions and import statements to the 
  environment.
"
  input Env inEnv;
  input list<SCode.Element> inSCodeElementLst;
  input Boolean inBoolean;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv,inSCodeElementLst,inBoolean)
    local
      list<Env.Frame> env,env_1,env_2;
      SCode.Class cl;
      list<SCode.Element> els;
      Boolean impl;
      Absyn.Import imp;
    case (env,els,impl) 
      local String s;
      equation
      	env_1 = addClassdefsToEnv2(env,els,impl);
      	env_2 = addClassdefsToEnv2(env_1,els,impl) "classes added with correct env"; 
       then env_2;     
  end matchcontinue;
end addClassdefsToEnv;

protected function addClassdefsToEnv2 "function: addClassdefsToEnv2
  author: PA
 
  Helper relation to addClassdefsToEnv
"
  input Env inEnv;
  input list<SCode.Element> inSCodeElementLst;
  input Boolean inBoolean;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv,inSCodeElementLst,inBoolean)
    local
      list<Env.Frame> env,env_1,env_2;
      SCode.Class cl;
      list<SCode.Element> xs;
      Boolean impl;
      Absyn.Import imp;
    case (env,{},_) then env; 
    case (env,(SCode.CLASSDEF(class_ = cl) :: xs),impl)
      local String s;
      equation 
        env_1 = Env.extendFrameC(env, cl);
        env_2 = addClassdefsToEnv2(env_1, xs, impl);
      then
        env_2;
    case (env,(SCode.IMPORT(import_ = imp) :: xs),impl)
      equation 
        env_1 = Env.extendFrameI(env, imp);
        env_2 = addClassdefsToEnv2(env_1, xs, impl);
      then
        env_2;
  end matchcontinue;
end addClassdefsToEnv2;

protected function isStructuralParameter "function: isStructuralParameter
  author: PA
 
  This function investigates a component to find out if it is a structural 
  parameter.
  This is achieved by looking at the restriction to find if it is a parameter
  and by investigating all components to find it is used in array dimensions 
  of the component. A parameter can also be structural if is is used
  in an if equation with different number of equations in each branch.
"
  input SCode.Variability inVariability;
  input Absyn.ComponentRef inComponentRef;
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst;
  input list<SCode.Equation> inSCodeEquationLst;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inVariability,inComponentRef,inTplSCodeElementModLst,inSCodeEquationLst)
    local
      list<Absyn.ComponentRef> crefs;
      Boolean b1,b2,res;
      SCode.Variability param;
      Absyn.ComponentRef compname;
      list<tuple<SCode.Element, Mod>> allcomps;
      list<SCode.Equation> eqns;
    case (SCode.CONST(),_,_,_) then false;  /* constants does not need to be checked. 
	   Must return false here to prevent constants from be outputed
	   as structural parameters, i.e. \"parameter\" in DAE, which is 
	   incorrect
	 */ 
    case (param,compname,allcomps,eqns) /* Check if structural:
	 1. By investigating array dimensions.
	 2. By investigating if-equations.
	 */ 
      equation 
        true = SCode.isParameterOrConst(param);
        crefs = getCrefsFromCompdims(allcomps);
        b1 = memberCrefs(compname, crefs);
        b2 = isStructuralIfEquationParameter(compname, eqns);
        res = boolOr(b1, b2);
      then
        res;
    case (_,_,_,_) then false; 
  end matchcontinue;
end isStructuralParameter;

protected function isStructuralIfEquationParameter "function isStructuralIfEquationParameter
  author: PA
 
  This function checks if a parameter is structural because it is present
  in the condition expression of an if equation.
"
  input Absyn.ComponentRef inComponentRef;
  input list<SCode.Equation> inSCodeEquationLst;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef,inSCodeEquationLst)
    local
      list<Absyn.ComponentRef> crefs;
      Absyn.ComponentRef compname;
      Absyn.Exp cond;
      Boolean res;
      list<SCode.Equation> eqns;
    case (_,{}) then false; 
    case (compname,(SCode.EQUATION(eEquation = SCode.EQ_IF(conditional = cond)) :: _))
      equation 
        crefs = Absyn.getCrefFromExp(cond);
        true = memberCrefs(compname, crefs);
      then
        true;
    case (compname,(_ :: eqns))
      equation 
        res = isStructuralIfEquationParameter(compname, eqns);
      then
        res;
  end matchcontinue;
end isStructuralIfEquationParameter;

protected function addComponentsToEnv "function: addComponentsToEnv
  author: PA
 
  Since Modelica has removed the declare before use limitation, all 
  components are intially added untyped to the environment, i.e. the 
  SCode.Element is added. This is performed by this function. Later, 
  during the second pass of the instantiation of components, the components 
  are updated  in the environment. This is done by the function 
  update_components_in_env. This function is also responsible for 
  changing parameters into structural  parameters if they are affecting 
  the number of variables or equations. This is needed because Modelica has
  no language construct for structural parameters, i.e. they must be 
  detected by the compiler.
 
  Structural parameters are identified by investigating array dimension 
  sizes of components and by investigating if-equations. If an if-equation
  has a boolean expression controlled by parameter(s), these are structural
  parameters.
"
  input Env inEnv1;
  input Mod inMod2;
  input Prefix inPrefix3;
  input Connect.Sets inSets4;
  input ClassInf.State inState5;
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst6;
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst7;
  input list<SCode.Equation> inSCodeEquationLst8;
  input InstDims inInstDims9;
  input Boolean inBoolean10;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv1,inMod2,inPrefix3,inSets4,inState5,inTplSCodeElementModLst6,inTplSCodeElementModLst7,inSCodeEquationLst8,inInstDims9,inBoolean10)
    local
      list<Env.Frame> env,env_1,env_2;
      Types.Mod mod,cmod;
      Prefix.Prefix pre;
      Connect.Sets csets;
      ClassInf.State cistate;
      SCode.Element comp;
      String n;
      Boolean final_,repl,prot,flow_,impl;
      SCode.Attributes attr;
      list<Absyn.Subscript> ad;
      SCode.Accessibility acc;
      SCode.Variability param;
      Absyn.Direction dir;
      Absyn.Path t;
      SCode.Mod m;
      Option<Absyn.Path> bc;
      Option<Absyn.Comment> comment;
      list<tuple<SCode.Element, Mod>> xs,allcomps,comps;
      list<SCode.Equation> eqns;
      InstDims instdims;
    case (env,_,_,_,_,{},_,_,_,_) then env;  /* implicit inst. */ 
    case (env,mod,pre,csets,cistate,(((comp as SCode.COMPONENT(component = n,final_ = final_,replaceable_ = repl,protected_ = prot,attributes = (attr as SCode.ATTR(arrayDim = ad,flow_ = flow_,RW = acc,parameter_ = param,input_ = dir)),type_ = t,mod = m,baseclass = bc,this = comment)),cmod) :: xs),allcomps,eqns,instdims,impl) /* Check if the component is a structural parameter, change it\'s
	 attribute to STRUCTPARAM. Not structural parameter. No Change. */ 
      equation 
        failure(ClassInf.isFunction(cistate));
        (1 == 0) = true "Functions not considered" ;
        true = isStructuralParameter(param, Absyn.CREF_IDENT(n,{}), allcomps, eqns);
        env_1 = addComponentsToEnv2(env, mod, pre, csets, cistate, 
          {
          (
          SCode.COMPONENT(n,final_,repl,prot,
          SCode.ATTR(ad,flow_,acc,SCode.STRUCTPARAM(),dir),t,m,bc,comment),cmod)}, instdims, impl);
        env_2 = addComponentsToEnv(env_1, mod, pre, csets, cistate, xs, allcomps, eqns, 
          instdims, impl);
      then
        env_2;
    case (env,mod,pre,csets,cistate,(((comp as SCode.COMPONENT(component = n,final_ = final_,replaceable_ = repl,protected_ = prot,attributes = (attr as SCode.ATTR(arrayDim = ad,flow_ = flow_,RW = acc,parameter_ = param,input_ = dir)),type_ = t,mod = m,baseclass = bc,this = comment)),cmod) :: xs),allcomps,eqns,instdims,impl) /* Not structural parameter. No Change. Import statements */ 
      equation 
        env_1 = addComponentsToEnv2(env, mod, pre, csets, cistate, 
          {
          (
          SCode.COMPONENT(n,final_,repl,prot,SCode.ATTR(ad,flow_,acc,param,dir),t,m,
          bc,comment),cmod)}, instdims, impl);
        env_2 = addComponentsToEnv(env_1, mod, pre, csets, cistate, xs, allcomps, eqns, 
          instdims, impl);
      then
        env_2;
    case (env,mod,pre,csets,cistate,((SCode.IMPORT(import_ = _),_) :: xs),allcomps,eqns,instdims,impl) /* Import statements Extends elements */ 
      equation 
        env_2 = addComponentsToEnv(env, mod, pre, csets, cistate, xs, allcomps, eqns, 
          instdims, impl);
      then
        env_2;
    case (env,mod,pre,csets,cistate,((SCode.EXTENDS(path = _),_) :: xs),allcomps,eqns,instdims,impl) /* Extends elements Class definitions */ 
      equation 
        env_2 = addComponentsToEnv(env, mod, pre, csets, cistate, xs, allcomps, eqns, 
          instdims, impl);
      then
        env_2;
    case (env,mod,pre,csets,cistate,((SCode.CLASSDEF(name = _),_) :: xs),allcomps,eqns,instdims,impl) /* Class definitions */ 
      equation 
        env_2 = addComponentsToEnv(env, mod, pre, csets, cistate, xs, allcomps, eqns, 
          instdims, impl);
      then
        env_2;
    case (_,_,_,_,_,comps,_,_,_,_)
      equation 
        //Debug.fprint("failtrace", "- add_components_to_env failed\n");
      then
        fail();
  end matchcontinue;
end addComponentsToEnv;

protected function addComponentsToEnv2 "function addComponentsToEnv2
  Helper function to add_components_to_env. Extends the environment with an 
  untyped variable for the component.
"
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst;
  input InstDims inInstDims;
  input Boolean inBoolean;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv,inMod,inPrefix,inSets,inState,inTplSCodeElementModLst,inInstDims,inBoolean)
    local
      Types.Mod compmod,cmod_1,mods,cmod;
      list<Env.Frame> env_1,env_2,env;
      Prefix.Prefix pre;
      Connect.Sets csets;
      ClassInf.State ci_state;
      SCode.Element comp;
      String n;
      Boolean final_,repl,prot,flow_,impl;
      SCode.Attributes attr;
      list<Absyn.Subscript> ad;
      SCode.Accessibility acc;
      SCode.Variability param;
      Absyn.Direction dir;
      Absyn.Path t;
      SCode.Mod m;
      Option<Absyn.Path> bc;
      Option<Absyn.Comment> comment;
      list<tuple<SCode.Element, Mod>> xs,comps;
      InstDims inst_dims;
    case (env,mods,pre,csets,ci_state,(((comp as SCode.COMPONENT(component = n,final_ = final_,replaceable_ = repl,protected_ = prot,attributes = (attr as SCode.ATTR(arrayDim = ad,flow_ = flow_,RW = acc,parameter_ = param,input_ = dir)),type_ = t,mod = m,baseclass = bc,this = comment)),cmod) :: xs),inst_dims,impl)
      equation 
        compmod = Mod.lookupCompModification(mods, n) "PA: PROBLEM, Modifiers should be merged in this phase, but
	   since undeclared components can not be found (is done in this phase)
	   the modifiers can not be elaborated to get a variable binding.
	   Thus, we need to store the merged modifier for elaboration in the 
	   next stage. 
	   Solution: Save all modifiers in environment...
	 Use type T_NOTYPE instead of as earier trying to instantiate, 
	  since instanitation might fail without having correct 
	  modifications, e.g. when instanitating a partial class that must
	  be redeclared through a modification
	" ;
        cmod_1 = Mod.merge(compmod, cmod, env, pre);
        env_1 = Env.extendFrameV(env, 
          Types.VAR(n,Types.ATTR(flow_,acc,param,dir),prot,
          (Types.T_NOTYPE(),NONE),Types.UNBOUND()), SOME((comp,cmod_1)), false, {}) "comp env" ;
        env_2 = addComponentsToEnv2(env_1, mods, pre, csets, ci_state, xs, inst_dims, impl);
      then
        env_2;
    case (env,_,_,_,_,{},_,_) then env; 
    case (env,_,_,_,_,comps,_,_)
      equation 
        //Debug.fprint("failtrace", "- add_components_to_env2 failed\n");
        //Debug.fprint("failtrace", "\n\n");
      then
        fail();
  end matchcontinue;
end addComponentsToEnv2;

protected function getCrefsFromCompdims "function: getCrefsFromCompdims
  author: PA
 
  This function collects all variables from the dimensionalities of 
  component elements. These variables are candidates for structural 
  parameters.
"
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm 
  outAbsynComponentRefLst:=
  matchcontinue (inTplSCodeElementModLst)
    local
      list<Absyn.ComponentRef> crefs1,crefs2,crefs;
      list<Absyn.Subscript> arraydim;
      list<tuple<SCode.Element, Mod>> xs;
    case ({}) then {}; 
    case (((SCode.COMPONENT(attributes = SCode.ATTR(arrayDim = arraydim)),_) :: xs))
      equation 
        crefs1 = getCrefFromDim(arraydim);
        crefs2 = getCrefsFromCompdims(xs);
        crefs = listAppend(crefs1, crefs2);
      then
        crefs;
    case ((_ :: xs))
      equation 
        crefs = getCrefsFromCompdims(xs);
      then
        crefs;
  end matchcontinue;
end getCrefsFromCompdims;

protected function memberCrefs "function member_cref
  author: PA
 
  This function checks if a componentreferece is a member of a list of 
  component references, disregarding subscripts.
"
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.ComponentRef> inAbsynComponentRefLst;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef,inAbsynComponentRefLst)
    local
      Absyn.ComponentRef cr,cr1;
      list<Absyn.ComponentRef> xs;
      Boolean res;
    case (cr,(cr1 :: xs))
      equation 
        true = Absyn.crefEqual(cr, cr1);
      then
        true;
    case (cr,(cr1 :: xs))
      equation 
        false = Absyn.crefEqual(cr, cr1);
        res = memberCrefs(cr, xs);
      then
        res;
    case (_,_) then false; 
  end matchcontinue;
end memberCrefs;

protected function instElement "function: instElement
 
  This monster function instantiates an element of a class
  definition.  An element is either a class definition, a variable,
  or an `extends\' clause.
  Last two bools are implicit instanitation and implicit package instantiation
"
  input Env inEnv1;
  input Mod inMod2;
  input Prefix inPrefix3;
  input Connect.Sets inSets4;
  input ClassInf.State inState5;
  input tuple<SCode.Element, Mod> inTplSCodeElementMod6;
  input InstDims inInstDims7;
  input Boolean inBoolean8;
  output list<DAE.Element> outDAEElementLst;
  output Env outEnv;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output list<Types.Var> outTypesVarLst;
algorithm 
  (outDAEElementLst,outEnv,outSets,outState,outTypesVarLst):=
  matchcontinue (inEnv1,inMod2,inPrefix3,inSets4,inState5,inTplSCodeElementMod6,inInstDims7,inBoolean8)
    local
      list<Env.Frame> env,env_1,env2,env2_1,cenv,compenv;
      Types.Mod mod,mods,classmod,mm,mods_1,classmod_1,mm_1,m_1,mod1,mod1_1,mod_1,cmod,omod;
      Prefix.Prefix pre,pre_1;
      Connect.Sets csets,csets_1;
      ClassInf.State ci_state;
      Absyn.Import imp;
      InstDims instdims,inst_dims;
      String n,n2,s,scope_str,ns;
      Boolean final_,repl,prot,f2,repl2,impl,flow_;
      SCode.Class cls2,c,cl;
      list<DAE.Element> dae;
      Exp.ComponentRef vn;
      Absyn.ComponentRef owncref;
      list<Absyn.ComponentRef> crefs,crefs2,crefs_1,crefs_2;
      SCode.Element comp,el;
      SCode.Attributes attr;
      list<Absyn.Subscript> ad;
      SCode.Accessibility acc;
      SCode.Variability param;
      Absyn.Direction dir;
      Absyn.Path t;
      SCode.Mod m;
      Option<Absyn.Path> bc;
      Option<Absyn.Comment> comment;
      Option<Types.EqMod> eq;
      list<DimExp> dims;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Binding binding;
      Types.Var new_var;
    case (env,mod,pre,csets,ci_state,(SCode.IMPORT(import_ = imp),_),instdims,_) then ({},env,csets,ci_state,{});  /* imports
	    imports are simply added to the current frame, so that the lookup rule can find them.
	 Import have allready been added to the environment so there 
	  is nothing more to do here.
	 */ 
   /* If a variable is declared multiple times, the first is used */ 
    case (env,mods,pre,csets,ci_state,(SCode.COMPONENT(component = n,final_ = final_,replaceable_ = repl,protected_ = prot),_),_,_) 
      equation 
        (_,NONE,true,_) = Lookup.lookupIdentLocal(env, n);
      then
        ({},env,csets,ci_state,{});
    case (env,mods,pre,csets,ci_state,(SCode.CLASSDEF(name = n),_),_,_) /* Illegal redeclarations */ 
      equation 
        (_,_,_,_) = Lookup.lookupIdentLocal(env, n);
        Error.addMessage(Error.REDECLARE_CLASS_AS_VAR, {n});
      then
        fail();
        
        /* A new class definition
	   	    Put it in the current frame in the environment
	 			*/ 
    case (env,mods,pre,csets,ci_state,(SCode.CLASSDEF(name = n,replaceable_ = true,class_ = c),_),inst_dims,impl) 
      equation 
        ((classmod as Types.REDECL(final_,{(SCode.CLASSDEF(n2,f2,repl2,cls2,_),_)}))) = Mod.lookupModificationP(mods, Absyn.IDENT(n)) "Redeclare of class definition, replaceable is true" ;
        (env_1,dae) = instClassDecl(env, classmod, pre, csets, cls2, inst_dims) "//Debug.fprintln (\"insttr\", \"--Classdef mods\") &
	Debug.fcall (\"insttr\", Mod.print_mod, classmod) &
	//Debug.fprintln (\"insttr\", \"--All mods\") &
	Debug.fcall (\"insttr\", Mod.print_mod, mods) &" ;
      then
        (dae,env_1,csets,ci_state,{});
    case (env,mods,pre,csets,ci_state,(SCode.CLASSDEF(name = n,replaceable_ = false,class_ = c),_),inst_dims,impl)
      equation 
        ((classmod as Types.REDECL(final_,{(SCode.CLASSDEF(n2,f2,repl2,cls2,_),_)}))) = Mod.lookupModificationP(mods, Absyn.IDENT(n)) "Redeclare of class definition, replaceable is false" ;
        Error.addMessage(Error.REDECLARE_NON_REPLACEABLE, {n});
      then
        fail();
    case (env,mods,pre,csets,ci_state,(SCode.CLASSDEF(name = n,class_ = c),_),inst_dims,impl) /* Classdefinition without redeclaration */ 
      equation 
        classmod = Mod.lookupModificationP(mods, Absyn.IDENT(n));
        (env_1,dae) = instClassDecl(env, classmod, pre, csets, c, inst_dims) "//Debug.fprintln (\"insttr\", \"Classdef mods\") &
	Debug.fcall (\"insttr\", Mod.print_mod, classmod) &
	//Debug.fprintln (\"insttr\", \"All mods\") &
	Debug.fcall (\"insttr\", Mod.print_mod, mods) &" ;
      then
        (dae,env_1,csets,ci_state,{});
        
        
        /* A component
	    This is the rule for instantiating a model component.  A
	    component can be a structured subcomponent or a variable,
	    parameter or constant.  All of these are treated in a
	    similar way.
	   
	    Lookup the class name, apply modifications and add the
	    variable to the current frame in the environment. Then
	    instantiate the class with an extended prefix.
	 */
    case (env,mods,pre,csets,ci_state,((comp as SCode.COMPONENT(component = n,final_ = final_,replaceable_ = repl,protected_ = prot,
      		attributes = (attr as SCode.ATTR(arrayDim = ad,flow_ = flow_,RW = acc,parameter_ = param,input_ = dir)),
      		type_ = t,mod = m,baseclass = bc,this = comment)),cmod),inst_dims,impl)  
      		  local String s;
      equation 
        vn = Prefix.prefixCref(pre, Exp.CREF_IDENT(n,{})) "//Debug.fprint(\"insttr\", \"Instantiating component \") &
	//Debug.fprint(\"insttr\", n) & //Debug.fprint(\"insttr\", \"\\n\") &" ;
        classmod = Mod.lookupModificationP(mods, t) "The class definition is fetched from the environment. Then the set of modifications is calculated.  The modificions is the result of merging the modifications from several sources.  The modification stored with the class definition is put in the variable `classmod\', the modification passed to the function_ is extracted and put in the variable `mm\', and the modification that is included in the variable declaration is in the variable `m\'.  All of these are merged so that the correct precedence rules are followed." ;
        mm = Mod.lookupCompModification(mods, n);
        owncref = Absyn.CREF_IDENT(n,{}) "The types in the environment does not have correct Binding.
	   We must update those variables that is found in m into a new environment." ;
        crefs = getCrefFromMod(m);
        crefs2 = getCrefFromDim(ad);
        crefs_1 = Util.listFlatten({crefs,crefs2});
        crefs_2 = removeCrefFromCrefs(crefs_1, owncref);
        env = getDerivedEnv(env, bc);
        (env2,csets) = updateComponentsInEnv(mods, crefs_2, env, ci_state, csets, impl);
        mods_1 = Mod.updateMod(env2, pre, mods, impl) "Update the untyped modifiers to typed ones, and extract class and component modifiers again." ;
        (_,SOME((comp,_)),_,_) = Lookup.lookupIdentLocal(env2, n) "refetch the component from environment, since attributes, etc.
	  might have changed.. comp used in redeclare_type below..." ;
        classmod_1 = Mod.lookupModificationP(mods_1, t);
        mm_1 = Mod.lookupCompModification(mods_1, n);
        m_1 = Mod.elabMod(env2, pre, m, impl);
        mod = Mod.merge(classmod_1, mm_1, env2, pre);
        mod1 = Mod.merge(mod, m_1, env2, pre);
        mod1_1 = Mod.merge(cmod, mod1, env2, pre);
        (SCode.COMPONENT(n,final_,repl,prot,(attr as SCode.ATTR(ad,flow_,acc,param,dir)),t,m,bc,comment),mod_1,env2_1,csets) = redeclareType(mod1_1, comp, env2, pre, ci_state, csets, impl);
        env_1 = getDerivedEnv(env, bc);
        (cl,cenv) = Lookup.lookupClass(env_1, t, true);
        checkProt(prot, mm_1, vn) "If the element is `protected\', and an external modification is applied, it is an error." ;
        eq = Mod.modEquation(mod_1);
        dims = elabArraydim(env2_1, owncref, ad, eq, impl, NONE) "The variable declaration and the (optional) equation modification are inspected for array dimensions." ;
        (compenv,dae,csets_1,ty) = instVar(cenv, ci_state, mod_1, pre, csets, n, cl, attr, dims, {}, 
          inst_dims, impl, comment) "Instantiate the component" ;    
        binding = makeBinding(env2_1, attr, mod_1, ty) "The environment is extended (updated) with the new variable 
	  binding. 
	" ;
        new_var = Types.VAR(n,Types.ATTR(flow_,acc,param,dir),prot,ty,binding) "true in update_frame means the variable is now instantiated." ;
        env_1 = Env.updateFrameV(env2_1, new_var, true, compenv) "type info present Now we can also put the binding into the dae If the type is one of the simple, predifined types a simple variable declaration is added to the DAE. & //Debug.fprint(\"insttr\",\"inst_element Component succeeded\\n\")" ;
      then
        (dae,env_1,csets_1,ci_state,{
          Types.VAR(n,Types.ATTR(flow_,acc,param,dir),prot,ty,binding)});
    case (env,_,pre,csets,ci_state,(SCode.COMPONENT(component = n,final_ = final_,replaceable_ = repl,protected_ = prot,type_ = t),_),_,_) /* If the class lookup in the previous rule fails, this
	  rule catches the error and prints an error message about
	  the unknown class. 
	 Failure => ({},env,csets,ci_state,{}) */ 
      equation 
        failure((cl,cenv) = Lookup.lookupClass(env, t, false));
        s = Absyn.pathString(t);
        scope_str = Env.printEnvPathStr(env);
        pre_1 = Prefix.prefixAdd(n, {}, pre);
        ns = Prefix.printPrefixStr(pre_1);
        Error.addMessage(Error.LOOKUP_ERROR_COMPNAME, {s,scope_str,ns}) "	Debug.fcall (\"instdb\", Env.print_env, env)" ;
      then
        fail();
    case (env,omod,_,_,_,(el,mod),_,_) /* => ({},env,csets,ci_state,{}) */ 
      equation 
        //Debug.fprint("failtrace", "- inst_element failed\n");
        Debug.fcall("failtrace", SCode.printElement, el);
        //Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end instElement;

protected function getDerivedEnv "function: getDerivedEnv
 
  This function returns the environment of a baseclass.
  It is used when instantiating a component defined in a baseclass.
"
  input Env inEnv;
  input Option<Absyn.Path> inAbsynPathOption;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv,inAbsynPathOption)
    local
      list<Env.Frame> env,cenv,cenv_2,env_2,fs;
      Env.Frame top_frame;
      SCode.Class c;
      String cn2;
      Boolean enc2,enc;
      SCode.Restriction r;
      ClassInf.State new_ci_state,new_ci_state_1;
      Option<String> id;
      Env.BinTree cl,tps;
      list<Env.Item> imps;
      list<Exp.ComponentRef> crs;
      Absyn.Path tp;
    case (env,NONE) then env; 
    case ((env as (Env.FRAME(class_1 = id,list_2 = cl,list_3 = tps,list_4 = imps,current6 = crs,encapsulated_7 = enc) :: fs)),SOME(tp)) /* Base classes are fully qualified names, search from top scope This is needed since the environment can be encapsulated, but
	  inherited classes are not affected by this and therefore should
	  search from top scope directly. */ 
      equation 
        top_frame = Env.topFrame(env);
        ((c as SCode.CLASS(cn2,_,enc2,r,_)),cenv) = Lookup.lookupClass({top_frame}, tp, true);
        cenv_2 = Env.openScope(cenv, enc2, SOME(cn2));
        new_ci_state = ClassInf.start(r, cn2);
        (env_2,new_ci_state_1) = partialInstClassIn(cenv_2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          new_ci_state, c, false, {});
      then
        (Env.FRAME(id,cl,tps,imps,env_2,crs,enc) :: fs);
    case (_,_)
      equation 
        //Debug.fprint("failtrace", "-get_derived_env failed\n");
      then
        fail();
  end matchcontinue;
end getDerivedEnv;

protected function removeCrefFromCrefs "function: removeCrefFromCrefs
 
  Removes a variable from a variable list
"
  input list<Absyn.ComponentRef> inAbsynComponentRefLst;
  input Absyn.ComponentRef inComponentRef;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm 
  outAbsynComponentRefLst:=
  matchcontinue (inAbsynComponentRefLst,inComponentRef)
    local
      String n1,n2;
      list<Absyn.ComponentRef> rest_1,rest;
      Absyn.ComponentRef cr1,cr2;
    case ({},_) then {}; 
    case ((cr1 :: rest),cr2)
      equation 
        Absyn.CREF_IDENT(name = n1,subscripts = {}) = cr1;
        Absyn.CREF_IDENT(name = n2,subscripts = {}) = cr2;
        equality(n1 = n2);
        rest_1 = removeCrefFromCrefs(rest, cr2);
      then
        rest_1;
    case ((cr1 :: rest),cr2)
      equation 
        rest_1 = removeCrefFromCrefs(rest, cr2);
      then
        (cr1 :: rest_1);
  end matchcontinue;
end removeCrefFromCrefs;

protected function redeclareType "function: redeclareType
 
  This function takes a \'Mod\' and an SCode.Element and if the modification 
  contains a redeclare of that element, the type is changed and an updated
  element is returned
"
  input Mod inMod;
  input SCode.Element inElement;
  input Env inEnv;
  input Prefix inPrefix;
  input ClassInf.State inState;
  input Connect.Sets inSets;
  input Boolean inBoolean;
  output SCode.Element outElement;
  output Mod outMod;
  output Env outEnv;
  output Connect.Sets outSets;
algorithm 
  (outElement,outMod,outEnv,outSets):=
  matchcontinue (inMod,inElement,inEnv,inPrefix,inState,inSets,inBoolean)
    local
      list<Absyn.ComponentRef> crefs;
      list<Env.Frame> env_1,env;
      Connect.Sets csets;
      Types.Mod m_1,old_m_1,m_2,m_3,m,rmod;
      SCode.Element redecl,newcomp,comp;
      String n1,n2;
      Boolean final_,repl,prot,repl2,prot2,impl,redfin;
      Absyn.Path t,t2;
      SCode.Mod mod,old_mod;
      Option<Absyn.Path> bc;
      Option<Absyn.Comment> comment,comment2;
      list<tuple<SCode.Element, Mod>> rest;
      Prefix.Prefix pre;
      ClassInf.State ci_state;
    case ((m as Types.REDECL(tplSCodeElementModLst = (((redecl as SCode.COMPONENT(component = n1,final_ = final_,replaceable_ = repl,protected_ = prot,type_ = t,mod = mod,baseclass = bc,this = comment)),rmod) :: rest))),SCode.COMPONENT(component = n2,final_ = false,replaceable_ = repl2,protected_ = prot2,type_ = t2,mod = old_mod),env,pre,ci_state,csets,impl) /* Implicit instantation */ 
      equation 
        equality(n1 = n2);
        crefs = getCrefFromMod(mod);
        (env_1,csets) = updateComponentsInEnv(Types.NOMOD(), crefs, env, ci_state, csets, impl) "m" ;
        m_1 = Mod.elabMod(env_1, pre, mod, impl);
        old_m_1 = Mod.elabMod(env_1, pre, old_mod, impl);
        m_2 = Mod.merge(rmod, m_1, env_1, pre);
        m_3 = Mod.merge(m_2, old_m_1, env_1, pre);
      then
        (redecl,m_3,env_1,csets);
    case ((mod as Types.REDECL(final_ = redfin,tplSCodeElementModLst = (((redecl as SCode.COMPONENT(component = n1,final_ = final_,replaceable_ = repl,protected_ = prot,type_ = t,baseclass = bc,this = comment)),rmod) :: rest))),(comp as SCode.COMPONENT(component = n2,final_ = false,replaceable_ = repl2,protected_ = prot2,type_ = t2,this = comment2)),env,pre,ci_state,csets,impl)
      local Types.Mod mod;
      equation 
        failure(equality(n1 = n2));
        (newcomp,mod,env_1,csets) = redeclareType(Types.REDECL(redfin,rest), comp, env, pre, ci_state, 
          csets, impl);
      then
        (newcomp,mod,env_1,csets);
    case (Types.REDECL(final_ = redfin,tplSCodeElementModLst = (_ :: rest)),comp,env,pre,ci_state,csets,impl)
      local Types.Mod mod;
      equation 
        (newcomp,mod,env_1,csets) = redeclareType(Types.REDECL(redfin,rest), comp, env, pre, ci_state, 
          csets, impl);
      then
        (newcomp,mod,env_1,csets);
    case (Types.REDECL(final_ = redfin,tplSCodeElementModLst = {}),comp,env,pre,ci_state,csets,impl) then (comp,Types.NOMOD(),env,csets); 
    case (mod,comp,env,pre,ci_state,csets,impl)
      local Types.Mod mod;
      then
        (comp,mod,env,csets);
    case (_,_,_,_,_,_,_)
      equation 
        //Debug.fprint("failtrace", "- redeclare_type failed\n");
      then
        fail();
  end matchcontinue;
end redeclareType;

protected function instVar "function: instVar
 
  A component element in a class may consist of several subcomponents
  or array elements.  This function is used to instantiate a
  component, instantiating all subcomponents and array elements
  separately.
  P.A: Most of the implementation is moved to inst_var2. inst_var collects 
  dimensions for userdefined types, such that these can be correctly 
  handled by inst_var2 (using inst_array)
"
  input Env inEnv;
  input ClassInf.State inState;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input Ident inIdent;
  input SCode.Class inClass;
  input SCode.Attributes inAttributes;
  input list<DimExp> inDimExpLst;
  input list<Integer> inIntegerLst;
  input InstDims inInstDims;
  input Boolean inBoolean;
  input Option<Absyn.Comment> inAbsynCommentOption;
  output Env outEnv;
  output list<DAE.Element> outDAEElementLst;
  output Connect.Sets outSets;
  output Types.Type outType;
algorithm 
  (outEnv,outDAEElementLst,outSets,outType):=
  matchcontinue (inEnv,inState,inMod,inPrefix,inSets,inIdent,inClass,inAttributes,inDimExpLst,inIntegerLst,inInstDims,inBoolean,inAbsynCommentOption)
    local
      list<DimExp> dims_1,dims;
      list<Env.Frame> compenv,env;
      list<DAE.Element> dae;
      Connect.Sets csets_1,csets;
      tuple<Types.TType, Option<Absyn.Path>> ty_1,ty;
      ClassInf.State ci_state;
      Types.Mod mod;
      Prefix.Prefix pre;
      String n,id;
      SCode.Class cl;
      SCode.Attributes attr;
      list<Integer> idxs;
      InstDims inst_dims;
      Boolean impl;
      Option<Absyn.Comment> comment;
    case (env,ci_state,mod,pre,csets,n,(cl as SCode.CLASS(name = id)),attr,dims,idxs,inst_dims,impl,comment) /* impl component environment dae elements for component Variables of userdefined type, e.g. Point p => Real p{3}; These must be handled separately since even if they do not 
	    appear to be an array, they can. Therefore we need to collect
	    the full dimensionality and call inst_var2 
	 */ 
      equation 
        ((dims_1 as (_ :: _))) = getUsertypeDimensions(env, mod, pre, cl, inst_dims, impl) "Collect dimensions" ;
        (compenv,dae,csets_1,ty_1) = instVar2(env, ci_state, mod, pre, csets, n, cl, attr, dims_1, idxs, 
          inst_dims, impl, comment);
        ty = makeArrayType(dims_1, ty_1);
      then
        (compenv,dae,csets_1,ty);
    case (env,ci_state,mod,pre,csets,n,(cl as SCode.CLASS(name = id)),attr,dims,idxs,inst_dims,impl,comment) /* Generic case: fall trough */ 
      equation 
        (compenv,dae,csets_1,ty_1) = instVar2(env, ci_state, mod, pre, csets, n, cl, attr, dims, idxs, 
          inst_dims, impl, comment);
      then
        (compenv,dae,csets_1,ty_1);
  end matchcontinue;
end instVar;

protected function instVar2 "function: instVar2
 
  Helper function to inst_var, does the main work.
"
  input Env inEnv;
  input ClassInf.State inState;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input Ident inIdent;
  input SCode.Class inClass;
  input SCode.Attributes inAttributes;
  input list<DimExp> inDimExpLst;
  input list<Integer> inIntegerLst;
  input InstDims inInstDims;
  input Boolean inBoolean;
  input Option<Absyn.Comment> inAbsynCommentOption;
  output Env outEnv;
  output list<DAE.Element> outDAEElementLst;
  output Connect.Sets outSets;
  output Types.Type outType;
algorithm 
  (outEnv,outDAEElementLst,outSets,outType):=
  matchcontinue (inEnv,inState,inMod,inPrefix,inSets,inIdent,inClass,inAttributes,inDimExpLst,inIntegerLst,inInstDims,inBoolean,inAbsynCommentOption)
    local
      InstDims dims_1,inst_dims,subs,inst_dims_1;
      Exp.Exp e,e_1;
      Types.Properties p;
      list<Env.Frame> env_1,env,compenv;
      Connect.Sets csets_1,csets;
      tuple<Types.TType, Option<Absyn.Path>> ty,ty_1,arrty;
      ClassInf.State st,ci_state;
      Exp.ComponentRef cr;
      Exp.Type ty_2;
      DAE.Element daeeq;
      list<DAE.Element> dae1,dae,dae1_1,dae3,dae2,daex;
      Types.Mod mod;
      Prefix.Prefix pre,pre_1;
      String n,prefix_str;
      SCode.Class cl;
      SCode.Attributes attr;
      list<DimExp> dims;
      list<Integer> idxs,idxs_1;
      Boolean impl,flow_;
      Option<Absyn.Comment> comment;
      Option<DAE.VariableAttributes> dae_var_attr;
      SCode.Accessibility acc;
      SCode.Variability vt;
      Absyn.Direction dir;
      list<String> index_string;
      Option<Exp.Exp> start;
      Exp.Subscript dime;
      list<Exp.ComponentRef> crs;
      Option<Integer> dimt;
      DimExp dim;
       /* Function. For Functions we can 
			    not always find dimensional sizes. e.g. 
			    input Real x{:}; component environement The class is instantiated with the calculated 
          modification, and an extended prefix. 
         
	  LS: Removed the part which checks if modelica_output is true
	  and generates variables with initialization expression from the
	  modifications, because it cannot handle right hand side which is a
	  component (T_COMPLEX) anyway. This case is handled by the rule below
	  which generates correct equations according to the modification.
	  Separate code can parse the DAE and put the rhs of the latest
	  equation inside the variable declaration, and discard all the
	  equations.
	 Rules for normal instantiation, will resolv dimensional sizes, etc. Array vars with binding in functions,e.g. input Real x{:}=Y */ 
      
    case (env,(ci_state as ClassInf.FUNCTION(string = _)),mod,pre,csets,n,cl,attr,(dims as (_ :: _)),idxs,inst_dims,impl,comment) 
           equation 
        dims_1 = instDimExpLst(dims, impl) "Do not flatten because it is a function" ;
        SOME(Types.TYPED(e,_,p)) = Mod.modEquation(mod) "get the equation modification" ;
        (_,env_1,csets_1,ty,st) = instClass(env, mod, pre, csets, cl, inst_dims, impl, INNER_CALL()) "Instantiate type of the component" ;
        ty_1 = makeArrayType(dims, ty) "Make it an array type since we are not flattening" ;
        cr = Prefix.prefixCref(pre, Exp.CREF_IDENT(n,{}));
        ty_2 = Types.elabType(ty_1);
        (e_1,_) = Types.matchProp(e, Types.PROP(ty_1,Types.C_VAR()), p);
        daeeq = makeDaeEquation(Exp.CREF(cr,ty_2), e_1, NON_INITIAL()) "Put the mod equation in the dae so that code will be generated" ;
        dae1 = daeDeclare(cr, ci_state, ty, attr, NONE, dims_1, NONE, NONE, comment);
        dae = listAppend(dae1, {daeeq});
      then
        (env_1,dae,csets_1,ty_1);
   
      /* Array vars without binding in functions , e.g. input Real x{:} */ 
    case (env,(ci_state as ClassInf.FUNCTION(string = _)),mod,pre,csets,n,cl,attr,(dims as (_ :: _)),idxs,inst_dims,impl,comment) 
       equation 
        (_,env_1,csets,ty,st) = instClass(env, mod, pre, csets, cl, inst_dims, impl, INNER_CALL()) "Do not flatten because it is a function" ;
        cr = Prefix.prefixCref(pre, Exp.CREF_IDENT(n,{}));
        dims_1 = instDimExpLst(dims, impl) "Do all dimensions..." ;
        dae = daeDeclare(cr, ci_state, ty, attr, NONE, dims_1, NONE, NONE, comment);
        arrty = makeArrayType(dims, ty);
      then
        (env_1,dae,csets,arrty);

         /* Constants */ 
    case (env,ci_state,(mod as Types.MOD(eqModOption = SOME(Types.TYPED(e,_,_)))),pre,csets,n,cl,SCode.ATTR(flow_ = flow_,RW = acc,parameter_ = (vt as SCode.CONST()),input_ = dir),{},idxs,inst_dims,impl,comment) 
      equation 
        idxs_1 = listReverse(idxs);
        pre_1 = Prefix.prefixAdd(n, idxs_1, pre);
        (dae1,env_1,csets_1,ty,st) = instClass(env, mod, pre_1, csets, cl, inst_dims, impl, INNER_CALL());
        dae1_1 = fixDirection(dae1, dir);
        subs = Exp.intSubscripts(idxs_1);
        cr = Prefix.prefixCref(pre, Exp.CREF_IDENT(n,subs));
        dae_var_attr = instDaeVariableAttributes(env, mod, ty, {}) "inst_mod_equation(cr,ty,mod) => dae2 &" ;
        dae3 = daeDeclare(cr, ci_state, ty, SCode.ATTR({},flow_,acc,vt,dir), 
          SOME(e), inst_dims, NONE, dae_var_attr, comment);
        dae = listAppend(dae1_1, dae3);
      then
        (env_1,dae,csets_1,ty);

        /* Parameters */ 
    case (env,ci_state,(mod as Types.MOD(eqModOption = SOME(Types.TYPED(e,_,_)))),pre,csets,n,cl,SCode.ATTR(flow_ = flow_,RW = acc,parameter_ = (vt as SCode.PARAM()),input_ = dir),{},idxs,inst_dims,impl,comment) 
      equation 
        idxs_1 = listReverse(idxs);
        pre_1 = Prefix.prefixAdd(n, idxs_1, pre);
        (dae1,env_1,csets_1,ty,st) = instClass(env, mod, pre_1, csets, cl, inst_dims, impl, INNER_CALL());
        dae1_1 = fixDirection(dae1, dir);
        subs = Exp.intSubscripts(idxs_1);
        cr = Prefix.prefixCref(pre, Exp.CREF_IDENT(n,subs));
        dae_var_attr = instDaeVariableAttributes(env, mod, ty, {});
        dae3 = daeDeclare(cr, ci_state, ty, SCode.ATTR({},flow_,acc,vt,dir), 
          SOME(e), inst_dims, NONE, dae_var_attr, comment);
        dae = listAppend(dae1_1, dae3);
      then
        (env_1,dae,csets_1,ty);

        /* Structural Parameters */ 
    case (env,ci_state,(mod as Types.MOD(eqModOption = SOME(Types.TYPED(e,_,_)))),pre,csets,n,cl,SCode.ATTR(flow_ = flow_,RW = acc,parameter_ = (vt as SCode.STRUCTPARAM()),input_ = dir),{},idxs,inst_dims,impl,comment) 
      equation 
        idxs_1 = listReverse(idxs);
        pre_1 = Prefix.prefixAdd(n, idxs_1, pre);
        (dae1,env_1,csets_1,ty,st) = instClass(env, mod, pre_1, csets, cl, inst_dims, impl, INNER_CALL());
        dae1_1 = fixDirection(dae1, dir);
        subs = Exp.intSubscripts(idxs_1);
        cr = Prefix.prefixCref(pre, Exp.CREF_IDENT(n,subs));
        dae_var_attr = instDaeVariableAttributes(env, mod, ty, {});
        dae3 = daeDeclare(cr, ci_state, ty, SCode.ATTR({},flow_,acc,vt,dir), 
          SOME(e), inst_dims, NONE, dae_var_attr, comment);
        dae = listAppend(dae1_1, dae3);
      then
        (env_1,dae,csets_1,ty);        
           
        /* Scalar Variables, different from the ones above since variable binings are expanded to equations.
        Exception: external objects, see below.*/         
    case (env,ci_state,mod,pre,csets,n,cl,SCode.ATTR(flow_ = flow_,RW = acc,parameter_ = vt,input_ = dir),{},idxs,inst_dims,impl,comment) 
      local Option<Exp.Exp> eOpt "for external objects";
      equation 
        idxs_1 = listReverse(idxs);
        pre_1 = Prefix.prefixAdd(n, idxs_1, pre);
        prefix_str = Prefix.printPrefixStr(pre_1);
        //Debug.fprintl("insttr", {"instantiating var class: ",n," prefix ",prefix_str,"\n"});
        (dae1,env_1,csets_1,ty,st) = instClass(env, mod, pre_1, csets, cl, inst_dims, impl, INNER_CALL());
        dae1_1 = fixDirection(dae1, dir);
        subs = Exp.intSubscripts(idxs_1);
        cr = Prefix.prefixCref(pre, Exp.CREF_IDENT(n,subs));
        dae2 = instModEquation(cr, ty, mod, impl);
        index_string = Util.listMap(idxs_1, int_string);
        //Debug.fprint("insttrind", "\n ******************\n ");
        //Debug.fprint("insttrind", "\n index_string ");
        //Debug.fprintl("insttr", index_string);
        //Debug.fprint("insttrind", "\n component ref ");
        Debug.fcall("insttr", Exp.printComponentRef, cr);
        //Debug.fprint("insttrind", "\n ******************\n ");
        //Debug.fprint("insttrind", "\n ");
        start = instStartBindingExp(mod, ty, idxs_1);
        eOpt = makeExternalObjectBinding(ty,mod);
        dae_var_attr = instDaeVariableAttributes(env, mod, ty, {}) "idxs\'" ;
        dae3 = daeDeclare(cr, ci_state, ty, SCode.ATTR({},flow_,acc,vt,dir), eOpt, 
          inst_dims, start, dae_var_attr, comment);
        daex = listAppend(dae1_1, dae2);
        dae = listAppend(daex, dae3);
      then
        (env_1,dae,csets_1,ty);
    case (env,ci_state,mod,pre,csets,n,cl,attr,(dim :: dims),idxs,inst_dims,impl,comment) /* FIXME: make a similar rule: if implicit=true and we fail to flatten, we should leave it unflattened */ 
      equation 
        dime = instDimExp(dim, impl) "Array variables , e.g. Real x{3} flatten" ;
        inst_dims_1 = listAppend(inst_dims, {dime});
        (compenv,dae,Connect.SETS(_,crs),ty) = instArray(env, ci_state, mod, pre, csets, n, (cl,attr), 1, dim, 
          dims, idxs, inst_dims_1, impl, comment);
        dimt = instDimType(dim);
        ty_1 = Types.liftArray(ty, dimt);
      then
        (compenv,dae,Connect.SETS({},crs),ty_1);
    case (_,_,_,_,_,n,_,_,_,_,_,_,_) /* Rules for instantation of function variables (e.g. input and output 
        parameters and protected variables) */ 
      equation 
        //Debug.fprint("failtrace", "- inst_var2 failed: ");
        //Debug.fprint("failtrace", n);
        //Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end instVar2;

protected function makeExternalObjectBinding "Helper relation to instVar2

For external objects the binding contains the constructor call.  This must be inserted in the DAE.VAR 
as the binding expression so the 
constructor code can be generated.
If the type is not externa object, NONE is returned, since an equation should be generated instead with
instModEquation.
"
input Types.Type tp;
input Types.Mod mod;
output Option<Exp.Exp> eOpt;

algorithm
  eOpt := matchcontinue(tp,mod)
  case ((Types.T_COMPLEX(complexClassType=ClassInf.EXTERNAL_OBJ(_)),_),
    Types.MOD(eqModOption = SOME(Types.TYPED(e,_,_))))
    local Exp.Exp e;
    then SOME(e);
  case (_,_) then NONE;
end matchcontinue;
end makeExternalObjectBinding;

protected function makeArrayType "function: makeArrayType
 
  Creates an array type from the element type given as argument and a 
  list of dimensional sizes.
"
  input list<DimExp> inDimExpLst;
  input Types.Type inType;
  output Types.Type outType;
algorithm 
  outType:=
  matchcontinue (inDimExpLst,inType)
    local
      tuple<Types.TType, Option<Absyn.Path>> ty,ty_1;
      Integer i;
      list<DimExp> xs;
      Option<Absyn.Path> p;
    case ({},ty) then ty; 
    case ((DIMINT(integer = i) :: xs),(ty,p))
      local Types.TType ty;
      equation 
        ty_1 = makeArrayType(xs, (ty,p));
      then
        ((Types.T_ARRAY(Types.DIM(SOME(i)),ty_1),p));
    case ((DIMEXP(subscript = _) :: xs),(ty,p))
      local Types.TType ty;
      equation 
        ty_1 = makeArrayType(xs, (ty,p));
      then
        ((Types.T_ARRAY(Types.DIM(NONE),ty_1),p));
    case (_,_)
      equation 
        //Debug.fprint("failtrace", "- make_array_type failed\n");
      then
        fail();
  end matchcontinue;
end makeArrayType;

protected function getUsertypeDimensions "function: getUsertypeDimensions
 
  Retrieves the dimensions of a usertype.
  The builtin types have no dimension, whereas a user defined type might
  have dimensions. For instance, type Point = Real{3}; 
  has one dimension of size 3.
"
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input SCode.Class inClass;
  input InstDims inInstDims;
  input Boolean inBoolean;
  output list<DimExp> outDimExpLst;
algorithm 
  outDimExpLst:=
  matchcontinue (inEnv,inMod,inPrefix,inClass,inInstDims,inBoolean)
    local
      SCode.Class cl;
      list<Env.Frame> cenv,env;
      Absyn.ComponentRef owncref;
      list<Absyn.Subscript> ad_1;
      Types.Mod mod_1,mods_2,mods_3,mods;
      Option<Types.EqMod> eq;
      list<DimExp> dim1,dim2,res;
      Prefix.Prefix pre;
      String id;
      Absyn.Path cn;
      Option<list<Absyn.Subscript>> ad;
      SCode.Mod mod;
      InstDims dims;
      Boolean impl;
    case (_,_,_,SCode.CLASS(name = "Real"),_,_) then {};  /* impl */ 
    case (_,_,_,SCode.CLASS(name = "Integer"),_,_) then {}; 
    case (_,_,_,SCode.CLASS(name = "String"),_,_) then {}; 
    case (_,_,_,SCode.CLASS(name = "Boolean"),_,_) then {}; 
    case (env,mods,pre,SCode.CLASS(name = id,restricion = SCode.R_TYPE(),parts = SCode.DERIVED(short = cn,absynArrayDimOption = ad,mod = mod)),dims,impl) /* Derived classes with restriction type, e.g. type Point = Real{3}; */ 
      equation 
        (cl,cenv) = Lookup.lookupClass(env, cn, true);
        owncref = Absyn.CREF_IDENT(id,{});
        ad_1 = getOptionArraydim(ad);
        mod_1 = Mod.elabMod(env, pre, mod, impl);
        mods_2 = Mod.merge(mods, mod_1, env, pre);
        eq = Mod.modEquation(mods_2);
        mods_3 = Mod.lookupCompModification(mods_2, id);
        dim1 = getUsertypeDimensions(cenv, mods_3, pre, cl, dims, impl);
        dim2 = elabArraydim(env, owncref, ad_1, eq, impl, NONE);
        res = listAppend(dim2, dim1);
      then
        res;
  end matchcontinue;
end getUsertypeDimensions;

protected function getCrefFromMod "function: getCrefFromMod
  author: PA
 
  Return all variables in a modifier, SCode.Mod.
  This is needed to prepare the second pass of instantiation, because a 
  component can not be instantiated unless the types of the modifiers are
  known. Therefore the variables in all  modifiers must be instantiated 
  before the component itself is instantiated. This is done by backpatching 
  in the instantiation process. NOTE: This means that a recursive 
  modification structure (which is not allowed in Modelica) will currently 
  run the compiler into infinite recursion.
"
  input SCode.Mod inMod;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm 
  outAbsynComponentRefLst:=
  matchcontinue (inMod)
    local
      list<Absyn.ComponentRef> res1,res2,res,l1,l2;
      Boolean b;
      String n;
      SCode.Mod m,mod;
      list<SCode.Element> xs;
      list<SCode.SubMod> submods;
      Absyn.Exp e;
    case (SCode.REDECL(final_ = b,elementLst = (SCode.COMPONENT(component = n,mod = m) :: xs))) /* For redeclarations e.g \"redeclare B2 b(cref=<expr>)\", find cref */ 
      equation 
        res1 = getCrefFromMod(SCode.REDECL(b,xs));
        res2 = getCrefFromMod(m);
        res = listAppend(res1, res2);
      then
        res;
    case (SCode.REDECL(final_ = b,elementLst = (_ :: xs))) /* For redeclarations e.g \"redeclare B2 b(cref=<expr>)\", find cref */ 
      equation 
        res = getCrefFromMod(SCode.REDECL(b,xs));
      then
        res;
    case (SCode.REDECL(final_ = b,elementLst = {})) then {}; 
    case ((mod as SCode.MOD(subModLst = submods,absynExpOption = SOME(e)))) /* Find in sub modifications e.g A(B=3) find B */ 
      equation 
        l1 = getCrefFromSubmods(submods);
        l2 = Absyn.getCrefFromExp(e);
        res = listAppend(l2, l1);
      then
        res;
    case (SCode.MOD(subModLst = submods,absynExpOption = NONE))
      equation 
        res = getCrefFromSubmods(submods);
      then
        res;
    case (_) then {}; 
    case (_)
      equation 
        //Debug.fprint("failtrace", "- get_cref_from_mod failed\n");
      then
        fail();
  end matchcontinue;
end getCrefFromMod;

protected function getCrefFromDim "function: getCrefFromDim
  author: PA
 
  Similar to get_cref_from_mod, but investigates array dimensionalitites 
  instead.
"
  input Absyn.ArrayDim inArrayDim;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm 
  outAbsynComponentRefLst:=
  matchcontinue (inArrayDim)
    local
      list<Absyn.ComponentRef> l1,l2,res;
      Absyn.Exp exp;
      list<Absyn.Subscript> rest;
    case ((Absyn.SUBSCRIPT(subScript = exp) :: rest))
      equation 
        l1 = getCrefFromDim(rest);
        l2 = Absyn.getCrefFromExp(exp);
        res = listAppend(l1, l2);
      then
        res;
    case ((Absyn.NOSUB() :: rest))
      equation 
        res = getCrefFromDim(rest);
      then
        res;
    case ({}) then {}; 
    case (_)
      equation 
        //Debug.fprint("failtrace", "- get_cref_from_dim failed\n");
      then
        fail();
  end matchcontinue;
end getCrefFromDim;

protected function getCrefFromSubmods "function: getCrefFromSubmods
 
  Helper function to get_cref_from_mod, investigates sub modifiers.
"
  input list<SCode.SubMod> inSCodeSubModLst;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm 
  outAbsynComponentRefLst:=
  matchcontinue (inSCodeSubModLst)
    local
      list<Absyn.ComponentRef> res1,res2,res;
      SCode.Mod mod;
      list<SCode.SubMod> rest;
    case ((SCode.NAMEMOD(A = mod) :: rest))
      equation 
        res1 = getCrefFromMod(mod);
        res2 = getCrefFromSubmods(rest);
        res = listAppend(res1, res2);
      then
        res;
    case ({}) then {}; 
  end matchcontinue;
end getCrefFromSubmods;

protected function updateComponentsInEnv "function: updateComponentsInEnv
  author: PA
 
  This function is the second pass of component instantiation, when a 
  component can be instantiated fully and the type of the component can be 
  determined. The type is added/updated to the environment such that other 
  components can use it when they are instantiated.
"
  input Mod inMod;
  input list<Absyn.ComponentRef> inAbsynComponentRefLst;
  input Env inEnv;
  input ClassInf.State inState;
  input Connect.Sets inSets;
  input Boolean inBoolean;
  output Env outEnv;
  output Connect.Sets outSets;
algorithm 
  (outEnv,outSets):=
  matchcontinue (inMod,inAbsynComponentRefLst,inEnv,inState,inSets,inBoolean)
    local
      list<Env.Frame> env_1,env_2,env;
      Connect.Sets csets;
      Types.Mod mods;
      Absyn.ComponentRef cr;
      list<Absyn.ComponentRef> rest;
      ClassInf.State ci_state;
      Boolean impl;
    case (mods,(cr :: rest),env,ci_state,csets,impl) /* Implicit instantiation */ 
      equation 
        (env_1,csets) = updateComponentInEnv(mods, cr, env, ci_state, csets, impl);
        (env_2,csets) = updateComponentsInEnv(mods, rest, env_1, ci_state, csets, impl);
      then
        (env_2,csets);
    case (_,{},env,ci_state,csets,impl) /* 	//Debug.fprint(\"decl\", \"update_components_in_env finished\\n\") */  then (env,csets); 
  end matchcontinue;
end updateComponentsInEnv;

protected function updateComponentInEnv "function: updateComponentInEnv
  author: PA
 
  Helper function to update_components_in_env.
  Does the work for one variable.
"
  input Mod inMod;
  input Absyn.ComponentRef inComponentRef;
  input Env inEnv;
  input ClassInf.State inState;
  input Connect.Sets inSets;
  input Boolean inBoolean;
  output Env outEnv;
  output Connect.Sets outSets;
algorithm 
  (outEnv,outSets):=
  matchcontinue (inMod,inComponentRef,inEnv,inState,inSets,inBoolean)
    local
      tuple<Types.TType, Option<Absyn.Path>> ty;
      String n,id,str,str2,str3;
      Boolean final_,repl,prot,flow_,impl;
      SCode.Attributes attr;
      list<Absyn.Subscript> ad,subscr;
      SCode.Accessibility acc;
      SCode.Variability param;
      Absyn.Direction dir;
      Absyn.Path t;
      SCode.Mod m;
      Option<Absyn.Path> bc;
      Option<Absyn.Comment> comment;
      Types.Mod cmod,m_1,classmod,mm,mod,mod_1,mod_2,mod_3,mods;
      SCode.Class cl;
      list<Env.Frame> cenv,env2,compenv,env2_1,env_1,env;
      list<Absyn.ComponentRef> crefs,crefs2,crefs_1,crefs_2;
      Connect.Sets csets,csets_1;
      Option<Types.EqMod> eq;
      list<DimExp> dims;
      list<DAE.Element> dae1;
      Types.Binding binding,binding_1;
      Absyn.ComponentRef cref,owncref;
      ClassInf.State ci_state;
    case (mods,(cref as Absyn.CREF_IDENT(name = id,subscripts = subscr)),env,ci_state,csets,impl) /* Variables that have Element in Environment, i.e. no type 
	    information are instnatiated here to get the type. */ 
      equation 
        (ty,SOME((SCode.COMPONENT(n,final_,repl,prot,(attr as SCode.ATTR(ad,flow_,acc,param,dir)),t,m,bc,comment),cmod)),_) = Lookup.lookupIdent(env, id);
        (cl,cenv) = Lookup.lookupClass(env, t, false);
        crefs = getCrefFromMod(m);
        crefs2 = getCrefFromDim(ad);
        crefs_1 = listAppend(crefs, crefs2);
        crefs_2 = removeCrefFromCrefs(crefs_1, cref);
        (env2,csets) = updateComponentsInEnv(mods, crefs_2, env, ci_state, csets, impl);
        m_1 = Mod.elabMod(env2, Prefix.NOPRE(), m, impl) "Prefix does not matter, since we only update types in env, and does
	   not make any dae elements, etc.." ;
        classmod = Mod.lookupModificationP(mods, t);
        mm = Mod.lookupCompModification(mods, n);
        mod = Mod.merge(classmod, mm, env2, Prefix.NOPRE());
        mod_1 = Mod.merge(mod, m_1, env2, Prefix.NOPRE());
        mod_2 = Mod.merge(cmod, mod_1, env2, Prefix.NOPRE());
        mod_3 = Mod.updateMod(env2, Prefix.NOPRE(), mod_2, impl);
        eq = Mod.modEquation(mod_3);
        dims = elabArraydim(env2, cref, ad, eq, impl, NONE) "The variable declaration and the (optional) equation modification are inspected for array dimensions." ;
        (compenv,dae1,csets_1,ty) = instVar(cenv, ci_state, mod_3, Prefix.NOPRE(), csets, n, cl, attr, 
          dims, {}, {}, impl, NONE) "Instantiate the component" ;
        binding = makeBinding(env2, attr, mod_3, ty) "The environment is extended with the new variable binding." ;
        (env2_1,binding_1) = checkStructuralParamBinding(param, binding, env2) "Check if binding makes other variables into structural parameters
	  For example input Integer n=p;
	  If p is known to be a structural parameter, n should also become
	  one. 
	" ;
        env_1 = Env.updateFrameV(env2_1, 
          Types.VAR(n,Types.ATTR(flow_,acc,param,dir),prot,ty,binding_1), false, compenv) "type info present" ;
      then
        (env_1,csets_1);
    case (mods,(cref as Absyn.CREF_IDENT(name = id,subscripts = subscr)),env,ci_state,csets,impl) /* Variable with NONE element is allready instantiated. */ 
      local Types.Var ty;
      equation 
        (ty,NONE,_) = Lookup.lookupIdent(env, id);
      then
        (env,csets);
    case (mods,Absyn.CREF_QUAL(name = id),env,ci_state,csets,impl) /* If first part of ident is a class, e.g StateSelect.None, nothing 
	  to update */ 
      equation 
        (cl,cenv) = Lookup.lookupClass(env, Absyn.IDENT(id), false);
      then
        (env,csets);
    case (mods,Absyn.CREF_QUAL(name = id),env,ci_state,csets,impl) /* Nothing to update. */ 
      local Types.Var ty;
      equation 
        (ty,NONE,_) = Lookup.lookupIdent(env, id);
      then
        (env,csets);
    case (mods,Absyn.CREF_QUAL(name = id),env,ci_state,csets,impl) /* For qualified names, e.g. a.b.c, instanitate component a */ 
      equation 
        (ty,SOME((SCode.COMPONENT(n,final_,repl,prot,(attr as SCode.ATTR(ad,flow_,acc,param,dir)),t,m,_,comment),cmod)),_) = Lookup.lookupIdent(env, id);
        (cl,cenv) = Lookup.lookupClass(env, t, false);
        crefs = getCrefFromMod(m);
        (env2_1,csets) = updateComponentsInEnv(mods, crefs, env, ci_state, csets, impl);
        crefs2 = getCrefFromDim(ad);
        (env2,csets) = updateComponentsInEnv(mods, crefs2, env2_1, ci_state, csets, impl);
        m_1 = Mod.elabMod(env2, Prefix.NOPRE(), m, impl) "Prefix does not matter, since we only update types in env, and does
	   not make any dae elements, etc.." ;
        classmod = Mod.lookupModificationP(mods, t) "lookup and merge modifications" ;
        mm = Mod.lookupCompModification(mods, n);
        mod = Mod.merge(classmod, mm, env2, Prefix.NOPRE());
        mod_1 = Mod.merge(mod, m_1, env2, Prefix.NOPRE());
        mod_2 = Mod.merge(cmod, mod_1, env2, Prefix.NOPRE());
        mod_3 = Mod.updateMod(env2, Prefix.NOPRE(), mod_2, impl);
        eq = Mod.modEquation(mod_3);
        owncref = Absyn.CREF_IDENT(n,{}) "The variable declaration and the (optional) equation modification are inspected for array dimensions." ;
        dims = elabArraydim(env2, owncref, ad, eq, impl, NONE);
        (compenv,dae1,csets_1,ty) = instVar(cenv, ci_state, mod_3, Prefix.NOPRE(), csets, n, cl, attr, 
          dims, {}, {}, false, NONE) "Instantiate the component" ;
        binding = makeBinding(env2, attr, mod_3, ty) "The environment is extended with the new variable binding." ;
        env_1 = Env.updateFrameV(env2, 
          Types.VAR(n,Types.ATTR(flow_,acc,param,dir),prot,ty,binding), false, compenv) "type info present" ;
      then
        (env_1,csets_1);
    case (mod,cref,env,ci_state,csets,impl)
      equation 
        //Debug.fprint("failtrace", "-update_component_in_env failed, ident = ");
        str = Debug.fcallret("failtrace", Dump.printComponentRefStr, cref, "");
        //Debug.fprint("failtrace", str);
        //Debug.fprint("failtrace", "\n mods:");
        str2 = Debug.fcallret("failtrace", Mod.printModStr, mod, "");
        //Debug.fprint("failtrace", str2);
        //Debug.fprint("failtrace", "\n   env:   ");
        str3 = Debug.fcallret("failtrace", Env.printEnvStr, env, "");
        //Debug.fprint("failtrace", str3);
        //Debug.fprint("failtrace", "\n");
      then
        (env,csets);
  end matchcontinue;
end updateComponentInEnv;

protected function checkStructuralParamBinding "function: checkStructuralParamBinding
  author: PA
  
  Checks if the binding of a structural parameter makes other parameters 
  structural. For instance,
  parameter Integer m=n
  if m is structural, so will n be.
"
  input SCode.Variability inVariability;
  input Types.Binding inBinding;
  input Env inEnv;
  output Env outEnv;
  output Types.Binding outBinding;
algorithm 
  (outEnv,outBinding):=
  matchcontinue (inVariability,inBinding,inEnv)
    local
      list<Exp.ComponentRef> crefs;
      String str;
      list<Env.Frame> env_1,env;
      Exp.Exp exp;
      Option<Values.Value> e_val;
      Types.Const const;
      Types.Binding bind;
    case (SCode.STRUCTPARAM(),Types.EQBOUND(exp = exp,evaluatedExp = e_val,constant_ = const),env) /* collect varnames from binding and make them structural. Also 
	    make sure that binding has constant = true.
	 */ 
      equation 
        crefs = Exp.getCrefFromExp(exp);
        str = Exp.printExpStr(exp);
        env_1 = Util.listFold(crefs, makeStructuralInEnv, env);
      then
        (env_1,Types.EQBOUND(exp,e_val,Types.C_CONST()));
    case (_,bind,env) then (env,bind); 
  end matchcontinue;
end checkStructuralParamBinding;

protected function makeStructuralInEnv "function: makeStructuralInEnv
  author: PA
 
  This function is used to update a parameter in the environment to a 
  structural parameter.
"
  input Exp.ComponentRef inComponentRef;
  input Env inEnv;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inComponentRef,inEnv)
    local
      list<Env.Frame> env,env_1;
      String n,a,id,s;
      Boolean flow_,prot,b,c,d,f,typed;
      SCode.Accessibility acc,g;
      Absyn.Direction dir,h;
      tuple<Types.TType, Option<Absyn.Path>> tp;
      Types.Binding bind;
      list<Absyn.Subscript> e;
      Absyn.Path i;
      SCode.Mod j;
      Option<Absyn.Path> k;
      Option<Absyn.Comment> l;
      Types.Mod m;
      Exp.ComponentRef cr;
    case (_,env) then env; 
    case (Exp.CREF_IDENT(ident = id),env)
      equation 
        (Types.VAR(n,Types.ATTR(flow_,acc,SCode.PARAM(),dir),prot,tp,bind),SOME((SCode.COMPONENT(a,b,c,d,SCode.ATTR(e,f,g,SCode.PARAM(),h),i,j,k,l),m)),typed) = Lookup.lookupIdent(env, id);
        env_1 = Env.extendFrameV(env, 
          Types.VAR(n,Types.ATTR(flow_,acc,SCode.STRUCTPARAM(),dir),prot,tp,
          bind), 
          SOME(
          (
          SCode.COMPONENT(a,b,c,d,SCode.ATTR(e,f,g,SCode.STRUCTPARAM(),h),i,j,k,l),m)), false, {}) "replace variable, relies on hash_add to replace node. comp env" ;
      then
        env_1;
    case (cr,env)
      equation 
        print("make_structural_in_env failed for component ");
        s = Exp.printComponentRefStr(cr);
        print(s);
        print("\n");
      then
        env;
  end matchcontinue;
end makeStructuralInEnv;

protected function instDimExpLst "function: instDimExpLst
 
  Instantiates dimension expressions, DimExp, which are transformed to 
  Exp.Subscript\'s
"
  input list<DimExp> inDimExpLst;
  input Boolean inBoolean;
  output list<Exp.Subscript> outExpSubscriptLst;
algorithm 
  outExpSubscriptLst:=
  matchcontinue (inDimExpLst,inBoolean)
    local
      list<Exp.Subscript> res;
      Exp.Subscript r;
      DimExp x;
      list<DimExp> xs;
      Boolean b;
    case ({},_) then {};  /* impl */ 
    case ((x :: xs),b)
      equation 
        res = instDimExpLst(xs, b);
        r = instDimExp(x, b);
      then
        (r :: res);
  end matchcontinue;
end instDimExpLst;

protected function instDimExp "function: instDimExp_lst
 
  instantiates one dimension expression, See also isnt_dim_exp_lst.
"
  input DimExp inDimExp;
  input Boolean inBoolean;
  output Exp.Subscript outSubscript;
algorithm 
  outSubscript:=
  matchcontinue (inDimExp,inBoolean)
    local
      Boolean impl;
      String s;
      Exp.Exp e;
      Integer i;
    case (DIMEXP(subscript = Exp.WHOLEDIM()),(impl as false)) /* impl FIXME: Fix slicing, e.g. Exp.SLICE, for impl=true */ 
      equation 
        Error.addMessage(Error.DIMENSION_NOT_KNOWN, {";"});
      then
        fail();
    case (DIMEXP(subscript = Exp.SLICE(exp = e)),(impl as false))
      equation 
        s = Exp.printExpStr(e);
        Error.addMessage(Error.DIMENSION_NOT_KNOWN, {s});
      then
        fail();
    case (DIMEXP(subscript = (e as Exp.WHOLEDIM())),(impl as true))
      local Exp.Subscript e;
      then
        e;
    case (DIMINT(integer = i),_) then Exp.INDEX(Exp.ICONST(i)); 
    case (DIMEXP(subscript = (e as Exp.INDEX(exp = _))),_)
      local Exp.Subscript e;
      then
        e;
  end matchcontinue;
end instDimExp;

protected function instDimType "function instDimType
  Retrieves the dimension expression as an integer option. 
  Non constant dimensions give NONE.
"
  input DimExp inDimExp;
  output Option<Integer> outIntegerOption;
algorithm 
  outIntegerOption:=
  matchcontinue (inDimExp)
    local Integer i;
    case DIMINT(integer = i) then SOME(i); 
    case DIMEXP(subscript = _) then NONE; 
  end matchcontinue;
end instDimType;

protected function fixDirection "function: fixDirection
 
  Updates the direction of a DAE element list.
  If a component has prefix input, all variables of the component 
  should be input.
  Similarly if a component has prefix output.
  If the component is bidirectional, the original direction is kept
"
  input list<DAE.Element> inDAEElementLst;
  input Absyn.Direction inDirection;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  outDAEElementLst:=
  matchcontinue (inDAEElementLst,inDirection)
    local
      list<DAE.Element> lst,r_1,r,lst_1;
      DAE.VarDirection dir_1;
      Exp.ComponentRef cr;
      DAE.VarKind vk;
      DAE.Type t;
      Option<Exp.Exp> e,start;
      InstDims id;
      DAE.Flow flow_;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      Absyn.Direction dir;
      String s1,s2;
      DAE.Element x;
    case (lst,Absyn.BIDIR()) then lst;  /* Component that is bidirectional does not change direction 
	    on subcomponents */ 
    case ({},_) then {}; 
    case ((DAE.VAR(componentRef = cr,varible = vk,variable = DAE.BIDIR(),input_ = t,one = e,binding = id,dimension = start,value = flow_,flow_ = class_,variableAttributesOption = dae_var_attr,absynCommentOption = comment) :: r),dir) /* Bidirectional variables are changed to input or output if 
	  component has such prefix. */ 
      equation 
        dir_1 = absynDirToDaeDir(dir);
        r_1 = fixDirection(r, dir);
      then
        (DAE.VAR(cr,vk,dir_1,t,e,id,start,flow_,class_,dae_var_attr,comment) :: r_1);
    case ((DAE.VAR(componentRef = cr,varible = vk,variable = DAE.INPUT(),input_ = t,one = e,binding = id,dimension = start,value = flow_,flow_ = class_,variableAttributesOption = dae_var_attr,absynCommentOption = comment) :: r),dir) /* Error, component declared as input or output  when containing 
	    variable that has prefix input. */ 
      equation 
        s1 = Dump.directionSymbol(dir);
        s2 = Exp.printComponentRefStr(cr);
        Error.addMessage(Error.COMPONENT_INPUT_OUTPUT_MISMATCH, {s1,s2});
      then
        fail();
    case ((DAE.VAR(componentRef = cr,varible = vk,variable = DAE.OUTPUT(),input_ = t,one = e,binding = id,dimension = start,value = flow_,flow_ = class_,variableAttributesOption = dae_var_attr,absynCommentOption = comment) :: r),dir) /* Error, component declared as input or output  when containing 
	    variable that has prefix output. */ 
      equation 
        s1 = Dump.directionSymbol(dir);
        s2 = Exp.printComponentRefStr(cr);
        Error.addMessage(Error.COMPONENT_INPUT_OUTPUT_MISMATCH, {s1,s2});
      then
        fail();
    case ((DAE.COMP(ident = id,dAElist = DAE.DAE(elementLst = lst)) :: r),dir)
      local String id;
      equation 
        lst_1 = fixDirection(lst, dir);
        r_1 = fixDirection(r, dir);
      then
        (DAE.COMP(id,DAE.DAE(lst_1)) :: r_1);
    case ((x :: r),dir)
      equation 
        r_1 = fixDirection(r, dir);
      then
        (x :: r_1);
  end matchcontinue;
end fixDirection;

protected function absynDirToDaeDir "function: absynDirToDaeDir
 
  Helper function to fix_direction. 
  Translates Absyn.Direction to DAE.VarDirection. Needed so that 
  input, output is transferred to DAE.
"
  input Absyn.Direction inDirection;
  output DAE.VarDirection outVarDirection;
algorithm 
  outVarDirection:=
  matchcontinue (inDirection)
    case Absyn.INPUT() then DAE.INPUT(); 
    case Absyn.OUTPUT() then DAE.OUTPUT(); 
    case Absyn.BIDIR() then DAE.BIDIR(); 
  end matchcontinue;
end absynDirToDaeDir;

protected function instArray "function: instArray
 
  When an array is instantiated by `inst_var\', this function is used
  to go through all the array elements and instantiate each array
  element separately.
"
  input Env inEnv;
  input ClassInf.State inState;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input Ident inIdent;
  input tuple<SCode.Class, SCode.Attributes> inTplSCodeClassSCodeAttributes;
  input Integer inInteger;
  input DimExp inDimExp;
  input list<DimExp> inDimExpLst;
  input list<Integer> inIntegerLst;
  input InstDims inInstDims;
  input Boolean inBoolean;
  input Option<Absyn.Comment> inAbsynCommentOption;
  output Env outEnv;
  output list<DAE.Element> outDAEElementLst;
  output Connect.Sets outSets;
  output Types.Type outType;
algorithm 
  (outEnv,outDAEElementLst,outSets,outType):=
  matchcontinue (inEnv,inState,inMod,inPrefix,inSets,inIdent,inTplSCodeClassSCodeAttributes,inInteger,inDimExp,inDimExpLst,inIntegerLst,inInstDims,inBoolean,inAbsynCommentOption)
    local
      Exp.Exp e,e_1;
      Types.Properties p;
      list<Env.Frame> env_1,env,compenv;
      Connect.Sets csets,csets_1,csets_2;
      tuple<Types.TType, Option<Absyn.Path>> ty,arrty;
      ClassInf.State st,ci_state;
      Exp.ComponentRef cr;
      Exp.Type ty_1,arrty_1;
      DAE.Element dae,dae3;
      Types.Mod mod,mod_1;
      Prefix.Prefix pre;
      String n;
      SCode.Class cl;
      SCode.Attributes attr;
      Integer i,stop,i_1;
      list<DimExp> dims;
      list<Integer> idxs;
      InstDims inst_dims;
      Boolean impl,b;
      Option<Absyn.Comment> comment;
      list<DAE.Element> dae1,dae2;
      Initial eqn_place;
    case (env,(ci_state as ClassInf.FUNCTION(string = _)),mod,pre,csets,n,(cl,attr),i,DIMEXP(subscript = _),dims,idxs,inst_dims,impl,comment) /* component environment If is a function var. */ 
      equation 
        SOME(Types.TYPED(e,_,p)) = Mod.modEquation(mod);
        (_,env_1,csets,ty,st) = instClass(env, mod, pre, csets, cl, inst_dims, true, INNER_CALL()) "Which has an 
							  expression binding" ;
        cr = Prefix.prefixCref(pre, Exp.CREF_IDENT(n,{})) "Check their types..." ;
        ty_1 = Types.elabType(ty);
        (e_1,_) = Types.matchProp(e, Types.PROP(ty,Types.C_VAR()), p);
        dae = makeDaeEquation(Exp.CREF(cr,ty_1), e_1, NON_INITIAL());
      then
        (env_1,{dae},csets,ty);
    case (env,ci_state,mod,pre,csets,n,(cl,attr),i,DIMEXP(subscript = _),dims,idxs,inst_dims,impl,comment)
      local list<DAE.Element> dae;
      equation 
        (compenv,dae,csets,ty) = instVar2(env, ci_state, mod, pre, csets, n, cl, attr, dims, 
          (i :: idxs), inst_dims, impl, comment);
      then
        (compenv,dae,csets,ty);
    case (env,ci_state,mod,pre,csets,n,(cl,attr),i,DIMINT(integer = stop),dims,idxs,inst_dims,impl,comment)
      equation 
        (i > stop) = true;
      then
        ({},{},csets,(Types.T_NOTYPE(),NONE));
    case (env,ci_state,mod,pre,csets,n,(cl,attr),i,DIMINT(integer = stop),dims,idxs,inst_dims,impl,comment) /* Modifiers of arrays that are functioncall, eg. 
	    Real x{:}=foo(...) Should only generate -one- functioncall */ 
      local list<DAE.Element> dae;
      equation 
        SOME(Types.TYPED(e,_,p)) = Mod.modEquation(mod);
        true = Exp.containFunctioncall(e);
        (env_1,dae1,csets_1,ty) = instVar2(env, ci_state, Types.NOMOD(), pre, csets, n, cl, attr, 
          dims, (i :: idxs), inst_dims, impl, comment);
        i_1 = i + 1;
        (_,dae2,csets_2,arrty) = instArray(env, ci_state, Types.NOMOD(), pre, csets_1, n, (cl,attr), 
          i_1, DIMINT(stop), dims, idxs, inst_dims, impl, comment);
        cr = Prefix.prefixCref(pre, Exp.CREF_IDENT(n,{})) "Make the equation containing the functioncall" ;
        arrty_1 = Types.elabType(arrty);
        b = attrIsParam(attr) "if parameter, add equation to initial eqn" ;
        eqn_place = Util.if_(b, INITIAL(), NON_INITIAL());
        dae3 = makeDaeEquation(Exp.CREF(cr,arrty_1), e, eqn_place);
        dae = Util.listFlatten({dae1,dae2,{dae3}});
      then
        (env_1,dae,csets_2,ty);
    case (env,ci_state,mod,pre,csets,n,(cl,attr),i,DIMINT(integer = stop),dims,idxs,inst_dims,impl,comment)
      local list<DAE.Element> dae;
      equation 
        mod_1 = Mod.lookupIdxModification(mod, i);
        (env_1,dae1,csets_1,ty) = instVar2(env, ci_state, mod_1, pre, csets, n, cl, attr, dims, 
          (i :: idxs), inst_dims, impl, comment);
        i_1 = i + 1;
        (_,dae2,csets_2,_) = instArray(env, ci_state, mod, pre, csets_1, n, (cl,attr), i_1, 
          DIMINT(stop), dims, idxs, inst_dims, impl, comment);
        dae = listAppend(dae1, dae2);
      then
        (env_1,dae,csets_2,ty);
    case (_,_,_,_,_,n,(_,_),_,_,_,_,_,_,_)
      equation 
        //Debug.fprint("failtrace", "- inst_array failed: ");
        Debug.fcall("failtrace", Print.printBuf, n);
        //Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end instArray;

protected function attrIsParam "function: attrIsParam
 
  Returns true if attributes contain PARAM
"
  input SCode.Attributes inAttributes;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inAttributes)
    case SCode.ATTR(parameter_ = SCode.PARAM()) then true; 
    case _ then false; 
  end matchcontinue;
end attrIsParam;

public function elabComponentArraydimFromEnv "function elabComponentArraydimFromEnv
  author: PA
 
  Lookup uninstantiated component in env, elaborate its modifiers to
  find arraydimensions and return as DimExp list.
  Used when components have submodifiers (on e.g. attributes) using size 
  to find dimensions of component.
"
  input Env inEnv;
  input Exp.ComponentRef inComponentRef;
  output list<DimExp> outDimExpLst;
algorithm 
  outDimExpLst:=
  matchcontinue (inEnv,inComponentRef)
    local
      Types.Var ty;
      String n,id;
      Boolean final_,repl,prot,flow_;
      SCode.Attributes attr;
      list<Absyn.Subscript> ad;
      SCode.Accessibility acc;
      SCode.Variability param;
      Absyn.Direction dir;
      Absyn.Path t;
      SCode.Mod m,m_1;
      Option<Absyn.Path> bc;
      Option<Absyn.Comment> comment;
      Types.Mod cmod,cmod_1,m_2,mod_2;
      Types.EqMod eq;
      list<DimExp> dims;
      list<Env.Frame> env;
      Exp.ComponentRef cref;
    case (env,(cref as Exp.CREF_IDENT(ident = id)))
      equation 
        (ty,SOME((SCode.COMPONENT(n,final_,repl,prot,(attr as SCode.ATTR(ad,flow_,acc,param,dir)),t,m,bc,comment),cmod)),_) = Lookup.lookupIdent(env, id);
        cmod_1 = Types.stripSubmod(cmod);
        m_1 = SCode.stripSubmod(m);
        m_2 = Mod.elabMod(env, Prefix.NOPRE(), m_1, false);
        mod_2 = Mod.merge(cmod_1, m_2, env, Prefix.NOPRE());
        SOME(eq) = Mod.modEquation(mod_2);
        dims = elabComponentArraydimFromEnv2(eq, env);
      then
        dims;
  end matchcontinue;
end elabComponentArraydimFromEnv;

protected function elabComponentArraydimFromEnv2 "function: elabComponentArraydimFromEnv2 
  author: PA
 
  Helper function to elab_component_arraydim_from_env. This function is 
  similar to elab_arraydim, but it will only investigate binding 
  (Types.EqMod) and not the component declaration.
"
  input Types.EqMod inEqMod;
  input Env inEnv;
  output list<DimExp> outDimExpLst;
algorithm 
  outDimExpLst:=
  matchcontinue (inEqMod,inEnv)
    local
      list<Integer> lst;
      list<DimExp> lst_1;
      Exp.Exp e;
      tuple<Types.TType, Option<Absyn.Path>> t;
      list<Env.Frame> env;
    case (Types.TYPED(modifierAsExp = e,properties = Types.PROP(type_ = t)),env)
      equation 
        lst = Types.getDimensionSizes(t);
        lst_1 = Util.listMap(lst, makeDimexpFromInt);
      then
        lst_1;
  end matchcontinue;
end elabComponentArraydimFromEnv2;

protected function makeDimexpFromInt "function: makeDimexpFromInt
 
  Helper function to elab_component_arraydfum_from_env_2
"
  input Integer inInteger;
  output DimExp outDimExp;
algorithm 
  outDimExp:=
  matchcontinue (inInteger)
    local Integer i;
    case (i) then DIMINT(i); 
  end matchcontinue;
end makeDimexpFromInt;

protected function elabArraydimOpt "function: elabArraydimOpt
 
  Same functionality as elab_arraydim, but takes an optional arraydim.
  In case of NONE, empty DimExp list is returned.
"
  input Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Option<Absyn.ArrayDim> inAbsynArrayDimOption;
  input Option<Types.EqMod> inTypesEqModOption;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  output list<DimExp> outDimExpLst;
algorithm 
  outDimExpLst:=
  matchcontinue (inEnv,inComponentRef,inAbsynArrayDimOption,inTypesEqModOption,inBoolean,inInteractiveInteractiveSymbolTableOption)
    local
      list<DimExp> res;
      list<Env.Frame> env;
      Absyn.ComponentRef owncref;
      list<Absyn.Subscript> ad;
      Option<Types.EqMod> eq;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
    case (env,owncref,SOME(ad),eq,impl,st) /* optional arraydim impl */ 
      equation 
        res = elabArraydim(env, owncref, ad, eq, impl, st);
      then
        res;
    case (env,owncref,NONE,eq,impl,st) then {}; 
  end matchcontinue;
end elabArraydimOpt;

protected function elabArraydim "function: elabArraydim
 
  This functions examines both an `Absyn.ArrayDim\' and an `Types.EqMod
  option\' argument to find out the dimensions af a component.  If
  no equation modifications is given, only the declared dimension is
  used.
 
  When the size of a dimension in the type is undefined, the
  corresponding size in the type of the modification is used.
 
  All this is accomplished by examining the two arguments separately
  and then using `complete_arraydime\' or `compatible_arraydim\' to
  check that that the dimension sizes are compatible and complete.
"
  input Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.ArrayDim inArrayDim;
  input Option<Types.EqMod> inTypesEqModOption;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  output list<DimExp> outDimExpLst;
algorithm 
  outDimExpLst:=
  matchcontinue (inEnv,inComponentRef,inArrayDim,inTypesEqModOption,inBoolean,inInteractiveInteractiveSymbolTableOption)
    local
      list<Option<DimExp>> dim,dim1,dim2;
      list<DimExp> dim_1,dim3;
      list<Env.Frame> env;
      Absyn.ComponentRef cref;
      list<Absyn.Subscript> ad;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Exp.Exp e,e_1;
      tuple<Types.TType, Option<Absyn.Path>> t;
      String e_str,t_str,dim_str;
    case (env,cref,ad,NONE,impl,st) /* impl */ 
      equation 
        dim = elabArraydimDecl(env, cref, ad, impl, st);
        dim_1 = completeArraydim(dim);
      then
        dim_1;
    case (env,cref,ad,SOME(Types.TYPED(e,_,Types.PROP(t,_))),impl,st) /* Untyped expressions must be elaborated. */ 
      equation 
        dim1 = elabArraydimDecl(env, cref, ad, impl, st);
        dim2 = elabArraydimType(t, ad);
        dim3 = compatibleArraydim(dim1, dim2);
      then
        dim3;
    case (env,cref,ad,SOME(Types.UNTYPED(e)),impl,st)
      local Absyn.Exp e;
      equation 
        (e_1,Types.PROP(t,_),_) = Static.elabExp(env, e, impl, st);
        dim1 = elabArraydimDecl(env, cref, ad, impl, st);
        dim2 = elabArraydimType(t, ad);
        dim3 = compatibleArraydim(dim1, dim2);
      then
        dim3;
    case (env,cref,ad,SOME(Types.TYPED(e,_,Types.PROP(t,_))),impl,st)
      equation 
        dim1 = elabArraydimDecl(env, cref, ad, impl, st);
        dim2 = elabArraydimType(t, ad);
        failure(dim3 = compatibleArraydim(dim1, dim2));
        e_str = Exp.printExpStr(e);
        t_str = Types.unparseType(t);
        dim_str = printDimStr(dim1);
        Error.addMessage(Error.ARRAY_DIMENSION_MISMATCH, {e_str,t_str,dim_str});
      then
        fail();
    case (_,cref,ad,_,_,_)
      equation 
        //Debug.fprint("failtrace", "- elab_arraydim failed\n cref:");
        Debug.fcall("failtrace", Dump.printComponentRef, cref);
        //Debug.fprint("failtrace", " dim: ");
        Debug.fcall("failtrace", Dump.printArraydim, ad);
        //Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end elabArraydim;

protected function printDimStr "function: print_dim
 
  This function prints array dimensions.  The code is not included
  in the report.
"
  input list<Option<DimExp>> inDimExpOptionLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inDimExpOptionLst)
    local
      String s,str,res,s2,s1;
      Integer x;
      list<Option<DimExp>> xs;
    case {NONE} then ":"; 
    case {SOME(DIMINT(x))}
      equation 
        s = intString(x);
      then
        s;
    case {SOME(DIMEXP(x,_))}
      local Exp.Subscript x;
      equation 
        s = Exp.printSubscriptStr(x);
      then
        s;
    case (NONE :: xs)
      equation 
        str = printDimStr(xs);
        res = stringAppend(":,", str);
      then
        res;
    case (SOME(DIMINT(x)) :: xs)
      equation 
        s = intString(x);
        s2 = printDimStr(xs);
        res = Util.stringAppendList({s,",",s2});
      then
        res;
    case (SOME(DIMEXP(x,_)) :: xs)
      local Exp.Subscript x;
      equation 
        s1 = Exp.printSubscriptStr(x);
        s2 = printDimStr(xs);
        res = Util.stringAppendList({s1,",",s2});
      then
        res;
    case (_) then ""; 
  end matchcontinue;
end printDimStr;

protected function printDim "function: printDim
 
  Prints a dimension expression option list to the print buffer.
"
  input list<Option<DimExp>> dims;
  String str;
algorithm 
  str := printDimStr(dims);
  Print.printBuf(str);
end printDim;

protected function printDim2 "function printDim2
 
  Helper function to print_dim
"
  input list<DimExp> inDimExpLst;
algorithm 
  _:=
  matchcontinue (inDimExpLst)
    local
      String s;
      Integer x;
      list<DimExp> xs;
    case {DIMINT(integer = x)}
      equation 
        s = intString(x);
        Print.printBuf(s);
      then
        ();
    case {DIMEXP(subscript = x)}
      local Exp.Subscript x;
      equation 
        Exp.printSubscript(x);
      then
        ();
    case (DIMINT(integer = x) :: xs)
      equation 
        s = intString(x);
        Print.printBuf(s);
        Print.printBuf(",");
        printDim2(xs);
      then
        ();
    case (DIMEXP(subscript = x) :: xs)
      local Exp.Subscript x;
      equation 
        Exp.printSubscript(x);
        Print.printBuf(",");
        printDim2(xs);
      then
        ();
    case {} then (); 
  end matchcontinue;
end printDim2;

protected function elabArraydimDecl "function: elabArraydimDecl
 
  Given an `Absyn.ArrayDim\', this function evaluates all dimension
  size specifications, creating a list of (optional) integers.  When
  the array dimension size is specified as `:\', the result will
  contain `NONE\'.
"
  input Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.ArrayDim inArrayDim;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  output list<Option<DimExp>> outDimExpOptionLst;
algorithm 
  outDimExpOptionLst:=
  matchcontinue (inEnv,inComponentRef,inArrayDim,inBoolean,inInteractiveInteractiveSymbolTableOption)
    local
      list<Option<DimExp>> l;
      list<Env.Frame> env;
      Absyn.ComponentRef cref,cr;
      list<Absyn.Subscript> ds;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Exp.Exp e;
      Types.Const cnst;
      Integer i;
      Absyn.Exp d;
      String str,e_str,t_str;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case (_,_,{},_,_) then {}; 
    case (env,cref,(Absyn.NOSUB() :: ds),impl,st)
      equation 
        l = elabArraydimDecl(env, cref, ds, impl, st);
      then
        (NONE :: l);
    case (env,cref,(Absyn.SUBSCRIPT(subScript = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "size"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr),_}))) :: ds),impl,st) /* For functions, this can occur: Real x{:,size(x,1)} ,i.e. 
	  refering to  the variable itself but a different dimension. */ 
      equation 
        true = Absyn.crefEqual(cref, cr);
        l = elabArraydimDecl(env, cref, ds, impl, st);
      then
        (NONE :: l);
    case (env,cref,(Absyn.SUBSCRIPT(subScript = d) :: ds),impl,st) /* Constant dimension creates DIMINT, valid for both implicit and 
	  nonimplicit instantiation.
	 as false */ 
      equation 
        //Debug.fprintln("insttr", "elab_arraydim_decl5");
        (e,Types.PROP((Types.T_INTEGER(_),_),cnst),_) = Static.elabExp(env, d, impl, st);
        failure(equality(cnst = Types.C_VAR()));
        (Values.INTEGER(i),_) = Ceval.ceval(env, e, impl, st, NONE, Ceval.MSG());
        l = elabArraydimDecl(env, cref, ds, impl, st);
      then
        (SOME(DIMINT(i)) :: l);
    case (env,cref,(Absyn.SUBSCRIPT(subScript = d) :: ds),(impl as false),st) /* when not implicit instantiation, array dim. must be constant. */ 
      equation 
        //Debug.fprintln("insttr", "elab_arraydim_decl5");
        (e,Types.PROP((Types.T_INTEGER(_),_),Types.C_VAR()),_) = Static.elabExp(env, d, impl, st);
        str = Dump.printExpStr(d);
        Error.addMessage(Error.DIMENSION_NOT_KNOWN, {str});
      then
        fail();
    case (env,cref,(Absyn.SUBSCRIPT(subScript = d) :: ds),(impl as true),st) /* Non-constant dimension creates DIMEXP */ 
      equation 
        //Debug.fprintln("insttr", "elab_arraydim_decl6");
        (e,Types.PROP((Types.T_INTEGER(_),_),cnst),_) = Static.elabExp(env, d, impl, st);
        l = elabArraydimDecl(env, cref, ds, impl, st);
      then
        (SOME(DIMEXP(Exp.INDEX(e),NONE)) :: l);
    case (env,cref,(Absyn.SUBSCRIPT(subScript = d) :: ds),impl,st) /* Size(x,1) in e.g. functions => Unknown dimension */ 
      equation 
        ((e as Exp.SIZE(_,_)),Types.PROP(t,_),_) = Static.elabExp(env, d, impl, st);
        l = elabArraydimDecl(env, cref, ds, impl, st);
      then
        (SOME(DIMEXP(Exp.INDEX(e),NONE)) :: l);
    case (env,cref,(Absyn.SUBSCRIPT(subScript = d) :: ds),impl,st)
      equation 
        (e,Types.PROP(t,_),_) = Static.elabExp(env, d, impl, st);
        e_str = Exp.printExpStr(e);
        t_str = Types.unparseType(t);
        Error.addMessage(Error.ARRAY_DIMENSION_INTEGER, {e_str,t_str});
      then
        fail();
    case (_,_,_,_,_)
      equation 
        //Debug.fprint("failtrace", "- elab_arraydim_decl failed\n");
      then
        fail();
  end matchcontinue;
end elabArraydimDecl;

protected function completeArraydim "function: completeArraydim
 
  This function converts a list of optional integers to a list of
  integers.  If one element of the list is `NONE\', this function
  will fail.
 
  This is used to check that an array specification contain fully
  specified array dimension sizes.
"
  input list<Option<DimExp>> inDimExpOptionLst;
  output list<DimExp> outDimExpLst;
algorithm 
  outDimExpLst:=
  matchcontinue (inDimExpOptionLst)
    local
      list<DimExp> xs_1;
      DimExp x;
      list<Option<DimExp>> xs;
    case {} then {}; 
    case (SOME(x) :: xs)
      equation 
        xs_1 = completeArraydim(xs);
      then
        (x :: xs_1);
    case (NONE :: xs)
      equation 
        xs_1 = completeArraydim(xs);
      then
        (DIMEXP(Exp.WHOLEDIM(),NONE) :: xs_1);
  end matchcontinue;
end completeArraydim;

protected function compatibleArraydim "function: compatibleArraydim
 
  Given two, possibly incomplete, array dimension size
  specifications as list of optional integers, this function checks
  whether they are compatible.  Being compatible means that they
  have the same number of dimension, and for every dimension at
  least one of the lists specifies its size.  If both lists specify
  a dimension size, they have to specify the same size.
"
  input list<Option<DimExp>> inDimExpOptionLst1;
  input list<Option<DimExp>> inDimExpOptionLst2;
  output list<DimExp> outDimExpLst;
algorithm 
  outDimExpLst:=
  matchcontinue (inDimExpOptionLst1,inDimExpOptionLst2)
    local
      list<DimExp> l;
      DimExp x,y,de;
      list<Option<DimExp>> xs,ys;
      Option<Exp.Exp> e,e1,e2;
    case ({},{}) then {}; 
    case ((SOME(x) :: xs),(NONE :: ys))
      equation 
        l = compatibleArraydim(xs, ys);
      then
        (x :: l);
    case ((NONE :: xs),(SOME(y) :: ys))
      equation 
        l = compatibleArraydim(xs, ys);
      then
        (y :: l);
    case ((SOME(DIMINT(x)) :: xs),(SOME(DIMINT(y)) :: ys))
      local Integer x,y;
      equation 
        equality(x = y);
        l = compatibleArraydim(xs, ys);
      then
        (DIMINT(x) :: l);
    case ((SOME(DIMINT(x)) :: xs),(SOME(DIMEXP(y,e)) :: ys))
      local
        Integer x;
        Exp.Subscript y;
      equation 
        de = arraydimCondition(DIMEXP(Exp.INDEX(Exp.ICONST(x)),NONE), DIMEXP(y,e));
        l = compatibleArraydim(xs, ys);
      then
        (de :: l);
    case ((SOME(DIMEXP(x,e)) :: xs),(SOME(DIMINT(y)) :: ys))
      local
        Exp.Subscript x;
        Integer y;
      equation 
        de = arraydimCondition(DIMEXP(Exp.INDEX(Exp.ICONST(y)),NONE), DIMEXP(x,e));
        l = compatibleArraydim(xs, ys);
      then
        (de :: l);
    case ((SOME(DIMEXP(x,e1)) :: xs),(SOME(DIMEXP(y,e2)) :: ys))
      local Exp.Subscript x,y;
      equation 
        de = arraydimCondition(DIMEXP(x,e1), DIMEXP(y,e2));
        l = compatibleArraydim(xs, ys);
      then
        (de :: l);
    case ((NONE :: xs),(NONE :: ys))
      equation 
        l = compatibleArraydim(xs, ys);
      then
        (DIMEXP(Exp.WHOLEDIM(),NONE) :: l);
    case (_,_)
      equation 
        Print.printBuf("-compatible_arraydim failed\n");
        //Debug.fprint("failtrace", "- compatible_arraydim failed\n");
      then
        fail();
  end matchcontinue;
end compatibleArraydim;

protected function arraydimCondition "function arraydimCondition
  
  This function checks that the two arraydim expressions have the same 
  dimension.
  FIXME: no check performed yet, just return first DimExp.
"
  input DimExp inDimExp1;
  input DimExp inDimExp2;
  output DimExp outDimExp;
algorithm 
  outDimExp:=
  matchcontinue (inDimExp1,inDimExp2)
    local DimExp de;
    case (de,_) then de; 
  end matchcontinue;
end arraydimCondition;

protected function elabArraydimType "function: elabArraydimType
 
  Find out the dimension sizes of a type.  The second argument is
  used to know how many dimensions should be extracted from the
  type.
"
  input Types.Type inType;
  input Absyn.ArrayDim inArrayDim;
  output list<Option<DimExp>> outDimExpOptionLst;
algorithm 
  outDimExpOptionLst:=
  matchcontinue (inType,inArrayDim)
    local
      list<Option<DimExp>> l;
      tuple<Types.TType, Option<Absyn.Path>> t;
      list<Absyn.Subscript> ad;
      Integer i;
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = NONE),arrayType = t),_),(_ :: ad))
      equation 
        l = elabArraydimType(t, ad);
      then
        (NONE :: l);
    case ((Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(i)),arrayType = t),_),(_ :: ad))
      equation 
        l = elabArraydimType(t, ad);
      then
        (SOME(DIMINT(i)) :: l);
    case (_,{}) then {}; 
    case (t,(_ :: ad)) /* PR, for debugging */ 
      equation 
        //Debug.fprint("failtrace", "Undefined!");
        //Debug.fprint("failtrace", " The type detected: ");
        Debug.fcall("failtrace", Types.printType, t);
      then
        fail();
  end matchcontinue;
end elabArraydimType;

public function instClassDecl "function: instClassDecl
 
  The class definition is instantiated although no variable
  is declared with it.  After instantiating it, it is
  checked to see if it can be used as a package, and if it
  can, then it is added as a variable under the same name as
  the class.  This makes it possible to use a unified lookup
  mechanism.  And since packages only can contain constants
  and class definition, instantiating a package does not do
  anything else.
"
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input SCode.Class inClass;
  input InstDims inInstDims;
  output Env outEnv;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  (outEnv,outDAEElementLst):=
  matchcontinue (inEnv,inMod,inPrefix,inSets,inClass,inInstDims,inBoolean)
    local
      list<Env.Frame> env_1,env_2,env;
      list<DAE.Element> dae;
      Types.Mod mod;
      Prefix.Prefix pre;
      Connect.Sets csets;
      SCode.Class c;
      String n;
      SCode.Restriction restr;
      InstDims inst_dims;
    case (env,mod,pre,csets,(c as SCode.CLASS(name = n,restricion = restr)),inst_dims)  
      local String s;
      equation 
        env_1 = Env.extendFrameC(env, c);
        (env_2,dae) = implicitInstantiation(env_1, Types.NOMOD(), pre, csets, c, inst_dims);
      then
        (env_2,dae);
    case (env,_,_,_,_,_)
      equation 
        //Debug.fprint("failtrace", "- inst_class_decl failed\n");
      then
        fail();
  end matchcontinue;
end instClassDecl;

public function implicitInstantiation "function implicitInstantiation
 
  This function adds types to the environment.
 
  If a class definition is a function or a package or an enumeration , 
  it is implicitly instantiated and added as a type binding under the
  same name as the class name.
"
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input SCode.Class inClass;
  input InstDims inInstDims;
  output Env outEnv;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  (outEnv,outDAEElementLst):=
  matchcontinue (inEnv,inMod,inPrefix,inSets,inClass,inInstDims)
    local
      list<DAE.Element> dae;
      Connect.Sets csets_1,csets;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      ClassInf.State st;
      list<Env.Frame> env_1,env,tempenv,env_2;
      Absyn.Path fpath;
      Types.Mod mod;
      Prefix.Prefix pre;
      SCode.Class c,enumclass;
      String n;
      InstDims inst_dims;
      Boolean prot;
      DAE.ExternalDecl extdecl;
      SCode.Restriction restr;
      SCode.ClassDef parts;
      list<SCode.Element> els;
      list<String> l;
     case (env,mod,pre,csets,(c as SCode.CLASS(name = n,restricion = SCode.R_TYPE(),parts = SCode.ENUMERATION(identLst = l))),inst_dims) /* enumerations */ 
      equation 
        enumclass = instEnumeration(n, l);
        env_2 = Env.extendFrameC(env, enumclass); 
      then
        (env_2,{});
    case (env,mod,pre,csets,c,_) then (env,{});  /* .. the rest will fall trough */
  end matchcontinue;
end implicitInstantiation;

public function makeFullyQualified "function: makeFullyQualified
  author: PA
 
  Transforms a class name to its fully qualified name by investigating the 
  environment.
  For instance, the model Resistor in Modelica.Electrical.Analog.Basic will
  given the correct environment have the fully qualified name: 
  Modelica.Electrical.Analog.Basic.Resistor
"
  input Env inEnv;
  input Absyn.Path inPath;
  output Absyn.Path outPath;
algorithm 
  outPath:=
  matchcontinue (inEnv,inPath)
    local
      list<Env.Frame> env,env_1;
      Absyn.Path path,path_1,path_2;
      String class_name;
    case (env,path)
      equation 
        NONE = Env.getEnvPath(env);
      then
        path;
    case (env,path) /* To make a class fully qualified, the class path
	  is looked up in the environment.
	  The FQ path consist of the simple class name
	  appended to the environment path of the looked up class.
	 */ 
	 local String s;
      equation 
         (_,env_1) = Lookup.lookupClass(env, path, false);
        SOME(path_1) = Env.getEnvPath(env_1);
        class_name = Absyn.pathLastIdent(path);
        path_2 = Absyn.joinPaths(path_1, Absyn.IDENT(class_name));
      then
        path_2;
    case (env,path) then path;  /* If it fails, leave name unchanged. */ 
  end matchcontinue;
end makeFullyQualified;

public function implicitFunctionInstantiation "function: implicitFunctionInstantiation
 
  This function instantiates a function, which is performed \"implicitly\" 
  since the variables of a function should not be instantiated as for an 
  ordinary class.
"
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input SCode.Class inClass;
  input InstDims inInstDims;
  output Env outEnv;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  (outEnv,outDAEElementLst):=
  matchcontinue (inEnv,inMod,inPrefix,inSets,inClass,inInstDims)
    local
      list<DAE.Element> dae,daefuncs;
      Connect.Sets csets_1,csets;
      tuple<Types.TType, Option<Absyn.Path>> ty,ty1;
      ClassInf.State st;
      list<Env.Frame> env_1,env,tempenv,cenv;
      Absyn.Path fpath;
      Types.Mod mod;
      Prefix.Prefix pre;
      SCode.Class c;
      String n;
      InstDims inst_dims;
      Boolean prot;
      DAE.ExternalDecl extdecl;
      SCode.Restriction restr;
      SCode.ClassDef parts;
      list<SCode.Element> els;
      list<Absyn.Path> funcnames;
    case (env,mod,pre,csets,(c as SCode.CLASS(name = n,restricion = SCode.R_FUNCTION())),inst_dims)
   local String s;
      equation 
        (dae,cenv,csets_1,ty,st) = instClass(env, mod, pre, csets, c, inst_dims, true, INNER_CALL());
        env_1 = Env.extendFrameC(env,c);
        fpath = makeFullyQualified(env_1, Absyn.IDENT(n));
        ty1 = setFullyQualifiedTypename(ty,fpath);
        env_1 = Env.extendFrameT(env_1, n, ty1); 
      then
        (env_1,{DAE.FUNCTION(fpath,DAE.DAE(dae),ty1)});

        /* External functions should also have their type in env, 
         but no dae. */ 
    case (env,mod,pre,csets,(c as SCode.CLASS(name = n,restricion = (restr as SCode.R_EXT_FUNCTION()),parts = (parts as SCode.PARTS(elementLst = els)))),inst_dims)
      equation 
        (dae,cenv,csets_1,ty,st) = instClass(env, mod, pre, csets, c, inst_dims, true, INNER_CALL());
        env_1 = Env.extendFrameC(env,c);    
        fpath = makeFullyQualified(env_1, Absyn.IDENT(n));
        ty1 = setFullyQualifiedTypename(ty,fpath);
        env_1 = Env.extendFrameT(env_1, n, ty1);
        prot = false;
        (_,tempenv,_,_,_,_) = instClassdef(env_1, mod, pre, csets_1, ClassInf.FUNCTION(n), parts, 
          restr, prot, inst_dims, true) "how to get this? impl" ;
        extdecl = instExtDecl(tempenv, n, parts, true) "impl" ;
      then
        (env_1,{DAE.EXTFUNCTION(fpath,DAE.DAE(dae),ty1,extdecl)});
    case (env,mod,pre,csets,(c as SCode.CLASS(name = n,restricion = (restr as SCode.R_FUNCTION()),parts = SCode.OVERLOAD(absynPathLst = funcnames))),inst_dims)
      equation 
        (env_1,daefuncs) = instOverloadedFunctions(env, n, funcnames) "Overloaded functions" ;
      then
        (env_1,daefuncs);
    case (_,_,_,_,_,_) equation /*print("implicit_function_instantiation failed\n");*/ then fail(); 
  end matchcontinue;
end implicitFunctionInstantiation;

protected function setFullyQualifiedTypename "This function sets the FQ path
given as argument in types that have optional path set. (The optional path
points to the class the type is built from)"

  input tuple<Types.TType, Option<Absyn.Path>> inType;
  input Absyn.Path path;
  output tuple<Types.TType, Option<Absyn.Path>> resType;
algorithm 
  resType := matchcontinue (tp,path) 
  local Absyn.Path p,newPath;
        Types.TType tp;   
  		case ((tp,NONE()),_) then ((tp,NONE));
  		case ((tp,SOME(p)),newPath) then ((tp,SOME(newPath)));
  end matchcontinue;
end setFullyQualifiedTypename; 
  
public function implicitFunctionTypeInstantiation "function implicitFunctionTypeInstantiation
  author: PA
 
  When looking up a function type it is sufficient to only instantiate the 
  input  and output arguments of the function. 
  The implicit_function_instantiation function will instantiate the function
  body, resulting in a DAE for the body. This function does not do that. 
  Therefore this function is the only solution available for recursive 
  functions, where the function body contain a call to the function itself.
"
  input Env inEnv;
  input SCode.Class inClass;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv,inClass)
    local
      SCode.Class stripped_class;
      list<Env.Frame> env_1,env;
      String id;
      Boolean p,e;
      SCode.Restriction r;
      option<Absyn.ExternalDecl> extDecl;
      list<SCode.Element> elts;
    case (env,SCode.CLASS(name = id,partial_ = p,encapsulated_ = e,restricion = r,parts = SCode.PARTS(elementLst = elts,used=extDecl))) /* The function type can be determined without the body. */ 
      equation 
        stripped_class = SCode.CLASS(id,p,e,r,SCode.PARTS(elts,{},{},{},{},extDecl));
        (env_1,_) = implicitFunctionInstantiation(env, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, stripped_class, {});
      then
        env_1;
  end matchcontinue;
end implicitFunctionTypeInstantiation;

protected function instOverloadedFunctions "function: instOverloadedFunctions
 
  This function instantiates the functions in the overload list of a 
  overloading function definition and register the function types using the
  overloaded name. It also creates dae elements for the functions. 
"
  input Env inEnv;
  input Absyn.Ident inIdent;
  input list<Absyn.Path> inAbsynPathLst;
  output Env outEnv;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  (outEnv,outDAEElementLst):=
  matchcontinue (inEnv,inIdent,inAbsynPathLst)
    local
      list<Env.Frame> env,cenv,env_1,env_2;
      SCode.Class c;
      String id,overloadname;
      Boolean encflag;
      list<DAE.Element> dae,dae1;
      list<tuple<String, tuple<Types.TType, Option<Absyn.Path>>>> args;
      tuple<Types.TType, Option<Absyn.Path>> tp,ty;
      ClassInf.State st;
      Absyn.Path fpath,ovlfpath,fn;
      list<Absyn.Path> fns;
    case (env,_,{}) then (env,{}); 
    case (env,overloadname,(fn :: fns)) /* Instantiate each function, add its FQ name to the type, 
	  needed when deoverloading */ 
      equation 
        ((c as SCode.CLASS(id,_,encflag,SCode.R_FUNCTION(),_)),cenv) = Lookup.lookupClass(env, fn, true);
        (dae,_,_,(Types.T_FUNCTION(args,tp),_),st) = instClass(cenv, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, 
          {}, true, INNER_CALL());
        fpath = makeFullyQualified(env, Absyn.IDENT(overloadname));
        ovlfpath = makeFullyQualified(cenv, Absyn.IDENT(id));
        ty = (Types.T_FUNCTION(args,tp),SOME(ovlfpath));
        env_1 = Env.extendFrameT(env, overloadname, ty);
        (env_2,dae1) = instOverloadedFunctions(env_1, overloadname, fns);
      then
        (env_2,(DAE.FUNCTION(fpath,DAE.DAE(dae),ty) :: dae1));
    case (env,_,_)
      equation 
        //Debug.fprint("failtrace", "inst_overloaded_functions failed\n");
      then
        fail();
  end matchcontinue;
end instOverloadedFunctions;

protected function instExtDecl "function: instExtDecl
  author: LS
 
  This function handles the external declaration. If there is an explicit 
  call of the external function, the component references are looked up and
  inserted in the argument list, otherwise the input and output parameters
  are inserted in the argument list with their order. The return type is
  determined according to the specification; if there is a explicit call 
  and a lhs, which must be an output parameter, the type of the function is
  that type. If no explicit call and only one output parameter exists, then
  this will be the return type of the function, otherwise the return type 
  will be void. 
"
  input Env inEnv;
  input Ident inIdent;
  input SCode.ClassDef inClassDef;
  input Boolean inBoolean;
  output DAE.ExternalDecl outExternalDecl;
algorithm 
  outExternalDecl:=
  matchcontinue (inEnv,inIdent,inClassDef,inBoolean)
    local
      String fname,lang,n;
      list<DAE.ExtArg> fargs;
      DAE.ExtArg rettype;
      Option<Absyn.Annotation> ann;
      DAE.ExternalDecl daeextdecl;
      list<Env.Frame> env;
      Absyn.ExternalDecl extdecl,orgextdecl;
      Boolean impl;
      list<SCode.Element> els;
    case (env,n,SCode.PARTS(elementLst=els,used = SOME(extdecl)),impl) /* impl */ 
      equation 
        isExtExplicitCall(extdecl);
        fname = instExtGetFname(extdecl, n);
        fargs = instExtGetFargs(env, extdecl, impl);
        rettype = instExtGetRettype(env, extdecl, impl);
        lang = instExtGetLang(extdecl);
        ann = instExtGetAnnotation(extdecl);
        daeextdecl = DAE.EXTERNALDECL(fname,fargs,rettype,lang,ann);
      then
        daeextdecl;
    case (env,n,SCode.PARTS(elementLst = els,used = SOME(orgextdecl)),impl)
      equation 
        failure(isExtExplicitCall(orgextdecl));
        extdecl = instExtMakeExternaldecl(n, els, orgextdecl);
        fname = instExtGetFname(extdecl, n);
        fargs = instExtGetFargs(env, extdecl, impl);
        rettype = instExtGetRettype(env, extdecl, impl);
        lang = instExtGetLang(extdecl);
        ann = instExtGetAnnotation(orgextdecl);
        daeextdecl = DAE.EXTERNALDECL(fname,fargs,rettype,lang,ann);
      then
        daeextdecl;
    case (env,_,_,_)
      equation 
        //Debug.fprint("failtrace", "#-- inst_ext_decl failed");
      then
        fail();
  end matchcontinue;
end instExtDecl;

protected function isExtExplicitCall "function: isExtExplicitCall
  
  If the external function id is present, then a function call must
  exist, i.e. explicit call was written in the external clause.
"
  input Absyn.ExternalDecl inExternalDecl;
algorithm 
  _:=
  matchcontinue (inExternalDecl)
    local String id;
    case Absyn.EXTERNALDECL(funcName = SOME(id)) then (); 
  end matchcontinue;
end isExtExplicitCall;

protected function instExtMakeExternaldecl "function: instExtMakeExternaldecl
  author: LS
 
  This function generates a default explicit function call, 
  when it is omitted. If only one output variable exists, the 
  implicit call is equivalent to 
  
     external \"C\" output_var=func(input_var1, input_var2,...)
 
  with the input_vars in their declaration order. If several output 
  variables exists, the implicit call is equivalent to
 
     external \"C\" func(var1, var2, ...)
 
  where each var can be input or output.
"
  input Ident inIdent;
  input list<SCode.Element> inSCodeElementLst;
  input Absyn.ExternalDecl inExternalDecl;
  output Absyn.ExternalDecl outExternalDecl;
algorithm 
  outExternalDecl:=
  matchcontinue (inIdent,inSCodeElementLst,inExternalDecl)
    local
      SCode.Element outvar;
      list<SCode.Element> invars,els,inoutvars;
      list<list<Absyn.Exp>> explists;
      list<Absyn.Exp> exps;
      Absyn.ComponentRef retcref;
      Absyn.ExternalDecl extdecl;
      String id;
      Option<String> lang;
    case (id,els,Absyn.EXTERNALDECL(lang = lang)) /* the case with only one output var, and that cannot be array, otherwise
      inst_ext_make_crefs outvar will fail */ 
      equation 
        (outvar :: {}) = Util.listMatching(els, isOutputVar);
        invars = Util.listMatching(els, isInputVar);
        explists = Util.listMap(invars, instExtMakeCrefs);
        exps = Util.listFlatten(explists);
        {Absyn.CREF(retcref)} = instExtMakeCrefs(outvar);
        extdecl = Absyn.EXTERNALDECL(SOME(id),lang,SOME(retcref),exps,NONE);
      then
        extdecl;
    case (id,els,Absyn.EXTERNALDECL(lang = lang))
      equation 
        inoutvars = Util.listMatching(els, isInoutVar);
        explists = Util.listMap(inoutvars, instExtMakeCrefs);
        exps = Util.listFlatten(explists);
        extdecl = Absyn.EXTERNALDECL(SOME(id),lang,NONE,exps,NONE);
      then
        extdecl;
    case (_,_,_)
      equation 
        //Debug.fprint("failtrace", "#-- inst_ext_make_externaldecl failed\n");
      then
        fail();
  end matchcontinue;
end instExtMakeExternaldecl;

protected function isInoutVar "function: isInoutVar 
 
  Succeds for Elements that are input or output components
"
  input SCode.Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local SCode.Element e;
    case e
      equation 
        isOutputVar(e);
      then
        ();
    case e
      equation 
        isInputVar(e);
      then
        ();
  end matchcontinue;
end isInoutVar;

protected function isOutputVar "function: isOutputVar
 
  Succeds for element that is output component
"
  input SCode.Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case SCode.COMPONENT(attributes = SCode.ATTR(input_ = Absyn.OUTPUT())) then (); 
  end matchcontinue;
end isOutputVar;

protected function isInputVar "function: isInputVar
 
  Succeds for element that is input component
"
  input SCode.Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case SCode.COMPONENT(attributes = SCode.ATTR(input_ = Absyn.INPUT())) then (); 
  end matchcontinue;
end isInputVar;

protected function instExtMakeCrefs "function: instExtMakeCrefs
  author: LS
 
  This function is used in external function declarations. It collects the 
  component identifier and the dimension sizes and returns as a 
  Absyn.Exp list
"
  input SCode.Element inElement;
  output list<Absyn.Exp> outAbsynExpLst;
algorithm 
  outAbsynExpLst:=
  matchcontinue (inElement)
    local
      list<Absyn.Exp> sizelist,crlist;
      String id;
      Boolean fi,re,pr;
      list<Absyn.Subscript> dims;
      Absyn.Path path;
      SCode.Mod mod;
      Option<Absyn.Comment> comment;
    case SCode.COMPONENT(component = id,final_ = fi,replaceable_ = re,protected_ = pr,attributes = SCode.ATTR(arrayDim = dims),type_ = path,mod = mod,this = comment)
      equation 
        sizelist = instExtMakeCrefs2(id, dims, 1);
        crlist = (Absyn.CREF(Absyn.CREF_IDENT(id,{})) :: sizelist);
      then
        crlist;
  end matchcontinue;
end instExtMakeCrefs;

protected function instExtMakeCrefs2 "function: instExtMakeCrefs2
 
  Helper function to inst_ext_make_crefs, collects array dimension sizes.
"
  input SCode.Ident inIdent;
  input Absyn.ArrayDim inArrayDim;
  input Integer inInteger;
  output list<Absyn.Exp> outAbsynExpLst;
algorithm 
  outAbsynExpLst:=
  matchcontinue (inIdent,inArrayDim,inInteger)
    local
      String id;
      Integer nextdimno,dimno;
      list<Absyn.Exp> restlist,exps;
      Absyn.Subscript dim;
      list<Absyn.Subscript> restdim;
    case (id,{},_) then {}; 
    case (id,(dim :: restdim),dimno)
      equation 
        nextdimno = dimno + 1;
        restlist = instExtMakeCrefs2(id, restdim, nextdimno);
        exps = (Absyn.CALL(Absyn.CREF_IDENT("size",{}),
          Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(id,{})),Absyn.INTEGER(dimno)},
          {})) :: restlist);
      then
        exps;
  end matchcontinue;
end instExtMakeCrefs2;

protected function instExtGetFname "function: inst_ex_get_fname
  
  Returns the function name of the externally defined function.
"
  input Absyn.ExternalDecl inExternalDecl;
  input Ident inIdent;
  output Ident outIdent;
algorithm 
  outIdent:=
  matchcontinue (inExternalDecl,inIdent)
    local String id,fid;
    case (Absyn.EXTERNALDECL(funcName = SOME(id)),fid) then id; 
    case (Absyn.EXTERNALDECL(funcName = NONE),fid) then fid; 
  end matchcontinue;
end instExtGetFname;

protected function instExtGetAnnotation "function: instExtGetAnnotation
  author: PA
 
  Return the annotation associated with an external function declaration.
  If no annotation is found, check the classpart annotations.
"
  input Absyn.ExternalDecl inExternalDecl;
  output Option<Absyn.Annotation> outAbsynAnnotationOption;
algorithm 
  outAbsynAnnotationOption:=
  matchcontinue (inExternalDecl,els)
    local Option<Absyn.Annotation> ann;
    case (Absyn.EXTERNALDECL(annotation_ = ann)) then ann; 
  end matchcontinue;
end instExtGetAnnotation;

protected function instExtGetLang "function: instExtGetLang
 
  Return the implementation language of the external function declaration
  Defaults to \"C\" if no language specified.
"
  input Absyn.ExternalDecl inExternalDecl;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExternalDecl)
    local String lang;
    case Absyn.EXTERNALDECL(lang = SOME(lang)) then lang; 
    case Absyn.EXTERNALDECL(lang = NONE) then "C"; 
  end matchcontinue;
end instExtGetLang;

protected function elabExpListExt "function: elabExpListExt
 
  special elab_exp for explicit external calls. This special function calls 
  elab_exp_ext which handles size builtin calls specially, and uses the 
  ordinary  Static.elab_exp for other expressions.
"
  input Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  output list<Exp.Exp> outExpExpLst;
  output list<Types.Properties> outTypesPropertiesLst;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outExpExpLst,outTypesPropertiesLst,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption)
    local
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st,st_1,st_2;
      Exp.Exp exp;
      Types.Properties p;
      list<Exp.Exp> exps;
      list<Types.Properties> props;
      list<Env.Frame> env;
      Absyn.Exp e;
      list<Absyn.Exp> rest;
    case (_,{},impl,st) then ({},{},st); 
    case (env,(e :: rest),impl,st)
      equation 
        (exp,p,st_1) = elabExpExt(env, e, impl, st);
        (exps,props,st_2) = elabExpListExt(env, rest, impl, st_1);
      then
        ((exp :: exps),(p :: props),st_2);
  end matchcontinue;
end elabExpListExt;

protected function elabExpExt "function: elabExpExt
  author: LS
 
  special elab_exp for explicit external calls. This special function calls 
  elab_exp_ext which handles size builtin calls specially, and uses the 
  ordinary Static.elab_exp for other expressions.
"
  input Env inEnv;
  input Absyn.Exp inExp;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  output Exp.Exp outExp;
  output Types.Properties outProperties;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outExp,outProperties,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption)
    local
      Exp.Exp dimp,arraycrefe,exp,e;
      tuple<Types.TType, Option<Absyn.Path>> dimty;
      Types.Properties arraycrprop,prop;
      list<Env.Frame> env;
      Absyn.Exp call,arraycr,dim;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
    case (env,(call as Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "size"),functionArgs = Absyn.FUNCTIONARGS(args = (args as {arraycr,dim}),argNames = nargs))),impl,st) /* special case for  size */ 
      equation 
        (dimp,Types.PROP(dimty,_),_) = Static.elabExp(env, dim, impl, NONE);
        (arraycrefe,arraycrprop,_) = Static.elabExp(env, arraycr, impl, NONE);
        exp = Exp.SIZE(arraycrefe,SOME(dimp));
      then
        (exp,Types.PROP((Types.T_INTEGER({}),NONE),Types.C_VAR()),st);
    case (env,exp,impl,st) /* For all other expressions, use normal elaboration */ 
      local Absyn.Exp exp;
      equation 
        (e,prop,st) = Static.elabExp(env, exp, impl, st);
      then
        (e,prop,st);
    case (env,exp,impl,st)
      local Absyn.Exp exp;
      equation 
        //Debug.fprint("failtrace", "-elab_exp_ext failed\n");
      then
        fail();
  end matchcontinue;
end elabExpExt;

protected function instExtGetFargs "function: instExtGetFargs
  author: LS
 
  instantiates function arguments, i.e. actual parameters, in external 
  declaration.
"
  input Env inEnv;
  input Absyn.ExternalDecl inExternalDecl;
  input Boolean inBoolean;
  output list<DAE.ExtArg> outDAEExtArgLst;
algorithm 
  outDAEExtArgLst:=
  matchcontinue (inEnv,inExternalDecl,inBoolean)
    local
      list<Exp.Exp> exps;
      list<Types.Properties> props;
      list<DAE.ExtArg> extargs;
      list<Env.Frame> env;
      Option<String> id,lang;
      Option<Absyn.ComponentRef> retcr;
      list<Absyn.Exp> absexps;
      Boolean impl;
    case (env,Absyn.EXTERNALDECL(funcName = id,lang = lang,output_ = retcr,args = absexps),impl) /* impl */ 
      equation 
        (exps,props,_) = elabExpListExt(env, absexps, impl, NONE);
        extargs = instExtGetFargs2(env, exps, props);
      then
        extargs;
    case (_,_,impl)
      equation 
        //Debug.fprint("failtrace", "- inst_ext_get_fargs failed\n");
      then
        fail();
  end matchcontinue;
end instExtGetFargs;

protected function instExtGetFargs2 "function: instExtGetFargs2
  author: LS
 
  Helper function to inst_ext_get_fargs
"
  input Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input list<Types.Properties> inTypesPropertiesLst;
  output list<DAE.ExtArg> outDAEExtArgLst;
algorithm 
  outDAEExtArgLst:=
  matchcontinue (inEnv,inExpExpLst,inTypesPropertiesLst)
    local
      list<DAE.ExtArg> extargs;
      DAE.ExtArg extarg;
      list<Env.Frame> env;
      Exp.Exp e;
      list<Exp.Exp> exps;
      Types.Properties p;
      list<Types.Properties> props;
    case (_,{},_) then {}; 
    case (env,(e :: exps),(p :: props))
      equation 
        extargs = instExtGetFargs2(env, exps, props);
        extarg = instExtGetFargsSingle(env, e, p);
      then
        (extarg :: extargs);
  end matchcontinue;
end instExtGetFargs2;

protected function instExtGetFargsSingle "function: instExtGetFargsSingle
  author: LS
 
  Helper function to inst_ext_get_fargs2, does the work for one argument.
"
  input Env inEnv;
  input Exp.Exp inExp;
  input Types.Properties inProperties;
  output DAE.ExtArg outExtArg;
algorithm 
  outExtArg:=
  matchcontinue (inEnv,inExp,inProperties)
    local
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty,varty;
      Types.Binding bnd;
      list<Env.Frame> env;
      Exp.ComponentRef cref;
      Exp.Type crty;
      Types.Const cnst;
      String crefstr,scope;
      Exp.Exp dim,exp;
      Types.Properties prop;
    case (env,Exp.CREF(componentRef = cref,ty = crty),Types.PROP(type_ = ty,constFlag = cnst))
      equation 
        (attr,ty,bnd) = Lookup.lookupVarLocal(env, cref);
      then
        DAE.EXTARG(cref,attr,ty);
    case (env,Exp.CREF(componentRef = cref,ty = crty),Types.PROP(type_ = ty,constFlag = cnst))
      equation 
        failure((attr,ty,bnd) = Lookup.lookupVarLocal(env, cref));
        crefstr = Exp.printComponentRefStr(cref);
        scope = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_VARIABLE_ERROR, {crefstr,scope});
      then
        fail();
    case (env,Exp.SIZE(exp = Exp.CREF(componentRef = cref,ty = crty),sz = SOME(dim)),Types.PROP(type_ = ty,constFlag = cnst))
      equation 
        (attr,varty,bnd) = Lookup.lookupVarLocal(env, cref);
      then
        DAE.EXTARGSIZE(cref,attr,varty,dim);
    case (env,exp,Types.PROP(type_ = ty,constFlag = cnst)) then DAE.EXTARGEXP(exp,ty); 
    case (_,exp,prop)
      equation 
        //Debug.fprint("failtrace", "#-- inst_ext_get_fargs_single failed\n");
        Debug.fcall("failtrace", Exp.printExp, exp);
        //Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end instExtGetFargsSingle;

protected function instExtGetRettype "function: instExtGetRettype
  author: LS
 
  Instantiates the return type of an external declaration.
"
  input Env inEnv;
  input Absyn.ExternalDecl inExternalDecl;
  input Boolean inBoolean;
  output DAE.ExtArg outExtArg;
algorithm 
  outExtArg:=
  matchcontinue (inEnv,inExternalDecl,inBoolean)
    local
      Exp.Exp exp;
      Types.Properties prop;
      SCode.Accessibility acc;
      DAE.ExtArg extarg;
      list<Env.Frame> env;
      Option<String> n,lang;
      Absyn.ComponentRef cref;
      list<Absyn.Exp> args;
      Boolean impl;
    case (_,Absyn.EXTERNALDECL(output_ = NONE),_) then DAE.NOEXTARG();  /* impl */ 
    case (env,Absyn.EXTERNALDECL(funcName = n,lang = lang,output_ = SOME(cref),args = args),impl)
      equation 
        (exp,prop,acc) = Static.elabCref(env, cref, impl);
        extarg = instExtGetFargsSingle(env, exp, prop);
      then
        extarg;
    case (_,_,_)
      equation 
        //Debug.fprint("failtrace", "#-- inst_ext_rettype failed\n");
      then
        fail();
  end matchcontinue;
end instExtGetRettype;

protected function instEnumeration "function: instEnumeration
  author: PA
 
  This function takes an \'Ident\' and list of strings, and returns an 
  enumeration class.
"
  input SCode.Ident n;
  input list<String> l;
  output SCode.Class outClass;
  list<SCode.Element> comp;
algorithm 
  comp := makeEnumComponents(l);
  outClass := SCode.CLASS(n,false,false,SCode.R_ENUMERATION(),
          SCode.PARTS(comp,{},{},{},{},NONE));
end instEnumeration;

protected function makeEnumComponents "function: makeEnumComponents
  author: PA
 
  This function takes a list of strings and returns the elements of 
  type \'EnumType\' each corresponding to one of the enumeration values.
"
  input list<String> inStringLst;
  output list<SCode.Element> outSCodeElementLst;
algorithm 
  outSCodeElementLst:=
  matchcontinue (inStringLst)
    local
      String str;
      list<SCode.Element> els;
      list<String> x;
    case ({str}) then {
          SCode.COMPONENT(str,true,false,false,
          SCode.ATTR({},false,SCode.RO(),SCode.CONST(),Absyn.BIDIR()),Absyn.IDENT("EnumType"),SCode.NOMOD(),NONE,NONE)}; 
    case ((str :: (x as (_ :: _))))
      equation 
        els = makeEnumComponents(x);
      then
        (SCode.COMPONENT(str,true,false,false,
          SCode.ATTR({},false,SCode.RO(),SCode.CONST(),Absyn.BIDIR()),Absyn.IDENT("EnumType"),SCode.NOMOD(),NONE,NONE) :: els);
  end matchcontinue;
end makeEnumComponents;

protected function daeDeclare "function: daeDeclare
 
  Given a global component name, a type, and a set of attributes,
  this function declares a component for the DAE result.  Altough
  this function returns a list of `DAE.Element\'s, only one component
  is actually declared.
 
  The functions `dae_declare2\' and `dae_declare3\' below are helper
  functions that perform parts of the task.
"
  input Exp.ComponentRef inComponentRef;
  input ClassInf.State inState;
  input Types.Type inType;
  input SCode.Attributes inAttributes;
  input Option<Exp.Exp> inExpExpOption;
  input InstDims inInstDims;
  input DAE.StartValue inStartValue;
  input Option<DAE.VariableAttributes> inDAEVariableAttributesOption;
  input Option<Absyn.Comment> inAbsynCommentOption;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  outDAEElementLst:=
  matchcontinue (inComponentRef,inState,inType,inAttributes,inExpExpOption,inInstDims,inStartValue,inDAEVariableAttributesOption,inAbsynCommentOption)
    local
      DAE.Flow flow_1;
      list<DAE.Element> dae;
      Exp.ComponentRef vn;
      ClassInf.State ci_state;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Boolean flow_;
      SCode.Variability par;
      Absyn.Direction dir;
      Option<Exp.Exp> e,start;
      InstDims inst_dims;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
    case (vn,ci_state,ty,SCode.ATTR(flow_ = flow_,parameter_ = par,input_ = dir),e,inst_dims,start,dae_var_attr,comment)
      equation 
        flow_1 = DAE.toFlow(flow_, ci_state);
        dae = daeDeclare2(vn, ty, flow_1, par, dir, e, inst_dims, start, 
          dae_var_attr, comment);
      then
        dae;
    case (_,_,_,_,_,_,_,_,_)
      equation 
        print("dae_declare failed\n");
        //Debug.fprint("failtrace", "- dae_declare failed\n");
      then
        fail();
  end matchcontinue;
end daeDeclare;

protected function daeDeclare2 "function: daeDeclare2
  
  Helper function to dae_declare.
"
  input Exp.ComponentRef inComponentRef;
  input Types.Type inType;
  input DAE.Flow inFlow;
  input SCode.Variability inVariability;
  input Absyn.Direction inDirection;
  input Option<Exp.Exp> inExpExpOption;
  input InstDims inInstDims;
  input DAE.StartValue inStartValue;
  input Option<DAE.VariableAttributes> inDAEVariableAttributesOption;
  input Option<Absyn.Comment> inAbsynCommentOption;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  outDAEElementLst:=
  matchcontinue (inComponentRef,inType,inFlow,inVariability,inDirection,inExpExpOption,inInstDims,inStartValue,inDAEVariableAttributesOption,inAbsynCommentOption)
    local
      list<DAE.Element> dae;
      Exp.ComponentRef vn;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      DAE.Flow flow_;
      Absyn.Direction dir;
      Option<Exp.Exp> e,start;
      InstDims inst_dims;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
    case (vn,ty,flow_,SCode.VAR(),dir,e,inst_dims,start,dae_var_attr,comment)
      equation 
        dae = daeDeclare3(vn, ty, flow_, DAE.VARIABLE(), dir, e, inst_dims, start, 
          dae_var_attr, comment);
      then
        dae;
    case (vn,ty,flow_,SCode.DISCRETE(),dir,e,inst_dims,start,dae_var_attr,comment)
      equation 
        dae = daeDeclare3(vn, ty, flow_, DAE.DISCRETE(), dir, e, inst_dims, start, 
          dae_var_attr, comment);
      then
        dae;
    case (vn,ty,flow_,SCode.PARAM(),dir,e,inst_dims,start,dae_var_attr,comment)
      equation 
        dae = daeDeclare3(vn, ty, flow_, DAE.PARAM(), dir, e, inst_dims, start, 
          dae_var_attr, comment);
      then
        dae;
    case (vn,ty,flow_,SCode.CONST(),dir,e,inst_dims,start,dae_var_attr,comment)
      equation 
        dae = daeDeclare3(vn, ty, flow_, DAE.CONST(), dir, e, inst_dims, start, 
          dae_var_attr, comment);
      then
        dae;
    case (vn,ty,flow_,SCode.STRUCTPARAM(),dir,e,inst_dims,start,dae_var_attr,comment)
      equation 
        dae = daeDeclare3(vn, ty, flow_, DAE.PARAM(), dir, e, inst_dims, start, 
          dae_var_attr, comment);
      then
        dae;
    case (_,_,_,_,_,_,_,_,_,_)
      equation 
        //Debug.fprint("failtrace", "- dae_declare2 failed\n");
      then
        fail();
  end matchcontinue;
end daeDeclare2;

protected function daeDeclare3 "function: daeDeclare3
  
  Helper function to dae_declare2.
"
  input Exp.ComponentRef inComponentRef;
  input Types.Type inType;
  input DAE.Flow inFlow;
  input DAE.VarKind inVarKind;
  input Absyn.Direction inDirection;
  input Option<Exp.Exp> inExpExpOption;
  input InstDims inInstDims;
  input DAE.StartValue inStartValue;
  input Option<DAE.VariableAttributes> inDAEVariableAttributesOption;
  input Option<Absyn.Comment> inAbsynCommentOption;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  outDAEElementLst:=
  matchcontinue (inComponentRef,inType,inFlow,inVarKind,inDirection,inExpExpOption,inInstDims,inStartValue,inDAEVariableAttributesOption,inAbsynCommentOption)
    local
      list<DAE.Element> dae;
      Exp.ComponentRef vn;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      DAE.Flow fl;
      DAE.VarKind vk;
      Option<Exp.Exp> e,start;
      InstDims inst_dims;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
    case (vn,ty,fl,vk,Absyn.INPUT(),e,inst_dims,start,dae_var_attr,comment)
      equation 
        dae = daeDeclare4(vn, ty, fl, vk, DAE.INPUT(), e, inst_dims, start, 
          dae_var_attr, comment);
      then
        dae;
    case (vn,ty,fl,vk,Absyn.OUTPUT(),e,inst_dims,start,dae_var_attr,comment)
      equation 
        dae = daeDeclare4(vn, ty, fl, vk, DAE.OUTPUT(), e, inst_dims, start, 
          dae_var_attr, comment);
      then
        dae;
    case (vn,ty,fl,vk,Absyn.BIDIR(),e,inst_dims,start,dae_var_attr,comment)
      equation 
        dae = daeDeclare4(vn, ty, fl, vk, DAE.BIDIR(), e, inst_dims, start, 
          dae_var_attr, comment);
      then
        dae;
    case (_,_,_,_,_,_,_,_,_,_)
      equation 
        //Debug.fprint("failtrace", "#- dae_declare3 failed\n");
      then
        fail();
  end matchcontinue;
end daeDeclare3;

protected function daeDeclare4 "function: daeDeclare4
  
  Helper function to dae_declare3.
"
  input Exp.ComponentRef inComponentRef;
  input Types.Type inType;
  input DAE.Flow inFlow;
  input DAE.VarKind inVarKind;
  input DAE.VarDirection inVarDirection;
  input Option<Exp.Exp> inExpExpOption;
  input InstDims inInstDims;
  input DAE.StartValue inStartValue;
  input Option<DAE.VariableAttributes> inDAEVariableAttributesOption;
  input Option<Absyn.Comment> inAbsynCommentOption;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  outDAEElementLst:=
  matchcontinue (inComponentRef,inType,inFlow,inVarKind,inVarDirection,inExpExpOption,inInstDims,inStartValue,inDAEVariableAttributesOption,inAbsynCommentOption)
    local
      Exp.ComponentRef vn,c;
      DAE.Flow fl;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      Option<Exp.Exp> e,start;
      InstDims inst_dims;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      list<String> l;
      list<DAE.Element> dae;
      ClassInf.State ci;
      tuple<Types.TType, Option<Absyn.Path>> tp,ty;
      Integer dim;
      String s;
    case (vn,(Types.T_INTEGER(varLstInt = _),_),fl,kind,dir,e,inst_dims,start,dae_var_attr,comment) then {
          DAE.VAR(vn,kind,dir,DAE.INT(),e,inst_dims,start,fl,{},dae_var_attr,
          comment)}; 
    case (vn,(Types.T_REAL(varLstReal = _),_),fl,kind,dir,e,inst_dims,start,dae_var_attr,comment) then {
          DAE.VAR(vn,kind,dir,DAE.REAL(),e,inst_dims,start,fl,{},
          dae_var_attr,comment)}; 
    case (vn,(Types.T_BOOL(varLstBool = _),_),fl,kind,dir,e,inst_dims,start,dae_var_attr,comment) then {
          DAE.VAR(vn,kind,dir,DAE.BOOL(),e,inst_dims,start,fl,{},
          dae_var_attr,comment)}; 
    case (vn,(Types.T_STRING(varLstString = _),_),fl,kind,dir,e,inst_dims,start,dae_var_attr,comment) then {
          DAE.VAR(vn,kind,dir,DAE.STRING(),e,inst_dims,start,fl,{},
          dae_var_attr,comment)}; 
    case (vn,(Types.T_ENUM(),_),fl,kind,dir,e,inst_dims,start,dae_var_attr,comment) then {}; 

			/* We should not declare each enumeration value of an enumeration when instantiating,
  		e.g Myenum my !=> constant EnumType my.enum1,... {DAE.VAR(vn, kind, dir, DAE.ENUM, e, inst_dims)} 
  		instantiation of complex type extending from basic type */ 
    case (vn,(Types.T_ENUMERATION(names = l),_),fl,kind,dir,e,inst_dims,start,dae_var_attr,comment) 
      then {DAE.VAR(vn,kind,dir,DAE.ENUMERATION(l),e,inst_dims,start,fl,{}, dae_var_attr,comment)};  

          /* Complex type that is ExternalObject*/
     case (vn, (Types.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path)),_),fl,kind,dir,e,inst_dims,start,dae_var_attr,comment)    
       local Absyn.Path path;
       equation
          then {DAE.VAR(vn,kind,dir,DAE.EXT_OBJECT(path),e,inst_dims,start,fl,{}, dae_var_attr,comment)};
            
      /* instantiation of complex type extending from basic type */ 
    case (vn,(Types.T_COMPLEX(complexClassType = ci,complexVarLst = {},complexTypeOption = SOME(tp)),_),fl,kind,dir,e,inst_dims,start,dae_var_attr,comment) 
      equation
        dae = daeDeclare4(vn,tp,fl,kind,dir,e,inst_dims,start,dae_var_attr,comment);
        then dae;
		
		/* Array that extends basic type */          
    case (vn,(Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(dim)),arrayType = tp),_),fl,kind,dir,e,inst_dims,start,dae_var_attr,comment) 
      equation 
        dae = daeDeclare4(vn, tp, fl, kind, dir, e, inst_dims, start, dae_var_attr, 
          comment);
      then
        dae;
    case (vn,(Types.T_ARRAY(arrayDim = Types.DIM(integerOption = NONE),arrayType = tp),_),fl,kind,dir,e,inst_dims,start,dae_var_attr,comment)
      equation 
        s = Exp.printComponentRefStr(vn);
        Error.addMessage(Error.DIMENSION_NOT_KNOWN, {s});
      then
        fail();
    case (c,ty,_,_,_,_,_,_,_,_) then {}; 
  end matchcontinue;
end daeDeclare4;

protected function instEquation "function instEquation
  author: LS, ELN
 
  Instantiates an equation by calling inst_equation_common with Inital set 
  to NON_INITIAL. 
"
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.Equation inEquation;
  input Boolean inBoolean;
  output list<DAE.Element> outDAEElementLst;
  output Env outEnv;
  output Connect.Sets outSets;
  output ClassInf.State outState;
algorithm 
  (outDAEElementLst,outEnv,outSets,outState):=
  matchcontinue (inEnv,inMod,inPrefix,inSets,inState,inEquation,inBoolean)
    local
      list<Env.Frame> env_1,env;
      list<DAE.Element> dae;
      Connect.Sets csets_1,csets;
      ClassInf.State ci_state_1,ci_state;
      Types.Mod mods;
      Prefix.Prefix pre;
      SCode.EEquation eq;
      Option<Absyn.Path> bc;
      Boolean impl;
    case (env,mods,pre,csets,ci_state,SCode.EQUATION(eEquation = eq,baseclassname = bc),impl) /* impl */ 
      equation 
        env_1 = getDerivedEnv(env, bc) "Equation inherited from base class" ;
        (dae,_,csets_1,ci_state_1) = instEquationCommon(env_1, mods, pre, csets, ci_state, eq, NON_INITIAL(), impl);
      then
        (dae,env,csets_1,ci_state_1);
    case (_,_,_,_,_,_,impl)
      equation 
        //Debug.fprint("failtrace", "- inst_equation failed\n");
      then
        fail();
  end matchcontinue;
end instEquation;

protected function instEEquation "function: instEEquation
 
  Instantiation of EEquation, used in for loops and if-equations.
"
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.EEquation inEEquation;
  input Boolean inBoolean;
  output list<DAE.Element> outDAEElementLst;
  output Env outEnv;
  output Connect.Sets outSets;
  output ClassInf.State outState;
algorithm 
  (outDAEElementLst,outEnv,outSets,outState):=
  matchcontinue (inEnv,inMod,inPrefix,inSets,inState,inEEquation,inBoolean)
    local
      list<DAE.Element> dae;
      Connect.Sets csets_1,csets;
      ClassInf.State ci_state_1,ci_state;
      list<Env.Frame> env;
      Types.Mod mods;
      Prefix.Prefix pre;
      SCode.EEquation eq;
      Boolean impl;
    case (env,mods,pre,csets,ci_state,eq,impl) /* impl */ 
      equation 
        (dae,_,csets_1,ci_state_1) = instEquationCommon(env, mods, pre, csets, ci_state, eq, NON_INITIAL(), impl);
      then
        (dae,env,csets_1,ci_state_1);
  end matchcontinue;
end instEEquation;

protected function instInitialequation "function: instInitialequation
  author: LS, ELN
 
  Instantiates initial equation by calling inst_equation_common with Inital 
  set to INITIAL.
"
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.Equation inEquation;
  input Boolean inBoolean;
  output list<DAE.Element> outDAEElementLst;
  output Env outEnv;
  output Connect.Sets outSets;
  output ClassInf.State outState;
algorithm 
  (outDAEElementLst,outEnv,outSets,outState):=
  matchcontinue (inEnv,inMod,inPrefix,inSets,inState,inEquation,inBoolean)
    local
      list<Env.Frame> env_1,env;
      list<DAE.Element> dae;
      Connect.Sets csets_1,csets;
      ClassInf.State ci_state_1,ci_state;
      Types.Mod mods;
      Prefix.Prefix pre;
      SCode.EEquation eq;
      Option<Absyn.Path> bc;
      Boolean impl;
    case (env,mods,pre,csets,ci_state,SCode.EQUATION(eEquation = eq,baseclassname = bc),impl) /* impl */ 
      equation 
        env_1 = getDerivedEnv(env, bc) "Equation inherited from base class" ;
        (dae,_,csets_1,ci_state_1) = instEquationCommon(env_1, mods, pre, csets, ci_state, eq, INITIAL(), impl);
      then
        (dae,env,csets_1,ci_state_1);
    case (_,_,_,_,_,_,impl)
      equation 
        //Debug.fprint("failtrace", "- inst_initialequation failed\n");
      then
        fail();
  end matchcontinue;
end instInitialequation;

protected function instEInitialequation "function: instEInitialequation
 
  Instantiates initial EEquation used in for loops and if equations 
"
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.EEquation inEEquation;
  input Boolean inBoolean;
  output list<DAE.Element> outDAEElementLst;
  output Env outEnv;
  output Connect.Sets outSets;
  output ClassInf.State outState;
algorithm 
  (outDAEElementLst,outEnv,outSets,outState):=
  matchcontinue (inEnv,inMod,inPrefix,inSets,inState,inEEquation,inBoolean)
    local
      list<DAE.Element> dae;
      Connect.Sets csets_1,csets;
      ClassInf.State ci_state_1,ci_state;
      list<Env.Frame> env;
      Types.Mod mods;
      Prefix.Prefix pre;
      SCode.EEquation eq;
      Boolean impl;
    case (env,mods,pre,csets,ci_state,eq,impl) /* impl */ 
      equation 
        (dae,_,csets_1,ci_state_1) = instEquationCommon(env, mods, pre, csets, ci_state, eq, INITIAL(), impl);
      then
        (dae,env,csets_1,ci_state_1);
  end matchcontinue;
end instEInitialequation;

protected function instEquationCommon "function: instEquationCommon
 
  The DAE output of the translation contains equations which
  in most cases directly corresponds to equations in the source.
  Some of them are also generated from `connect\' clauses.
 
  This function takes an equation from the source and generates DAE
  equations and connection sets.
  
"
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.EEquation inEEquation;
  input Initial inInitial;
  input Boolean inBoolean;
  output list<DAE.Element> outDAEElementLst;
  output Env outEnv;
  output Connect.Sets outSets;
  output ClassInf.State outState;
algorithm 
  (outDAEElementLst,outEnv,outSets,outState):=
  matchcontinue (inEnv,inMod,inPrefix,inSets,inState,inEEquation,inInitial,inBoolean)
    local
      Connect.Sets csets_1,csets;
      list<DAE.Element> dae,dae1,dae2;
      ClassInf.State ci_state_1,ci_state,ci_state_2;
      list<Env.Frame> env,env_1,env_2;
      Types.Mod mods,mod;
      Prefix.Prefix pre;
      Absyn.ComponentRef c1,c2,cr;
      Initial initial_;
      Boolean impl,cond;
      String n,i,s;
      Absyn.Exp e2,e1,e,ee;
      Exp.Exp e1_1,e2_1,e1_2,e2_2,e_1,e_2;
      Types.Properties prop1,prop2;
      list<SCode.EEquation> b,tb,fb,el,eel;
      list<tuple<Absyn.Exp, list<SCode.EEquation>>> eex;
      tuple<Types.TType, Option<Absyn.Path>> id_t;
      Values.Value v;
      Exp.ComponentRef cr_1;
      SCode.EEquation eqn;
    case (env,mods,pre,csets,ci_state,SCode.EQ_CONNECT(componentRef1 = c1,componentRef2 = c2),initial_,impl) /* impl 
	  Handle connect statements
	 */ 
      equation 
        (csets_1,dae) = instConnect(csets, env, pre, c1, c2, impl);
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
      then
        (dae,env,csets_1,ci_state_1);
    case (env,mods,pre,csets,ci_state,SCode.EQ_EQUALS(exp1 = Absyn.CREF(componentReg = Absyn.CREF_IDENT(name = n,subscripts = {})),exp2 = e2),initial_,impl) /* The following rule handles shadowed (replaced) equations. If an equation has a simple name on the left-hand side, and that component has an equation modifier, this equation is discarded. */ 
      equation 
        (Types.VAR(_,_,_,_,Types.EQBOUND(_,_,_)),_,_,_) = Lookup.lookupIdentLocal(env, n);
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
      then
        ({},env,csets,ci_state_1);
    case (env,mods,pre,csets,ci_state,SCode.EQ_EQUALS(exp1 = e1,exp2 = e2),initial_,impl)
      local Option<Interactive.InteractiveSymbolTable> c1,c2;
      equation 
        (e1_1,prop1,c1) = Static.elabExp(env, e1, impl, NONE) "
	 Do static analysis and constant evaluation of expressions. 
	 Gives expression and properties 
	 (Type  bool | (Type  Const as (bool | Const list))).
	 For a function, it checks the funtion name. 
	 Also the function call\'s in parameters are type checked with
	 the functions definition\'s inparameters. This is done with
	 regard to the position of the input arguments.

	 Returns the output parameters from the function.
	" ;
        (e2_1,prop2,c2) = Static.elabExp(env, e2, impl, NONE);
        e1_2 = Prefix.prefixExp(env, e1_1, pre);
        e2_2 = Prefix.prefixExp(env, e2_1, pre);
        dae = instEqEquation(e1_2, prop1, e2_2, prop2, initial_, impl) "Check that the lefthandside and the righthandside get along." ;
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
      then
        (dae,env,csets,ci_state_1);
    case (env,mod,pre,csets,ci_state,SCode.EQ_IF(conditional = e,true_ = tb,false_ = fb),NON_INITIAL(),impl) /* `if\' statements
	 
	  If statements are instantiated by evaluating the
	  conditional expression, and selecting the branch that
	  should be used.
	 EQ_IF. When the condition is constant evaluate it and 
	  select the correct branch */ 
      equation 
        (e_1,Types.PROP((Types.T_BOOL(_),_),_),_) = Static.elabExp(env, e, impl, NONE);
        (Values.BOOL(cond),_) = Ceval.ceval(env, e_1, impl, NONE, NONE, Ceval.NO_MSG());
        b = select(cond, tb, fb);
        (dae,env_1,csets_1,ci_state_1) = instList(env, mod, pre, csets, ci_state, instEEquation, b, impl);
      then
        (dae,env_1,csets_1,ci_state_1);
    case (env,mod,pre,csets,ci_state,SCode.EQ_IF(conditional = e,true_ = tb,false_ = fb),INITIAL(),impl) /* initial EQ_IF. When the condition is constant evaluate it and 
	  select the correct branch */ 
      equation 
        (e_1,Types.PROP((Types.T_BOOL(_),_),_),_) = Static.elabExp(env, e, impl, NONE);
        (Values.BOOL(cond),_) = Ceval.ceval(env, e_1, impl, NONE, NONE, Ceval.NO_MSG());
        b = select(cond, tb, fb);
        (dae,env_1,csets_1,ci_state_1) = instList(env, mod, pre, csets, ci_state, instEInitialequation, b, 
          impl);
      then
        (dae,env_1,csets_1,ci_state_1);
    case (env,mod,pre,csets,ci_state,SCode.EQ_IF(conditional = e,true_ = tb,false_ = fb),NON_INITIAL(),impl) /* IF_EQUATION */ 
      equation 
        (e_1,Types.PROP((Types.T_BOOL(_),_),Types.C_VAR()),_) = Static.elabExp(env, e, impl, NONE);
        (dae1,env_1,_,ci_state_1) = instList(env, mod, pre, csets, ci_state, instEEquation, tb, impl);
        (dae2,env_2,_,ci_state_2) = instList(env_1, mod, pre, csets, ci_state, instEEquation, fb, impl) "There are no connections inside if-clauses." ;
      then
        ({DAE.IF_EQUATION(e_1,dae1,dae2)},env_1,csets,ci_state_1);
    case (env,mod,pre,csets,ci_state,SCode.EQ_IF(conditional = e,true_ = tb,false_ = fb),INITIAL(),impl) /* Initial IF_EQUATION */ 
      equation 
        (e_1,Types.PROP((Types.T_BOOL(_),_),Types.C_VAR()),_) = Static.elabExp(env, e, impl, NONE);
        (dae1,env_1,_,ci_state_1) = instList(env, mod, pre, csets, ci_state, instEInitialequation, tb, 
          impl);
        (dae2,env_2,_,ci_state_2) = instList(env_1, mod, pre, csets, ci_state, instEInitialequation, 
          fb, impl) "There are no connections inside if-clauses." ;
      then
        ({DAE.INITIAL_IF_EQUATION(e_1,dae1,dae2)},env_1,csets,ci_state_1);
    case (env,mod,pre,csets,ci_state,SCode.EQ_WHEN(exp = e,eEquationLst = el,tplAbsynExpEEquationLstLst = ((ee,eel) :: eex)),(initial_ as NON_INITIAL()),impl) /* `when equation\' statement, modelica 1.1 
	 
	  When statements are instantiated by evaluating the
	  conditional expression.
	 */ 
      local DAE.Element dae2;
      equation 
        (e_1,_,_) = Static.elabExp(env, e, impl, NONE);
        e_2 = Prefix.prefixExp(env, e_1, pre);
        (dae1,env_1,_,_) = instList(env, mod, pre, csets, ci_state, instEEquation, el, impl);
        ((dae2 :: _),env_2,_,ci_state_1) = instEquationCommon(env_1, mod, pre, csets, ci_state, 
          SCode.EQ_WHEN(ee,eel,eex), initial_, impl);
        ci_state_2 = instEquationCommonCiTrans(ci_state_1, initial_);
      then
        ({DAE.WHEN_EQUATION(e_2,dae1,SOME(dae2))},env_2,csets,ci_state_2);
    case (env,mod,pre,csets,ci_state,SCode.EQ_WHEN(exp = e,eEquationLst = el,tplAbsynExpEEquationLstLst = {}),(initial_ as NON_INITIAL()),impl)
      equation 
        (e_1,_,_) = Static.elabExp(env, e, impl, NONE);
        e_2 = Prefix.prefixExp(env, e_1, pre);
        (dae1,env_1,_,_) = instList(env, mod, pre, csets, ci_state, instEEquation, el, impl);
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
      then
        ({DAE.WHEN_EQUATION(e_2,dae1,NONE)},env_1,csets,ci_state_1);
    case (env,mod,pre,csets,ci_state,SCode.EQ_FOR(ident = i,exp = e,eEquationLst = el),initial_,impl) /* seems unnecessary to handle when equations that are initial `for\' loops
	 
	  The loop expression is evaluated to a constant array of
	  integers, and then the loop is unrolled.
	 
          FIXME: Why lookup after add_for_loop_scope ?
	 */ 
      equation 
        (e_1,Types.PROP((Types.T_ARRAY(Types.DIM(_),id_t),_),_),_) = Static.elabExp(env, e, impl, NONE) "//Debug.fprintln (\"insttr\", \"inst_equation_common_eqfor_1\") &" ;
        env_1 = addForLoopScope(env, i, id_t) "//Debug.fprintln (\"insti\", \"for expression elaborated\") &" ;
        (Types.ATTR(false,SCode.RW(),SCode.VAR(),_),(Types.T_INTEGER(_),_),Types.UNBOUND()) = Lookup.lookupVar(env_1, Exp.CREF_IDENT(i,{})) "	//Debug.fprintln (\"insti\", \"loop-variable added to scope\") &" ;
        (v,_) = Ceval.ceval(env, e_1, impl, NONE, NONE, Ceval.MSG()) "	//Debug.fprintln (\"insti\", \"loop variable looked up\") & FIXME: Check bounds" ;
        (dae,csets_1) = unroll(env_1, mod, pre, csets, ci_state, i, v, el, initial_, impl) "	//Debug.fprintln (\"insti\", \"for expression evaluated\") &" ;
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_) "	//Debug.fprintln (\"insti\", \"for expression unrolled\") & 	& //Debug.fprintln (\"insttr\", \"inst_equation_common_eqfor_1 succeeded\")" ;
      then
        (dae,env,csets_1,ci_state_1);
    case (env,mod,pre,csets,ci_state,SCode.EQ_FOR(ident = i,exp = e,eEquationLst = el),initial_,impl)
      equation 
        (Types.ATTR(false,SCode.RW(),SCode.VAR(),_),(Types.T_INTEGER(_),_),Types.UNBOUND()) = Lookup.lookupVar(env, Exp.CREF_IDENT(i,{})) "for loops with non-constant iteration bounds" ;
        (e_1,Types.PROP((Types.T_ARRAY(Types.DIM(_),(Types.T_INTEGER(_),_)),_),Types.C_VAR()),_) = Static.elabExp(env, e, impl, NONE);
        Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, 
          {"Non-constant iteration bounds","No suggestion"});
      then
        fail();
    case (env,mod,pre,csets,ci_state,SCode.EQ_ASSERT(exp = e1,condition = e2),initial_,impl)
      equation 
        (e1_1,Types.PROP((Types.T_BOOL(_),_),_),_) = Static.elabExp(env, e1, impl, NONE) "assert statement" ;
        (e2_1,Types.PROP((Types.T_STRING(_),_),_),_) = Static.elabExp(env, e2, impl, NONE);
      then
        ({
          DAE.ASSERT(Exp.CALL(Absyn.IDENT("assert"),{e1_1,e2_1},false,false))},env,csets,ci_state);
    case (env,mod,pre,csets,ci_state,SCode.EQ_REINIT(componentRef = cr,state = e2),initial_,impl)
      equation 
        (Exp.CREF(cr_1,_),_,_) = Static.elabCref(env, cr, impl) "reinit statement" ;
        (e2_1,_,_) = Static.elabExp(env, e2, impl, NONE);
      then
        ({DAE.REINIT(cr_1,e2_1)},env,csets,ci_state);
    case (_,_,_,_,_,eqn,_,impl)
      equation 
        //Debug.fprint("failtrace", "- inst_equation_common failed for eqn: ");
        s = SCode.equationStr(eqn);
        //Debug.fprint("failtrace", s);
        //Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end instEquationCommon;

protected function instEquationCommonCiTrans "function: instEquationCommonCiTrans
  
  updats The ClassInf state machine when an equation is instantiated.
"
  input ClassInf.State inState;
  input Initial inInitial;
  output ClassInf.State outState;
algorithm 
  outState:=
  matchcontinue (inState,inInitial)
    local ClassInf.State ci_state_1,ci_state;
    case (ci_state,NON_INITIAL())
      equation 
        ci_state_1 = ClassInf.trans(ci_state, ClassInf.FOUND_EQUATION());
      then
        ci_state_1;
    case (ci_state,INITIAL()) then ci_state; 
  end matchcontinue;
end instEquationCommonCiTrans;

protected function addForLoopScope "function: addForLoopScope
  author: HJ
 
  Adds a scope on the environment used in for loops.
  The name of the scope is for_scope_name, defined as a value.
"
  input Env env;
  input Ident i;
  input Types.Type typ;
  output Env env_2;
  list<Env.Frame> env_1,env_2;
algorithm 
  env_1 := Env.openScope(env, false, SOME(forScopeName));
  env_2 := Env.extendFrameV(env_1, 
          Types.VAR(i,Types.ATTR(false,SCode.RW(),SCode.VAR(),Absyn.BIDIR()),
          false,typ,Types.UNBOUND()), NONE, false, {}) "comp env" ;
end addForLoopScope;

protected function isParameter "function: isParameter
  author: LS
  
  Succeeds if a variable is a parameter.
"
  input Exp.ComponentRef cr;
  input Env env;
  Boolean fl;
  SCode.Accessibility acc;
  Absyn.Direction dir;
  tuple<Types.TType, Option<Absyn.Path>> ty;
  Types.Binding bnd;
algorithm 
  (Types.ATTR(fl,acc,SCode.PARAM(),dir),ty,bnd) := Lookup.lookupVar(env, cr) "Env.print_env env &" ;
end isParameter;

protected function instEqEquation "function: instEqEquation
  author: LS, ELN
 
  Equations follow the same typing rules as equality expressions.
  This function adds the equation to the DAE.
 
"
  input Exp.Exp inExp1;
  input Types.Properties inProperties2;
  input Exp.Exp inExp3;
  input Types.Properties inProperties4;
  input Initial inInitial5;
  input Boolean inBoolean6;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  outDAEElementLst:=
  matchcontinue (inExp1,inProperties2,inExp3,inProperties4,inInitial5,inBoolean6)
    local
      Exp.Exp e1_1,e1,e2,e2_1;
      tuple<Types.TType, Option<Absyn.Path>> t_1,t1,t2,t;
      list<DAE.Element> dae;
      Types.Properties p1,p2;
      Initial initial_;
      Boolean impl;
      String e1_str,t1_str,e2_str,t2_str,s1,s2;
    case (e1,(p1 as Types.PROP(type_ = t1)),e2,(p2 as Types.PROP(type_ = t2)),initial_,impl) /* impl PR. e1= lefthandside, e2=righthandside
	 This seem to be a strange function. 
	 wich rule is matched? or is both rules matched?
	 LS: Static.type_convert in Static.match_prop can probably fail,
	  then the first rule will not match. Question if whether the second
	  rule can match in that case.
	 This rule is matched first, if it fail the next rule is matched.
	 If it fails then this rule is matched. */ 
      equation 
        (e1_1,Types.PROP(t_1,_)) = Types.matchProp(e1, p1, p2) "Debug.print(\"\\ninst_eq_equation (match e1) PROP, PROP\") &" ;
        dae = instEqEquation2(e1_1, e2, t_1, initial_);
      then
        dae;
    case (e1,(p1 as Types.PROP(type_ = t1)),e2,(p2 as Types.PROP(type_ = t2)),initial_,impl) /* If it fails then this rule is matched. */ 
      equation 
        (e2_1,Types.PROP(t_1,_)) = Types.matchProp(e2, p2, p1) "Debug.print(\"\\ninst_eq_equation (match e2) PROP, PROP\") &" ;
        dae = instEqEquation2(e1, e2_1, t_1, initial_) "	Debug.print(\"\\n Second rule of function_ inst_eq_equation \") & 	& Debug.print(\"\\n Second rule complete. \")" ;
      then
        dae;
    case (e1,(p1 as Types.PROP_TUPLE(type_ = t1)),e2,(p2 as Types.PROP_TUPLE(type_ = t2)),initial_,impl) /* PR. */ 
      equation 
        (e1_1,Types.PROP_TUPLE(t_1,_)) = Types.matchProp(e1, p1, p2) "Debug.print(\"\\ninst_eq_equation(e1) PROP_TUPLE, PROP_TUPLE\") & Exp.print_exp (e1) &" ;
        dae = instEqEquation2(e1_1, e2, t_1, initial_) "Exp.print_exp (e1\') &" ;
      then
        dae;
    case (e1,(p1 as Types.PROP_TUPLE(type_ = t1)),e2,(p2 as Types.PROP_TUPLE(type_ = t2)),initial_,impl) /* PR. 
	    An assignment to a varaible of T_ENUMERATION type is an explicit 
	    assignment to the value componnent of the enumeration, i.e. having 
	    a type T_ENUM
	 */ 
      equation 
        (e2_1,Types.PROP_TUPLE(t_1,_)) = Types.matchProp(e2, p2, p1) "Debug.print(\"\\ninst_eq_equation(e2) PROP_TUPLE, PROP_TUPLE\") &
	Debug.print \"\\n About to do a static match e2. \" &" ;
        dae = instEqEquation2(e1, e2_1, t_1, initial_) "	Debug.print(\"\\n Second rule of function_ inst_eq_equation \") & 	& Debug.print(\"\\n Second rule complete. \")" ;
      then
        dae;
    case ((e1 as Exp.CREF(componentRef = _)),Types.PROP(type_ = (Types.T_ENUMERATION(names = _),_)),e2,Types.PROP(type_ = (t as (Types.T_ENUM(),_))),initial_,impl) /* 
	    An assignment to a varaible of T_ENUMERATION type is an explicit 
	    assignment to the value componnent of the enumeration, i.e. having 
	    a type T_ENUM
	 */ 
      equation 
        dae = instEqEquation2(e1, e2, t, initial_) "//Debug.fprint (\"insttr\", \"Found assignment to T_ENUMERATION type. Rhs type must be T_ENUM or T_ENUMERATION.\\n\") &" ;
      then
        dae;
    case ((e1 as Exp.CREF(componentRef = _)),Types.PROP(type_ = (Types.T_ENUMERATION(names = _),_)),e2,Types.PROP(type_ = (t as (Types.T_ENUMERATION(names = _),_))),initial_,impl)
      equation 
        dae = instEqEquation2(e1, e2, t, initial_) "//Debug.fprint (\"insttr\", \"Found assignment to T_ENUMERATION type. Rhs type must be T_ENUM or T_ENUMERATION.\\n\") &" ;
      then
        dae;
    case (e1,Types.PROP(type_ = t1),e2,Types.PROP(type_ = t2),initial_,impl)
      equation 
        e1_str = Exp.printExpStr(e1) "Types.equivtypes(t1,t2) => false &" ;
        t1_str = Types.unparseType(t1);
        e2_str = Exp.printExpStr(e2);
        t2_str = Types.unparseType(t2);
        s1 = Util.stringAppendList({e1_str,"=",e2_str});
        s2 = Util.stringAppendList({t1_str,"=",t2_str});
        Error.addMessage(Error.EQUATION_TYPE_MISMATCH_ERROR, {s1,s2});
      then
        fail();
  end matchcontinue;
end instEqEquation;

protected function instEqEquation2 "function: instEqEquation2
  author: LS, ELN
 
  This is the second stage of `inst_eq_equation\', when the types are
  checked.
"
  input Exp.Exp inExp1;
  input Exp.Exp inExp2;
  input Types.Type inType3;
  input Initial inInitial4;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  outDAEElementLst:=
  matchcontinue (inExp1,inExp2,inType3,inInitial4)
    local
      DAE.Element dae;
      Exp.Exp e1,e2;
      Initial initial_;
      Exp.ComponentRef cr,c1_1,c2_1,c1,c2;
      Exp.Type t,t1,t2,tp;
      list<Integer> ds;
      tuple<Types.TType, Option<Absyn.Path>> bc;
      list<DAE.Element> dae1,dae2,decl;
      Types.ArrayDim ad;
      ClassInf.State cs;
      String n;
      list<Types.Var> vs;
      Option<Absyn.Path> p;
    case (e1,e2,(Types.T_INTEGER(varLstInt = _),_),initial_)
      equation 
        dae = makeDaeEquation(e1, e2, initial_);
      then
        {dae};
    case (e1,e2,(Types.T_REAL(varLstReal = _),_),initial_)
      equation 
        dae = makeDaeEquation(e1, e2, initial_);
      then
        {dae};
    case (e1,e2,(Types.T_STRING(varLstString = _),_),initial_)
      equation 
        dae = makeDaeEquation(e1, e2, initial_);
      then
        {dae};
    case (e1,e2,(Types.T_BOOL(varLstBool = _),_),initial_)
      equation 
        dae = makeDaeEquation(e1, e2, initial_);
      then
        {dae};
    case (Exp.CREF(componentRef = cr,ty = t),e2,(Types.T_ENUM(),_),initial_)
      equation 
        dae = makeDaeDefine(cr, e2, initial_);
      then
        {dae};
    case (Exp.CREF(componentRef = cr,ty = t),e2,(Types.T_ENUMERATION(names = _),_),initial_)
      equation 
        dae = makeDaeDefine(cr, e2, initial_);
      then
        {dae};
    case (e1,(e2 as Exp.CALL(path = _)),(t as (Types.T_ARRAY(arrayDim = _),_)),initial_) /* arrays with function calls => array equations */ 
      local tuple<Types.TType, Option<Absyn.Path>> t;
      equation 
        ds = Types.getDimensionSizes(t);
      then
        {DAE.ARRAY_EQUATION(ds,e1,e2)};
    case ((e1 as Exp.CALL(path = _)),e2,(t as (Types.T_ARRAY(arrayDim = _),_)),initial_) /* arrays with function calls => array equations */ 
      local tuple<Types.TType, Option<Absyn.Path>> t;
      equation 
        ds = Types.getDimensionSizes(t);
      then
        {DAE.ARRAY_EQUATION(ds,e1,e2)};
    case (e1,e2,(Types.T_ARRAY(arrayDim = ad,arrayType = t),_),initial_) /* arrays that are splitted */ 
      local
        list<DAE.Element> dae;
        tuple<Types.TType, Option<Absyn.Path>> t;
      equation 
        dae = instArrayEquation(e1, e2, ad, t, initial_);
      then
        dae;
    case (e1,e2,(Types.T_TUPLE(tupleType = _),_),initial_) /* tuples */ 
      equation 
        dae = makeDaeEquation(e1, e2, initial_);
      then
        {dae};
    case (e1,e2,(Types.T_COMPLEX(complexVarLst = {},complexTypeOption = SOME(bc)),_),initial_) /* Complex types extending basic type */ 
      local list<DAE.Element> dae;
      equation 
        dae = instEqEquation2(e1, e2, bc, initial_);
      then
        dae;
    case (e1,e2,(Types.T_COMPLEX(complexVarLst = {}),_),initial_) then {}; 
    case (Exp.CREF(componentRef = c1,ty = t1),Exp.CREF(componentRef = c2,ty = t2),(Types.T_COMPLEX(complexClassType = cs,complexVarLst = (Types.VAR(name = n,type_ = t) :: vs),complexTypeOption = bc),p),initial_)
      local
        list<DAE.Element> dae;
        tuple<Types.TType, Option<Absyn.Path>> t;
        Option<tuple<Types.TType, Option<Absyn.Path>>> bc;
      equation 
        c1_1 = Exp.extendCref(c1, n, {});
        c2_1 = Exp.extendCref(c2, n, {});
        dae1 = instEqEquation2(Exp.CREF(c1_1,t1), Exp.CREF(c2_1,t2), t, initial_);
        dae2 = instEqEquation2(Exp.CREF(c1,t1), Exp.CREF(c2,t2), 
          (Types.T_COMPLEX(cs,vs,bc),p), initial_);
        dae = listAppend(dae1, dae2);
      then
        dae;
    case (e1,(e2 as Exp.CREF(componentRef = _)),(t as (Types.T_COMPLEX(complexClassType = _),_)),initial_) /* When the type of the expressions is a complex type, and the left-hand side of the equation is not a component reference, a new variable is introduced to be able to dereference components of the expression.  This is rather ugly, since it doesn\'t really solve the problem of describing the semantics.  Now the semantics of composite equations are defined in terms of other composite equations.  To make this a little cleaner, the equation that equates the new name to the expression is stored using DAE.DEFINE rather than DAE.EQUATION.  This makes it a little clearer. */ 
      local
        Exp.ComponentRef n;
        list<DAE.Element> dae;
        tuple<Types.TType, Option<Absyn.Path>> t;
      equation 
        n = newIdent();
        decl = daeDeclare(n, ClassInf.UNKNOWN(""), t, 
          SCode.ATTR({},false,SCode.RW(),SCode.VAR(),Absyn.BIDIR()), NONE, {}, NONE, NONE, NONE);
        tp = Exp.typeof(e2);
        dae1 = instEqEquation2(Exp.CREF(n,tp), e2, t, initial_);
        dae = listAppend(decl, (DAE.DEFINE(n,e1) :: dae1));
      then
        dae;
    case (e1,e2,(t as (Types.T_COMPLEX(complexClassType = _),_)),initial_) /* When the right-hand side is not a component reference a similar trick is applied.  This also catched the case where none of the sides is a component reference */ 
      local
        Exp.ComponentRef n;
        list<DAE.Element> dae;
        tuple<Types.TType, Option<Absyn.Path>> t;
      equation 
        n = newIdent();
        decl = daeDeclare(n, ClassInf.UNKNOWN(""), t, 
          SCode.ATTR({},false,SCode.RW(),SCode.VAR(),Absyn.BIDIR()), NONE, {}, NONE, NONE, NONE);
        tp = Exp.typeof(e2);
        dae1 = instEqEquation2(e1, Exp.CREF(n,tp), t, initial_);
        dae = listAppend(decl, (DAE.DEFINE(n,e2) :: dae1));
      then
        dae;
    case (e1,e2,t,initial_)
      local tuple<Types.TType, Option<Absyn.Path>> t;
      equation 
        //Debug.fprint("failtrace", "- inst_eq_equation_2 failed\n exp1=");
        Debug.fcall("failtrace", Exp.printExp, e1);
        //Debug.fprint("failtrace", " exp2=");
        Debug.fcall("failtrace", Exp.printExp, e2);
        //Debug.fprint("failtrace", " type =");
        Debug.fcall("failtrace", Types.printType, t);
        //Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end instEqEquation2;

protected function makeDaeEquation "function: makeDaeEquation
  author: LS, ELN 
 
  Constructs an equation in the DAE, they can be either an initial equation 
  or an ordinary equation.
"
  input Exp.Exp inExp1;
  input Exp.Exp inExp2;
  input Initial inInitial3;
  output DAE.Element outElement;
algorithm 
  outElement:=
  matchcontinue (inExp1,inExp2,inInitial3)
    local Exp.Exp e1,e2;
    case (e1,e2,NON_INITIAL()) then DAE.EQUATION(e1,e2); 
    case (e1,e2,INITIAL()) then DAE.INITIALEQUATION(e1,e2); 
  end matchcontinue;
end makeDaeEquation;

protected function makeDaeDefine "function: makeDaeDefine
  author: LS, ELN 
 
"
  input Exp.ComponentRef inComponentRef;
  input Exp.Exp inExp;
  input Initial inInitial;
  output DAE.Element outElement;
algorithm 
  outElement:=
  matchcontinue (inComponentRef,inExp,inInitial)
    local
      Exp.ComponentRef cr;
      Exp.Exp e2;
    case (cr,e2,NON_INITIAL()) then DAE.DEFINE(cr,e2); 
    case (cr,e2,INITIAL()) then DAE.INITIALDEFINE(cr,e2); 
  end matchcontinue;
end makeDaeDefine;

protected function instArrayEquation "function: instArrayEquation
 
  This checks the array size and creates an array equation in DAE.
"
  input Exp.Exp inExp1;
  input Exp.Exp inExp2;
  input Types.ArrayDim inArrayDim3;
  input Types.Type inType4;
  input Initial inInitial5;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  outDAEElementLst:=
  matchcontinue (inExp1,inExp2,inArrayDim3,inType4,inInitial5)
    local
      String e1_str,e2_str,s1;
      Exp.Exp e1,e2;
      tuple<Types.TType, Option<Absyn.Path>> t;
      Initial initial_;
      list<DAE.Element> dae;
      Integer sz;
    case (e1,e2,Types.DIM(integerOption = NONE),t,initial_) /* array elt type */ 
      equation 
        e1_str = Exp.printExpStr(e1);
        e2_str = Exp.printExpStr(e1);
        s1 = Util.stringAppendList({e1_str,"=",e2_str});
        Error.addMessage(Error.INST_ARRAY_EQ_UNKNOWN_SIZE, {s1});
      then
        fail();
    case (e1,e2,Types.DIM(integerOption = SOME(sz)),t,initial_)
      equation 
        dae = instArrayElEq(e1, e2, t, 1, sz, initial_);
      then
        dae;
    case (_,_,_,_,_)
      equation 
        //Debug.fprint("failtrace", "- inst_array_equation failed\n");
      then
        fail();
  end matchcontinue;
end instArrayEquation;

protected function instArrayElEq "function: instArrayElEq
 
  This function loops recursively through all indexes in the two
  arrays and generates an equation for each pair of elements.
"
  input Exp.Exp inExp1;
  input Exp.Exp inExp2;
  input Types.Type inType3;
  input Integer inInteger4;
  input Integer inInteger5;
  input Initial inInitial6;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  outDAEElementLst:=
  matchcontinue (inExp1,inExp2,inType3,inInteger4,inInteger5,inInitial6)
    local
      Exp.Exp e1_1,e2_1,e1,e2;
      list<DAE.Element> dae1,dae2,dae;
      Integer i_1,i,sz;
      tuple<Types.TType, Option<Absyn.Path>> t;
      Initial initial_;
    case (e1,e2,t,i,sz,initial_) /* lhs rhs elt type iterator dim size */ 
      equation 
        (i <= sz) = true;
        e1_1 = Exp.simplify(Exp.ASUB(e1,i));
        e2_1 = Exp.simplify(Exp.ASUB(e2,i));
        dae1 = instEqEquation2(e1_1, e2_1, t, initial_);
        i_1 = i + 1;
        dae2 = instArrayElEq(e1, e2, t, i_1, sz, initial_);
        dae = listAppend(dae1, dae2);
      then
        dae;
    case (e1,e2,t,i,sz,initial_)
      equation 
        (i <= sz) = false;
      then
        {};
    case (_,_,_,_,_,_)
      equation 
        //Debug.fprint("failtrace", "- inst_array_el_eq failed\n");
      then
        fail();
  end matchcontinue;
end instArrayElEq;

protected function unroll "function: unroll
 
  Unrolling a loop is a way of removing the non-linear structure of
  the `for\' clause by explicitly repeating the body of the loop once
  for each iteration.
"
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input Ident inIdent;
  input Values.Value inValue;
  input list<SCode.EEquation> inSCodeEEquationLst;
  input Initial inInitial;
  input Boolean inBoolean;
  output list<DAE.Element> outDAEElementLst;
  output Connect.Sets outSets;
algorithm 
  (outDAEElementLst,outSets):=
  matchcontinue (inEnv,inMod,inPrefix,inSets,inState,inIdent,inValue,inSCodeEEquationLst,inInitial,inBoolean)
    local
      Connect.Sets csets,csets_1,csets_2;
      list<Env.Frame> env_1,env_2,env_3,env;
      list<DAE.Element> dae1,dae2,dae;
      ClassInf.State ci_state_1,ci_state;
      Types.Mod mods;
      Prefix.Prefix pre;
      String i;
      Values.Value fst,v;
      list<Values.Value> rest;
      list<SCode.EEquation> eqs;
      Initial initial_;
      Boolean impl;
    case (_,_,_,csets,_,_,Values.ARRAY(valueLst = {}),_,_,_) then ({},csets);  /* impl */ 
    case (env,mods,pre,csets,ci_state,i,Values.ARRAY(valueLst = (fst :: rest)),eqs,(initial_ as NON_INITIAL()),impl)
      equation 
        env_1 = Env.openScope(env, false, SOME(forScopeName));
        env_2 = Env.extendFrameV(env_1, 
          Types.VAR(i,Types.ATTR(false,SCode.RO(),SCode.CONST(),Absyn.BIDIR()),
          true,(Types.T_INTEGER({}),NONE),Types.VALBOUND(fst)), NONE, false, {}) "comp env" ;
        (dae1,env_3,csets_1,ci_state_1) = instList(env_2, mods, pre, csets, ci_state, instEEquation, eqs, impl);
        (dae2,csets_2) = unroll(env, mods, pre, csets_1, ci_state_1, i, 
          Values.ARRAY(rest), eqs, initial_, impl);
        dae = listAppend(dae1, dae2);
      then
        (dae,csets_2);
    case (env,mods,pre,csets,ci_state,i,Values.ARRAY(valueLst = (fst :: rest)),eqs,(initial_ as INITIAL()),impl)
      equation 
        env_1 = Env.openScope(env, false, SOME(forScopeName));
        env_2 = Env.extendFrameV(env_1, 
          Types.VAR(i,Types.ATTR(false,SCode.RO(),SCode.CONST(),Absyn.BIDIR()),
          true,(Types.T_INTEGER({}),NONE),Types.VALBOUND(fst)), NONE, false, {}) "comp env" ;
        (dae1,env_3,csets_1,ci_state_1) = instList(env_2, mods, pre, csets, ci_state, instEInitialequation, 
          eqs, impl);
        (dae2,csets_2) = unroll(env, mods, pre, csets_1, ci_state_1, i, 
          Values.ARRAY(rest), eqs, initial_, impl);
        dae = listAppend(dae1, dae2);
      then
        (dae,csets_2);
    case (_,_,_,_,_,_,v,_,_,_)
      equation 
        //Debug.fprint("failtrace", "- unroll ");
        Debug.fcall("failtrace", Values.printVal, v);
        //Debug.fprint("failtrace", " failed\n");
      then
        fail();
  end matchcontinue;
end unroll;

protected function instAlgorithm "function: instAlgorithm
 
  Algorithms are converted to the representation defined in the
  module `Algorithm\', and the added to the DAE result.
 
  This function converts an algorithm section.
"
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.Algorithm inAlgorithm;
  input Boolean inBoolean;
  output list<DAE.Element> outDAEElementLst;
  output Env outEnv;
  output Connect.Sets outSets;
  output ClassInf.State outState;
algorithm 
  (outDAEElementLst,outEnv,outSets,outState):=
  matchcontinue (inEnv,inMod,inPrefix,inSets,inState,inAlgorithm,inBoolean)
    local
      list<Env.Frame> env_1,env;
      list<Algorithm.Statement> statements_1;
      Connect.Sets csets;
      ClassInf.State ci_state;
      list<Absyn.Algorithm> statements;
      Option<Absyn.Path> bc;
      Boolean impl;
    case (env,_,_,csets,ci_state,SCode.ALGORITHM(absynAlgorithmLst = statements,baseclass = bc),impl) /* impl */ 
      equation 
        env_1 = getDerivedEnv(env, bc) "If algorithm is inherited, find base class environment" ;
        statements_1 = instStatements(env_1, statements, impl);
      then
        ({DAE.ALGORITHM(Algorithm.ALGORITHM(statements_1))},env,csets,ci_state);
    case (_,_,_,_,_,_,_)
      equation 
        //Debug.fprint("failtrace", "- inst_algorithm failed\n");
      then
        fail();
  end matchcontinue;
end instAlgorithm;

protected function instInitialalgorithm "function: instInitialalgorithm
 
  Algorithms are converted to the representation defined in the
  module `Algorithm\', and the added to the DAE result.
 
  This function converts an algorithm section.
"
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.Algorithm inAlgorithm;
  input Boolean inBoolean;
  output list<DAE.Element> outDAEElementLst;
  output Env outEnv;
  output Connect.Sets outSets;
  output ClassInf.State outState;
algorithm 
  (outDAEElementLst,outEnv,outSets,outState):=
  matchcontinue (inEnv,inMod,inPrefix,inSets,inState,inAlgorithm,inBoolean)
    local
      list<Env.Frame> env_1,env;
      list<Algorithm.Statement> statements_1;
      Connect.Sets csets;
      ClassInf.State ci_state;
      list<Absyn.Algorithm> statements;
      Option<Absyn.Path> bc;
      Boolean impl;
    case (env,_,_,csets,ci_state,SCode.ALGORITHM(absynAlgorithmLst = statements,baseclass = bc),impl) /* impl */ 
      equation 
        env_1 = getDerivedEnv(env, bc);
        statements_1 = instStatements(env, statements, impl);
      then
        ({DAE.INITIALALGORITHM(Algorithm.ALGORITHM(statements_1))},env,csets,ci_state);
    case (_,_,_,_,_,_,_)
      equation 
        //Debug.fprint("failtrace", "- inst_algorithm failed\n");
      then
        fail();
  end matchcontinue;
end instInitialalgorithm;

protected function instStatements "function: instStatements
 
  This function converts a list of algorithm statements.
"
  input Env inEnv;
  input list<Absyn.Algorithm> inAbsynAlgorithmLst;
  input Boolean inBoolean;
  output list<Algorithm.Statement> outAlgorithmStatementLst;
algorithm 
  outAlgorithmStatementLst:=
  matchcontinue (inEnv,inAbsynAlgorithmLst,inBoolean)
    local
      list<Env.Frame> env;
      Boolean impl;
      Algorithm.Statement x_1;
      list<Algorithm.Statement> xs_1;
      Absyn.Algorithm x;
      list<Absyn.Algorithm> xs;
    case (env,{},impl) then {};  /* impl */ 
    case (env,(x :: xs),impl)
      equation 
        x_1 = instStatement(env, x, impl);
        xs_1 = instStatements(env, xs, impl);
      then
        (x_1 :: xs_1);
  end matchcontinue;
end instStatements;

protected function instAlgorithmitems "function: instAlgorithmitems
 
  Helper function to inst_statement.
"
  input Env inEnv;
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  input Boolean inBoolean;
  output list<Algorithm.Statement> outAlgorithmStatementLst;
algorithm 
  outAlgorithmStatementLst:=
  matchcontinue (inEnv,inAbsynAlgorithmItemLst,inBoolean)
    local
      list<Env.Frame> env;
      Boolean impl;
      Algorithm.Statement x_1;
      list<Algorithm.Statement> xs_1;
      Absyn.Algorithm x;
      list<Absyn.AlgorithmItem> xs;
    case (env,{},impl) then {};  /* impl */ 
    case (env,(Absyn.ALGORITHMITEM(algorithm_ = x) :: xs),impl)
      equation 
        x_1 = instStatement(env, x, impl);
        xs_1 = instAlgorithmitems(env, xs, impl);
      then
        (x_1 :: xs_1);
    case (env,(Absyn.ALGORITHMITEMANN(annotation_ = _) :: xs),impl)
      equation 
        xs_1 = instAlgorithmitems(env, xs, impl);
      then
        xs_1;
  end matchcontinue;
end instAlgorithmitems;

protected function instStatement "function: instStatement
 
  This function Looks at an algorithm statement and uses functions
  in the `Algorithm\' module to build a representation of it that can
  be used in the DAE output.
"
  input Env inEnv;
  input Absyn.Algorithm inAlgorithm;
  input Boolean inBoolean;
  output Algorithm.Statement outStatement;
algorithm 
  outStatement:=
  matchcontinue (inEnv,inAlgorithm,inBoolean)
    local
      Exp.ComponentRef ce,ce_1;
      Exp.Type t;
      Types.Properties cprop,eprop,prop,msgprop;
      SCode.Accessibility acc;
      Exp.Exp e_1,cond_1,msg_1;
      Algorithm.Statement stmt;
      list<Env.Frame> env,env_1;
      Absyn.ComponentRef cr;
      Absyn.Exp e,cond,msg;
      Boolean impl;
      list<Exp.Exp> expl_1;
      list<Types.Properties> cprops;
      list<Absyn.Exp> expl;
      String s,i;
      list<Algorithm.Statement> tb_1,fb_1,sl_1;
      list<tuple<Exp.Exp, Types.Properties, list<Algorithm.Statement>>> eib_1;
      list<Absyn.AlgorithmItem> tb,fb,sl;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> eib,el;
      Absyn.Algorithm alg;
    case (env,Absyn.ALG_ASSIGN(assignComponent = cr,value = e),impl) /* impl */ 
      equation 
        (Exp.CREF(ce,t),cprop,acc) = Static.elabCref(env, cr, impl);
        ce_1 = Static.canonCref(env, ce, impl);
        (e_1,eprop,_) = Static.elabExp(env, e, impl, NONE);
        stmt = Algorithm.makeAssignment(Exp.CREF(ce_1,t), cprop, e_1, eprop, acc);
      then
        stmt;
    case (env,Absyn.ALG_ASSIGN(assignComponent = cr,value = e),impl)
      local Exp.Exp ce;
      equation 
        (ce,cprop,acc) = Static.elabCref(env, cr, impl);
        (e_1,eprop,_) = Static.elabExp(env, e, impl, NONE);
        stmt = Algorithm.makeAssignment(ce, cprop, e_1, eprop, acc);
      then
        stmt;
    case (env,Absyn.ALG_TUPLE_ASSIGN(tuple_ = Absyn.TUPLE(expressions = expl),value = e),impl)
      equation 
        ((e_1 as Exp.CALL(_,_,_,_)),eprop,_) = Static.elabExp(env, e, impl, NONE);
        (expl_1,cprops,_) = Static.elabExpList(env, expl, impl, NONE);
        stmt = Algorithm.makeTupleAssignment(expl_1, cprops, e_1, eprop);
      then
        stmt;
    case (env,Absyn.ALG_TUPLE_ASSIGN(tuple_ = Absyn.TUPLE(expressions = expl),value = e),impl)
      equation 
        s = Dump.printExpStr(e);
        Error.addMessage(Error.TUPLE_ASSIGN_FUNCALL_ONLY, {s});
      then
        fail();
    case (env,Absyn.ALG_IF(ifExp = e,trueBranch = tb,elseIfAlgorithmBranch = eib,elseBranch = fb),impl)
      equation 
        (e_1,prop,_) = Static.elabExp(env, e, impl, NONE);
        tb_1 = instAlgorithmitems(env, tb, impl);
        eib_1 = instElseifs(env, eib, impl);
        fb_1 = instAlgorithmitems(env, fb, impl);
        stmt = Algorithm.makeIf(e_1, prop, tb_1, eib_1, fb_1);
      then
        stmt;
    case (env,Absyn.ALG_FOR(forVariable = i,forStmt = e,forBody = sl),impl)
      local tuple<Types.TType, Option<Absyn.Path>> t;
      equation 
        (e_1,(prop as Types.PROP((Types.T_ARRAY(_,t),_),_)),_) = Static.elabExp(env, e, impl, NONE);
        env_1 = addForLoopScope(env, i, t);
        sl_1 = instAlgorithmitems(env_1, sl, impl);
        stmt = Algorithm.makeFor(i, e_1, prop, sl_1);
      then
        stmt;
    case (env,Absyn.ALG_WHILE(whileStmt = e,whileBody = sl),impl)
      equation 
        (e_1,prop,_) = Static.elabExp(env, e, impl, NONE);
        sl_1 = instAlgorithmitems(env, sl, impl);
        stmt = Algorithm.makeWhile(e_1, prop, sl_1);
      then
        stmt;
    case (env,Absyn.ALG_WHEN_A(whenStmt = e,whenBody = sl,elseWhenAlgorithmBranch = el),impl)
      equation 
        (e_1,prop,_) = Static.elabExp(env, e, impl, NONE);
        sl_1 = instAlgorithmitems(env, sl, impl);
        stmt = Algorithm.makeWhenA(e_1, prop, sl_1) "TODO elsewhen" ;
      then
        stmt;
    case (env,Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "assert"),functionArgs = Absyn.FUNCTIONARGS(args = {cond,msg},argNames = {})),impl)
      equation 
        (cond_1,cprop,_) = Static.elabExp(env, cond, impl, NONE);
        (msg_1,msgprop,_) = Static.elabExp(env, msg, impl, NONE);
        stmt = Algorithm.makeAssert(cond_1, msg_1, cprop, msgprop);
      then
        stmt;
    case (env,alg,impl)
      equation 
        //Debug.fprint("failtrace", "- inst_statement failed\n alg:");
        Debug.fcall("failtrace", Dump.printAlgorithm, alg);
        //Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end instStatement;

protected function instElseifs "function: instElseifs
 
  This function helps `inst_statement\' to handle `elseif\' parts.
"
  input Env inEnv;
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inTplAbsynExpAbsynAlgorithmItemLstLst;
  input Boolean inBoolean;
  output list<tuple<Exp.Exp, Types.Properties, list<Algorithm.Statement>>> outTplExpExpTypesPropertiesAlgorithmStatementLstLst;
algorithm 
  outTplExpExpTypesPropertiesAlgorithmStatementLstLst:=
  matchcontinue (inEnv,inTplAbsynExpAbsynAlgorithmItemLstLst,inBoolean)
    local
      list<Env.Frame> env;
      Boolean impl;
      Exp.Exp e_1;
      Types.Properties prop;
      list<Algorithm.Statement> stmts;
      list<tuple<Exp.Exp, Types.Properties, list<Algorithm.Statement>>> tail_1;
      Absyn.Exp e;
      list<Absyn.AlgorithmItem> l;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> tail;
    case (env,{},impl) then {}; 
    case (env,((e,l) :: tail),impl)
      equation 
        (e_1,prop,_) = Static.elabExp(env, e, impl, NONE);
        stmts = instAlgorithmitems(env, l, impl);
        tail_1 = instElseifs(env, tail, impl);
      then
        ((e_1,prop,stmts) :: tail_1);
    case (_,_,_)
      equation 
        //Debug.fprint("failtrace", "- inst_elseifs failed\n");
      then
        fail();
  end matchcontinue;
end instElseifs;

protected function instConnect "function: instConnect
  
  Generates connectionsets for connections.
  Parameters and constants in connectors should generate appropriate 
  assert statements.
  Hence, a \'DAE.Element list\' is returned as well.
"
  input Connect.Sets inSets1;
  input Env inEnv2;
  input Prefix inPrefix3;
  input Absyn.ComponentRef inComponentRef4;
  input Absyn.ComponentRef inComponentRef5;
  input Boolean inBoolean6;
  output Connect.Sets outSets;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  (outSets,outDAEElementLst):=
  matchcontinue (inSets1,inEnv2,inPrefix3,inComponentRef4,inComponentRef5,inBoolean6)
    local
      Exp.ComponentRef c1_1,c2_1,c1_2,c2_2;
      Exp.Type t1,t2;
      Types.Properties prop1,prop2;
      SCode.Accessibility acc;
      Types.Attributes attr1,attr2;
      Boolean flow1,impl;
      tuple<Types.TType, Option<Absyn.Path>> ty1,ty2;
      Connect.Face f1,f2;
      Connect.Sets sets_1,sets;
      list<DAE.Element> dae;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      Absyn.ComponentRef c1,c2;
    case (sets,env,pre,c1,c2,impl) /* impl */ 
      equation 
        (Exp.CREF(c1_1,t1),prop1,acc) = Static.elabCref(env, c1, impl);
        (Exp.CREF(c2_1,t2),prop2,acc) = Static.elabCref(env, c2, impl);
        c1_2 = Static.canonCref(env, c1_1, impl);
        c2_2 = Static.canonCref(env, c2_1, impl);
        ((attr1 as Types.ATTR(flow1,_,_,_)),ty1,_) = Lookup.lookupVarLocal(env, c1_2);
        (attr2,ty2,_) = Lookup.lookupVar(env, c2_2);
        validConnector(ty1) "Check that the types of the connectors are good." ;
        validConnector(ty2);
        checkConnectTypes(c1_2, ty1, attr1, c2_2, ty2, attr2);
        f1 = componentFace(c1_2);
        f2 = componentFace(c2_2);
        (sets_1,dae) = connectComponents(sets, env, pre, c1_2, f1, ty1, c2_2, f2, ty2, flow1);
      then
        (sets_1,dae);
    case (_,_,_,_,_,_)
      equation 
        //Debug.fprint("failtrace", "-inst_connect failed\n");
      then
        fail();
  end matchcontinue;
end instConnect;

protected function validConnector "function: validConnector
 
  This function tests whether a type is a eligible to be used in
  connections.
 
"
  input Types.Type inType;
algorithm 
  _:=
  matchcontinue (inType)
    local
      ClassInf.State state;
      tuple<Types.TType, Option<Absyn.Path>> tp,t;
      String str;
    case ((Types.T_REAL(varLstReal = _),_)) then (); 
    case ((Types.T_COMPLEX(complexClassType = state),_))
      equation 
        ClassInf.valid(state, SCode.R_CONNECTOR());
      then
        ();
    case ((Types.T_ARRAY(arrayType = tp),_))
      equation 
        validConnector(tp);
      then
        ();
    case t
      equation 
        str = Types.unparseType(t);
        Error.addMessage(Error.INVALID_CONNECTOR_TYPE, {str});
      then
        fail();
  end matchcontinue;
end validConnector;

protected function checkConnectTypes "function: checkConnectTypes
 
  Check that the type and type attributes of two connectors match,
  so that they really may be connected.
 
"
  input Exp.ComponentRef inComponentRef1;
  input Types.Type inType2;
  input Types.Attributes inAttributes3;
  input Exp.ComponentRef inComponentRef4;
  input Types.Type inType5;
  input Types.Attributes inAttributes6;
algorithm 
  _:=
  matchcontinue (inComponentRef1,inType2,inAttributes3,inComponentRef4,inType5,inAttributes6)
    local
      String c1_str,c2_str;
      Exp.ComponentRef c1,c2;
      tuple<Types.TType, Option<Absyn.Path>> t1,t2;
      Boolean flow1,flow2;
    case (c1,_,Types.ATTR(direction = Absyn.INPUT()),c2,_,Types.ATTR(direction = Absyn.INPUT()))
      equation 
        assertDifferentFaces(c1, c2);
        c1_str = Exp.printComponentRefStr(c1);
        c2_str = Exp.printComponentRefStr(c2);
        Error.addMessage(Error.CONNECT_TWO_INPUTS, {c1_str,c2_str});
      then
        fail();
    case (c1,_,Types.ATTR(direction = Absyn.OUTPUT()),c2,_,Types.ATTR(direction = Absyn.OUTPUT()))
      equation 
        assertDifferentFaces(c1, c2);
        c1_str = Exp.printComponentRefStr(c1);
        c2_str = Exp.printComponentRefStr(c2);
        Error.addMessage(Error.CONNECT_TWO_OUTPUTS, {c1_str,c2_str});
      then
        fail();
    case (_,t1,Types.ATTR(flow_ = flow1),_,t2,Types.ATTR(flow_ = flow2))
      equation 
        equality(flow1 = flow2);
        true = Types.equivtypes(t1, t2);
      then
        ();
    case (c1,_,Types.ATTR(flow_ = true),c2,_,Types.ATTR(flow_ = false))
      equation 
        c1_str = Exp.printComponentRefStr(c1);
        c2_str = Exp.printComponentRefStr(c2);
        Error.addMessage(Error.CONNECT_FLOW_TO_NONFLOW, {c1_str,c2_str});
      then
        fail();
    case (c1,_,Types.ATTR(flow_ = false),c2,_,Types.ATTR(flow_ = true))
      equation 
        c1_str = Exp.printComponentRefStr(c1);
        c2_str = Exp.printComponentRefStr(c2);
        Error.addMessage(Error.CONNECT_FLOW_TO_NONFLOW, {c2_str,c1_str});
      then
        fail();
    case (c1,_,_,c2,_,_)
      equation 
        //Debug.fprint("failtrace", "- check_connect_types(");
        Debug.fcall("failtrace", Exp.printComponentRef, c1);
        //Debug.fprint("failtrace", " <-> ");
        Debug.fcall("failtrace", Exp.printComponentRef, c2);
        //Debug.fprint("failtrace", ") failed\n");
      then
        fail();
  end matchcontinue;
end checkConnectTypes;

protected function assertDifferentFaces "function assertDifferentFaces
 
  This function fails if two connectors have same faces, 
  e.g both inside or both outside connectors 
"
  input Exp.ComponentRef inComponentRef1;
  input Exp.ComponentRef inComponentRef2;
algorithm 
  _:=
  matchcontinue (inComponentRef1,inComponentRef2)
    local Exp.ComponentRef c1,c2;
    case (c1,c2)
      equation 
        Connect.INNER() = componentFace(c1);
        Connect.OUTER() = componentFace(c1);
      then
        ();
    case (c1,c2)
      equation 
        Connect.OUTER() = componentFace(c1);
        Connect.INNER() = componentFace(c1);
      then
        ();
  end matchcontinue;
end assertDifferentFaces;

protected function connectComponents "function: connectComponents
 
  This function connects two components and generates connection
  sets along the way.  For simple components (of type `Real\') it
  adds the components to the set, and for complex types it traverses
  the subcomponents and recursively connects them to each other.
  A DAE.Element list is returned for assert statements.
"
  input Connect.Sets inSets1;
  input Env inEnv2;
  input Prefix inPrefix3;
  input Exp.ComponentRef inComponentRef4;
  input Connect.Face inFace5;
  input Types.Type inType6;
  input Exp.ComponentRef inComponentRef7;
  input Connect.Face inFace8;
  input Types.Type inType9;
  input Boolean inBoolean10;
  output Connect.Sets outSets;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  (outSets,outDAEElementLst):=
  matchcontinue (inSets1,inEnv2,inPrefix3,inComponentRef4,inFace5,inType6,inComponentRef7,inFace8,inType9,inBoolean10)
    local
      Exp.ComponentRef c1_1,c2_1,c1,c2;
      Connect.Sets sets_1,sets;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      Connect.Face f1,f2;
      tuple<Types.TType, Option<Absyn.Path>> t1,t2,bc_tp1,bc_tp2;
      SCode.Variability vr;
      Integer dim1,dim2;
      list<DAE.Element> dae;
      list<Types.Var> l1,l2;
      Boolean flow_;
      String c1_str,t1_str;
      
      /* flow - with a subtype of Real */ 
    case (sets,env,pre,c1,f1,(Types.T_REAL(varLstReal = _),_),c2,f2,(Types.T_REAL(varLstReal = _),_),true) 
      equation 
        c1_1 = Prefix.prefixCref(pre, c1);
        c2_1 = Prefix.prefixCref(pre, c2);
        sets_1 = Connect.addFlow(sets, c1_1, f1, c2_1, f2);
      then
        (sets_1,{});
        
        /* flow - with arrays */ 
    case (sets,env,pre,c1,f1,(Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(dim1)),arrayType = t1),_),c2,f2,(Types.T_ARRAY(arrayType = t2),_),true)
      equation 
        ((Types.T_REAL(_),_)) = Types.arrayElementType(t1);
        ((Types.T_REAL(_),_)) = Types.arrayElementType(t2);
        c1_1 = Prefix.prefixCref(pre, c1);
        c2_1 = Prefix.prefixCref(pre, c2);
        sets_1 = Connect.addArrayFlow(sets, c1_1,f1, c2_1,f2,dim1);
      then
        (sets_1,{});
    case (sets,env,pre,c1,f1,(_,_),c2,f2,(_,_),false) /* Non-flow type Parameters and constants generate assert statements */ 
      equation 
        c1_1 = Prefix.prefixCref(pre, c1);
        c2_1 = Prefix.prefixCref(pre, c2);
        (Types.ATTR(_,_,vr,_),t1,_) = Lookup.lookupVarLocal(env, c1_1);
        true = SCode.isParameterOrConst(vr);
        true = Types.basicType(t1);
        (Types.ATTR(_,_,_,_),t2,_) = Lookup.lookupVarLocal(env, c2_1);
        true = Types.basicType(t2);
      then
        (sets,{
          DAE.ASSERT(
          Exp.CALL(Absyn.IDENT("assert"),
          {
          Exp.RELATION(Exp.CREF(c1_1,Exp.REAL()),Exp.EQUAL(Exp.BOOL()),
          Exp.CREF(c2_1,Exp.REAL())),Exp.SCONST("automatically generated from connect")},false,true))});
    case (sets,env,pre,c1,_,(Types.T_REAL(varLstReal = _),_),c2,_,(Types.T_REAL(varLstReal = _),_),false)
      equation 
        c1_1 = Prefix.prefixCref(pre, c1);
        c2_1 = Prefix.prefixCref(pre, c2);
        sets_1 = Connect.addEqu(sets, c1_1, c2_1);
      then
        (sets_1,{});
    case (sets,env,pre,c1,_,(Types.T_INTEGER(varLstInt = _),_),c2,_,(Types.T_INTEGER(varLstInt = _),_),false)
      equation 
        c1_1 = Prefix.prefixCref(pre, c1);
        c2_1 = Prefix.prefixCref(pre, c2);
        sets_1 = Connect.addEqu(sets, c1_1, c2_1);
      then
        (sets_1,{});
    case (sets,env,pre,c1,f1,(Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(dim1)),arrayType = t1),_),c2,f2,(Types.T_ARRAY(arrayDim = Types.DIM(integerOption = SOME(dim2)),arrayType = t2),_),false)
      equation 
        c1_1 = Prefix.prefixCref(pre, c1);
        c2_1 = Prefix.prefixCref(pre, c2);
        equality(dim1 = dim2);
        sets_1 = Connect.addArrayEqu(sets, c1_1, c2_1, dim1);
      then
        (sets_1,{});
    case (sets,env,pre,c1,f1,(Types.T_COMPLEX(complexVarLst = l1,complexTypeOption = SOME(bc_tp1)),_),c2,f2,(Types.T_COMPLEX(complexVarLst = l2,complexTypeOption = SOME(bc_tp2)),_),flow_) /* Complex types extending basetype */ 
      equation 
        (sets_1,dae) = connectComponents(sets, env, pre, c1, f1, bc_tp1, c2, f2, bc_tp2, flow_);
      then
        (sets_1,dae);
    case (sets,env,pre,c1,f1,(Types.T_COMPLEX(complexVarLst = l1),_),c2,f2,(Types.T_COMPLEX(complexVarLst = l2),_),_) /* Complex types */ 
      equation 
        c1_1 = Prefix.prefixCref(pre, c1);
        c2_1 = Prefix.prefixCref(pre, c2);
        (sets_1,dae) = connectVars(sets, env, c1_1, f1, l1, c2_1, f2, l2);
      then
        (sets_1,dae);
    case (_,env,pre,c1,_,t1,c2,_,t2,_) /* Error */ 
      equation 
        c1_1 = Prefix.prefixCref(pre, c1);
        c2_1 = Prefix.prefixCref(pre, c2);
        c1_str = Exp.printComponentRefStr(c1);
        t1_str = Types.unparseType(t1);
        Error.addMessage(Error.INVALID_CONNECTOR_VARIABLE, {c1_str,t1_str});
      then
        fail();
    case (_,env,pre,c1,_,t1,c2,_,t2,_)
      equation 
        print("-connect_components failed\n");
      then
        fail();
  end matchcontinue;
end connectComponents;

protected function connectVars "function: connectVars
 
  This function connects two subcomponents by adding the component
  name to the current path and recursively connecting the components
  using the function `connet_components\'.
"
  input Connect.Sets inSets1;
  input Env inEnv2;
  input Exp.ComponentRef inComponentRef3;
  input Connect.Face inFace4;
  input list<Types.Var> inTypesVarLst5;
  input Exp.ComponentRef inComponentRef6;
  input Connect.Face inFace7;
  input list<Types.Var> inTypesVarLst8;
  output Connect.Sets outSets;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  (outSets,outDAEElementLst):=
  matchcontinue (inSets1,inEnv2,inComponentRef3,inFace4,inTypesVarLst5,inComponentRef6,inFace7,inTypesVarLst8)
    local
      Connect.Sets sets,sets_1,sets_2;
      list<Env.Frame> env;
      Exp.ComponentRef c1_1,c2_1,c1,c2;
      list<DAE.Element> dae,dae2,dae_1;
      Connect.Face f1,f2;
      String n;
      Types.Attributes attr1,attr2;
      Boolean flow1,flow2;
      SCode.Variability vt1,vt2;
      tuple<Types.TType, Option<Absyn.Path>> ty1,ty2;
      list<Types.Var> xs1,xs2;
    case (sets,env,_,_,{},_,_,{}) then (sets,{}); 
    case (sets,env,c1,f1,(Types.VAR(name = n,attributes = (attr1 as Types.ATTR(flow_ = flow1,parameter_ = vt1)),type_ = ty1) :: xs1),c2,f2,(Types.VAR(attributes = (attr2 as Types.ATTR(flow_ = flow2,parameter_ = vt2)),type_ = ty2) :: xs2))
      equation 
        c1_1 = Exp.extendCref(c1, n, {});
        c2_1 = Exp.extendCref(c2, n, {});
        checkConnectTypes(c1_1, ty1, attr1, c2_1, ty2, attr2);
        (sets_1,dae) = connectComponents(sets, env, Prefix.NOPRE(), c1_1, f1, ty1, c2_1, f2, ty2, 
          flow1);
        (sets_2,dae2) = connectVars(sets_1, env, c1, f1, xs1, c2, f2, xs2);
        dae_1 = listAppend(dae, dae2);
      then
        (sets_2,dae_1);
  end matchcontinue;
end connectVars;

public function mktype "function: mktype 
 
  From a class typename, its inference state, and a list of subcomponents, 
  this function returns `Types.Type\'.  If the class inference state
  indicates that the type should be a built-in type, one of the
  built-in type constructors is used.  Otherwise, a `T_COMPLEX\' is
  built.
"
  input Absyn.Path inPath;
  input ClassInf.State inState;
  input list<Types.Var> inTypesVarLst;
  input Option<Types.Type> inTypesTypeOption;
  output Types.Type outType;
algorithm 
  outType:=
  matchcontinue (inPath,inState,inTypesVarLst,inTypesTypeOption)
    local
      Option<Absyn.Path> somep;
      Absyn.Path p;
      list<Types.Var> v,vl,v1,l;
      tuple<Types.TType, Option<Absyn.Path>> functype,enumtype;
      ClassInf.State st;
      String name;
      Option<tuple<Types.TType, Option<Absyn.Path>>> bc;
    case (p,ClassInf.TYPE_INTEGER(string = _),v,_) 
      equation 
        somep = getOptPath(p);
      then
        ((Types.T_INTEGER(v),somep));
    case (p,ClassInf.TYPE_REAL(string = _),v,_)
      equation 
        somep = getOptPath(p);
      then
        ((Types.T_REAL(v),somep));
    case (p,ClassInf.TYPE_STRING(string = _),v,_)
      equation 
        somep = getOptPath(p);
      then
        ((Types.T_STRING(v),somep));
    case (p,ClassInf.TYPE_BOOL(string = _),v,_)
      equation 
        somep = getOptPath(p);
      then
        ((Types.T_BOOL(v),somep));
    case (p,ClassInf.TYPE_ENUM(string = _),_,_)
      equation 
        somep = getOptPath(p);
      then
        ((Types.T_ENUM(),somep));
    case (p,(st as ClassInf.FUNCTION(string = name)),vl,_) /* Insert function type construction here
	   after checking input/output arguments? 
	   see Types.rml T_FUNCTION */ 
      equation 
        functype = Types.makeFunctionType(p, vl);
      then
        functype;
    case (p,ClassInf.ENUMERATION(string = name),v1,_)
      equation 
        enumtype = Types.makeEnumerationType(p, v1);
      then
        enumtype;
    case (p,st,l,bc)
      equation 
        somep = getOptPath(p);
      then
        ((Types.T_COMPLEX(st,l,bc),somep));
  end matchcontinue;
end mktype;

protected function mktypeWithArrays "function: mktypeWithArrays
  author: PA
 
  This function is similar to mktype with the exception
  that it will create array types based on the last argument,
  which indicates wheter the class extends from a basictype.
  It is used only in the inst_class_basictype function.
"
  input Absyn.Path inPath;
  input ClassInf.State inState;
  input list<Types.Var> inTypesVarLst;
  input Option<Types.Type> inTypesTypeOption;
  output Types.Type outType;
algorithm 
  outType:=
  matchcontinue (inPath,inState,inTypesVarLst,inTypesTypeOption)
    local
      Absyn.Path p;
      ClassInf.State ci,st;
      list<Types.Var> vs,v,vl,v1,l;
      tuple<Types.TType, Option<Absyn.Path>> tp,functype,enumtype;
      Option<Absyn.Path> somep;
      String name;
      Option<tuple<Types.TType, Option<Absyn.Path>>> bc;
    case (p,ci,vs,SOME(tp))
      equation 
        true = Types.isArray(tp);
        failure(ClassInf.isConnector(ci));
      then
        tp;
    case (p,ClassInf.TYPE_INTEGER(string = _),v,_)
      equation 
        somep = getOptPath(p);
      then
        ((Types.T_INTEGER(v),somep));
    case (p,ClassInf.TYPE_REAL(string = _),v,_)
      equation 
        somep = getOptPath(p);
      then
        ((Types.T_REAL(v),somep));
    case (p,ClassInf.TYPE_STRING(string = _),v,_)
      equation 
        somep = getOptPath(p);
      then
        ((Types.T_STRING(v),somep));
    case (p,ClassInf.TYPE_BOOL(string = _),v,_)
      equation 
        somep = getOptPath(p);
      then
        ((Types.T_BOOL(v),somep));
    case (p,ClassInf.TYPE_ENUM(string = _),_,_)
      equation 
        somep = getOptPath(p);
      then
        ((Types.T_ENUM(),somep));
    case (p,(st as ClassInf.FUNCTION(string = name)),vl,_) /* Insert function type construction here
	   after checking input/output arguments? 
	   see Types.rml T_FUNCTION */ 
      equation 
        functype = Types.makeFunctionType(p, vl);
      then
        functype;
    case (p,ClassInf.ENUMERATION(string = name),v1,_)
      equation 
        enumtype = Types.makeEnumerationType(p, v1);
      then
        enumtype;
    case (p,st,l,bc)
      equation 
        somep = getOptPath(p);
      then
        ((Types.T_COMPLEX(st,l,bc),somep));
  end matchcontinue;
end mktypeWithArrays;

protected function getOptPath "function: getOptPath
  
  Helper function to mktype
  Transforms a Path into a Path option.
"
  input Absyn.Path inPath;
  output Option<Absyn.Path> outAbsynPathOption;
algorithm 
  outAbsynPathOption:=
  matchcontinue (inPath)
    local Absyn.Path p;
    case Absyn.IDENT(name = "") then NONE; 
    case p then SOME(p); 
  end matchcontinue;
end getOptPath;

protected function instList "function: instList
 
  This is a utility used to do instantiation of list of things,
  collecting the result in another list.
"
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input FuncTypeEnvModPrefixConnect_SetsClassInf_StateType_aBooleanToType_bLstEnvConnect_SetsClassInf_State inFuncTypeEnvModPrefixConnectSetsClassInfStateTypeABooleanToTypeBLstEnvConnectSetsClassInfState;
  input list<Type_a> inTypeALst;
  input Boolean inBoolean;
  output list<Type_b> outTypeBLst;
  output Env outEnv;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  partial function FuncTypeEnvModPrefixConnect_SetsClassInf_StateType_aBooleanToType_bLstEnvConnect_SetsClassInf_State
    input Env inEnv;
    input Mod inMod;
    input Prefix inPrefix;
    input Connect.Sets inSets;
    input ClassInf.State inState;
    input Type_a inTypeA;
    input Boolean inBoolean;
    output list<Type_b> outTypeBLst;
    output Env outEnv;
    output Connect.Sets outSets;
    output ClassInf.State outState;
    replaceable type Type_a;
    replaceable type Type_b;
  end FuncTypeEnvModPrefixConnect_SetsClassInf_StateType_aBooleanToType_bLstEnvConnect_SetsClassInf_State;
  replaceable type Type_a;
  replaceable type Type_b;
algorithm 
  (outTypeBLst,outEnv,outSets,outState):=
  matchcontinue (inEnv,inMod,inPrefix,inSets,inState,inFuncTypeEnvModPrefixConnectSetsClassInfStateTypeABooleanToTypeBLstEnvConnectSetsClassInfState,inTypeALst,inBoolean)
    local
      partial function FuncTypeEnv_FrameLstTypes_ModPrefix_PrefixConnect_SetsClassInf_StateType_aBooleanToType_bLstEnv_FrameLstConnect_SetsClassInf_State
        input list<Env.Frame> inEnvFrameLst;
        input Types.Mod inMod;
        input Prefix.Prefix inPrefix;
        input Connect.Sets inSets;
        input ClassInf.State inState;
        input Type_a inTypeA;
        input Boolean inBoolean;
        output list<Type_b> outTypeBLst;
        output list<Env.Frame> outEnvFrameLst;
        output Connect.Sets outSets;
        output ClassInf.State outState;
      end FuncTypeEnv_FrameLstTypes_ModPrefix_PrefixConnect_SetsClassInf_StateType_aBooleanToType_bLstEnv_FrameLstConnect_SetsClassInf_State;
      list<Env.Frame> env,env_1,env_2;
      Types.Mod mod;
      Prefix.Prefix pre;
      Connect.Sets csets,csets_1,csets_2;
      ClassInf.State ci_state,ci_state_1,ci_state_2;
      FuncTypeEnv_FrameLstTypes_ModPrefix_PrefixConnect_SetsClassInf_StateType_aBooleanToType_bLstEnv_FrameLstConnect_SetsClassInf_State r;
      Boolean impl;
      list<Type_b> l,l_1,l_2;
      Type_a e;
      list<Type_a> es;
    case (env,mod,pre,csets,ci_state,r,{},impl) then ({},env,csets,ci_state);  /* impl impl */ 
    case (env,mod,pre,csets,ci_state,r,(e :: es),impl)
      equation 
        (l,env_1,csets_1,ci_state_1) = r(env, mod, pre, csets, ci_state, e, impl);
        (l_1,env_2,csets_2,ci_state_2) = instList(env_1, mod, pre, csets_1, ci_state_1, r, es, impl);
        l_2 = listAppend(l, l_1);
      then
        (l_2,env_2,csets_2,ci_state_2);
  end matchcontinue;
end instList;

protected function componentFace "function: componentFace
  
  This function determines whether a component reference refers to an
  inner or outer connector.
"
  input Exp.ComponentRef inComponentRef;
  output Connect.Face outFace;
algorithm 
  outFace:=
  matchcontinue (inComponentRef)
    case Exp.CREF_QUAL(componentRef = Exp.CREF_IDENT(ident = _)) then Connect.INNER(); 
    case Exp.CREF_QUAL(componentRef = Exp.CREF_QUAL(ident = _)) then Connect.INNER(); 
    case Exp.CREF_IDENT(ident = _) then Connect.OUTER(); 
  end matchcontinue;
end componentFace;

protected function instBinding "function: instBinding
 
  This function investigates a modification and extracts the 
  <...> modification. E.g. Real x(<...>=1+3) => 1+3
  It also handles the case Integer T0{2}(final <...>={5,6})={9,10} becomes
  Integer T0{1}(<...>=5); Integer T0{2}(<...>=6);
 
  Arg 1 is the modification  
  Arg 2 is the expected type that the modification should have
  Arg 3 is the index list for the element: for T0{1,2} is {1,2} 
 
"
  input Mod inMod;
  input Types.Type inType;
  input list<Integer> inIntegerLst;
  input String inString;
  output Option<Exp.Exp> outExpExpOption;
algorithm 
  outExpExpOption:=
  matchcontinue (inMod,inType,inIntegerLst,inString)
    local
      Types.Mod mod2,mod;
      Exp.Exp e,e_1;
      tuple<Types.TType, Option<Absyn.Path>> ty2,ty_1,expected_type,etype;
      String bind_name;
      Option<Exp.Exp> result;
      list<Integer> index_list;
    case (mod,expected_type,{},bind_name) /* No subscript/index */ 
      equation 
        mod2 = Mod.lookupCompModification(mod, bind_name);
        SOME(Types.TYPED(e,_,Types.PROP(ty2,_))) = Mod.modEquation(mod2);
        (e_1,ty_1) = Types.matchType(e, ty2, expected_type);
      then
        SOME(e_1);
    case (mod,etype,index_list,bind_name) /* Have subscript/index */ 
      equation 
        mod2 = Mod.lookupCompModification(mod, bind_name);
        result = instBinding2(mod2, etype, index_list, bind_name);
      then
        result;
    case (mod,expected_type,{},bind_name) /* No modifier for this name. */ 
      equation 
        failure(mod2 = Mod.lookupCompModification(mod, bind_name));
      then
        NONE;
    case (mod,etype,_,_) then NONE; 
  end matchcontinue;
end instBinding;

protected function instBinding2 "function: instBinding2
 
  This function investigates a modification and extracts the <...> 
  modification if the modification is in array of components. 
  Help-function to inst_binding
"
  input Mod inMod;
  input Types.Type inType;
  input list<Integer> inIntegerLst;
  input String inString;
  output Option<Exp.Exp> outExpExpOption;
algorithm 
  outExpExpOption:=
  matchcontinue (inMod,inType,inIntegerLst,inString)
    local
      Types.Mod mod2,mod;
      Exp.Exp e,e_1;
      tuple<Types.TType, Option<Absyn.Path>> ty2,ty_1,etype;
      Integer index;
      String bind_name;
      Option<Exp.Exp> result;
      list<Integer> res;
    case (mod,etype,(index :: {}),bind_name) /* Only one element in the index-list */ 
      equation 
        mod2 = Mod.lookupIdxModification(mod, index);
        SOME(Types.TYPED(e,_,Types.PROP(ty2,_))) = Mod.modEquation(mod2);
        (e_1,ty_1) = Types.matchType(e, ty2, etype);
      then
        SOME(e_1);
    case (mod,etype,(index :: res),bind_name) /* Several elements in the index-list */ 
      equation 
        mod2 = Mod.lookupIdxModification(mod, index);
        result = instBinding2(mod2, etype, res, bind_name);
      then
        result;
    case (mod,etype,(index :: res),bind_name)
      equation 
        failure(mod2 = Mod.lookupIdxModification(mod, index));
      then
        NONE;
    case (_,_,_,_) /* Print.printBuf(\"inst_binding2 failed\\n\") */  then fail(); 
  end matchcontinue;
end instBinding2;

protected function instStartBindingExp "function: instStartBindingExp
 
  This function investigates a modification and extracts the 
  start modification. E.g. Real x(start=1+3) => 1+3
  It also handles the case Integer T0{2}(final start={5,6})={9,10} becomes
  Integer T0{1}(start=5); Integer T0{2}(start=6);
 
  Arg 1 is the start modification  
  Arg 2 is the expected type that the modification should have
  Arg 3 is the index list for the element: for T0{1,2} is {1,2} 
"
  input Mod mod;
  input Types.Type etype;
  input list<Integer> index_list;
  output DAE.StartValue result;
algorithm 
  result := instBinding(mod, etype, index_list, "start");
end instStartBindingExp;

protected function instDaeVariableAttributes "function: instDaeVariableAttributes 
 
  this function extracts the attributes from the modification
  It returns a DAE.VariableAttributes option because 
  somtimes a varible does not contain the variable-attr.
"
  input Env inEnv;
  input Mod inMod;
  input Types.Type inType;
  input list<Integer> inIntegerLst;
  output Option<DAE.VariableAttributes> outDAEVariableAttributesOption;
algorithm 
  outDAEVariableAttributesOption:=
  matchcontinue (inEnv,inMod,inType,inIntegerLst)
    local
      Option<String> quantity_str,unit_str,displayunit_str;
      Option<Real> min_val,max_val,start_val,nominal_val;
      Option<Boolean> fixed_val;
      Option<Exp.Exp> exp_bind_select,exp_bind_min,exp_bind_max,exp_bind_start;
      Option<DAE.StateSelect> stateSelect_value;
      list<Env.Frame> env;
      Types.Mod mod;
      Option<Absyn.Path> path;
      list<Integer> index_list;
      tuple<Types.TType, Option<Absyn.Path>> enumtype;
    case (env,mod,(Types.T_REAL(varLstReal = _),path),index_list) /* Real */ 
      equation 
        quantity_str = instStringBinding(env, mod, index_list, "quantity");
        unit_str = instStringBinding(env, mod, index_list, "unit");
        displayunit_str = instStringBinding(env, mod, index_list, "displayUnit");
        min_val = instRealBinding(env, mod, index_list, "min");
        max_val = instRealBinding(env, mod, index_list, "max");
        start_val = instRealBinding(env, mod, index_list, "start");
        fixed_val = instBoolBinding(env, mod, index_list, "fixed");
        nominal_val = instRealBinding(env, mod, index_list, "nominal");
        exp_bind_select = instEnumerationBinding(env, mod, index_list, "stateSelect");
        stateSelect_value = getStateSelectFromExpOption(exp_bind_select);
      then
        SOME(
          DAE.VAR_ATTR_REAL(quantity_str,unit_str,displayunit_str,(min_val,max_val),
          start_val,fixed_val,nominal_val,stateSelect_value));
    case (env,mod,(Types.T_INTEGER(varLstInt = _),_),index_list) /* Integer */ 
      local Option<Integer> min_val,max_val,start_val;
      equation 
        quantity_str = instStringBinding(env, mod, index_list, "quantity");
        min_val = instIntBinding(env, mod, index_list, "min");
        max_val = instIntBinding(env, mod, index_list, "max");
        start_val = instIntBinding(env, mod, index_list, "start");
        fixed_val = instBoolBinding(env, mod, index_list, "fixed");
      then
        SOME(
          DAE.VAR_ATTR_INT(quantity_str,(min_val,max_val),start_val,fixed_val));
    case (env,mod,(Types.T_BOOL(varLstBool = _),_),index_list) /* Boolean */ 
      local Option<Boolean> start_val;
      equation 
        quantity_str = instStringBinding(env, mod, index_list, "quantity");
        start_val = instBoolBinding(env, mod, index_list, "start");
        fixed_val = instBoolBinding(env, mod, index_list, "fixed");
      then
        SOME(DAE.VAR_ATTR_BOOL(quantity_str,start_val,fixed_val));
    case (env,mod,(Types.T_STRING(varLstString = _),_),index_list) /* String */ 
      local Option<String> start_val;
      equation 
        quantity_str = instStringBinding(env, mod, index_list, "quantity");
        start_val = instStringBinding(env, mod, index_list, "start");
      then
        SOME(DAE.VAR_ATTR_STRING(quantity_str,start_val));
    case (env,mod,(enumtype as (Types.T_ENUMERATION(names = _),_)),index_list) /* Enumeration */ 
      equation 
        quantity_str = instStringBinding(env, mod, index_list, "quantity");
        exp_bind_min = instBinding(mod, enumtype, index_list, "min");
        exp_bind_max = instBinding(mod, enumtype, index_list, "max");
        exp_bind_start = instBinding(mod, enumtype, index_list, "start");
        fixed_val = instBoolBinding(env, mod, index_list, "fixed");
      then
        SOME(
          DAE.VAR_ATTR_ENUMERATION(quantity_str,(exp_bind_min,exp_bind_max),exp_bind_start,
          fixed_val));
    case (env,mod,_,_) /* Print.print_error_buf \"# unknown type for variable.\\n\"  & Mod.print_mod_str(mod) => str & print str & print \"<- mod \\n\" */  then NONE; 
  end matchcontinue;
end instDaeVariableAttributes;

protected function instBoolBinding "function instBoolBinding
  author: LP
 
  instantiates a bool binding and retrieves the value.
  FIXME: check the type of variable for the fixed because there is a 
  difference between parameters and variables
"
  input Env inEnv;
  input Mod inMod;
  input list<Integer> inIntegerLst;
  input String inString;
  output Option<Boolean> outBooleanOption;
algorithm 
  outBooleanOption:=
  matchcontinue (inEnv,inMod,inIntegerLst,inString)
    local
      Exp.Exp e;
      Boolean result;
      list<Env.Frame> env;
      Types.Mod mod;
      list<Integer> index_list;
      String bind_name;
    case (env,mod,index_list,bind_name)
      equation 
        SOME(e) = instBinding(mod, (Types.T_BOOL({}),NONE), index_list, bind_name);
        (Values.BOOL(result),_) = Ceval.ceval(env, e, false, NONE, NONE, Ceval.NO_MSG());
      then
        SOME(result);
    case (env,mod,index_list,bind_name) /* Non constant expression return NONE */ 
      equation 
        SOME(e) = instBinding(mod, (Types.T_BOOL({}),NONE), index_list, bind_name);
      then
        NONE;
    case (env,mod,index_list,bind_name)
      equation 
        NONE = instBinding(mod, (Types.T_BOOL({}),NONE), index_list, bind_name);
      then
        NONE;
    case (env,mod,index_list,bind_name)
      equation 
        Error.addMessage(Error.TYPE_ERROR, {bind_name,"Boolean"});
      then
        fail();
  end matchcontinue;
end instBoolBinding;

protected function instRealBinding "function: instRealBinding
  author: LP
 
  instantiates a real binding and retrieves the value.
"
  input Env inEnv;
  input Mod inMod;
  input list<Integer> inIntegerLst;
  input String inString;
  output Option<Real> outRealOption;
algorithm 
  outRealOption:=
  matchcontinue (inEnv,inMod,inIntegerLst,inString)
    local
      Exp.Exp e;
      Real result;
      list<Env.Frame> env;
      Types.Mod mod;
      list<Integer> index_list;
      String bind_name;
    case (env,mod,index_list,bind_name)
      equation 
        SOME(e) = instBinding(mod, (Types.T_REAL({}),NONE), index_list, bind_name);
        (Values.REAL(result),_) = Ceval.ceval(env, e, false, NONE, NONE, Ceval.NO_MSG());
      then
        SOME(result);
    case (env,mod,index_list,bind_name) /* non constant expression, return NONE */ 
      equation 
        SOME(e) = instBinding(mod, (Types.T_REAL({}),NONE), index_list, bind_name);
      then
        NONE;
    case (env,mod,index_list,bind_name)
      equation 
        NONE = instBinding(mod, (Types.T_REAL({}),NONE), index_list, bind_name);
      then
        NONE;
    case (env,mod,index_list,bind_name)
      equation 
        Error.addMessage(Error.TYPE_ERROR, {bind_name,"Real"});
      then
        fail();
  end matchcontinue;
end instRealBinding;

protected function instIntBinding "function: instIntBinding
  author: LP
 
  instantiates an int binding and retrieves the value.
"
  input Env inEnv;
  input Mod inMod;
  input list<Integer> inIntegerLst;
  input String inString;
  output Option<Integer> outIntegerOption;
algorithm 
  outIntegerOption:=
  matchcontinue (inEnv,inMod,inIntegerLst,inString)
    local
      Exp.Exp e;
      Integer result;
      list<Env.Frame> env;
      Types.Mod mod;
      list<Integer> index_list;
      String bind_name;
    case (env,mod,index_list,bind_name)
      equation 
        SOME(e) = instBinding(mod, (Types.T_INTEGER({}),NONE), index_list, bind_name);
        (Values.INTEGER(result),_) = Ceval.ceval(env, e, false, NONE, NONE, Ceval.NO_MSG());
      then
        SOME(result);
    case (env,mod,index_list,bind_name) /* got non-constant expression, return NONE */ 
      equation 
        SOME(e) = instBinding(mod, (Types.T_INTEGER({}),NONE), index_list, bind_name);
      then
        NONE;
    case (env,mod,index_list,bind_name)
      equation 
        NONE = instBinding(mod, (Types.T_INTEGER({}),NONE), index_list, bind_name);
      then
        NONE;
    case (env,mod,index_list,bind_name)
      equation 
        Error.addMessage(Error.TYPE_ERROR, {bind_name,"Integer"});
      then
        fail();
  end matchcontinue;
end instIntBinding;

protected function instStringBinding "function: instStringBinding
  author: LP
 
  instantiates a string binding and retrieves the value.
"
  input Env inEnv;
  input Mod inMod;
  input list<Integer> inIntegerLst;
  input String inString;
  output Option<String> outStringOption;
algorithm 
  outStringOption:=
  matchcontinue (inEnv,inMod,inIntegerLst,inString)
    local
      Exp.Exp e;
      String result,bind_name;
      list<Env.Frame> env;
      Types.Mod mod;
      list<Integer> index_list;
    case (env,mod,index_list,bind_name)
      equation 
        SOME(e) = instBinding(mod, (Types.T_STRING({}),NONE), index_list, bind_name);
        (Values.STRING(result),_) = Ceval.ceval(env, e, false, NONE, NONE, Ceval.NO_MSG());
      then
        SOME(result);
    case (env,mod,index_list,bind_name) /* Non constant expression return NONE */ 
      equation 
        SOME(e) = instBinding(mod, (Types.T_STRING({}),NONE), index_list, bind_name);
      then
        NONE;
    case (env,mod,index_list,bind_name)
      equation 
        NONE = instBinding(mod, (Types.T_STRING({}),NONE), index_list, bind_name);
      then
        NONE;
    case (env,mod,index_list,bind_name)
      equation 
        Error.addMessage(Error.TYPE_ERROR, {bind_name,"String"});
      then
        fail();
  end matchcontinue;
end instStringBinding;

protected function instEnumerationBinding "function: instEnumerationBinding
  author: LP
 
  instantiates a enumeration binding and retrieves the value.
"
  input Env inEnv;
  input Mod inMod;
  input list<Integer> inIntegerLst;
  input String inString;
  output Option<Exp.Exp> outExpExpOption;
algorithm 
  outExpExpOption:=
  matchcontinue (inEnv,inMod,inIntegerLst,inString)
    local
      Option<Exp.Exp> result;
      list<Env.Frame> env;
      Types.Mod mod;
      list<Integer> index_list;
      String bind_name;
    case (env,mod,index_list,bind_name)
      equation 
        result = instBinding(mod, (Types.T_ENUMERATION({},{}),NONE), index_list, 
          bind_name);
      then
        result;
    case (env,mod,index_list,bind_name)
      equation 
        Error.addMessage(Error.TYPE_ERROR, {bind_name,"enumeration type"});
      then
        fail();
  end matchcontinue;
end instEnumerationBinding;

protected function getStateSelectFromExpOption "function: getStateSelectFromExpOption
  author: LP
 
  Retrieves the stateSelect value, as defined in DAE,  from an Expression option.
"
  input Option<Exp.Exp> inExpExpOption;
  output Option<DAE.StateSelect> outDAEStateSelectOption;
algorithm 
  outDAEStateSelectOption:=
  matchcontinue (inExpExpOption)
    case (SOME(Exp.CREF(Exp.CREF_QUAL("StateSelect",{},Exp.CREF_IDENT("never",{})),Exp.ENUM()))) then SOME(DAE.NEVER()); 
    case (SOME(Exp.CREF(Exp.CREF_QUAL("StateSelect",{},Exp.CREF_IDENT("avoid",{})),Exp.ENUM()))) then SOME(DAE.AVOID()); 
    case (SOME(Exp.CREF(Exp.CREF_QUAL("StateSelect",{},Exp.CREF_IDENT("default",{})),Exp.ENUM()))) then SOME(DAE.DEFAULT()); 
    case (SOME(Exp.CREF(Exp.CREF_QUAL("StateSelect",{},Exp.CREF_IDENT("prefer",{})),Exp.ENUM()))) then SOME(DAE.PREFER()); 
    case (SOME(Exp.CREF(Exp.CREF_QUAL("StateSelect",{},Exp.CREF_IDENT("always",{})),Exp.ENUM()))) then SOME(DAE.ALWAYS()); 
    case (NONE) then NONE; 
    case (_) then NONE; 
  end matchcontinue;
end getStateSelectFromExpOption;

protected function instModEquation "function: instModEquation
 
  This function adds the equation in the declaration of a variable,
  if such an equation exists.
"
  input Exp.ComponentRef inComponentRef;
  input Types.Type inType;
  input Mod inMod;
  input Boolean inBoolean;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  outDAEElementLst:=
  matchcontinue (inComponentRef,inType,inMod,inBoolean)
    local
      Exp.Type t;
      list<DAE.Element> dae;
      Exp.ComponentRef cr,c;
      tuple<Types.TType, Option<Absyn.Path>> ty1;
      Types.Mod mod,m;
      Exp.Exp e;
      Types.Properties prop2;
      Boolean impl;
    case (cr,ty1,(mod as Types.MOD(eqModOption = SOME(Types.TYPED(e,_,prop2)))),impl) /* impl */ 
      equation 
        t = Types.elabType(ty1);
        dae = instEqEquation(Exp.CREF(cr,t), Types.PROP(ty1,Types.C_VAR()), e, prop2, 
          NON_INITIAL(), impl);
      then
        dae;
    case (_,_,Types.MOD(eqModOption = NONE),impl) then {}; 
    case (_,_,Types.NOMOD(),impl) then {}; 
    case (_,_,Types.REDECL(final_ = _),impl) then {}; 
    case (c,t,m,impl)
      local tuple<Types.TType, Option<Absyn.Path>> t;
      equation 
        //Debug.fprint("failtrace", "- inst_mod_equation failed\n type: ");
        Debug.fcall("failtrace", Types.printType, t);
        //Debug.fprint("failtrace", "\n  cref: ");
        Debug.fcall("failtrace", Exp.printComponentRef, c);
        //Debug.fprint("failtrace", "\n mod:");
        Debug.fcall("failtrace", Mod.printMod, m);
        //Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end instModEquation;

protected function checkProt "function: checkProt
 
  This function is used to check that a protected element is not
  modified.
"
  input Boolean inBoolean;
  input Mod inMod;
  input Exp.ComponentRef inComponentRef;
algorithm 
  _:=
  matchcontinue (inBoolean,inMod,inComponentRef)
    local
      Exp.ComponentRef cref;
      String str;
    case (false,_,cref) then (); 
    case (_,Types.NOMOD(),_) then (); 
    case (true,_,cref)
      equation 
        str = Exp.printComponentRefStr(cref);
        Error.addMessage(Error.MODIFY_PROTECTED, {str});
      then
        fail();
  end matchcontinue;
end checkProt;

public function makeBinding "function: makeBinding
 
  This function looks at the equation part of a modification, and if
  there is a declaration equation builds a `Types.Binding\' for it.
 
"
  input Env inEnv;
  input SCode.Attributes inAttributes;
  input Mod inMod;
  input Types.Type inType;
  output Types.Binding outBinding;
algorithm 
  outBinding:=
  matchcontinue (inEnv,inAttributes,inMod,inType)
    local
      tuple<Types.TType, Option<Absyn.Path>> tp,e_tp;
      Exp.Exp e_1,e;
      Values.Value v;
      list<Env.Frame> env;
      Option<Values.Value> e_val;
      Types.Const c;
      String e_tp_str,tp_str,e_str,e_str_1;
    case (_,_,Types.NOMOD(),tp) then Types.UNBOUND(); 
    case (_,_,Types.REDECL(final_ = _),tp) then Types.UNBOUND(); 
    case (_,_,Types.MOD(eqModOption = NONE),tp) then Types.UNBOUND(); 
    case (env,_,Types.MOD(eqModOption = SOME(Types.TYPED(e,_,Types.PROP(e_tp,_)))),tp) /* numerical values */ 
      equation 
        (e_1,_) = Types.matchType(e, e_tp, tp);
        (v,_) = Ceval.ceval(env, e_1, false, NONE, NONE, Ceval.NO_MSG());
      then
        Types.VALBOUND(v);
    case (_,_,Types.MOD(eqModOption = SOME(Types.TYPED(e,e_val,Types.PROP(e_tp,c)))),tp) /* default */ 
      equation 
        (e_1,_) = Types.matchType(e, e_tp, tp);
        e_1 = Exp.simplify(e_1);
      then
        Types.EQBOUND(e_1,e_val,c);
    case (_,_,Types.MOD(eqModOption = SOME(Types.TYPED(e,e_val,Types.PROP(e_tp,c)))),tp)
      equation 
        (e_1,_) = Types.matchType(e, e_tp, tp);
      then
        Types.EQBOUND(e_1,e_val,c);
    case (_,_,Types.MOD(eqModOption = SOME(Types.TYPED(e,e_val,Types.PROP(e_tp,c)))),tp)
      equation 
        failure((_,_) = Types.matchType(e, e_tp, tp));
        e_tp_str = Types.unparseType(e_tp);
        tp_str = Types.unparseType(tp);
        e_str = Exp.printExpStr(e);
        e_str_1 = stringAppend("=", e_str);
        Error.addMessage(Error.MODIFIER_TYPE_MISMATCH_ERROR, 
          {tp_str,e_str_1,e_tp_str});
      then
        fail();
    case (_,_,_,_)
      equation 
        //Debug.fprint("failtrace", "- make_binding failed\n");
      then
        fail();
  end matchcontinue;
end makeBinding;

public function initVarsModelicaOutput "function initVarsModelicaOutput
  author: LS
 
  This rule goes through the elements and for each variable, searches the 
  rest of the list for \"equations\" which refer to that variable on the LHS, 
  and puts their RHS in the variable as the initialization expression. This 
  is needed for modelica output where parameters must be \"assigned\" (?) 
  during declaration.
"
  input list<DAE.Element> l;
  output list<DAE.Element> l_1;
  list<DAE.Element> l_1;
algorithm 
  l_1 := initVarsModelicaOutput1({}, l);
end initVarsModelicaOutput;

protected function initVarsModelicaOutput1 "function: init_var_modelica_output_1
 
  Helper relaation to init_vars_modelica_output
"
  input list<DAE.Element> inDAEElementLst1;
  input list<DAE.Element> inDAEElementLst2;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  outDAEElementLst:=
  matchcontinue (inDAEElementLst1,inDAEElementLst2)
    local
      list<DAE.Element> done,done_1,todorest_1,done_2,done_3,todorest,dae_1,dae,rest;
      Option<Exp.Exp> exp_1,exp_2,exp,start;
      DAE.Element v,e;
      Exp.ComponentRef cr;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Type ty;
      InstDims inst_dims;
      DAE.Flow flow_;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      String n;
      Absyn.Path fpath;
    case (done,{}) then done; 
    case (done,((v as DAE.VAR(componentRef = cr,varible = vk,variable = vd,input_ = ty,one = exp,binding = inst_dims,dimension = start,value = flow_,flow_ = class_,variableAttributesOption = dae_var_attr,absynCommentOption = comment)) :: todorest))
      equation 
        (exp_1,done_1) = initVarsModelicaOutput2(cr, exp, done);
        (exp_2,todorest_1) = initVarsModelicaOutput2(cr, exp_1, todorest);
        done_2 = listAppend(done_1, 
          {
          DAE.VAR(cr,vk,vd,ty,exp_2,inst_dims,start,flow_,class_,
          dae_var_attr,comment)});
        done_3 = initVarsModelicaOutput1(done_2, todorest_1);
      then
        done_3;
    case (done,(DAE.COMP(ident = n,dAElist = DAE.DAE(elementLst = dae)) :: rest))
      equation 
        dae_1 = initVarsModelicaOutput(dae);
        done_1 = listAppend(done, {DAE.COMP(n,DAE.DAE(dae_1))});
        done_2 = initVarsModelicaOutput1(done_1, rest);
      then
        done_2;
    case (done,(DAE.FUNCTION(path = fpath,dAElist = DAE.DAE(elementLst = dae),type_ = ty) :: rest))
      local tuple<Types.TType, Option<Absyn.Path>> ty;
      equation 
        dae_1 = initVarsModelicaOutput(dae);
        done_1 = listAppend(done, {DAE.FUNCTION(fpath,DAE.DAE(dae_1),ty)});
        done_2 = initVarsModelicaOutput1(done_1, rest);
      then
        done_2;
    case (done,(e :: rest))
      equation 
        done_1 = listAppend(done, {e});
        done_2 = initVarsModelicaOutput1(done_1, rest);
      then
        done_2;
  end matchcontinue;
end initVarsModelicaOutput1;

protected function initVarsModelicaOutput2 "function initVarsModelicaOutput2
  author: LS
 
  Search the list for equations with LHS as componentref = cr, remove from the
  list and return the RHS of the last of those equations
"
  input Exp.ComponentRef inComponentRef;
  input Option<Exp.Exp> inExpExpOption;
  input list<DAE.Element> inDAEElementLst;
  output Option<Exp.Exp> outExpExpOption;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  (outExpExpOption,outDAEElementLst):=
  matchcontinue (inComponentRef,inExpExpOption,inDAEElementLst)
    local
      Exp.ComponentRef cr,e1cr,excr;
      Option<Exp.Exp> exp,exp_2;
      list<DAE.Element> rest_1,rest;
      Exp.Exp exp_1;
      DAE.Element e1;
    case (cr,exp,{}) then (exp,{}); 
    case (cr,exp,(DAE.EQUATION(exp = Exp.CREF(componentRef = e1cr),scalar = exp_1) :: rest)) /* Exp.OTHER */ 
      equation 
        true = Exp.crefEqual(cr, e1cr);
        (exp_2,rest_1) = initVarsModelicaOutput2(cr, SOME(exp_1), rest);
      then
        (exp_2,rest_1);
    case (cr,exp,((e1 as DAE.EQUATION(exp = Exp.CREF(componentRef = e1cr),scalar = exp_1)) :: rest)) /* Exp.OTHER */ 
      equation 
        false = Exp.crefEqual(cr, e1cr);
        (exp_2,rest_1) = initVarsModelicaOutput2(cr, exp, rest);
      then
        (exp_2,(e1 :: rest_1));
    case (excr,exp,(e1 :: rest))
      local Option<Exp.Exp> exp_1;
      equation 
        (exp_1,rest_1) = initVarsModelicaOutput2(excr, exp, rest);
      then
        (exp_1,(e1 :: rest_1));
  end matchcontinue;
end initVarsModelicaOutput2;

public function instRecordConstructorElt "function: instRecordConstructorElt
  author: PA
 
  This function takes an Env and an Element and builds a input argument to 
  a record constructor.
  E.g if the element is Real x; the resulting Var is \"input Real x;\"
"
  input Env inEnv;
  input SCode.Element inElement;
  input Boolean inBoolean;
  output Types.Var outVar;
algorithm 
  outVar:=
  matchcontinue (inEnv,inElement,inBoolean)
    local
      SCode.Class cl;
      list<Env.Frame> cenv,env;
      Types.Mod mod_1;
      Absyn.ComponentRef owncref;
      list<DimExp> dimexp;
      tuple<Types.TType, Option<Absyn.Path>> tp_1;
      Types.Binding bind;
      String id,str;
      Boolean repl,prot,f,impl;
      SCode.Attributes attr;
      list<Absyn.Subscript> dim;
      SCode.Accessibility acc;
      SCode.Variability var;
      Absyn.Direction dir;
      Absyn.Path t;
      SCode.Mod mod;
      Option<Absyn.Path> bc;
      Option<Absyn.Comment> comment;
      SCode.Element elt;
    case (env,SCode.COMPONENT(component = id,replaceable_ = repl,protected_ = prot,attributes = (attr as SCode.ATTR(arrayDim = dim,flow_ = f,RW = acc,parameter_ = var,input_ = dir)),type_ = t,mod = mod,baseclass = bc,this = comment),impl) /* impl */ 
      equation 
        //Debug.fprint("recconst", "inst_record_constructor_elt called\n");
        (cl,cenv) = Lookup.lookupClass(env, t, true);
        //Debug.fprint("recconst", "looked up class\n");
        mod_1 = Mod.elabMod(env, Prefix.NOPRE(), mod, impl);
        owncref = Absyn.CREF_IDENT(id,{});
        dimexp = elabArraydim(env, owncref, dim, NONE, false, NONE);
        //Debug.fprint("recconst", "calling inst_var\n");
        (_,_,_,tp_1) = instVar(cenv, ClassInf.FUNCTION(""), mod_1, Prefix.NOPRE(), 
          Connect.emptySet, id, cl, attr, dimexp, {}, {}, impl, comment);
        //Debug.fprint("recconst", "Type of argument:");
        Debug.fcall("recconst", Types.printType, tp_1);
        //Debug.fprint("recconst", "\nMod=");
        Debug.fcall("recconst", Mod.printMod, mod_1);
        bind = makeBinding(env, attr, mod_1, tp_1);
      then
        Types.VAR(id,Types.ATTR(f,acc,var,Absyn.INPUT()),prot,tp_1,bind);
    case (env,elt,impl)
      equation 
        //Debug.fprint("failtrace", "- inst_record_constructor_elt failed.,elt:");
        str = SCode.printElementStr(elt);
        //Debug.fprint("failtrace", str);
        //Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end instRecordConstructorElt;

protected function isTopCall "function: isTopCall
  author: PA
 
  The topmost instantiation call is treated specially with for instance 
  unconnected connectors.
  This function returns true if the CallingScope indicates the top call.
"
  input CallingScope inCallingScope;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inCallingScope)
    case TOP_CALL() then true; 
    case INNER_CALL() then false; 
  end matchcontinue;
end isTopCall;
end Inst;

