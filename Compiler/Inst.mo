/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
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
 * The OpenModelica software and the Open Source 	Modelica
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

package Inst
" file:	       Inst.mo
  package:     Inst
  description: Model instantiation

  RCS: $Id$
 
  This module is responsible for instantiation of Modelica models. 
  The instantation is the process of instantiating model components, 
  flattening inheritance and generating equations from connect statements.
  The instantiation process takes Modelica AST as defined in SCode and 
  produces variables and equations and algorithms, etc. as defined in DAE.
  
  This module uses \'Lookup\' to lookup classes and variables from the
  environment defined in \'Env\'. It uses \'Connect\' for generating equations from
  connect statements. The type system defined in \'Types\' is used for
  variable instantiation and type . \'Mod\' is used for modifiers and
  merging of modifiers. 
  
  There are basically four different ways/granularities of instantiation.
  1. Using partialInstClassIn which only instantiates class definitions.
     This function is used for looking up class definitions in e.g. packages.
     For example, if looking up the class A.B.C, a new scope is opened and 
     A is partially instantiated in that scope using partialInstClassIn.
 
  2. Function implicit instantiation. is the last argument of type bool to 
     instClassIn. It is needed since instantiation of functions is needed 
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
     instClassIn. 
     This is also needed, when a DAE should not be generated. 
     It is not clear when this is needed, perhaps it can be removed in the 
     future.
  4. Fu"

// public imports
public import Absyn;
public import ClassInf;
public import Connect;
public import ConnectionGraph;
public import DAE;
public import Env;
public import InnerOuter;
public import SCodeUtil;
public import Mod;
public import Prefix;
public import RTOpts;
public import SCode;
public import UnitAbsyn;

// **
// These type aliases are introduced to make the code a little more readable.
// **

public 
type Prefix = Prefix.Prefix "a prefix";

public 
type Mod = DAE.Mod "a modification";

public 
type Ident = DAE.Ident "an identifier";

public 
type Env = Env.Env "an environment";
  
public 
type InstanceHierarchy = InnerOuter.InstHierarchy "an instance hierarchy";

public uniontype CallingScope "
Calling scope is used to determine when unconnected flow variables should be set to zero."
  record TOP_CALL "this is a top call" end TOP_CALL;
  record INNER_CALL "this is an inner call" end INNER_CALL;
end CallingScope;

public type InstDims = list<list<DAE.Subscript>> 
"Changed from list<Subscript> to list<list<Subscript>>. One list for each scope.
 This so when instantiating classes extending from primitive types can collect the dimension of -one- surrounding scope to create type.
 E.g. RealInput p[3]; gives the list {3} for this scope and other lists for outer (in instance hierachy) scopes";

public 
uniontype DimExp "a dimension expresion"
  record DIMINT "the dimension is given by an integer"
    Integer integer "the dimension";
  end DIMINT;

  record DIMEXP "the dimension is given by a subscript or an optional expresion"
    DAE.Subscript subscript "the subscript";
    Option<DAE.Exp> expExpOption "the optional expresion";
  end DIMEXP;
end DimExp;

// protected imports
protected import Algorithm;
protected import Builtin;
protected import Ceval;
protected import DAEUtil;
protected import Debug;
protected import Dump;
protected import Error;
protected import ErrorExt;
protected import Exp;
protected import HashTable;
protected import HashTable5;
protected import Interactive;
protected import Lookup;
protected import MetaUtil;
protected import ModUtil;
protected import OptManager;
protected import Patternm;
protected import Static;
protected import Types;
protected import UnitAbsynBuilder;
protected import UnitChecker;
protected import UnitParserExt;
protected import Util;
protected import Values;
protected import ValuesUtil;
protected import System;
protected import ConnectUtil;
protected import PrefixUtil;
//protected import DAELow;
//protected import CevalScript;

protected function printDimsStr 
"function: printDims
  Print DimExp list to a string"
  input list<DimExp> inDimExpLst;
  output String str;
algorithm 
  str := matchcontinue (inDimExpLst)
    local
      DimExp x;
      list<DimExp> xs;
      String s1,s2;
    case ((x :: xs))
      equation 
        s1 = printDimStr({SOME(x)});
        s2 = printDimsStr(xs);
        str = Util.stringDelimitListNonEmptyElts({s1,s2},",");
      then
        str;
    case ({}) then ""; 
  end matchcontinue;
end printDimsStr;

public function newIdent 
"function: newIdent
  This function creates a new, unique identifer. 
  The same name is never returned twice."
  output DAE.ComponentRef outComponentRef;
  Integer i;
  String is,s;
algorithm 
  i := tick();
  is := intString(i);
  s := stringAppend("__TMP__", is);
  outComponentRef := DAE.CREF_IDENT(s,DAE.ET_OTHER(),{});
end newIdent;

protected function select 
"function: select
  This utility function selects one of two 
  objects depending on a boolean variable."
  input Boolean inBoolean1;
  input Type_a inTypeA2;
  input Type_a inTypeA3;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeA := matchcontinue (inBoolean1,inTypeA2,inTypeA3)
    local Type_a x;
    case (true,x,_) then x; 
    case (false,_,x) then x; 
  end matchcontinue;
end select;

protected function isNotFunction 
"function: isNotFunction 
  This function returns true if the Class is not a function."
  input SCode.Class cls;
  output Boolean res;
algorithm 
  res := SCode.isFunction(cls);
  res := boolNot(res);
end isNotFunction;

public function instantiate 
"function: instantiate
  To instantiate a Modelica program, an initial environment is
  built, containing the predefined types. Then the program is
  instantiated by the function instProgram"
  input Env.Cache inCache;
  input InstanceHierarchy inIH;
  input SCode.Program inProgram;
  output Env.Cache outCache;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDAElist;
  output SCode.Program outProgram;
algorithm 
  (outCache,outIH,outDAElist) := matchcontinue (inCache,inIH,inProgram)
    local
      list<SCode.Class> pnofunc,pfunc,p,p_1;
      list<Env.Frame> env,envimpl,envimpl_1;
      list<String> pfuncnames,pnofuncnames;
      String str1,str2;
      DAE.DAElist lfunc,lnofunc,l;
      Env.Cache cache;
      InstanceHierarchy oIH1, oIH2, iIH;
    case (cache,iIH,p)
      equation 
        // Debug.fprintln("insttr", "instantiate");
        pnofunc = Util.listSelect(p, isNotFunction);
        pfunc = Util.listSelect(p, SCode.isFunction);
        (cache,env) = Builtin.initialEnv(cache);
        // Debug.fprintln("insttr", "Instantiating functions");
        pfuncnames = Util.listMap(pfunc, SCode.className);
        str1 = Util.stringDelimitList(pfuncnames, ", ");
        // Debug.fprint("insttr", "Instantiating functions: ");
        // Debug.fprintln("insttr", str1);
        envimpl = Env.extendFrameClasses(env, p) "pfunc" ;
        (cache,envimpl_1,oIH1,lfunc) = instProgramImplicit(cache, envimpl, iIH, pfunc);
        // Debug.fprint("insttr", "Instantiating other classes: ");
        pnofuncnames = Util.listMap(pnofunc, SCode.className);
        str2 = Util.stringDelimitList(pnofuncnames, ", ");
        // Debug.fprintln("insttr", str2);
        (cache, oIH2, lnofunc) = instProgram(cache, envimpl_1, oIH1, pnofunc);
        l = DAEUtil.joinDaes(lfunc, lnofunc);
        // p_1 = addElaboratedFuncsToProgram(cache,env,p); // stefan
      then
        (cache,oIH2,l,p);
    case (_,_,_)
      equation 
        //Debug.fprintln("failtrace", "Inst.instantiate failed");
      then
        fail();
  end matchcontinue;
end instantiate;

public function instantiateImplicit 
"function: instantiateImplicit
  Implicit instantiation of a program can be used for e.g. code generation
  of functions, since a function must be implicitly instantiated in order to
  generate code from it."
  input Env.Cache inCache;
  input InstanceHierarchy inIH;
  input SCode.Program inProgram;
  output Env.Cache outCache;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDAElist;
algorithm 
  (outCache,outIH,outDAElist) := matchcontinue (inCache,inIH,inProgram)
    local
      list<Env.Frame> env,env_1;
      DAE.DAElist l;
      list<SCode.Class> p;
      Env.Cache cache;
    case (cache,inIH,p)
      equation 
        // Debug.fprintln("insttr", "instantiate_implicit");
        (cache,env) = Builtin.initialEnv(cache);
        env_1 = Env.extendFrameClasses(env, p);
        (cache,_,outIH,l) = instProgramImplicit(cache,env_1,inIH, p);
      then
        (cache,outIH,l);
    case (_,_,_)
      equation 
        //Debug.fprintln("failtrace", "Inst.instantiateImplicit failed");
      then
        fail();
  end matchcontinue;
end instantiateImplicit;

public function instantiateClass 
"function: instantiateClass
  To enable interactive instantiation, an arbitrary class in the program 
  needs to be possible to instantiate. This function performs the same 
  action as instProgram, but given a specific class to instantiate.
  
   First, all the class definitions are added to the environment without 
  modifications, and then the specified class is instantiated in the 
  function instClassInProgram"
	input Env.Cache inCache;
	input InstanceHierarchy inIH;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output Env.Cache outCache;
  output Env outEnv;  
  output InstanceHierarchy outIH;  
  output DAE.DAElist outDAElist;
algorithm 
  (outCache,outEnv,outIH,outDAElist) := matchcontinue (inCache,inIH,inProgram,inPath)
    local
      Absyn.Path cr,path;
      list<Env.Frame> env,env_1,env_2;
      DAE.DAElist dae1,dae,dae2;
      list<SCode.Class> cdecls;
      String name2,n,pathstr,name,cname_str;
      SCode.Class cdef;
      Env.Cache cache;
      InstanceHierarchy ih;
      ConnectionGraph.ConnectionGraph graph;
      DAE.ElementSource source "the origin of the element";
      DAE.FunctionTree funcs;
      list<DAE.Element> daeElts;      
      
    case (cache,ih,{},cr)
      equation 
        Error.addMessage(Error.NO_CLASSES_LOADED, {});
      then
        fail();
        
    case (cache,ih,(cdecls as (_ :: _)),(path as Absyn.IDENT(name = name2))) /* top level class */ 
      equation 
        (cache,env) = Builtin.initialEnv(cache);
        (cache,env_1,ih,dae1) = instClassDecls(cache, env, ih, cdecls, path);
        (cache,env_2,ih,dae2) = instClassInProgram(cache, env_1, ih, cdecls, path);
        // check the models for balancing
        //Debug.fcall2("checkModel", checkModelBalancing, SOME(path), dae1);
        //Debug.fcall2("checkModel", checkModelBalancing, SOME(path), dae2);
        
        // set the source of this element
        source = DAEUtil.addElementSourcePartOfOpt(DAE.emptyElementSource, Env.getEnvPath(env));
        daeElts = DAEUtil.daeElements(dae2); funcs = DAEUtil.daeFunctionTree(dae2);
        dae2 = DAE.DAE({DAE.COMP(name2,daeElts,source)},funcs);
      then
        (cache,env_2,ih,dae2);
        
    case (cache,ih,(cdecls as (_ :: _)),(path as Absyn.QUALIFIED(name = name))) /* class in package */ 
      equation 
        (cache,env) = Builtin.initialEnv(cache);
        pathstr = Absyn.pathString(path);
        (cache,env_1,ih,_) = instClassDecls(cache, env, ih, cdecls, path);
        (cache,(cdef as SCode.CLASS(name = n)),env_2) = Lookup.lookupClass(cache, env_1, path, true);
        (cache,env_2,ih,_,dae,_,_,_,_,graph) = instClass(cache,env_2,ih, UnitAbsynBuilder.emptyInstStore(),DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, cdef, {}, false, TOP_CALL(), ConnectionGraph.EMPTY) "impl";
        // deal with Overconstrained connections
        dae = ConnectionGraph.handleOverconstrainedConnections(graph, dae);
        // check the model for balancing
        //Debug.fcall2("checkModel", checkModelBalancing, SOME(path), dae);
        
        // set the source of this element
        source = DAEUtil.addElementSourcePartOfOpt(DAE.emptyElementSource, Env.getEnvPath(env));
        daeElts = DAEUtil.daeElements(dae); funcs = DAEUtil.daeFunctionTree(dae);
        dae = DAE.DAE({DAE.COMP(pathstr,daeElts,source)},funcs);
      then
        (cache, env_2, ih, dae);
        
    case (cache,ih,cdecls,path) /* error instantiating */ 
      equation 
        cname_str = Absyn.pathString(path);
        Error.addMessage(Error.ERROR_FLATTENING, {cname_str});
      then
        fail();
  end matchcontinue;
end instantiateClass;

public function instantiatePartialClass 
"Author: BZ, 2009-07
 This is a function for instantiating partial 'top' classes.
 It does so by converting the partial class into a non partial class.
 Currently used by: MathCore.modelEquations, CevalScript.checkModel"
  input Env.Cache inCache;
  input InstanceHierarchy inIH;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDAElist;
algorithm 
  (outCache,outEnv,outIH,outDAElist) := matchcontinue (inCache,inIH,inProgram,inPath)
    local
      Absyn.Path cr,path;
      list<Env.Frame> env,env_1,env_2;
      DAE.DAElist dae1,dae;
      list<SCode.Class> cdecls;
      String name2,n,pathstr,name,cname_str;
      SCode.Class cdef;
      Env.Cache cache;
      InstanceHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      list<DAE.Element> daeElts;
      DAE.FunctionTree funcs;
    case (cache,ih,{},cr)
      equation 
        Error.addMessage(Error.NO_CLASSES_LOADED, {});
      then
        fail();
        
    case (cache,ih,(cdecls as (_ :: _)),(path as Absyn.IDENT(name = name2))) /* top level class */ 
      equation 
        (cache,env) = Builtin.initialEnv(cache);
        (cache,env_1,ih,dae1) = instClassDecls(cache, env, ih, cdecls, path);
        cdecls = Util.listMap1(cdecls,SCode.classSetPartial,false);
        (cache,env_2,ih,dae) = instClassInProgram(cache, env_1, ih, cdecls, path);

        // set the source of this element
        source = DAEUtil.addElementSourcePartOfOpt(DAE.emptyElementSource, Env.getEnvPath(env));
        daeElts = DAEUtil.daeElements(dae); funcs = DAEUtil.daeFunctionTree(dae);
        dae = DAE.DAE({DAE.COMP(name2,daeElts,source)},funcs);
      then
        (cache,env_2,ih,dae);
        
    case (cache,ih,(cdecls as (_ :: _)),(path as Absyn.QUALIFIED(name = name))) /* class in package */ 
      equation 
        (cache,env) = Builtin.initialEnv(cache);
        (cache,env_1,ih,_) = instClassDecls(cache, env, ih, cdecls, path);
        (cache,(cdef as SCode.CLASS(name = n)),env_2) = Lookup.lookupClass(cache,env_1, path, true);
        cdef = SCode.classSetPartial(cdef, false);
        (cache,env_2,ih,_,dae,_,_,_,_,_) = 
          instClass(cache, env_2, ih, UnitAbsynBuilder.emptyInstStore(),DAE.NOMOD(), Prefix.NOPRE(), 
                    Connect.emptySet, cdef, {}, false, TOP_CALL(), ConnectionGraph.EMPTY) "impl" ;
        pathstr = Absyn.pathString(path);
        
        // set the source of this element
        source = DAEUtil.addElementSourcePartOfOpt(DAE.emptyElementSource, Env.getEnvPath(env));
        daeElts = DAEUtil.daeElements(dae); funcs = DAEUtil.daeFunctionTree(dae);
        dae = DAE.DAE({DAE.COMP(pathstr,daeElts,source)},funcs);
      then
        (cache,env_2,ih,dae);
        
    case (cache,ih,cdecls,path) /* error instantiating */ 
      equation 
        cname_str = Absyn.pathString(path);
        // print(" Error flattening partial, errors: " +& ErrorExt.printMessagesStr() +& "\n");
        Error.addMessage(Error.ERROR_FLATTENING, {cname_str});
      then
        fail();
  end matchcontinue;
end instantiatePartialClass;

public function instantiateClassImplicit 
"function: instantiateClassImplicit
  author: PA
  Similar to instantiate_class, i.e. instantation of arbitrary classes
  but this one instantiates the class implicit, which is less costly."
  input Env.Cache inCache;
  input InstanceHierarchy inIH;  
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;  
  output DAE.DAElist outDAElist;
algorithm 
  (outCache,outIH,outDAElist,outEnv) := matchcontinue (inCache,inIH,inProgram,inPath)
    local
      Absyn.Path cr,path;
      list<Env.Frame> env,env_1,env_2;
      DAE.DAElist dae1,dae;
      list<SCode.Class> cdecls;
      String name2,n,name;
      SCode.Class cdef;
      Env.Cache cache;
      InstanceHierarchy ih;
      
    case (cache,ih,{},cr)
      equation 
        Error.addMessage(Error.NO_CLASSES_LOADED, {});
      then
        fail();

    case (cache,ih,(cdecls as (_ :: _)),(path as Absyn.IDENT(name = name2))) /* top level class */ 
      equation 
        (cache,env) = Builtin.initialEnv(cache); 
        (cache,env_1,ih,dae1) = instClassDecls(cache, env, ih, cdecls, path);
        (cache,env_2,ih,dae) = instClassInProgramImplicit(cache, env_1, ih, cdecls, path);
      then
        (cache,env_2,ih,dae);

    case (cache,ih,(cdecls as (_ :: _)),(path as Absyn.QUALIFIED(name = name))) /* class in package */ 
      local String s;
      equation
        (cache,env) = Builtin.initialEnv(cache);
        (cache,env_1,ih,_) = instClassDecls(cache, env, ih, cdecls, path);
        (cache,(cdef as SCode.CLASS(name = n)),env_2) = Lookup.lookupClass(cache,env_1, path, true);
        env_2 = Env.extendFrameC(env_2, cdef);
        (cache, env, ih, dae) = implicitInstantiation(cache, env_2, ih, DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, cdef, {});
      then
        (cache,env,ih,dae);

    case (_,_,_,_)
      equation 
        print("-Inst.instantiateClassImplicit failed\n");
      then
        fail();
  end matchcontinue; 
end instantiateClassImplicit;

public function instantiateFunctionImplicit 
"function: instantiateFunctionImplicit
  author: PA
  Similar to instantiateClassImplict, i.e. instantation of arbitrary 
  classes but this one instantiates the class implicit for functions."
  input Env.Cache inCache;
  input InstanceHierarchy inIH;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;  
  output DAE.DAElist outDAElist;
algorithm 
  (outCache,outEnv,outIH,outDAElist) := matchcontinue (inCache,inIH,inProgram,inPath)
    local
      Absyn.Path cr,path;
      list<Env.Frame> env,env_1,env_2;
      DAE.DAElist dae1,dae;
      list<SCode.Class> cdecls;
      String name2,n,name,s;
      SCode.Class cdef;
      Env.Cache cache;
      DAE.DAElist daelst;
      InstanceHierarchy ih;
      
      // Fully qualified paths
    case (cache,ih,cdecls,Absyn.FULLYQUALIFIED(path)) 
      equation
        (cache,env,ih,daelst) = instantiateFunctionImplicit(cache,ih,cdecls,path);
      then       
        (cache,env,ih,daelst);
        
    case (cache,ih,{},cr)
      equation 
        Error.addMessage(Error.NO_CLASSES_LOADED, {});
      then
        fail();
        
    case (cache,ih,(cdecls as (_ :: _)),(path as Absyn.IDENT(name = name2))) /* top level class */ 
      equation 
        (cache,env) = Builtin.initialEnv(cache);        
        (cache,env_1,ih,dae1) = instClassDecls(cache, env, ih, cdecls, path);
        (cache,env_2,ih,dae) = instFunctionInProgramImplicit(cache, env_1, ih, cdecls, path);
      then
        (cache,env_2,ih,dae);
        
    case (cache,ih,(cdecls as (_ :: _)),(path as Absyn.QUALIFIED(name = name))) /* class in package */ 
      equation 
        (cache,env) = Builtin.initialEnv(cache);        
        (cache,env_1,ih,_) = instClassDecls(cache, env, ih, cdecls, path);
        (cache,(cdef as SCode.CLASS(name = n)),env_2) = Lookup.lookupClass(cache,env_1, path, true);
        env_2 = Env.extendFrameC(env_2, cdef);
        (cache,env,ih,dae) = implicitFunctionInstantiation(cache, env_2, ih, DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, cdef, {});
      then
        (cache,env,ih,dae);
        
    case (_,_,_,path)
      equation 
        // print("-instantiateFunctionImplicit ");print(Absyn.pathString(path));print(" failed\n");
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "-Inst.instantiateFunctionImplicit " +& Absyn.pathString(path) +& " failed\n");
      then
        fail();
  end matchcontinue;
end instantiateFunctionImplicit;

protected function instClassInProgram 
"function: instClassInProgram
  Instantitates a specifc class in a Program. 
  The class must reside on top level."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output Env.Cache outCache;
  output Env outEnv;  
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
algorithm 
  (outCache,outEnv,outIH,outDae) := matchcontinue (inCache,inEnv,inIH,inProgram,inPath)
    local
      DAE.DAElist dae, dae2;
      list<Env.Frame> env_1,env;
      SCode.Class c;
      String name,name2;
      list<SCode.Class> cs;
      Absyn.Path path;
      Env.Cache cache;
      InstanceHierarchy ih;
      ConnectionGraph.ConnectionGraph graph;
      
    case (cache,env,ih,((c as SCode.CLASS(name = name)) :: cs),Absyn.IDENT(name = name2))
      equation 
        equality(name = name2);
        (cache,env_1,ih,_,dae,_,_,_,_,graph) = instClass(cache,env, ih, UnitAbsynBuilder.emptyInstStore(), DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, {}, false, TOP_CALL(), ConnectionGraph.EMPTY) "impl" ;
        // deal with Overconstrained connections
        dae = ConnectionGraph.handleOverconstrainedConnections(graph, dae);
        // check the models for balancing
        //Debug.fcall2("checkModel",checkModelBalancing,SOME(inPath),dae);                
      then
        (cache,env_1,ih,dae);
        
    case (cache,env,ih,((c as SCode.CLASS(name = name)) :: cs),(path as Absyn.IDENT(name = name2)))
      equation 
        failure(equality(name = name2));
        (cache,env,ih,dae) = instClassInProgram(cache, env, ih, cs, path);
      then
        (cache,env,ih,dae);
        
    case (cache,env,ih,{},_) then (cache,env,ih,DAEUtil.emptyDae); 
    case (cache,env,ih,_,_) 
      equation
        Debug.fprintln("failtrace", "Inst.instClassInProgram failed"); 
      then fail();

  end matchcontinue;
end instClassInProgram;

protected function instClassInProgramImplicit 
"function: instClassInProgramImplicit
  Instantitates a specifc class in a Program using implicit instatiation.
  The class must reside on top level."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output Env.Cache outCache;
  output Env outEnv;  
  output InstanceHierarchy outIH;  
  output DAE.DAElist outDae;
algorithm 
  (outCache,outEnv,outIH,outDae) := matchcontinue (inCache,inEnv,inIH,inProgram,inPath)
    local
      list<Env.Frame> env_1,env;
      DAE.DAElist dae;
      SCode.Class c;
      String name,name2;
      list<SCode.Class> cs;
      Absyn.Path path;
      Env.Cache cache;
      InstanceHierarchy ih;
      
    case (cache,env,ih,((c as SCode.CLASS(name = name)) :: cs),Absyn.IDENT(name = name2))
      local String s;
      equation 
        equality(name = name2);
        env = Env.extendFrameC(env, c);
        (cache,env_1,ih,dae) = implicitInstantiation(cache,env,ih, DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, {}) ;
      then
        (cache,env_1,ih,dae);
        
    case (cache,env,ih,((c as SCode.CLASS(name = name)) :: cs),(path as Absyn.IDENT(name = name2)))
      equation 
        failure(equality(name = name2));
        (cache,env,ih,dae) = instClassInProgramImplicit(cache, env, ih, cs, path);
      then
        (cache,env,ih,dae);
        
    case (cache,env,ih,{},_) then (cache,env,ih,DAEUtil.emptyDae);
       
    case (_,env,ih,_,_) 
      equation
        Debug.fprint("failtrace", "Inst.instClassInProgramImplicit failed");
      then fail();
  end matchcontinue;
end instClassInProgramImplicit;

protected function instFunctionInProgramImplicit 
"function: instFunctionInProgramImplicit
  Instantitates a specific function in a Program using implicit instatiation.
  The class must reside on top level."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;  
  output DAE.DAElist outDae;
algorithm 
  (outCache,outEnv,outIH,outDae) := matchcontinue (inCache,inEnv,inIH,inProgram,inPath)
    local
      list<Env.Frame> env_1,env;
      DAE.DAElist dae;
      SCode.Class c;
      String name,name2;
      list<SCode.Class> cs;
      Absyn.Path path;
      Env.Cache cache;
      InstanceHierarchy ih;
      
    case (cache,env,ih,((c as SCode.CLASS(name = name)) :: cs),Absyn.IDENT(name = name2))
      local String s;
      equation 
        equality(name = name2);
        env = Env.extendFrameC(env, c);
        (cache,env_1,ih,dae) = implicitFunctionInstantiation(cache,env,ih, DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, {});
      then
        (cache,env_1,ih,dae);

    case (cache,env,ih,((c as SCode.CLASS(name = name)) :: cs),(path as Absyn.IDENT(name = name2)))
      equation 
        failure(equality(name = name2));
        (cache,env,ih,dae) = instFunctionInProgramImplicit(cache,env,ih, cs, path);
      then
        (cache,env,ih,dae);

    case (cache,env,ih,{},_) then (cache,env,ih,DAEUtil.emptyDae); 
    case (cache,env,ih,_,_)  then fail(); 
  end matchcontinue;
end instFunctionInProgramImplicit;

protected function instClassDecls 
"function: instClassDecls
  This function instantiated class definitions, i.e. 
  adding the class definitions to the environment. 
  See also partialInstClassIn."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
algorithm 
  (outCache,outEnv,outIH,outDae) := matchcontinue (inCache,inEnv,inIH,inProgram,inPath)
    local
      list<Env.Frame> env_1,env_2,env;
      DAE.DAElist dae1,dae2,dae;
      SCode.Class c;
      String name,name2,str;
      list<SCode.Class> cs;
      Absyn.Path ref;
      Env.Cache cache;
      InstanceHierarchy ih;
      
    case (cache,env,ih,((c as SCode.CLASS(name = name)) :: cs),(ref as Absyn.IDENT(name = name2)))
      equation 
        failure(equality(name = name2));
        (cache,env_1,ih,dae1) = instClassDecl(cache,env,ih, DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, {}) ;
        (cache,env_2,ih,dae2) = instClassDecls(cache,env_1,ih, cs, ref);
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache,env_2,ih,dae);

    case (cache,env,ih,((c as SCode.CLASS(name = name)) :: cs),(ref as Absyn.IDENT(name = name2)))
      equation 
        equality(name = name2);
        (cache,env_1,ih,dae2) = instClassDecls(cache,env,ih, cs, ref);
      then
        (cache,env_1,ih,dae2);

    case (cache,env,ih,((c as SCode.CLASS(name = name)) :: cs),(ref as Absyn.QUALIFIED(name = name2)))
      equation 
        equality(name = name2);
        (cache,env_1,ih,dae1) = instClassDecl(cache,env,ih, DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, {});
        (cache,env_2,ih,dae2) = instClassDecls(cache,env_1,ih, cs, ref);
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache,env_2,ih,dae);

    case (cache,env,ih,((c as SCode.CLASS(name = name)) :: cs),(ref as Absyn.QUALIFIED(name = name2)))
      equation 
        failure(equality(name = name2));
        (cache,env_1,ih,dae1) = instClassDecl(cache,env,ih, DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, {})  ;
        (cache,env_2,ih,dae2) = instClassDecls(cache,env_1,ih, cs, ref);
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache,env_2,ih,dae);

    case (cache,env,ih,{},_) then (cache,env,ih,DAEUtil.emptyDae); 
    case (_,_,ih,_,ref)
      equation 
        print("Inst.instClassDecls failed\n ref =" +& Absyn.pathString(ref) +& "\n");
      then
        fail();
  end matchcontinue;
end instClassDecls;

public function makeEnvFromProgram 
"function: makeEnvFromProgram
  This function takes a SCode.Program and builds 
  an environment, excluding the class in A1."
	input Env.Cache inCache;
  input SCode.Program prog;
  input SCode.Path c;
  output Env.Cache outCache;
  output Env env_1;
  list<Env.Frame> env,env_1;
  Env.Cache cache;
algorithm 
  (cache,env) := Builtin.initialEnv(inCache);
  (outCache,env_1,_) := addProgramToEnv(cache,env,InnerOuter.emptyInstHierarchy, prog, c);
end makeEnvFromProgram;

public function makeSimpleEnvFromProgram 
"function: makeSimpleEnvFromProgram
  Similar as to makeEnvFromProgram, but not using the complete builtin 
  environment, but a more simple one without the builtin operators.
  See also: Builtin.simpleInitialEnv."
	input Env.Cache inCache;
  input SCode.Program prog;
  input SCode.Path c;
  output Env.Cache outCache;
  output Env env_1;
  list<Env.Frame> env,env_1;
algorithm 
  env := Builtin.simpleInitialEnv();
  (outCache,env_1,_) := addProgramToEnv(inCache,env,InnerOuter.emptyInstHierarchy, prog, c);
end makeSimpleEnvFromProgram;

protected function addProgramToEnv 
"function: addProgramToEnv
  Adds all classes in a Program to the environment."
	input Env.Cache inCache;
  input Env env;
  input InstanceHierarchy inIH;
  input SCode.Program p;
  input SCode.Path path;
  output Env.Cache outCache;
  output Env env_1;
  output InstanceHierarchy outIH;
  list<Env.Frame> env_1;
algorithm 
  (outCache,env_1,outIH,_) := instClassDecls(inCache,env,inIH, p, path);
end addProgramToEnv;

protected function instProgram 
"function: instProgram
  Instantiating a Modelica program is the same as instantiating the
  last class definition in the source file. First all the class
  definitions is added to the environment without modifications, and
  then the last class is instantiated in the function instClass.
  This is used when calling the compiler with a Modelica source code file.
  It is not used in the interactive environment when instantiating a class."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input SCode.Program inProgram;
  output Env.Cache outCache;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
algorithm 
  (outCache,outIH,outDae) := matchcontinue (inCache,inEnv,inIH,inProgram)
    local
      list<Env.Frame> env,env_1;
      DAE.DAElist dae,dae1,dae2;
      Connect.Sets csets;
      SCode.Class c;
      String n, fullPathName;
      list<SCode.Class> cs;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      UnitAbsyn.InstStore store;
      Option<Absyn.Path> containedInOpt;
      Absyn.Path fullPath;
      DAE.ElementSource source "the origin of the element";
      list<DAE.Element> daeElts;
      DAE.FunctionTree funcs;
      
    case (cache,env,ih,{})
      equation 
        Error.addMessage(Error.NO_CLASSES_LOADED, {});
      then
        fail();
        
    case (cache,env,ih,{(c as SCode.CLASS(name = n))})
      equation 
        Debug.fcall("execstat",print, "*** Inst -> enter at time: " +& realString(clock()) +& "\n" );
        // Debug.fprint("insttr", "inst_program1: ");
        // Debug.fprint("insttr", n);
        // Debug.fprintln("insttr", "");
        containedInOpt = Env.getEnvPath(env);
        (cache,env_1,ih,store,dae,csets,_,_,_,graph) = instClass(cache,env,ih,UnitAbsynBuilder.emptyInstStore(), DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, {}, false, TOP_CALL(), ConnectionGraph.EMPTY) ;
        Debug.fcall("execstat",print, "*** Inst -> instClass finished at time: " +& realString(clock()) +& "\n" );
        // deal with Overconstrained connections
        dae = ConnectionGraph.handleOverconstrainedConnections(graph, dae);
        // check the models for balancing
        //Debug.fcall2("checkModel",checkModelBalancing,containedInOpt,dae);
                       
        // set the source of this element
        source = DAEUtil.addElementSourcePartOfOpt(DAE.emptyElementSource, Env.getEnvPath(env));
        
        // finish with the execution statistics        
        Debug.fcall("execstat",print, "*** Inst -> exit at time: " +& realString(clock()) +& "\n" );
  
        daeElts = DAEUtil.daeElements(dae); funcs = DAEUtil.daeFunctionTree(dae);
        dae = DAE.DAE({DAE.COMP(n,daeElts,source)},funcs);
      then
        (cache,ih,dae);
        
    case (cache,env,ih,(c :: (cs as (_ :: _))))
         local String str;
      equation  
        // Debug.fprintln("insttr", "inst_program2");
        (cache,env_1,ih,dae1) = instClassDecl(cache,env,ih, DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, {}) ;
        //str = SCode.printClassStr(c); print("------------------- CLASS instProgram-----------------\n");print(str);print("\n===============================================\n");
        //str = Env.printEnvStr(env_1);print("------------------- env instProgram 1-----------------\n");print(str);print("\n===============================================\n");
        (cache,ih,dae2) = instProgram(cache,env_1,ih, cs) "Env.extend_frame_c(env,c) => env\' &" ;
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache,ih,dae);
        
    case (_,_,ih,_)
      equation 
        //Debug.fprintln("failtrace", "- Inst.instProgram failed");
      then
        fail();
        
  end matchcontinue;
end instProgram;

protected function instProgramImplicit 
"function: instProgramImplicit
  Instantiates a program using implicit instantiation.
  Used when instantiating functions."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input SCode.Program inProgram;
  output Env.Cache outCache;
  output Env outEnv;  
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
algorithm 
  (outCache,outEnv,outIH,outDae) := matchcontinue (inCache,inEnv,inIH,inProgram)
    local
      list<Env.Frame> env_1,env_2,env;
      DAE.DAElist dae1,dae2,dae;
      SCode.Class c;
      String n;
      SCode.Restriction restr;
      list<SCode.Class> cs;
      Env.Cache cache;
      InstanceHierarchy ih;
      
    case (cache,env,ih,((c as SCode.CLASS(name = n,restriction = restr)) :: cs))
      local String s;
      equation 
        // Debug.fprint("insttr", "inst_program_implicit: ");
        // Debug.fprint("insttr", n);
        // Debug.fprintln("insttr", "");
        env = Env.extendFrameC(env, c);
        (cache,env_1,ih,dae1) = implicitInstantiation(cache,env,ih, DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, {});
        (cache,env_2,ih,dae2) = instProgramImplicit(cache,env_1,ih, cs);
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache,env_2,ih,dae);
        
    case (cache,env,ih,{})
      equation 
        // Debug.fprintln("insttr", "Inst.instProgramImplicit (end)");
      then
        (cache,env,ih,DAEUtil.emptyDae);
  end matchcontinue;
end instProgramImplicit;

public function instClass "function: instClass
  Instantiation of a class can be either implicit or normal. 
  This function is used in both cases. When implicit instantiation 
  is performed, the last argument is true, otherwise it is false.
  
  Instantiating a class consists of the following steps:
   o Create a new frame on the environment
   o Initialize the class inference state machine
   o Instantiate all the elements and equations
   o Generate equations from the connection sets built during instantiation"
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input UnitAbsyn.InstStore store;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input SCode.Class inClass;
  input InstDims inInstDims;
  input Boolean inBoolean;
  input CallingScope inCallingScope;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache cache;
  output Env outEnv;
  output InstanceHierarchy outIH;  
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output DAE.Type outType;
  output ClassInf.State outState;
  output Option<Absyn.ElementAttributes> optDerAttr;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outStore,outDae,outSets,outType,outState,optDerAttr,outGraph):=
  matchcontinue (inCache,inEnv,inIH,store,inMod,inPrefix,inSets,inClass,inInstDims,inBoolean,inCallingScope,inGraph)
    local
      list<Env.Frame> env,env_1,env_3,env_4;
      DAE.Mod mod;
      Prefix.Prefix pre;
      Connect.Sets csets,csets_1;
      String n;
      Boolean partialPrefix,impl,callscope_1,encflag,isFn,notIsPartial,isPartialFn;
      ClassInf.State ci_state,ci_state_1;
      DAE.DAElist dae1,dae1_1,dae2,dae3,dae;
      list<DAE.ComponentRef> crs;
      list<DAE.Var> tys;
      Option<tuple<DAE.TType, Option<Absyn.Path>>> bc_ty;
      Absyn.Path fq_class,typename;
      list<DAE.Type> functionTypes;      
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      SCode.Class c;
      SCode.Restriction r;
      InstDims inst_dims;
      CallingScope callscope;
      Env.Cache cache;
      list<Connect.OuterConnect> oc;
      Option<Absyn.ElementAttributes> oDA;
      String str;
      list<DAE.ComponentRef> dc;
      ConnectionGraph.ConnectionGraph graph; 
      InstanceHierarchy ih;
      DAE.EqualityConstraint equalityConstraint; 
      
    /* Instantiation of a class. Create new scope and call instClassIn.
     *  Then generate equations from connects.
     */
    case (cache,env,ih,store,mod,pre,csets,
          (c as SCode.CLASS(name = n,encapsulatedPrefix = encflag,restriction = r, partialPrefix = partialPrefix)),
          inst_dims,impl,callscope,graph)
      equation 
        // print("---- CLASS: "); print(n);print(" ----\n"); print(SCode.printClassStr(c)); //Print out the input SCode class
        // str = SCode.printClassStr(c); print("------------------- CLASS instClass-----------------\n");print(str);print("\n===============================================\n");
        
        // First check if the class is non-partial or a partial function
        isFn = SCode.isFunctionOrExtFunction(r);
        notIsPartial = not partialPrefix;
        isPartialFn = isFn and partialPrefix;
        true = notIsPartial or isPartialFn;
        
        env_1 = Env.openScope(env, encflag, SOME(n));
        
        ci_state = ClassInf.start(r,Env.getEnvName(env_1));
        (cache,env_3,ih,store,dae1,(csets_1 as Connect.SETS(_,crs,dc,oc)),ci_state_1,tys,bc_ty,oDA,equalityConstraint, graph) 
        			= instClassIn(cache, env_1, ih, store, mod, pre, csets, ci_state, c, false, inst_dims, impl, graph,NONE) ;
        (cache,fq_class) = makeFullyQualified(cache,env, Absyn.IDENT(n));
				// str = Absyn.pathString(fq_class); print("------------------- CLASS makeFullyQualified instClass-----------------\n");print(n); print("  ");print(str);print("\n===============================================\n");
        dae1_1 = DAEUtil.addComponentType(dae1, fq_class);
        callscope_1 = isTopCall(callscope);
        reportUnitConsistency(callscope_1,store);
        //print("in class ");print(n);print(" generate equations for sets:");print(Connect.printSetsStr(csets_1));print("\n");
        InnerOuter.checkMissingInnerDecl(dae1_1,callscope_1);
        (csets_1,_) = InnerOuter.retrieveOuterConnections(cache,env_3,ih,pre,csets_1,callscope_1);
        // print("updated sets: ");print(Connect.printSetsStr(csets_1));print("\n");        
        dae2 = ConnectUtil.equations(csets_1,pre);
        (cache,dae3) = ConnectUtil.unconnectedFlowEquations(cache, csets_1, dae1, env_3, pre, callscope_1, {});
        dae1_1 = updateTypesInUnconnectedConnectors(dae3,dae1_1);
        dae = DAEUtil.joinDaeLst({dae1_1,dae2,dae3});
        ty = mktype(fq_class, ci_state_1, tys, bc_ty, equalityConstraint, c); 
        // update Enumerationtypes in environment
        // (cache,env_4) = updateEnumerationEnvironment(cache,env_3,ty,c,ci_state_1);      
        // print("\n---- DAE ----\n"); DAE.printDAE(DAE.DAE(dae));  //Print out flat modelica
        dae = InnerOuter.renameUniqueVarsInTopScope(callscope_1,dae);
        dae = updateDeducedUnits(callscope_1,store,dae);
        
        // Fix the problems with fixing MetaModelica Uniontypes right by the source.
        // Also fixes partial functions.
        ty = fixInstClassType(c,ty,isPartialFn);
      then 
        (cache,env_3,ih,store,dae,Connect.SETS({},crs,dc,oc),ty,ci_state_1,oDA,graph);

      /*  Classes with the keyword partial can not be instantiated. They can only be inherited */ 
    case (cache,env,ih,store,mod,pre,csets,SCode.CLASS(name = n,partialPrefix = (partialPrefix as true)),_,(impl as false),_,graph)
      equation
        Error.addMessage(Error.INST_PARTIAL_CLASS, {n});        
      then
        fail();
        
    case (_,_,ih,_,_,_,_,SCode.CLASS(name = n),_,impl,_,graph)
      equation 
        Debug.fprintln("failtrace", "- Inst.instClass: " +& n +& " failed");
      then
        fail();
  end matchcontinue; 
end instClass;

protected function fixInstClassType
"Fixes the type of a class if it is uniontype or function reference.
These are MetaModelica extensions."
  input SCode.Class cl;
  input DAE.Type ty;
  input Boolean isPartialFn;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (cl,ty,isPartialFn)
    local
      list<SCode.Element> els;
      list<Absyn.Path> pathLst;
      list<String> slst;
      Absyn.Path p;
      DAE.Type t;
    case (_,ty,true) then Types.makeFunctionPolymorphicReference(ty);
    case (SCode.CLASS(classDef = SCode.PARTS(elementLst = els), restriction = SCode.R_UNIONTYPE),(_,SOME(p)),false)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        slst = MetaUtil.getListOfStrings(els);
        pathLst = Util.listMap1r(slst, Absyn.pathReplaceIdent, p);
        t = (DAE.T_UNIONTYPE(pathLst),SOME(p));
      then t;
    case (_,ty,false) then ty;
  end matchcontinue;
end fixInstClassType;

protected function updateEnumerationEnvironment
	input Env.Cache inCache;
  input Env inEnv;
  input tuple<DAE.TType, Option<Absyn.Path>> inType;
  input SCode.Class inClass;
  input ClassInf.State inCi_State;
	output Env.Cache outCache;
  output Env outEnv;
algorithm
  (outCache,outEnv) := matchcontinue(inCache,inEnv,inType,inClass,inCi_State)
  local
    Env.Cache cache;
    Env env,env_1;
    tuple<DAE.TType, Option<Absyn.Path>> ty;
    SCode.Class c;
    ClassInf.State ci_state;
    String name;
    list<String> names;
    list<DAE.Var> vars;
    Absyn.Path p,pname;
    case (cache,env,ty as ((DAE.T_ENUMERATION(NONE(),_,names,vars)),SOME(p)),c,ClassInf.ENUMERATION(pname)) 
      equation
        (cache,env_1) = updateEnumerationEnvironment1(cache,env,Absyn.pathString(pname),names,vars,p);
      then
       (cache,env_1);
    case (cache,env,ty,c,_) then (cache,env);
  end matchcontinue;  
end updateEnumerationEnvironment;

protected function updateEnumerationEnvironment1
	input Env.Cache inCache;
  input Env inEnv;
  input Absyn.Ident inName;
  input list<String> inNames;
  input list<DAE.Var> inVars;
  input Absyn.Path inPath;
	output Env.Cache outCache;
  output Env outEnv;
algorithm
  (outCache,outEnv) := matchcontinue(inCache,inEnv,inName,inNames,inVars,inPath)
  local
    Env.Cache cache;
    Env env,env_1,env_2,env_3,compenv;
    String name,n,nn;
    list<String> names;
    list<DAE.Var> vars;
    DAE.Var var, outVar, new_var;
    DAE.Type ty;
    Option<tuple<SCode.Element, DAE.Mod>> outTplSCodeElementTypesModOption;
    Env.InstStatus instStatus;
    Absyn.Path p;
    DAE.Ident name;
    DAE.Attributes attributes;
    Boolean protected_;
    DAE.Binding binding;
    case (cache,env,name,nn::names,(var as DAE.TYPES_VAR(_,_,_,ty,_))::vars,p) 
      equation
        // get Var
        (cache,DAE.TYPES_VAR(name,attributes,protected_,_,binding),outTplSCodeElementTypesModOption,instStatus,compenv)  = Lookup.lookupIdentLocal(cache,env, nn);
        // change type
        new_var = DAE.TYPES_VAR(name,attributes,protected_,ty,binding);
        // update
         env_1 = Env.updateFrameV(env, new_var, Env.VAR_DAE(), compenv)  ;
        // next
        (cache,env_2) = updateEnumerationEnvironment1(cache,env_1,name,names,vars,p); 
      then
       (cache,env_2);
    case (cache,env,_,{},_,_) then (cache,env);
  end matchcontinue;  
end updateEnumerationEnvironment1;

protected function updateDeducedUnits "updates the deduced units in each DAE.VAR"
  input Boolean callScope;
  input UnitAbsyn.InstStore store;
  input DAE.DAElist dae;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue(callScope,store,dae)
  local UnitAbsyn.Store st; HashTable.HashTable ht; Integer indx;
    Option<UnitAbsyn.Unit>[:] vec;
    String unitStr;
    UnitAbsyn.Unit unit;
    Option<DAE.VariableAttributes> varOpt;
    DAE.Element elt,v;
    DAE.FunctionTree funcs;
    list<DAE.Element> elts;
    case(false,_,dae) then dae;
    
      /* Only traverse on top scope */
    case(true,store as UnitAbsyn.INSTSTORE(UnitAbsyn.STORE(vec,_),ht,_),DAE.DAE((v as DAE.VAR(variableAttributesOption=varOpt as SOME(DAE.VAR_ATTR_REAL(unit = NONE))))::elts,funcs)) equation
      indx = HashTable.get(DAEUtil.varCref(v),ht);
      SOME(unit) = vec[indx];
      unitStr = UnitAbsynBuilder.unit2str(unit);
      varOpt = DAEUtil.setUnitAttr(varOpt,DAE.SCONST(unitStr));
      v = DAEUtil.setVariableAttributes(v,varOpt);
      DAE.DAE(elts,_)= updateDeducedUnits(true,store,DAE.DAE(elts,funcs));
      then DAE.DAE(v::elts,funcs);
      
    case(true,store,DAE.DAE(elt::elts,funcs)) equation
      DAE.DAE(elts,_) = updateDeducedUnits(true,store,DAE.DAE(elts,funcs));
    then DAE.DAE(elt::elts,funcs);
    case(true,store,DAE.DAE({},funcs)) then DAE.DAE({},funcs);
      
  end matchcontinue;
end updateDeducedUnits;

protected function reportUnitConsistency "reports CONSISTENT or INCOMPLETE error message depending on content of store"
  input Boolean topScope;
  input UnitAbsyn.InstStore store;
algorithm
  _ := matchcontinue(topScope,store)
  local Boolean complete; UnitAbsyn.Store st;
    case(_,_) equation
      false = OptManager.getOption("unitChecking");
    then ();
    case(true,UnitAbsyn.INSTSTORE(st,_,SOME(UnitAbsyn.CONSISTENT()))) equation
      (complete,_) = UnitChecker.isComplete(st);
      Error.addMessage(Util.if_(complete,Error.CONSISTENT_UNITS,Error.INCOMPLETE_UNITS),{});          
    then();
    case(_,_) then ();
      
  end matchcontinue;
end reportUnitConsistency;

protected function extractConnectorPrefix "
Author: BZ, 2009-09 
Extract the part before the conector ex: a.b.c.connector_d.e would return a.b.c
"
input DAE.ComponentRef connectorRef;
output DAE.ComponentRef prefixCon;
algorithm prefixCon := matchcontinue(connectorRef)
  local
    DAE.ComponentRef child;
    String name; 
    list<DAE.Subscript> subs;
    DAE.ExpType ty;
    
  case(DAE.CREF_IDENT(name,_,_)) // If the bottom var is a connector, then it is not an outside connector. (spec 0.1.2)
    /*equation print(name +& " is not a outside connector \n");*/
    then fail();
      
  case(DAE.CREF_QUAL(name,(ty as DAE.ET_COMPLEX(complexClassType=ClassInf.CONNECTOR(_,_))),subs,_))
    then DAE.CREF_IDENT(name,ty,subs);
      
  case(DAE.CREF_QUAL(name,ty,subs,child))
    equation
      child = extractConnectorPrefix(child); 
    then 
      DAE.CREF_QUAL(name,ty,subs,child);
      
end matchcontinue;
end extractConnectorPrefix;

protected function updateTypesInUnconnectedConnectors "
Author: BZ, 2009-09
Given a set of zeroequations (unconnected flow variables) and the subset dae containing flow-variable declaration:
Set same type to variable as the equations have.
Note: This is a hack to readd the typing of the variables. 
"
  input DAE.DAElist zeroEqnDae;
  input DAE.DAElist fullDae;
  output DAE.DAElist outdae;
algorithm outdae := matchcontinue(zeroEqnDae,fullDae)
  local
    DAE.Element ze;
    DAE.Exp e;
    DAE.ComponentRef cr;
    list<DAE.Element> zeroEqns;
    DAE.FunctionTree funcs;
  case(DAE.DAE({},_),fullDae) then fullDae;
  case(_, DAE.DAE({},_)) equation print(" error in updateTypesInUnconnectedConnectors\n"); then fail();
  case(DAE.DAE((ze as DAE.EQUATION(exp = (e as DAE.CREF(cr,_))))::zeroEqns,funcs), fullDae)
    equation
      // print(Exp.printComponentRefStr(cr));
      cr = extractConnectorPrefix(cr);
      // print(" ===> " +& Exp.printComponentRefStr(cr) +& "\n");
      fullDae = updateTypesInUnconnectedConnectors2(cr,fullDae);
      fullDae = updateTypesInUnconnectedConnectors(DAE.DAE(zeroEqns,funcs),fullDae);
    then
      fullDae;
  case(DAE.DAE((ze as DAE.EQUATION(scalar = (e as DAE.CREF(cr,_))))::zeroEqns,funcs), fullDae)
    equation
      // print(Exp.printComponentRefStr(cr));
      cr = extractConnectorPrefix(cr); 
      // print(" ===> " +& Exp.printComponentRefStr(cr) +& "\n");
      fullDae = updateTypesInUnconnectedConnectors2(cr,fullDae);
      fullDae = updateTypesInUnconnectedConnectors(DAE.DAE(zeroEqns,funcs),fullDae);
    then
      fullDae;
  case(DAE.DAE((ze as DAE.EQUATION(exp = (e as DAE.CREF(cr,_))))::zeroEqns,funcs), fullDae)
    equation
      failure(cr = extractConnectorPrefix(cr));
      // print("Var is not a outside connector: " +& Exp.printComponentRefStr(cr));
      fullDae = updateTypesInUnconnectedConnectors(DAE.DAE(zeroEqns,funcs),fullDae);
    then
      fullDae;
  case(DAE.DAE((ze as DAE.EQUATION(scalar = (e as DAE.CREF(cr,_))))::zeroEqns,funcs), fullDae)
    equation
      failure(cr = extractConnectorPrefix(cr)); 
      // print("Var is not a outside connector: " +& Exp.printComponentRefStr(cr));
      fullDae = updateTypesInUnconnectedConnectors(DAE.DAE(zeroEqns,funcs),fullDae);
    then
      fullDae;
  case(_,_) equation print(" ERROR -- updateTypesInUnconnectedConnectors\n"); then fail();
  end matchcontinue;
end updateTypesInUnconnectedConnectors;

protected function updateTypesInUnconnectedConnectors2 "
Author: BZ, 2009-09
Helper function for updateTypesInUnconnectedConnectors
"
input DAE.ComponentRef inCr;
input DAE.DAElist elems; 
output DAE.DAElist outelems;
algorithm outelems := matchcontinue(inCr, elems)
  local
    DAE.ComponentRef cr1,cr2;
    DAE.Element elem,elem2;
    DAE.FunctionTree funcs;
    list<DAE.Element> elts;
  case(cr1,DAE.DAE({},funcs))
    equation 
      // print("error updateTypesInUnconnectedConnectors2\n");
      // print(" no match for: " +& Exp.printComponentRefStr(cr1) +& "\n"); 
    then 
      DAE.DAE({},funcs);
  case(inCr,DAE.DAE((elem2 as DAE.VAR(componentRef = cr2))::elts,funcs))
    equation
      true = Exp.crefPrefixOf(inCr,cr2);
      // print(" Found: " +& Exp.printComponentRefStr(cr2) +& "\n");
      cr1 = updateCrefTypesWithConnectorPrefix(inCr,cr2);
      elem = DAEUtil.replaceCrefInVar(cr1,elem2);
      // print(" replaced to: " ); print(DAE.dump2str(DAE.DAE({elem}))); print("\n");
      DAE.DAE(elts,funcs) = updateTypesInUnconnectedConnectors2(inCr, DAE.DAE(elts,funcs));      
    then
      DAE.DAE(elem::elts,funcs);
  case(cr1,DAE.DAE(elem2::elts,funcs))
    equation
      DAE.DAE(elts,funcs) = updateTypesInUnconnectedConnectors2(cr1, DAE.DAE(elts,funcs));
    then
      DAE.DAE(elem2::elts,funcs);
  case(_,_) equation print(" ERROR updateTypesInUnconnectedConnectors2\n"); then fail();
  end matchcontinue;
end updateTypesInUnconnectedConnectors2;

protected function updateCrefTypesWithConnectorPrefix "
Author: BZ, 2009-09
Helper function for updateTypesInUnconnectedConnectors2
"
input DAE.ComponentRef cr1,cr2;
output DAE.ComponentRef outCref;
algorithm outCref := matchcontinue(cr1,cr2)
  local
    String name,name2;
    DAE.ComponentRef child,child2;
    DAE.ExpType ty;
    list<DAE.Subscript> subs;
  case(DAE.CREF_IDENT(name,ty,subs),DAE.CREF_QUAL(name2,_,_,child2))
    equation
      true = stringEqual(name,name2);
    then
      DAE.CREF_QUAL(name,ty,subs,child2);
      
  case(DAE.CREF_QUAL(name,ty,subs,child),DAE.CREF_QUAL(name2,_,_,child2))
    equation
      true = stringEqual(name,name2);
      outCref = updateCrefTypesWithConnectorPrefix(child,child2);
    then
      DAE.CREF_QUAL(name,ty,subs,outCref);
  case(cr1,cr2)
    equation
      print(" ***** FAILURE with " +& Exp.printComponentRefStr(cr1) +& " _and_ " +& Exp.printComponentRefStr(cr2) +& "\n");
      then
        fail();
  end matchcontinue;
end updateCrefTypesWithConnectorPrefix;

protected function instClassBasictype 
"function: instClassBasictype
  author: PA
  This function instantiates a basictype class, e.g. Real, Integer, Real[2],
  etc. This function has the same functionality as instClass except that
  it will create array types when needed. (instClass never creates array
  types). This is needed because this function is used to instantiate classes
  extending from basic types. See instBasictypeBaseclass.
  NOTE: This function should only be called from instBasictypeBaseclass.
  This is new functionality in Modelica v 2.2."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input UnitAbsyn.InstStore store;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input SCode.Class inClass;
  input InstDims inInstDims;
  input Boolean inBoolean;
  input CallingScope inCallingScope;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;  
  output Connect.Sets outSets;
  output DAE.Type outType;
  output list<DAE.Var>  outTypeVars "attributes of builtin types";
  output ClassInf.State outState;
algorithm 
  (outCache,outIH,outEnv,outStore,outDae,outSets,outType,outTypeVars,outState):=
  matchcontinue (inCache,inEnv,inIH,store,inMod,inPrefix,inSets,inClass,inInstDims,inBoolean,inCallingScope)
    local
      list<Env.Frame> env_1,env_3,env;
      ClassInf.State ci_state,ci_state_1;
      SCode.Class c_1,c;
      DAE.DAElist dae1,dae1_1,dae2,dae3,dae;
      Connect.Sets csets_1,csets;
      list<DAE.ComponentRef> crs;
      list<DAE.Var> tys;
      Option<tuple<DAE.TType, Option<Absyn.Path>>> bc_ty;
      Absyn.Path fq_class,typename;
      Boolean callscope_1,encflag,impl;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Mod mod;
      Prefix.Prefix pre;
      String n;
      SCode.Restriction r;
      InstDims inst_dims;
      CallingScope callscope;
      list<DAE.ComponentRef> dc;
      list<Connect.OuterConnect> oc;
      Env.Cache cache;
      InstanceHierarchy ih;
    case (cache,env,ih,store,mod,pre,csets,(c as SCode.CLASS(name = n,encapsulatedPrefix = encflag,restriction = r)),inst_dims,impl,callscope) /* impl */
      equation 
        env_1 = Env.openScope(env, encflag, SOME(n));
        ci_state = ClassInf.start(r, Env.getEnvName(env_1));
        c_1 = SCode.classSetPartial(c, false);
        (cache,env_3,ih,store,dae1,(csets_1 as Connect.SETS(_,crs,dc,oc)),ci_state_1,tys,bc_ty,_,_,_) 
        = instClassIn(cache,env_1,ih,store, mod, pre, csets, ci_state, c_1, false, inst_dims, impl, ConnectionGraph.EMPTY,NONE);
        (cache,fq_class) = makeFullyQualified(cache,env_3, Absyn.IDENT(n));
        dae1_1 = DAEUtil.addComponentType(dae1, fq_class);
        callscope_1 = isTopCall(callscope);
        dae2 = ConnectUtil.equations(csets_1,pre);
        (cache,dae3) = ConnectUtil.unconnectedFlowEquations(cache,csets_1, dae1, env_3, pre,callscope_1,{});
        dae = DAEUtil.joinDaes(dae1_1,DAEUtil.joinDaes(dae2,dae3));
        /*
        (cache,typename) = makeFullyQualified(cache,env_3, Absyn.IDENT(n));
        ty = mktypeWithArrays(typename, ci_state_1, tys, bc_ty);
        */
        ty = mktypeWithArrays(fq_class, ci_state_1, tys, bc_ty, c);
      then
        (cache,env_3,ih,store,dae,Connect.SETS({},crs,dc,oc),ty,tys,ci_state_1);
        
    case (_,_,ih,_,_,_,_,SCode.CLASS(name = n),_,impl,_)
      equation 
        //Debug.fprintln("failtrace", "- Inst.instClassBasictype: " +& n +& " failed");
      then
        fail();
  end matchcontinue;
end instClassBasictype;

public function instClassIn 
"function: instClassIn 
  This rule instantiates the contents of a class definition, with a new 
  environment already setup.
  The *implicitInstantiation* boolean indicates if the class should be 
  instantiated implicit, i.e. without generating DAE.
  The last option is a even stronger indication of implicit instantiation, 
  used when looking up variables in packages. This must be used because 
  generation of functions in implicit instanitation (according to 
  *implicitInstantiation* boolean) can cause circular dependencies 
  (e.g. if a function uses a constant in its body)"
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input UnitAbsyn.InstStore store;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.Class inClass;
  input Boolean isProtected;
  input InstDims inInstDims;
  input Boolean implicitInstantiation;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Option<DAE.ComponentRef> instSingleCref;
	output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output UnitAbsyn.InstStore outStore;  
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output list<DAE.Var> outTypesVarLst;
  output Option<DAE.Type> outTypesTypeOption;
  output Option<Absyn.ElementAttributes> optDerAttr;
  output DAE.EqualityConstraint outEqualityConstraint;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outStore,outDae,outSets,outState,outTypesVarLst,outTypesTypeOption,optDerAttr,outEqualityConstraint,outGraph):=
  matchcontinue (inCache,inEnv,inIH,store,inMod,inPrefix,inSets,inState,inClass,isProtected,inInstDims,implicitInstantiation,inGraph,instSingleCref)
    local
      Option<tuple<DAE.TType, Option<Absyn.Path>>> bc;
      list<Env.Frame> env,env_1;
      DAE.Mod mods;
      Prefix.Prefix pre;
      list<DAE.ComponentRef> crs;
      ClassInf.State ci_state,ci_state_1;
      SCode.Class c,cls;
      InstDims inst_dims;
      Boolean impl,prot;
      String clsname,implstr,n;
      DAE.DAElist dae;
      Connect.Sets csets_1,csets;
      list<DAE.Var> tys;
      SCode.Restriction r;
      SCode.ClassDef d;
      Env.Cache cache;
      list<DAE.ComponentRef> dc;
      Real t1,t2,time; Boolean b;
      list<Connect.OuterConnect> oc;
      Option<Absyn.ElementAttributes> oDA;
      DAE.EqualityConstraint equalityConstraint;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      InstHashTable instHash;
      tuple<Env.Cache, Env, InstanceHierarchy, UnitAbsyn.InstStore, Mod, Prefix, 
            Connect.Sets, ClassInf.State, SCode.Class, Boolean, InstDims, Boolean, 
            ConnectionGraph.ConnectionGraph, Option<DAE.ComponentRef>> inputs;
      tuple<Env.Cache, Env, InstanceHierarchy, UnitAbsyn.InstStore, DAE.DAElist, 
            Connect.Sets, ClassInf.State, list<DAE.Var>, Option<DAE.Type>, 
            Option<Absyn.ElementAttributes>, DAE.EqualityConstraint, 
            ConnectionGraph.ConnectionGraph> outputs;
      Absyn.Path fullEnvPathPlusClass;
      Option<Absyn.Path> envPathOpt;
      String className;
      
      Mod aa_1; 
      Prefix aa_2; 
      Connect.Sets aa_3; 
      ClassInf.State aa_4;
      SCode.Class aa_5; 
      Boolean aa_6; 
      InstDims aa_7;
      Boolean aa_8; 
      Option<DAE.ComponentRef> aa_9;
      replaceable type Type_a subtypeof Any;
      Type_a bbx, bby;
      CachedInstItem partialFunc;
      
    /* Partial packages can sometimes be instantiated here, but should really be done in partialInstClass, since
     * it filters out a lot of things. */
    case (cache,env,ih,store,mods,pre,csets,ci_state,c as SCode.CLASS(restriction = SCode.R_PACKAGE(), partialPrefix = true),prot,inst_dims,impl,graph,instSingleCref) 
      equation
        (cache,env,ih,ci_state) = partialInstClassIn(cache, env, ih, mods, pre, csets, ci_state, c, prot, inst_dims);
      then (cache,env,ih,store,DAEUtil.emptyDae,csets,ci_state,{},NONE,NONE,NONE,graph);
        
    /*  see if we have it in the cache */ 
    case (cache,env,ih,store,mods,pre,csets,ci_state,c,prot,inst_dims,impl,graph,instSingleCref) 
      equation 
        false = RTOpts.debugFlag("noCache");
        instHash = System.getFromRoots(0);
        envPathOpt = Env.getEnvPath(inEnv);
        className = SCode.className(c);
        fullEnvPathPlusClass = Absyn.selectPathsOpt(envPathOpt, Absyn.IDENT(className));        
        {SOME(FUNC_instClassIn(inputs, outputs)),_} = get(fullEnvPathPlusClass, instHash);
        (_, _, _, _, aa_1, aa_2, aa_3, aa_4, aa_5, _, aa_7, aa_8, _, aa_9) = inputs;
        // are the important inputs the same??
        bbx = (aa_1, aa_2, aa_3, aa_4, aa_5, aa_7, aa_8, aa_9);
        bby = (mods,pre,csets, ci_state,c,inst_dims,impl,instSingleCref);
        equality(bbx = bby);
        (cache,env,ih,store,dae,csets_1,ci_state,tys,bc,oDA,equalityConstraint,graph) = outputs;
        // Debug.fprintln("cache", "IIII->got from instCache: " +& Absyn.pathString(fullEnvPathPlusClass));
      then
        (inCache,env,ih,store,dae,csets_1,ci_state,tys,bc,oDA,equalityConstraint,graph);
        
    /* call the function and then add it in the cache */
    case (cache,env,ih,store,mods,pre,csets,ci_state,c as SCode.CLASS(restriction=r),prot,inst_dims,impl,graph,instSingleCref) 
      equation 
        (cache,env,ih,store,dae,csets,ci_state,tys,bc,oDA,equalityConstraint,graph) = 
           instClassIn_dispatch(inCache,inEnv,inIH,store,inMod,inPrefix,inSets,inState,inClass,isProtected,inInstDims,implicitInstantiation,inGraph,instSingleCref);

        envPathOpt = Env.getEnvPath(inEnv);
        className = SCode.className(c);
        fullEnvPathPlusClass = Absyn.selectPathsOpt(envPathOpt, Absyn.IDENT(className));
        
        inputs = (inCache,inEnv,inIH,store,inMod,inPrefix,inSets,inState,inClass,isProtected,inInstDims,implicitInstantiation,inGraph,instSingleCref);
        outputs = (cache,env,ih,store,dae,csets,ci_state,tys,bc,oDA,equalityConstraint,graph); 
        
        addToInstCache(fullEnvPathPlusClass,
           SOME(FUNC_instClassIn( // result for full instantiation
             inputs,
             outputs)),
           /* 
           SOME(FUNC_partialInstClassIn( // result for partial instantiation
             (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inClass,isProtected,inInstDims),
             (cache,env,ih,ci_state)))*/ NONE());
        // Debug.fprintln("cache", "IIII->added to instCache: " +& Absyn.pathString(fullEnvPathPlusClass));        
        //checkModelBalancingFilterByRestriction(r, envPathOpt, dae);
      then
        (cache,env,ih,store,dae,csets,ci_state,tys,bc,oDA,equalityConstraint,graph);        
    
    // failure
    case (cache,env,ih,store,mods,pre,csets,ci_state,(c as SCode.CLASS(name = n,restriction = r,classDef = d)),prot,inst_dims,impl,graph,_)
      equation 
        // print("instClassIn(");print(n);print(") failed\n");
        Debug.fprintln("insttr", "- Inst.instClassIn failed on class:" +& 
           n +& " in environment: " +& Env.printEnvPathStr(env));
      then
        fail();
  end matchcontinue;
end instClassIn;

public function instClassIn_dispatch 
"function: instClassIn 
  This rule instantiates the contents of a class definition, with a new 
  environment already setup.
  The *implicitInstantiation* boolean indicates if the class should be 
  instantiated implicit, i.e. without generating DAE.
  The last option is a even stronger indication of implicit instantiation, 
  used when looking up variables in packages. This must be used because 
  generation of functions in implicit instanitation (according to 
  *implicitInstantiation* boolean) can cause circular dependencies 
  (e.g. if a function uses a constant in its body)"
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input UnitAbsyn.InstStore store;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.Class inClass;
  input Boolean isProtected;
  input InstDims inInstDims;
  input Boolean implicitInstantiation;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Option<DAE.ComponentRef> instSingleCref;
	output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output UnitAbsyn.InstStore outStore;  
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output list<DAE.Var> outTypesVarLst;
  output Option<DAE.Type> outTypesTypeOption;
  output Option<Absyn.ElementAttributes> optDerAttr;
  output DAE.EqualityConstraint outEqualityConstraint;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outStore,outDae,outSets,outState,outTypesVarLst,outTypesTypeOption,optDerAttr,outEqualityConstraint,outGraph):=
  matchcontinue (inCache,inEnv,inIH,store,inMod,inPrefix,inSets,inState,inClass,isProtected,inInstDims,implicitInstantiation,inGraph,instSingleCref)
    local
      Option<tuple<DAE.TType, Option<Absyn.Path>>> bc;
      list<Env.Frame> env,env_1;
      DAE.Mod mods;
      Prefix.Prefix pre;
      list<DAE.ComponentRef> crs;
      ClassInf.State ci_state,ci_state_1;
      SCode.Class c,cls;
      InstDims inst_dims;
      Boolean impl,prot;
      String clsname,implstr,n,s;
      Connect.Sets csets_1,csets;
      list<DAE.Var> tys;
      SCode.Restriction r;
      SCode.ClassDef d;
      Env.Cache cache;
      list<DAE.ComponentRef> dc;
      Real t1,t2,time; Boolean b;
      list<Connect.OuterConnect> oc;
      Option<Absyn.ElementAttributes> oDA;
      DAE.EqualityConstraint equalityConstraint;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      Absyn.Info info;
      DAE.DAElist dae,dae1,dae1_1;
      
    /*  Real class */ 
    case (cache,env,ih,store,mods,pre,csets as Connect.SETS(connection = crs,deletedComponents=dc,outerConnects=oc),
          ci_state,(c as SCode.CLASS(name = "Real",restriction = r,classDef = d)),prot,inst_dims,impl,graph,_) 
      equation 
        tys = instRealClass(cache,env,mods,pre);
        bc = arrayBasictypeBaseclass(inst_dims, (DAE.T_REAL(tys),NONE));                
      then
        (cache,env,ih,store,DAEUtil.emptyDae,Connect.SETS({},crs,dc,oc),ci_state,tys,bc /* NONE */,NONE,NONE,graph);       
        
    /* Integer class */
    case (cache,env,ih,store,mods,pre,csets as Connect.SETS(connection = crs,deletedComponents=dc,outerConnects=oc),
          ci_state,(c as SCode.CLASS(name = "Integer",restriction = r,classDef = d)),prot,inst_dims,impl,graph,_) 
      equation
        tys =  instIntegerClass(cache,env,mods,pre);       
        bc = arrayBasictypeBaseclass(inst_dims, (DAE.T_INTEGER(tys),NONE));
      then (cache,env,ih,store,DAEUtil.emptyDae,Connect.SETS({},crs,dc,oc),ci_state,tys,bc /* NONE */,NONE,NONE,graph);   

    /* String class */
    case (cache,env,ih,store,mods,pre,csets as Connect.SETS(connection = crs,deletedComponents=dc,outerConnects=oc),
          ci_state,(c as SCode.CLASS(name = "String",restriction = r,classDef = d)),prot,inst_dims,impl,graph,_) 
      equation
        tys =  instStringClass(cache,env,mods,pre);    
        bc = arrayBasictypeBaseclass(inst_dims, (DAE.T_STRING(tys),NONE));        
      then (cache,env,ih,store,DAEUtil.emptyDae,Connect.SETS({},crs,dc,oc),ci_state,tys,bc /* NONE */,NONE,NONE,graph);   

    /* Boolean class */
    case (cache,env,ih,store,mods,pre,csets as Connect.SETS(connection = crs,deletedComponents=dc,outerConnects=oc),
          ci_state,(c as SCode.CLASS(name = "Boolean",restriction = r,classDef = d)),prot,inst_dims,impl,graph,_) 
      equation
        tys =  instBooleanClass(cache,env,mods,pre); 
        bc = arrayBasictypeBaseclass(inst_dims, (DAE.T_BOOL(tys),NONE));        
      then (cache,env,ih,store,DAEUtil.emptyDae,Connect.SETS({},crs,dc,oc),ci_state,tys,bc /* NONE */,NONE,NONE,graph);           

    /* Enumeration class */
    case (cache,env,ih,store,mods,pre,csets as Connect.SETS(connection = crs,deletedComponents=dc,outerConnects=oc),
          ci_state,(c as SCode.CLASS(name = n,restriction = SCode.R_ENUMERATION(),classDef = SCode.PARTS(elementLst = els),info = info)),prot,inst_dims,impl,graph,_)
          local
            list<Env.Frame> env_2, env_3;
            list<SCode.Element> els;
            list<tuple<SCode.Element, Mod>> comp;
            list<String> names; 
            DAE.EqualityConstraint eqConstraint;
            tuple<DAE.TType, Option<Absyn.Path>> ty;
            Absyn.Path fq_class;
            list<DAE.Var> tys1,tys2;
            DAE.DAElist fdae;
      equation
        tys =  instEnumerationClass(cache,env,mods,pre); 
        ci_state_1 = ClassInf.trans(ci_state, ClassInf.NEWDEF());
        comp = addNomod(els);
        (cache,env_1,ih,fdae) = addComponentsToEnv(cache,env,ih, mods, pre, csets, ci_state_1, comp, comp, {}, inst_dims, impl);
        (cache,env_2,ih,store,dae1,csets,ci_state_1,tys1,graph) = instElementList(cache,env_1,ih,store, mods, pre, csets, ci_state_1, comp, inst_dims, impl,graph);
        (cache,fq_class) = makeFullyQualified(cache,env_2, Absyn.IDENT(n));
        eqConstraint = equalityConstraint(cache, env_2, els);        
        dae1_1 = DAEUtil.addComponentType(dae1, fq_class);
        names = SCode.componentNames(c);
        bc = arrayBasictypeBaseclass(inst_dims, (DAE.T_ENUMERATION(NONE(),Absyn.IDENT(""),names,tys1),NONE));
        ty = mktype(fq_class, ci_state_1, tys1, bc, eqConstraint, c); 
        // update Enumerationtypes in environment
        (cache,env_3) = updateEnumerationEnvironment(cache,env_2,ty,c,ci_state_1);  
        tys2 = listAppend(tys,tys1);       
      then (cache,env_3,ih,store,fdae,Connect.SETS({},crs,dc,oc),ci_state_1,tys2,bc /* NONE */,NONE,NONE,graph);           

  
   	/* Ignore functions if not implicit instantiation */ 
    case (cache,env,ih,store,mods,pre,Connect.SETS(connection = crs,deletedComponents=dc,outerConnects=oc),
          ci_state,cls,_,_,(impl as false),graph,_) 
      equation        
        true = SCode.isFunction(cls);
        clsname = SCode.className(cls);
        // print("Ignore function" +& clsname +& "\n");
      then
        (cache,env,ih,store,DAEUtil.emptyDae,Connect.SETS({},crs,dc,oc),ci_state,{},NONE,NONE,NONE,graph);
         
    /* Instantiate a class definition made of parts */
    case (cache,env,ih,store,mods,pre,csets,ci_state,(c as SCode.CLASS(name = n,restriction = r,classDef = d)),prot,inst_dims,impl,graph,instSingleCref)
      equation 
        false = isBuiltInClass(n) "If failed above, no need to try again";
        // Debug.fprint("insttr", "ICLASS ["); 
        implstr = Util.if_(impl, "impl] ", "expl] ");
        // Debug.fprint("insttr", implstr);
        // Debug.fprintln("insttr", Env.printEnvPathStr(env) +& "." +& n +& " mods: " +& Mod.printModStr(mods));
        // t1 = clock();
        (cache,env_1,ih,store,dae,csets_1,ci_state_1,tys,bc,oDA,equalityConstraint,graph) = instClassdef(cache,env,ih,store, mods, pre, csets, ci_state, n,d, r, prot, inst_dims, impl,graph,instSingleCref);
        // t2 = clock();
        // time = t2 -. t1;
        // b=realGt(time,0.05);
        // s = realString(time);
        // Debug.fprintln("insttr", " -> ICLASS " +& n +& " inst time: " +& s +& " in env: " +& Env.printEnvPathStr(env) +& " mods: " +& Mod.printModStr(mods)); 
        cache = Env.addCachedEnv(cache,n,env_1);
      then
        (cache,env_1,ih,store,dae,csets_1,ci_state_1,tys,bc,oDA,equalityConstraint,graph);
    
    // failure
    case (cache,env,ih,store,mods,pre,csets,ci_state,(c as SCode.CLASS(name = n,restriction = r,classDef = d)),prot,inst_dims,impl,graph,_)
      equation 
        // print("instClassIn(");print(n);print(") failed\n");
        // Debug.fprintln("failtrace", "- Inst.instClassIn failed" +& n);
      then
        fail();
  end matchcontinue;
end instClassIn_dispatch;

public function isBuiltInClass "
Author: BZ, this function identifies built in classes." 
  input String className;
  output Boolean b;
algorithm b := matchcontinue(className)
  case("Real") then true;
  case("Integer") then true;
  case("String") then true;
  case("Boolean") then true;
  case(_) then false;
end matchcontinue;
end isBuiltInClass;

protected function instRealClass 
"function instRealClass
  Instantiation of the Real class"
  input Env.Cache cache;
  input Env.Env env;
  input Mod mods;
  input Prefix.Prefix pre;
  output list<DAE.Var> varLst;
algorithm
  varLst := matchcontinue(cache,env,mods,pre)
    local 
      Boolean f; Absyn.Each e; list<DAE.SubMod> submods; Option<DAE.EqMod> eqmod; DAE.Exp exp;
      DAE.Var v; DAE.Properties p;
      Option<Values.Value> optVal;
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("quantity",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instRealClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"quantity",optVal,exp,DAE.T_STRING_DEFAULT,p);
        then v::varLst;
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("unit",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instRealClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"unit",optVal,exp,DAE.T_STRING_DEFAULT,p);
        then v::varLst;
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("displayUnit",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instRealClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"displayUnit",optVal,exp,DAE.T_STRING_DEFAULT,p);
        then v::varLst;  
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("min",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instRealClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"min",optVal,exp,DAE.T_REAL_DEFAULT,p);
        then v::varLst;                    
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("max",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instRealClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"max",optVal,exp,DAE.T_REAL_DEFAULT,p);
        then v::varLst;                    
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("start",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instRealClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"start",optVal,exp,DAE.T_REAL_DEFAULT,p);
        then v::varLst;
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("fixed",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instRealClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"fixed",optVal,exp,DAE.T_BOOL_DEFAULT,p);
        then v::varLst;                
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("nominal",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instRealClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"nominal",optVal,exp,DAE.T_REAL_DEFAULT,p);
        then v::varLst;          
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("stateSelect",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instRealClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"stateSelect",optVal,exp,(DAE.T_ENUMERATION(NONE(),Absyn.IDENT(""),{"never","avoid","default","prefer","always"},
          {DAE.TYPES_VAR("never",DAE.ATTR(false,false,SCode.RO(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,(DAE.T_ENUMERATION(SOME(1),Absyn.IDENT(""),{"never","avoid","default","prefer","always"},{}),NONE),DAE.UNBOUND()),
          DAE.TYPES_VAR("avoid",DAE.ATTR(false,false,SCode.RO(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,(DAE.T_ENUMERATION(SOME(2),Absyn.IDENT(""),{"never","avoid","default","prefer","always"},{}),NONE),DAE.UNBOUND()),
          DAE.TYPES_VAR("default",DAE.ATTR(false,false,SCode.RO(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,(DAE.T_ENUMERATION(SOME(3),Absyn.IDENT(""),{"never","avoid","default","prefer","always"},{}),NONE),DAE.UNBOUND()),
          DAE.TYPES_VAR("prefer",DAE.ATTR(false,false,SCode.RO(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,(DAE.T_ENUMERATION(SOME(4),Absyn.IDENT(""),{"never","avoid","default","prefer","always"},{}),NONE),DAE.UNBOUND()),
          DAE.TYPES_VAR("always",DAE.ATTR(false,false,SCode.RO(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,(DAE.T_ENUMERATION(SOME(5),Absyn.IDENT(""),{"never","avoid","default","prefer","always"},{}),NONE),DAE.UNBOUND())
//          {DAE.TYPES_VAR("never",DAE.ATTR(false,false,SCode.RO(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,(DAE.T_ENUM(),NONE),DAE.UNBOUND()),
//          DAE.TYPES_VAR("avoid",DAE.ATTR(false,false,SCode.RO(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,(DAE.T_ENUM(),NONE),DAE.UNBOUND()),
//          DAE.TYPES_VAR("default",DAE.ATTR(false,false,SCode.RO(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,(DAE.T_ENUM(),NONE),DAE.UNBOUND()),
//          DAE.TYPES_VAR("prefer",DAE.ATTR(false,false,SCode.RO(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,(DAE.T_ENUM(),NONE),DAE.UNBOUND()),
//          DAE.TYPES_VAR("always",DAE.ATTR(false,false,SCode.RO(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,(DAE.T_ENUM(),NONE),DAE.UNBOUND())
          }),NONE),p);
      then v::varLst;   
    case(cache,env,( mym as DAE.MOD(f,e,smod::submods,eqmod)),pre)
      local String s1; DAE.SubMod smod; DAE.Mod mym; 
      equation
        s1 = Mod.prettyPrintMod(mym,0) +& ", not found in the built-in class Real";
        Error.addMessage(Error.UNUSED_MODIFIER,{s1});
      then fail();
    case(cache,env,DAE.MOD(f,e,{},eqmod),pre) then {};
    case(cache,env,DAE.NOMOD(),pre) then {};
    case(cache,env,DAE.REDECL(_,_),pre) then fail(); /*TODO, report error when redeclaring in Real*/
  end matchcontinue;
end instRealClass;  

protected function instIntegerClass 
"function instIntegerClass
  Instantiation of the Integer class"
  input Env.Cache cache;
  input Env.Env env;
  input Mod mods;
  input Prefix.Prefix pre;
  output list<DAE.Var> varLst;
algorithm
  varLst := matchcontinue(cache,env,mods,pre)
    local 
      Boolean f; Absyn.Each e; list<DAE.SubMod> submods; Option<DAE.EqMod> eqmod; DAE.Exp exp;
      DAE.Var v; DAE.Properties p;
      Option<Values.Value> optVal;
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("quantity",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instIntegerClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"quantity",optVal,exp,DAE.T_STRING_DEFAULT,p);
        then v::varLst;
     
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("min",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instIntegerClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"min",optVal,exp,DAE.T_INTEGER_DEFAULT,p);
        then v::varLst;                    
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("max",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instIntegerClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"max",optVal,exp,DAE.T_INTEGER_DEFAULT,p);
        then v::varLst;                    
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("start",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instIntegerClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"start",optVal,exp,DAE.T_INTEGER_DEFAULT,p);
        then v::varLst;
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("fixed",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instIntegerClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"fixed",optVal,exp,DAE.T_BOOL_DEFAULT,p);
        then v::varLst;                
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("nominal",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instIntegerClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"nominal",optVal,exp,DAE.T_INTEGER_DEFAULT,p);
        then v::varLst;           
    case(cache,env,DAE.MOD(f,e,smod::submods,eqmod),pre)
      local String s1; DAE.SubMod smod;
      equation
        s1 = Mod.prettyPrintMod(mods,0) +& ", not found in the built-in class Integer";
        Error.addMessage(Error.UNUSED_MODIFIER,{s1});
      then fail();
    case(cache,env,DAE.MOD(f,e,{},eqmod),pre) then {};
    case(cache,env,DAE.NOMOD(),pre) then {};
    case(cache,env,DAE.REDECL(_,_),pre) then fail(); /*TODO, report error when redeclaring in Real*/
  end matchcontinue;
end instIntegerClass;

protected function instStringClass 
"function instStringClass
  Instantiation of the String class"
  input Env.Cache cache;
  input Env.Env env;
  input Mod mods;
  input Prefix.Prefix pre;
  output list<DAE.Var> varLst;
algorithm
  varLst := matchcontinue(cache,env,mods,pre)
    local Boolean f; Absyn.Each e; list<DAE.SubMod> submods; Option<DAE.EqMod> eqmod; DAE.Exp exp;
      DAE.Var v;
      DAE.Properties p;
      Option<Values.Value> optVal;
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("quantity",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instStringClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"quantity",optVal,exp,DAE.T_STRING_DEFAULT,p);
        then v::varLst;                    
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("start",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instStringClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"start",optVal,exp,DAE.T_STRING_DEFAULT,p);
        then v::varLst;      
    case(cache,env,DAE.MOD(f,e,smod::submods,eqmod),pre)
      local String s1; DAE.SubMod smod; 
      equation
        s1 = Mod.prettyPrintMod(mods,0) +& ", not found in the built-in class String";
        Error.addMessage(Error.UNUSED_MODIFIER,{s1});
      then fail();
    case(cache,env,DAE.MOD(f,e,{},eqmod),pre) then {};
    case(cache,env,DAE.NOMOD(),pre) then {};
    case(cache,env,DAE.REDECL(_,_),pre) then fail(); /*TODO, report error when redeclaring in Real*/
  end matchcontinue;
end instStringClass;

protected function instBooleanClass 
"function instBooleanClass
  Instantiation of the Boolean class"
  input Env.Cache cache;
  input Env.Env env;
  input Mod mods;
  input Prefix.Prefix pre;
  output list<DAE.Var> varLst;
algorithm
  varLst := matchcontinue(cache,env,mods,pre)
    local 
      Boolean f; Absyn.Each e; list<DAE.SubMod> submods; Option<DAE.EqMod> eqmod; DAE.Exp exp;
      Option<Values.Value> optVal;
      DAE.Var v; DAE.Properties p;
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("quantity",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instBooleanClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"quantity",optVal,exp,DAE.T_STRING_DEFAULT,p);
        then v::varLst;                    
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("start",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instBooleanClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"start",optVal,exp,DAE.T_BOOL_DEFAULT,p);
      then v::varLst;     
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("fixed",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instBooleanClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"fixed",optVal,exp,DAE.T_BOOL_DEFAULT,p);
      then v::varLst;              
    case(cache,env,DAE.MOD(f,e,smod::submods,eqmod),pre)
      local String s1; DAE.SubMod smod; 
      equation
        s1 = Mod.prettyPrintMod(mods,0) +& ", not found in the built-in class Boolean";
        Error.addMessage(Error.UNUSED_MODIFIER,{s1});
      then fail();
    case(cache,env,DAE.MOD(f,e,{},eqmod),pre) then {};
    case(cache,env,DAE.NOMOD(),pre) then {};
    case(cache,env,DAE.REDECL(_,_),pre) then fail(); /*TODO, report error when redeclaring in Real*/
  end matchcontinue;
end instBooleanClass;

protected function instEnumerationClass 
"function instEnumerationClass
  Instantiation of the Enumeration class"
  input Env.Cache cache;
  input Env.Env env;
  input Mod mods;
  input Prefix.Prefix pre;
  output list<DAE.Var> varLst;
algorithm
  varLst := matchcontinue(cache,env,mods,pre)
    local 
      Boolean f; Absyn.Each e; list<DAE.SubMod> submods; Option<DAE.EqMod> eqmod; DAE.Exp exp;
      Option<Values.Value> optVal;
      DAE.Var v; DAE.Properties p;
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("quantity",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instEnumerationClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"quantity",optVal,exp,DAE.T_STRING_DEFAULT,p);
        then v::varLst; 
   case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("min",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instEnumerationClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"min",optVal,exp,(DAE.T_ENUMERATION(NONE(),Absyn.IDENT(""),{},{}),NONE),p);
        then v::varLst;                    
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("max",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instEnumerationClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"max",optVal,exp,(DAE.T_ENUMERATION(NONE(),Absyn.IDENT(""),{},{}),NONE),p);
        then v::varLst;                    
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("start",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instEnumerationClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"start",optVal,exp,(DAE.T_ENUMERATION(NONE(),Absyn.IDENT(""),{},{}),NONE),p);
      then v::varLst;     
    case(cache,env,DAE.MOD(f,e,DAE.NAMEMOD("fixed",DAE.MOD(_,_,_,SOME(DAE.TYPED(exp,optVal,p))))::submods,eqmod),pre) 
      equation
        varLst = instEnumerationClass(cache,env,DAE.MOD(f,e,submods,eqmod),pre);
        v = instBuiltinAttribute(cache,env,"fixed",optVal,exp,DAE.T_BOOL_DEFAULT,p);
      then v::varLst;              
    case(cache,env,DAE.MOD(f,e,smod::submods,eqmod),pre)
      local String s1; DAE.SubMod smod; 
      equation
        s1 = Mod.prettyPrintMod(mods,0) +& ", not found in the built-in class Enumeration";
        Error.addMessage(Error.UNUSED_MODIFIER,{s1});
      then fail();
    case(cache,env,DAE.MOD(f,e,{},eqmod),pre) then {};
    case(cache,env,DAE.NOMOD(),pre) then {};
    case(cache,env,DAE.REDECL(_,_),pre) then fail(); /*TODO, report error when redeclaring in Real*/
  end matchcontinue;
end instEnumerationClass;

protected function instBuiltinAttribute 
"function instBuiltinAttribute
  Help function to e.g. instRealClass, etc."
  input Env.Cache cache;
  input Env.Env env;
  input Ident id;
  input Option<Values.Value> optVal;
  input DAE.Exp bind;
  input DAE.Type expectedTp;
  input DAE.Properties bindProp;
  output DAE.Var var;
algorithm
  var := matchcontinue(cache,env,id,optVal,bind,expectedTp,bindProp)
    local 
      Values.Value v; DAE.Type t_1,bindTp; DAE.Exp bind1; 
   
    case(cache,env,id,SOME(v),bind,expectedTp,DAE.PROP(bindTp,_)) 
      equation
        (bind1,t_1) = Types.matchType(bind,bindTp,expectedTp,true);
      then DAE.TYPES_VAR(id,DAE.ATTR(false,false,SCode.RO(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
        false,t_1,DAE.EQBOUND(bind1,SOME(v),DAE.C_PARAM()));
      
    case(cache,env,id,_,bind,expectedTp,DAE.PROP(bindTp,_)) 
      equation
        (bind1,t_1) = Types.matchType(bind,bindTp,expectedTp,true);
        (cache,v,_) = Ceval.ceval(cache,env, bind1, false, NONE, NONE, Ceval.NO_MSG());
      then DAE.TYPES_VAR(id,DAE.ATTR(false,false,SCode.RO(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
      false,t_1,DAE.EQBOUND(bind1,SOME(v),DAE.C_PARAM()));

    case(cache,env,id,_,bind,expectedTp,DAE.PROP(bindTp,_)) 
      equation
         (bind1,t_1) = Types.matchType(bind,bindTp,expectedTp,true);   
      then DAE.TYPES_VAR(id,DAE.ATTR(false,false,SCode.RO(),SCode.PARAM(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
      false,t_1,DAE.EQBOUND(bind1,NONE(),DAE.C_PARAM()));
      
    case(cache,env,id,_,bind,expectedTp,DAE.PROP(bindTp,_)) local String s1,s2;
      equation 
        failure((_,_) = Types.matchType(bind,bindTp,expectedTp,true));
        s1 = "builtin attribute " +& id +& " of type "+&Types.unparseType(bindTp);
        s2 = Types.unparseType(expectedTp);
        Error.addMessage(Error.TYPE_ERROR,{s1,s2});
      then fail();   
    case(cache,env,id,SOME(v),bind,expectedTp,bindProp) equation
			true = RTOpts.debugFlag("failtrace");
      Debug.fprintln("failtrace", "instBuiltinAttribute failed for: " +& id +&
                                  " value binding: " +& ValuesUtil.printValStr(v) +& 
                                  " binding: " +& Exp.printExpStr(bind) +&
                                  " expected type: " +& Types.printTypeStr(expectedTp) +&
                                  " type props: " +& Types.printPropStr(bindProp));
    then fail();
    case(cache,env,id,_,bind,expectedTp,bindProp) equation
			true = RTOpts.debugFlag("failtrace");
      Debug.fprintln("failtrace", "instBuiltinAttribute failed for: " +& id +&
                                  " value binding: NONE()" +& 
                                  " binding: " +& Exp.printExpStr(bind) +&
                                  " expected type: " +& Types.printTypeStr(expectedTp) +&
                                  " type props: " +& Types.printPropStr(bindProp));
    then fail();
  end matchcontinue;
end instBuiltinAttribute;

protected function arrayBasictypeBaseclass 
"function: arrayBasictypeBaseclass
  author: PA"
  input InstDims inInstDims;
  input DAE.Type inType;
  output Option<DAE.Type> outTypesTypeOption;
algorithm 
  outTypesTypeOption := matchcontinue (inInstDims,inType)
    local
      tuple<DAE.TType, Option<Absyn.Path>> tp,tp_1;
      list<Option<Integer>> lst;
      InstDims inst_dims;
    case ({},tp) then NONE; 
    case (inst_dims,tp)
      equation 
        lst = instdimsIntOptList(Util.listLast(inst_dims));
        tp_1 = arrayBasictypeBaseclass2(lst, tp);
      then
        SOME(tp_1);
  end matchcontinue;
end arrayBasictypeBaseclass;

protected function instdimsIntOptList 
"function: instdimsIntOptList
  author: PA"
  input list<DAE.Subscript> inInstDims;
  output list<Option<Integer>> outIntegerOptionLst;
algorithm 
  outIntegerOptionLst := matchcontinue (inInstDims)
    local
      list<Option<Integer>> res;
      Integer i;
      list<DAE.Subscript> ss;
    case ({}) then {}; 
    case ((DAE.INDEX(exp = DAE.ICONST(integer = i)) :: ss))
      equation 
        res = instdimsIntOptList(ss);
      then
        (SOME(i) :: res);
  end matchcontinue;
end instdimsIntOptList;

protected function arrayBasictypeBaseclass2 
"function: arrayBasictypeBaseclass2
  author: PA"
  input list<Option<Integer>> inIntegerOptionLst;
  input DAE.Type inType;
  output DAE.Type outType;
algorithm 
  outType := matchcontinue (inIntegerOptionLst,inType)
    local
      tuple<DAE.TType, Option<Absyn.Path>> tp,tp_1,res;
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

public function partialInstClassIn 
"function: partialInstClassIn
  This function is used when instantiating classes in lookup of other classes.
  The only work performed by this function is to instantiate local classes and
  inherited classes."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.Class inClass;
  input Boolean inBoolean;
  input InstDims inInstDims;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output ClassInf.State outState;
algorithm 
  (outCache,outEnv,outIH,outState) := matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inClass,inBoolean,inInstDims)
    local
      list<Env.Frame> env,env_1;
      DAE.Mod mods;
      Prefix.Prefix pre;
      Connect.Sets csets;
      ClassInf.State ci_state,ci_state_1;
      SCode.Class c;
      String n;
      SCode.Restriction r;
      SCode.ClassDef d;
      Boolean prot;
      InstDims inst_dims;
      Env.Cache cache;
      Absyn.Path fullPath;
      Real t1,t2,time; String s,s2; Boolean b;
      InstanceHierarchy ih;
      InstHashTable instHash;
      
      tuple<Env.Cache, Env, InstanceHierarchy, Mod, Prefix, Connect.Sets, 
            ClassInf.State, SCode.Class, Boolean, InstDims> inputs;
      tuple<Env.Cache, Env, InstanceHierarchy, ClassInf.State> outputs;
      Absyn.Path fullEnvPathPlusClass;
      Option<Absyn.Path> envPathOpt;
      String className;
      
      Mod aa_1; 
      Prefix aa_2; 
      Connect.Sets aa_3; 
      ClassInf.State aa_4;
      SCode.Class aa_5; 
      Boolean aa_6; 
      InstDims aa_7;
      replaceable type Type_a subtypeof Any;
      Type_a bbx, bby;
            
    // see if we find a partial class inst
    case (cache,env,ih,mods,pre,csets,ci_state,c,prot,inst_dims)
      equation
        false = RTOpts.debugFlag("noCache");
        instHash = System.getFromRoots(0);
        envPathOpt = Env.getEnvPath(inEnv);
        className = SCode.className(c);
        fullEnvPathPlusClass = Absyn.selectPathsOpt(envPathOpt, Absyn.IDENT(className));        
        {_,SOME(FUNC_partialInstClassIn(inputs, outputs))} = get(fullEnvPathPlusClass, instHash);
        (_, _, _, aa_1, aa_2, aa_3, aa_4, aa_5, _, aa_7) = inputs;
        // are the important inputs the same??
        bbx = (aa_1, aa_2, aa_3, aa_4, aa_5, aa_7);
        bby = (mods,pre,csets,ci_state,c,inst_dims);
        equality(bbx = bby);
        (cache,env,ih,ci_state_1) = outputs;
        // Debug.fprintln("cache", "IIIIPARTIAL->got PARTIAL from instCache: " +& Absyn.pathString(fullEnvPathPlusClass));
      then
        (inCache,env,ih,ci_state_1);
     
    /*/ adrpo: TODO! FIXME! see if we find a full instantiation!
      // this fails for 2-3 examples, so disable it for now and check it later
    case (cache,env,ih,mods,pre,csets,ci_state,c,prot,inst_dims)
      local
      tuple<Env.Cache, Env, InstanceHierarchy, UnitAbsyn.InstStore, Mod, Prefix, 
            Connect.Sets, ClassInf.State, SCode.Class, Boolean, InstDims, Boolean, 
            ConnectionGraph.ConnectionGraph, Option<DAE.ComponentRef>> inputs;
      tuple<Env.Cache, Env, InstanceHierarchy, UnitAbsyn.InstStore, DAE.DAElist, 
            Connect.Sets, ClassInf.State, list<DAE.Var>, Option<DAE.Type>, 
            Option<Absyn.ElementAttributes>, DAE.EqualityConstraint, 
            ConnectionGraph.ConnectionGraph> outputs;
      equation
        false = RTOpts.debugFlag("noCache");
        instHash = System.getFromRoots(0);
        envPathOpt = Env.getEnvPath(inEnv);
        className = SCode.className(c);
        fullEnvPathPlusClass = Absyn.selectPathsOpt(envPathOpt, Absyn.IDENT(className));        
        {FUNC_instClassIn(inputs, outputs)} = get(fullEnvPathPlusClass, instHash);
        (_, _, _, _, aa_1, aa_2, aa_3, aa_4, aa_5, _, aa_7, _, _, _) = inputs;
        // are the important inputs the same??
        bbx = (aa_1, aa_2, aa_3, aa_4, aa_5, aa_7);
        bby = (mods,pre,csets,ci_state,c,inst_dims);
        equality(bbx = bby);
        (cache,env,ih,_,_,_,ci_state_1,_,_,_,_,_) = outputs;
        // Debug.fprintln("cache", "IIIIPARTIAL->got FULL from instCache: " +& Absyn.pathString(fullEnvPathPlusClass));
      then
        (inCache,env,ih,ci_state_1);*/     
        
    /* call the function and then add it in the cache */
    case (cache,env,ih,mods,pre,csets,ci_state,c,prot,inst_dims) 
      equation 
        (cache,env,ih,ci_state) = 
           partialInstClassIn_dispatch(inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inClass,inBoolean,inInstDims);

        envPathOpt = Env.getEnvPath(inEnv);
        className = SCode.className(c);
        fullEnvPathPlusClass = Absyn.selectPathsOpt(envPathOpt, Absyn.IDENT(className));
        
        inputs = (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inClass,inBoolean,inInstDims);
        outputs = (cache,env,ih,ci_state); 
        
        addToInstCache(fullEnvPathPlusClass,
           NONE(), 
           SOME(FUNC_partialInstClassIn( // result for partial instantiation
             inputs,outputs)));
        // Debug.fprintln("cache", "IIIIPARTIAL->added to instCache: " +& Absyn.pathString(fullEnvPathPlusClass));
      then
        (cache,env,ih,ci_state);
        
    case (cache,env,ih,mods,pre,csets,ci_state,(c as SCode.CLASS(name = n,restriction = r,classDef = d)),prot,inst_dims)
      equation 
        Debug.fprintln("insttr", "- Inst.partialInstClassIn failed on class:" +& 
           n +& " in environment: " +& Env.printEnvPathStr(env));
      then
        fail();
  end matchcontinue;
end partialInstClassIn;

public function partialInstClassIn_dispatch 
"function: partialInstClassIn
  This function is used when instantiating classes in lookup of other classes.
  The only work performed by this function is to instantiate local classes and
  inherited classes."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.Class inClass;
  input Boolean inBoolean;
  input InstDims inInstDims;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output ClassInf.State outState;
algorithm 
  (outCache,outEnv,outIH,outState) := matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inClass,inBoolean,inInstDims)
    local
      list<Env.Frame> env,env_1;
      DAE.Mod mods;
      Prefix.Prefix pre;
      Connect.Sets csets;
      ClassInf.State ci_state,ci_state_1;
      SCode.Class c;
      String n;
      SCode.Restriction r;
      SCode.ClassDef d;
      Boolean prot,partialPrefix;
      InstDims inst_dims;
      Env.Cache cache;
      Absyn.Path fullPath;
      Real t1,t2,time; String s,s2; Boolean b;
      InstanceHierarchy ih;
      
    case (cache,env,ih,mods,pre,csets,ci_state,(c as SCode.CLASS(name = "Real")),_,_) 
      then (cache,env,ih,ci_state);
         
    case (cache,env,ih,mods,pre,csets,ci_state,(c as SCode.CLASS(name = "Integer")),_,_) 
      then (cache,env,ih,ci_state);
         
    case (cache,env,ih,mods,pre,csets,ci_state,(c as SCode.CLASS(name = "String")),_,_) 
      then (cache,env,ih,ci_state);
         
    case (cache,env,ih,mods,pre,csets,ci_state,(c as SCode.CLASS(name = "Boolean")),_,_) 
      then (cache,env,ih,ci_state);
         
    case (cache,env,ih,mods,pre,csets,ci_state,(c as SCode.CLASS(name = n,restriction = r,partialPrefix=partialPrefix,classDef = d)),prot,inst_dims)
      equation 
        // t1 = clock();
        (cache,env_1,ih,ci_state_1) = partialInstClassdef(cache,env,ih, mods, pre, csets, ci_state, d, r, partialPrefix, prot, inst_dims, n);
        // t2 = clock();
        // time = t2 -. t1;
        // b=realGt(time,0.05);
        // s = realString(time);
        // s2 = Env.printEnvPathStr(env);
        // Debug.fprintln("insttr", "ICLASSPARTIAL " +& n +& " inst time: " +& s +& " in env " +& s2 +& " mods: " +& Mod.printModStr(mods));
        // print(Util.if_(b,s,""));
        // print("inCache:");print(Env.printCacheStr(cache));print("\n");
        cache = Env.addCachedEnv(cache,n,env_1);
        // print("outCache:");print(Env.printCacheStr(cache));print("\n");
        // print("partialInstClassDef, outenv:");print(Env.printEnvStr(env_1));
      then
        (cache,env_1,ih,ci_state_1);        
  end matchcontinue;
end partialInstClassIn_dispatch;

protected function equalityConstraintOutputDimension
  input list<SCode.Element> inElements;
  output Integer outDimension;
algorithm
  outDimension := matchcontinue(inElements)
  local
    list<SCode.Element> tail;
    Integer dim;
    case({}) equation
      then 0;
    case(SCode.COMPONENT(attributes = SCode.ATTR(
        direction = Absyn.OUTPUT,
        arrayDims = {Absyn.SUBSCRIPT(Absyn.INTEGER(dim))}
      )) :: _) equation
      then dim;
    case(_ :: tail) equation
      dim = equalityConstraintOutputDimension(tail);
      then dim;
  end matchcontinue;
end equalityConstraintOutputDimension;

protected function equalityConstraint
  "function: equalityConstraint
    Tests if the given elements contain equalityConstraint function and returns 
    corresponding DAE.EqualityConstraint."
  input Env.Cache inCache;
  input Env inEnv;
  input list<SCode.Element> inCdefelts;
  //output Env.Cache outCache;  
  output DAE.EqualityConstraint outResult;
algorithm
  (outCache, outResult) := matchcontinue(inCache, inEnv, inCdefelts)
  local
      list<SCode.Element> tail, els;      
      String name;
      Env.Cache cache;
      Env env;
      Absyn.Path path;
      list<DAE.Type> types;
      Integer dimension;
      DAE.EqualityConstraint result;
    case(cache, env, {})
      then NONE;
    case(cache, env, SCode.CLASSDEF(classDef = classDef as SCode.CLASS(name = "equalityConstraint", restriction = SCode.R_FUNCTION,
         classDef = SCode.PARTS(elementLst = els))) :: _)
      local 
        SCode.Class classDef;
      equation
        SOME(path) = Env.getEnvPath(env);
        path = Absyn.joinPaths(path, Absyn.IDENT("equalityConstraint"));
        /*(cache, env) = implicitFunctionTypeInstantiation(cache, env, classDef);
        (cache, types) = Lookup.lookupFunctionsInEnv(cache, env, path);
        length = listLength(types);
        print("type count: ");
        print(intString(length));
        print("\n");*/
        dimension = equalityConstraintOutputDimension(els);
        /*print("dimension: ");
        print(intString(dimension));
        print("\n");*/
      then SOME((path, dimension));    
    case(cache, env, _ :: tail)
      then equalityConstraint(cache, env, tail);
  end matchcontinue;
end equalityConstraint;

protected function handleUnitChecking
"@author: adrpo
 do this unit checking ONLY if we have the flag!"
  input Env.Cache cache;
  input Env env;
  input UnitAbsyn.InstStore store;
  input Connect.Sets csets;
  input Prefix.Prefix pre;
  input DAE.DAElist compDAE;  
  input list<DAE.DAElist> daes;
  output Env.Cache outCache;
  output Env outEnv;
  output UnitAbsyn.InstStore outStore;
algorithm
  (outCache,outEnv,outStore) := matchcontinue(cache,env,store,csets,pre,compDAE,daes)
    local
      DAE.DAElist daetemp;
      UnitAbsyn.UnitTerms ut;
        
    // do nothing if we don't have to do unit checking
    case (cache,env,store,csets,pre,compDAE,daes)
      equation
        false = OptManager.getOption("unitChecking");
      then
        (cache,env,store);
        
    case (cache,env,store,csets,pre,compDAE,daes)
      equation
        // Perform unit checking/dimensional analysis 
        daetemp = ConnectUtil.equations(csets,pre); // ToDO. calculation of connect eqns done twice. remove in future.          
        // equations from components (dae1) not considered, they are checked in resp recursive call
        // but bindings on scalar variables must be considered, therefore passing dae1 separately
        daetemp = DAEUtil.joinDaeLst(daetemp::daes);
        (store,ut)=  UnitAbsynBuilder.instBuildUnitTerms(env,daetemp,compDAE,store);          
        
        //print("built store for "+&className+&"\n");
        //UnitAbsynBuilder.printInstStore(store);
        //print("terms for "+&className+&"\n");
        //UnitAbsynBuilder.printTerms(ut);
  
        UnitAbsynBuilder.registerUnitWeights(cache,env,compDAE);
        
        // perform the check
        store = UnitChecker.check(ut,store);         
       
        //print("store for "+&className+&"\n");
        //UnitAbsynBuilder.printInstStore(store);
        //print("dae1="+&DAE.dumpDebugDAE(DAE.DAE(dae1))+&"\n");
     then
       (cache,env,store);
  end matchcontinue;
end  handleUnitChecking;

protected function instClassdef 
"function: instClassdef
  There are two kinds of class definitions, either explicit
  definitions SCode.PARTS() or 
  derived definitions SCode.DERIVED() or 
  extended derived definitions SCode.CLASS_EXTENDS().

  When instantiating an explicit definition, the elements are first
  instantiated, using instElementList, and then the equations
  and finally the algorithms are instantiated using instEquation
  and instAlgorithm, respectively. The resulting lists of equations 
  are concatenated to produce the result.
  The last two arguments are the same as for instClassIn:
  implicit instantiation and implicit package/function instantiation."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input UnitAbsyn.InstStore store;
  input Mod inMod2;
  input Prefix inPrefix3;
  input Connect.Sets inSets4;
  input ClassInf.State inState5;
  input String className;
  input SCode.ClassDef inClassDef6;
  input SCode.Restriction inRestriction7;
  input Boolean inBoolean8;
  input InstDims inInstDims9;
  input Boolean inBoolean10;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Option<DAE.ComponentRef> instSingleCref;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;  
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output list<DAE.Var> outTypesVarLst;
  output Option<DAE.Type> outTypesTypeOption;
  output Option<Absyn.ElementAttributes> optDerAttr;
  output DAE.EqualityConstraint outEqualityConstraint;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outStore,outDae,outSets,outState,outTypesVarLst,outTypesTypeOption,optDerAttr,outEqualityConstraint,outGraph):=
  matchcontinue (inCache,inEnv,inIH,store,inMod2,inPrefix3,inSets4,inState5,className,inClassDef6,inRestriction7,inBoolean8,inInstDims9,inBoolean10,inGraph,instSingleCref)
    local
      list<SCode.Element> cdefelts,compelts,extendselts,els,extendsclasselts;
      list<Env.Frame> env1,env2,env3,env,env4,env5,cenv,cenv_2,env_2;
      list<tuple<SCode.Element, Mod>> cdefelts_1,cdefelts_2,extcomps,compelts_1,compelts_2;
      list<SCode.Element> compelts_2_elem;
      Connect.Sets csets,csets1,csets_filtered,csets2,csets3,csets4,csets5,csets_1;
      DAE.DAElist dae1,dae2,dae3,dae4,dae5,dae,daetemp;
      ClassInf.State ci_state1,ci_state,ci_state2,ci_state3,ci_state4,ci_state5,ci_state6,new_ci_state,ci_state_1;
      list<DAE.Var> tys;
      Option<tuple<DAE.TType, Option<Absyn.Path>>> bc;
      DAE.Mod mods,emods,m,mod_1,mods_1,mods_2,checkMods;
      Prefix.Prefix pre;
      list<SCode.Equation> eqs,initeqs,eqs2,initeqs2,eqs_1,initeqs_1;
      list<SCode.Algorithm> alg,initalg,alg2,initalg2,alg_1,initalg_1;
      SCode.Restriction re,r;
      Boolean prot,impl,enc2;
      InstDims inst_dims,inst_dims_1;
      list<DAE.Subscript> inst_dims2;
      String id,pre_str,cn2,cns,scope_str,s;
      SCode.Class c;
      Option<DAE.EqMod> eq;
      list<DimExp> dims;
      Absyn.Path cn;
      Option<list<Absyn.Subscript>> ad;
      SCode.Mod mod;
      Env.Cache cache;
      list<DAE.ComponentRef> dc;
      list<DAE.ComponentRef> crs;
      Option<Absyn.ElementAttributes> oDA;
      list<Connect.OuterConnect> oc;
      DAE.EqualityConstraint eqConstraint;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      UnitAbsyn.Store utstore;
      UnitAbsyn.UnitCheckResult res;
      UnitAbsyn.Store st2;
      UnitAbsyn.Store st3;
      UnitAbsyn.Unit u1;
      DAE.DAElist fdae,fdae0,fdae1;
      
      /* This rule describes how to instantiate a class definition
	   * that extends a basic type. (No equations or algorithms allowed) 
       */ 

    case (cache,env,ih,store,mods,pre,csets as Connect.SETS(_,crs,dc,oc),ci_state,className,
          SCode.PARTS(elementLst = els,
                      normalEquationLst = {}, initialEquationLst = {},
                      normalAlgorithmLst = {}, initialAlgorithmLst = {}),
          re,prot,inst_dims,impl,graph,instSingleCref) 
      equation
        (cdefelts,{},extendselts as (_ :: _),compelts) = splitElts(els) "extendselts should be empty, checked in inst_basic type below";
        (env1,ih) = addClassdefsToEnv(env,ih, cdefelts, impl,SOME(mods)) "1. CLASSDEF & IMPORT nodes and COMPONENT nodes(add to env)" ;
        cdefelts_1 = addNomod(cdefelts) "instantiate CDEFS so redeclares are carried out" ;
        (cache,env2,ih,cdefelts_2,csets,fdae) = updateCompeltsMods(cache,env1,ih, pre, cdefelts_1, ci_state, csets, impl);
        (cache,env3,ih,store,_,csets1,ci_state1,tys,graph) = 
          instElementList(cache, env2, ih, store, mods , pre, csets, ci_state, cdefelts_2, inst_dims, impl,graph);
        mods = Types.removeFirstSubsRedecl(mods);
        (cache,ih,store,bc,tys)= instBasictypeBaseclass(cache, env3, ih, store, extendselts, compelts, mods, inst_dims);
        // Search for equalityConstraint
        eqConstraint = equalityConstraint(cache, env, els);
      then
        (cache,env,ih,store,fdae,Connect.SETS({},crs,dc,oc),ci_state,tys,bc,NONE,eqConstraint,graph);

    /* This case instantiates external objects. An external object inherits from ExternalOBject
     * and have two local functions: constructor and destructor (and no other elements). 
     */
    case (cache,env,ih,store,mods,pre,csets,ci_state,className,
          SCode.PARTS(elementLst = els, 
                      normalEquationLst = eqs, initialEquationLst = initeqs, 
                      normalAlgorithmLst = alg, initialAlgorithmLst = initalg), 
          re,prot,inst_dims,impl,graph,instSingleCref) 
      equation
       	true = isExternalObject(els);
       	(cache,env,ih,dae,ci_state) = instantiateExternalObject(cache,env,ih,els,impl);       	
      then 
        (cache,env,ih,store,dae,Connect.emptySet,ci_state,{},NONE,NONE,NONE,graph);   
        
    /* This rule describes how to instantiate an explicit class definition */ 
    case (cache,env,ih,store,mods,pre,csets,ci_state,className,
          SCode.PARTS(elementLst = els,
                      normalEquationLst = eqs, initialEquationLst = initeqs,
                      normalAlgorithmLst = alg, initialAlgorithmLst = initalg),
          re,prot,inst_dims,impl,graph,instSingleCref)
          local list<Mod> tmpModList; 
      equation 
        UnitParserExt.checkpoint();        
        //Debug.traceln(" Instclassdef for: " +& PrefixUtil.printPrefixStr(pre) +& "." +&  className +& " mods: " +& Mod.printModStr(mods)); 
        ci_state1 = ClassInf.trans(ci_state, ClassInf.NEWDEF());
        els = extractConstantPlusDeps(els,instSingleCref,{},className);
        (cdefelts,extendsclasselts,extendselts,compelts) = splitElts(els);
        
        (env1,ih) = addClassdefsToEnv(env, ih, cdefelts, impl, SOME(mods)) 
        "1. CLASSDEF & IMPORT nodes and COMPONENT nodes(add to env)" ;
                
        (cache,env2,ih,emods,extcomps,eqs2,initeqs2,alg2,initalg2) = 
        instExtendsAndClassExtendsList(cache, env1, ih, mods, extendselts, extendsclasselts, ci_state, className, impl) 
        "2. EXTENDS Nodes inst_extends_list only flatten inhteritance structure. It does not perform component instantiations." ;         
        compelts_1 = addNomod(compelts) 
        "Problem. Modifiers on inherited components are unelabed, loosing their 
	                type information. This will not work, since the modifier type 
	                can not always be found.
	       For instance. 
          model B extends B2; end B; model B2 Integer ni=1; end B2;
	        model test
	          Integer n=2;
	          B b(ni=n);
	        end test;

	       The modifier (n=n) will be untypes when B is instantiated 
	       and the variable n can not be found, since the component b 
	       is instantiated in env of B.
       
	       Solution:
	        Redesign instExtendsList to return (SCode.Element, Mod) list and
	        convert other component elements to the same format, such that 
	        instElement can handle the new format uniformely." ;
        
        cdefelts_1 = addNomod(cdefelts);
        compelts_1 = Util.listFlatten({extcomps,compelts_1,cdefelts_1}); 
        // Add components from base classes to be instantiated in 3 as well.
        eqs_1 = listAppend(eqs, eqs2);
        initeqs_1 = listAppend(initeqs, initeqs2);
        alg_1 = listAppend(alg, alg2);
        initalg_1 = listAppend(initalg, initalg2);
        
        //Only keep inside connections with matching prefix for this class.
        //csets will remain unfiltered for other components in "outer class"
        csets_filtered = filterConnectionSetCrefs(csets, pre);
        
        //Add connection crefs from equations to connection sets
        csets = addConnectionCrefs(csets, eqs_1);
        csets_filtered = addConnectionCrefs(csets_filtered, eqs_1);

        //Add filtered connection sets to env so ceval can reach it
        (env2,ih) = addConnectionSetToEnv(csets_filtered, pre, env2,ih);
        id = Env.printEnvPathStr(env);

        //Add variables to env, wihtout type and binding, which will be added 
        //later in instElementList (where update_variable is called)" 
        (cache,env3,ih,fdae0) = addComponentsToEnv(cache,env2,ih, emods, pre, csets, ci_state, compelts_1, compelts_1, eqs_1, inst_dims, impl);
        //Update the modifiers of elements to typed ones, needed for modifiers
		    //on components that are inherited.  		 
        (cache,env4,ih,compelts_2,csets,fdae) = updateCompeltsMods(cache,env3,ih, pre, extcomps, ci_state, csets, impl);
        compelts_1 = addNomod(compelts);
        cdefelts_1 = addNomod(cdefelts);
        compelts_2 = Util.listFlatten({compelts_2,compelts_1, cdefelts_1});
        
        //Instantiate components
 
        compelts_2_elem = Util.listMap(compelts_2,Util.tuple21);
        checkMods = Mod.merge(mods,emods,env4,Prefix.NOPRE());
        mods = checkMods; 
        //print("To match modifiers,\n" +& Mod.printModStr(checkMods) +& "\n on components: "); 
        //print(" (" +& Util.stringDelimitList(Util.listMap(compelts_2_elem,SCode.elementName),", ") +& ") \n");                  
        matchModificationToComponents(compelts_2_elem,checkMods,className);
        
        (cache,env5,ih,store,dae1,csets1,ci_state2,tys,graph) = instElementList(cache,env4,ih,store, mods, pre, csets, ci_state1, compelts_2, inst_dims, impl,graph);
        //Instantiate equations (see function "instEquation")
        (cache,_,ih,dae2,csets2,ci_state3,graph) = 
        instList(cache,env5,ih, mods, pre, csets1, ci_state2, instEquation, eqs_1, impl, graph) ;
        
        //Instantiate inital equations (see function "instInitialequation")
        (cache,_,ih,dae3,csets3,ci_state4,graph) = 
        instList(cache,env5,ih, mods, pre, csets2, ci_state3, instInitialequation, initeqs_1, impl, graph);
        
        //Instantiate algorithms  (see function "instAlgorithm")
        (cache,_,ih,dae4,csets4,ci_state5,graph) = 
        instList(cache,env5,ih, mods, pre, csets3, ci_state4, instAlgorithm, alg_1, impl, graph);        

        //Instantiate algorithms  (see function "instInitialalgorithm")
        (cache,_,ih,dae5,csets5,ci_state6,graph) = 
        instList(cache,env5,ih, mods, pre, csets4, ci_state5, instInitialalgorithm, initalg_1, impl, graph);
        
        //Collect the DAE's
        dae = DAEUtil.joinDaeLst({dae1,dae2,dae3,dae4,dae5,fdae,fdae0});
        
        //Change outer references to corresponding inner reference
        // adrpo: TODO! FIXME! very very very expensive function, try to get rid of it!
        (dae,csets5,ih,graph) = InnerOuter.changeOuterReferences(dae,csets5,ih,graph);
        
        // adrpo: moved bunch of a lot of expensive unit checking operations to this function
        (cache,env,store) = handleUnitChecking(cache,env,store,csets5,pre,dae1,{dae2,dae3,dae4,dae5});
        
        UnitParserExt.rollback();
        //print("rollback for "+&className+&"\n");
      
        // Search for equalityConstraint
        eqConstraint = equalityConstraint(cache, env, els);
      then
        (cache,env5,ih,store,dae,csets5,ci_state6,tys,NONE/* no basictype bc*/,NONE,eqConstraint,graph);
   
    /* This rule describes how to instantiate class definition derived from an enumeration */ 
    case (cache,env,ih,store,mods,pre,csets,ci_state,className,
          SCode.DERIVED(Absyn.TPATH(path = cn,arrayDim = ad),modifications = mod,attributes=DA),
          re,prot,inst_dims,impl,graph,instSingleCref)
      local Absyn.ElementAttributes DA; Absyn.Path fq_class; DAE.DAElist fdae;
      equation 
        // adrpo - here we need to check if we don't have recursive extends of the form:
        // package Icons
        //   extends Icons.BaseLibrary;
        //        model BaseLibrary "Icon for base library"
        //        end BaseLibrary;
        // end Icons;
        // if we don't check that, then the compiler enters an infinite loop!
        // what we do is removing Icons from extends Icons.BaseLibrary;
        cn = removeSelfReference(className, cn);
        
        (cache,(c as SCode.CLASS(name=cn2,encapsulatedPrefix=enc2,restriction=r as SCode.R_ENUMERATION())),cenv) = 
          Lookup.lookupClass(cache,env, cn, true);

       
        env3 = Env.openScope(cenv, enc2, SOME(cn2));        
        ci_state2 = ClassInf.start(r, Env.getEnvName(env3));
        (cache,cenv_2,_,_,_,_,_,_,_,_,_,_) = 
        instClassIn(
          cache,env3,InnerOuter.emptyInstHierarchy,UnitAbsyn.noStore, 
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state2, c, false, {}, false, ConnectionGraph.EMPTY,NONE);
        
        
        (cache,mod_1,fdae) = Mod.elabMod(cache,cenv_2, pre, mod, impl);
        new_ci_state = ClassInf.start(r, Env.getEnvName(env3));
        mods_1 = Mod.merge(mods, mod_1, cenv_2, pre);
        eq = Mod.modEquation(mods_1) "instantiate array dimensions" ;
        (cache,dims,fdae1) = elabArraydimOpt(cache,cenv_2, Absyn.CREF_IDENT("",{}),cn, ad, eq, impl, NONE,true) "owncref not valid here" ;
        inst_dims2 = instDimExpLst(dims, impl);
        inst_dims_1 = Util.listListAppendLast(inst_dims, inst_dims2);
        (cache,env_2,ih,store,dae,csets_1,ci_state_1,tys,bc,oDA,eqConstraint,graph) = instClassIn(cache,cenv_2,ih,store,mods_1, pre, csets, new_ci_state, c, prot, 
                    inst_dims_1, impl, graph, instSingleCref) "instantiate class in opened scope. " ;
        ClassInf.assertValid(ci_state_1, re) "Check for restriction violations" ;
        oDA = Absyn.mergeElementAttributes(DA,oDA);        
        dae = DAEUtil.joinDaeLst({dae,fdae,fdae1});    
      then
        (cache,env_2,ih,store,dae,csets_1,ci_state_1,tys,bc,oDA,eqConstraint,graph);
      
    /* This rule describes how to instantiate a derived class definition */ 
    case (cache,env,ih,store,mods,pre,csets,ci_state,className,
          SCode.DERIVED(Absyn.TPATH(path = cn,arrayDim = ad),modifications = mod,attributes=DA),
          re,prot,inst_dims,impl,graph,instSingleCref)
      local Absyn.ElementAttributes DA; Absyn.Path fq_class;
      equation 
        // adrpo - here we need to check if we don't have recursive extends of the form:
        // package Icons
        //   extends Icons.BaseLibrary;
        //        model BaseLibrary "Icon for base library"
        //        end BaseLibrary;
        // end Icons;
        // if we don't check that, then the compiler enters an infinite loop!
        // what we do is removing Icons from extends Icons.BaseLibrary;
        cn = removeSelfReference(className, cn);
        
        (cache,(c as SCode.CLASS(name=cn2,encapsulatedPrefix=enc2,restriction=r)),cenv) = Lookup.lookupClass(cache,env, cn, true);
        
        cenv_2 = Env.openScope(cenv, enc2, SOME(cn2));
        (cache,mod_1,fdae) = Mod.elabMod(cache,env, pre, mod, impl);
        new_ci_state = ClassInf.start(r, Env.getEnvName(cenv_2));
        mods_1 = Mod.merge(mods, mod_1, cenv_2, pre);
        eq = Mod.modEquation(mods_1) "instantiate array dimensions" ;
        (cache,dims,fdae1) = elabArraydimOpt(cache,cenv_2, Absyn.CREF_IDENT("",{}),cn, ad, eq, impl, NONE,true) "owncref not valid here" ;
        inst_dims2 = instDimExpLst(dims, impl);
        inst_dims_1 = Util.listListAppendLast(inst_dims, inst_dims2);
        (cache,env_2,ih,store,dae,csets_1,ci_state_1,tys,bc,oDA,eqConstraint,graph) = instClassIn(cache,cenv_2,ih,store,mods_1, pre, csets, new_ci_state, c, prot, 
                    inst_dims_1, impl, graph, instSingleCref) "instantiate class in opened scope. " ;
        ClassInf.assertValid(ci_state_1, re) "Check for restriction violations" ;
        oDA = Absyn.mergeElementAttributes(DA,oDA);        
        dae = DAEUtil.joinDaeLst({dae,fdae,fdae1});        
      then
        (cache,env_2,ih,store,dae,csets_1,ci_state_1,tys,bc,oDA,eqConstraint,graph);
        
    /* MetaModelica extension */
    case (cache,env,ih,store,mods,pre,csets,ci_state,className,
          SCode.DERIVED(Absyn.TCOMPLEX(Absyn.IDENT("list"),tSpecs,_),modifications = mod, attributes=DA),
          re,prot,inst_dims,impl,graph,instSingleCref)
      local 
        list<Absyn.TypeSpec> tSpecs; list<DAE.Type> tys; DAE.Type ty;
        Absyn.ElementAttributes DA;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cache,cenv,ih,tys,csets,oDA) = 
        instClassDefHelper(cache,env,ih,tSpecs,pre,inst_dims,impl,{},csets);
        ty = Util.listFirst(tys);
        bc = SOME((DAE.T_LIST(ty),NONE));
        oDA = Absyn.mergeElementAttributes(DA,oDA);
      then (cache,env,ih,store,DAEUtil.emptyDae,csets,ClassInf.META_LIST(Absyn.IDENT("")),{},bc,oDA,NONE,graph);

    case (cache,env,ih,store,mods,pre,csets,ci_state,className,
          SCode.DERIVED(Absyn.TCOMPLEX(Absyn.IDENT("Option"),tSpecs,_),modifications = mod, attributes=DA),
          re,prot,inst_dims,impl,graph,instSingleCref)
      local 
        list<Absyn.TypeSpec> tSpecs; list<DAE.Type> tys; DAE.Type ty;
        Absyn.ElementAttributes DA;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cache,cenv,ih,tys,csets,oDA) = 
        instClassDefHelper(cache,env,ih,tSpecs,pre,inst_dims,impl,{},csets);
        {ty} = tys;
        bc = SOME((DAE.T_METAOPTION(ty),NONE));
        oDA = Absyn.mergeElementAttributes(DA,oDA);
      then (cache,env,ih,store,DAEUtil.emptyDae,csets,ClassInf.META_OPTION(Absyn.IDENT("")),{},bc,oDA,NONE,graph);

    case (cache,env,ih,store,mods,pre,csets,ci_state,className,
          SCode.DERIVED(Absyn.TCOMPLEX(Absyn.IDENT("tuple"),tSpecs,_),modifications = mod, attributes=DA),
          re,prot,inst_dims,impl,graph,instSingleCref)
      local 
        list<Absyn.TypeSpec> tSpecs; list<DAE.Type> tys;
        Absyn.ElementAttributes DA;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cache,cenv,ih,tys,csets,oDA) = instClassDefHelper(cache,env,ih,tSpecs,pre,inst_dims,impl,{},csets);
        bc = SOME((DAE.T_METATUPLE(tys),NONE));
        oDA = Absyn.mergeElementAttributes(DA,oDA);
      then (cache,env,ih,store,DAEUtil.emptyDae,csets,ClassInf.META_TUPLE(Absyn.IDENT("")),{},bc,oDA,NONE,graph);

    case (cache,env,ih,store,mods,pre,csets,ci_state,className,
          SCode.DERIVED(Absyn.TCOMPLEX(Absyn.IDENT("array"),tSpecs,_),modifications = mod, attributes=DA),
          re,prot,inst_dims,impl,graph,instSingleCref)
      local 
        list<Absyn.TypeSpec> tSpecs; list<DAE.Type> tys; DAE.Type ty;
        Absyn.ElementAttributes DA;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cache,cenv,ih,tys,csets,oDA) = instClassDefHelper(cache,env,ih,tSpecs,pre,inst_dims,impl,{},csets);
        {ty} = tys;
        bc = SOME((DAE.T_META_ARRAY(ty),NONE));
        oDA = Absyn.mergeElementAttributes(DA,oDA);
      then (cache,env,ih,store,DAEUtil.emptyDae,csets,ClassInf.META_ARRAY(Absyn.IDENT(className)),{},bc,oDA,NONE,graph);
    
    case (cache,env,ih,store,mods,pre,csets,ci_state,className,
          SCode.DERIVED(Absyn.TCOMPLEX(Absyn.IDENT("polymorphic"),{Absyn.TPATH(Absyn.IDENT("Any"),NONE)},_),modifications = mod, attributes=DA),
          re,prot,inst_dims,impl,graph,instSingleCref)
      local 
        list<Absyn.TypeSpec> tSpecs; list<DAE.Type> tys; DAE.Type ty;
        Absyn.ElementAttributes DA;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cache,cenv,ih,tys,csets,oDA) = instClassDefHelper(cache,env,ih,{},pre,inst_dims,impl,{},csets);
        bc = SOME((DAE.T_POLYMORPHIC(className),NONE));
        oDA = Absyn.mergeElementAttributes(DA,oDA);
      then (cache,env,ih,store,DAEUtil.emptyDae,csets,ClassInf.META_POLYMORPHIC(Absyn.IDENT(className)),{},bc,oDA,NONE,graph);
    
    case (cache,env,ih,store,mods,pre,csets,ci_state,className,
          SCode.DERIVED(typeSpec=Absyn.TCOMPLEX(path=Absyn.IDENT("polymorphic"))),
          re,prot,inst_dims,impl,graph,instSingleCref)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        Error.addMessage(Error.META_POLYMORPHIC, {className});
      then fail();
    /* ----------------------- */

    /* If the class is derived from a class that can not be found in the environment, this rule prints an error message. */    
    case (cache,env,ih,store,mods,pre,csets,ci_state,className,
          SCode.DERIVED(Absyn.TPATH(path = cn, arrayDim = ad),modifications = mod),
          re,prot,inst_dims,impl,graph,instSingleCref)
      equation 
        failure((_,_,_) = Lookup.lookupClass(cache,env, cn, false));
        cns = Absyn.pathString(cn);
        scope_str = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_ERROR, {cns,scope_str});
      then
        fail();
        
    case (cache,env,ih,store,mods,pre,csets,ci_state,className,
          SCode.DERIVED(Absyn.TPATH(path = cn, arrayDim = ad),modifications = mod),
          re,prot,inst_dims,impl,graph,instSingleCref)
      equation 
				true = RTOpts.debugFlag("failtrace");
        failure((_,_,_) = Lookup.lookupClass(cache,env, cn, false));
        Debug.fprint("failtrace", "- Inst.instClassdef DERIVED( ");
        Debug.fprint("failtrace", Absyn.pathString(cn));
        Debug.fprint("failtrace", ") lookup failed\n ENV:");
        Debug.fprint("failtrace",Env.printEnvStr(env));
      then
        fail();
        
    case (_,env,ih,_,_,_,_,_,_,_,_,_,_,_,_,instSingleCref)
      equation 
        // System.enableTrace();
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- Inst.instClassdef failed");
        s = Env.printEnvPathStr(env);
        Debug.traceln("  class :" +& s);
        // Debug.traceln("  Env :" +& Env.printEnvStr(env));
      then
        fail();
  end matchcontinue;
end instClassdef;

protected function matchModificationToComponents "
Author: BZ, 2009-05
This function is called from instClassDef, recursivly remove modifers on each component.
What ever is left in modifier is printed as a warning. That means that we have modifiers on a component that does not exist.
 
"
  input list<SCode.Element> elems;
  input DAE.Mod inmod;
  input String callingScope;
algorithm _ := matchcontinue(elems, inmod,callingScope)
  local
    SCode.Element elem;
    String cn,s1,s2;
    DAE.Mod mod;
  case({},DAE.NOMOD,_) then ();
  case({},DAE.MOD(subModLst={}),_) then ();
  case({},inmod,callingScope)
    equation
      s1 = Mod.prettyPrintMod(inmod,0); 
      s2 = s1 +& " not found in <" +& callingScope +& ">";
      // Line below can be used for testing test-suite for dangeling modifiers when getErrorString() is not called.
      //print(" *** ERROR Unused modifer...: " +& s2 +& "\n");      
      Error.addMessage(Error.UNUSED_MODIFIER,{s2});
    then fail(); 
      
  case((elem as SCode.COMPONENT(component=cn))::elems,inmod,callingScope)
    equation
      inmod = Types.removeMod(inmod,cn);
      matchModificationToComponents(elems,inmod,callingScope);
    then
      ();
  case((elem as SCode.EXTENDS(modifications=_))::elems,inmod,callingScope)
    equation matchModificationToComponents(elems,inmod,callingScope); then ();
      //TODO: only remove modifiers on replaceable classes, make special case for redeclaration of local classes 
  case((elem as SCode.CLASSDEF(name=cn,replaceablePrefix=_/*true*/))::elems,inmod,callingScope)
    equation 
      inmod = Types.removeMod(inmod,cn);
      matchModificationToComponents(elems,inmod,callingScope); 
    then ();
  case((elem as SCode.IMPORT(imp=_))::elems,inmod,callingScope)
    equation matchModificationToComponents(elems,inmod,callingScope); then ();
  case( (elem as SCode.CLASSDEF(replaceablePrefix=false))::elems,inmod,callingScope)
    equation
      matchModificationToComponents(elems,inmod,callingScope); 
    then ();
end matchcontinue;
end matchModificationToComponents;

protected function extractConstantPlusDeps "
Author: BZ, 2009-04
This function filters the list of elements to instantiate depending on optional(DAE.ComponentRef), the
optional argument is set in Lookup.lookupVarInPackages.
If it is set, we are only looking for one variable in current scope hence we are not interested in 
instantiating more then nescessary.

The actuall action of this function is to compare components to the DAE.ComponentRef name
if it is found return that component and any dependant components(modifiers), this is done by calling the function recursivly.

If the component specified in argument 2 is not found, we return all extend and import statements.
TODO: search import and extends statements for specified variable.
       this includes to check class definitions to so that we do not need to instantiate local class definitions while looking for a constant.
"
  input list<SCode.Element> inComps;
  input Option<DAE.ComponentRef> ocr;
  input list<SCode.Element> allComps;
  input String className;
  output list<SCode.Element> outComps;
algorithm outComps := matchcontinue(inComps, ocr,allComps,className)
  local DAE.ComponentRef cr;
  case(inComps, NONE,allComps,className) then inComps;
  case(inComps, SOME(cr), allComps,className)
    local
      list<String> elemStrings;
      list<SCode.Element> elems;
    equation
      outComps = extractConstantPlusDeps2(inComps, ocr,allComps,className,{});
      true = listLength(outComps) >= 1;
      outComps = listReverse(outComps);
    then 
      outComps;
  case(inComps, SOME(cr), allComps,className)
    equation
			true = RTOpts.debugFlag("failtrace");
      Debug.fprint("failtrace", "ExtractConstantPlusDeps::Failure to find " +& Exp.printComponentRefStr(cr) +& ", returning \n");
      Debug.fprint("failtrace", "Elements to instantiate:" +& intString(listLength(inComps)) +& "\n");
    then 
      inComps;
end matchcontinue;
end extractConstantPlusDeps;
  
protected function extractConstantPlusDeps2 "
Author: BZ, 2009-04
Helper function for extractConstantPlusDeps
"
  input list<SCode.Element> inComps;
  input Option<DAE.ComponentRef> ocr;
  input list<SCode.Element> allComps;
  input String className;
  input list<String> existing;
  output list<SCode.Element> outComps;
algorithm outComps := matchcontinue(inComps, ocr,allComps,className,existing)
  local
    SCode.Element compMod;
    list<SCode.Element> recDeps;
    SCode.Element selem;
    DAE.Mod mod;
    String name,name2;
    SCode.Mod umod,scmod;
    case({},SOME(cr),_,_,_)
      local DAE.ComponentRef cr; 
      equation
        //print(" failure to find: " +& Exp.printComponentRefStr(cr) +& " in scope: " +& className +& "\n");
      then {};
    case({},_,_,_,_) then fail();
    case(inComps,NONE,_,_,_) then inComps;
      /*
    case( (selem as SCode.CLASSDEF(name=name2))::inComps,SOME(DAE.CREF_IDENT(ident=name)),allComps,className,existing)
      local
        list<Absyn.ComponentRef> crefs,crefs2;
      equation
        true = stringEqual(name,name2);
        outComps = extractConstantPlusDeps2(inComps,ocr,allComps,className,existing);
      then
        selem::outComps;
        */
    case( ((selem as SCode.CLASSDEF(name=name2)))::inComps,SOME(DAE.CREF_IDENT(ident=name)),allComps,className,existing)
      equation
        //false = stringEqual(name,name2);   
        allComps = listAppend({selem},allComps);
        existing = listAppend({name2},existing);
        outComps = extractConstantPlusDeps2(inComps,ocr,allComps,className,existing);
      then //extractConstantPlusDeps2(inComps,ocr,allComps,className,existing);
         selem::outComps;
         
    case((selem as SCode.COMPONENT(component=name2,modifications=scmod))::inComps,SOME(DAE.CREF_IDENT(ident=name)),allComps,className,existing)
      local 
        list<Absyn.ComponentRef> crefs,crefs2;
      equation
        true = stringEqual(name,name2);
        crefs = getCrefFromMod(scmod);
        allComps = listAppend(inComps,allComps);
        existing = listAppend({name2},existing);
        recDeps = extractConstantPlusDeps3(crefs,allComps,className,existing);
      then
        selem::recDeps;
        
    case( ( (selem as SCode.COMPONENT(component=name2)))::inComps,SOME(DAE.CREF_IDENT(ident=name)),allComps,className,existing)
      equation
        false = stringEqual(name,name2);
        allComps = listAppend({selem},allComps);
      then extractConstantPlusDeps2(inComps,ocr,allComps,className,existing);
         
    case((compMod as SCode.EXTENDS(baseClassPath=p))::inComps,(ocr as SOME(DAE.CREF_IDENT(ident=_))),allComps,className,existing)
      local Absyn.Path p; 
      equation 
        allComps = listAppend({compMod},allComps);
        recDeps = extractConstantPlusDeps2(inComps,ocr,allComps,className,existing); 
        then 
          compMod::recDeps;
    case((compMod as SCode.IMPORT(imp=_))::inComps,(ocr as SOME(DAE.CREF_IDENT(ident=_))),allComps,className,existing) 
      equation 
        allComps = listAppend({compMod},allComps);
        recDeps = extractConstantPlusDeps2(inComps,ocr,allComps,className,existing); 
      then 
        compMod::recDeps;
        
    case((compMod as SCode.DEFINEUNIT(name=_))::inComps,(ocr as SOME(DAE.CREF_IDENT(ident=_))),allComps,className,existing) 
      equation 
        allComps = listAppend({compMod},allComps);
        recDeps = extractConstantPlusDeps2(inComps,ocr,allComps,className,existing); 
      then 
        compMod::recDeps;
    case(inComps, ocr, allComps, className, existing) 
      equation
        //debug_print("all",  (inComps, ocr, allComps, className, existing));
        print(" failure in get_Constant_PlusDeps \n"); 
      then fail();   
end matchcontinue;
end extractConstantPlusDeps2;

protected function extractConstantPlusDeps3 "
Author: BZ, 2009-04
Helper function for extractConstantPlusDeps
"
input list<Absyn.ComponentRef> acrefs;
input list<SCode.Element> remainingComps;
input String className;
input list<String> existing;
output list<SCode.Element> outComps;
algorithm outComps := matchcontinue(acrefs,remainingComps,className,existing)
  local
    String s1,s2,s3,s4;
    Absyn.ComponentRef acr;
    list<SCode.Element> localComps;
  case({},_,_,_) then {};
  case(Absyn.CREF_QUAL(s1,_,(acr as Absyn.CREF_IDENT(s2,_)))::acrefs,remainingComps,className,existing)
    equation
      true = stringEqual(className,s1); // in same scope look up.
      acrefs = acr::acrefs;
      then
        extractConstantPlusDeps3(acrefs,remainingComps,className,existing);
  case((acr as Absyn.CREF_QUAL(s1,_,_))::acrefs,remainingComps,className,existing)
    equation
      false = stringEqual(className,s1);
      outComps = extractConstantPlusDeps3(acrefs,remainingComps,className,existing);
      then
        outComps;
  case(Absyn.CREF_IDENT(s1,_)::acrefs,remainingComps,className,existing) // modifer dep already added
    equation
      true = Util.listContainsWithCompareFunc(s1,existing,stringEqual);
    then 
      extractConstantPlusDeps3(acrefs,remainingComps,className,existing);
  case(Absyn.CREF_IDENT(s1,_)::acrefs,remainingComps,className,existing)
    local 
      list<SCode.Element> elems;
      list<String> names;
    equation
      localComps = extractConstantPlusDeps2(remainingComps,SOME(DAE.CREF_IDENT(s1,DAE.ET_OTHER(),{})),{},className,existing);
      names = SCode.componentNamesFromElts(localComps);
      existing = listAppend(names,existing);
      outComps = extractConstantPlusDeps3(acrefs,remainingComps,className,existing);
      outComps = listAppend(localComps,outComps);
    then
      outComps;
  end matchcontinue;
end extractConstantPlusDeps3;

public function removeSelfReference
"@author adrpo
 Removes self reference from a path if it exists.
 Examples:
   removeSelfReference('Icons', 'Icons.BaseLibrary') => 'BaseLibrary'
   removeSelfReference('Icons', 'BlaBla.BaseLibrary') => 'BlaBla.BaseLibrary'"
  input  String     className;
  input  Absyn.Path path;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue (className, path)
    local
      String clsName;
      Absyn.Path p, newPath;
    case(clsName, p) // self reference, remove the first.
      equation
        true = stringEqual(clsName, Absyn.pathFirstIdent(p));
        newPath = Absyn.removePrefix(Absyn.IDENT(clsName), p);
      then
        newPath;
    case(clsName, p) // not self reference, return the same.
      equation
        false = stringEqual(clsName, Absyn.pathFirstIdent(p));
      then
        p;
  end matchcontinue;
end removeSelfReference;

protected function instClassDefHelper 
"Function: instClassDefHelper
 MetaModelica extension. KS TODO: Document this function!!!!"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input list<Absyn.TypeSpec> inSpecs;
  input Prefix.Prefix inPre;
  input InstDims inDims;
  input Boolean inImpl;
  input list<DAE.Type> accTypes;
  input Connect.Sets inCSets;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InstanceHierarchy outIH;
  output list<DAE.Type> outType;
  output Connect.Sets outSets;
  output Option<Absyn.ElementAttributes> outAttr;
algorithm
  (outCache,outEnv,outIH,outType,outSets,outAttr) := 
  matchcontinue (inCache,inEnv,inIH,inSpecs,inPre,inDims,inImpl,accTypes,inCSets)
    local
      Env.Cache cache; Env.Env env; Prefix.Prefix pre; InstDims dims; Boolean impl;
      list<DAE.Type> localAccTypes;
      list<Absyn.TypeSpec> restTypeSpecs; Connect.Sets csets;
      Absyn.Path cn; SCode.Class c;
      Env.Env cenv; DAE.Type ty;
      Absyn.Path p; SCode.Class c;
      Env.Env cenv; 
      Absyn.Ident id; 
      Absyn.TypeSpec tSpec;
      Absyn.ElementAttributes attr;
      Option<Absyn.ElementAttributes> oDA;
      InstanceHierarchy ih;
            
    case (cache,env,ih,{},_,_,_,localAccTypes,csets) 
      then (cache,env,ih,localAccTypes,csets,NONE);

    case (cache,env,ih, Absyn.TPATH(cn,_) :: restTypeSpecs,pre,dims,impl,localAccTypes,csets)
      equation
        (cache,(c as SCode.CLASS(name = _)),cenv) = Lookup.lookupClass(cache,env, cn, true);
        (cache,cenv,ih,_,_,csets,ty,_,oDA,_)=instClass(cache,cenv,ih,UnitAbsyn.noStore,DAE.NOMOD(),pre,csets,c,dims,impl,INNER_CALL(), ConnectionGraph.EMPTY);
        localAccTypes = listAppend(localAccTypes,{ty});
        (cache,env,ih,localAccTypes,csets,_) = 
        instClassDefHelper(cache,env,ih,restTypeSpecs,pre,dims,impl,localAccTypes,csets);         
      then (cache,env,ih,localAccTypes,csets,oDA);

    case (cache,env,ih, (tSpec as Absyn.TCOMPLEX(p,_,_)) :: restTypeSpecs,pre,dims,impl,localAccTypes,csets)
      equation
        id=Absyn.pathString(p);
        c = SCode.CLASS(id,false,false,SCode.R_TYPE(),
                        SCode.DERIVED(tSpec,SCode.NOMOD(),
                        Absyn.ATTR(false, false, Absyn.VAR(), Absyn.BIDIR(), {}),
                        NONE()),Absyn.dummyInfo);
        (cache,cenv,ih,_,_,csets,ty,_,oDA,_)=instClass(cache,env,ih,UnitAbsyn.noStore,DAE.NOMOD(),pre,csets,c,dims,impl,INNER_CALL(), ConnectionGraph.EMPTY);        
        localAccTypes = listAppend(localAccTypes,{ty});
        (cache,env,ih,localAccTypes,csets,_) = instClassDefHelper(cache,env,ih,restTypeSpecs,pre,dims,impl,localAccTypes,csets);
      then (cache,env,ih,localAccTypes,csets,oDA);
  end matchcontinue;
end instClassDefHelper;

protected function instantiateExternalObject 
"instantiate an external object. 
 This is done by instantiating the destructor and constructor
 functions and create a DAE element containing these two."
  input Env.Cache inCache;
  input Env.Env env "environment";
  input InstanceHierarchy inIH;
  input list<SCode.Element> els "elements";
  input Boolean impl;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist dae "resulting dae";
  output ClassInf.State ciState;
algorithm
  (outCache,outEnv,outIH,dae,ciState) := matchcontinue(inCache,env,inIH,els,impl) 
 	 local 
 	   SCode.Class destr,constr;
 	   DAE.Element destr_dae,constr_dae;
 	   Env.Env env1;
 	   Env.Cache cache;
 	   Ident className;
 	   Absyn.Path classNameFQ;
 	   DAE.Type functp;
 	   Env.Frame f;
 	   list<Env.Frame> fs,fs1;
 	   Absyn.Path classNameFQ;
 	   InstanceHierarchy ih;
 	   DAE.ElementSource source "the origin of the element";
     DAE.FunctionTree funcs;
 	   // Explicit instantiation, generate constructor and destructor and the function type.
    case	(cache,env,ih,els,false) 
      equation     
        destr = getExternalObjectDestructor(els);
        constr = getExternalObjectConstructor(els);
        (cache,ih,destr_dae) = instantiateExternalObjectDestructor(cache,env,ih,destr);
        (cache,ih,constr_dae,functp) = instantiateExternalObjectConstructor(cache,env,ih,constr);
        className=Env.getClassName(env); // The external object classname is in top frame of environment.
        SOME(classNameFQ)= Env.getEnvPath(env); // Fully qualified classname
        // Extend the frame with the type, one frame up at the same place as the class.
        f::fs = env;
        fs1 = Env.extendFrameT(fs,className,functp);
        env1 = f::fs1; 
            
        // set the  of this element
       source = DAEUtil.addElementSourcePartOfOpt(DAE.emptyElementSource, Env.getEnvPath(env));
       
       funcs = DAEUtil.avlTreeNew();
      then 
        (cache,env1,ih,DAE.DAE({DAE.EXTOBJECTCLASS(classNameFQ,constr_dae,destr_dae,source)},funcs),ClassInf.EXTERNAL_OBJ(classNameFQ));
      
    // Implicit, do not instantiate constructor and destructor.
    case (cache,env,ih,els,true) 
      equation 
        SOME(classNameFQ)= Env.getEnvPath(env); // Fully qualified classname
      then 
        (cache,env,ih,DAEUtil.emptyDae,ClassInf.EXTERNAL_OBJ(classNameFQ));
    
    // failed
    case (cache,env,ih,els,impl) 
      equation
        print("Inst.instantiateExternalObject failed\n");
      then fail();
  end matchcontinue;   
end instantiateExternalObject;

protected function instantiateExternalObjectDestructor 
"instantiates the destructor function of an external object"
  input Env.Cache inCache;
	input Env.Env env;
	input InstanceHierarchy inIH;
	input SCode.Class cl;
	output Env.Cache outCache;
	output InstanceHierarchy outIH;
	output DAE.Element dae;
algorithm	
  (outCache,outIH,dae) := matchcontinue (inCache,env,inIH,cl)
  local 
        Env.Cache cache;
  	    Env.Env env1;
  	    DAE.Element daeElt;
  	    String s;
  	    InstanceHierarchy ih;
  	    
  	case (cache,env,ih,cl) 
  		equation
  		  (cache,env1,ih,DAE.DAE({daeElt},_)) = implicitFunctionInstantiation(cache,env,ih, DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, cl, {}) ;
  	then
  	  (cache,ih,daeElt);
  	// failure
  	case (cache,env,ih,cl)
  	  equation
  	    print("Inst.instantiateExternalObjectDestructor failed\n");
  	  then fail();
   end matchcontinue;   	  
end instantiateExternalObjectDestructor;

protected function instantiateExternalObjectConstructor 
"instantiates the constructor function of an external object"
	input Env.Cache inCache;
	input Env.Env env;
	input InstanceHierarchy inIH;
	input SCode.Class cl;
	output Env.Cache outCache;
	output InstanceHierarchy outIH;
	output DAE.Element dae;
	output DAE.Type tp;
algorithm	
	(outCaceh,inIH,dae) := matchcontinue (inCache,env,outIH,cl)
	local	
      Env.Cache cache;
      Env.Env env1;
      DAE.Element daeElt;
      DAE.Type funcTp;
      String s;
      InstanceHierarchy ih;
      
  	case (cache,env,ih,cl) 
  		equation
  		  (cache,env1,ih,DAE.DAE({daeElt as DAE.FUNCTION(type_ = funcTp, functions=(DAE.FUNCTION_EXT(body=_)::_))},_))
  		     	= implicitFunctionInstantiation(cache,env,ih, DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, cl, {}) ;
  	then
  	  (cache,ih,daeElt,funcTp);
	  case (cache,env,ih,cl)
  	  equation
        print("Inst.instantiateExternalObjectConstructor failed\n");
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
    case SCode.CLASS(classDef=SCode.PARTS(elementLst=els))
      equation
        res = isExternalObject(els);
     then res;       
    case (_) then false;
  end matchcontinue;
end classIsExternalObject;

public function isExternalObject 
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
    case SCode.EXTENDS(baseClassPath = Absyn.IDENT("ExternalObject"))::_ then true;
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
    case SCode.CLASSDEF(classDef = SCode.CLASS(name="destructor"))::_ then true;
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
    case SCode.CLASSDEF(classDef = SCode.CLASS(name="constructor"))::_ then true;
  	case _::els then hasExternalObjectConstructor(els);
  	case _ then false;
  end matchcontinue;
end hasExternalObjectConstructor;

protected function getExternalObjectDestructor 
"returns the class 'function destructor .. end destructor' from element list"
input list<SCode.Element> els;
output SCode.Class cl;
algorithm 
  cl:= matchcontinue(els) 
    local SCode.Class cl;
    case SCode.CLASSDEF(classDef = cl as SCode.CLASS(name="destructor"))::_ then cl;
  	case _::els then getExternalObjectDestructor(els);
  end matchcontinue;
end getExternalObjectDestructor;

protected function getExternalObjectConstructor 
"returns the class 'function constructor ... end constructor' from element list"
input list<SCode.Element> els;
output SCode.Class cl;
algorithm 
  cl:= matchcontinue(els)
    case SCode.CLASSDEF(classDef = cl as SCode.CLASS(name="constructor"))::_ then cl;
  	case _::els then getExternalObjectConstructor(els);
  end matchcontinue;
end getExternalObjectConstructor;
 
public function printExtcomps 
"prints the tuple of elements and modifiers to stdout"
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst;
algorithm 
  _ := matchcontinue (inTplSCodeElementModLst)
    local
      String s;
      SCode.Element el;
      DAE.Mod mod;
      list<tuple<SCode.Element, Mod>> els;
    case ({}) then (); 
    case (((el,mod) :: els))
      equation 
        s = SCode.printElementStr(el);
        print(s);
        print(", ");print(Mod.printModStr(mod));
        print("\n");
        printExtcomps(els);
      then
        ();
  end matchcontinue;
end printExtcomps;

protected function instBasictypeBaseclass 
"function: instBasictypeBaseclass
  This function finds the type of classes that extends a basic type.
  For instance,
  connector RealSignal
    extends SignalType;
    replaceable type SignalType = Real;
  end RealSignal;
  Such classes can not have any other components, 
  and can only inherit one basic type."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input UnitAbsyn.InstStore store;
  input list<SCode.Element> inSCodeElementLst2;
  input list<SCode.Element> inSCodeElementLst3;
  input Mod inMod4;
  input InstDims inInstDims5;
  output Env.Cache outCache;
  output InstanceHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output Option<DAE.Type> outTypesTypeOption;
  output list<DAE.Var> outTypeVars;
algorithm 
  (outCache,outIH,outStore,outTypesTypeOption,outTypeVars) := 
  matchcontinue (inCache,inEnv,inIH,store,inSCodeElementLst2,inSCodeElementLst3,inMod4,inInstDims5)
    local
      DAE.Mod m_1,m_2,mods;
      SCode.Class cdef,cdef_1;
      list<Env.Frame> cenv,env_1,env;
      DAE.DAElist dae;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      list<DAE.Var> tys;
      ClassInf.State st;
      Boolean b1,b2,b3;
      Absyn.Path path;
      SCode.Mod mod;
      InstDims inst_dims;
      String classname;
      Env.Cache cache;
      InstanceHierarchy ih;
      
    case (cache,env,ih,store,{SCode.EXTENDS(baseClassPath = path,modifications = mod)},{},mods,inst_dims)
      equation 
        ErrorExt.setCheckpoint();
        (cache,m_1,_) = Mod.elabMod(cache,env, Prefix.NOPRE(), mod, true) "impl" ;
        m_2 = Mod.merge(mods, m_1, env, Prefix.NOPRE());
        (cache,cdef,cenv) = Lookup.lookupClass(cache,env, path, true);
        (cache,env_1,ih,store,dae,_,ty,tys,st) = instClassBasictype(cache,cenv,ih, store,m_2, Prefix.NOPRE(), Connect.emptySet, cdef, inst_dims, false, INNER_CALL());
        b1 = Types.basicType(ty);
        b2 = Types.arrayType(ty);
        b3 = Types.extendsBasicType(ty);
        true = Util.boolOrList({b1, b2, b3});
        ErrorExt.rollBack();
      then
        (cache,ih,store,SOME(ty),tys);
    case (cache,env,ih,store,{SCode.EXTENDS(baseClassPath = path,modifications = mod)},{},mods,inst_dims)
      equation
        rollbackCheck(path) "only rollback errors affection basic types";
      then fail();        
    
    /* Inherits baseclass -and- has components */
    case (cache,env,ih,store,{SCode.EXTENDS(baseClassPath = path,modifications = mod)},inSCodeElementLst3,mods,inst_dims) 
      equation
        true = (listLength(inSCodeElementLst3) > 0);
        instBasictypeBaseclass2(cache,env,ih,store,inSCodeElementLst2,inSCodeElementLst3,mods,inst_dims);
      then
        fail();
    case(_,_,_,_,_,_,_,_) equation 
        then fail();
  end matchcontinue;
end instBasictypeBaseclass;

protected function rollbackCheck "
Author BZ 2009-08
Rollsback errors on builtin classes.
"
  input Absyn.Path p;
algorithm _ := matchcontinue(p)
  local String n;
  case(p) 
    equation
      n = Absyn.pathString(p);
      true = isBuiltInClass(n);
      ErrorExt.rollBack();
    then ();
  case(p)
    equation
      n = Absyn.pathString(p);
      false = isBuiltInClass(n);
    then ();  
end matchcontinue;
end rollbackCheck;

protected function instBasictypeBaseclass2 "
Author: BZ, 2009-02
Helper function for instBasictypeBaseClass
Handles the fail case rollbacks/deleteCheckpoint of errors.
"
	input Env.Cache inCache;
  input Env inEnv1;
  input InstanceHierarchy inIH;
  input UnitAbsyn.InstStore store;
  input list<SCode.Element> inSCodeElementLst2;
  input list<SCode.Element> inSCodeElementLst3;
  input Mod inMod4;
  input InstDims inInstDims5;
  algorithm _ := matchcontinue(inCache,inEnv1,inIH,store,inSCodeElementLst2,inSCodeElementLst3,inMod4,inInstDims5)
        local
      DAE.Mod m_1,m_2,mods;
      SCode.Class cdef,cdef_1;
      list<Env.Frame> cenv,env_1,env;
      DAE.DAElist dae;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      list<DAE.Var> tys;
      ClassInf.State st;
      Boolean b1,b2,b3;
      Absyn.Path path;
      SCode.Mod mod;
      InstDims inst_dims;
      String classname;
      Env.Cache cache;
      InstanceHierarchy ih;
    case (cache,env,ih,store,{SCode.EXTENDS(baseClassPath = path,modifications = mod)},(_ :: _),mods,inst_dims) /* Inherits baseclass -and- has components */
      equation     
        (cache,m_1,_) = Mod.elabMod(cache,env, Prefix.NOPRE(), mod, true) "impl" ;
        (cache,cdef,cenv) = Lookup.lookupClass(cache,env, path, true);
        cdef_1 = SCode.classSetPartial(cdef, false);
        (cache,env_1,ih,_,dae,_,ty,st,_,_) = instClass(cache,cenv,ih,store, m_1, Prefix.NOPRE(), Connect.emptySet, cdef_1, inst_dims, false, INNER_CALL(), ConnectionGraph.EMPTY) "impl" ;
        b1 = Types.basicType(ty);
        b2 = Types.arrayType(ty);
        true = boolOr(b1, b2);
        classname = Env.printEnvPathStr(env);
        ErrorExt.rollBack();
        Error.addMessage(Error.INHERIT_BASIC_WITH_COMPS, {classname});
      then
        ();    
    // if not error above, then do not report error at all, try another case in instClassdef.
    case (_,_,_,_,_,_,_,_) equation      
      ErrorExt.rollBack(); then (); 
    end matchcontinue;
end instBasictypeBaseclass2;

protected function addConnectionSetToEnv 
"function: addConnectionSetToEnv
  Adds the connection set and Prefix to the environment such that Ceval can reach it.
  It is required to evaluate cardinality."
  input Connect.Sets inSets;
  input Prefix.Prefix prefix;
  input Env inEnv;
  input InstanceHierarchy inIH;
  output Env outEnv;
  output InstanceHierarchy outIH;
algorithm 
  (outEnv,outIH) := matchcontinue (inSets,prefix,inEnv,inIH)
    local
      list<DAE.ComponentRef> crs;
      Option<String> n;
      Env.AvlTree bt2;
      Env.AvlTree bt1;
      list<Env.Item> imp;
      DAE.ComponentRef prefix_cr;
      list<Env.Frame> bc,fs;
      Boolean enc;
      InstanceHierarchy ih;
      list<SCode.Element> defineUnits;
      
    case (Connect.SETS(connection = crs),prefix,      
      (Env.FRAME( n,bt1,bt2,imp,bc,_,enc,defineUnits) :: fs),ih)
      equation
        prefix_cr = PrefixUtil.prefixToCref(prefix);
    then (Env.FRAME(n,bt1,bt2,imp,bc,(crs,prefix_cr),enc,defineUnits) :: fs,ih); 
    case (Connect.SETS(connection = crs),prefix,
        (Env.FRAME(n,bt1,bt2,imp,bc,_,enc,defineUnits) :: fs),ih)
      equation
      then (Env.FRAME(n,bt1,bt2,imp,bc,(crs,DAE.CREF_IDENT("",DAE.ET_OTHER(),{})),enc,defineUnits) :: fs,ih); 
 
  end matchcontinue;
end addConnectionSetToEnv;

protected function addConnectionCrefs
"function: addConnectionCrefs
  author: PA
  This function adds the connection component references
  from local equations to the connection sets."
  input Connect.Sets inSets;
  input list<SCode.Equation> inSCodeEquationLst;
  output Connect.Sets outSets;
algorithm 
  outSets := matchcontinue (inSets,inSCodeEquationLst)
    local
      Connect.Sets sets,sets_1;
      DAE.ComponentRef cr1_1,cr2_1;
      list<DAE.ComponentRef> crs_1,crs;
      Absyn.ComponentRef cr1,cr2;
      list<SCode.Equation> es;
      list<Connect.Set> setList;
      list<DAE.ComponentRef> dc;
      list<Connect.OuterConnect> oc;
      list<Connect.Set> setLst;
      
    case (sets,{}) then sets; 
    case (Connect.SETS(setLst = setLst,connection = crs,deletedComponents=dc,outerConnects=oc),
          (SCode.EQUATION(eEquation = SCode.EQ_CONNECT(crefLeft = cr1,crefRight = cr2)) :: es))
      equation 
        cr1_1 = Exp.toExpCref(cr1);
        cr2_1 = Exp.toExpCref(cr2);
        crs_1 = listAppend(crs, {cr1_1,cr2_1});
        sets_1 = addConnectionCrefs(Connect.SETS(setLst,crs_1,dc,oc), es);
      then
        sets_1;
    case (sets,(_ :: es))
      equation 
        sets_1 = addConnectionCrefs(sets, es);
      then
        sets_1;
  end matchcontinue;
end addConnectionCrefs;

protected function filterConnectionSetCrefs 
"function: filterConnectionSetCrefs
  author: PA
  This function investigates Prefix and filters all connectRefs 
  to only contain references starting with actual prefix."
  input Connect.Sets inSets;
  input Prefix inPrefix;
  output Connect.Sets outSets;
algorithm 
  outSets := matchcontinue (inSets,inPrefix)
    local
      Connect.Sets s;
      Prefix.Prefix first_pre,pre;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crs_1,crs;
      list<Connect.Set> set;
      list<DAE.ComponentRef> dc;
      list<Connect.OuterConnect> oc;
    case (s,Prefix.NOPRE()) then s;  /* no Prefix, nothing to filter */ 
    case (Connect.SETS(setLst = set,connection = crs,deletedComponents=dc,outerConnects=oc),pre)
      equation 
        first_pre = PrefixUtil.prefixFirst(pre);
        cr = PrefixUtil.prefixToCref(first_pre);
        crs_1 = Util.listSelect1R(crs, cr, Exp.crefPrefixOf);
      then
        Connect.SETS(set,crs_1,dc,oc);
  end matchcontinue;
end filterConnectionSetCrefs;

protected function partialInstClassdef 
"function: partialInstClassdef
  This function is used by partialInstClassIn for instantiating local
  class definitons and inherited class definitions only."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.ClassDef inClassDef;
  input SCode.Restriction inRestriction;
  input Boolean inPartialPrefix;
  input Boolean inProt;
  input InstDims inInstDims;
  input String inClassName "the class name that contains the elements we are instanting";
	output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output ClassInf.State outState;
algorithm 
  (outCache,outEnv,outIH,outState):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inClassDef,inRestriction,inPartialPrefix,inProt,inInstDims,inClassName)
    local
      ClassInf.State ci_state1,ci_state,new_ci_state,new_ci_state_1,ci_state2;
      list<SCode.Element> cdefelts,extendselts,els,allEls,cdefelts2,classextendselts,compelts;
      list<Env.Frame> env1,env2,env,cenv,cenv_2,env_2,env3;
      DAE.Mod emods,mods,m,mod_1,mods_1,mods_2;
      list<tuple<SCode.Element, Mod>> extcomps,allEls2,lst_constantEls;
      list<SCode.Equation> eqs2,initeqs2,eqs,initeqs;
      list<SCode.Algorithm> alg2,initalg2,alg,initalg;
      Prefix.Prefix pre;
      Connect.Sets csets;
      SCode.Restriction re,r;
      Boolean prot,enc2,isPackage,partialPrefix;
      InstDims inst_dims;
      SCode.Class c;
      String cn2,cns,scope_str,className,baseClassName;
      Absyn.Path cn;
      Option<list<Absyn.Subscript>> ad;
      SCode.Mod mod;
      Env.Cache cache;
      String str,str2,str3;
      Real t1,t2,time; Boolean b;
      InstanceHierarchy ih;

      /* long class definition */  /* the normal case, a class with parts */
      /*
    case (cache,env,ih,mods,pre,csets,ci_state,
          SCode.PARTS(elementLst = els,
                      normalEquationLst = eqs, initialEquationLst = initeqs,
      		            normalAlgorithmLst = alg, initialAlgorithmLst = initalg),
      	  re,prot,inst_dims,className)
      equation
        ci_state1 = ClassInf.trans(ci_state, ClassInf.NEWDEF());
        (cdefelts,classextendselts,extendselts,_) = splitElts(els);
        (env1,ih) = addClassdefsToEnv(env, ih, cdefelts, true, NONE) " CLASSDEF & IMPORT nodes are added to env" ;
        (cache,env2,ih,emods,extcomps,eqs2,initeqs2,alg2,initalg2) = 
        partialInstExtendsAndClassExtendsList(cache,env1,ih, mods, extendselts, classextendselts, ci_state, className, true)
        "2. EXTENDS Nodes inst_Extends_List only flatten inhteritance structure. It does not perform component instantiations." ;
		    lst_constantEls = addNomod(constantEls(els)) " Retrieve all constants";
	      *//* 
	       Since partial instantiation is done in lookup, we need to add inherited classes here.
	       Otherwise when looking up e.g. A.B where A inherits the definition of B, and without having a
	       base class context (since we do not have any element to find it in), the class must be added 
	       to the environment here.
	      *//*
        cdefelts2 = classdefElts2(extcomps);
        (env2,ih) = addClassdefsToEnv(env2,ih,cdefelts2,true,NONE); // Add inherited classes to env
        (cache,env3,ih) = addComponentsToEnv(cache, env2, ih, mods, pre, csets, ci_state, 
                                             lst_constantEls, lst_constantEls, {}, 
                                             inst_dims, false);
      then
        (cache,env3,ih,ci_state1);
    */
      
      case (cache,env,ih,mods,pre,csets,ci_state,
          SCode.PARTS(elementLst = els,
            normalEquationLst = eqs, initialEquationLst = initeqs,
            normalAlgorithmLst = alg, initialAlgorithmLst = initalg),
            re,partialPrefix,prot,inst_dims,className)
      equation
        ci_state1 = ClassInf.trans(ci_state, ClassInf.NEWDEF());
        (cdefelts,classextendselts,extendselts,_) = splitElts(els);
        (env1,ih) = addClassdefsToEnv(env, ih, cdefelts, true, NONE) " CLASSDEF & IMPORT nodes are added to env" ;
        (cache,env2,ih,emods,extcomps) = 
        partialInstExtendsAndClassExtendsList(cache,env1,ih, mods, extendselts, classextendselts, ci_state, className, true)
        "2. EXTENDS Nodes inst_Extends_List only flatten inhteritance structure. It does not perform component instantiations." ;
        els = Util.if_(partialPrefix, {}, els);
        // If we partially instantiate a partial package, we filter out constants (maybe we should also filter out functions) /sjoelund
		    lst_constantEls = addNomod(constantEls(els)) " Retrieve all constants";
	      /* 
	       Since partial instantiation is done in lookup, we need to add inherited classes here.
	       Otherwise when looking up e.g. A.B where A inherits the definition of B, and without having a
	       base class context (since we do not have any element to find it in), the class must be added 
	       to the environment here.
	      */	      
        (cdefelts2,extcomps) = classdefElts2(extcomps, partialPrefix);
        // lst_constantEls = listAppend(extcomps,lst_constantEls); // Adding this line breaks mofiles/ClassExtends3.mo
        (env2,ih) = addClassdefsToEnv(env2,ih,cdefelts2,true,NONE); // Add inherited classes to env
        (cache,env3,ih,_/*Skip collecting functions here, since partial */) = addComponentsToEnv(cache, env2, ih, mods, pre, csets, ci_state, 
                                             lst_constantEls, lst_constantEls, {}, 
                                             inst_dims, false);
        (cache,env3,ih,_,_,_,ci_state2,_,_) = 
           instElementList(cache, env3, ih, UnitAbsyn.noStore, mods, pre, csets, ci_state1, lst_constantEls, 
                          inst_dims, true, ConnectionGraph.EMPTY) "instantiate constants";
      then
        (cache,env3,ih,ci_state2);
    /* Short class definition */
    /* This rule describes how to instantiate a derived class definition */ 
    case (cache,env,ih,mods,pre,csets,ci_state,
          SCode.DERIVED(Absyn.TPATH(path = cn, arrayDim = ad),modifications = mod),
          re,partialPrefix,prot,inst_dims,className) 
      equation 
        (cache,(c as SCode.CLASS(name=cn2,encapsulatedPrefix=enc2,restriction=r)),cenv) = Lookup.lookupClass(cache, env, cn, true);
        cenv_2 = Env.openScope(cenv, enc2, SOME(cn2));
        (cache,mod_1,_) = Mod.elabMod(cache,env, pre, mod, false);
        new_ci_state = ClassInf.start(r, Env.getEnvName(cenv_2));
        mods_1 = Mod.merge(mods, mod_1, cenv_2, pre);
        (cache,env_2,ih,new_ci_state_1) = partialInstClassIn(cache, cenv_2, ih, mods_1, pre, csets, new_ci_state, c, prot, inst_dims);
      then
        (cache,env_2,ih,new_ci_state_1);

    /* If the class is derived from a class that can not be found in the environment, 
     * this rule prints an error message. 
     */
    case (cache,env,ih,mods,pre,csets,ci_state,
          SCode.DERIVED(Absyn.TPATH(path = cn, arrayDim = ad),modifications = mod),
          re,partialPrefix,prot,inst_dims,className)
      equation 
        failure((_,_,_) = Lookup.lookupClass(cache,env, cn, false));
        cns = Absyn.pathString(cn);
        scope_str = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_ERROR, {cns,scope_str});
      then
        fail();
  end matchcontinue;
end partialInstClassdef;

protected function constantEls 
"Returns only elements that are constants.
author: PA
Used buy partialInstClassdef to instantiate constants in packages."
input list<SCode.Element> elements;
output list<SCode.Element> outElements;
algorithm 
  outElements := matchcontinue (elements) 
  local 
    SCode.Attributes attr;
    SCode.Variability vari;
    SCode.Element el;
    DAE.Mod m;
    list<SCode.Element> els,els1;
  	case	({}) then {};
  	  
 	  case	((el as SCode.COMPONENT(attributes=attr))::els) local String str;
 	    equation
				SCode.CONST() = SCode.attrVariability(attr);
 	      els1 = constantEls(els);
	  then (el::els1);
	    
	  case (_::els)
	    equation
	      els1 = constantEls(els);
	   then els1;
  end matchcontinue;
end constantEls;

protected function getModsForDep "
Author: BZ, 2009-08
Extract modifer for dependent variables(dep).
"
input Absyn.ComponentRef dep;
input list<tuple<SCode.Element, Mod>> elems;
output DAE.Mod omods;
algorithm omods := matchcontinue(dep,elems)
  local
    String name1,name2;
    DAE.Mod cmod;
    tuple<SCode.Element, Mod> tpl;
  case(_,{}) then DAE.NOMOD();
  case(dep,( tpl as (SCode.COMPONENT(component=name1),DAE.NOMOD()))::elems)
      then getModsForDep(dep,elems);
  case(dep,( tpl as (SCode.COMPONENT(component=name1),cmod))::elems)
    equation
      name2 = Absyn.printComponentRefStr(dep); 
      true = stringEqual(name2,name1);
      cmod = DAE.MOD(false,Absyn.NON_EACH(),{DAE.NAMEMOD(name2,cmod)},NONE);      
      then
        cmod;
  case(dep,tpl::elems)
    equation
      cmod = getModsForDep(dep,elems);
      then
        cmod;    
  end matchcontinue;
end getModsForDep;

protected function updateCompeltsMods 
"function: updateCompeltsMods
  author: PA
  This function updates component modifiers to typed modifiers.
  Typed modifiers are needed  to merge modifiers and to be able to 
  fully instantiate a component."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Prefix inPrefix;
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst;
  input ClassInf.State inState;
  input Connect.Sets inSets;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;    
  output list<tuple<SCode.Element, Mod>> outTplSCodeElementModLst;
  output Connect.Sets outSets;
  output DAE.DAElist outDae "contain functions";
algorithm 
  (outCache,outEnv,outIH,outTplSCodeElementModLst,outSets,outDae):=
  matchcontinue (inCache,inEnv,inIH,inPrefix,inTplSCodeElementModLst,inState,inSets,inBoolean)
    local
      list<Env.Frame> env,env2,env3;
      Prefix.Prefix pre;
      Connect.Sets csets;
      SCode.Mod umod;
      list<Absyn.ComponentRef> crefs,crefs_1,crefs2;      
      DAE.Mod cmod_1,cmod,localModifiers,cmod2,redMod;
      list<DAE.Mod> ltmod;
      list<tuple<SCode.Element, Mod>> res,xs,newXS,head;
      SCode.Element comp,redComp;
      ClassInf.State ci_state;
      Boolean impl;
      Env.Cache cache;
      SCode.OptBaseClass bc;
      output InstanceHierarchy ih;
      DAE.DAElist dae,dae1,dae2,fdae1,fdae2,dae3;
      
    case (cache,env,ih,pre,{},_,csets,_) then (cache,env,ih,{},csets,DAEUtil.emptyDae); 
      // Special case for components beeing redeclared, we might instantiate partial classes when instantiating var(-> instVar2->instClass) to update component in env.       
    case (cache,env,ih,pre,((comp,(cmod as DAE.REDECL(_,{(redComp,redMod)}))) :: xs),ci_state,csets,impl)
      equation 
        umod = Mod.unelabMod(cmod);
        crefs = getCrefFromMod(umod);
        crefs_1 = getCrefFromCompDim(comp) "get crefs from dimension arguments";
        crefs = Util.listUnionOnTrue(crefs,crefs_1,Absyn.crefEqual);
        crefs2 = getCrefFromComp(comp);
        ltmod = Util.listMap1(crefs,getModsForDep,xs);
        cmod2 = Util.listFold_3(cmod::ltmod,Mod.merge,DAE.NOMOD,env,pre);
        
        //print("("+&intString(listLength(ltmod))+&")UpdateCompeltsMods_(" +& Util.stringDelimitList(Util.listMap(crefs2,Absyn.printComponentRefStr),",") +& ") subs: " +& Util.stringDelimitList(Util.listMap(crefs,Absyn.printComponentRefStr),",")+& "\n");
        //print("REDECL     acquired mods: " +& Mod.printModStr(cmod2) +& "\n");
        
        (cache,env2,ih,csets,dae) = updateComponentsInEnv(cache, env, ih, pre, cmod2, crefs, ci_state, csets, impl);
        ErrorExt.setCheckpoint();
        (cache,env2,ih,csets,dae1) = updateComponentsInEnv(cache, env2, ih, pre, DAE.NOMOD(), crefs2, ci_state, csets, impl);
        ErrorExt.rollBack() "roll back any errors";
        (cache,cmod_1,dae2) = Mod.updateMod(cache,env2, pre, cmod, impl);
        (cache,env3,ih,res,csets,dae3) = updateCompeltsMods(cache, env2, ih, pre, xs, ci_state, csets, impl);
        dae = DAEUtil.joinDaeLst({dae,dae1,dae2,dae3});
      then
        (cache,env3,ih,((comp,cmod_1) :: res),csets,dae);
      
    case (cache,env,ih,pre,((comp,cmod) :: xs),ci_state,csets,impl)
      equation 
        umod = Mod.unelabMod(cmod);
        crefs = getCrefFromMod(umod);
        crefs_1 = getCrefFromCompDim(comp);
        crefs = Util.listUnionOnTrue(crefs,crefs_1,Absyn.crefEqual);
        crefs2 = getCrefFromComp(comp);
        
        ltmod = Util.listMap1(crefs,getModsForDep,xs);
        cmod2 = Util.listFold_3(cmod::ltmod,Mod.merge,DAE.NOMOD,env,pre);
        
        //print("("+&intString(listLength(ltmod))+&")UpdateCompeltsMods_(" +& Util.stringDelimitList(Util.listMap(crefs2,Absyn.printComponentRefStr),",") +& ") subs: " +& Util.stringDelimitList(Util.listMap(crefs,Absyn.printComponentRefStr),",")+& "\n");
        //print("     acquired mods: " +& Mod.printModStr(cmod2) +& "\n");
        
        bc=SCode.elementBaseClassPath(comp);
        (cache,env,ih)=getDerivedEnv(cache,env,ih,bc);
        (cache,env2,ih,csets,fdae1) = updateComponentsInEnv(cache, env, ih, pre, cmod2, crefs, ci_state, csets, impl);
        (cache,env2,ih,csets,fdae2) = updateComponentsInEnv(cache, env2, ih, pre, DAE.NOMOD(), crefs2, ci_state, csets, impl);
        (cache,cmod_1,dae1) = Mod.updateMod(cache,env2, pre, cmod, impl);
        (cache,env3,ih,res,csets,dae2) = updateCompeltsMods(cache, env2, ih, pre, xs, ci_state, csets, impl);
        dae = DAEUtil.joinDaeLst({dae1,dae2,fdae1,fdae2});
      then
        (cache,env3,ih,((comp,cmod_1) :: res),csets,dae);
  end matchcontinue;
end updateCompeltsMods;

protected function getOptionArraydim 
"function: getOptionArraydim 
  Return the Arraydim of an optional arradim. 
  Empty list returned if no arraydim present."
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

public function instExtendsAndClassExtendsList " 
  This function flattens out the inheritance structure of a class.
  It takes an SCode.Element list and flattens out the extends nodes and
  class extends nodes of that list. The result is a list of components and
  lists of equations and algorithms."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input list<SCode.Element> inExtendsElementLst;
  input list<SCode.Element> inClassExtendsElementLst;
  input ClassInf.State inState;
  input String inClassName; // the class name whose elements are getting instantiated.
  input Boolean inImpl;
	output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output Mod outMod;
  output list<tuple<SCode.Element, Mod>> outTplSCodeElementModLst;
  output list<SCode.Equation> outSCodeNormalEquationLst;
  output list<SCode.Equation> outSCodeInitialEquationLst;
  output list<SCode.Algorithm> outSCodeNormalAlgorithmLst;
  output list<SCode.Algorithm> outSCodeInitialAlgorithmLst;
  Env env;
  list<SCode.Element> lst;
  list<Mod> mods;
  list<String> modStrings,elStrs;
algorithm 
  (outCache,outEnv,outIH,outMod,outTplSCodeElementModLst,outSCodeNormalEquationLst,outSCodeInitialEquationLst,outSCodeNormalAlgorithmLst,outSCodeInitialAlgorithmLst):=
  instExtendsList(inCache,inEnv,inIH,inMod,inExtendsElementLst,inState,inClassName,inImpl);
  (outMod,outTplSCodeElementModLst):=instClassExtendsList(outMod,inClassExtendsElementLst,outTplSCodeElementModLst);  
end instExtendsAndClassExtendsList;

protected function instExtendsList " 
  author: PA
  This function flattens out the inheritance structure of a class.
  It takes an SCode.Element list and flattens out the extends nodes
  of that list. The result is a list of components and lists of equations
  and algorithms."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input list<SCode.Element> inSCodeElementLst;
  input ClassInf.State inState;
  input String inClassName; // the class name whose elements are getting instantiated.
  input Boolean inBoolean;
	output Env.Cache outCache;
  output Env outEnv1;
  output InstanceHierarchy outIH;
  output Mod outMod2;
  output list<tuple<SCode.Element, Mod>> outTplSCodeElementModLst3;
  output list<SCode.Equation> outSCodeEquationLst4;
  output list<SCode.Equation> outSCodeEquationLst5;
  output list<SCode.Algorithm> outSCodeAlgorithmLst6;
  output list<SCode.Algorithm> outSCodeAlgorithmLst7;
algorithm 
  (outCache,outEnv1,outIH,outMod2,outTplSCodeElementModLst3,outSCodeEquationLst4,outSCodeEquationLst5,outSCodeAlgorithmLst6,outSCodeAlgorithmLst7):=
  matchcontinue (inCache,inEnv,inIH,inMod,inSCodeElementLst,inState,inClassName,inBoolean)
    local
      SCode.Class c;
      String cn,s,scope_str,className;
      Boolean encf,impl;
      SCode.Restriction r;
      list<Env.Frame> cenv,cenv1,cenv3,env2,env,env_1;
      DAE.Mod outermod,mod_1,mod_2,mods,mods_1,emod_1,emod_2,mod;
      list<SCode.Element> els,els_1,rest,cdefelts,extendselts,classextendselts;
      list<SCode.Equation> eq1,ieq1,eq1_1,ieq1_1,eq2,ieq2,eq3,ieq3,eq,ieq,initeq2;
      list<SCode.Algorithm> alg1,ialg1,alg1_1,ialg1_1,alg2,ialg2,alg3,ialg3,alg,ialg;
      Absyn.Path tp_1,tp;
      ClassInf.State new_ci_state,ci_state;
      list<tuple<SCode.Element, Mod>> compelts1,compelts2,compelts,compelts3;
      SCode.Mod emod;
      SCode.Element elt;
      Env.Cache cache;
      ClassInf.State new_ci_state;
      InstanceHierarchy ih;
    /* instantiate a base class */
    case (cache,env,ih,mod,(SCode.EXTENDS(baseClassPath = tp,modifications = emod) :: rest),ci_state,className,impl)
      equation
        // adrpo - here we need to check if we don't have recursive extends of the form:
        // package Icons
        //   extends Icons.BaseLibrary;
        //        model BaseLibrary "Icon for base library"
        //        end BaseLibrary;
        // end Icons;
        // if we don't check that, then the compiler enters an infinite loop!
        // what we do is removing Icons from extends Icons.BaseLibrary;
        tp = removeSelfReference(className, tp);
        (cache,(c as SCode.CLASS(name=cn,encapsulatedPrefix=encf,restriction=r)),cenv) = Lookup.lookupClass(cache,env, tp, false);
              
        outermod = Mod.lookupModificationP(mod, Absyn.IDENT(cn));
        (cache,cenv1,ih,els,eq1,ieq1,alg1,ialg1) = instDerivedClasses(cache,cenv,ih, outermod, c, impl);
        (cache,tp_1) = makeFullyQualified(cache,/* adrpo: cenv1?? FIXME */env, tp);
        els_1 = addInheritScope(noImportElements(els), (tp_1,emod)) "Add the scope of the base class to elements" ;
        eq1_1 = addEqnInheritScope(eq1, (tp_1,emod));
        ieq1_1 = addEqnInheritScope(ieq1, (tp_1,emod));
        alg1_1 = addAlgInheritScope(alg1, (tp_1,emod));
        ialg1_1 = addAlgInheritScope(ialg1, (tp_1,emod));

        cenv3 = Env.openScope(cenv1, encf, SOME(cn));
        new_ci_state = ClassInf.start(r, Env.getEnvName(cenv3));
        /* Add classdefs and imports to env, so e.g. imports from baseclasses found, see Extends5.mo */
        (cdefelts,classextendselts,_,_) = splitElts(els);
        (cenv3,ih) = addClassdefsToEnv(cenv3,ih,cdefelts,impl,NONE);
        els_1 = Util.listSelect(els_1, SCode.isNotElementClassExtends); // Filtering is faster than listAppend. TODO: Create a new splitElts so this is even faster
        
        (cache,_,ih,mods,compelts1,eq2,ieq2,alg2,ialg2) = instExtendsAndClassExtendsList(cache,cenv3,ih,outermod,els_1,classextendselts,ci_state,className,impl) 
        "recurse to fully flatten extends elements env" ;
        (cache,env2,ih,mods_1,compelts2,eq3,ieq3,alg3,ialg3) = instExtendsList(cache,env,ih, mod, rest, ci_state, className, impl) 
        "continue with next element in list" ;
        /*
        corresponding elements. But emod is Absyn.Mod and can not Must merge(mod,emod) 
        here and then apply the bindings to the be elaborated, because for instance extends 
        A(x=y) can reference a variable y defined in A and will thus not be found. 
        On the other hand: A(n=4), n might be a structural parameter that must be set 
        to instantiate A. How could this be solved? Solution: made new function elab_untyped_mod 
        which transforms to a Mod, but set the type information to unknown. We can then perform the 
        merge, and update untyped modifications later (using update_mod), when we are instantiating 
        the components." 
        */
        emod_1 = Mod.elabUntypedMod(emod, env2, Prefix.NOPRE());
        mods_1 = Mod.merge(mod, mods_1, env2, Prefix.NOPRE());
        mods_1 = Mod.merge(mods_1, emod_1, env2, Prefix.NOPRE());
        
        compelts = listAppend(compelts1, compelts2);

        (compelts3,mods_1) = updateComponents(compelts, mods_1, env2) "update components with new merged modifiers" ;
        eq = Util.listlistFunc(eq1_1,{eq2,eq3},Util.listUnionOnTrue,Util.equal);
        ieq = Util.listlistFunc(ieq1_1,{ieq2,ieq3},Util.listUnionOnTrue,Util.equal);
        alg = Util.listlistFunc(alg1_1,{alg2,alg3},Util.listUnionOnTrue,Util.equal);
        ialg = Util.listlistFunc(ialg1_1,{ialg2,ialg3},Util.listUnionOnTrue,Util.equal);
      then
        (cache,env2,ih,mods_1,compelts3,eq,ieq,alg,ialg);
    
    /* base class was not found */
    case (cache,env,ih,mod,(SCode.EXTENDS(baseClassPath = tp,modifications = emod) :: rest),ci_state,className,impl)
      equation 
        failure((_,c,cenv) = Lookup.lookupClass(cache,env, tp, false));
        s = Absyn.pathString(tp);
        scope_str = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_BASECLASS_ERROR, {s,scope_str});
      then
        fail();
        
    /* instantiate elements that are not extends */
    case (cache,env,ih,mod,(elt :: rest),ci_state,className,impl) /* Components that are not EXTENDS */
      equation
         false = SCode.isElementExtends(elt) "verify that it is not an extends element";
        (cache,env_1,ih,mods,compelts2,eq2,initeq2,alg2,ialg2) = 
        instExtendsList(cache,env,ih, mod, rest, ci_state, className, impl);
      then
        (cache,env_1,ih,mods,((elt,DAE.NOMOD()) :: compelts2),eq2,initeq2,alg2,ialg2);

    /* no further elements to instantiate */
    case (cache,env,ih,mod,{},ci_state,className,impl) then (cache,env,ih,mod,{},{},{},{},{});

    /* instantiation failed */
    case (_,_,_,_,_,_,_,_)
      equation 
        Debug.fprint("failtrace", "- Inst.instExtendsList failed\n");
      then
        fail();
  end matchcontinue;
end instExtendsList;

protected function instClassExtendsList
"Instantiate element nodes of type SCode.CLASS_EXTENDS. This is done by walking
the extended classes and performing the modifications in-place. The old class
will no longer be accessible."
  input DAE.Mod inMod;
  input list<SCode.Element> inClassExtendsList;
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst;
  output DAE.Mod outMod;
  output list<tuple<SCode.Element, Mod>> outTplSCodeElementModLst;
algorithm
  (outMod,outTplSCodeElementModLst) := matchcontinue (inMod,inClassExtendsList,inTplSCodeElementModLst)
    local
      SCode.Element first;
      SCode.Class cl;
      list<SCode.Element> rest;
      SCode.ClassDef classDef;
      Boolean partialPrefix,encapsulatedPrefix;
      SCode.Restriction restriction;
      String name;
      Option<Absyn.ExternalDecl> externalDecl;
      list<SCode.Annotation> annotationLst;
      Option<SCode.Comment> comment;
      list<SCode.Element> els,els1,els2;
      list<SCode.Equation> nEqn,nEqn1,nEqn2,inEqn,inEqn1,inEqn2;
      list<SCode.Algorithm> nAlg,nAlg1,nAlg2,inAlg,inAlg1,inAlg2;
      list<tuple<SCode.Element, Mod>> compelts;
      SCode.Mod mods;
      DAE.Mod emod;
      list<String> names;
    case (emod,{},compelts) then (emod,compelts);
    case (emod,(first as SCode.CLASSDEF(name=name))::rest,compelts)
      equation
        (emod,compelts) = instClassExtendsList2(emod,name,first,compelts);
        (emod,compelts) = instClassExtendsList(emod,rest,compelts);
      then (emod,compelts);
    case (_,SCode.CLASSDEF(name=name)::rest,compelts)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- Inst.instClassExtendsList failed " +& name);
        Debug.traceln("  Candidate classes: ");
        els = Util.listMap(compelts, Util.tuple21);
        names = Util.listMap(els, SCode.elementName);
        Debug.traceln(Util.stringDelimitList(names, ","));
      then fail();
  end matchcontinue;
end instClassExtendsList;

protected function instClassExtendsList2
  input DAE.Mod inMod;
  input String inName;
  input SCode.Element inClassExtendsElt;
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst;
  output DAE.Mod outMod;
  output list<tuple<SCode.Element, Mod>> outTplSCodeElementModLst;
algorithm
  (outMod,outTplSCodeElementModLst) := matchcontinue (inMod,inName,inClassExtendsElt,inTplSCodeElementModLst)
    local
      SCode.Element elt,compelt,classExtendsElt,compelt;
      SCode.Class cl,classExtendsClass;
      SCode.ClassDef classDef,classExtendsCdef;
      Boolean partialPrefix2,encapsulatedPrefix2,finalPrefix2,replaceablePrefix2,partialPrefix1,encapsulatedPrefix1,finalPrefix1,replaceablePrefix1;
      SCode.Restriction restriction1,restriction2;
      String name1,name2;
      Option<Absyn.ExternalDecl> externalDecl;
      list<SCode.Annotation> annotationLst1,annotationLst2;
      Option<SCode.Comment> comment1,comment2;
      list<SCode.Element> els,els1,els2;
      list<SCode.Equation> nEqn,nEqn1,nEqn2,inEqn,inEqn1,inEqn2;
      list<SCode.Algorithm> nAlg,nAlg1,nAlg2,inAlg,inAlg1,inAlg2;
      list<tuple<SCode.Element, Mod>> rest,elsAndMods;
      SCode.Mod mods;
      Mod mod,mod1,mod2,emod;
      SCode.OptBaseClass baseClassPath1,baseClassPath2;
      Option<Absyn.ConstrainClass> cc1,cc2;
      Absyn.Info info1, info2;
      
    case (emod,name1,classExtendsElt,(SCode.CLASSDEF(name2,finalPrefix2,replaceablePrefix2,cl,baseClassPath2,cc2),mod1)::rest)
      equation
        true = name1 ==& name2; // Compare the name before pattern-matching to speed this up
        
        name2 = name2 +& "$parent";
        SCode.CLASS(_,partialPrefix2,encapsulatedPrefix2,restriction2,SCode.PARTS(els2,nEqn2,inEqn2,nAlg2,inAlg2,externalDecl,annotationLst2,comment2),info2) = cl;

        SCode.CLASSDEF(_, finalPrefix1, replaceablePrefix1, classExtendsClass, baseClassPath1, cc1) = classExtendsElt;
        SCode.CLASS(_, partialPrefix1, encapsulatedPrefix1, restriction1, classExtendsCdef, info1) = classExtendsClass;
        SCode.CLASS_EXTENDS(_,mods,els1,nEqn1,inEqn1,nAlg1,inAlg1,annotationLst1,comment1) = classExtendsCdef;

        classDef = SCode.PARTS(els2,nEqn2,inEqn2,nAlg2,inAlg2,externalDecl,annotationLst2,comment2);
        cl = SCode.CLASS(name2,partialPrefix2,encapsulatedPrefix2,restriction2,classDef,info2);
        compelt = SCode.CLASSDEF(name2, finalPrefix2, replaceablePrefix2, cl, baseClassPath2, cc2);
        
        elt = SCode.EXTENDS(Absyn.IDENT(name2), mods, NONE);
        classDef = SCode.PARTS(elt::els1,nEqn1,inEqn1,nAlg1,inAlg1,NONE,annotationLst1,comment1);
        cl = SCode.CLASS(name1,partialPrefix1,encapsulatedPrefix1,restriction1,classDef, info1);
        elt = SCode.CLASSDEF(name1, finalPrefix1, replaceablePrefix1, cl, baseClassPath1, cc1);
        emod = Mod.renameTopLevelNamedSubMod(emod,name1,name2);
      then (emod,(compelt,mod1)::(elt,DAE.NOMOD)::rest);
    case (emod,name1,classExtendsElt,(compelt,mod)::rest)
      equation
        (emod,rest) = instClassExtendsList2(emod,name1,classExtendsElt,rest);
      then (emod,(compelt,mod)::rest);
    case (_,_,_,{})
      equation
        Debug.traceln("TODO: Make a proper Error message here - Inst.instClassExtendsList2 couldn't find the class to extend");
      then fail();
  end matchcontinue;
end instClassExtendsList2;

protected function partialInstExtendsAndClassExtendsList " 
  This function flattens out the inheritance structure of a class.
  It takes an SCode.Element list and flattens out the extends nodes and
  class extends nodes of that list. The result is a list of components and
  lists of equations and algorithms."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input list<SCode.Element> inExtendsElementLst;
  input list<SCode.Element> inClassExtendsElementLst;
  input ClassInf.State inState;
  input String inClassName; // the class name whose elements are getting instantiated.
  input Boolean inImpl;
	output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output Mod outMod;
  output list<tuple<SCode.Element, Mod>> outTplSCodeElementModLst;
  Env env;
  list<SCode.Element> lst;
  list<Mod> mods;
  list<String> modStrings,elStrs;
algorithm 
  (outCache,outEnv,outIH,outMod,outTplSCodeElementModLst):=
  partialInstExtendsList(inCache,inEnv,inIH,inMod,inExtendsElementLst,inState,inClassName,inImpl);
  (outMod,outTplSCodeElementModLst):=instClassExtendsList(outMod,inClassExtendsElementLst,outTplSCodeElementModLst);
end partialInstExtendsAndClassExtendsList;

protected function partialInstExtendsList 
"function: partialInstExtendsList 
  author: PA
  This function is the same as instExtendsList, except that it does partial instantiation."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input list<SCode.Element> inSCodeElementLst;
  input ClassInf.State inState;
  input String inClassName; // the class name whose elements are getting instantiated.
  input Boolean inBoolean;
	output Env.Cache outCache;
  output Env outEnv1;
  output InstanceHierarchy outIH;
  output Mod outMod2;
  output list<tuple<SCode.Element, Mod>> outTplSCodeElementModLst3;
algorithm 
  (outCache,outEnv1,outIH,outMod2,outTplSCodeElementModLst3,outSCodeEquationLst4,outSCodeEquationLst5,outSCodeAlgorithmLst6,outSCodeAlgorithmLst7):=
  matchcontinue (inCache,inEnv,inIH,inMod,inSCodeElementLst,inState,inClassName,inBoolean)
    local
      SCode.Class c;
      String cn,s,scope_str,className;
      Boolean encf,impl;
      SCode.Restriction r;
      list<Env.Frame> cenv,cenv1,cenv3,env2,env,env_1;
      DAE.Mod outermod,mod_1,mod_2,mods,mods_1,emod_1,emod_2,mod;
      list<SCode.Element> els,els_1,rest,cdefelts,extendselts,classextendselts;
      Absyn.Path tp_1,tp;
      ClassInf.State new_ci_state,ci_state;
      list<tuple<SCode.Element, Mod>> compelts1,compelts2,compelts,compelts3;
      SCode.Mod emod;
      SCode.Element elt;
      Env.Cache cache;
      ClassInf.State new_ci_state;
      InstanceHierarchy ih;
    /* instantiate a base class */
    case (cache,env,ih,mod,(SCode.EXTENDS(baseClassPath = tp,modifications = emod) :: rest),ci_state,className,impl)
      equation
        // adrpo - here we need to check if we don't have recursive extends of the form:
        // package Icons
        //   extends Icons.BaseLibrary;
        //        model BaseLibrary "Icon for base library"
        //        end BaseLibrary;
        // end Icons;
        // if we don't check that, then the compiler enters an infinite loop!
        // what we do is removing Icons from extends Icons.BaseLibrary;
        tp = removeSelfReference(className, tp);
        (cache,(c as SCode.CLASS(name=cn,encapsulatedPrefix=encf,restriction=r)),cenv) = Lookup.lookupClass(cache,env, tp, false);
              
        outermod = Mod.lookupModificationP(mod, Absyn.IDENT(cn));
        (cache,cenv1,ih,els,_,_,_,_) = instDerivedClasses(cache,cenv,ih, outermod, c, impl);
        (cache,tp_1) = makeFullyQualified(cache,/* adrpo: cenv1?? FIXME */env, tp);
        els_1 = addInheritScope(noImportElements(els), (tp_1,emod)) "Add the scope of the base class to elements" ;

        cenv3 = Env.openScope(cenv1, encf, SOME(cn));
        new_ci_state = ClassInf.start(r, Env.getEnvName(cenv3));
        /* Add classdefs and imports to env, so e.g. imports from baseclasses found, see Extends5.mo */
        (cdefelts,classextendselts,_,_) = splitElts(els);
        (cenv3,ih) = addClassdefsToEnv(cenv3,ih,cdefelts,impl,NONE);
        els_1 = Util.listSelect(els_1, SCode.isNotElementClassExtends); // Filtering is faster than listAppend. TODO: Create a new splitElts so this is even faster
        
        (cache,_,ih,mods,compelts1) = partialInstExtendsAndClassExtendsList(cache,cenv3,ih,outermod,els_1,classextendselts,ci_state,className,impl) 
        "recurse to fully flatten extends elements env" ;
        (cache,env2,ih,mods_1,compelts2) = partialInstExtendsList(cache,env,ih, mod, rest, ci_state, className, impl) 
        "continue with next element in list" ;
        /*
        corresponding elements. But emod is Absyn.Mod and can not Must merge(mod,emod) 
        here and then apply the bindings to the be elaborated, because for instance extends 
        A(x=y) can reference a variable y defined in A and will thus not be found. 
        On the other hand: A(n=4), n might be a structural parameter that must be set 
        to instantiate A. How could this be solved? Solution: made new function elab_untyped_mod 
        which transforms to a Mod, but set the type information to unknown. We can then perform the 
        merge, and update untyped modifications later (using update_mod), when we are instantiating 
        the components." 
        */
        emod_1 = Mod.elabUntypedMod(emod, env2, Prefix.NOPRE());
        mods_1 = Mod.merge(mod, mods_1, env2, Prefix.NOPRE());
        mods_1 = Mod.merge(mods_1, emod_1, env2, Prefix.NOPRE());
        
        compelts = listAppend(compelts1, compelts2);

        (compelts3,mods_1) = updateComponents(compelts, mods_1, env2) "update components with new merged modifiers" ;
      then
        (cache,env2,ih,mods_1,compelts3);
    
    /* base class was not found */
    case (cache,env,ih,mod,(SCode.EXTENDS(baseClassPath = tp,modifications = emod) :: rest),ci_state,className,impl)
      equation 
        failure((_,c,cenv) = Lookup.lookupClass(cache,env, tp, false));
        s = Absyn.pathString(tp);
        scope_str = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_BASECLASS_ERROR, {s,scope_str});
      then
        fail();
        
    /* instantiate elements that are not extends */
    case (cache,env,ih,mod,(elt :: rest),ci_state,className,impl) /* Components that are not EXTENDS */
      equation
         false = SCode.isElementExtends(elt) "verify that it is not an extends element";
        (cache,env_1,ih,mods,compelts2) = 
        partialInstExtendsList(cache,env,ih, mod, rest, ci_state, className, impl);
      then
        (cache,env_1,ih,mods,((elt,DAE.NOMOD()) :: compelts2));

    /* no further elements to instantiate */
    case (cache,env,ih,mod,{},ci_state,className,impl) then (cache,env,ih,mod,{});

    /* instantiation failed */
    case (_,_,_,_,_,_,_,_)
      equation 
        Debug.fprint("failtrace", "- Inst.partialInstExtendsList failed\n");
      then
        fail();
  end matchcontinue;
end partialInstExtendsList;

protected function addInheritScope 
"function: addInheritScope
  author: PA 
  Adds the optional base class in a SCode.COMPONENTS to indicate which base 
  class the component originates from. This is needed in instantiation to 
  be able to look up classes, etc. from the scope where the component is 
  defined."
  input list<SCode.Element> inSCodeElementLst;
  input SCode.BaseClass inPathMod;
  output list<SCode.Element> outSCodeElementLst;
algorithm 
  outSCodeElementLst := matchcontinue (inSCodeElementLst,inPathMod)
    local
      list<SCode.Element> res,xs;
      String a,name;
      Boolean b,c,d,o2,i2,partialPrefix,encapsulatedPrefix;
      SCode.Attributes e;
      Absyn.TypeSpec f;
      SCode.BaseClass tp;
      SCode.Mod g;
      Option<SCode.Comment> comment;
      SCode.Element x;
      Absyn.InnerOuter io;
      Option<Absyn.Exp> cond;
      SCode.Class cd;
      Option<Absyn.Info> infoOpt;
      Option<Absyn.ConstrainClass> cc;
      SCode.Restriction r,restriction;
      SCode.ClassDef classDef;
      Absyn.Info info;
      
    case ({},_) then {}; 

    case ((SCode.COMPONENT(component = a,innerOuter=io,finalPrefix = b,replaceablePrefix = c,
                           protectedPrefix = d,attributes = e,typeSpec = f,modifications = g,
                           comment = comment,condition=cond,info=infoOpt,cc=cc) :: xs),tp)
      equation 
        res = addInheritScope(xs, tp);
      then
        (SCode.COMPONENT(a,io,b,c,d,e,f,g,SOME(tp),comment,cond,infoOpt,cc) :: res);

    case ((SCode.CLASSDEF(name = a,finalPrefix = b,replaceablePrefix = c,
                          classDef = cd as SCode.CLASS(name = name, partialPrefix = partialPrefix, encapsulatedPrefix = encapsulatedPrefix, restriction = restriction, classDef = classDef, info = info),
                          cc=cc) :: xs),tp)
      equation
        classDef = addInheritScopeToClassDef(classDef,tp);
        res = addInheritScope(xs, tp);
      then
        (SCode.CLASSDEF(a,b,c,SCode.CLASS(name,partialPrefix,encapsulatedPrefix,restriction,classDef,info),SOME(tp),cc) :: res);
        
    case ((x :: xs),tp)
      equation 
        res = addInheritScope(xs, tp);
      then
        (x :: res);
        
    case (_,_)
      equation 
        print("Inst.addInheritScope failed\n");
      then
        fail();
  end matchcontinue;
end addInheritScope;

protected function addInheritScopeToClassDef
  input SCode.ClassDef classDef;
  input SCode.BaseClass bc;
  output SCode.ClassDef outClassDef;
algorithm
  outClassDef := matchcontinue (classDef,bc)
    local
      list<SCode.Element> elementLst;
      list<SCode.Equation> normalEquationLst,initialEquationLst;
      list<SCode.Algorithm> normalAlgorithmLst,initialAlgorithmLst;
      Option<Absyn.ExternalDecl> externalDecl;
      list<SCode.Annotation> annotationLst;
      Option<SCode.Comment> comment;
    case (SCode.PARTS(elementLst,normalEquationLst,initialEquationLst,normalAlgorithmLst,initialAlgorithmLst,externalDecl,annotationLst,comment),bc)
      equation
        elementLst = addInheritScope(elementLst,bc);
      then SCode.PARTS(elementLst,normalEquationLst,initialEquationLst,normalAlgorithmLst,initialAlgorithmLst,externalDecl,annotationLst,comment);
    case (classDef,bc) then classDef;
  end matchcontinue;
end addInheritScopeToClassDef;

protected function addEqnInheritScope 
"function: addEqnInheritScope
  author: PA
  Adds the optional base class in a SCode.EQUATION to indicate which 
  base class the equation originates from. This is needed in instantiation
  to be able to look up e.g. constants, etc. from the scope where the 
  equation  is defined."
  input list<SCode.Equation> inSCodeEquationLst;
  input SCode.BaseClass inPathMod;
  output list<SCode.Equation> outSCodeEquationLst;
algorithm 
  outSCodeEquationLst := matchcontinue (inSCodeEquationLst,inPathMod)
    local
      list<SCode.Equation> res,xs;
      SCode.EEquation e;
      SCode.BaseClass tp;
    case ({},_) then {}; 
    case ((SCode.EQUATION(eEquation = e) :: xs),tp)
      equation 
        res = addEqnInheritScope(xs, tp);
      then
        (SCode.EQUATION(e,SOME(tp)) :: res);
  end matchcontinue;
end addEqnInheritScope;

protected function addAlgInheritScope 
"function: addAlgInheritScope
  author: PA
  Adds the optional base class in a SCode.Algorithm to indicate which 
  base class the algorithm originates from. This is needed in instantiation
  to be able to look up e.g. constants, etc. from the scope where the 
  algorithm is defined."
  input list<SCode.Algorithm> inSCodeAlgorithmLst;
  input SCode.BaseClass inPathMod;
  output list<SCode.Algorithm> outSCodeAlgorithmLst;
algorithm 
  outSCodeAlgorithmLst := matchcontinue (inSCodeAlgorithmLst,inPathMod)
    local
      list<SCode.Algorithm> res,xs;
      list<Absyn.Algorithm> a;
      SCode.BaseClass tp;
    case ({},_) then {}; 
    case ((SCode.ALGORITHM(statements = a) :: xs),tp)
      equation 
        res = addAlgInheritScope(xs, tp);
      then
        (SCode.ALGORITHM(a,SOME(tp)) :: res);
  end matchcontinue;
end addAlgInheritScope;

public function addNomod 
"function: addNomod  
  This function takes an SCode.Element list and tranforms it into a 
  (SCode.Element Mod) list by inserting DAE.NOMOD for each element.
  Used to transform elements into a uniform list combined from inherited 
  elements and ordinary elements."
  input list<SCode.Element> inSCodeElementLst;
  output list<tuple<SCode.Element, Mod>> outTplSCodeElementModLst;
algorithm 
  outTplSCodeElementModLst := matchcontinue (inSCodeElementLst)
    local
      list<tuple<SCode.Element, Mod>> res;
      SCode.Element x;
      list<SCode.Element> xs;
    case {} then {}; 
    case ((x :: xs))
      equation 
        res = addNomod(xs);
      then
        ((x,DAE.NOMOD()) :: res);
  end matchcontinue;
end addNomod;

protected function updateComponents 
"function: updateComponents
  author: PA
  This function takes a list of components and a Mod and returns a list of
  components  with the modifiers updated.  The function is used when 
  flattening the inheritance structure, resulting in a list of components 
  to insert into the class definition. For instance 
  model A 
    extends B(modifiers) 
  end A; 
  will result in a list of components 
  from B for which modifiers should be applied to."
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst;
  input Mod inMod;
  input Env inEnv;
  output list<tuple<SCode.Element, Mod>> outTplSCodeElementModLst;
  output Mod restMod;
algorithm (outTplSCodeElementModLst,restMod) := matchcontinue (inTplSCodeElementModLst,inMod,inEnv)
    local
      DAE.Mod cmod2,mod_1,cmod,mod,emod,mod_rest;
      list<tuple<SCode.Element, Mod>> res,xs;
      SCode.Element comp,c;
      String id;
      list<Env.Frame> env;
  case ({},mod,_) then ({},mod);
    case ((((comp as SCode.COMPONENT(component = id)),cmod) :: xs),mod,env)
      equation 
       // print(" comp: " +& id +& " " +& Mod.printModStr(mod) +& "\n"); 
        cmod2 = Mod.lookupCompModification(mod, id);
       // print("\tSpecific mods on comp: " +&  Mod.printModStr(cmod2) +& "\n");
        mod_1 = Mod.merge(cmod2, cmod, env, Prefix.NOPRE());
        mod_rest = Types.removeMod(mod,id);
        (res,mod_rest) = updateComponents(xs, mod_rest, env);
      then
        (((comp,mod_1) :: res),mod_rest);
    case ((((c as SCode.EXTENDS(baseClassPath = _)),emod) :: xs),mod,env)
      equation 
        (res,mod_rest) = updateComponents(xs, mod, env);
      then
        (((c,emod) :: res),mod_rest);
    case ((((c as SCode.CLASSDEF(name = _)),cmod) :: xs),mod,env)
      equation 
        (res,mod_rest) = updateComponents(xs, mod, env);
      then
        (((c,cmod) :: res),mod_rest);
    case ((((c as SCode.IMPORT(imp = _)),_) :: xs),mod,env)
      equation 
        (res,mod_rest) = updateComponents(xs, mod, env);
      then
        (((c,DAE.NOMOD()) :: res),mod_rest);
    case (_,_,_)
      equation 
        Debug.fprintln("failtrace", "-Inst.updateComponents failed");
      then
        fail();
  end matchcontinue;
end updateComponents;

protected function noImportElements 
"function: noImportElements 
  Returns all elements except imports, i.e. filter out import elements."
  input list<SCode.Element> inSCodeElementLst;
  output list<SCode.Element> outSCodeElementLst;
algorithm 
  outSCodeElementLst := matchcontinue (inSCodeElementLst)
    local
      list<SCode.Element> elt,rest;
      SCode.Element e;
    case {} then {}; 
    case (SCode.IMPORT(imp = _) :: rest)
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

protected function instDerivedClasses 
"function: instDerivedClasses
  author: PA
  This function takes a class definition and returns the
  elements and equations and algorithms of the class.
  If the class is derived, the class is looked up and the 
  derived class parts are fetched."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input SCode.Class inClass;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Env outEnv1;
  output InstanceHierarchy outIH;
  output list<SCode.Element> outSCodeElementLst2;
  output list<SCode.Equation> outSCodeEquationLst3;
  output list<SCode.Equation> outSCodeEquationLst4;
  output list<SCode.Algorithm> outSCodeAlgorithmLst5;
  output list<SCode.Algorithm> outSCodeAlgorithmLst6;
algorithm 
  (outCache,outEnv1,outIH,outSCodeElementLst2,outSCodeEquationLst3,outSCodeEquationLst4,outSCodeAlgorithmLst5,outSCodeAlgorithmLst6):=
  matchcontinue (inCache,inEnv,inIH,inMod,inClass,inBoolean)
    local
      list<SCode.Element> elt_1,elt;
      list<Env.Frame> env,cenv;
      DAE.Mod mod;
      list<SCode.Equation> eq,ieq;
      list<SCode.Algorithm> alg,ialg;
      SCode.Class c;
      Absyn.Path tp;
      SCode.Mod dmod;
      Boolean impl;
      Env.Cache cache;
      InstanceHierarchy ih;
      Option<SCode.Comment> cmt;
      list<SCode.Enum> enumLst;
      String n;
      Absyn.Info info;      
      
    case (cache,env,ih,mod,SCode.CLASS(classDef = 
          SCode.PARTS(elementLst = elt,
                      normalEquationLst = eq,initialEquationLst = ieq,
                      normalAlgorithmLst = alg,initialAlgorithmLst = ialg)),_)
      equation
        /* elt_1 = noImportElements(elt); */
      then
        (cache,env,ih,elt,eq,ieq,alg,ialg);
      
    case (cache,env,ih,mod,SCode.CLASS(classDef = SCode.DERIVED(typeSpec = Absyn.TPATH(tp, _),modifications = dmod)),impl)
      equation 
        (cache,c,cenv) = Lookup.lookupClass(cache,env, tp, true);
        (cache,env,ih,elt,eq,ieq,alg,ialg) = instDerivedClasses(cache,cenv,ih, mod, c, impl) 
        "Mod.lookup_modification_p(mod, c) => innermod & We have to merge and apply modifications as well!" ;
      then
        (cache,env,ih,elt,eq,ieq,alg,ialg);
        
    case (cache,env,ih,mod,SCode.CLASS(name=n, classDef = SCode.ENUMERATION(enumLst,cmt), info = info),impl)
      equation 
        c = instEnumeration(n, enumLst, cmt, info);
        (cache,env,ih,elt,eq,ieq,alg,ialg) = instDerivedClasses(cache,env,ih, mod, c, impl);
      then
        (cache,env,ih,elt,eq,ieq,alg,ialg);        
        
    case (_,_,_,_,_,_)
      equation 
        Debug.fprint("failtrace", "- Inst.instDerivedClasses failed\n");
      then
        fail();
  end matchcontinue;
end instDerivedClasses;

public function instElementList 
"function: instElementList
  Moved to instClassdef, FIXME: Move commments later
  Instantiate elements one at a time, and concatenate the resulting
  lists of equations.
  P.A, Modelica1.4: (allows declare before use)
  1. 'First names of declared local classes (and components) are found. 
      Redeclarations are performed.'
      This means that we first handle all CLASSDEF nodes and apply modifiers and 
      declarations to them and also COMPONENT nodes to add the variables to the
      environment.
  2.  Second, 'base-classes are looked up, flattened and inserted into the class.'
      This means that all EXTENDS nodes are handled.
  3.  Third, 'Flatten the class, apply modifiers and instantiate all local elements.'
      This handles COMPONENT nodes."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input UnitAbsyn.InstStore store;
  input Mod inMod2;
  input Prefix inPrefix3;
  input Connect.Sets inSets4;
  input ClassInf.State inState5;
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst6;
  input InstDims inInstDims7;
  input Boolean inBoolean8;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output list<DAE.Var> outTypesVarLst;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outStore,outDae,outSets,outState,outTypesVarLst,outGraph):=
  matchcontinue (inCache,inEnv,inIH,store,inMod2,inPrefix3,inSets4,inState5,inTplSCodeElementModLst6,inInstDims7,inBoolean8,inGraph)
    local
      list<Env.Frame> env,env_1,env_2;
      Connect.Sets csets,csets_1,csets_2;
      ClassInf.State ci_state,ci_state_1,ci_state_2;
      DAE.DAElist dae1,dae2,dae;
      list<DAE.Var> tys1,tys2,tys;
      DAE.Mod mod;
      Prefix.Prefix pre;
      tuple<SCode.Element, Mod> el;
      list<tuple<SCode.Element, Mod>> els;
      InstDims inst_dims;
      Boolean impl;
      Env.Cache cache;
      Absyn.Path path;
      Option<Absyn.Info> info;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      String str,prepath,s1; 
      SCode.Element ele; 
      Boolean nopre;
      
    case (cache,env,ih,store,_,_,csets,ci_state,{},_,_,graph) 
      then (cache,env,ih,store,DAEUtil.emptyDae,csets,ci_state,{},graph);
         
    /* most work done in inst_element. */ 
    case (cache,env,ih,store,mod,pre,csets,ci_state,el :: els,inst_dims,impl,graph)
      equation  
        /* make variable_string for error printing*/ 
        ele = Util.tuple21(el);
        (str, info) = extractCurrentName(ele);
        path = Absyn.IDENT(str);
        path = PrefixUtil.prefixPath(path,pre);        
        str = Absyn.pathString(path);         
        verifySingleMod(mod,pre,str);
        /*
        classmod = Mod.lookupModificationP(mods, t);
        mm = Mod.lookupCompModification(mods, n);
        */
        // A frequent used debugging line 
        //print("Instantiating element: " +& str +& " in scope " +& Env.getScopeName(env) +& ", elements to go: " +& intString(listLength(els)) +&
        //"\t mods: " +& Mod.printModStr(mod) +&  "\n");
        
        (cache,env_1,ih,store,dae1,csets_1,ci_state_1,tys1,graph) = instElement(cache,env,ih,store, mod, pre, csets, ci_state, el, inst_dims, impl,graph);
        /*s1 = Util.if_(stringEqual("n", str),DAE.dumpElementsStr(dae1),"");
        print(s1) "To print what happened to a specific var";*/
        Error.updateCurrentComponent("",NONE);
        (cache,env_2,ih,store,dae2,csets_2,ci_state_2,tys2,graph) = instElementList(cache,env_1,ih,store, mod, pre, csets_1, ci_state_1, els, inst_dims, impl,graph);
        tys = listAppend(tys1, tys2);
        dae = DAEUtil.joinDaes(dae1, dae2); 
      then
        (cache,env_2,ih,store,dae,csets_2,ci_state_2,tys,graph);
        
    case (_,_,_,_,_,_,_,_,els,_,_,_)
      equation 
        //print("instElementList failed\n ");
        // no need for this line as we already printed the crappy element that we couldn't instantiate
        // Debug.fprintln("failtrace", "- Inst.instElementList failed");
      then
        fail();
  end matchcontinue;
end instElementList;

protected function verifySingleMod "
Author BZ 
Checks so that we only have one modifier for each element. 
Fails on; a(x=3, redeclare Integer x)
"
  input Mod m;
  input Prefix.Prefix pre;
  input String str;
algorithm _ := matchcontinue(m,pre,str)
  local
    list<DAE.SubMod> subs;
  case(DAE.MOD(_,_,subs,_),pre,str)
    equation
      verifySingleMod2(subs,{},pre,str);
    then
      ();
  case(DAE.NOMOD,pre,str) then ();
  case(DAE.REDECL(finalPrefix=_),pre,str) then ();
end matchcontinue;
end verifySingleMod;

protected function verifySingleMod2 "
helper function for verifySingleMod
"
  input list<DAE.SubMod> subs;
  input list<String> prior;
  input Prefix.Prefix pre;
  input String str;
algorithm _ := matchcontinue(subs,prior,pre,str)
  local String n,s1;
  case({},_,pre,str) then ();
  case(DAE.NAMEMOD(ident = n)::subs,prior,pre,str)
    equation
      false = Util.listContainsWithCompareFunc(n,prior,stringEqual);
      verifySingleMod2(subs,n::prior,pre,str);
      then
        ();
  case(DAE.NAMEMOD(ident = n)::subs,prior,pre,str)
    equation
      true = Util.listContainsWithCompareFunc(n,prior,stringEqual);
      s1 = makePrefixString(pre);
      Error.addMessage(Error.MULTIPLE_MODIFIER, {n,s1});
      then
        fail();        
  end matchcontinue;
end verifySingleMod2;

protected function makePrefixString "
helper function for verifySingleMod, pretty output
"
input Prefix.Prefix pre;
output String str;
algorithm str := matchcontinue(pre)
  case(Prefix.NOPRE()) then "from top scope";
  case(pre) 
    equation 
      str = "from calling scope: " +& PrefixUtil.printPrefixStr(pre); 
    then str;
  end matchcontinue;
end makePrefixString;

protected function classdefElts2 
"function: classdeElts2
  author: PA
  This function filters out the class definitions (ElementMod) list."
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst;
  input Boolean partialPrefix;
  output list<SCode.Element> outSCodeElementLst;
  output list<tuple<SCode.Element, Mod>> outConstEls;
algorithm 
  (outSCodeElementLst,outConstEls) := matchcontinue (inTplSCodeElementModLst,partialPrefix)
    local
      list<SCode.Element> cdefs;
      SCode.Element cdef;
      tuple<SCode.Element, Mod> el;
      list<tuple<SCode.Element, Mod>> xs, els;
      SCode.Attributes attr;
    case ({},_) then ({},{}); 
    case ((cdef as SCode.CLASSDEF(classDef = SCode.CLASS(restriction = SCode.R_PACKAGE())),_) :: xs,true)
      equation
        (cdefs,els) = classdefElts2(xs,partialPrefix);
      then
        (cdef::cdefs,els);
    case (((cdef as SCode.CLASSDEF(name = _),_)) :: xs,false)
      equation 
        (cdefs,els) = classdefElts2(xs,partialPrefix);
      then
        (cdef::cdefs,els);
    case((el as (SCode.COMPONENT(attributes=attr),_))::xs,false)
 	    equation
				SCode.CONST() = SCode.attrVariability(attr);
 	      (cdefs,els) = classdefElts2(xs,partialPrefix);
 	    then (cdefs,el::els);
    case ((_ :: xs),_)
      equation 
        (cdefs,els) = classdefElts2(xs,partialPrefix);
      then
        (cdefs,els);
  end matchcontinue;
end classdefElts2;

public function classdefAndImpElts 
"function: classdefAndImpElts
  author: PA 
  This function filters out the class definitions 
  and import statements of an Element list."
  input list<SCode.Element> elts;
  output list<SCode.Element> cdefElts;
  output list<SCode.Element> restElts;
algorithm 
  (cdefElts,restElts) := matchcontinue (elts)
    local
      list<SCode.Element> res,xs;
      SCode.Element cdef,imp,e;
    case ({}) then ({},{}); 
    case (((cdef as SCode.CLASSDEF(name = _)) :: xs))
      equation 
        (cdefElts,restElts) = classdefAndImpElts(xs);
      then
        (cdef :: restElts,restElts);
    case (((imp as SCode.IMPORT(imp = _)) :: xs))
      equation 
        (cdefElts,restElts) = classdefAndImpElts(xs);
      then
        (imp :: cdefElts,restElts);
    case ((e :: xs))
      equation 
        (cdefElts,restElts) = classdefAndImpElts(xs);
      then
        (cdefElts,e::restElts); 
  end matchcontinue;
end classdefAndImpElts;

/*
protected function extendsElts 
"function: extendsElts
  author: PA
  This function filters out the extends Element in an Element list"
  input list<SCode.Element> inSCodeElementLst;
  output list<SCode.Element> outSCodeElementLst;
algorithm 
  outSCodeElementLst := matchcontinue (inSCodeElementLst)
    local
      list<SCode.Element> res,xs;
      SCode.Element cdef;
    case ({}) then {}; 
    case (((cdef as SCode.EXTENDS(baseClassPath = _)) :: xs))
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
*/

public function componentElts 
"function: componentElts
  author: PA
  This function filters out the component Element in an Element list"
  input list<SCode.Element> inSCodeElementLst;
  output list<SCode.Element> outSCodeElementLst;
algorithm 
  outSCodeElementLst := matchcontinue (inSCodeElementLst)
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

public function addClassdefsToEnv 
"function: addClassdefsToEnv
  author: PA

  This function adds classdefinitions and 
  import statements to the  environment."
  input Env inEnv;
  input InstanceHierarchy inIH;
  input list<SCode.Element> inSCodeElementLst;
  input Boolean inBoolean;
  input Option<Mod> redeclareMod; 
  output Env outEnv;
  output InstanceHierarchy outIH;
algorithm 
  (outEnv,outIH) := matchcontinue (inEnv,inIH,inSCodeElementLst,inBoolean,redeclareMod)
    local
      list<Env.Frame> env,env_1,env_2;
      SCode.Class cl;
      list<SCode.Element> els;
      Boolean impl;
      Absyn.Import imp;
      String s;
    case (env,inIH,els,impl,redeclareMod) 
      equation
        (env_1,inIH) = addClassdefsToEnv2(env,inIH,els,impl,redeclareMod);
        env_2 = Env.updateEnvClasses(env_1,env_1)
        "classes added with correct env.
        This is needed to store the correct env in Env.CLASS. 
        It is required to get external objects to work";
       then (env_2,inIH);
    case(_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "- Inst.addClassdefsToEnv failed\n");
        then
          fail();
  end matchcontinue;
end addClassdefsToEnv;

protected function addClassdefsToEnv2 
"function: addClassdefsToEnv2
  author: PA
  Helper relation to addClassdefsToEnv"
  input Env inEnv;
  input InstanceHierarchy inIH;
  input list<SCode.Element> inSCodeElementLst;
  input Boolean inBoolean;
  input Option<Mod> redeclareMod;  
  output Env outEnv;
  output InstanceHierarchy outIH;
algorithm 
  (outEnv,inIH) := matchcontinue (inEnv,inIH,inSCodeElementLst,inBoolean,redeclareMod)
    local
      list<Env.Frame> env,env_1,env_2,env_3,env1;
      SCode.Class cl,cl2;
      SCode.Element sel1;
      list<SCode.Element> xs;
      Boolean impl;
      Absyn.Import imp;
      InstanceHierarchy ih;
      Absyn.Info info;
      SCode.OptBaseClass optBaseClass;
      
    case (env,ih,{},_,_) then (env,ih); 
    // we do have a redeclaration of class. 
    case (env,ih,( (sel1 as SCode.CLASSDEF(name = s, classDef = cl, baseClassPath = optBaseClass)) :: xs),impl,redeclareMod)
      local String s;
      equation 
        (env1,ih,cl2) = addClassdefsToEnv3(env,ih,redeclareMod,sel1);
        env_1 = Env.extendFrameC(env1, cl2);
        (env_2,ih) = addClassdefsToEnv2(env_1, ih, xs, impl,redeclareMod);
      then
        (env_2,ih);
        
    // adrpo: see if is an enumeration! then extend frame with in class. 
    case (env,ih,( (sel1 as SCode.CLASSDEF(name = s, classDef = SCode.CLASS(classDef=SCode.ENUMERATION(enumLst,cmt),info=info))) :: xs),impl,redeclareMod)
      local 
        String s; 
        list<SCode.Enum> enumLst; 
        Option<SCode.Comment> cmt; 
        SCode.Class enumclass;
      equation 
        enumclass = instEnumeration(s, enumLst, cmt, info);        
        env_1 = Env.extendFrameC(env, enumclass);
        (env_2,ih) = addClassdefsToEnv2(env_1, ih, xs, impl,redeclareMod);
      then
        (env_2,ih);
        
    // otherwise, extend frame with in class. 
    case (env,ih,((sel1 as SCode.CLASSDEF(classDef = cl)) :: xs),impl,redeclareMod)
      equation 
        env_1 = Env.extendFrameC(env, cl);
        (env_2, ih) = addClassdefsToEnv2(env_1, ih, xs, impl,redeclareMod);
      then
        (env_2,ih);
        
    case (env,ih,(SCode.IMPORT(imp = imp) :: xs),impl,redeclareMod)
      equation 
        env_1 = Env.extendFrameI(env, imp);
        (env_2,ih) = addClassdefsToEnv2(env_1, ih, xs, impl,redeclareMod);
      then
        (env_2,ih);
    case(env,ih,((elt as SCode.DEFINEUNIT(name=_))::xs), impl,redeclareMod)
      local SCode.Element elt; 
      equation
        env_1 = Env.extendFrameDefunit(env,elt);
        (env_2,ih) = addClassdefsToEnv2(env_1,ih, xs, impl,redeclareMod);
      then (env_2,ih);
        
    case(env,ih,_,_,_)
      equation
        Debug.fprint("failtrace", "- Inst.addClassdefsToEnv2 failed\n");
      then
        fail();
  end matchcontinue;
end addClassdefsToEnv2;

protected function isStructuralParameter 
"function: isStructuralParameter
  author: PA 
  This function investigates a component to find out if it is a structural parameter.
  This is achieved by looking at the restriction to find if it is a parameter
  and by investigating all components to find it is used in array dimensions 
  of the component. A parameter can also be structural if is is used
  in an if equation with different number of equations in each branch."
  input SCode.Variability inVariability;
  input Absyn.ComponentRef inComponentRef;
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst;
  input list<SCode.Equation> inSCodeEquationLst;
  output Boolean outBoolean;
algorithm 
  outBoolean := matchcontinue (inVariability,inComponentRef,inTplSCodeElementModLst,inSCodeEquationLst)
    local
      list<Absyn.ComponentRef> crefs;
      Boolean b1,b2,res;
      SCode.Variability param;
      Absyn.ComponentRef compname;
      list<tuple<SCode.Element, Mod>> allcomps;
      list<SCode.Equation> eqns;
    /* constants does not need to be checked. 
	 * Must return false here to prevent constants from be outputed
	 * as structural parameters, i.e. \"parameter\" in DAE, which is 
	 * incorrect
	 */ 
    case (SCode.CONST(),_,_,_) then false;

    /* Check if structural:
	 * 1. By investigating array dimensions.
	 * 2. By investigating if-equations.
	 */ 
    case (param,compname,allcomps,eqns) 
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

protected function isStructuralIfEquationParameter 
"function isStructuralIfEquationParameter
  author: PA
  This function checks if a parameter is structural because 
  it is present in the condition expression of an if equation."
  input Absyn.ComponentRef inComponentRef;
  input list<SCode.Equation> inSCodeEquationLst;
  output Boolean outBoolean;
algorithm 
  outBoolean := matchcontinue (inComponentRef,inSCodeEquationLst)
    local
      list<Absyn.ComponentRef> crefs;
      Absyn.ComponentRef compname;
      list<Absyn.Exp> conds;
      Boolean res;
      list<SCode.Equation> eqns;
    case (_,{}) then false; 
    case (compname,(SCode.EQUATION(eEquation = SCode.EQ_IF(condition = conds)) :: _))
      equation 
        crefs = Util.listFlatten(Util.listMap1(conds,Absyn.getCrefFromExp,false));
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

public function addComponentsToEnv 
"function: addComponentsToEnv
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
  parameters."
  input Env.Cache inCache;
  input Env inEnv1;
  input InstanceHierarchy inIH;
  input Mod inMod2;
  input Prefix inPrefix3;
  input Connect.Sets inSets4;
  input ClassInf.State inState5;
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst6;
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst7;
  input list<SCode.Equation> inSCodeEquationLst8;
  input InstDims inInstDims9;
  input Boolean inBoolean10;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae "contain functions";
algorithm 
  (outCache,outEnv,outIH,outDae) := matchcontinue (inCache,inEnv1,inIH,inMod2,inPrefix3,inSets4,inState5,inTplSCodeElementModLst6,inTplSCodeElementModLst7,inSCodeEquationLst8,inInstDims9,inBoolean10)
    local
      list<Env.Frame> env,env_1,env_2;
      DAE.Mod mod,cmod;
      Prefix.Prefix pre;
      Connect.Sets csets;
      ClassInf.State cistate;
      SCode.Element comp;
      String n;
      Boolean finalPrefix,repl,prot,flowPrefix,streamPrefix,impl;
      Absyn.InnerOuter io;
      SCode.Attributes attr;
      list<Absyn.Subscript> ad;
      SCode.Accessibility acc;
      SCode.Variability param;
      Absyn.Direction dir;
      Absyn.TypeSpec t;
      SCode.Mod m;
      SCode.OptBaseClass bc;
      Option<SCode.Comment> comment;
      list<tuple<SCode.Element, Mod>> xs,allcomps,comps;
      list<SCode.Equation> eqns;
      InstDims instdims;
      Option<Absyn.Exp> aExp;
      Option<Absyn.Info> aInfo;
      Option<Absyn.ConstrainClass> cc;
      InstanceHierarchy ih;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2,dae3;
      
    /* no more components. */
    case (cache,env,ih,_,_,_,_,{},_,_,_,_) then (cache,env,ih,DAEUtil.emptyDae);
      
    /* A TPATH component */ 
    case (cache,env,ih,mod,pre,csets,cistate,
        (((comp as SCode.COMPONENT(component = n,
                                   innerOuter=io,
                                   finalPrefix = finalPrefix,
                                   replaceablePrefix = repl,
                                   protectedPrefix = prot,
                                   attributes = (attr as SCode.ATTR(arrayDims = ad,flowPrefix = flowPrefix,
                                                                    streamPrefix = streamPrefix,accesibility = acc,
                                                                    variability = param,direction = dir)),
                                   typeSpec = (tss as Absyn.TPATH(tpp, _)),
                                   modifications = m,
                                   baseClassPath = bc,
                                   comment = comment,
                                   condition = aExp, 
                                   info = aInfo,cc=cc)),cmod) :: xs),
        allcomps,eqns,instdims,impl) 
        local
          Absyn.TypeSpec tss;
          Absyn.Path tpp;
          SCode.Element selem;
          DAE.Mod smod,compModLocal; 
      equation 
        // print(" adding comp: " +& n +& " " +& Mod.printModStr(mod) +& " cmod: " +& Mod.printModStr(cmod) +& "\n");
        compModLocal = Mod.lookupModificationP(mod, tpp);
        m = traverseModAddFinal(m, finalPrefix);
        
        // compModLocal = Mod.lookupCompModification12(mod,n);
        // print(" \t comp: " +& n +& " " +& " compModLocal: " +& Mod.printModStr(compModLocal) +& "\n");        
        (cache,env,ih,selem,smod,csets,dae1) = redeclareType(cache,env,ih,compModLocal, 
        /*comp,*/ SCode.COMPONENT(n,io,finalPrefix,repl,prot,attr,tss,m,bc,comment, aExp, aInfo,cc),
        pre, cistate, csets, impl,cmod);
        // print(" \t comp: " +& n +& " " +& " smod: " +& Mod.printModStr(smod) +& "\n");
        (cache,env_1,ih,dae2) = addComponentsToEnv2(cache, env, ih, mod, pre, csets, cistate, {(selem,smod)}, instdims, impl);
        (cache,env_2,ih,dae3) = addComponentsToEnv(cache, env_1, ih, mod, pre, csets, cistate, xs, allcomps, eqns, instdims, impl);
        dae = DAEUtil.joinDaeLst({dae1,dae2,dae3});
      then
        (cache,env_2,ih,dae);
                
    /* A TCOMPLEX component */ 
    case (cache,env,ih,mod,pre,csets,cistate,
        (((comp as SCode.COMPONENT(component = n,
                                   innerOuter=io,
                                   finalPrefix = finalPrefix,
                                   replaceablePrefix = repl,
                                   protectedPrefix = prot,
                                   attributes = (attr as SCode.ATTR(arrayDims = ad,flowPrefix = flowPrefix,
                                                                    streamPrefix = streamPrefix,accesibility = acc,
                                                                    variability = param,direction = dir)),
                                   typeSpec = (t as Absyn.TCOMPLEX(_,_,_)),
                                   modifications = m,
                                   baseClassPath = bc,
                                   comment = comment,
                                   condition = aExp, 
                                   info = aInfo,cc=cc)),cmod as DAE.NOMOD()) :: xs),
        allcomps,eqns,instdims,impl) 
      equation
        m = traverseModAddFinal(m, finalPrefix);
        comp = SCode.COMPONENT(n,io,finalPrefix,repl,prot,attr,t,m,bc,comment, aExp, aInfo, cc);
        (cache,env_1,ih,dae1) = addComponentsToEnv2(cache, env, ih, mod, pre, csets, cistate, {(comp,cmod)}, instdims, impl);
        (cache,env_2,ih,dae2) = addComponentsToEnv(cache, env_1, ih, mod, pre, csets, cistate, xs, allcomps, eqns, instdims, impl);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,env_2,ih,dae);

    /* Import statement */
    case (cache,env,ih,mod,pre,csets,cistate,((SCode.IMPORT(_),_) :: xs),allcomps,eqns,instdims,impl)
      equation 
        (cache,env_2,ih,dae) = addComponentsToEnv(cache, env, ih, mod, pre, csets, cistate, xs, allcomps, eqns, instdims, impl);
      then
        (cache,env_2,ih,dae);
        
    /* Extends elements */ 
    case (cache,env,ih,mod,pre,csets,cistate,((SCode.EXTENDS(_,_,_),_) :: xs),allcomps,eqns,instdims,impl)
      equation 
        (cache,env_2,ih,dae) = addComponentsToEnv(cache,env, ih, mod, pre, csets, cistate, xs, allcomps, eqns, instdims, impl);
      then
        (cache,env_2,ih,dae);

    /* Class definitions */ 
    case (cache,env,ih,mod,pre,csets,cistate,((SCode.CLASSDEF(name = _),_) :: xs),allcomps,eqns,instdims,impl)
      equation 
        (cache,env_2,ih,dae) = addComponentsToEnv(cache, env, ih, mod, pre, csets, cistate, xs, allcomps, eqns, instdims, impl);
      then
        (cache,env_2,ih,dae);

    case (_,env,_,_,_,_,_,comps,_,_,_,_)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- Inst.addComponentsToEnv failed");
      then
        fail();
  end matchcontinue;
end addComponentsToEnv;

protected function addComponentsToEnv2 
"function addComponentsToEnv2
  Helper function to addComponentsToEnv. 
  Extends the environment with an untyped variable for the component."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst;
  input InstDims inInstDims;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae "contain functions";
algorithm 
  (outCache,outEnv,outIH,outDae) := matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inTplSCodeElementModLst,inInstDims,inBoolean)
    local
      DAE.Mod compmod,cmod_1,mods,cmod;
      list<Env.Frame> env_1,env_2,env;
      Prefix.Prefix pre;
      Connect.Sets csets;
      ClassInf.State ci_state;
      SCode.Element comp;
      String n;
      Boolean finalPrefix,repl,prot,flowPrefix,streamPrefix,impl;
      Absyn.InnerOuter io;
      SCode.Attributes attr;
      list<Absyn.Subscript> ad;
      SCode.Accessibility acc;
      SCode.Variability param;
      Absyn.Direction dir;
      Absyn.TypeSpec t;
      SCode.Mod m;
      SCode.OptBaseClass bc;
      Option<SCode.Comment> comment;
      list<tuple<SCode.Element, Mod>> xs,comps;
      InstDims inst_dims;
      Option<Absyn.Info> info;
      Option<Absyn.Exp> condition;
      Option<Absyn.ConstrainClass> cc;
      InstanceHierarchy ih;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;

    // a component 
    case (cache,env,ih,mods,pre,csets,ci_state,
          ((comp as SCode.COMPONENT(n,io,finalPrefix,repl,prot,
                                    attr as SCode.ATTR(ad,flowPrefix,streamPrefix,acc,param,dir),
                                    t,m,bc,comment,condition,info,cc),cmod) :: xs),
          inst_dims,impl)
      equation 
        compmod = Mod.lookupCompModification(mods, n) 
        "PA: PROBLEM, Modifiers should be merged in this phase, but
	       since undeclared components can not be found (is done in this phase)
	       the modifiers can not be elaborated to get a variable binding.
	       Thus, we need to store the merged modifier for elaboration in 
	       the next stage. 
	       	       
	       Solution: Save all modifiers in environment...
	       Use type T_NOTYPE instead of as earier trying to instantiate,
	       since instanitation might fail without having correct 
	       modifications, e.g. when instanitating a partial class that must
	       be redeclared through a modification" ;
        cmod_1 = Mod.merge(compmod, cmod, env, pre);

        /*
        print("Inst.addCompToEnv: " +& 
          n +& " in env " +& 
          Env.printEnvPathStr(env) +& " with mod: " +& Mod.printModStr(cmod_1) +& " in element: " +& 
          SCode.printElementStr(comp) +& "\n");
        */
        
        env_1 = Env.extendFrameV(env, 
          DAE.TYPES_VAR(n,DAE.ATTR(flowPrefix,streamPrefix,acc,param,dir,io),prot,
          (DAE.T_NOTYPE(),NONE),DAE.UNBOUND()), SOME((comp,cmod_1)), Env.VAR_UNTYPED(), {});
        (cache,env_2,ih,dae1) = addComponentsToEnv2(cache, env_1, ih, mods, pre, csets, ci_state, xs, inst_dims, impl);
        (cache,env_2,ih,dae2) = addComponentsToEnv2(cache, env_1, ih, mods, pre, csets, ci_state, xs, inst_dims, impl);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,env_2,ih,dae);
    // no components in list    
    case (cache,env,ih,_,_,_,_,{},_,_) then (cache,env,ih,DAEUtil.emptyDae);
    // failtrace
    case (cache,env,ih,_,_,_,_,comps,_,_)
      equation 
        Debug.fprint("failtrace", "- Inst.addComponentsToEnv2 failed\n");
        Debug.fprint("failtrace", "\n\n");
      then
        fail();
  end matchcontinue;
end addComponentsToEnv2;

protected function getCrefsFromCompdims 
"function: getCrefsFromCompdims
  author: PA
  This function collects all variables from the dimensionalities of 
  component elements. These variables are candidates for structural 
  parameters."
  input list<tuple<SCode.Element, Mod>> inTplSCodeElementModLst;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm 
  outAbsynComponentRefLst := matchcontinue (inTplSCodeElementModLst)
    local
      list<Absyn.ComponentRef> crefs1,crefs2,crefs;
      list<Absyn.Subscript> arraydim;
      list<tuple<SCode.Element, Mod>> xs;
    case ({}) then {}; 
    case (((SCode.COMPONENT(attributes = SCode.ATTR(arrayDims = arraydim)),_) :: xs))
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

protected function memberCrefs 
"function memberCrefs
  author: PA
  This function checks if a componentreferece is a member of 
  a list of component references, disregarding subscripts."
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.ComponentRef> inAbsynComponentRefLst;
  output Boolean outBoolean;
algorithm 
  outBoolean := matchcontinue (inComponentRef,inAbsynComponentRefLst)
    local
      Absyn.ComponentRef cr,cr1;
      list<Absyn.ComponentRef> xs;
      Boolean res;
    case (cr,(cr1 :: xs))
      equation 
        true = Absyn.crefEqualNoSubs(cr, cr1);
      then
        true;
    case (cr,(cr1 :: xs))
      equation 
        false = Absyn.crefEqualNoSubs(cr, cr1);
        res = memberCrefs(cr, xs);
      then
        res;
    case (_,_) then false; 
  end matchcontinue;
end memberCrefs;

public function instElement " 
  This monster function instantiates an element of a class
  definition.  An element is either a class definition, a variable,
  or an extends clause.
  Last two bools are implicit instanitation and implicit package instantiation"
  input Env.Cache inCache; 
  input Env inEnv;
  input InstanceHierarchy inIH;
  input UnitAbsyn.InstStore store;
  input Mod inMod2;
  input Prefix inPrefix3;
  input Connect.Sets inSets4;
  input ClassInf.State inState5;
  input tuple<SCode.Element, Mod> inTplSCodeElementMod6;
  input InstDims inInstDims7;
  input Boolean inBoolean8;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDAe;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output list<DAE.Var> outTypesVarLst;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outStore,outDae,outSets,outState,outTypesVarLst,outGraph):=
  matchcontinue (inCache,inEnv,inIH,store,inMod2,inPrefix3,inSets4,inState5,inTplSCodeElementMod6,inInstDims7,inBoolean8,inGraph)
    local
      list<Env.Frame> env,env_1,env2,env2_1,cenv,compenv;
      DAE.Mod mod,mods,classmod,mm,mods_1,classmod_1,mm_1,m_1,mod1,mod1_1,mod_1,cmod,omod,variableClassMod,redeclareComponentMod;
      Prefix.Prefix pre,pre_1;
      Connect.Sets csets,csets_1;
      ClassInf.State ci_state;
      Absyn.Import imp;
      InstDims instdims,inst_dims;
      String n,n2,s,scope_str,ns;
      Boolean finalPrefix,repl,prot,f2,repl2,impl,flowPrefix,streamPrefix;
      SCode.Class cls2,c,cl;
      DAE.DAElist dae,dae2,fdae,fdae1,fdae2,fdae3,fdae4,fdae5,fdae6;
      DAE.ComponentRef vn;
      Absyn.ComponentRef owncref;
      list<Absyn.ComponentRef> crefs,crefs2,crefs3,crefs_1,crefs_2;
      SCode.Element comp,el;
      SCode.Attributes attr;
      list<Absyn.Subscript> ad;
      SCode.Accessibility acc;
      SCode.Variability param;
      Absyn.Direction dir;
      Absyn.Path t;
      SCode.Mod m;
      SCode.OptBaseClass bc;
      Option<SCode.Comment> comment;
      Option<DAE.EqMod> eq;
      list<DimExp> dims;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Binding binding;
      DAE.Var new_var;
      Env.Cache cache;
      Absyn.InnerOuter io;
      Option<Absyn.Exp> cond;
      String s;
      Boolean alreadyDeclared; Absyn.ComponentRef tref;
      list<DAE.Var> vars; 
      Option<Absyn.Info> aInfo;
      Absyn.TypeSpec ts,tSpec;
      Absyn.Ident id;
      ConnectionGraph.ConnectionGraph graph,graphNew;
      Option<Absyn.ConstrainClass> cc,cc2;
      InstanceHierarchy ih;
      
    // Imports are simply added to the current frame, so that the lookup rule can find them.
	 	// Import have allready been added to the environment so there is nothing more to do here.
    case (cache,env,ih,store,mod,pre,csets,ci_state,(SCode.IMPORT(imp = imp),_),instdims,_,graph)
      then (cache,env,ih,store,DAEUtil.emptyDae,csets,ci_state,{},graph);  

    // Illegal redeclarations 
    case (cache,env,ih,store,mods,pre,csets,ci_state,(SCode.CLASSDEF(name = n),_),_,_,_) 
      equation 
        (_,_,_,_,_) = Lookup.lookupIdentLocal(cache,env, n);
        Error.addMessage(Error.REDECLARE_CLASS_AS_VAR, {n});
      then
        fail();
        
    // A new class definition. Put it in the current frame in the environment
    case (cache,env,ih,store,mods,pre,csets,ci_state,(SCode.CLASSDEF(name = n,replaceablePrefix = true,classDef = c, cc=cc2),_),inst_dims,impl,graph)
      local
        Option<Absyn.ConstrainClass> cc;
      equation 
        
        //Redeclare of class definition, replaceable is true
        ((classmod as DAE.REDECL(finalPrefix,{(SCode.CLASSDEF(n2,f2,repl2,cls2,_,cc),_)}))) = Mod.lookupModificationP(mods, Absyn.IDENT(n))  ;
        //print(" to strp redecl?\n");
        classmod = Types.removeMod(classmod,n);
        (cache,env_1,ih,dae) = instClassDecl(cache,env,ih, classmod, pre, csets, cls2, inst_dims);
        
        //print(" instClassDecl Call finished \n");
        // Debug.fprintln("insttr", "--Classdef mods");
        // Debug.fcall ("insttr", Mod.printMod, classmod);
        // Debug.fprintln ("insttr", "--All mods");
        // Debug.fcall ("insttr", Mod.printMod, mods);
      then
        (cache,env_1,ih,store,dae,csets,ci_state,{},graph);
        
    /* non replaceable class definition */
    case (cache,env,ih,store,mods,pre,csets,ci_state,(SCode.CLASSDEF(name = n,replaceablePrefix = false,classDef = c),_),inst_dims,impl,_)
      equation 
        ((classmod as DAE.REDECL(finalPrefix,{(SCode.CLASSDEF(n2,f2,repl2,cls2,_,_),_)}))) = Mod.lookupModificationP(mods, Absyn.IDENT(n)) 
        "Redeclare of class definition, replaceable is false" ;
        Error.addMessage(Error.REDECLARE_NON_REPLACEABLE, {n});
      then
        fail();

    // Classdefinition without redeclaration 
    case (cache,env,ih,store,mods,pre,csets,ci_state,(SCode.CLASSDEF(name = n,classDef = c),_),inst_dims,impl,graph)
      equation 
        classmod = Mod.lookupModificationP(mods, Absyn.IDENT(n));
        (cache,env_1,ih,dae) = 
        instClassDecl(cache,env,ih, classmod, pre, csets, c, inst_dims);
      then
        (cache,env_1,ih,store,dae,csets,ci_state,{},graph);
        
    // A component
	  // This is the rule for instantiating a model component.  A component can be 
	  // a structured subcomponent or a variable, parameter or constant.  All of these 
	  // are treated in a similar way. Lookup the class name, apply modifications and add the
	  // variable to the current frame in the environment. Then instantiate the class with 
	  // an extended prefix.
    case (cache,env,ih,store,mods,pre,csets,ci_state,
          ((comp as SCode.COMPONENT(component = n,innerOuter=io,
                                    finalPrefix = finalPrefix,replaceablePrefix = repl,protectedPrefix = prot,
      		                          attributes = (attr as SCode.ATTR(arrayDims = ad,flowPrefix = flowPrefix,
      		                                                           streamPrefix = streamPrefix, accesibility = acc,
      		                                                           variability = param,direction = dir)),
      		                          typeSpec = ( ts as Absyn.TPATH(t, _)), 
      		                          modifications = m,
      		                          baseClassPath = bc,
      		                          comment = comment,
      		                          condition=cond,
      		                          info = aInfo,cc=cc)),cmod),
          inst_dims,impl,graph)  
      equation
        //print("  instElement: A component: " +& n +& "\n");
        m = traverseModAddFinal(m, finalPrefix); 
        comp = SCode.COMPONENT(n,io,finalPrefix,repl,prot,attr,ts,m,bc,comment, cond, aInfo,cc);
        // Fails if multiple decls not identical
        alreadyDeclared = checkMultiplyDeclared(cache,env,mods,pre,csets,ci_state,(comp,cmod),inst_dims,impl);
        ci_state = ClassInf.trans(ci_state, ClassInf.FOUND_COMPONENT());
        vn = PrefixUtil.prefixCref(pre, DAE.CREF_IDENT(n,DAE.ET_OTHER(),{})); 
        // Debug.fprintln("insttr", "ICOMP " +& Env.printEnvPathStr(env) +& "/" +& PrefixUtil.printPrefixStr(pre) +& "." +& n);
				//The class definition is fetched from the environment. Then the set of modifications 
				//is calculated. The modificions is the result of merging the modifications from 
				//several sources. The modification stored with the class definition is put in the 
				//variable `classmod\', the modification passed to the function_ is extracted and put 
				//in the variable `mm\', and the modification that is included in the variable declaration 
				//is in the variable `m\'.  All of these are merged so that the correct precedence 
				//rules are followed." 
        classmod = Mod.lookupModificationP(mods, t);
        mm = Mod.lookupCompModification(mods, n);
        //The types in the environment does not have correct Binding.
	   		//We must update those variables that is found in m into a new environment.
        owncref = Absyn.CREF_IDENT(n,{})  ;
        /* INACTIVE FOR NOW, check for variable with class names. 
           tref = Absyn.pathToCref(t);
           failure(equality(tref = owncref));
        */
        crefs = getCrefFromMod(m);
        crefs2 = getCrefFromDim(ad);
        crefs3 = getCrefFromCond(cond);
        crefs_1 = Util.listFlatten({crefs,crefs2,crefs3});
        (cache,env,ih,store,crefs_2) = removeSelfReferenceAndUpdate(cache,env,ih,store,crefs_1,owncref,t,ci_state,csets,prot,attr,impl,io,inst_dims,pre,mods,finalPrefix,aInfo);
        (cache,env,ih) = getDerivedEnv(cache, env, ih, bc);
        (cache,env2,ih,csets,fdae3) = updateComponentsInEnv(cache, env, ih, pre, mods, crefs_2, ci_state, csets, impl);
				//Update the untyped modifiers to typed ones, and extract class and 
				//component modifiers again. 
        (cache,mods_1,fdae1) = Mod.updateMod(cache, env2, pre, mods, impl) ;
        //Refetch the component from environment, since attributes, etc.
		  	//might have changed.. comp used in redeclare_type below...	  
		  	
		  	// ***** NOTE *****
		  	// BZ 2008-06-04 
		  	// TODO: Verfiy
		  	// The line below is commented out due to that it does not seem to have any effect on the system.
		  	// It will stay here until this can be confirmed.
        //(cache,_,SOME((comp,_)),_,_) = Lookup.lookupIdentLocal(cache,env2, n);
        classmod_1 = Mod.lookupModificationP(mods_1, t);
        
        /* (BZ part:1/2) 
         * If we have a redeclaration of a inner model, we have lowest priority on it. 
         * This is while if we instantiate an instance of this redeclared class with a 
         * modifier, the modifier should be the value to use.
         */
        (variableClassMod,classmod_1) = modifyInstantiateClass(classmod_1,t);
        
        mm_1 = Mod.lookupCompModification(mods_1, n);
        //(cache,m) = removeSelfModReference(cache,n,m); // Remove self-reference i.e. A a(x=a.y);
        //print("Inst.instElement: before elabMod " +& PrefixUtil.printPrefixStr(pre) +& "." +& n +& " component mod: " +& SCode.printModStr(m) +& " in env: " +& Env.printEnvPathStr(env2) +& "\n");        
        (cache,m_1,fdae6) = Mod.elabMod(cache,env2, pre, m, impl);
        //print("Inst.instElement: after elabMod " +& PrefixUtil.printPrefixStr(pre) +& "." +& n +& " component mod: " +& Mod.printModStr(m_1) +& " in env: " +& Env.printEnvPathStr(env2) +& "\n");
        mod = Mod.merge(mm_1,classmod_1,  env2, pre);

        mod1 = Mod.merge(mod, m_1, env2, pre);
        mod1_1 = Mod.merge(cmod, mod1, env2, pre);
        
        /* (BZ part:2/2) here we merge the redeclared class modifier. Redeclaration has lowest priority and if we have any local 
         * modifiers, they will be used before "global" modifers. 
         */
        mod1_1 = Mod.merge(mod1_1, variableClassMod, env2, pre);
        
        /* Apply redeclaration modifier to component */
        (cache,env2_1,ih,
         SCode.COMPONENT(n,io,finalPrefix,repl,prot,
          (attr as SCode.ATTR(ad,flowPrefix,streamPrefix,acc,param,dir)),
          Absyn.TPATH(t, _),m,bc,comment,cond,_,_),
          mod_1,csets,fdae5) = redeclareType(cache, env2, ih, mod1_1, comp, pre, ci_state, csets, impl, DAE.NOMOD());
        (cache,env_1,ih) = getDerivedEnv(cache, env, ih, bc);
        (cache,cl,cenv) = Lookup.lookupClass(cache, env_1, t, true);
        
        checkRecursiveDefinition(env,t,ci_state,cl);
         
				//If the element is `protected\', and an external modification 
				//is applied, it is an error. 
        checkProt(prot, mm_1, vn) ;
        eq = Mod.modEquation(mod_1);
        
				// The variable declaration and the (optional) equation modification are inspected for array dimensions.				
        
        (cache,dims,fdae4) = elabArraydim(cache,env2_1, owncref, t,ad, eq, impl, NONE,true)  ;
        //Instantiate the component
        inst_dims = listAppend(inst_dims,{{}}); // Start a new "set" of inst_dims for this component (in instance hierarchy), see InstDims
        (cache,mod_1,fdae2) = Mod.updateMod(cache,cenv, pre, mod_1, impl);
        (cache,compenv,ih,store,dae,csets_1,ty,graphNew) = instVar(cache,cenv,ih,store, ci_state, mod_1, pre, csets, n, cl, attr, prot, dims, {}, inst_dims, impl, comment,io,finalPrefix,aInfo,graph);
				//The environment is extended (updated) with the new variable binding. 
        (cache,binding) = makeBinding(cache, env2_1, attr, mod_1, ty);
        //true in update_frame means the variable is now instantiated. 
        new_var = DAE.TYPES_VAR(n,DAE.ATTR(flowPrefix,streamPrefix,acc,param,dir,io),prot,ty,binding);

        //type info present Now we can also put the binding into the dae.
        //If the type is one of the simple, predifined types a simple variable 
        //declaration is added to the DAE. 
        env_1 = Env.updateFrameV(env2_1, new_var, Env.VAR_DAE(), compenv);
        vars = Util.if_(alreadyDeclared,{},{DAE.TYPES_VAR(n,DAE.ATTR(flowPrefix,streamPrefix,acc,param,dir,io),prot,ty,binding)});
        dae = Util.if_(alreadyDeclared,DAEUtil.emptyDae,dae);
        (dae,ih,graph) = InnerOuter.handleInnerOuterEquations(io,dae,ih,graphNew,graph);
        
        /* if declaration condition is true, remove dae elements and connections */
        (cache,dae,csets_1,graph,fdae) = instConditionalDeclaration(cache,env2,cond,n,dae,csets_1,pre,graph);
        dae = DAEUtil.joinDaeLst({dae,fdae,fdae1,fdae2,fdae3,fdae4,fdae5,fdae6});
      then
        (cache,env_1,ih,store,dae,csets_1,ci_state,vars,graph);
        
/* INACTIVE FOR NOW, check for variable with class names.        
    case (_,_,_,_,_,_,((comp as SCode.COMPONENT(component = n, typeSpec = Absyn.TPATH(t, _))),_),_,_)
      local Absyn.ComponentRef tref;   String s;   
      equation 
        owncref = Absyn.CREF_IDENT(n,{})  ;
        tref = Absyn.pathToCref(t);
        equality(tref = owncref);
        s = Absyn.pathString(t);
        Error.addMessage(Error.CLASS_NAME_VARIABLE,{n,s});
      then 
        fail();
*/

    //------------------------------------------------------------------------
    // MetaModelica Complex Types. Part of MetaModelica extension.
    //------------------------------------------------------------------------
    case (cache,env,ih,store,mods,pre,csets,ci_state,
          ((comp as SCode.COMPONENT(n,io,finalPrefix,repl,prot,attr as SCode.ATTR(ad,flowPrefix,streamPrefix,acc,param,dir),
                                    tSpec as Absyn.TCOMPLEX(typeName,_,_), m, bc,comment,cond,aInfo,cc),cmod)),
          inst_dims,impl,graph)
      local Absyn.Path typeName;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        // see if we have a modification on the inner component
        m = traverseModAddFinal(m, finalPrefix); 
        comp = SCode.COMPONENT(n,io,finalPrefix,repl,prot,attr,tSpec,m,bc,comment, cond, aInfo,cc);
        
        // Fails if multiple decls not identical
        alreadyDeclared = checkMultiplyDeclared(cache,env,mods,pre,csets,ci_state,(comp,cmod),inst_dims,impl);
        //checkRecursiveDefinition(env,t);
        vn = PrefixUtil.prefixCref(pre, DAE.CREF_IDENT(n,DAE.ET_OTHER(),{}));
        // Debug.fprintln("insttr", "ICOMP " +& Env.printEnvPathStr(env) +& "/" +& PrefixUtil.printPrefixStr(pre) +& "." +& n);
        
        // The class definition is fetched from the environment. Then the set of modifications
        // is calculated. The modificions is the result of merging the modifications from
        // several sources. The modification stored with the class definition is put in the
        // variable `classmod\', the modification passed to the function_ is extracted and put
        // in the variable `mm\', and the modification that is included in the variable declaration
        // is in the variable `m\'.  All of these are merged so that the correct precedence
        // rules are followed."
        // classmod = Mod.lookupModificationP(mods, t) ;
        // mm = Mod.lookupCompModification(mods, n);

        // The types in the environment does not have correct Binding.
        // We must update those variables that is found in m into a new environment.
        owncref = Absyn.CREF_IDENT(n,{})  ;
        // crefs = getCrefFromMod(m);
        // crefs2 = getCrefFromDim(ad);
        // crefs_1 = Util.listFlatten({crefs,crefs2});
        // crefs_2 = removeCrefFromCrefs(crefs_1, owncref);
        // (cache,env) = getDerivedEnv(cache,env, bc);
        //(cache,env2,csets) = updateComponentsInEnv(cache,mods, crefs_2, env, ci_state, csets, impl);
        // Update the untyped modifiers to typed ones, and extract class and
        // component modifiers again.
        // (cache,mods_1) = Mod.updateMod(cache,env2, pre, mods, impl) ;

        // Refetch the component from environment, since attributes, etc.
        // might have changed.. comp used in redeclare_type below...
        // (cache,_,SOME((comp,_)),_,_) = Lookup.lookupIdentLocal(cache,env2, n);
        // classmod_1 = Mod.lookupModificationP(mods_1, t);
        // mm_1 = Mod.lookupCompModification(mods_1, n);
        // (cache,m) = removeSelfModReference(cache,n,m); // Remove self-reference i.e. A a(x=a.y);
        (cache,m_1,fdae) = Mod.elabMod(cache, env, pre, m, impl); // In case we want to EQBOUND a complex type, e.g. when declaring constants. /sjoelund 2009-10-30
        // mod = Mod.merge(classmod_1, mm_1, env2, pre);
        // mod1 = Mod.merge(mod, m_1, env2, pre);
        // mod1_1 = Mod.merge(cmod, mod1, env2, pre);

        /* Apply redeclaration modifier to component */
        // (cache,env2,ih,SCode.COMPONENT(n,io,finalPrefix,repl,prot,(attr as SCode.ATTR(ad,flowPrefix,streamPrefix,acc,param,dir)),_,m,bc,comment),mod_1,env2_1,csets)
        // = redeclareType(cache,env,ih,mod1_1, comp, env2, pre, ci_state, csets, impl);
        (cache,env_1,ih) = getDerivedEnv(cache,env,ih, bc);
        //---------
        // We build up a class structure for the complex type
        id=Absyn.pathString(typeName);
        cl = SCode.CLASS(id,false,false,SCode.R_TYPE(),
                         SCode.DERIVED(tSpec,SCode.NOMOD(),
                            Absyn.ATTR(flowPrefix, streamPrefix,Absyn.VAR(),Absyn.BIDIR(),ad),
                            NONE()),Absyn.dummyInfo);
        // (cache,cl,cenv) = Lookup.lookupClass(cache,env_1, Absyn.IDENT("Integer"), true);

        // If the element is protected, and an external modification
        // is applied, it is an error.
        // checkProt(prot, mm_1, vn) ;
        // eq = Mod.modEquation(mod);

        // The variable declaration and the (optional) equation modification are inspected for array dimensions.
        // Gather all the dimensions
        // (Absyn.IDENT("Integer") is used as a dummie)
        (cache,dims,fdae1) = elabArraydim(cache,env, owncref, Absyn.IDENT("Integer"),ad, NONE, impl, NONE,true)  ;

        // Instantiate the component
        (cache,compenv,ih,store,dae,csets_1,ty,graphNew) = instVar(cache, env, ih, store, ci_state, m_1, pre, csets, n, cl, attr, prot, dims, {}, inst_dims, impl, comment, io, finalPrefix, aInfo, graph);

        // The environment is extended (updated) with the new variable binding.
        (cache,binding) = makeBinding(cache,env, attr, m_1, ty) ;

        // true in update_frame means the variable is now instantiated.
        new_var = DAE.TYPES_VAR(n,DAE.ATTR(flowPrefix,streamPrefix,acc,param,dir,io),prot,ty,binding) ;

        // type info present Now we can also put the binding into the dae.
        // If the type is one of the simple, predifined types a simple variable
        // declaration is added to the DAE.
        env_1 = Env.updateFrameV(env, new_var, Env.VAR_DAE(), compenv)  ;
        vars = Util.if_(alreadyDeclared,{},{DAE.TYPES_VAR(n,DAE.ATTR(flowPrefix,streamPrefix,acc,param,dir,io),prot,ty,binding)});
        dae = Util.if_(alreadyDeclared,DAEUtil.emptyDae,dae);
        (dae,ih,graph) = InnerOuter.handleInnerOuterEquations(io,dae,ih,graphNew,graph);
        // If an outer element, remove this variable from the DAE. Variable references will be bound to
        // corresponding inner element instead.
        // dae2 = Util.if_(ModUtil.isOuter(io),{},dae);
        
        dae = DAEUtil.joinDaeLst({dae,fdae,fdae1});
      then
        (cache,env_1,ih,store,dae,csets_1,ci_state,vars,graph);

    //------------------------------
    // If the class lookup in the previous rule fails, this rule catches the error 
    // and prints an error message about the unknown class. 
    // Failure => ({},env,csets,ci_state,{}) 
    case (cache,env,ih,store,_,pre,csets,ci_state,
          (SCode.COMPONENT(component = n, innerOuter=io,finalPrefix = finalPrefix,replaceablePrefix = repl,
                           protectedPrefix = prot,
                           attributes=SCode.ATTR(variability=vt),typeSpec = Absyn.TPATH(t,_),cc=cc),_),_,_,_) 
      local Absyn.ComponentRef tref; SCode.Variability vt;
      equation 
        failure((_,cl,cenv) = Lookup.lookupClass(cache,env, t, false));
        s = Absyn.pathString(t);
        scope_str = Env.printEnvPathStr(env);
        pre_1 = PrefixUtil.prefixAdd(n, {}, pre,vt);
        ns = PrefixUtil.printPrefixStr(pre_1);
        // Debug.fcall (\"instdb\", Env.print_env, env)
        Error.addMessage(Error.LOOKUP_ERROR_COMPNAME, {s,scope_str,ns});
        Debug.fprint("failtrace", "Lookup class failed\n");
      then
        fail();
        
    case (cache,env,ih,store,omod,_,_,_,(el,mod),_,_,_) 
      equation         
				true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- Inst.instElement failed: " +& SCode.printElementStr(el));
        Debug.traceln("  Scope: " +& Env.printEnvPathStr(env));
      then
        fail();
  end matchcontinue;
end instElement;

protected function removeSelfModReference 
"Help function to elabMod, removes self-references in modifiers.
 For instance, A a(x = a.y) the modifier references the component itself. 
 This is removed to avoid a circular dependency, resulting in A a(x=y);"
	input Env.Cache inCache;
	input Ident preId;
	input SCode.Mod inMod;
	output Env.Cache outCache;
  output SCode.Mod outMod;
algorithm
  outExp := matchcontinue(inCache,preId,inMod)
    local 
      Absyn.Exp e,e1; String id;
      Absyn.Each ea;
      Boolean fi;
      list<SCode.SubMod> subs;
      Env.Cache cache;
      Integer cnt;
      Boolean delayTpCheck;

    case(cache,id,SCode.MOD(fi,ea,subs,SOME((e,_)))) 
      equation
        ((e1,(_,cnt))) = Absyn.traverseExp(e,removeSelfModReferenceExp,(id,0));
        (cache,subs) = removeSelfModReferenceSubs(cache,id,subs);
        delayTpCheck = cnt > 0 ;
    then (cache,SCode.MOD(fi,ea,subs,SOME((e1,delayTpCheck)))); // true to delay type checking/elabExp
      
    case(cache,id,SCode.MOD(fi,ea,subs,NONE)) 
      equation
      (cache,subs) = removeSelfModReferenceSubs(cache,id,subs);
    then (cache,SCode.MOD(fi,ea,subs,NONE));
    case(cache,id,inMod) then (cache,inMod);
  end matchcontinue;
end removeSelfModReference;

protected function removeSelfModReferenceSubs 
"Help function to removeSelfModeReference" 
	input Env.Cache inCache;
	input String id;
  input list<SCode.SubMod> inSubs;
  output Env.Cache outCache;
  output list<SCode.SubMod> outSubs;
algorithm
 (outCache,outSubs) := matchcontinue(inCache,id,inSubs)
   local 
     Env.Cache cache;
       list<SCode.Subscript> idxs;
       list<SCode.SubMod> subs;
       SCode.Mod mod;
       Env.Cache cache;
       String ident;

   case (cache,id,{}) then (cache,{});
     
   case(cache, id,SCode.NAMEMOD(ident,mod)::subs) 
     equation
       (cache,SCode.NOMOD()) = removeSelfModReference(cache,id,mod);
       (cache,subs) = removeSelfModReferenceSubs(cache,id,subs);
     then (cache,subs);
     
   case(cache, id,SCode.NAMEMOD(ident,mod)::subs) 
     equation
       (cache,mod) = removeSelfModReference(cache,id,mod);
       (cache,subs) = removeSelfModReferenceSubs(cache,id,subs);
     then (cache,SCode.NAMEMOD(ident,mod)::subs);
     
   case(cache,id,SCode.IDXMOD(idxs,mod)::subs) 
     equation
      (cache,mod) = removeSelfModReference(cache,id,mod);
     (cache,subs) = removeSelfModReferenceSubs(cache,id,subs);
     then (cache,SCode.IDXMOD(idxs,mod)::subs);     
  end matchcontinue;
end removeSelfModReferenceSubs;

protected function removeSelfModReferenceExp 
"Help function to removeSelfModReference."
	input tuple<Absyn.Exp,tuple<String,Integer>> inExp;
	output tuple<Absyn.Exp,tuple<String,Integer>> outExp;
algorithm
  outExp := matchcontinue(inExp)
  local 
    Absyn.ComponentRef cr,cr1;
    Absyn.Exp e,e1;
    String id,id2;
    Absyn.ComponentRef cr1;
    Integer cnt;
    case( (Absyn.CREF(cr),(id,cnt))) 
      equation
        Absyn.CREF_IDENT(id2,_) = Absyn.crefGetFirst(cr);
        // prefix == first part of cref
        0 = System.strcmp(id2,id); 
        cr1 = Absyn.crefStripFirst(cr);      
      then ((Absyn.CREF(cr1),(id,cnt+1)));
		// other expressions falltrough
    case((e,(id,cnt))) then ((e,(id,cnt)));
  end matchcontinue;
end removeSelfModReferenceExp;  

protected function checkRecursiveDefinition 
"Checks that a class does not have a recursive definition, 
 i.e. an instance of itself. This is not allowed in Modelica."
  input Env.Env env;
  input Absyn.Path tp;
  input ClassInf.State ci_state;
  input SCode.Class cl;
algorithm
  _ := matchcontinue(env,tp,ci_state,cl)
    local Absyn.Path envPath;
    // No envpath, nothing to check.
    case(env,tp,ci_state,cl) 
      equation
        NONE = Env.getEnvPath(env);
      then ();
    // No recursive definition, succed.
    case(env,tp,ci_state,cl) 
      equation
        SOME(envPath) = Env.getEnvPath(env);
        false = Absyn.pathSuffixOf(tp,envPath) and checkRecursiveDefinitionRecConst(ci_state,cl);
      then ();
    // report error: recursive definition        
    case(env,tp,ci_state,cl) local String s; 
      equation
        SOME(envPath) = Env.getEnvPath(env);
        true= Absyn.pathSuffixOf(tp,envPath);
        s = Absyn.pathString(tp);
        Error.addMessage(Error.RECURSIVE_DEFINITION,{s});
      then fail();
    // failure
    case(env,tp,ci_state,cl) 
      equation
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace","-Inst.checkRecursiveDefinition failed, envpath="+&Env.printEnvPathStr(env)+&" tp :"+&Absyn.pathString(tp)+&"\n");
      then fail();      
  end matchcontinue;
end checkRecursiveDefinition;
 
protected function checkMultiplyDeclared 
"Check if variable is multiply declared and 
 that all declarations are identical if so."
  input Env.Cache cache;
  input Env env;
  input Mod mod;
  input Prefix prefix;
  input Connect.Sets csets;
  input ClassInf.State ciState;
  input tuple<SCode.Element, Mod> compTuple;
  input InstDims instDims;
  input Boolean impl;
  output Boolean alreadyDeclared;
algorithm
  alreadyDeclared := matchcontinue(cache,env,mod,prefix,csets,ciState,compTuple,instDims,impl)
    local
      list<Env.Frame> env,env_1,env2,env2_1,cenv,compenv;
      DAE.Mod mod;
      String n;
      Boolean finalPrefix,repl,prot;
      SCode.Element oldElt; DAE.Mod oldMod;
      tuple<SCode.Element,DAE.Mod> newComp;
      Env.InstStatus instStatus;
      SCode.Element oldElt; DAE.Mod oldMod;
      tuple<SCode.Element,DAE.Mod> newComp;
      Boolean alreadyDeclared;

    case (_,_,_,_,_,_,_,_,_) equation /*print(" dupe check setting ");*/ ErrorExt.setCheckpoint(); then fail();
        
    /* If a variable is declared multiple times, the first is used. 
     * If the two variables are not identical, an error is given.
     */ 
     
    case (cache,env,mod,prefix,csets,ciState,
          (newComp as (SCode.COMPONENT(component = n,finalPrefix = finalPrefix,replaceablePrefix = repl,protectedPrefix = prot),_)),_,_)
      equation 
        (_,_,SOME((oldElt,oldMod)),instStatus,_) = Lookup.lookupIdentLocal(cache, env, n); 
        checkMultipleElementsIdentical((oldElt,oldMod),newComp);
        alreadyDeclared = instStatusToBool(instStatus);
      then alreadyDeclared;
       
    // If not multiply declared, return.
    case (cache,env,mod,prefix,csets,ciState,
          (newComp as (SCode.COMPONENT(component = n,finalPrefix = finalPrefix,replaceablePrefix = repl,protectedPrefix = prot),_)),_,_)
      equation 
        failure((_,_,SOME((oldElt,oldMod)),_,_) = Lookup.lookupIdentLocal(cache,env, n)); 
      then false;

    // failure
    case (cache,env,mod,prefix,csets,ciState,_,_,_) 
      equation
        Debug.fprint("failtrace","-Inst.checkMultiplyDeclared failed\n");
      then fail();     
  end matchcontinue;
end checkMultiplyDeclared;

protected function instStatusToBool 
"Translates InstStatus to a boolean indicating if component is allready declared."
  input Env.InstStatus instStatus;
  output Boolean alreadyDeclared;
algorithm
  alreadyDeclared := matchcontinue(instStatus)
    case (Env.VAR_DAE()) then true;
    case (Env.VAR_UNTYPED()) then false;
    case (Env.VAR_TYPED()) then false;
  end matchcontinue;
end instStatusToBool;

protected function checkMultipleElementsIdentical 
"Checks that the old declaration is identical 
 to the new one. If not, give error message"
  input tuple<SCode.Element,DAE.Mod> oldComponent;
  input tuple<SCode.Element,DAE.Mod> newComponent;
algorithm
  _ := matchcontinue(oldComponent,newComponent)
    local 
      SCode.Element oldElt,newElt;
      DAE.Mod oldMod,newMod;
      String s1,s2;
      SCode.Ident n "the component name" ;
      Absyn.InnerOuter io "the inner/outer/innerouter prefix" ;
      Boolean fp,rp,pp;
      SCode.Attributes attr;
      Absyn.TypeSpec ts ;
      SCode.Mod mod;
      SCode.OptBaseClass bcp1, bcp2;
      Option<SCode.Comment> comment;
      Option<Absyn.Exp> condition;
      Option<Absyn.Info> info;
      Option<Absyn.ConstrainClass> cc;

    // try equality first! 
    case((oldElt,oldMod),(newElt,newMod)) 
      equation
        // NOTE: Should be type identical instead? see spec. 
        // p.23, check of flattening. "Check that duplicate elements are identical". 
        true = SCode.elementEqual(oldElt,newElt);
      then ();

    case ((oldElt,oldMod),(newElt,newMod)) 
      equation
      s1 = SCode.unparseElementStr(oldElt);
      s2 = SCode.unparseElementStr(newElt);
      Error.addMessage(Error.DUPLICATE_ELEMENTS_NOT_IDENTICAL(),{s1,s2});
      //print(" *** error message added *** \n");
      then fail();
  end matchcontinue;
end checkMultipleElementsIdentical;
  
protected function getDerivedEnv 
"function: getDerivedEnv 
  This function returns the environment of a baseclass.
  It is used when instantiating a component defined in a baseclass."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input SCode.OptBaseClass inAbsynPathOption;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
algorithm 
  (outCache,outEnv,outIH) := matchcontinue (inCache,inEnv,inIH,inAbsynPathOption)
    local
      list<Env.Frame> env,cenv,cenv_2,env_2,fs;
      Env.Frame top_frame;
      SCode.Class c;
      String cn2;
      Boolean enc2,enc;
      SCode.Restriction r;
      ClassInf.State new_ci_state,new_ci_state_1;
      Option<String> id;
      Env.AvlTree tps;
      Env.AvlTree cl;
      list<Env.Item> imps;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crs;
      SCode.BaseClass bc;
      Absyn.Path tp,envpath,newTp;
      Env.Cache cache;
      InstanceHierarchy ih;
      list<SCode.Element> defineUnits;
      SCode.Mod mod;

    /* case (cache,env,NONE,ih) then (cache,env,ih); adrpo: CHECK if needed! */

    case (cache,
          (env as (Env.FRAME(id, cl,tps,imps,_,crs,enc,defineUnits) :: fs)),ih,NONE) 
      equation
        // print("Inst.getDerivedEnv: case 1 " +& Env.printEnvPathStr(env) +& "\n");
      then 
        (cache,Env.FRAME(id,cl,tps,imps,{},crs,enc,defineUnits)::fs,ih);
 
    /* Special case to avoid infinite recursion.
     * If in scope A.B and searching for A.B.C.D, look for C.D directly in the scope. Otherwise, A.B 
     * will be instantiated over and over again, see testcase packages2.mo
     */      		
    case (cache,
          (env as (Env.FRAME(id,cl,tps,imps,_,crs,enc,defineUnits) :: fs)),ih,SOME((tp,mod))) 
      equation        
				SOME(envpath) = Env.getEnvPath(env);
				// print("Inst.getDerivedEnv: case 2 " +& Env.printEnvPathStr(env) +& "\n");
				true = Absyn.pathPrefixOf(envpath,tp);
				newTp = Absyn.removePrefix(envpath,tp);
				(cache,env_2) = Lookup.lookupAndInstantiate(cache,env,newTp,mod,true);
        // print("Inst.getDerivedEnv: case 2 end " +& Env.printEnvPathStr(env) +& "\n");
      then
        (cache,Env.FRAME(id,cl,tps,imps,env_2,crs,enc,defineUnits) :: fs,ih);
            
    /* Base classes are fully qualified names, search from top scope.
    * This is needed since the environment can be encapsulated, but inherited classes are not affected 
    * by this and therefore should search from top scope directly. 
    */ 
    case (cache,
          (env as (Env.FRAME(id,cl,tps,imps,_,crs,enc,defineUnits) :: fs)),ih,SOME((tp,mod)))
      equation 
        // print("Inst.getDerivedEnv: case 3 " +& Env.printEnvPathStr(env) +& "\n");
        top_frame = Env.topFrame(env);
        (cache,env_2) = Lookup.lookupAndInstantiate(cache,{top_frame},tp,mod,true);
        // print("Inst.getDerivedEnv: case 3 end " +& Env.printEnvPathStr(env) +& "\n");
      then
        (cache,Env.FRAME(id,cl,tps,imps,env_2,crs,enc,defineUnits) :: fs,ih);
        
    case (_,env,_,_)
      equation 
        // print("Inst.getDerivedEnv: failure " +& Env.printEnvPathStr(env) +& "\n");
        Debug.fprint("failtrace", "- Inst.getDerivedEnv failed\n");
      then
        fail();
  end matchcontinue;
end getDerivedEnv;

protected function removeCrefFromCrefs 
"function: removeCrefFromCrefs
  Removes a variable from a variable list"
  input list<Absyn.ComponentRef> inAbsynComponentRefLst;
  input Absyn.ComponentRef inComponentRef;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm 
  outAbsynComponentRefLst := matchcontinue (inAbsynComponentRefLst,inComponentRef)
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
    case ((cr1 :: rest),cr2) // If modifier like on comp like: T t(x=t.y) => t.y must be removed
      equation 
        Absyn.CREF_QUAL(name = n1) = cr1;
        Absyn.CREF_IDENT(name = n2) = cr2;
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

protected function redeclareType 
"function: redeclareType 
  This function takes a Mod and an SCode.Element and if the modification 
  contains a redeclare of that element, the type is changed and an updated
  element is returned."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input SCode.Element inElement;
  input Prefix inPrefix;
  input ClassInf.State inState;
  input Connect.Sets inSets;
  input Boolean inBoolean;
  input DAE.Mod cmod;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output SCode.Element outElement;
  output Mod outMod;
  output Connect.Sets outSets;
  output DAE.DAElist outDae "contain functions";
algorithm 
  (outCache,outEnv,outIH,outElement,outMod,outSets,outDae) := matchcontinue (inCache,inEnv,inIH,inMod,inElement,inPrefix,inState,inSets,inBoolean,cmod)
    local
      list<Absyn.ComponentRef> crefs;
      list<Env.Frame> env_1,env;
      Connect.Sets csets;
      DAE.Mod m_1,old_m_1,m_2,m_3,m,rmod,innerCompMod,compMod;
      SCode.Element redecl,newcomp,comp,redComp;
      String n1,n2;
      Boolean finalPrefix,repl,prot,repl2,prot2,impl,redfin;
      Absyn.TypeSpec t,t2;
      SCode.Mod mod,old_mod;
      SCode.OptBaseClass bc;
      Option<SCode.Comment> comment,comment2;
      list<tuple<SCode.Element, Mod>> rest;
      Prefix.Prefix pre;
      ClassInf.State ci_state;
      Env.Cache cache;
      InstanceHierarchy ih;

      Option<Absyn.ConstrainClass> cc;
      list<SCode.Element> compsOnConstrain;
      Absyn.InnerOuter io;
      SCode.Attributes at;
      Option<Absyn.Exp> cond;
      Option<Absyn.Info> nfo;
      DAE.DAElist dae,dae1,dae2,dae3;
      
    /* Implicit instantation */
    case (cache,env,ih,(m as DAE.REDECL(tplSCodeElementModLst = (((redecl as 
          SCode.COMPONENT(component = n1,finalPrefix = finalPrefix,replaceablePrefix = repl,protectedPrefix = prot,
                          typeSpec = t,modifications = mod,baseClassPath = bc,comment = comment,
                            innerOuter = io, attributes = at,condition = cond, info = nfo
                            )),rmod) :: rest))),
          SCode.COMPONENT(component = n2,finalPrefix = false,replaceablePrefix = repl2,protectedPrefix = prot2,
                          typeSpec = t2,modifications = old_mod,cc=(cc as SOME(Absyn.CONSTRAINCLASS(elementSpec=_)))),
          pre,ci_state,csets,impl,cmod) 
      equation 
        equality(n1 = n2);
        compsOnConstrain = extractConstrainingComps(cc,env) "extract components belonging to constraining class";
        crefs = getCrefFromMod(mod);
        (cache,env_1,ih,csets,dae1) = updateComponentsInEnv(cache, env, ih, pre, DAE.NOMOD(), crefs, ci_state, csets, impl) "m" ;
        (cache,m_1,dae2) = Mod.elabMod(cache,env_1, pre, mod, impl);
        (cache,old_m_1,dae3) = Mod.elabMod(cache,env_1, pre, old_mod, impl);
        
        old_m_1 = keepConstrainingTypeModifersOnly(old_m_1,compsOnConstrain) "keep previous constrainingclass mods";
        cmod = keepConstrainingTypeModifersOnly(cmod,compsOnConstrain) "keep previous constrainingclass mods";
        
        innerCompMod = Mod.merge(m_1,old_m_1,env_1,pre) "inner comp modifier merg(new_inner, old_inner) ";
        compMod = Mod.merge(rmod,cmod,env_1,pre) "outer comp modifier";
        
        redComp = SCode.COMPONENT(n1,io,finalPrefix,repl,prot,at,t,mod,bc,comment,cond,nfo,cc);
        m_2 = Mod.merge(compMod, innerCompMod, env_1, pre);
        dae = DAEUtil.joinDaeLst({dae1,dae2,dae3});
      then
        (cache,env_1,ih,redComp,m_2,csets,dae);

// no constraining type on comp, throw away modifiers prior to redeclaration
    case (cache,env,ih,(m as DAE.REDECL(tplSCodeElementModLst = (((redecl as 
          SCode.COMPONENT(component = n1,finalPrefix = finalPrefix,replaceablePrefix = repl,protectedPrefix = prot,
                          typeSpec = t,modifications = mod,baseClassPath = bc,comment = comment)),rmod) :: rest))),
          SCode.COMPONENT(component = n2,finalPrefix = false,replaceablePrefix = repl2,protectedPrefix = prot2,
                          typeSpec = t2,modifications = old_mod,cc=(cc as NONE)),
          pre,ci_state,csets,impl,cmod) 
      equation 
        equality(n1 = n2);
        crefs = getCrefFromMod(mod);
        (cache,env_1,ih,csets,dae1) = updateComponentsInEnv(cache,env,ih, pre, DAE.NOMOD(), crefs, ci_state, csets, impl) "m" ;
        (cache,m_1,dae2) = Mod.elabMod(cache,env_1, pre, mod, impl);
        (cache,old_m_1,dae3) = Mod.elabMod(cache,env_1, pre, old_mod, impl);
        m_2 = Mod.merge(rmod, m_1, env_1, pre);
        m_3 = Mod.merge(m_2, old_m_1, env_1, pre);
        dae = DAEUtil.joinDaeLst({dae1,dae2,dae3});
      then
        (cache,env_1,ih,redecl,m_3,csets,dae);

    // redeclaration of classes: 
    case (cache,env,ih,(m as DAE.REDECL(tplSCodeElementModLst = (((redecl as SCode.CLASSDEF(name = n1) ),rmod) :: rest))),
          SCode.CLASSDEF(name = n2),pre,ci_state,csets,impl,cmod)
      equation 
        equality(n1 = n2);
        //crefs = getCrefFromMod(mod);
        (cache,env_1,ih,csets,dae1) = updateComponentsInEnv(cache,env,ih, pre, DAE.NOMOD(), {Absyn.CREF_IDENT(n2,{})}, ci_state, csets, impl) "m" ;
        //(cache,m_1) = Mod.elabMod(cache,env_1, pre, mod, impl);
        //(cache,old_m_1) = Mod.elabMod(cache,env_1, pre, old_mod, impl);
        // m_2 = Mod.merge(rmod, m_1, env_1, pre);
        // m_3 = Mod.merge(m_2, old_m_1, env_1, pre);
      then
        (cache,env_1,ih,redecl,rmod,csets,dae1);
        
        // local redeclaration of class
    case (cache,env,ih,(m as DAE.REDECL(tplSCodeElementModLst = (((SCode.CLASSDEF(name = n1) ),rmod) :: rest))),
        redecl as SCode.COMPONENT(typeSpec = apt),pre,ci_state,csets,impl,cmod)
      local Absyn.TypeSpec apt;
      equation 
        n2 = Absyn.typeSpecPathString(apt);
        equality(n1 = n2);        
        (cache,env_1,ih,csets,dae1) = updateComponentsInEnv(cache,env,ih, pre, DAE.NOMOD(), {Absyn.CREF_IDENT(n2,{})}, ci_state, csets, impl) "m" ;
      then
        (cache,env_1,ih,redecl,rmod,csets,dae1);
        
    case (cache,env,ih,(mod as DAE.REDECL(finalPrefix = redfin,tplSCodeElementModLst = (((redecl as 
          SCode.COMPONENT(component = n1,finalPrefix = finalPrefix,replaceablePrefix = repl,protectedPrefix = prot,
                          typeSpec = t,baseClassPath = bc,comment = comment)),rmod) :: rest))),(comp as 
          SCode.COMPONENT(component = n2,finalPrefix = false,replaceablePrefix = repl2,protectedPrefix = prot2,
                          typeSpec = t2,comment = comment2)),
          pre,ci_state,csets,impl,cmod)
      local DAE.Mod mod;
      equation 
        failure(equality(n1 = n2));
        (cache,env_1,ih,newcomp,mod,csets,dae) = 
          redeclareType(cache, env, ih, DAE.REDECL(redfin,rest), comp, pre, ci_state, csets, impl, cmod);
      then
        (cache,env_1,ih,newcomp,mod,csets,dae);
        
    case (cache,env,ih,DAE.REDECL(finalPrefix = redfin,tplSCodeElementModLst = (_ :: rest)),comp,pre,ci_state,csets,impl,cmod)
      local DAE.Mod mod;
      equation 
        (cache,env_1,ih,newcomp,mod,csets,dae) = 
          redeclareType(cache, env, ih, DAE.REDECL(redfin,rest), comp, pre, ci_state, csets, impl,cmod);
      then
        (cache,env_1,ih,newcomp,mod,csets,dae);

    case (cache,env,ih,DAE.REDECL(finalPrefix = redfin,tplSCodeElementModLst = {}),comp,pre,ci_state,csets,impl,cmod) 
      then (cache,env,ih,comp,DAE.NOMOD(),csets,DAEUtil.emptyDae); 
        
    case (cache,env,ih,mod,comp,pre,ci_state,csets,impl,cmod)
      local DAE.Mod mod;
      then
        (cache,env,ih,comp,mod,csets,DAEUtil.emptyDae);
        
    case (_,_,ih,_,_,_,_,_,_,_)
      equation 
        Debug.fprintln("failtrace", "- Inst.redeclareType failed");
      then
        fail();
  end matchcontinue;
end redeclareType;

protected function keepConstrainingTypeModifersOnly 
"Author: BZ, 2009-07
 A function for filtering out the modifications on the constraining type class."
input DAE.Mod inMod;
input list<SCode.Element> elems;
output DAE.Mod filteredMod;
algorithm filteredMod := matchcontinue(inMod,elems)  
  case(inMod,{}) then inMod;
  case(DAE.NOMOD(),_ ) then DAE.NOMOD();
  case(DAE.REDECL(_,_),_) then inMod;
  case(DAE.MOD(b,e,subs,oe),elems)
    local 
      Boolean b;
      Absyn.Each e;
      Option<DAE.EqMod> oe;
      list<DAE.SubMod> subs;
      list<String> compNames;
    equation
      compNames = Util.listMap(elems,SCode.elementName);
      subs = keepConstrainingTypeModifersOnly2(subs,compNames);
      then
        DAE.MOD(b,e,subs,oe);
  end matchcontinue;
end keepConstrainingTypeModifersOnly;

protected function keepConstrainingTypeModifersOnly2 "
Author BZ
Helper function for keepConstrainingTypeModifersOnly 
"
input list<DAE.SubMod> subs;
input list<String> elems;
output list<DAE.SubMod> osubs;
algorithm osubs := matchcontinue(subs,elems)
  local
    DAE.SubMod sub;
    DAE.Mod mod;
    String n;
    list<DAE.SubMod> osubs2;
    Boolean b;
  case({},_) then {};
  case(subs,{}) then subs;
  case((sub as DAE.NAMEMOD(ident=n,mod=mod))::subs,elems)
    equation
      osubs = keepConstrainingTypeModifersOnly2(subs,elems);
      b = Util.listContainsWithCompareFunc(n,elems,stringEqual);
      osubs2 = Util.if_(b, {sub},{});
      osubs = listAppend(osubs2,osubs);
      then
        osubs;
  case(sub::subs,elems) then keepConstrainingTypeModifersOnly2(subs,elems) ;
  end matchcontinue;
end keepConstrainingTypeModifersOnly2;

protected function extractConstrainingComps 
"Author: BZ, 2009-07
 This function examines a optional Absyn.ConstrainClass argument.
 If there is a constraining class, lookup the class and return its elements."
  input Option<Absyn.ConstrainClass> cc;
  input Env.Env env;
  output list<SCode.Element> elems;
algorithm str := matchcontinue(cc,env)
  local
    Absyn.Path path,derP;
    list<Absyn.ElementArg> args;
    Env.Env clenv;
    SCode.Class cl;
    String name;
    list<SCode.Element> selems,extendselts,compelts,extcompelts,classextendselts;
    list<tuple<SCode.Element, Mod>> extcomps;
    Option<Absyn.Annotation> annOpt;
  case(NONE,_) then {};
  case(SOME(Absyn.CONSTRAINCLASS(elementSpec = Absyn.EXTENDS(path,args,annOpt))),env)
    equation
      (_,(cl as SCode.CLASS(name = name, classDef = SCode.PARTS(elementLst=selems))) ,clenv) = Lookup.lookupClass(Env.emptyCache(),env,path,false);
      (_,classextendselts,extendselts,compelts) = splitElts(selems); 
      (_,_,_,_,extcomps,_,_,_,_) = instExtendsAndClassExtendsList(Env.emptyCache(), env, InnerOuter.emptyInstHierarchy, DAE.NOMOD(), extendselts, classextendselts, ClassInf.UNKNOWN(Absyn.IDENT("")), name, true);
      extcompelts = Util.listMap(extcomps,Util.tuple21);
      compelts = listAppend(compelts,extcompelts);
    then
      compelts;  
  case(SOME(Absyn.CONSTRAINCLASS(elementSpec = Absyn.EXTENDS(path,args,annOpt))),env)
    equation
      (_,(cl as SCode.CLASS(classDef = SCode.DERIVED(typeSpec = Absyn.TPATH(path = derP)))) ,clenv) = Lookup.lookupClass(Env.emptyCache(),env,path,false);
      compelts = extractConstrainingComps(SOME(Absyn.CONSTRAINCLASS(Absyn.EXTENDS(derP,{},annOpt),NONE)),env);
    then
      compelts;  
end matchcontinue;
end extractConstrainingComps;

protected function instVar 
"function: instVar 
  this function will look if a variable is inner/outer and depending on that will:
  - lookup for inner in the instanance hieararchy if we have ONLY outer
  - instantiate normally via instVar_dispatch otherwise
  - report an error if we have modifications on outer"
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input UnitAbsyn.InstStore store;
  input ClassInf.State inState;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input Ident inIdent;
  input SCode.Class inClass;
  input SCode.Attributes inAttributes;
  input Boolean protection;
  input list<DimExp> inDimExpLst;
  input list<Integer> inIntegerLst;
  input InstDims inInstDims;
  input Boolean inBoolean;
  input Option<SCode.Comment> inSCodeCommentOption;
  input Absyn.InnerOuter io;
  input Boolean finalPrefix;
  input Option<Absyn.Info> info;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output DAE.Type outType;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm (outCache,outEnv,outIH,outStore,outDae,outSets,outType,outGraph):=
  matchcontinue (inCache,inEnv,inIH,store,inState,inMod,inPrefix,inSets,inIdent,inClass,inAttributes,protection,inDimExpLst,inIntegerLst,inInstDims,inBoolean,inSCodeCommentOption,io,finalPrefix,info,inGraph)
    local
      list<DimExp> dims_1,dims;
      list<Env.Frame> compenv,env,innerCompEnv,outerCompEnv;
      DAE.DAElist dae, outerDae, odae;
      Connect.Sets csets_1,csets;
      tuple<DAE.TType, Option<Absyn.Path>> ty_1,ty;
      ClassInf.State ci_state;
      DAE.Mod mod;
      Prefix.Prefix pre;
      String n,id,s1,s2,s;
      SCode.Class cl;
      SCode.Attributes attr;
      list<Integer> idxs;
      InstDims inst_dims;
      Boolean impl;
      Option<SCode.Comment> comment;
      Env.Cache cache;
      Boolean prot;
      Absyn.Path p1;
      String str;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      Mod modificationOnInnerComponent;
      list<DAE.Element> daeEls;
      DAE.FunctionTree ftree;
      DAE.ComponentRef cref;
      list<DAE.ComponentRef> outers;
      String nInner;
      Absyn.InnerOuter ioInner;

    // is ONLY inner 
    case (cache,env,ih,store,ci_state,mod,pre,csets,n,cl,attr,prot,dims,idxs,inst_dims,impl,comment,io,finalPrefix,info,graph) 
      equation
        false = RTOpts.debugFlag("noIO");
        // only inner!
        false = Absyn.isOuter(io);
        true = Absyn.isInner(io);
        // print ("- Inst.instVar inner: " +& PrefixUtil.printPrefixStr(pre) +& "." +& n +& " in env: " +& Env.printEnvPathStr(env) +& "\n");
        // instantiate as inner
        (cache,innerCompEnv,ih,store,dae,csets,ty,graph) = 
           instVar_dispatch(cache,env,ih,store,ci_state,mod,pre,csets,n,cl,attr,prot,dims,idxs,inst_dims,impl,comment,io,finalPrefix,info,graph);

        cref = PrefixUtil.prefixCref(pre, DAE.CREF_IDENT(n, DAE.ET_OTHER(), {})); 
        
        // also all the components in the environment should be updated to be outer!        
        // switch components from inner to outer in the component env.
        outerCompEnv = InnerOuter.switchInnerToOuterInEnv(innerCompEnv, cref);
        
        // because we calculate outer, we only need variable 
        // declarations so we remove all the equations here
        (outerDae,_) = DAEUtil.splitDAEIntoVarsAndEquations(dae);
        // adrpo: TODO! FIXME! actually outer doesn't generate a visible DAE
        //                     but unfortunately we need them right now for later phases!
        // outerDae = DAEUtil.emptyDae;
        
        // add to instance hierarchy
        ih = InnerOuter.updateInstHierarchy(ih, pre, io, 
               InnerOuter.INST_INNER(
                  n, io, SOME(InnerOuter.INST_RESULT(cache,outerCompEnv,store,outerDae,csets,ty,graph)), {}));
      then 
        (cache,innerCompEnv,ih,store,dae,csets,ty,graph);

    // is ONLY outer and it has modifications on it!
    case (cache,env,ih,store,ci_state,mod,pre,csets,n,cl,attr,prot,dims,idxs,inst_dims,impl,comment,io,finalPrefix,info,graph) 
      equation
        // only outer!
        true = Absyn.isOuter(io);
        false = Absyn.isInner(io);        
        // we should have here any kind of modification! 
        false = Mod.modEqual(mod, DAE.NOMOD());
        cref = PrefixUtil.prefixCref(pre, DAE.CREF_IDENT(n, DAE.ET_OTHER(), {}));        
        s1 = Exp.printComponentRefStr(cref);
        s2 = Mod.prettyPrintMod(mod, 0);
        s = s1 +&  " " +& s2;
        // add a warning!
        Error.addMessage(Error.OUTER_MODIFICATION, {s});
        // call myself without any modification!
        (cache,compenv,ih,store,dae,csets,ty,graph) = 
           instVar(cache,env,ih,store,ci_state,DAE.NOMOD(),pre,csets,n,cl,attr,prot,dims,idxs,inst_dims,impl,comment,io,finalPrefix,info,graph);        
      then 
        (cache,compenv,ih,store,dae,csets,ty,graph);

    // is ONLY outer
    case (cache,env,ih,store,ci_state,mod,pre,csets,n,cl,attr,prot,dims,idxs,inst_dims,impl,comment,io,finalPrefix,info,graph) 
      equation
        false = RTOpts.debugFlag("noIO");
        // only outer!
        true = Absyn.isOuter(io);
        false = Absyn.isInner(io);
        // we should have NO modifications on only outer!
        true = Mod.modEqual(mod, DAE.NOMOD());  

        // print ("- Inst.instVar outer: " +& PrefixUtil.printPrefixStr(pre) +& "." +& n +& " in env: " +& Env.printEnvPathStr(env) +& "\n");
        // lookup in IH
        InnerOuter.INST_INNER(nInner, ioInner, SOME(InnerOuter.INST_RESULT(cache,compenv,store,outerDae,_,ty,graph)),outers) =
          InnerOuter.lookupInnerVar(cache, env, ih, pre, n, io);
        
        // we should update here all the Absyn.INNER in the DAE with Absyn.OUTER
        // and also prefix it with the given prefix!
        DAE.DAE(daeEls, ftree) = outerDae;
        daeEls = InnerOuter.switchInnerToOuterAndPrefix(daeEls, io, pre);
        outerDae = DAE.DAE(daeEls, ftree);
        
        cref = PrefixUtil.prefixCref(pre, DAE.CREF_IDENT(n, DAE.ET_OTHER(), {}));
        ih = InnerOuter.updateInstHierarchy(ih, pre, io, 
               InnerOuter.INST_INNER(
                  nInner, ioInner, SOME(InnerOuter.INST_RESULT(cache,compenv,store,outerDae,csets,ty,graph)), cref::outers));  
        // print("DAE: \n" +& DAEUtil.dumpDebugDAE(dae) +& "\n");
        // print("Env: \n" +& Env.printEnvStr(compenv) +& "\n");
        // outer dae has no meaning!
        // dae = DAEUtil.emptyDae;
      then 
        (cache,compenv,ih,store,outerDae,csets,ty,graph);
        
    // is ONLY outer and the inner was not yet set in the IH!
    case (cache,env,ih,store,ci_state,mod,pre,csets,n,cl,attr,prot,dims,idxs,inst_dims,impl,comment,io,finalPrefix,info,graph) 
      equation
        false = RTOpts.debugFlag("noIO");
        // only outer!
        true = Absyn.isOuter(io);
        false = Absyn.isInner(io);
        // no modifications! 
        true = Mod.modEqual(mod, DAE.NOMOD());        
        // lookup in IH, crap, we couldn't find it!
        InnerOuter.INST_INNER(_, _, NONE(), _) = InnerOuter.lookupInnerVar(cache, env, ih, pre, n, io);
        // print ("- Inst.instVar failed to lookup inner: " +& PrefixUtil.printPrefixStr(pre) +& "." +& n +& " in env: " +& Env.printEnvPathStr(env) +& "\n");
        // call it normaly
        (cache,compenv,ih,store,dae,csets,ty,graph) = 
           instVar_dispatch(cache,env,ih,store,ci_state,mod,pre,csets,n,cl,attr,prot,dims,idxs,inst_dims,impl,comment,io,finalPrefix,info,graph);        
      then 
        (cache,compenv,ih,store,dae,csets,ty,graph);
        
    // is ONLY outer and we failed to lookup the inner in the IH
    case (cache,env,ih,store,ci_state,mod,pre,csets,n,cl,attr,prot,dims,idxs,inst_dims,impl,comment,io,finalPrefix,info,graph) 
      equation
        false = RTOpts.debugFlag("noIO");
        // only outer!
        true = Absyn.isOuter(io);
        false = Absyn.isInner(io);
        // no modifications! 
        true = Mod.modEqual(mod, DAE.NOMOD());        
        // lookup in IH, crap, we couldn't find it!
        failure(_ = InnerOuter.lookupInnerVar(cache, env, ih, pre, n, io));
        // print ("- Inst.instVar failed to lookup inner: " +& PrefixUtil.printPrefixStr(pre) +& "." +& n +& " in env: " +& Env.printEnvPathStr(env) +& "\n");
        // call it normaly
        (cache,compenv,ih,store,dae,csets,ty,graph) = 
           instVar_dispatch(cache,env,ih,store,ci_state,mod,pre,csets,n,cl,attr,prot,dims,idxs,inst_dims,impl,comment,io,finalPrefix,info,graph);        
      then 
        (cache,compenv,ih,store,dae,csets,ty,graph);

    // is inner outer!
    case (cache,env,ih,store,ci_state,mod,pre,csets,n,cl,attr,prot,dims,idxs,inst_dims,impl,comment,io,finalPrefix,info,graph) 
      equation
        false = RTOpts.debugFlag("noIO");
        // both inner and outer        
        true = Absyn.isOuter(io);
        true = Absyn.isInner(io);
        // print ("- Inst.instVar inner outer: " +& PrefixUtil.printPrefixStr(pre) +& "." +& n +& " in env: " +& Env.printEnvPathStr(env) +& "\n");
        (cache,compenv,ih,store,dae,csets,ty,graph) = 
           instVar_dispatch(cache,env,ih,store,ci_state,mod,pre,csets,n,cl,attr,prot,dims,idxs,inst_dims,impl,comment,io,finalPrefix,info,graph);
      then 
        (cache,compenv,ih,store,dae,csets,ty,graph);        
  
    // is NO INNER NOR OUTER or it failed before! 
    case (cache,env,ih,store,ci_state,mod,pre,csets,n,cl,attr,prot,dims,idxs,inst_dims,impl,comment,io,finalPrefix,info,graph) 
      equation
        // no inner no outer
        false = Absyn.isOuter(io);
        false = Absyn.isInner(io);
        // print ("- Inst.instVar NO inner NO outer: " +& PrefixUtil.printPrefixStr(pre) +& "." +& n +& " in env: " +& Env.printEnvPathStr(env) +& "\n");        
        (cache,compenv,ih,store,dae,csets,ty,graph) = 
           instVar_dispatch(cache,env,ih,store,ci_state,mod,pre,csets,n,cl,attr,prot,dims,idxs,inst_dims,impl,comment,io,finalPrefix,info,graph);
      then 
        (cache,compenv,ih,store,dae,csets,ty,graph);
        
    case (cache,env,ih,store,ci_state,mod,pre,csets,n,cl,attr,prot,dims,idxs,inst_dims,impl,comment,io,finalPrefix,info,graph) 
      equation
        true = RTOpts.debugFlag("failtrace");
        cref = PrefixUtil.prefixCref(pre, DAE.CREF_IDENT(n, DAE.ET_OTHER(), {}));
        Debug.fprintln("failtrace", "- Inst.instVar failed while instatiating variable: " +& 
          Exp.printComponentRefStr(cref) +& " " +& Mod.prettyPrintMod(mod, 0) +& 
          " in scope: " +& Env.printEnvPathStr(env));
      then
        fail();
  end matchcontinue;
end instVar;

protected function instVar_dispatch "function: instVar_dispatch 
  A component element in a class may consist of several subcomponents
  or array elements.  This function is used to instantiate a
  component, instantiating all subcomponents and array elements
  separately.
  P.A: Most of the implementation is moved to instVar2. instVar collects
  dimensions for userdefined types, such that these can be correctly 
  handled by instVar2 (using instArray)"
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input UnitAbsyn.InstStore store;
  input ClassInf.State inState;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input Ident inIdent;
  input SCode.Class inClass;
  input SCode.Attributes inAttributes;
  input Boolean protection;
  input list<DimExp> inDimExpLst;
  input list<Integer> inIntegerLst;
  input InstDims inInstDims;
  input Boolean inBoolean;
  input Option<SCode.Comment> inSCodeCommentOption;
  input Absyn.InnerOuter io;
  input Boolean finalPrefix;
  input Option<Absyn.Info> info;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output DAE.Type outType;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm (outCache,outEnv,outIH,outStore,outDae,outSets,outType,outGraph):=
  matchcontinue (inCache,inEnv,inIH,store,inState,inMod,inPrefix,inSets,inIdent,inClass,inAttributes,protection,inDimExpLst,inIntegerLst,inInstDims,inBoolean,inSCodeCommentOption,io,finalPrefix,info,inGraph)
    local
      list<DimExp> dims_1,dims;
      list<Env.Frame> compenv,env;
      DAE.DAElist dae;
      Connect.Sets csets_1,csets;
      tuple<DAE.TType, Option<Absyn.Path>> ty_1,ty;
      ClassInf.State ci_state;
      DAE.Mod mod;
      Prefix.Prefix pre;
      String n,id;
      SCode.Class cl;
      SCode.Attributes attr;
      list<Integer> idxs;
      InstDims inst_dims;
      Boolean impl;
      Option<SCode.Comment> comment;
      Env.Cache cache;
      Boolean prot;
      Absyn.Path p1;
      String str;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      Mod modificationOnInnerComponent;
      
   	// impl component environment dae elements for component Variables of userdefined type, 
   	// e.g. Point p => Real p[3]; These must be handled separately since even if they do not 
	 	// appear to be an array, they can. Therefore we need to collect
 	 	// the full dimensionality and call instVar2 	 	 
    case (cache,env,ih,store,ci_state,mod,pre,csets,n,(cl as SCode.CLASS(name = id)),attr,prot,dims,idxs,inst_dims,impl,comment,io,finalPrefix,info,graph) 
      equation 
				// Collect dimensions
        p1 = Absyn.IDENT(n);
        p1 = PrefixUtil.prefixPath(p1,pre);
        str = Absyn.pathString(p1);
        Error.updateCurrentComponent(str,info);
        (cache,(dims_1 as (_ :: _)),cl,dae) = getUsertypeDimensions(cache,env, mod, pre, cl, inst_dims, impl);
        attr = propagateClassPrefix(attr,pre);
        (cache,compenv,ih,store,dae,csets_1,ty_1,graph) = instVar2(cache,env,ih,store, ci_state, mod, pre, csets, n, cl, attr, prot, dims_1, idxs, inst_dims, impl, comment,io,finalPrefix,graph);
        ty = ty_1; // adrpo: this doubles the dimension! ty = makeArrayType(dims_1, ty_1);
        Error.updateCurrentComponent("",NONE); 
      then
        (cache,compenv,ih,store,dae,csets_1,ty,graph);
        
    // Generic case: fall trough 
    case (cache,env,ih,store,ci_state,mod,pre,csets,n,(cl as SCode.CLASS(name = id)),attr,prot,dims,idxs,inst_dims,impl,comment,io,finalPrefix,info,graph) 
      equation 
        p1 = Absyn.IDENT(n);
        p1 = PrefixUtil.prefixPath(p1,pre);
        str = Absyn.pathString(p1); 
        Error.updateCurrentComponent(str,info);
        // print("instVar: " +& str +& " in scope " +& Env.printEnvPathStr(env) +& "\t mods: " +& Mod.printModStr(mod) +& "\n");        
        attr = propagateClassPrefix(attr,pre);
        (cache,compenv,ih,store,dae,csets_1,ty_1,graph) = 
        instVar2(cache,env,ih,store, ci_state, mod, pre, csets, n, 
                 cl, attr, prot, dims, idxs, inst_dims, impl, 
                 comment,io,finalPrefix,graph);
        Error.updateCurrentComponent("",NONE); 
      then
        (cache,compenv,ih,store,dae,csets_1,ty_1,graph);
        
    case(_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_) 
      equation 
        Error.updateCurrentComponent("",NONE); 
      then fail();
  end matchcontinue;
end instVar_dispatch;

protected function instVar2 
"function: instVar2 
  Helper function to instVar, does the main work."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input UnitAbsyn.InstStore store;
  input ClassInf.State inState;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input Ident inIdent;
  input SCode.Class inClass;
  input SCode.Attributes inAttributes;
  input Boolean protection;
  input list<DimExp> inDimExpLst;
  input list<Integer> inIntegerLst;
  input InstDims inInstDims;
  input Boolean inBoolean;
  input Option<SCode.Comment> inSCodeCommentOption;
  input Absyn.InnerOuter io;
  input Boolean finalPrefix;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output DAE.Type outType;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outStore,outDae,outSets,outType,finalPrefix,outGraph):=
  matchcontinue (inCache,inEnv,inIH,store,inState,inMod,inPrefix,inSets,inIdent,inClass,inAttributes,protection,inDimExpLst,inIntegerLst,inInstDims,inBoolean,inSCodeCommentOption,io,finalPrefix,inGraph)
    local
      InstDims inst_dims,inst_dims_1;
      list<DAE.Subscript> dims_1,subs;
      DAE.Exp e,e_1;
      DAE.Properties p;
      list<Env.Frame> env_1,env,compenv;
      Connect.Sets csets_1,csets;
      tuple<DAE.TType, Option<Absyn.Path>> ty,ty_1,arrty;
      ClassInf.State st,ci_state;
      DAE.ComponentRef cr;
      DAE.ExpType ty_2;
      DAE.Element daeeq;
      DAE.DAElist dae1,dae,dae1_1,dae3,dae2,daex;
      DAE.Mod mod,mod2;
      Prefix.Prefix pre,pre_1;
      String n,prefix_str;
      SCode.Class cl;
      SCode.Attributes attr,attr2;
      list<DimExp> dims;
      list<Integer> idxs,idxs_1;
      Boolean impl,flowPrefix,streamPrefix;
      Option<SCode.Comment> comment;
      Option<DAE.VariableAttributes> dae_var_attr;
      SCode.Accessibility acc;
      SCode.Variability vt;
      Absyn.Direction dir;
      list<String> index_string;
      Option<DAE.Exp> start;
      DAE.Subscript dime;
      list<DAE.ComponentRef> crs;
      Option<Integer> dimt;
      DimExp dim;
      Env.Cache cache;
      Boolean prot;
      Option<DAE.Exp> eOpt "for external objects";
      list<DAE.ComponentRef> dc;
      list<Connect.OuterConnect> oc;
      DAE.ExpType identType;
      Option<Absyn.ElementAttributes> oDA;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      
    // Rules for instantation of function variables (e.g. input and output     
      
    // Function variables with modifiers (outputs or local/protected variables)
    // For Functions we cannot always find dimensional sizes. e.g. 
	  // input Real x[:]; component environement The class is instantiated 
	  // with the calculated modification, and an extended prefix. 
    //     
    case (cache,env,ih,store,ci_state,mod,pre,csets,n,cl,attr,prot,dims,idxs,inst_dims,impl,comment,io,finalPrefix,graph)
      equation 
        ClassInf.isFunction(ci_state);
        
        //Do not flatten because it is a function 
        dims_1 = instDimExpLst(dims, impl) ;
                
        //get the equation modification 
        SOME(DAE.TYPED(e,_,p)) = Mod.modEquation(mod) ;				
				//Instantiate type of the component, skip dae/not flattening
				// adrpo: do not send in the modifications as it will fail if the modification is an ARRAY. 
				//        anyhow the modifications are handled below.
				//        input Integer sequence[3](min = {1,1,1}, max = {3,3,3}) = {1,2,3}; // this will fail if we send in the mod.
				//        see testsuite/mofiles/Sequence.mo
        (cache,env_1,ih,store,_,csets_1,ty,st,_,graph) = instClass(cache,env,ih,store, /* mod */ DAE.NOMOD(), pre, csets, cl, inst_dims, impl, INNER_CALL(), graph);
        //Make it an array type since we are not flattening
        ty_1 = makeArrayType(dims, ty);

        (cache,dae_var_attr) = instDaeVariableAttributes(cache, env, mod, ty, {});
        // Check binding type matches variable type
        (e_1,_) = Types.matchProp(e,p,DAE.PROP(ty_1,DAE.C_VAR()),true);
        
        //Generate variable with default binding
        ty_2 = Types.elabType(ty_1);
        cr = PrefixUtil.prefixCref(pre, DAE.CREF_IDENT(n,ty_2,{}));

        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        dae = daeDeclare(cr, ci_state, ty, attr, prot, SOME(e_1), {dims_1}, NONE, dae_var_attr, comment,io,finalPrefix,source,true);
        store = UnitAbsynBuilder.instAddStore(store,ty,cr);
      then
        (cache,env_1,ih,store,dae,csets_1,ty_1,graph);
   
    // Function variables without binding
    case (cache,env,ih,store,ci_state,mod,pre,csets,n,(cl as SCode.CLASS(name=n2)),attr,prot,dims,idxs,inst_dims,impl,comment,io,finalPrefix,graph)
      local
        DAE.Mod tm1,tm2,mod2; 
        String n2;
       equation 
        ClassInf.isFunction(ci_state);
         //Instantiate type of the component, skip dae/not flattening
        (cache,env_1,ih,store,_,csets,ty,st,_,_) = instClass(cache, env, ih, store, mod, pre, csets, cl, inst_dims, impl, INNER_CALL(), ConnectionGraph.EMPTY) ;
        cr = PrefixUtil.prefixCref(pre, DAE.CREF_IDENT(n,DAE.ET_OTHER(),{}));
        (cache,dae_var_attr) = instDaeVariableAttributes(cache, env, mod, ty, {});
        //Do all dimensions...
        dims_1 = instDimExpLst(dims, impl);

        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        dae = daeDeclare(cr, ci_state, ty, attr,prot, NONE, {dims_1}, NONE, dae_var_attr, comment,io,finalPrefix,source,true);
        arrty = makeArrayType(dims, ty);
        store = UnitAbsynBuilder.instAddStore(store,ty,cr);
      then
        (cache,env_1,ih,store,dae,csets,arrty,graph);

    // Constants 
    case (cache,env,ih,store,ci_state,(mod as DAE.MOD(eqModOption = SOME(DAE.TYPED(e,_,_)))),pre,csets,n,cl,
          SCode.ATTR(flowPrefix = flowPrefix,streamPrefix=streamPrefix,
                     accesibility = acc,variability = (vt as SCode.CONST()),direction = dir),
          prot,{},idxs,inst_dims,impl,comment,io,finalPrefix,graph) 
      equation
        idxs_1 = listReverse(idxs);
        pre_1 = PrefixUtil.prefixAdd(n, idxs_1, pre,vt);
        (cache,env_1,ih,store,dae1,csets_1,ty,st,oDA,graph) = instClass(cache,env,ih,store, mod, pre_1, csets, cl, inst_dims, impl, INNER_CALL(), graph);
        dae1_1 = propagateAttributes(dae1, dir, io, SCode.CONST());
        subs = Exp.intSubscripts(idxs_1);
        identType = makeCrefBaseType(ty,inst_dims);
        cr = PrefixUtil.prefixCref(pre, DAE.CREF_IDENT(n,identType,subs));        
        (cache,dae_var_attr) = instDaeVariableAttributes(cache, env, mod, ty, {});
        
        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        eOpt = makeVariableBinding(ty,mod);
        dae3 = daeDeclare(cr, ci_state, ty, SCode.ATTR({},flowPrefix,streamPrefix,acc,vt,dir),prot, eOpt, inst_dims, NONE, dae_var_attr, comment,io,finalPrefix,source,false);
        dae = DAEUtil.joinDaes(dae1_1, dae3);
        store = UnitAbsynBuilder.instAddStore(store,ty,cr);
      then
        (cache,env_1,ih,store,dae,csets_1,ty,graph);

    // Parameters 
    case (cache,env,ih,store,ci_state,(mod as DAE.MOD(eqModOption = SOME(DAE.TYPED(e,_,_)))),pre,csets,n,cl,
          SCode.ATTR(flowPrefix = flowPrefix,streamPrefix = streamPrefix,
                     accesibility = acc,variability = (vt as SCode.PARAM()),direction = dir),
          prot,{},idxs,inst_dims,impl,comment,io,finalPrefix,graph) 
      equation 
        idxs_1 = listReverse(idxs);
        pre_1 = PrefixUtil.prefixAdd(n, idxs_1, pre,vt);    
        //print(" instantiateVarparam: " +& PrefixUtil.printPrefixStr(pre) +& " . " +& n +& " mod: " +&  Mod.printModStr(mod) +& "\n");
        (cache,env_1,ih,store,dae1,csets_1,ty,st,_,graph) = instClass(cache,env,ih,store, mod, pre_1, csets, cl, inst_dims, impl, INNER_CALL(), graph);
        dae1_1 = propagateAttributes(dae1, dir,io,SCode.PARAM());
        subs = Exp.intSubscripts(idxs_1);
        identType = makeCrefBaseType(ty,inst_dims);
        cr = PrefixUtil.prefixCref(pre, DAE.CREF_IDENT(n,identType,subs));
        start = instStartBindingExp(mod, ty, idxs_1);
        (cache,dae_var_attr) = instDaeVariableAttributes(cache, env, mod, ty, {});
        
        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        eOpt = makeVariableBinding(ty,mod);        
        dae3 = daeDeclare(cr, ci_state, ty, SCode.ATTR({},flowPrefix,streamPrefix,acc,vt,dir),prot, eOpt, inst_dims, start, dae_var_attr, comment,io,finalPrefix, source, false);
        
        dae2 = instModEquation(cr, ty, mod, source, impl);
        daex= propagateBinding(dae1_1, dae2) "The equations generated by instModEquation are used only to modify
                                              the bindings of parameters (DAE.VAR's in dae1_1). No extra equations are added. -- alleb";  
        dae = DAEUtil.joinDaes(daex, dae3);
        store = UnitAbsynBuilder.instAddStore(store,ty,cr);
      then
        (cache,env_1,ih,store,dae,csets_1,ty,graph);
           
    // Scalar Variables, different from the ones above since variable binings are expanded to equations.
    // Exception: external objects, see below.
    case (cache,env,ih,store,ci_state,mod,pre,csets,n,(cl as SCode.CLASS(name=ss1)),
          SCode.ATTR(flowPrefix = flowPrefix, streamPrefix = streamPrefix,
                     accesibility = acc,variability = vt,direction = dir),
          prot,{},idxs,inst_dims,impl,comment,io,finalPrefix,graph) 
          local String ss1;
      equation
        idxs_1 = listReverse(idxs);
        pre_1 = PrefixUtil.prefixAdd(n, idxs_1, pre,vt);
        prefix_str = PrefixUtil.printPrefixStr(pre_1);
        // Debug.fprint("insttr", "ICLASS " +& ss1 +& " prefix: " +& prefix_str +& " ");
        // Debug.fprintln("insttr", Env.printEnvPathStr(env) +& "." +& ss1 +& " mods: " +& Mod.printModStr(mod));        
        (mod2) = extractEnumerationClassModifier(inMod,cl) 
        "remove Enumeration class modifier handled in instDaeVariableAttributes call";
        //print("\n Inst class: " +& ss1 +& " for var : " +& n +& ", mods: " +& Mod.printModStr(mod2)+& "\n");
        (cache,env_1,ih,store,dae1,csets_1,ty,st,oDA,graph) = instClass(cache,env,ih,store, mod2, pre_1, csets, cl, inst_dims, impl, INNER_CALL(), graph);
        dae1_1 = propagateAttributes(dae1, dir,io,vt);
        subs = Exp.intSubscripts(idxs_1);
        identType = makeCrefBaseType(ty,inst_dims);
        cr = PrefixUtil.prefixCref(pre, DAE.CREF_IDENT(n,identType,subs));
        
        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        dae2 = instModEquation(cr, ty, mod, source, impl);
        index_string = Util.listMap(idxs_1, int_string);
        //Debug.fprint("insttrind", "\n ******************\n ");
        //Debug.fprint("insttrind", "\n index_string ");
        //Debug.fprintl("insttr", index_string);
        //Debug.fprint("insttrind", "\n component ref ");
        //Debug.fcall("insttr", Exp.printComponentRef, cr);
        //Debug.fprint("insttrind", "\n ******************\n ");
        //Debug.fprint("insttrind", "\n ");
        start = instStartBindingExp(mod, ty, idxs_1);
        eOpt = makeVariableBinding(ty,mod);
        (cache,dae_var_attr) = instDaeVariableAttributes(cache,env, mod, ty, {}) "idxs\'" ;
        dir = propagateAbSCDirection(dir,oDA);
        // adrpo: we cannot check this here as:
        //        we might have modifications on inner that we copy here
        //        Dymola doesn't report modifications on outer as error!
        //        instead we check here if the modification is not the same
        //        as the one on inner  
        false = InnerOuter.modificationOnOuter(cache,env,ih,pre,n,cr,mod,io,impl);
        
        dae3 = daeDeclare(cr, ci_state, ty, SCode.ATTR({},flowPrefix,streamPrefix,acc,vt,dir),prot, eOpt, 
                          inst_dims, start, dae_var_attr, comment,io,finalPrefix,source,false);
        dae3 = DAEUtil.addComponentTypeOpt(dae3, Types.getClassnameOpt(ty));
        dae2 = Util.if_(Types.isComplexType(ty), dae2, DAEUtil.emptyDae);
        dae3 = DAEUtil.joinDaes(dae2,dae3);
        dae = DAEUtil.joinDaes(dae1_1, dae3);
        store = UnitAbsynBuilder.instAddStore(store,ty,cr);
      then
        (cache,env_1,ih,store,dae,csets_1,ty,graph);
    
    // Array variables with unknown dimensions, e.g. Real x[:] = [some expression that can be used to determine dimension]. 
    case (cache,env,ih,store,ci_state,(mod as DAE.MOD(eqModOption = SOME(DAE.TYPED(e,_,_)))),pre,csets,n,cl,attr,prot,
      ((dim as DIMEXP(subscript = DAE.WHOLEDIM)) :: dims),idxs,inst_dims,impl,comment,io,finalPrefix,graph)
      local
        Integer deduced_dim;
      equation
        // Try to deduce the dimension from the modifier.
        (dime as DAE.INDEX(DAE.ICONST(integer = deduced_dim))) = instWholeDimFromMod(dim, mod);
        dim = DIMINT(deduced_dim);
        inst_dims_1 = Util.listListAppendLast(inst_dims, {dime});
        (cache,compenv,ih,store,dae,Connect.SETS(_,crs,dc,oc),ty,graph) = 
          instArray(cache,env,ih,store, ci_state, mod, pre, csets, n, (cl,attr),prot, 1, dim, dims, idxs, inst_dims_1, impl, comment,io,finalPrefix,graph);
        dimt = instDimType(dim);        
        ty_1 = liftNonBasicTypes(ty,dimt); // Do not lift types extending basic type, they are already array types.
      then
        (cache,compenv,ih,store,dae,Connect.SETS({},crs,dc,oc),ty_1,graph);
        
    // Array variables , e.g. Real x[3]
    case (cache,env,ih,store,ci_state,mod,pre,csets,n,cl,attr,prot,(dim :: dims),idxs,inst_dims,impl,comment,io,finalPrefix,graph) 
      equation 
        dime = instDimExp(dim, impl);
        inst_dims_1 = Util.listListAppendLast(inst_dims, {dime});
        (cache,compenv,ih,store,dae,Connect.SETS(_,crs,dc,oc),ty,graph) = 
          instArray(cache,env,ih,store, ci_state, mod, pre, csets, n, (cl,attr),prot, 1, dim, dims, idxs, inst_dims_1, impl, comment,io,finalPrefix,graph);
        dimt = instDimType(dim);        
        ty_1 = liftNonBasicTypes(ty,dimt); // Do not lift types extending basic type, they are already array types.
      then
        (cache,compenv,ih,store,dae,Connect.SETS({},crs,dc,oc),ty_1,graph);
     
    case (_,env,ih,_,_,mod,pre,_,n,_,_,_,_,_,_,_,_,_,_,_) 
      equation 
				true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- Inst.instVar2 failed: " +& 
          PrefixUtil.printPrefixStr(pre) +& "." +& 
          n +& "(" +& Mod.prettyPrintMod(mod, 0) +& ")\n  Scope: " +& 
          Env.printEnvPathStr(env));
      then
        fail();
  end matchcontinue;
end instVar2;

protected function extractEnumerationClassModifier "
Author: BZ, 2008-07
remove builtin attributes from modifier for Enumeration class."
  input DAE.Mod inMod;
  input SCode.Class cl;
  output DAE.Mod outMod2;
algorithm (outMod2) := matchcontinue(inMod,cl)
  local
    Boolean b;
    Absyn.Each e;
    Option<DAE.EqMod> tq;
    list<DAE.SubMod> subs;
  case(inMod, (cl as SCode.CLASS(restriction = SCode.R_ENUMERATION)))
    then Types.removeModList(inMod, {"min","max","start","fixed","quantity"});
  case(inMod, _)
    equation
    then
      (inMod);
  end matchcontinue;
end extractEnumerationClassModifier;

protected function liftNonBasicTypes 
"Helper functin to instVar2. All array variables should be 
 given array types, by lifting the type given a dimensionality. 
 An exception are types extending builtin types, since they already 
 have array types. This relation performs the lifting for alltypes 
 except types extending basic types."
	input DAE.Type tp;
  input  Option<Integer> dimt;
	output DAE.Type outTp;
algorithm
  outTp:= matchcontinue(tp,dimt)
    case ((tp as (DAE.T_COMPLEX(_,_,SOME(_),_),_)),dimt) then tp;
      
    case (tp,dimt) 
      equation  outTp = Types.liftArray(tp, dimt);
      then outTp;
  end matchcontinue;
end liftNonBasicTypes;

protected function makeVariableBinding "Helper relation to instVar2

For external objects the binding contains the constructor call.  This must be inserted in the DAE.VAR 
as the binding expression so the constructor code can be generated.
-- BZ 2008-11, added:
If the type is not externa object, the normal binding value is bound, 
Unless it is a complex var that not inherites a basic type. In that case DAE.Equation are generated."
  input DAE.Type tp;
  input DAE.Mod mod;
  output Option<DAE.Exp> eOpt;
algorithm eOpt := matchcontinue(tp,mod)
  local DAE.Exp e,e1;DAE.Properties p;
  case ((DAE.T_COMPLEX(complexClassType=ClassInf.EXTERNAL_OBJ(_)),_),
    DAE.MOD(eqModOption = SOME(DAE.TYPED(e,_,_))))
    then SOME(e);
  case(tp,mod)
    equation
      SOME(DAE.TYPED(e,_,p)) = Mod.modEquation(mod);
      (e1,_) = Types.matchProp(e,p,DAE.PROP(tp,DAE.C_VAR()),true);
    then
      SOME(e1);
  case (_,_) then NONE;
end matchcontinue;
end makeVariableBinding;

public function makeArrayType 
"function: makeArrayType 
  Creates an array type from the element type 
  given as argument and a list of dimensional sizes."
  input list<DimExp> inDimExpLst;
  input DAE.Type inType;
  output DAE.Type outType;
algorithm 
  outType := matchcontinue (inDimExpLst,inType)
    local
      tuple<DAE.TType, Option<Absyn.Path>> ty,ty_1;
      Integer i;
      list<DimExp> xs;
      Option<Absyn.Path> p;
      DAE.TType tty;
    case ({},ty) then ty; 
    case ((DIMINT(integer = i) :: xs),(tty,p))
      equation 
        ty_1 = makeArrayType(xs, (tty,p));
      then
        ((DAE.T_ARRAY(DAE.DIM(SOME(i)),ty_1),p));
    case ((DIMEXP(subscript = _) :: xs),(tty,p))
      equation 
        ty_1 = makeArrayType(xs, (tty,p));
      then
        ((DAE.T_ARRAY(DAE.DIM(NONE),ty_1),p));
    case (_,_)
      equation 
        Debug.fprintln("failtrace", "- Inst.makeArrayType failed");
      then
        fail();
  end matchcontinue;
end makeArrayType;

public function getUsertypeDimensions 
"function: getUsertypeDimensions 
  Retrieves the dimensions of a usertype and the innermost class type to instantiate.
  The builtin types have no dimension, whereas a user defined type might
  have dimensions. For instance, type Point = Real[3]; 
  has one dimension of size 3 and the class to instantiate is Real"
  input Env.Cache inCache;
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input SCode.Class inClass;
  input InstDims inInstDims;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output list<DimExp> outDimExpLst;
  output SCode.Class classToInstantiate;
  output DAE.DAElist outDae "contain functions";
algorithm 
  (outCache,outDimExpLst,classToInstantiate,outDae) := matchcontinue (inCache,inEnv,inMod,inPrefix,inClass,inInstDims,inBoolean)
    local
      SCode.Class cl;
      list<Env.Frame> cenv,env;
      Absyn.ComponentRef owncref;
      list<Absyn.Subscript> ad_1;
      DAE.Mod mod_1,mods_2,mods_3,mods;
      Option<DAE.EqMod> eq;
      list<DimExp> dim1,dim2,res;
      Prefix.Prefix pre;
      String id;
      Absyn.Path cn;
      Option<list<Absyn.Subscript>> ad;
      SCode.Mod mod;
      InstDims dims;
      Boolean impl;
      Env.Cache cache;
      DAE.DAElist fdae,fdae2,fdae3;
      
    case (cache,_,_,_,cl as SCode.CLASS(name = "Real"),_,_) then (cache,{},cl,DAEUtil.emptyDae);  /* impl */ 
    case (cache,_,_,_,cl as SCode.CLASS(name = "Integer"),_,_) then (cache,{},cl,DAEUtil.emptyDae); 
    case (cache,_,_,_,cl as SCode.CLASS(name = "String"),_,_) then (cache,{},cl,DAEUtil.emptyDae); 
    case (cache,_,_,_,cl as SCode.CLASS(name = "Boolean"),_,_) then (cache,{},cl,DAEUtil.emptyDae);
      
    case (cache,_,_,_,cl as SCode.CLASS(restriction = SCode.R_RECORD(), 
                                        classDef = SCode.PARTS(elementLst = _)),_,_) then (cache,{},cl,DAEUtil.emptyDae);

    /*------------------------*/
    /* MetaModelica extension */
    case (cache,env,_,_,cl as SCode.CLASS(name = id,
                                          classDef = SCode.DERIVED(Absyn.TCOMPLEX(Absyn.IDENT(_),_,arrayDim = ad),
                                                                   modifications = mod)),
          dims,impl)
      equation
        true=RTOpts.acceptMetaModelicaGrammar();
        owncref = Absyn.CREF_IDENT(id,{});
        ad_1 = getOptionArraydim(ad);
        // Absyn.IDENT("Integer") used as a dummie
        (cache,dim1,fdae) = elabArraydim(cache,env, owncref, Absyn.IDENT("Integer"), ad_1, NONE, impl, NONE,true);
      then (cache,dim1,cl,fdae);
    // Partial function definitions with no output - stefan
    case (cache,env,_,_,cl as SCode.CLASS(name = id,restriction = SCode.R_FUNCTION(),partialPrefix = true),_,_) then (cache,{},cl,DAEUtil.emptyDae);
    case (cache,env,_,_,SCode.CLASS(name = id,restriction = SCode.R_FUNCTION(),partialPrefix = false),_,_)
      equation
        Error.addMessage(Error.META_FUNCTION_TYPE_NO_PARTIAL_PREFIX, {id});
      then fail();
      
      // MetaModelica Uniontype. Added 2009-05-11 sjoelund
    case (cache,env,_,_,cl as SCode.CLASS(name = id,restriction = SCode.R_UNIONTYPE()),_,_) then (cache,{},cl,DAEUtil.emptyDae);
      /*----------------------*/

    /* Derived classes with restriction type, e.g. type Point = Real[3]; */ 
    case (cache,env,mods,pre,inClass as SCode.CLASS(name = id,restriction = SCode.R_TYPE(),
                                         classDef = SCode.DERIVED(Absyn.TPATH(path = cn, arrayDim = ad),modifications = mod)),
          dims,impl) 
      equation
        (cache,cl,cenv) = Lookup.lookupClass(cache,env, cn, true);
        owncref = Absyn.CREF_IDENT(id,{});
        ad_1 = getOptionArraydim(ad);
        (cache,mod_1,fdae) = Mod.elabMod(cache,env, pre, mod, impl);
        mods_2 = Mod.merge(mods, mod_1, env, pre);
        eq = Mod.modEquation(mods_2);
        mods_3 = Mod.lookupCompModification(mods_2, id);                
        (cache,dim1,cl,fdae2) = getUsertypeDimensions(cache,cenv, mods_3, pre, cl, dims, impl);
        (cache,dim2,fdae3) = elabArraydim(cache,env, owncref, cn, ad_1, eq, impl, NONE,true);
        res = listAppend(dim2, dim1);
        fdae = DAEUtil.joinDaeLst({fdae,fdae2,fdae3});
      then
        (cache,res,cl,fdae);

    /* extended classes type Y = Real[3]; class X extends Y; */   
    case (cache,env,mods,pre,SCode.CLASS(name = id,restriction = _,
                                         classDef = SCode.PARTS(elementLst=els,
                                                                normalEquationLst={},
                                                                initialEquationLst={},
                                                                normalAlgorithmLst={},
                                                                initialAlgorithmLst={},
                                                                externalDecl=_)),
          dims,impl) 
      local list<SCode.Element> els, extendsels; SCode.Path path;
      equation 
        (_,_,{SCode.EXTENDS(path, mod,_)},{}) = splitElts(els); // ONLY ONE extends!
        (cache,mod_1,fdae) = Mod.elabMod(cache,env, pre, mod, impl);
        mods_2 = Mod.merge(mods, mod_1, env, pre);
        (cache,cl,cenv) = Lookup.lookupClass(cache,env, path, true);
        (cache,res,cl,fdae2) = getUsertypeDimensions(cache,env,mods_2,pre,cl,{},impl);
        fdae = DAEUtil.joinDaes(fdae,fdae2);
      then
        (cache,res,cl,fdae);    
        
    case (cache,_,_,_,cl as SCode.CLASS(name = _),_,_) 
      then (cache,{},cl,DAEUtil.emptyDae);
    
    case (_,_,_,_,SCode.CLASS(name = id),_,_)
      equation
				true = RTOpts.debugFlag("failtrace");
        id = SCode.printClassStr(inClass);
        Debug.traceln("Inst.getUsertypeDimensions failed: " +& id);
      then fail();
  end matchcontinue;
end getUsertypeDimensions;

protected function getCrefFromMod 
"function: getCrefFromMod
  author: PA 
  Return all variables in a modifier, SCode.Mod.
  This is needed to prepare the second pass of instantiation, because a 
  component can not be instantiated unless the types of the modifiers are
  known. Therefore the variables in all  modifiers must be instantiated 
  before the component itself is instantiated. This is done by backpatching 
  in the instantiation process. 
  NOTE: This means that a recursive modification structure 
        (which is not allowed in Modelica) will currently 
        run the compiler into infinite recursion."
  input SCode.Mod inMod;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm 
  outAbsynComponentRefLst := matchcontinue (inMod)
    local
      list<Absyn.ComponentRef> res1,res2,res,l1,l2;
      Boolean b;
      String n;
      SCode.Mod m,mod;
      list<SCode.Element> xs;
      list<SCode.SubMod> submods;
      Absyn.Exp e;

    /* For redeclarations e.g \"redeclare B2 b(cref=<expr>)\", find cref */
    case (SCode.REDECL(finalPrefix = b,elementLst = (SCode.COMPONENT(component = n,modifications = m) :: xs))) 
      equation 
        res1 = getCrefFromMod(SCode.REDECL(b,xs));
        res2 = getCrefFromMod(m);
        res = listAppend(res1, res2);
      then
        res;

    /* For redeclarations e.g \"redeclare B2 b(cref=<expr>)\", find cref */ 
    case (SCode.REDECL(finalPrefix = b,elementLst = (_ :: xs))) 
      equation 
        res = getCrefFromMod(SCode.REDECL(b,xs));
      then
        res;
    case (SCode.REDECL(finalPrefix = b,elementLst = {})) then {}; 

    /* Find in sub modifications e.g A(B=3) find B */ 
    case ((mod as SCode.MOD(subModLst = submods,absynExpOption = SOME((e,_))))) 
      equation 
        l1 = getCrefFromSubmods(submods);
        l2 = Absyn.getCrefFromExp(e,true);
        res = listAppend(l2, l1);
      then
        res;
    case (SCode.MOD(subModLst = submods,absynExpOption = NONE))
      equation 
        res = getCrefFromSubmods(submods);
      then
        res;
    case(SCode.NOMOD()) then {};        
    case (_) then {}; // this should never happen, keeping it anyway.
    case (_)
      equation 
        Debug.fprintln("failtrace", "- Inst.getCrefFromMod failed");
      then
        fail();
  end matchcontinue;
end getCrefFromMod;

protected function getCrefFromDim 
"function: getCrefFromDim
  author: PA
  Similar to getCrefFromMod, but investigates 
  array dimensionalitites instead."
  input Absyn.ArrayDim inArrayDim;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm 
  outAbsynComponentRefLst := matchcontinue (inArrayDim)
    local
      list<Absyn.ComponentRef> l1,l2,res;
      Absyn.Exp exp;
      list<Absyn.Subscript> rest;
    case ((Absyn.SUBSCRIPT(subScript = exp) :: rest))
      equation 
        l1 = getCrefFromDim(rest);
        l2 = Absyn.getCrefFromExp(exp,true);
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
        Debug.fprintln("failtrace", "- Inst.getCrefFromDim failed");
      then
        fail();
  end matchcontinue;
end getCrefFromDim;

protected function getCrefFromSubmods 
"function: getCrefFromSubmods 
  Helper function to getCrefFromMod, investigates sub modifiers."
  input list<SCode.SubMod> inSCodeSubModLst;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm 
  outAbsynComponentRefLst := matchcontinue (inSCodeSubModLst)
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

protected function updateComponentsInEnv 
"function: updateComponentsInEnv
  author: PA
  This function is the second pass of component instantiation, when a 
  component can be instantiated fully and the type of the component can be 
  determined. The type is added/updated to the environment such that other 
  components can use it when they are instantiated."
  input Env.Cache cache;
  input Env env;
  input InstanceHierarchy inIH;
  input Prefix.Prefix pre;
  input Mod mod;
  input list<Absyn.ComponentRef> crefs;
  input ClassInf.State ci_state;
  input Connect.Sets csets;
  input Boolean impl;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output Connect.Sets outSets;
  output DAE.DAElist outDae "contain functions";
algorithm 
  (outCache,outEnv,outIH,outSets,_,outDae):= 
  updateComponentsInEnv2(cache,env,inIH,pre,mod,crefs,ci_state,csets,impl,HashTable5.emptyHashTable());
  //print("outEnv:");print(Env.printEnvStr(outEnv));print("\n"); 
end updateComponentsInEnv;

protected function updateComponentInEnv 
"function: updateComponentInEnv
  author: PA
  Helper function to updateComponentsInEnv.
  Does the work for one variable."
	input Env.Cache cache;
  input Env env;
  input InstanceHierarchy inIH;
  input Prefix.Prefix pre;
  input Mod mod;
  input Absyn.ComponentRef cref;
  input ClassInf.State ci_state;
  input Connect.Sets csets;
  input Boolean impl;
  input HashTable5.HashTable updatedComps;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output Connect.Sets outSets;
  output HashTable5.HashTable outUpdatedComps;
  output DAE.DAElist outDae "contains functions";
algorithm 
  (outCache,outEnv,outIH,outSets,outUpdatedComps,outDae) := 
  matchcontinue (cache,env,inIH,pre,mod,cref,ci_state,csets,impl,updatedComps)
    local
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      String n,id,str,str2,str3;
      Boolean finalPrefix,repl,prot,flowPrefix,streamPrefix;
      Absyn.InnerOuter io;
      SCode.Attributes attr;
      list<Absyn.Subscript> ad,subscr;
      SCode.Accessibility acc;
      SCode.Variability param;
      Absyn.Direction dir;
      Absyn.Path t;
      SCode.Mod m;
      SCode.OptBaseClass bc;
      Option<SCode.Comment> comment;
      DAE.Mod cmod,m_1,classmod,mm,mod,mod_1,mod_2,mod_3,mods;
      SCode.Class cl;
      list<Env.Frame> cenv,env2,compenv,env2_1,env_1;
      list<Absyn.ComponentRef> crefs,crefs2,crefs3,crefs_1,crefs_2;
      Connect.Sets csets,csets_1;
      Option<DAE.EqMod> eq;
      list<DimExp> dims;
      DAE.DAElist dae1;
      DAE.Binding binding,binding_1;
      Absyn.ComponentRef cref,owncref;
      Option<Absyn.Exp> cond;
      DAE.Var tyVar;
      Env.InstStatus is;
      Option<Absyn.Info> info;
      InstanceHierarchy ih;
      Option<Absyn.ConstrainClass> cc;
      DAE.DAElist dae,dae1,dae2,dae3,dae4;
      DAE.FunctionTree funcs;
    /* Variables that have Element in Environment, i.e. no type 
	 * information are instantiated here to get the type. 
     */ 
    case (cache,env,ih,pre,mods,(cref as Absyn.CREF_IDENT(name = id,subscripts = subscr)),ci_state,csets,impl,updatedComps) 
      equation 
        (cache,ty,SOME((SCode.COMPONENT(n,io,finalPrefix,repl,prot,(attr as SCode.ATTR(ad,flowPrefix,streamPrefix,acc,param,dir)),Absyn.TPATH(t, _),m,bc,comment,cond,info,cc),cmod)),_) 
        	= Lookup.lookupIdent(cache, env, id);
        (cache,cl,cenv) = Lookup.lookupClass(cache, env, t, false);
        (mods,cmod,m) = noModForUpdatedComponents(updatedComps,cref,mods,cmod,m);
        crefs = getCrefFromMod(m);
        crefs2 = getCrefFromDim(ad);
        crefs3 = getCrefFromCond(cond);
        crefs_1 = listAppend(listAppend(crefs, crefs2),crefs3);
        crefs_2 = removeCrefFromCrefs(crefs_1, cref);
        updatedComps = HashTable5.add((cref,0),updatedComps);
        (cache,env2,ih,csets,updatedComps,dae4) = updateComponentsInEnv2(cache, env, ih, pre, mods, crefs_2, ci_state, csets, impl, updatedComps);
        ErrorExt.setCheckpoint();
        (cache,m_1,dae1) = Mod.elabMod(cache,env2, Prefix.NOPRE(), m, impl) 
        "Prefix does not matter, since we only update types 
         in env, and does not make any dae elements, etc.." ;
        ErrorExt.rollBack() 
        "Rollback all error since we are only interested in type, not value at this point. 
         Errors that occurse in elabMod which does not fail the function will be accepted.";
        classmod = Mod.lookupModificationP(mods, t);
        mm = Mod.lookupCompModification(mods, n);
        mod = Mod.merge(classmod, mm, env2, Prefix.NOPRE());
        mod_1 = Mod.merge(mod, m_1, env2, Prefix.NOPRE());
        mod_2 = Mod.merge(cmod, mod_1, env2, Prefix.NOPRE());
        (cache,mod_3,dae2) = Mod.updateMod(cache,env2, Prefix.NOPRE(), mod_2, impl);
        eq = Mod.modEquation(mod_3);        
        (cache,dims,dae3) = elabArraydim(cache,env2, cref, t,ad, eq, impl, NONE,true) 
        "The variable declaration and the (optional) equation modification are inspected for array dimensions." ;
        /* Instantiate the component */
        (cache,compenv,ih,_,DAE.DAE(_,funcs),csets_1,ty,_) = instVar(cache, cenv, ih, UnitAbsyn.noStore,ci_state, mod_3, pre, csets, n, cl, attr, prot, dims, {}, {}, impl, NONE, io, finalPrefix, info, ConnectionGraph.EMPTY);
        /* The environment is extended with the new variable binding. */
        (cache,binding) = makeBinding(cache, env2, attr, mod_3, ty)  ;
        /* type info present */
        env_1 = Env.updateFrameV(env2, DAE.TYPES_VAR(n,DAE.ATTR(flowPrefix,streamPrefix,acc,param,dir,io),prot,ty,binding), Env.VAR_TYPED(), compenv);
        updatedComps = HashTable5.delete(cref,updatedComps);
        dae = DAEUtil.joinDaeLst({DAE.DAE({},funcs),dae1,dae2,dae3,dae4}); // Collect the functions, but not dae variable
      then
        (cache,env_1,ih,csets_1,updatedComps,dae);
/*   
    case (cache,env,ih,pre,mods,(cref as Absyn.CREF_IDENT(name = id,subscripts = subscr)),ci_state,csets,impl,updatedComps)
      equation
        print("\n Update comp env for: " +& id +& " FAILED \n");
        print(" Extern modifier: " +& Mod.printModStr(mods) +& " \n"); 
        (cache,_,SOME((SCode.COMPONENT(n,io,_,_,_,_,Absyn.TPATH(t, _),m,bc,_,_,_),cmod)),_) 
        	= Lookup.lookupIdent(cache,env, id);
        print(" ComponentModifier(class): " +& Mod.printModStr(cmod) +& " \n\n");
      then
        fail();
 */       
        /* Variable with NONE element is already instantiated. */ 
    case (cache,env,ih,pre,mods,(cref as Absyn.CREF_IDENT(name = id,subscripts = subscr)),ci_state,csets,impl,updatedComps) 
      local DAE.Var ty; Env.InstStatus is;
      equation 
        (cache,ty,_,is) = Lookup.lookupIdent(cache,env, id);
        true = Env.isTyped(is) "If InstStatus is typed, return";
      then
        (cache,env,ih,csets,updatedComps,DAEUtil.emptyDae);

        /* Nothing to update. */ 
    case (cache,env,ih,pre,mods,(cref as Absyn.CREF_QUAL(name = id)),ci_state,csets,impl,updatedComps) 
      equation 
        (cache,tyVar,_,is) = Lookup.lookupIdent(cache,env, id);
        true = Env.isTyped(is) "If InstStatus is typed, return";
      then
        (cache,env,ih,csets,updatedComps,DAEUtil.emptyDae);

        /* For qualified names, e.g. a.b.c, instanitate component a */
    case (cache,env,ih,pre,mods,(cref as Absyn.CREF_QUAL(name = id)),ci_state,csets,impl,updatedComps)
      local Option<Absyn.Info> info;    
      equation 
        (cache,tyVar,SOME((SCode.COMPONENT(n,io,finalPrefix,repl,prot,(attr as SCode.ATTR(ad,flowPrefix,streamPrefix,acc,param,dir)),Absyn.TPATH(t,_),m,_,comment,cond,info,cc),cmod)),_) 
        = Lookup.lookupIdent(cache,env, id);
        (cache,cl,cenv) = Lookup.lookupClass(cache,env, t, false);
        (mods,cmod,m) = noModForUpdatedComponents(updatedComps,cref,mods,cmod,m);
        crefs = getCrefFromMod(m);
        updatedComps = HashTable5.add((cref,0),updatedComps);
        (cache,env2_1,ih,csets,updatedComps,dae1) = updateComponentsInEnv2(cache, env, ih, pre, mods, crefs, ci_state, csets, impl, updatedComps);
        crefs2 = getCrefFromDim(ad);
        (cache,env2,ih,csets,updatedComps,dae2) = updateComponentsInEnv2(cache, env2_1, ih, pre, mods, crefs2, ci_state, csets, impl, updatedComps);
        /* Prefix does not matter, since we only update types in env, and does
	   	   not make any dae elements, etc.. 
         */
        ErrorExt.setCheckpoint();
        (cache,m_1,dae3) = Mod.elabMod(cache,env2, Prefix.NOPRE(), m, impl);
        ErrorExt.rollBack() "Rollback all error since we are only interested in type, not value at this point. Errors that occur in elabMod which does not fail the function will be accepted.";
        
        /* lookup and merge modifications */
        classmod = Mod.lookupModificationP(mods, t) ;
        mm = Mod.lookupCompModification(mods, n);
        mod = Mod.merge(classmod, mm, env2, Prefix.NOPRE());
        mod_1 = Mod.merge(mod, m_1, env2, Prefix.NOPRE());
        mod_2 = Mod.merge(cmod, mod_1, env2, Prefix.NOPRE());
        (cache,mod_3,dae4) = Mod.updateMod(cache,env2, Prefix.NOPRE(), mod_2, impl);
        eq = Mod.modEquation(mod_3);
        owncref = Absyn.CREF_IDENT(n,{})  ;

        /* The variable declaration and the (optional) equation modification are inspected for array dimensions.*/
        (cache,dims,dae4) = elabArraydim(cache,env2, owncref, t,ad, eq, impl, NONE,true);

        /* Instantiate the component */
        (cache,compenv,ih,_,DAE.DAE(_,funcs),csets_1,ty,_) = instVar(cache, cenv, ih, UnitAbsyn.noStore, ci_state, mod_3, pre, csets, n, cl, attr, prot, dims, {}, {}, false, NONE, io, finalPrefix, info, ConnectionGraph.EMPTY);

        /*The environment is extended with the new variable binding.*/
        (cache,binding) = makeBinding(cache,env2, attr, mod_3, ty);

        /* type info present */        
        env_1 = Env.updateFrameV(env2, 
          DAE.TYPES_VAR(n,DAE.ATTR(flowPrefix,streamPrefix,acc,param,dir,io),prot,ty,binding), Env.VAR_TYPED(), compenv);
        updatedComps = HashTable5.delete(cref,updatedComps);
        dae = DAEUtil.joinDaeLst({DAE.DAE({},funcs),dae1,dae2,dae3,dae4}); // Collect functions, but not dae variable
      then
        (cache,env_1,ih,csets_1,updatedComps,dae);
        
          /* If first part of ident is a class, e.g StateSelect.None, nothing to update*/
    case (cache,env,ih,pre,mods,(cref /*as Absyn.CREF_QUAL(name = id)*/),ci_state,csets,impl,updatedComps) 
      equation 
        id = Absyn.crefFirstIdent(cref);
        (cache,cl,cenv) = Lookup.lookupClass(cache,env, Absyn.IDENT(id), false);
      then
        (cache,env,ih,csets,updatedComps,DAEUtil.emptyDae);

    /* report an error! */
    case (cache,env,ih,pre,mod,cref,ci_state,csets,impl,updatedComps)
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
        (cache,env,ih,csets,updatedComps,DAEUtil.emptyDae);
  end matchcontinue;
end updateComponentInEnv;

protected function instDimExpLst 
"function: instDimExpLst 
  Instantiates dimension expressions, DimExp, which are transformed to DAE.Subscript\'s"
  input list<DimExp> inDimExpLst;
  input Boolean inBoolean;
  output list<DAE.Subscript> outExpSubscriptLst;
algorithm 
  outExpSubscriptLst := matchcontinue (inDimExpLst,inBoolean)
    local
      list<DAE.Subscript> res;
      DAE.Subscript r;
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

protected function instDimExp 
"function: instDimExp
  instantiates one dimension expression, See also instDimExpLst."
  input DimExp inDimExp;
  input Boolean inBoolean;
  output DAE.Subscript outSubscript;
algorithm 
  outSubscript := matchcontinue (inDimExp,inBoolean)
    local
      Boolean impl;
      String s;
      DAE.Exp e;
      Integer i;
      DAE.Subscript eSubscr;

    /* TODO: Fix slicing, e.g. DAE.SLICE, for impl=true */ 
    case (DIMEXP(subscript = DAE.WHOLEDIM()),(impl as false)) 
      equation 
        Error.addMessage(Error.DIMENSION_NOT_KNOWN, {":"});
      then
        fail();
    case (DIMEXP(subscript = DAE.SLICE(exp = e)),(impl as false))
      equation 
        s = Exp.printExpStr(e);
        Error.addMessage(Error.DIMENSION_NOT_KNOWN, {s});
      then
        fail();
    case (DIMEXP(subscript = (eSubscr as DAE.WHOLEDIM())),(impl as true)) then eSubscr;
    case (DIMINT(integer = i),_) then DAE.INDEX(DAE.ICONST(i)); 
    case (DIMEXP(subscript = (eSubscr as DAE.INDEX(exp = _))),_) then eSubscr;
  end matchcontinue;
end instDimExp;

protected function instWholeDimFromMod
	"Tries to determine the size of a WHOLEDIM dimension by looking at a variables
	modifier."
	input DimExp dimensionExp;
	input DAE.Mod modifier;
	output DAE.Subscript subscript;
algorithm
	subscript := matchcontinue(dimensionExp, modifier)
		local
			list<Option<Integer>> dims;
			DAE.Subscript sub;
		case (DIMEXP(subscript = DAE.WHOLEDIM()), DAE.NOMOD()) 
		  then fail(); // No modifier, which is ok if the variable has a binding.
		case (DIMEXP(subscript = DAE.WHOLEDIM()), 
					DAE.MOD(eqModOption =	SOME(DAE.TYPED(modifierAsExp = DAE.ARRAY(ty = DAE.ET_ARRAY(arrayDimensions = dims))))))
			equation
				(sub :: _) = Exp.arrayDimensionsToSubscripts(dims);
			then sub;
	end matchcontinue;
end instWholeDimFromMod;

protected function instDimType 
"function instDimType
  Retrieves the dimension expression as an integer option. 
  Non constant dimensions give NONE."
  input DimExp inDimExp;
  output Option<Integer> outIntegerOption;
algorithm 
  outIntegerOption := matchcontinue (inDimExp)
    local Integer i;
    case DIMINT(integer = i) then SOME(i); 
    case DIMEXP(subscript = _) then NONE; 
  end matchcontinue;
end instDimType;

protected function propagateAttributes 
"function: propagateAttributes 
  Updates the direction and inner/outer of a DAE element list.
  If a component has prefix input, all variables of the component 
  should be input.
  Similarly if a component has prefix output.
  If the component is bidirectional, the original direction is kept.
  Also, if a component has prefix inner, all variables of the component should be inner
  Similarly if a component has prefix outer.
  If the component has Unspecified inner/outer, the original InnerOuter is kept"
  input DAE.DAElist inDae;
  input Absyn.Direction inDirection;
  input Absyn.InnerOuter io;
  input SCode.Variability vt;
  output DAE.DAElist outDae;
  protected DAE.DAElist dae;
algorithm 
  outDae := propagateAllAttributes(inDae, inDirection, io, vt);
end propagateAttributes;

protected function propagateAllAttributes "Propagages ALL Attributes, to variables of a component."
  input DAE.DAElist inDae;
  input Absyn.Direction dir;
  input Absyn.InnerOuter io;
  input SCode.Variability vt;  
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue(inDae,dir,io,vt)
  local
    list<DAE.Element> elts;
    DAE.FunctionTree funcs;
    case(DAE.DAE(elts,funcs),dir,io,vt) equation
      elts = propagateAllAttributes2(elts,dir,io,vt);
      /* No need to go through funcs, they do not contain DAE variables*/
    then DAE.DAE(elts,funcs);
  end matchcontinue;
end propagateAllAttributes; 
 
protected function propagateAllAttributes2  
"Help function to propagateAllAttributes, goes through the element list"
  input list<DAE.Element> inDae;  
  input Absyn.Direction dir;
  input Absyn.InnerOuter io;
  input SCode.Variability vt;  
  output list<DAE.Element> outDae;
algorithm
  outDae := matchcontinue (inDae,dir,io,vt)
    local
      DAE.Element e;
      list<DAE.Element> rest, propagated;
    // empty case
    case ({},_,_,_) then {}; 
    // normal case
    case (e::rest,dir,io,vt)
      equation 
        {e} = propagateDirection({e},dir);
        {e} = propagateVariability({e},vt);
        {e} = propagateInnerOuter({e},io);
        propagated = propagateAllAttributes2(rest, dir, io, vt);
      then
        e::propagated;
  end matchcontinue;
end propagateAllAttributes2;

protected function propagateDirection 
"Help function to propagateAttributes, propagtes 
 the input/output attributes to variables of a component."
  input list<DAE.Element> inDae;
  input Absyn.Direction inDirection;
  output list<DAE.Element> outDae;
algorithm
  outDae := matchcontinue (inDae,inDirection)
    local
      list<DAE.Element> lst,r_1,r,lst_1;
      DAE.VarDirection dir_1;
      DAE.ComponentRef cr;
      DAE.VarKind vk;
      DAE.Type t;
      Option<DAE.Exp> e;
      list<DAE.Subscript> id;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      Absyn.Direction dir;
      String s1,s2;
      DAE.Element x;
      Absyn.InnerOuter io;
      DAE.VarProtection prot;
      String idName;
      DAE.ElementSource source "the origin of the element";

    /* Component that is bidirectional does not change direction on subcomponents */
    case (lst,Absyn.BIDIR()) then lst;   

    case ({},_) then {}; 
    /* Bidirectional variables are changed to input or output if component has such prefix. */
    case ((DAE.VAR(componentRef = cr,
                   kind = vk,
                   protection=prot,
                   direction = DAE.BIDIR(),
                   ty = t,
                   binding = e,
                   dims = id,
                   flowPrefix = flowPrefix,
                   streamPrefix = streamPrefix,
                   source = source,
                   variableAttributesOption = dae_var_attr,
                   absynCommentOption = comment,
                   innerOuter=io) :: r),dir)  
      equation 
        dir_1 = absynDirToDaeDir(dir);
        r_1 = propagateDirection(r, dir);
      then
        (DAE.VAR(cr,vk,dir_1,prot,t,e,id,flowPrefix,streamPrefix,source,dae_var_attr,comment,io) :: r_1);

   /* Error, component declared as input or output  when containing variable that has prefix input. */
    case ((DAE.VAR(componentRef = cr,
                   kind = vk,
                   protection=prot,
                   direction = DAE.INPUT(),
                   ty = t,
                   binding = e,
                   dims = id,
                   flowPrefix = flowPrefix,
                   streamPrefix = streamPrefix,
                   source = source,
                   variableAttributesOption = dae_var_attr,
                   absynCommentOption = comment,
                   innerOuter=io) :: r),dir)  
      equation 
        s1 = Dump.directionSymbol(dir);
        s2 = Exp.printComponentRefStr(cr);
        Error.addMessage(Error.COMPONENT_INPUT_OUTPUT_MISMATCH, {s1,s2});
      then
        fail();

   /* Error, component declared as input or output  when containing variable that has prefix output. */
    case ((DAE.VAR(componentRef = cr,
                   kind = vk,
                   direction = DAE.OUTPUT(),
                   ty = t,
                   binding = e,
                   dims = id,
                   flowPrefix = flowPrefix,
                   streamPrefix = streamPrefix,
                   source = source,
                   variableAttributesOption = dae_var_attr,
                   absynCommentOption = comment) :: r),dir)  
      equation 
        s1 = Dump.directionSymbol(dir);
        s2 = Exp.printComponentRefStr(cr);
        Error.addMessage(Error.COMPONENT_INPUT_OUTPUT_MISMATCH, {s1,s2});
      then
        fail();

    case ((DAE.COMP(ident = idName,dAElist = lst,source = source) :: r),dir)
      equation 
        lst_1 = propagateDirection(lst, dir);
        r_1 = propagateDirection(r, dir);
      then
        (DAE.COMP(idName,lst_1,source) :: r_1);
    case ((x :: r),dir)
      equation 
        r_1 = propagateDirection(r, dir);
      then
        (x :: r_1);
  end matchcontinue;
end propagateDirection;

protected function propagateVariability " help function to propagateAttributes, propagtes 
 the variability attribute (parameter or constant) to variables of a component."
  input list<DAE.Element> inDae;
  input SCode.Variability vt;
  output list<DAE.Element> outDae;
 algorithm
  outDae := matchcontinue (inDae,vt)
    local
      list<DAE.Element> lst,r_1,r,lst_1;
      DAE.Element v,x;
      DAE.VarDirection dir_1;
      DAE.ComponentRef cr;
      DAE.VarKind vk;
      DAE.Type t;
      Option<DAE.Exp> e;
      list<DAE.Subscript> id;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.VarDirection dir;
      String s1,s2;
      Absyn.InnerOuter io;
      DAE.VarProtection prot;
      DAE.ElementSource source "the origin of the element";
      
      /* Component that is VAR does not change variablity of subcomponents */ 
    case (lst,SCode.VAR()) then lst;  
      
    case ({},_) then {}; 
      
      /* the most restrictive variability is preserved (a const may not become PARAM) */
    case ((x as DAE.VAR(cr,DAE.CONST(),dir,prot,t,e,id,flowPrefix,streamPrefix,source,dae_var_attr,comment,io)) :: r,SCode.PARAM()) 
      equation
        r_1 = propagateVariability(r, vt);
      then
        x :: r_1;

      /* parameter */
    case ((DAE.VAR(cr,vk,dir,prot,t,e,id,flowPrefix,streamPrefix,source,dae_var_attr,comment,io) :: r),SCode.PARAM()) 
      equation 
        r_1 = propagateVariability(r, vt);
      then
        (DAE.VAR(cr,DAE.PARAM(),dir,prot,t,e,id,flowPrefix,streamPrefix,source,dae_var_attr,comment,io) :: r_1);

      /* constant */
    case ((DAE.VAR(cr,vk,dir,prot,t,e,id,flowPrefix,streamPrefix,source,dae_var_attr,comment,io) :: r),SCode.CONST()) 
      equation 
        r_1 = propagateVariability(r, vt);
      then
        (DAE.VAR(cr,DAE.CONST(),dir,prot,t,e,id,flowPrefix,streamPrefix,source,dae_var_attr,comment,io) :: r_1);


			/* Traverse components */
    case ((DAE.COMP(ident = id,dAElist = lst,source = source) :: r),vt)
      local String id;
      equation 
        lst_1 = propagateVariability(lst, vt);
        r_1 = propagateVariability(r, vt);
      then
        (DAE.COMP(id,lst_1,source) :: r_1);

    case ((x :: r),vt)
      equation 
        r_1 = propagateVariability(r, vt);
      then
        (x :: r_1);
  end matchcontinue;
end propagateVariability;

protected function propagateInnerOuter 
"function propagateInnerOuter 
  help function to propagateAttributes, propagtes the 
  inner/outer attributes to variables of a component."
  input list<DAE.Element> inDae;
  input Absyn.InnerOuter io;
   output list<DAE.Element> outDae;
 algorithm
  outDae := matchcontinue (inDae,io)
    local
      list<DAE.Element> lst,r_1,r,lst_1;
      DAE.Element v;
      DAE.VarDirection dir_1;
      DAE.ComponentRef cr;
      DAE.VarKind vk;
      DAE.Type t;
      Option<DAE.Exp> e;
      list<DAE.Subscript> id;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.VarDirection dir;
      String s1,s2;
      DAE.Element x;
      Absyn.InnerOuter io;
      DAE.VarProtection prot;
      String idName;
      DAE.ElementSource source "the origin of the element";

      /* Component that is unspecified does not change inner/outer on subcomponents */ 
    case (lst,Absyn.UNSPECIFIED()) then lst;  
      
    case ({},_) then {}; 
      
      /* unspecified variables are changed to inner/outer if component has such prefix. */ 
    case ((DAE.VAR(componentRef = cr,
                   kind = vk,
                   direction = dir,
                   protection=prot,
                   ty = t,
                   binding = e,
                   dims = id,
                   flowPrefix = flowPrefix,
                   streamPrefix = streamPrefix,
                   source = source,
                   variableAttributesOption = dae_var_attr,
                   absynCommentOption = comment,
                   innerOuter=Absyn.UNSPECIFIED()) :: r),io) 
      equation 
				false = ModUtil.isUnspecified(io);
        r_1 = propagateInnerOuter(r, io);
      then
        (DAE.VAR(cr,vk,dir,prot,t,e,id,flowPrefix,streamPrefix,source,dae_var_attr,comment,io) :: r_1);

			/* If var already have inner/outer, keep it. */
    case ( (v as DAE.VAR(componentRef = _)) :: r,io) 
      equation 
        r_1 = propagateInnerOuter(r, io);
      then
        v :: r_1;

			/* Traverse components */
    case ((DAE.COMP(ident = idName,dAElist = lst,source = source) :: r),io)
      equation 
        lst_1 = propagateInnerOuter(lst, io);
        r_1 = propagateInnerOuter(r, io);
      then
        (DAE.COMP(idName,lst_1,source) :: r_1);

    case ((x :: r),io)
      equation 
        r_1 = propagateInnerOuter(r, io);
      then
        (x :: r_1);
  end matchcontinue;
end propagateInnerOuter;

protected function absynDirToDaeDir 
"function: absynDirToDaeDir 
  Helper function to fix_direction. 
  Translates Absyn.Direction to DAE.VarDirection. 
  Needed so that input, output is transferred to DAE."
  input Absyn.Direction inDirection;
  output DAE.VarDirection outVarDirection;
algorithm 
  outVarDirection := matchcontinue (inDirection)
    case Absyn.INPUT() then DAE.INPUT(); 
    case Absyn.OUTPUT() then DAE.OUTPUT(); 
    case Absyn.BIDIR() then DAE.BIDIR(); 
  end matchcontinue;
end absynDirToDaeDir;

protected function instArray 
"function: instArray 
  When an array is instantiated by instVar, this function is used
  to go through all the array elements and instantiate each array
  element separately."
  input Env.Cache cache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input UnitAbsyn.InstStore store;
  input ClassInf.State inState;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input Ident inIdent;
  input tuple<SCode.Class, SCode.Attributes> inTplSCodeClassSCodeAttributes;
  input Boolean protection;
  input Integer inInteger;
  input DimExp inDimExp;
  input list<DimExp> inDimExpLst;
  input list<Integer> inIntegerLst;
  input InstDims inInstDims;
  input Boolean inBoolean;
  input Option<SCode.Comment> inAbsynCommentOption;
  input Absyn.InnerOuter io;
  input Boolean finalPrefix;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output DAE.Type outType;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outStore,outDae,outSets,outType,outGraph):=
  matchcontinue (cache,inEnv,inIH,store,inState,inMod,inPrefix,inSets,inIdent,inTplSCodeClassSCodeAttributes,protection,inInteger,inDimExp,inDimExpLst,inIntegerLst,inInstDims,inBoolean,inAbsynCommentOption,io,finalPrefix,inGraph)
    local
      DAE.Exp e,e_1;
      DAE.Properties p,p2;
      list<Env.Frame> env_1,env,compenv;
      Connect.Sets csets,csets_1,csets_2;
      tuple<DAE.TType, Option<Absyn.Path>> ty,arrty;
      ClassInf.State st,ci_state;
      DAE.ComponentRef cr;
      DAE.ExpType ty_1,arrty_1;
      DAE.Mod mod,mod_1;
      Prefix.Prefix pre;
      String n;
      SCode.Class cl;
      SCode.Attributes attr;
      Integer i,stop,i_1;
      list<DimExp> dims;
      list<Integer> idxs;
      InstDims inst_dims;
      Boolean impl,b;
      Option<SCode.Comment> comment;
      DAE.DAElist dae,dae1,dae2,dae3,daeLst;
      SCode.Initial eqn_place;
      Boolean prot;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      DAE.DAElist fdae;

    /* component environment If is a function var. */
    case (cache,env,ih,store,(ci_state as ClassInf.FUNCTION(path = _)),mod,pre,csets,n,(cl,attr),prot,i,DIMEXP(subscript = _),dims,idxs,inst_dims,impl,comment,io,_,graph) 
      equation 
        SOME(DAE.TYPED(e,_,p)) = Mod.modEquation(mod);
        (cache,env_1,ih,store,_,csets,ty,st,_,graph) = instClass(cache,env,ih,store, mod, pre, csets, cl, inst_dims, true, INNER_CALL(),graph) "Which has an expression binding";
        ty_1 = Types.elabType(ty);
        cr = PrefixUtil.prefixCref(pre,DAE.CREF_IDENT(n,ty_1,{})) "check their types";        
        (e_1,_) = Types.matchProp(e,p,DAE.PROP(ty,DAE.C_VAR()),true);
        
        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        dae = makeDaeEquation(DAE.CREF(cr,ty_1), e_1, source, SCode.NON_INITIAL());
      then
        (cache,env_1,ih,store,dae,csets,ty,graph);

    case (cache,env,ih,store,ci_state,mod,pre,csets,n,(cl,attr),prot,i,DIMEXP(subscript = _),dims,idxs,inst_dims,impl,comment,io,finalPrefix,graph)
      equation 
        (cache,compenv,ih,store,daeLst,csets,ty,graph) = 
          instVar2(cache, env, ih, store, ci_state, mod, pre, csets, n, cl, attr, prot, dims, (i :: idxs), inst_dims, impl, comment,io,finalPrefix,graph);
      then
        (cache,compenv,ih,store,daeLst,csets,ty,graph);

		/* Special case when instantiating Real[0]. We need to know the type */
    case (cache,env,ih,store,ci_state,mod,pre,csets,n,(cl,attr),prot,i,DIMINT(0),dims,idxs,inst_dims,impl,comment,io,finalPrefix,graph)
      equation 
        ErrorExt.setCheckpoint();
        (cache,compenv,ih,store,_,csets,ty,graph) = 
           instVar2(cache,env,ih,store, ci_state, mod, pre, csets, n, cl, attr,prot, dims, (0 :: idxs), inst_dims, impl, comment,io,finalPrefix,graph);
        ErrorExt.rollBack();
      then
        (cache,compenv,ih,store,DAEUtil.emptyDae,csets,ty,graph);

    case (cache,env,ih,store,ci_state,mod,pre,csets,n,(cl,attr),prot,i,DIMINT(integer = stop),dims,idxs,inst_dims,impl,comment,io,finalPrefix,graph)
      equation 
        (i > stop) = true;
      then
        (cache,env,ih,store,DAEUtil.emptyDae,csets,(DAE.T_NOTYPE(),NONE),graph);

    /* adrpo: if a class is derived WITH AN ARRAY DIMENSION we should instVar2 the derived from type not the actual type!!! */
    case (cache,env,ih,store,ci_state,mod,pre,csets,n,
          (cl as SCode.CLASS(classDef=SCode.DERIVED(typeSpec=Absyn.TPATH(path,SOME(_)),
                                                    modifications=scodeMod,attributes=absynAttr)),
                                                    attr),
          prot,i,DIMINT(integer = stop),dims,idxs,inst_dims,impl,comment,io,finalPrefix,graph)
      local SCode.Class clBase; Absyn.Path path;
            Absyn.ElementAttributes absynAttr;
            SCode.Mod scodeMod;            
            DAE.Mod mod2, mod3;
      equation                 
        (_,clBase,_) = Lookup.lookupClass(cache, env, path, true);
        /* adrpo: TODO: merge also the attributes, i.e.:
           type A = input discrete flow Integer[3];
           A x; <-- input discrete flow IS NOT propagated even if it should. FIXME!
         */
        //SOME(attr3) = Absyn.mergeElementAttributes(attr,SOME(absynAttr));
        (_,mod2,fdae) = Mod.elabMod(cache, env, pre, scodeMod, impl);
        mod3 = Mod.merge(mod, mod2, env, pre);
        mod_1 = Mod.lookupIdxModification(mod3, i);                            
        (cache,env_1,ih,store,dae1,csets_1,ty,graph) = 
           instVar2(cache,env,ih, store,ci_state, mod_1, pre, csets, n, clBase, attr, prot,dims, (i :: idxs), {} /* inst_dims */, impl, comment,io,finalPrefix,graph);
        i_1 = i + 1;
        (cache,_,ih,store,dae2,csets_2,_,graph) = 
          instArray(cache,env,ih,store, ci_state, mod, pre, csets_1, n, (cl,attr), prot, i_1, DIMINT(stop), dims, idxs, {} /* inst_dims */, impl, comment,io,finalPrefix,graph);
        daeLst = DAEUtil.joinDaeLst({dae1, dae2,fdae});        
      then
        (cache,env_1,ih,store,daeLst,csets_2,ty,graph);
        
    case (cache,env,ih,store,ci_state,mod,pre,csets,n,(cl,attr),prot,i,DIMINT(integer = stop),dims,idxs,inst_dims,impl,comment,io,finalPrefix,graph)
      equation 
        mod_1 = Mod.lookupIdxModification(mod, i);
        (cache,env_1,ih,store,dae1,csets_1,ty,graph) = 
           instVar2(cache,env,ih, store,ci_state, mod_1, pre, csets, n, cl, attr, prot,dims, (i :: idxs), inst_dims, impl, comment,io,finalPrefix,graph);
        i_1 = i + 1;
        (cache,_,ih,store,dae2,csets_2,_,graph) = 
          instArray(cache,env,ih,store, ci_state, mod, pre, csets_1, n, (cl,attr), prot, i_1, DIMINT(stop), dims, idxs, inst_dims, impl, comment,io,finalPrefix,graph);
        daeLst = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache,env_1,ih,store,daeLst,csets_2,ty,graph);
        
    case (_,_,ih,_,_,_,_,_,n,(_,_),_,_,_,_,_,_,_,_,_,_,_)
      equation 
				true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- Inst.instArray failed: " +& n);
      then
        fail();
  end matchcontinue;
end instArray;

protected function attrIsParam 
"function: attrIsParam 
  Returns true if attributes contain PARAM"
  input SCode.Attributes inAttributes;
  output Boolean outBoolean;
algorithm 
  outBoolean := matchcontinue (inAttributes)
    case SCode.ATTR(variability = SCode.PARAM()) then true;
    case _ then false; 
  end matchcontinue;
end attrIsParam;

public function elabComponentArraydimFromEnv 
"function elabComponentArraydimFromEnv
  author: PA
  Lookup uninstantiated component in env, elaborate its modifiers to
  find arraydimensions and return as DimExp list.
  Used when components have submodifiers (on e.g. attributes) using 
  size to find dimensions of component."
	input Env.Cache inCache;
  input Env inEnv;
  input DAE.ComponentRef inComponentRef;
  output Env.Cache outCache;
  output list<DimExp> outDimExpLst;
  output DAE.DAElist outDae "contain functions";
algorithm 
  (outCache,outDimExpLst,outDae) := matchcontinue (inCache,inEnv,inComponentRef)
    local
      DAE.Var ty;
      String n,id;
      Boolean finalPrefix,repl,prot,flowPrefix,streamPrefix;
      Absyn.InnerOuter io;
      SCode.Attributes attr;
      list<Absyn.Subscript> ad;
      SCode.Accessibility acc;
      SCode.Variability param;
      Absyn.Direction dir;
      SCode.Mod m,m_1;
      SCode.OptBaseClass bc;
      Option<SCode.Comment> comment;
      DAE.Mod cmod,cmod_1,m_2,mod_2;
      DAE.EqMod eq;
      list<DimExp> dims;
      list<Env.Frame> env;
      DAE.ComponentRef cref;
      Env.Cache cache;
      DAE.DAElist fdae;
      
    case (cache,env,(cref as DAE.CREF_IDENT(ident = id)))
      equation 
        (cache,ty,SOME((SCode.COMPONENT(n,io,finalPrefix,repl,prot,(attr as SCode.ATTR(ad,flowPrefix,streamPrefix,acc,param,dir)),_,m,bc,comment,_,_,_),cmod)),_) 
        	= Lookup.lookupIdent(cache,env, id);
        cmod_1 = Types.stripSubmod(cmod);
        m_1 = SCode.stripSubmod(m);
        (cache,m_2,fdae) = Mod.elabMod(cache,env, Prefix.NOPRE(), m_1, false);
        mod_2 = Mod.merge(cmod_1, m_2, env, Prefix.NOPRE());
        SOME(eq) = Mod.modEquation(mod_2);
        (cache,dims) = elabComponentArraydimFromEnv2(cache,eq, env);
      then
        (cache,dims,fdae);
  end matchcontinue;
end elabComponentArraydimFromEnv;

protected function elabComponentArraydimFromEnv2 
"function: elabComponentArraydimFromEnv2 
  author: PA
  Helper function to elabComponentArraydimFromEnv. 
  This function is similar to elabArraydim, but it will only 
  investigate binding (DAE.EqMod) and not the component declaration."
	input Env.Cache inCache;
  input DAE.EqMod inEqMod;
  input Env inEnv;
  output Env.Cache outCache;
  output list<DimExp> outDimExpLst;
algorithm 
  (outCache,outDimExpLst) := matchcontinue (inCache,inEqMod,inEnv)
    local
      list<Integer> lst;
      list<DimExp> lst_1;
      DAE.Exp e;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      list<Env.Frame> env;
      Env.Cache cache;
    case (cache,DAE.TYPED(modifierAsExp = e,properties = DAE.PROP(type_ = t)),env)
      equation 
        lst = Types.getDimensionSizes(t);
        lst_1 = Util.listMap(lst, makeDimexpFromInt);
      then
        (cache,lst_1);
  end matchcontinue;
end elabComponentArraydimFromEnv2;

protected function makeDimexpFromInt 
"function: makeDimexpFromInt 
  Helper function to elabComponentArraydfumFromEnv2"
  input Integer inInteger;
  output DimExp outDimExp;
algorithm 
  outDimExp := matchcontinue (inInteger)
    local Integer i;
    case (i) then DIMINT(i); 
  end matchcontinue;
end makeDimexpFromInt;

protected function elabArraydimOpt 
"function: elabArraydimOpt 
  Same functionality as elabArraydim, but takes an optional arraydim.
  In case of NONE, empty DimExp list is returned."
	input Env.Cache inCache;
  input Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Path path "Class of declaration";
  input Option<Absyn.ArrayDim> inAbsynArrayDimOption;
  input Option<DAE.EqMod> inTypesEqModOption;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  output Env.Cache outCache;
  output list<DimExp> outDimExpLst;
  output DAE.DAElist outDae "contain functions";
algorithm 
  (outCache,outDimExpLst,outDae) :=
  matchcontinue (inCache,inEnv,inComponentRef,path,inAbsynArrayDimOption,inTypesEqModOption,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization)
    local
      list<DimExp> res;
      list<Env.Frame> env;
      Absyn.ComponentRef owncref;
      list<Absyn.Subscript> ad;
      Option<DAE.EqMod> eq;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
      Boolean doVect;
      DAE.DAElist dae;
    case (cache,env,owncref,path,SOME(ad),eq,impl,st,doVect)  
      equation 
        (cache,res,dae) = elabArraydim(cache,env, owncref, path,ad, eq, impl, st,doVect);
      then
        (cache,res,dae);
    case (cache,env,owncref,path,NONE,eq,impl,st,doVect) then (cache,{},DAEUtil.emptyDae); 
  end matchcontinue;
end elabArraydimOpt;

protected function elabArraydim 
"function: elabArraydim
  This functions examines both an `Absyn.ArrayDim\' and an `DAE.EqMod
  option\' argument to find out the dimensions af a component.  If
  no equation modifications is given, only the declared dimension is
  used.
 
  When the size of a dimension in the type is undefined, the
  corresponding size in the type of the modification is used.
 
  All this is accomplished by examining the two arguments separately
  and then using `complete_arraydime\' or `compatible_arraydim\' to
  check that that the dimension sizes are compatible and complete."
	input Env.Cache inCache;
  input Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Path path "Class of declaration";
  input Absyn.ArrayDim inArrayDim;
  input Option<DAE.EqMod> inTypesEqModOption;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  output Env.Cache outCache;
  output list<DimExp> outDimExpLst;
  output DAE.DAElist outDae "contain functions";
algorithm 
  (outCache,outDimExpLst,outDae) :=
  matchcontinue (inCache,inEnv,inComponentRef,path,inArrayDim,inTypesEqModOption,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization)
    local
      list<Option<DimExp>> dim,dim1,dim2;
      list<DimExp> dim_1,dim3;
      list<Env.Frame> env;
      Absyn.ComponentRef cref;
      list<Absyn.Subscript> ad;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      DAE.Exp e,e_1;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      String e_str,t_str,dim_str;
      Env.Cache cache;
      Boolean doVect;
      DAE.Properties prop;
      DAE.DAElist dae,dae1,dae2;
      
    case (cache,env,cref,path,ad,NONE,impl,st,doVect) /* impl */ 
      equation 
        (cache,dim,dae) = elabArraydimDecl(cache,env, cref, ad, impl, st,doVect);
        dim_1 = completeArraydim(dim);
      then
        (cache,dim_1,dae);
    case (cache,env,cref,path,ad,SOME(DAE.TYPED(e,_,prop)),impl,st,doVect) /* Untyped expressions must be elaborated. */ 
      equation
        t = Types.getPropType(prop);
        (cache,dim1,dae) = elabArraydimDecl(cache,env, cref, ad, impl, st,doVect);
        dim2 = elabArraydimType(t, ad,e,path);
        dim3 = compatibleArraydim(dim1, dim2);
      then
        (cache,dim3,dae);
    case (cache,env,cref,path,ad,SOME(DAE.UNTYPED(e)),impl,st,doVect)
      local Absyn.Exp e;
      equation 
        (cache,e_1,prop,_,dae1) = Static.elabExp(cache,env, e, impl, st,doVect);
        t = Types.getPropType(prop);
        (cache,dim1,dae2) = elabArraydimDecl(cache,env, cref, ad, impl, st,doVect);
        dim2 = elabArraydimType(t, ad,e_1,path);
        dim3 = compatibleArraydim(dim1, dim2);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,dim3,dae);
    case (cache,env,cref,path,ad,SOME(DAE.TYPED(e,_,DAE.PROP(t,_))),impl,st,doVect)
      equation 
        (cache,dim1,_) = elabArraydimDecl(cache,env, cref, ad, impl, st,doVect);
        dim2 = elabArraydimType(t, ad,e,path);
        failure(dim3 = compatibleArraydim(dim1, dim2));
        e_str = Exp.printExpStr(e);
        t_str = Types.unparseType(t);
        dim_str = printDimStr(dim1);
        Error.addMessage(Error.ARRAY_DIMENSION_MISMATCH, {e_str,t_str,dim_str});
      then
        fail();
    // print some failures 
    case (_,_,cref,path,ad,eq,_,_,_)
      local Option<DAE.EqMod> eq;
      equation 
        // only display when the failtrace flag is on
        true = RTOpts.debugFlag("failtrace");
        Debug.trace("- Inst.elabArraydim failed on: \n\tcref:");
        Debug.trace(Absyn.pathString(path) +& " " +& Dump.printComponentRefStr(cref));
        Debug.traceln(Dump.printArraydimStr(ad) +& " = " +& Types.unparseOptionEqMod(eq));
      then
        fail();
  end matchcontinue;
end elabArraydim;

protected function printDimStr 
"function: printDimStr
  This function prints array dimensions.  
  The code is not included in the report."
  input list<Option<DimExp>> inDimExpOptionLst;
  output String outString;
algorithm 
  outString := matchcontinue (inDimExpOptionLst)
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
      local DAE.Subscript x;
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
      local DAE.Subscript x;
      equation 
        s1 = Exp.printSubscriptStr(x);
        s2 = printDimStr(xs);
        res = Util.stringAppendList({s1,",",s2});
      then
        res;
    case (_) then ""; 
  end matchcontinue;
end printDimStr;

protected function elabArraydimDecl 
"function: elabArraydimDecl
  Given an Absyn.ArrayDim, this function evaluates all dimension
  size specifications, creating a list of (optional) integers.  
  When the array dimension size is specified as :, the result 
  will contain NONE."
	input Env.Cache inCache;
  input Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.ArrayDim inArrayDim;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  output Env.Cache outCache;
  output list<Option<DimExp>> outDimExpOptionLst;
  output DAE.DAElist outDae "contain functions";
algorithm 
  (outCache,outDimExpOptionLst,outDae) :=
  matchcontinue (inCache,inEnv,inComponentRef,inArrayDim,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization)
    local
      list<Option<DimExp>> l;
      list<Env.Frame> env;
      Absyn.ComponentRef cref,cr;
      list<Absyn.Subscript> ds;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      DAE.Exp e;
      DAE.Const cnst;
      Integer i;
      Absyn.Exp d;
      String str,e_str,t_str;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      Env.Cache cache;
      Boolean doVect;
      DAE.DAElist dae,dae1,dae2;
      
    // empty case
    case (cache,_,_,{},_,_,_) then (cache,{},DAEUtil.emptyDae);
    // no subs 
    case (cache,env,cref,(Absyn.NOSUB() :: ds),impl,st,doVect)
      equation 
        (cache,l,dae) = elabArraydimDecl(cache,env, cref, ds, impl, st,doVect);
      then
        (cache,NONE :: l,dae);
    // For functions, this can occur: Real x{:,size(x,1)} ,i.e. refering to  the variable itself but a different dimension.
    case (cache,env,cref,(Absyn.SUBSCRIPT(subScript = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "size"),
          functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentRef = cr),_}))) :: ds),impl,st,doVect)
      equation 
        true = Absyn.crefEqual(cref, cr);
        (cache,l,dae) = elabArraydimDecl(cache,env, cref, ds, impl, st,doVect);
      then
        (cache,NONE :: l,dae);
    // adrpo: See if our array dimension comes from an enumeration! 
    case (cache,env,cref,(Absyn.SUBSCRIPT(subScript = Absyn.CREF(cr)) :: ds),impl,st,doVect)
      local Absyn.ComponentRef cr; Absyn.Path typePath; list<SCode.Element> elementLst;
      equation 
        typePath = Absyn.crefToPath(cr);
        // make sure is an enumeration! 
        (_, SCode.CLASS(restriction=SCode.R_ENUMERATION(),classDef=SCode.PARTS(elementLst=elementLst)), _) = 
             Lookup.lookupClass(cache, env, typePath, false);
        i = listLength(elementLst);
        (cache,l,dae) = elabArraydimDecl(cache,env, cref, ds, impl, st,doVect);
      then
        (cache,SOME(DIMINT(i)) :: l,dae);
    // Frenkel TUD try next enum
    case (cache,env,cref,(Absyn.SUBSCRIPT(subScript = Absyn.CREF(cr)) :: ds),impl,st,doVect)
      local Absyn.ComponentRef cr; Absyn.Path typePath; list<SCode.Enum> enumLst;
      equation 
        typePath = Absyn.crefToPath(cr);
        // make sure is an enumeration! 
        (_, SCode.CLASS(restriction=SCode.R_TYPE(),classDef=SCode.ENUMERATION(enumLst=enumLst)), _) = 
             Lookup.lookupClass(cache, env, typePath, false);
        i = listLength(enumLst);
        (cache,l,dae) = elabArraydimDecl(cache,env, cref, ds, impl, st,doVect);
      then
        (cache,SOME(DIMINT(i)) :: l,dae);
    // Constant dimension creates DIMINT 
    case (cache,env,cref,(Absyn.SUBSCRIPT(subScript = d) :: ds),impl,st,doVect) 
      equation 
        //Debug.fprintln("insttr", "elab_arraydim_decl5");
        (cache,e,DAE.PROP((DAE.T_INTEGER(_),_),cnst),_,dae1) = Static.elabExp(cache,env, d, impl, st,doVect);
        failure(equality(cnst = DAE.C_VAR()));
        (cache,Values.INTEGER(i),_) = Ceval.ceval(cache,env, e, impl, st, NONE, Ceval.NO_MSG());
        (cache,l,dae2) = elabArraydimDecl(cache,env, cref, ds, impl, st,doVect);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,SOME(DIMINT(i)) :: l,dae);
    
    // when not implicit instantiation, array dim. must be constant.
    case (cache,env,cref,(Absyn.SUBSCRIPT(subScript = d) :: ds),(impl as false),st,doVect)  
      equation 
        //Debug.fprintln("insttr", "elab_arraydim_decl5");
        (cache,e,DAE.PROP((DAE.T_INTEGER(_),_),DAE.C_VAR()),_,_) = Static.elabExp(cache,env, d, impl, st,doVect);
        str = Dump.printExpStr(d);
        Error.addMessage(Error.DIMENSION_NOT_KNOWN, {str});
      then
        fail();
    // Non-constant dimension creates DIMEXP 
    case (cache,env,cref,(Absyn.SUBSCRIPT(subScript = d) :: ds),(impl as true),st,doVect)
      equation 
        // Debug.fprintln("insttr", "elab_arraydim_decl6");
        (cache,e,DAE.PROP((DAE.T_INTEGER(_),_),cnst),_,dae1) = Static.elabExp(cache,env, d, impl, st,doVect);
        (cache,l,dae2) = elabArraydimDecl(cache,env, cref, ds, impl, st,doVect);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,SOME(DIMEXP(DAE.INDEX(e),NONE))::l, dae);
    /* Size(x,1) in e.g. functions => Unknown dimension */
    case (cache,env,cref,(Absyn.SUBSCRIPT(subScript = d) :: ds),impl,st,doVect)
      equation 
        (cache,(e as DAE.SIZE(_,_)),DAE.PROP(t,_),_,dae1) = Static.elabExp(cache,env, d, impl, st,doVect);
        (cache,l,dae2) = elabArraydimDecl(cache,env, cref, ds, impl, st,doVect);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,SOME(DIMEXP(DAE.INDEX(e),NONE)) :: l,dae);
    case (cache,env,cref,(Absyn.SUBSCRIPT(subScript = d) :: ds),impl,st,doVect)
      equation 
        (cache,e,DAE.PROP(t,_),_,_) = Static.elabExp(cache,env, d, impl, st,doVect);
        e_str = Exp.printExpStr(e);
        t_str = Types.unparseType(t);
        Error.addMessage(Error.ARRAY_DIMENSION_INTEGER, {e_str,t_str});
      then
        fail();
    case (_,_,cref,ds,_,_,_)
      equation 
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- Inst.elabArraydimDecl failed on: " +& 
          Absyn.printComponentRefStr(cref) +& Dump.printArraydimStr(ds));
      then
        fail();
  end matchcontinue;
end elabArraydimDecl;

protected function completeArraydim 
"function: completeArraydim
  This function converts a list of optional integers to a list of integers.
  If one element of the list is NONE, this function will fail.
  This is used to check that an array specification contain fully specified array dimension sizes."
  input list<Option<DimExp>> inDimExpOptionLst;
  output list<DimExp> outDimExpLst;
algorithm 
  outDimExpLst := matchcontinue (inDimExpOptionLst)
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
        (DIMEXP(DAE.WHOLEDIM(),NONE) :: xs_1);
  end matchcontinue;
end completeArraydim;

protected function compatibleArraydim 
"function: compatibleArraydim
  Given two, possibly incomplete, array dimension size specifications 
  as list of optional integers, this function checks whether they are compatible. 
  Being compatible means that they have the same number of dimension, 
  and for every dimension at least one of the lists specifies its size.  
  If both lists specify a dimension size, they have to specify the same size."
  input list<Option<DimExp>> inDimExpOptionLst1;
  input list<Option<DimExp>> inDimExpOptionLst2;
  output list<DimExp> outDimExpLst;
algorithm 
  outDimExpLst := matchcontinue (inDimExpOptionLst1,inDimExpOptionLst2)
    local
      list<DimExp> l;
      DimExp x,y,de;
      list<Option<DimExp>> xs,ys;
      Option<DAE.Exp> e,e1,e2;
      Integer xI,yI;
      DAE.Subscript yS,xS;
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
    case ((SOME(DIMINT(xI)) :: xs),(SOME(DIMINT(yI)) :: ys))
      equation 
        equality(xI = yI);
        l = compatibleArraydim(xs, ys);
      then
        (DIMINT(xI) :: l);
    case ((SOME(DIMINT(xI)) :: xs),(SOME(DIMEXP(yS,e)) :: ys))
      equation 
        de = arraydimCondition(DIMEXP(DAE.INDEX(DAE.ICONST(xI)),NONE), DIMEXP(yS,e));
        l = compatibleArraydim(xs, ys);
      then
        (de :: l);
    case ((SOME(DIMEXP(xS,e)) :: xs),(SOME(DIMINT(yI)) :: ys))
      equation 
        de = arraydimCondition(DIMEXP(DAE.INDEX(DAE.ICONST(yI)),NONE), DIMEXP(xS,e));
        l = compatibleArraydim(xs, ys);
      then
        (de :: l);
    case ((SOME(DIMEXP(xS,e1)) :: xs),(SOME(DIMEXP(yS,e2)) :: ys))
      equation 
        de = arraydimCondition(DIMEXP(xS,e1), DIMEXP(yS,e2));
        l = compatibleArraydim(xs, ys);
      then
        (de :: l);
    case ((NONE :: xs),(NONE :: ys))
      equation 
        l = compatibleArraydim(xs, ys);
      then
        (DIMEXP(DAE.WHOLEDIM(),NONE) :: l);
    case (_,_)
      equation 
        Debug.fprintln("failtrace", "- Inst.compatibleArraydim failed");
      then
        fail();
  end matchcontinue;
end compatibleArraydim;

protected function arraydimCondition 
"function arraydimCondition  
  This function checks that the two arraydim expressions have the same dimension.
  FIXME: no check performed yet, just return first DimExp."
  input DimExp inDimExp1;
  input DimExp inDimExp2;
  output DimExp outDimExp;
algorithm 
  outDimExp := matchcontinue (inDimExp1,inDimExp2)
    local DimExp de;
    case (de,_) then de; 
  end matchcontinue;
end arraydimCondition;

protected function elabArraydimType 
"function: elabArraydimType 
  Find out the dimension sizes of a type. The second argument is
  used to know how many dimensions should be extracted from the
  type."
  input DAE.Type inType;
  input Absyn.ArrayDim inArrayDim;
  input DAE.Exp exp "Primarily used for error messages";
  input Absyn.Path path "class of declaration, primarily used for error messages";
  output list<Option<DimExp>> outDimExpOptionLst;
algorithm
  outDimExpOptionLst := matchcontinue(inType,inArrayDim,exp,path)
    local
      list<Option<DimExp>> l;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      list<Absyn.Subscript> ad;
      Integer i;
      String tpStr,adStr,expStr;
    case(t,ad,exp,path) 
      equation
        true = (Types.ndims(t) >= listLength(ad));
        outDimExpOptionLst = elabArraydimType2(t,ad);
      then outDimExpOptionLst;
 
    case(t,ad,exp,path) 
      equation
        adStr = Absyn.pathString(path) +& Dump.printArraydimStr(ad);
        tpStr = Types.unparseType(t);
        expStr = Exp.printExpStr(exp);
        Error.addMessage(Error.MODIFIER_DECLARATION_TYPE_MISMATCH_ERROR,{adStr,expStr,tpStr});
      then fail(); 
    end matchcontinue;
end  elabArraydimType; 

protected function elabArraydimType2 
"Help function to elabArraydimType."
  input DAE.Type inType;
  input Absyn.ArrayDim inArrayDim;
  output list<Option<DimExp>> outDimExpOptionLst;
algorithm 
  outDimExpOptionLst := matchcontinue (inType,inArrayDim)
    local
      list<Option<DimExp>> l;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      list<Absyn.Subscript> ad;
      Integer i;
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM(integerOption = NONE),arrayType = t),_),(_ :: ad))
      equation 
        l = elabArraydimType2(t, ad);
      then
        (NONE :: l);
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM(integerOption = SOME(i)),arrayType = t),_),(_ :: ad))
      equation 
        l = elabArraydimType2(t, ad);
      then
        (SOME(DIMINT(i)) :: l);
    /*
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM(integerOption = NONE),arrayType = t),_),{})
      then
        (NONE :: {});
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM(integerOption = SOME(i)),arrayType = t),_),{})
      then
        (SOME(DIMINT(i)) :: {});
    */        
    case (_,{}) then {};
    /* adrpo: handle also complex type!  
    case ((DAE.T_COMPLEX(complexTypeOption=SOME(t)),_),ad)
      equation 
        l = elabArraydimType2(t, ad);
      then
        l; */     
    case (t,(_ :: ad)) /* PR, for debugging */ 
      equation 
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "Undefined!");
        Debug.fprint("failtrace", " The type detected: ");
        Debug.fprint("failtrace", Types.printTypeStr(t));
      then
        fail();
  end matchcontinue;
end elabArraydimType2;

public function instClassDecl 
"function: instClassDecl 
  The class definition is instantiated although no variable is declared with it.  
  After instantiating it, it is checked to see if it can be used as a package, 
  and if it can, then it is added as a variable under the same name as the class.  
  This makes it possible to use a unified lookup mechanism.  
  And since packages only can contain constants and class definition, instantiating 
  a package does not do anything else."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input SCode.Class inClass;
  input InstDims inInstDims;
	output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
algorithm 
  (outCache,outEnv,outIH,outDae) := matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inClass,inInstDims)
    local
      list<Env.Frame> env_1,env_2,env;
      DAE.DAElist dae;
      DAE.Mod mod;
      Prefix.Prefix pre;
      Connect.Sets csets;
      SCode.Class c;
      String n,s;
      SCode.Restriction restr;
      InstDims inst_dims;
      Env.Cache cache;
      InstanceHierarchy ih;
      
    case (cache,env,ih,mod,pre,csets,(c as SCode.CLASS(name = n,restriction = restr)),inst_dims)  
      equation 
        env_1 = Env.extendFrameC(env, c);
        (cache,env_2,ih,dae) = implicitInstantiation(cache,env_1,ih, DAE.NOMOD(), pre, csets, c, inst_dims);
      then
        (cache,env_2,ih,dae);
    case (cache,env,ih,_,_,_,_,_)
      equation 
        Debug.fprint("failtrace", "- Inst.instClassDecl failed\n");
      then
        fail();
  end matchcontinue;
end instClassDecl;

public function implicitInstantiation 
"function implicitInstantiation 
  This function adds types to the environment.
  If a class definition is a function or a package or an enumeration , 
  it is implicitly instantiated and added as a type binding under the
  same name as the class name."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input SCode.Class inClass;
  input InstDims inInstDims;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
algorithm 
  (outCache,outEnv,outIH,outDAEElementLst) := matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inClass,inInstDims)
    local
      DAE.DAElist dae;
      Connect.Sets csets_1,csets;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      ClassInf.State st;
      list<Env.Frame> env_1,env,tempenv,env_2;
      Absyn.Path fpath;
      DAE.Mod mod;
      Prefix.Prefix pre;
      SCode.Class c,enumclass;
      String n;
      InstDims inst_dims;
      Boolean prot;
      DAE.ExternalDecl extdecl;
      SCode.Restriction restr;
      SCode.ClassDef parts;
      list<SCode.Element> els;
      list<SCode.Enum> l;
      Env.Cache cache;
      InstanceHierarchy ih;
      Option<SCode.Comment> cmt;
      Absyn.Info info;

     /* enumerations */
     case (cache,env,ih,mod,pre,csets,
           (c as SCode.CLASS(name = n,restriction = SCode.R_TYPE(),
                             classDef = SCode.ENUMERATION(enumLst=l, comment=cmt),info = info)),inst_dims)  
      equation 
        enumclass = instEnumeration(n, l, cmt, info);
        env_2 = Env.extendFrameC(env, enumclass); 
      then
        (cache,env_2,ih,DAEUtil.emptyDae);

    /* .. the rest will fall trough */
    case (cache,env,ih,mod,pre,csets,c,_) then (cache,env,ih,DAEUtil.emptyDae);
  end matchcontinue;
end implicitInstantiation;

public function makeFullyQualified 
"function: makeFullyQualified
  author: PA
  Transforms a class name to its fully qualified name by investigating the environment.
  For instance, the model Resistor in Modelica.Electrical.Analog.Basic will given the 
  correct environment have the fully qualified name: Modelica.Electrical.Analog.Basic.Resistor"
	input Env.Cache inCache;
  input Env inEnv;
  input Absyn.Path inPath;
  output Env.Cache outCache;
  output Absyn.Path outPath;
algorithm 
  (outCache,outPath) := matchcontinue (inCache,inEnv,inPath)
    local
      list<Env.Frame> env,env_1;
      Absyn.Path path,path_1,path_2;
      String class_name,s;
      Env.Cache cache;
      SCode.Class cl;

      /*Special cases: assert and reinit can not be handled by builtin.mo, since they do not have return type */
    case(cache,env,path as Absyn.IDENT("assert")) then (cache,path); 
    case(cache,env,path as Absyn.IDENT("reinit")) then (cache,path);
      
      /* Other functions that can not be represented in env due to e.g. applicable to any record */
    case(cache,env,path as Absyn.IDENT("smooth")) then (cache,path);

    /* MetaModelica extension */
    case (cache,_,path as Absyn.IDENT("list")) equation true=RTOpts.acceptMetaModelicaGrammar(); then (cache,path);
    case (cache,_,path as Absyn.IDENT("Option")) equation true=RTOpts.acceptMetaModelicaGrammar(); then (cache,path);
    case (cache,_,path as Absyn.IDENT("tuple")) equation true=RTOpts.acceptMetaModelicaGrammar(); then (cache,path);
    case (cache,_,path as Absyn.IDENT("polymorphic")) equation true=RTOpts.acceptMetaModelicaGrammar(); then (cache,path);
    case (cache,_,path as Absyn.IDENT("array")) equation true=RTOpts.acceptMetaModelicaGrammar(); then (cache,path);
    /*-------------------------*/    
                     
    /* To make a class fully qualified, the class path is looked up in the environment.
	 * The FQ path consist of the simple class name
	 * appended to the environment path of the looked up class.
	 */ 
    case (cache,env,path) 
      equation 
         (cache,cl,env_1) = Lookup.lookupClass(cache,env, path, false);
         path_2 = makeFullyQualified2(env_1,SCode.className(cl));
      then
        (cache,Absyn.FULLYQUALIFIED(path_2)); 
    
    /* A type can exist without a class (i.e. builtin functions) */  
    case (cache,env,Absyn.IDENT(s)) 
      equation 
         (cache,_,env_1) = Lookup.lookupType(cache,env, Absyn.IDENT(s), false);
         path_2 = makeFullyQualified2(env_1,s);  
      then
        (cache,Absyn.FULLYQUALIFIED(path_2));
        
     /* A package constant */
    case (cache,(f::fs) ,path) // First try to look it up local(top frame)
      local Absyn.Path path3; DAE.ComponentRef crPath;
        Env.Frame f;
        Env.Env fs;        
      equation 
        crPath = Exp.pathToCref(path);
        (cache,_,_,_,_) = Lookup.lookupVarInternal(cache,{f}, crPath);
        path3 = makeFullyQualified2({},Absyn.pathLastIdent(path));
      then
        (cache,Absyn.FULLYQUALIFIED(path3));
        
    case (cache,env,path) 
      local String s; SCode.Class cl; Absyn.Path path3; DAE.ComponentRef crPath;        
      equation 
          crPath = Exp.pathToCref(path); 
         (cache,env,_,_,_) = Lookup.lookupVarInPackages(cache,env, crPath);
          path3 = makeFullyQualified2(env,Absyn.pathLastIdent(path));
      then
        (cache,Absyn.FULLYQUALIFIED(path3));    
                
    case (cache,env,path) equation
      /*print(Absyn.pathString(path));print(" failed to make FQ in env:");
      print("\n");
      print(Env.printEnvPathStr(env));
      print("\n");
     
      print(Env.printEnvStr(env));*/
      then (cache,path);  /* If it fails, leave name unchanged. */ 
  end matchcontinue;
end makeFullyQualified;

public function implicitFunctionInstantiation 
"function: implicitFunctionInstantiation 
  This function instantiates a function, which is performed *implicitly*
  since the variables of a function should not be instantiated as for an 
  ordinary class."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input SCode.Class inClass;
  input InstDims inInstDims;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
algorithm 
  (outCache,outEnv,outIH,outDae):= matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inClass,inInstDims)
    local
      DAE.DAElist dae,daefuncs,dae1;
      Connect.Sets csets_1,csets;
      tuple<DAE.TType, Option<Absyn.Path>> ty,ty1;
      ClassInf.State st;
      list<Env.Frame> env_1,env,tempenv,cenv,env_11;
      Absyn.Path fpath;
      DAE.Mod mod;
      Prefix.Prefix pre;
      SCode.Class c;
      String n, s;
      InstDims inst_dims;
      Boolean prot,partialPrefix,ep;
      DAE.ExternalDecl extdecl;
      SCode.Restriction restr;
      SCode.ClassDef parts;
      list<SCode.Element> els;
      list<Absyn.Path> funcnames;
      Env.Cache cache;
      InstanceHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      DAE.FunctionTree funcs;
      list<DAE.Element> daeElts;
      list<DAE.FunctionDefinition> derFuncs;
      Absyn.Info info;

    case (cache,env,ih,mod,pre,csets,(c as SCode.CLASS(name = n,restriction = SCode.R_RECORD())),inst_dims) 
      equation
        (c,cenv) = Lookup.lookupRecordConstructorClass(env,Absyn.IDENT(n));
        (cache,env,ih,DAE.DAE({DAE.FUNCTION(fpath,_,ty1,false,_,source)},funcs)) = implicitFunctionInstantiation(cache,cenv,ih,mod,pre,csets,c,inst_dims);
      then (cache,env,ih,DAE.DAE({DAE.RECORD_CONSTRUCTOR(fpath,ty1,source)},funcs));
      
    /* normal functions */
    case (cache,env,ih,mod,pre,csets,(c as SCode.CLASS(classDef=cd,partialPrefix = partialPrefix, name = n,restriction = SCode.R_FUNCTION())),inst_dims)
      local 
        Option<SCode.Mod> ocp;
        Absyn.Path fq_func;
        
        Boolean finline;
        DAE.InlineType inlineType; 
        SCode.ClassDef cd;
      equation
        inlineType = isInlineFunc2(c);
        
        (cache,cenv,ih,_,DAE.DAE(daeElts,funcs),csets_1,ty,st,_,_) = instClass(cache,env, ih, UnitAbsynBuilder.emptyInstStore(),mod, pre, csets, c, inst_dims, true, INNER_CALL(), ConnectionGraph.EMPTY);
        env_1 = Env.extendFrameC(env,c);
        (cache,fpath) = makeFullyQualified(cache,env_1, Absyn.IDENT(n));
        derFuncs = getDeriveAnnotation(cd,fpath,cache,env,pre);
                
        (cache,dae1) = instantiateDerivativeFuncs(cache,env,ih,derFuncs,fpath);              
        
        ty1 = setFullyQualifiedTypename(ty,fpath);

        env_1 = Env.extendFrameT(env_1, n, ty1); 
        
        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        dae = DAEUtil.joinDaes(DAE.DAE({DAE.FUNCTION(fpath,DAE.FUNCTION_DEF(daeElts)::derFuncs,ty1,partialPrefix,inlineType,source)},funcs),dae1);
      then
        (cache,env_1,ih,dae);

    /* External functions should also have their type in env, but no dae. */ 
    case (cache,env,ih,mod,pre,csets,(c as SCode.CLASS(partialPrefix=partialPrefix,name = n,restriction = (restr as SCode.R_EXT_FUNCTION()),
          classDef = (parts as SCode.PARTS(elementLst = els)))),inst_dims)
      equation 
        (cache,cenv,ih,_,DAE.DAE(daeElts,funcs),csets_1,ty,st,_,_) = instClass(cache,env,ih, UnitAbsynBuilder.emptyInstStore(),mod, pre, csets, c, inst_dims, true, INNER_CALL(), ConnectionGraph.EMPTY);
        //env_11 = Env.extendFrameC(cenv,c); 
        // Only created to be able to get FQ path.  
        (cache,fpath) = makeFullyQualified(cache,cenv, Absyn.IDENT(n));

        derFuncs = getDeriveAnnotation(parts,fpath,cache,env,pre);
        
        (cache,dae1) = instantiateDerivativeFuncs(cache,env,ih,derFuncs,fpath); 
         
        ty1 = setFullyQualifiedTypename(ty,fpath);
        env_1 = Env.extendFrameT(cenv, n, ty1);
        prot = false;
        (cache,tempenv,ih,_,_,_,_,_,_,_,_,_) = 
          instClassdef(cache,env_1,ih, UnitAbsyn.noStore,mod, pre, csets_1, ClassInf.FUNCTION(fpath), n,parts, restr, prot, inst_dims, true,ConnectionGraph.EMPTY,NONE) "how to get this? impl" ;
        (cache,ih,extdecl) = instExtDecl(cache,tempenv,ih, n, parts, true) "impl" ;
        
        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        dae = DAEUtil.joinDaes(DAE.DAE({DAE.FUNCTION(fpath,{DAE.FUNCTION_EXT(daeElts,extdecl)},ty1,partialPrefix,DAE.NO_INLINE,source)},funcs),dae1);
      then
        (cache,env_1,ih,dae);

    /* Instantiate overloaded functions */
    case (cache,env,ih,mod,pre,csets,(c as SCode.CLASS(name = n,restriction = (restr as SCode.R_FUNCTION()),
          classDef = SCode.OVERLOAD(pathLst = funcnames))),inst_dims)
      equation 
        (cache,env_1,ih,daefuncs) = instOverloadedFunctions(cache,env,ih, n, funcnames) "Overloaded functions" ;
      then
        (cache,env_1,ih,daefuncs);
    // handle failure
    case (_,env,_,_,_,_,SCode.CLASS(name=n),_)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- Inst.implicitFunctionInstantiation failed " +& n);
        Debug.traceln("  Scope: " +& Env.printEnvPathStr(env));
      then fail();
  end matchcontinue;
end implicitFunctionInstantiation;

protected function instantiateDerivativeFuncs "instantiates all functions found in derivative annotations so they are also added to the 
dae and can be generated code for in case they are required"
  input Env.Cache cache;
  input Env.Env env;
  input InstanceHierarchy ih;
  input list<DAE.FunctionDefinition> funcs;
  input Absyn.Path path "the function name itself, must be added to derivative functions mapping to be able to search upwards";
  output Env.Cache outCache;
  output DAE.DAElist dae;
algorithm  
  //print("instantiate deriative functions for "+&Absyn.pathString(path)+&"\n"); 
 (outCache,dae) := instantiateDerivativeFuncs2(cache,env,ih,DAEUtil.getDerivativePaths(funcs),path);
 //print("instantiated derivative functions"+&DAEUtil.dumpStr(dae)+&"\n");
end instantiateDerivativeFuncs;

protected function instantiateDerivativeFuncs2 "help function"
  input Env.Cache cache;
  input Env.Env env;
  input InstanceHierarchy ih;
  input list<Absyn.Path> paths;
  input Absyn.Path path "the function name itself, must be added to derivative functions mapping to be able to search upwards";
  output Env.Cache outCache;
  output DAE.DAElist dae;
algorithm
  (outCache,dae) := matchcontinue(cache,env,ih,paths,path)
    local Absyn.Path p; Env.Env cenv;
      SCode.Class cdef;
    DAE.DAElist dae1,dae2;
    case(cache,env,ih,{},path) then (cache,DAEUtil.emptyDae);
    /* Skipped recursive calls (by looking in cache) */
    case(cache,env,ih,p::paths,path) equation
        (cache,cdef,cenv) = Lookup.lookupClass(cache,env,p,true);   
        (cache,p) = makeFullyQualified(cache,cenv,p);      
        _ = Env.getCachedInstFunc(cache,p);
        (cache,dae) = instantiateDerivativeFuncs2(cache,env,ih,paths,path);
    then (cache,dae);
      
      
    case(cache,env,ih,p::paths,path) equation
        (cache,cdef,cenv) = Lookup.lookupClass(cache,env,p,true);
        (cache,p) = makeFullyQualified(cache,cenv,p);
        // add to cache before instantiating, to break recursion for recursive definitions.  
        cache = Env.addCachedInstFunc(cache,path);
        cache = Env.addCachedInstFunc(cache,p);
        (cache,_,ih,dae1) = implicitFunctionInstantiation(cache,cenv,ih,DAE.NOMOD(),Prefix.NOPRE(), Connect.emptySet,cdef,{});
        
        dae1 = addNameToDerivativeMapping(dae1,path);
        dae1 = DAEUtil.addDaeFunction(dae1);
        (cache,dae2) = instantiateDerivativeFuncs2(cache,env,ih,paths,path);
        dae = DAEUtil.joinDaes(dae1,dae2);        
    then (cache,dae);        
  end matchcontinue;
end instantiateDerivativeFuncs2;

protected function addNameToDerivativeMapping "adds the function name to the lowerOrderDerivatives list of the function mapping "
  input DAE.DAElist dae;
  input Absyn.Path name;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue(dae,name)
  local 
    DAE.FunctionTree funcs;
    list<DAE.Element> elts;
    
    case(DAE.DAE(elts,funcs),name) equation
      elts = addNameToDerivativeMappingElts(elts,name);      
    then DAE.DAE(elts,funcs);
  end matchcontinue;   
end addNameToDerivativeMapping;

protected function addNameToDerivativeMappingElts "help function to addNameToDerivativeMapping "
  input list<DAE.Element> elts;
  input Absyn.Path path;
  output list<DAE.Element> outElts;
algorithm
  outElts := matchcontinue(elts,path) 
  local 
    DAE.Element elt;
    list<DAE.FunctionDefinition> funcs;
    DAE.Type tp;
    Absyn.Path p;
    Boolean part;
    DAE.InlineType inline;
    DAE.ElementSource source;
    
    case({},path) then {};
    
    case(DAE.FUNCTION(p,funcs,tp,part,inline,source)::elts,path) equation
      elts = addNameToDerivativeMappingElts(elts,path);
      funcs = addNameToDerivativeMappingFunctionDefs(funcs,path);
    then DAE.FUNCTION(p,funcs,tp,part,inline,source)::elts;
    
    case(elt::elts,path) equation
        elts = addNameToDerivativeMappingElts(elts,path);
    then elt::elts;  
  end matchcontinue;
end addNameToDerivativeMappingElts;

protected function addNameToDerivativeMappingFunctionDefs " help function to addNameToDerivativeMappingElts"
  input list<DAE.FunctionDefinition> funcs;
  input Absyn.Path path;
  output list<DAE.FunctionDefinition> outFuncs;
algorithm
  outFuncs := matchcontinue(funcs,path)
  local DAE.FunctionDefinition func;
    Absyn.Path p1,p2;
    Integer do;
    Option<Absyn.Path> dd;
    list<Absyn.Path> lowerOrderDerivatives;
    list<tuple<Integer,DAE.derivativeCond>> conds;
    
    case({},_) then {};
      
    case(DAE.FUNCTION_DER_MAPPER(p1,p2,do,conds,dd,lowerOrderDerivatives)::funcs,path) equation
      funcs = addNameToDerivativeMappingFunctionDefs(funcs,path);
    then DAE.FUNCTION_DER_MAPPER(p1,p2,do,conds,dd,path::lowerOrderDerivatives)::funcs;
    
    case(func::funcs,path) equation
      funcs = addNameToDerivativeMappingFunctionDefs(funcs,path);
    then func::funcs;
      
  end matchcontinue;
end addNameToDerivativeMappingFunctionDefs;

protected function getDeriveAnnotation "
Authot BZ
helper function for implicitFunctionInstantiation, returns derivative of function, if any.
"
  input SCode.ClassDef cd;
  input Absyn.Path baseFunc;
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  output list<DAE.FunctionDefinition> element;
algorithm 
  (element) := matchcontinue(cd,baseFunc,inCache,inEnv,inPrefix)
  local
    list<SCode.Annotation> anns;
    list<SCode.Element> elemDecl;
  case(SCode.PARTS(annotationLst = anns, elementLst = elemDecl),baseFunc,inCache,inEnv,inPrefix)
     then getDeriveAnnotation2(anns,elemDecl,baseFunc,inCache,inEnv,inPrefix);
  case(SCode.CLASS_EXTENDS(annotationLst = anns, elementLst = elemDecl),baseFunc,inCache,inEnv,inPrefix)
     then getDeriveAnnotation2(anns,elemDecl,baseFunc,inCache,inEnv,inPrefix);
  case(_,_,_,_,_) then {};
end matchcontinue;
end getDeriveAnnotation;

protected function getDeriveAnnotation2 "
helper function for getDeriveAnnotation
"
  input list<SCode.Annotation> anns;
  input list<SCode.Element> elemDecl;
  input Absyn.Path baseFunc;
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  output list<DAE.FunctionDefinition> element;
algorithm 
  (element) := matchcontinue(anns,elemDecl,baseFunc,inCache,inEnv,inPrefix)
  local
    list<SCode.SubMod> smlst;
    SCode.Mod mod;
  case({},_,_,_,_,_) then {}; 
  case(SCode.ANNOTATION(SCode.MOD(_,_,smlst,_)) :: anns,elemDecl,baseFunc,inCache,inEnv,inPrefix)
     then getDeriveAnnotation3(smlst,elemDecl,baseFunc,inCache,inEnv,inPrefix);
  case(_::anns,elemDecl,baseFunc,inCache,inEnv,inPrefix) 
     then getDeriveAnnotation2(anns,elemDecl,baseFunc,inCache,inEnv,inPrefix);
end matchcontinue;
end getDeriveAnnotation2; 

protected function getDeriveAnnotation3 "
Author: bjozac
	helper function to getDeriveAnnotation2"
  input list<SCode.SubMod> subs;
  input list<SCode.Element> elemDecl;
  input Absyn.Path baseFunc;
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  output list<DAE.FunctionDefinition> element;
algorithm element := matchcontinue(subs,elemDecl,baseFunc,inCache,inEnv,inPrefix)
  local
    Absyn.Exp ae;
    Exp.Exp exp;
    Absyn.ComponentRef acr;
    Absyn.Path deriveFunc;
    Option<Absyn.Path> defaultDerivative;
    SCode.Mod m;
    list<SCode.SubMod> subs2;
    Integer order;
    list<tuple<Integer,DAE.derivativeCond>> conditionRefs;
    String dbgString;
    DAE.FunctionDefinition mapper;
      list<DAE.Type> deriveTypes;
  case({},_,_,_,_,_) then fail();
  case(SCode.NAMEMOD("derivative",(m as SCode.MOD(subModLst = (subs2 as _::_),absynExpOption=SOME(((ae as Absyn.CREF(acr)),_)))))::subs,elemDecl,baseFunc,inCache,inEnv,inPrefix)
    equation
      deriveFunc = Absyn.crefToPath(acr);
      (_,deriveFunc) = makeFullyQualified(inCache,inEnv,deriveFunc);
      order = getDerivativeOrder(subs2);

      ErrorExt.setCheckpoint() "don't report errors on modifers in functions";
      conditionRefs = getDeriveCondition(subs2,elemDecl,inCache,inEnv,inPrefix);
      ErrorExt.rollBack();

      conditionRefs = Util.sort(conditionRefs,DAEUtil.derivativeOrder); 
      defaultDerivative = getDerivativeSubModsOptDefault(subs,inCache,inEnv,inPrefix);
      
      
      /*print("\n adding conditions on derivative count: " +& intString(listLength(conditionRefs)) +& "\n");
      dbgString = Absyn.optPathString(defaultDerivative);
      dbgString = Util.if_(stringEqual(dbgString,""),"", "**** Default Derivative: " +& dbgString +& "\n");
      print("**** Function derived: " +& Absyn.pathString(baseFunc) +& " \n");        
      print("**** Deriving function: " +& Absyn.pathString(deriveFunc) +& "\n"); 
      print("**** Conditions: " +& Util.stringDelimitList(DAEUtil.dumpDerivativeCond(conditionRefs),", ") +& "\n");
      print("**** Order: " +& intString(order) +& "\n");
      print(dbgString);*/
      
      
      mapper = DAE.FUNCTION_DER_MAPPER(baseFunc,deriveFunc,order,conditionRefs,defaultDerivative,{});
    then 
      {mapper};
  case(_ :: subs,elemDecl,baseFunc,inCache,inEnv,inPrefix) 
  then getDeriveAnnotation3(subs,elemDecl,baseFunc,inCache,inEnv,inPrefix);
end matchcontinue;
end getDeriveAnnotation3;

protected function getDeriveCondition "
helper function for getDeriveAnnotation
Extracts conditions for derivative.
"
  input list<SCode.SubMod> subs;
    input list<SCode.Element> elemDecl;
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  output list<tuple<Integer,DAE.derivativeCond>> outconds;
algorithm outconds := matchcontinue(subs,elemDecl,inCache,inEnv,inPrefix)
  local
    Absyn.Exp ae;
    SCode.Mod m;
    DAE.Mod elabedMod;
    DAE.SubMod sub;
    String name;
    DAE.derivativeCond cond;
    DAE.Exp e;
    Absyn.ComponentRef acr;
    Integer varPos;
  case({},_,_,_,_) then {};
  case(SCode.NAMEMOD("noDerivative",(m as SCode.MOD(absynExpOption = SOME(((Absyn.CREF(acr)),_)))))::subs,elemDecl,inCache,inEnv,inPrefix)
    equation
      name = Absyn.printComponentRefStr(acr);
      outconds = getDeriveCondition(subs,elemDecl,inCache,inEnv,inPrefix);
      varPos = setFunctionInputIndex(elemDecl,name,1);
    then 
      (varPos,DAE.NO_DERIVATIVE(DAE.ICONST(99)))::outconds;

  case(SCode.NAMEMOD("zeroDerivative",(m as SCode.MOD(absynExpOption =  SOME(((Absyn.CREF(acr)),_)) )))::subs,elemDecl,inCache,inEnv,inPrefix)
    equation      
      name = Absyn.printComponentRefStr(acr);
      outconds = getDeriveCondition(subs,elemDecl,inCache,inEnv,inPrefix);
      varPos = setFunctionInputIndex(elemDecl,name,1);
    then 
      (varPos,DAE.ZERO_DERIVATIVE)::outconds;
  case(SCode.NAMEMOD("noDerivative",(m as SCode.MOD(absynExpOption=_)))::subs,elemDecl,inCache,inEnv,inPrefix)
    equation
      (inCache,(elabedMod as DAE.MOD(subModLst={sub})),_) = Mod.elabMod(inCache,inEnv, inPrefix, m, false);
      (name,cond) = extractNameAndExp(sub);
      outconds = getDeriveCondition(subs,elemDecl,inCache,inEnv,inPrefix);
      varPos = setFunctionInputIndex(elemDecl,name,1);
    then 
      (varPos,cond)::outconds;
      
  case(_::subs,elemDecl,inCache,inEnv,inPrefix) then getDeriveCondition(subs,elemDecl,inCache,inEnv,inPrefix);
end matchcontinue;
end getDeriveCondition;

protected function setFunctionInputIndex "
Author BZ
"
input list<SCode.Element> elemDecl;
input String str;
input Integer currPos;
output Integer index;
algorithm
  index := matchcontinue(elemDecl,str,currPos)
  local
    String str2;
  case({},str,currPos) 
    equation
      print(" failure in setFunctionInputIndex, didn't find any index for: " +& str +& "\n"); 
      then fail();
        /* found matching input*/ 
      case(SCode.COMPONENT(component=str2,attributes =SCode.ATTR(direction=Absyn.INPUT()))::elemDecl,str,currPos)
        equation
          true = stringEqual(str2, str);
          then
            currPos; 
       /* Non-matching input, increase inputarg pos*/     
      case(SCode.COMPONENT(component=_,attributes =SCode.ATTR(direction=Absyn.INPUT()))::elemDecl,str,currPos) then setFunctionInputIndex(elemDecl,str,currPos+1);
       
       /* Other element, do not increaese inputarg pos*/ 
      case(_::elemDecl,str,currPos) then setFunctionInputIndex(elemDecl,str,currPos);
  end matchcontinue;
end setFunctionInputIndex;

protected function extractNameAndExp "
Author BZ
could be used by getDeriveCondition, depending on interpretation of spec compared to constructed libraries.
helper function for getDeriveAnnotation
"
input DAE.SubMod m;
output String inputVar;
output DAE.derivativeCond cond;
algorithm (cr,cond) := matchcontinue(m)
  local
    DAE.EqMod eq;
    DAE.Exp e;
    Option<tuple<Absyn.Exp,Boolean>> aoe;
  case(DAE.NAMEMOD(inputVar,mod = DAE.MOD(eqModOption = SOME(eq as DAE.TYPED(modifierAsExp=e)))))
    equation
      then (inputVar,DAE.NO_DERIVATIVE(e));
  case(DAE.NAMEMOD(inputVar,mod = DAE.MOD(eqModOption = NONE)))
    equation 
    then (inputVar,DAE.NO_DERIVATIVE(DAE.ICONST(1)));
  case(DAE.NAMEMOD(inputVar,mod = DAE.MOD(eqModOption = NONE))) // zeroderivative
  then (inputVar,DAE.ZERO_DERIVATIVE);
    
  case(_) then ("",DAE.ZERO_DERIVATIVE);
  end matchcontinue;
end extractNameAndExp;

protected function getDerivativeSubModsOptDefault "
helper function for getDeriveAnnotation"
input list<SCode.SubMod> subs;
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
output Option<Absyn.Path> defaultDerivative;
algorithm defaultDerivative := matchcontinue(subs,inCache,inEnv,inPrefix)
  local
    Absyn.ComponentRef acr;
    Absyn.Path p;
    Absyn.Exp ae;
    SCode.Mod m;
  case({},inCache,inEnv,inPrefix) then NONE;
  case(SCode.NAMEMOD("derivative",(m as SCode.MOD(absynExpOption =SOME(((ae as Absyn.CREF(acr)),_)))))::subs,inCache,inEnv,inPrefix)
    equation
      p = Absyn.crefToPath(acr);
      (_,p) = makeFullyQualified(inCache,inEnv, p);
    then
      SOME(p);
  case(_::subs,inCache,inEnv,inPrefix) then getDerivativeSubModsOptDefault(subs,inCache,inEnv,inPrefix);
  end matchcontinue;
end getDerivativeSubModsOptDefault;

protected function getDerivativeOrder "
helper function for getDeriveAnnotation
Get current derive order
"
input list<SCode.SubMod> subs;
output Integer order;
algorithm order := matchcontinue(subs)
  local
    Absyn.Exp ae;
    SCode.Mod m;
  case({}) then 1;
  case(SCode.NAMEMOD("order",(m as SCode.MOD(absynExpOption= SOME(((ae as Absyn.INTEGER(order)),_)))))::subs)
  then order;
  case(_::subs) then getDerivativeOrder(subs);  
  end matchcontinue;
end getDerivativeOrder;

protected function setFullyQualifiedTypename 
"This function sets the FQ path given as argument in types that have optional path set. 
 (The optional path points to the class the type is built from)"
  input tuple<DAE.TType, Option<Absyn.Path>> inType;
  input Absyn.Path path;
  output tuple<DAE.TType, Option<Absyn.Path>> resType;
algorithm 
  resType := matchcontinue (tp,path) 
    local 
      Absyn.Path p,newPath;
      DAE.TType tp;   
    case ((tp,NONE()),_) then ((tp,NONE));
    case ((tp,SOME(p)),newPath) then ((tp,SOME(newPath)));
  end matchcontinue;
end setFullyQualifiedTypename; 
  
public function isInlineFunc "
Author: stefan 
function: isInlineFunc
	looks up a function and returns whether or not it is an inline function"
	input Absyn.Path inPath;
	input Env.Cache inCache;
	input Env.Env inEnv;
	output DAE.InlineType outBoolean;
algorithm 
  outBoolean := matchcontinue(inPath,inCache,inEnv)
    local
      Absyn.Path p;
      Env.Cache c;
      Env.Env env;
      SCode.Class cl;
    case(p,c,env)
      equation
        (c,cl,env) = Lookup.lookupClass(c,env,p,true);
      then
        isInlineFunc2(cl);
    case(_,_,_) then DAE.NO_INLINE;
  end matchcontinue;
end isInlineFunc;

public function isInlineFunc2 "
Author: bjozac 2009-12 
	helper function to isInlineFunc"
	input SCode.Class inClass;
	output DAE.InlineType outInlineType;
algorithm
  outInlineType := matchcontinue(inClass)
    local
      list<SCode.Annotation> anns;
      
    case(SCode.CLASS(classDef = SCode.PARTS(annotationLst = anns))) 
      then isInlineFunc3(anns);

    case(SCode.CLASS(classDef = SCode.CLASS_EXTENDS(annotationLst = anns)))
      then isInlineFunc3(anns);
    case(_) then DAE.NO_INLINE;
  end matchcontinue;
end isInlineFunc2;

protected function isInlineFunc3 "
Author Stefan
	helper function to isInlineFunc2"
	input list<SCode.Annotation> inAnnotationList;
	output DAE.InlineType outBoolean;
algorithm
  outBoolean := matchcontinue(inAnnotationList)
    local
      list<SCode.Annotation> cdr;
      list<SCode.SubMod> smlst;
      DAE.InlineType res;
    case({}) then DAE.NO_INLINE;
    case(SCode.ANNOTATION(SCode.MOD(_,_,smlst,_)) :: cdr)
      equation
        res = isInlineFunc4(smlst);
        true = DAEUtil.convertInlineTypeToBool(res);
      then
        res;
    case(_ :: cdr)
      equation
        res = isInlineFunc3(cdr);
      then
        res;
  end matchcontinue;
end isInlineFunc3;

protected function isInlineFunc4 "
Author: stefan
function: isInlineFunc4
	helper function to isInlineFunc3"
  input list<SCode.SubMod> inSubModList;
  output DAE.InlineType res;
algorithm
  outBoolean := matchcontinue(inSubModList)
    local
      list<SCode.SubMod> cdr;
      Boolean res;
    case({}) then DAE.NO_INLINE;
      
    case(SCode.NAMEMOD("Inline",SCode.MOD(_,_,_,SOME((Absyn.BOOL(true),_)))) :: _)
    then DAE.NORM_INLINE;
      
    case(SCode.NAMEMOD("__MathCore_InlineAfterIndexReduction",SCode.MOD(_,_,_,SOME((Absyn.BOOL(true),_)))) :: _)
    then DAE.AFTER_INDEX_RED_INLINE;
      
    case(SCode.NAMEMOD("__Dymola_InlineAfterIndexReduction",SCode.MOD(_,_,_,SOME((Absyn.BOOL(true),_)))) :: _)
    then DAE.AFTER_INDEX_RED_INLINE;  
      
    case(_ :: cdr) then isInlineFunc4(cdr);
  end matchcontinue;
end isInlineFunc4;

public function implicitFunctionTypeInstantiation 
"function implicitFunctionTypeInstantiation
  author: PA
  When looking up a function type it is sufficient to only instantiate the input and output arguments of the function. 
  The implicitFunctionInstantiation function will instantiate the function body, resulting in a DAE for the body. 
  This function does not do that. Therefore this function is the only solution available for recursive functions, 
  where the function body contain a call to the function itself.
  
  Extended 2007-06-29, BZ 
  Now this function also handles Derived function."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input SCode.Class inClass;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
algorithm 
  (outCache,outEnv,outIH) := matchcontinue (inCache,inEnv,inIH,inClass)
    local
      SCode.Class stripped_class;
      list<Env.Frame> env_1,env;
      String id,cn2;
      Boolean p,e;
      SCode.Restriction r;
      Option<Absyn.ExternalDecl> extDecl;
      list<SCode.Element> elts;
      Env.Cache cache;
      InstanceHierarchy ih;
      list<SCode.Annotation> annotationLst;
      Absyn.Info info;
      Env.Cache garbageCache;

    /* The function type can be determined without the body. Annotations need to be preserved though. */
    case (cache,env,ih,SCode.CLASS(name = id,partialPrefix = p,encapsulatedPrefix = e,restriction = r,
                                   classDef = SCode.PARTS(elementLst = elts,annotationLst=annotationLst,externalDecl=extDecl),info = info)) 
      equation 
        stripped_class = SCode.CLASS(id,p,e,r,SCode.PARTS(elts,{},{},{},{},extDecl,annotationLst,NONE()),info);
        (garbageCache,env_1,ih,_) = implicitFunctionInstantiation(cache,env,ih, DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, stripped_class, {});
      then
        (cache,env_1,ih);

    /* The function type canNOT be determined without the body. */
    case (cache,env,ih,SCode.CLASS(name = id,partialPrefix = p,encapsulatedPrefix = e,restriction = r,
                                   classDef = SCode.DERIVED(typeSpec = Absyn.TPATH(path = cn,arrayDim = ad), 
                                                            modifications = mod1),info = info))  
      local 
        Absyn.Path cn,fpath; 
        Option<list<Absyn.Subscript>> ad;
        SCode.Mod mod1;
        Mod mod2;
        Env.Env cenv,cenv_2;
        SCode.ClassDef part;
        SCode.Class c;
        tuple<DAE.TType, Option<Absyn.Path>> ty1,ty;
      equation 
        (cache,(c as SCode.CLASS(name = cn2, restriction = r)),cenv) = Lookup.lookupClass(cache,env, cn, true);
        (cache,mod2,_) = Mod.elabMod(cache,env, Prefix.NOPRE(), mod1, false); 
        (cache,_,ih,_,_,_,ty,_,_,_) = instClass(cache,env,ih,UnitAbsynBuilder.emptyInstStore(), mod2, Prefix.NOPRE(), Connect.emptySet, c, {}, true, INNER_CALL(), ConnectionGraph.EMPTY);
        env_1 = Env.extendFrameC(env,c);
        (cache,fpath) = makeFullyQualified(cache,env_1, Absyn.IDENT(id));
        ty1 = setFullyQualifiedTypename(ty,fpath);
        env_1 = Env.extendFrameT(env_1, id, ty1);
      then
        (cache,env_1,ih);

    case (_,_,_,_)
      equation
        Debug.fprintln("failtrace", "- Inst.implicitFunctionTypeInstantiation failed");
      then fail();
  end matchcontinue;
end implicitFunctionTypeInstantiation; 

protected function instOverloadedFunctions 
"function: instOverloadedFunctions 
  This function instantiates the functions in the overload list of a 
  overloading function definition and register the function types using 
  the overloaded name. It also creates dae elements for the functions."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Absyn.Ident inIdent;
  input list<Absyn.Path> inAbsynPathLst;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
algorithm 
  (outCache,outEnv,outIH,outDae) := matchcontinue (inCache,inEnv,inIH,inIdent,inAbsynPathLst)
    local
      list<Env.Frame> env,cenv,env_1,env_2;
      SCode.Class c;
      String id,overloadname;
      Boolean encflag;
      list<DAE.Element> daeElts;
      list<tuple<String, tuple<DAE.TType, Option<Absyn.Path>>>> args;
      tuple<DAE.TType, Option<Absyn.Path>> tp,ty;
      ClassInf.State st;
      Absyn.Path fpath,ovlfpath,fn;
      list<Absyn.Path> fns;
      Env.Cache cache;
      InstanceHierarchy ih;
      Boolean partialPrefix;
      DAE.InlineType isInline;
      DAE.ElementSource source "the origin of the element";
      DAE.FunctionTree funcs;
      DAE.DAElist dae,dae2;     
      
    case (cache,env,ih,_,{}) then (cache,env,ih,DAEUtil.emptyDae);

    // Instantiate each function, add its FQ name to the type, needed when deoverloading  
    case (cache,env,ih,overloadname,(fn :: fns))  
      equation 
        (cache,(c as SCode.CLASS(name=id,partialPrefix=partialPrefix,encapsulatedPrefix=encflag,restriction=SCode.R_FUNCTION())),cenv) = Lookup.lookupClass(cache, env, fn, true);
        (cache,_,ih,_,DAE.DAE(daeElts,funcs),_,(DAE.T_FUNCTION(args,tp,isInline),_),st,_,_) = 
           instClass(cache,cenv,ih,UnitAbsynBuilder.emptyInstStore(), DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, {}, true, INNER_CALL(), ConnectionGraph.EMPTY);
        (cache,fpath) = makeFullyQualified(cache,env, Absyn.IDENT(overloadname));
        (cache,ovlfpath) = makeFullyQualified(cache,cenv, Absyn.IDENT(id));
        ty = (DAE.T_FUNCTION(args,tp,isInline),SOME(ovlfpath));
        env_1 = Env.extendFrameT(env, overloadname, ty);
        (cache,env_2,ih,dae2) = instOverloadedFunctions(cache,env_1,ih, overloadname, fns);
        // TODO: Fix inline here 
        print(" DAE.InlineType FIX HERE \n");
        // set the  of this element
        source = DAEUtil.addElementSourcePartOfOpt(DAE.emptyElementSource, Env.getEnvPath(env));        
        dae = DAEUtil.joinDaes(DAE.DAE({DAE.FUNCTION(fpath,{DAE.FUNCTION_DEF(daeElts)},ty,partialPrefix,DAE.NO_INLINE(),source)},funcs),dae2);        
      then
        (cache,env_2,ih,dae);
    // failure
    case (_,env,ih,_,_)
      equation 
        Debug.fprint("failtrace", "-Inst.instOverloaded_functions failed\n");
      then
        fail();
  end matchcontinue;
end instOverloadedFunctions;

protected function instExtDecl 
"function: instExtDecl
  author: LS
  This function handles the external declaration. If there is an explicit 
  call of the external function, the component references are looked up and
  inserted in the argument list, otherwise the input and output parameters
  are inserted in the argument list with their order. The return type is
  determined according to the specification; if there is a explicit call 
  and a lhs, which must be an output parameter, the type of the function is
  that type. If no explicit call and only one output parameter exists, then
  this will be the return type of the function, otherwise the return type 
  will be void."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Ident inIdent;
  input SCode.ClassDef inClassDef;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output InstanceHierarchy outIH;
  output DAE.ExternalDecl outExternalDecl;
algorithm 
  (outCache,outIH,outExternalDecl) := matchcontinue (inCache,inEnv,inIH,inIdent,inClassDef,inBoolean)
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
      Env.Cache cache;
      InstanceHierarchy ih;
      
    case (cache,env,ih,n,SCode.PARTS(elementLst=els,externalDecl = SOME(extdecl)),impl) /* impl */
      equation 
        isExtExplicitCall(extdecl);
        fname = instExtGetFname(extdecl, n);
        (cache,fargs) = instExtGetFargs(cache,env, extdecl, impl);
        (cache,rettype) = instExtGetRettype(cache,env, extdecl, impl);
        lang = instExtGetLang(extdecl);
        ann = instExtGetAnnotation(extdecl);
        daeextdecl = DAE.EXTERNALDECL(fname,fargs,rettype,lang,ann);
      then
        (cache,ih,daeextdecl);
        
    case (cache,env,ih,n,SCode.PARTS(elementLst = els,externalDecl = SOME(orgextdecl)),impl)
      equation 
        failure(isExtExplicitCall(orgextdecl));
        extdecl = instExtMakeExternaldecl(n, els, orgextdecl);
        (fname) = instExtGetFname(extdecl, n);
        (cache,fargs) = instExtGetFargs(cache,env, extdecl, impl);
        (cache,rettype) = instExtGetRettype(cache,env, extdecl, impl);
        lang = instExtGetLang(extdecl);
        ann = instExtGetAnnotation(orgextdecl);
        daeextdecl = DAE.EXTERNALDECL(fname,fargs,rettype,lang,ann);
      then
        (cache,ih,daeextdecl);
    case (_,env,ih,_,_,_)
      equation 
        Debug.fprintln("failtrace", "#-- Inst.instExtDecl failed");
      then
        fail();
  end matchcontinue;
end instExtDecl;

protected function isExtExplicitCall 
"function: isExtExplicitCall  
  If the external function id is present, then a function call must
  exist, i.e. explicit call was written in the external clause."
  input Absyn.ExternalDecl inExternalDecl;
algorithm 
  _ := matchcontinue (inExternalDecl)
    local String id;
    case Absyn.EXTERNALDECL(funcName = SOME(id)) then (); 
  end matchcontinue;
end isExtExplicitCall;

protected function instExtMakeExternaldecl 
"function: instExtMakeExternaldecl
  author: LS
   This function generates a default explicit function call, 
  when it is omitted. If only one output variable exists, 
  the implicit call is equivalent to:
       external \"C\" output_var=func(input_var1, input_var2,...)
  with the input_vars in their declaration order. If several output 
  variables exists, the implicit call is equivalent to:
      external \"C\" func(var1, var2, ...)
  where each var can be input or output."
  input Ident inIdent;
  input list<SCode.Element> inSCodeElementLst;
  input Absyn.ExternalDecl inExternalDecl;
  output Absyn.ExternalDecl outExternalDecl;
algorithm 
  outExternalDecl := matchcontinue (inIdent,inSCodeElementLst,inExternalDecl)
    local
      SCode.Element outvar;
      list<SCode.Element> invars,els,inoutvars;
      list<list<Absyn.Exp>> explists;
      list<Absyn.Exp> exps;
      Absyn.ComponentRef retcref;
      Absyn.ExternalDecl extdecl;
      String id;
      Option<String> lang;

    /* the case with only one output var, and that cannot be 
     * array, otherwise instExtMakeCrefs outvar will fail 
     */      
    case (id,els,Absyn.EXTERNALDECL(lang = lang))
      equation 
        (outvar :: {}) = Util.listFilter(els, isOutputVar);
        invars = Util.listFilter(els, isInputVar);
        explists = Util.listMap(invars, instExtMakeCrefs);
        exps = Util.listFlatten(explists);
        {Absyn.CREF(retcref)} = instExtMakeCrefs(outvar);
        extdecl = Absyn.EXTERNALDECL(SOME(id),lang,SOME(retcref),exps,NONE);
      then
        extdecl;
    case (id,els,Absyn.EXTERNALDECL(lang = lang))
      equation 
        inoutvars = Util.listFilter(els, isInoutVar);
        explists = Util.listMap(inoutvars, instExtMakeCrefs);
        exps = Util.listFlatten(explists);
        extdecl = Absyn.EXTERNALDECL(SOME(id),lang,NONE,exps,NONE);
      then
        extdecl;
    case (_,_,_)
      equation 
        Debug.fprintln("failtrace", "#-- Inst.instExtMakeExternaldecl failed");
      then
        fail();
  end matchcontinue;
end instExtMakeExternaldecl;

protected function isInoutVar 
"function: isInoutVar  
  Succeds for Elements that are input or output components"
  input SCode.Element inElement;
algorithm 
  _ := matchcontinue (inElement)
    local SCode.Element e;
    case e equation isOutputVar(e); then ();
    case e equation isInputVar(e); then ();
  end matchcontinue;
end isInoutVar;

protected function isOutputVar 
"function: isOutputVar 
  Succeds for element that is output component"
  input SCode.Element inElement;
algorithm 
  _ := matchcontinue (inElement)
    case SCode.COMPONENT(attributes = SCode.ATTR(direction = Absyn.OUTPUT())) then ();
  end matchcontinue;
end isOutputVar;

protected function isInputVar 
"function: isInputVar 
  Succeds for element that is input component"
  input SCode.Element inElement;
algorithm 
  _ := matchcontinue (inElement)
    case SCode.COMPONENT(attributes = SCode.ATTR(direction = Absyn.INPUT())) then ();
  end matchcontinue;
end isInputVar;

protected function instExtMakeCrefs 
"function: instExtMakeCrefs
  author: LS
  This function is used in external function declarations. 
  It collects the component identifier and the dimension 
  sizes and returns as a Absyn.Exp list"
  input SCode.Element inElement;
  output list<Absyn.Exp> outAbsynExpLst;
algorithm 
  outAbsynExpLst := matchcontinue (inElement)
    local
      list<Absyn.Exp> sizelist,crlist;
      String id;
      Boolean fi,re,pr;
      list<Absyn.Subscript> dims;
      Absyn.TypeSpec path;
      SCode.Mod mod;
      Option<SCode.Comment> comment;

    case SCode.COMPONENT(component = id,finalPrefix = fi,replaceablePrefix = re,protectedPrefix = pr,
                         attributes = SCode.ATTR(arrayDims = dims),typeSpec = path,
                         modifications = mod,comment = comment)
      equation 
        sizelist = instExtMakeCrefs2(id, dims, 1);
        crlist = (Absyn.CREF(Absyn.CREF_IDENT(id,{})) :: sizelist);
      then
        crlist;
  end matchcontinue;
end instExtMakeCrefs;

protected function instExtMakeCrefs2 
"function: instExtMakeCrefs2 
  Helper function to instExtMakeCrefs, collects array dimension sizes."
  input SCode.Ident inIdent;
  input Absyn.ArrayDim inArrayDim;
  input Integer inInteger;
  output list<Absyn.Exp> outAbsynExpLst;
algorithm 
  outAbsynExpLst := matchcontinue (inIdent,inArrayDim,inInteger)
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
          Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(id,{})),
          Absyn.INTEGER(dimno)},{})) :: restlist);
      then
        exps;
  end matchcontinue;
end instExtMakeCrefs2;

protected function instExtGetFname 
"function: instExtGetFname
  Returns the function name of the externally defined function."
  input Absyn.ExternalDecl inExternalDecl;
  input Ident inIdent;
  output Ident outIdent;
algorithm 
  outIdent := matchcontinue (inExternalDecl,inIdent)
    local String id,fid;
    case (Absyn.EXTERNALDECL(funcName = SOME(id)),fid) then id; 
    case (Absyn.EXTERNALDECL(funcName = NONE),fid) then fid; 
  end matchcontinue;
end instExtGetFname;

protected function instExtGetAnnotation 
"function: instExtGetAnnotation
  author: PA
  Return the annotation associated with an external function declaration.
  If no annotation is found, check the classpart annotations."
  input Absyn.ExternalDecl inExternalDecl;
  output Option<Absyn.Annotation> outAbsynAnnotationOption;
algorithm 
  outAbsynAnnotationOption := matchcontinue (inExternalDecl)
    local Option<Absyn.Annotation> ann;
    case (Absyn.EXTERNALDECL(annotation_ = ann)) then ann; 
  end matchcontinue;
end instExtGetAnnotation;

protected function instExtGetLang 
"function: instExtGetLang
  Return the implementation language of the external function declaration.
  Defaults to \"C\" if no language specified."
  input Absyn.ExternalDecl inExternalDecl;
  output String outString;
algorithm 
  outString := matchcontinue (inExternalDecl)
    local String lang;
    case Absyn.EXTERNALDECL(lang = SOME(lang)) then lang; 
    case Absyn.EXTERNALDECL(lang = NONE) then "C"; 
  end matchcontinue;
end instExtGetLang;

protected function elabExpListExt 
"function: elabExpListExt 
  Special elabExp for explicit external calls. 
  This special function calls elabExpExt which handles size builtin 
  calls specially, and uses the ordinary Static.elab_exp for other 
  expressions."
  input Env.Cache inCache; 
  input Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  output Env.Cache outCache;
  output list<DAE.Exp> outExpExpLst;
  output list<DAE.Properties> outTypesPropertiesLst;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outExpExpLst,outTypesPropertiesLst,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption)
    local
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st,st_1,st_2;
      DAE.Exp exp;
      DAE.Properties p;
      list<DAE.Exp> exps;
      list<DAE.Properties> props;
      list<Env.Frame> env;
      Absyn.Exp e;
      list<Absyn.Exp> rest;
      Env.Cache cache;
    case (cache,_,{},impl,st) then (cache,{},{},st); 
    case (cache,env,(e :: rest),impl,st)
      equation 
        (cache,exp,p,st_1) = elabExpExt(cache,env, e, impl, st);
        (cache,exps,props,st_2) = elabExpListExt(cache,env, rest, impl, st_1);
      then
        (cache,(exp :: exps),(p :: props),st_2);
  end matchcontinue;
end elabExpListExt;

protected function elabExpExt 
"function: elabExpExt
  author: LS
  special elabExp for explicit external calls. 
  This special function calls elabExpExt which handles size builtin calls 
  specially, and uses the ordinary Static.elab_exp for other expressions."
  input Env.Cache inCache;
  input Env inEnv;
  input Absyn.Exp inExp;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outExp,outProperties,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption)
    local
      DAE.Exp dimp,arraycrefe,exp,e;
      tuple<DAE.TType, Option<Absyn.Path>> dimty;
      DAE.Properties arraycrprop,prop;
      list<Env.Frame> env;
      Absyn.Exp call,arraycr,dim;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
      Absyn.Exp absynExp;
      
    /* special case for  size */
    case (cache,env,(call as Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "size"),
          functionArgs = Absyn.FUNCTIONARGS(args = (args as {arraycr,dim}),argNames = nargs))),impl,st) 
      equation         
        (cache,dimp,DAE.PROP(dimty,_),_,_) = Static.elabExp(cache, env, dim, impl, NONE,false);
        (cache,arraycrefe,arraycrprop,_,_) = Static.elabExp(cache, env, arraycr, impl, NONE,false);
        exp = DAE.SIZE(arraycrefe,SOME(dimp));
      then
        (cache,exp,DAE.PROP(DAE.T_INTEGER_DEFAULT,DAE.C_VAR()),st);
    /* For all other expressions, use normal elaboration */
    case (cache,env,absynExp,impl,st) 
      equation 
        (cache,e,prop,st,_) = Static.elabExp(cache, env, absynExp, impl, st,false);
      then
        (cache,e,prop,st);
    case (cache,env,absynExp,impl,st)
      equation 
        Debug.fprintln("failtrace", "-Inst.elabExpExt failed");
      then
        fail();
  end matchcontinue;
end elabExpExt;

protected function instExtGetFargs 
"function: instExtGetFargs
  author: LS
  instantiates function arguments, i.e. actual parameters, in external declaration."
	input Env.Cache inCache;
  input Env inEnv;
  input Absyn.ExternalDecl inExternalDecl;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output list<DAE.ExtArg> outDAEExtArgLst;
algorithm 
  (outCache,outDAEExtArgLst) :=
  matchcontinue (inCache,inEnv,inExternalDecl,inBoolean)
    local
      list<DAE.Exp> exps;
      list<DAE.Properties> props;
      list<DAE.ExtArg> extargs;
      list<Env.Frame> env;
      Option<String> id,lang;
      Option<Absyn.ComponentRef> retcr;
      list<Absyn.Exp> absexps;
      Boolean impl;
      Env.Cache cache;
    case (cache,env,Absyn.EXTERNALDECL(funcName = id,lang = lang,output_ = retcr,args = absexps),impl) /* impl */ 
      equation 
        (cache,exps,props,_) = elabExpListExt(cache,env, absexps, impl, NONE);
        (cache,extargs) = instExtGetFargs2(cache,env, exps, props);
      then
        (cache,extargs);
    case (_,_,_,impl)
      equation 
        Debug.fprintln("failtrace", "- Inst.instExtGetFargs failed");
      then
        fail();
  end matchcontinue;
end instExtGetFargs;

protected function instExtGetFargs2 
"function: instExtGetFargs2
  author: LS
  Helper function to instExtGetFargs"
	input Env.Cache inCache;
  input Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input list<DAE.Properties> inTypesPropertiesLst;
  output Env.Cache outCache;
  output list<DAE.ExtArg> outDAEExtArgLst;
algorithm 
  (outCache,outDAEExtArgLst) := matchcontinue (inCache,inEnv,inExpExpLst,inTypesPropertiesLst)
    local
      list<DAE.ExtArg> extargs;
      DAE.ExtArg extarg;
      list<Env.Frame> env;
      DAE.Exp e;
      list<DAE.Exp> exps;
      DAE.Properties p;
      list<DAE.Properties> props;
      Env.Cache cache;
    case (cache,_,{},_) then (cache,{}); 
    case (cache,env,(e :: exps),(p :: props))
      equation 
        (cache,extargs) = instExtGetFargs2(cache,env, exps, props);
        (cache,extarg) = instExtGetFargsSingle(cache,env, e, p);
      then
        (cache,extarg :: extargs);
  end matchcontinue;
end instExtGetFargs2;

protected function instExtGetFargsSingle 
"function: instExtGetFargsSingle
  author: LS
  Helper function to instExtGetFargs2, does the work for one argument."
	input Env.Cache inCache;
  input Env inEnv;
  input DAE.Exp inExp;
  input DAE.Properties inProperties;
  output Env.Cache outCache;
  output DAE.ExtArg outExtArg;
algorithm 
  (outCache,outExtArg) := matchcontinue (inCache,inEnv,inExp,inProperties)
    local
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty,varty;
      DAE.Binding bnd;
      list<Env.Frame> env;
      DAE.ComponentRef cref;
      DAE.ExpType crty;
      DAE.Const cnst;
      String crefstr,scope;
      DAE.Exp dim,exp;
      DAE.Properties prop;
      Env.Cache cache;
    case (cache,env,DAE.CREF(componentRef = cref,ty = crty),DAE.PROP(type_ = ty,constFlag = cnst))
      equation 
        (cache,attr,ty,bnd) = Lookup.lookupVarLocal(cache,env, cref);
      then
        (cache,DAE.EXTARG(cref,attr,ty));
    case (cache,env,DAE.CREF(componentRef = cref,ty = crty),DAE.PROP(type_ = ty,constFlag = cnst))
      equation 
        failure((_,attr,ty,bnd) = Lookup.lookupVarLocal(cache,env, cref));
        crefstr = Exp.printComponentRefStr(cref);
        scope = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_VARIABLE_ERROR, {crefstr,scope});
      then
        fail();
    case (cache,env,DAE.SIZE(exp = DAE.CREF(componentRef = cref,ty = crty),sz = SOME(dim)),DAE.PROP(type_ = ty,constFlag = cnst))
      equation 
        (cache,attr,varty,bnd) = Lookup.lookupVarLocal(cache,env, cref);
      then
        (cache,DAE.EXTARGSIZE(cref,attr,varty,dim));
    case (cache,env,exp,DAE.PROP(type_ = ty,constFlag = cnst)) then (cache,DAE.EXTARGEXP(exp,ty)); 
    case (cache,_,exp,prop)
      equation 
        Debug.fprintln("failtrace", "#-- Inst.instExtGetFargsSingle failed for expression: " +& Exp.printExpStr(exp));
      then
        fail();
  end matchcontinue;
end instExtGetFargsSingle;

protected function instExtGetRettype 
"function: instExtGetRettype
  author: LS
  Instantiates the return type of an external declaration."
	input Env.Cache inCache;
  input Env inEnv;
  input Absyn.ExternalDecl inExternalDecl;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output DAE.ExtArg outExtArg;
algorithm 
  (outCache,outExtArg) := matchcontinue (inCache,inEnv,inExternalDecl,inBoolean)
    local
      DAE.Exp exp;
      DAE.Properties prop;
      SCode.Accessibility acc;
      DAE.ExtArg extarg;
      list<Env.Frame> env;
      Option<String> n,lang;
      Absyn.ComponentRef cref;
      list<Absyn.Exp> args;
      Boolean impl;
      Env.Cache cache;
    case (cache,_,Absyn.EXTERNALDECL(output_ = NONE),_) then (cache,DAE.NOEXTARG());  /* impl */ 
    case (cache,env,Absyn.EXTERNALDECL(funcName = n,lang = lang,output_ = SOME(cref),args = args),impl)
      equation 
        (cache,exp,prop,acc,_) = Static.elabCref(cache,env, cref, impl,true);
        (cache,extarg) = instExtGetFargsSingle(cache,env, exp, prop);
      then
        (cache,extarg);
    case (_,_,_,_)
      equation 
        Debug.fprintln("failtrace", "- Inst.instExtRettype failed");
      then
        fail();
  end matchcontinue;
end instExtGetRettype;

protected function instEnumeration 
"function: instEnumeration
  author: PA
  This function takes an Ident and list of strings, and returns an enumeration class."
  input SCode.Ident n;
  input list<SCode.Enum> l;
  input Option<SCode.Comment> cmt;
  input Absyn.Info info;
  output SCode.Class outClass;
  list<SCode.Element> comp;
algorithm 
  comp := makeEnumComponents(l);
  outClass := SCode.CLASS(n,false,false,SCode.R_ENUMERATION(),SCode.PARTS(comp,{},{},{},{},NONE,{},cmt),info);
end instEnumeration;

protected function makeEnumComponents 
"function: makeEnumComponents
  author: PA
  This function takes a list of strings and returns the elements of 
  type EnumType each corresponding to one of the enumeration values."
  input list<SCode.Enum> inEnumLst;
  output list<SCode.Element> outSCodeElementLst;
algorithm 
  outSCodeElementLst:= matchcontinue (inEnumLst)
    local
      String str;
      Integer idx;
      list<SCode.Element> els;
      list<SCode.Enum> x;
      Option<SCode.Comment> cmt;
      
    case ({SCode.ENUM(str,cmt)}) 
      then {SCode.COMPONENT(str,Absyn.UNSPECIFIED(),true,false,false,
            SCode.ATTR({},false,false,SCode.RO(),SCode.CONST(),Absyn.BIDIR()),
            Absyn.TPATH(Absyn.IDENT("EnumType"),NONE),SCode.NOMOD(),NONE,cmt,NONE,NONE,NONE)}; 
    case ((SCode.ENUM(str,cmt) :: (x as (_ :: _))))
      equation 
        els = makeEnumComponents(x);
      then
        (SCode.COMPONENT(str,Absyn.UNSPECIFIED(),true,false,false,
         SCode.ATTR({},false,false,SCode.RO(),SCode.CONST(),Absyn.BIDIR()),
         Absyn.TPATH(Absyn.IDENT("EnumType"),NONE),SCode.NOMOD(),NONE,cmt,NONE,NONE,NONE) :: els);
  end matchcontinue;
end makeEnumComponents;

protected function daeDeclare 
"function: daeDeclare 
  Given a global component name, a type, and a set of attributes, this function declares a component for the DAE result.  
  Altough this function returns a list of DAE.Element, only one component is actually declared.
  The functions daeDeclare2 and daeDeclare3 below are helper functions that perform parts of the task.
  Note: Currently, this function can only declare scalar variables, i.e. the element type of an array type is used. To indicate that the variable
  is an array, the InstDims attribute is used. This will need to be redesigned in the futurue, when array variables should not be flattened out in the frontend. 
  "
  input DAE.ComponentRef inComponentRef;
  input ClassInf.State inState;
  input DAE.Type inType;
  input SCode.Attributes inAttributes;
  input Boolean protection;
  input Option<DAE.Exp> inExpExpOption;
  input InstDims inInstDims;
  input DAE.StartValue inStartValue;
  input Option<DAE.VariableAttributes> inDAEVariableAttributesOption;
  input Option<SCode.Comment> inAbsynCommentOption;
  input Absyn.InnerOuter io;
  input Boolean finalPrefix;
  input DAE.ElementSource source "the origin of the element";
  input Boolean declareComplexVars "if true, declare variables for complex variables, e.g. record vars in functions";  
  output DAE.DAElist outDae;
algorithm 
  outDae := matchcontinue (inComponentRef,inState,inType,inAttributes,protection,inExpExpOption,
                                     inInstDims,inStartValue,inDAEVariableAttributesOption,inAbsynCommentOption,
                                     io,finalPrefix,source,declareComplexVars )
    local
      DAE.Flow flowPrefix1;
      DAE.Stream streamPrefix1;
      DAE.DAElist dae;
      DAE.ComponentRef vn;
      ClassInf.State ci_state;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      Boolean flowPrefix,streamPrefix,prot;
      SCode.Variability par;
      Absyn.Direction dir;
      Option<DAE.Exp> e,start;
      InstDims inst_dims;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
    case (vn,ci_state,ty,
          SCode.ATTR(flowPrefix = flowPrefix,
                     streamPrefix = streamPrefix,
                     variability = par,direction = dir),
          prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars )
      equation 
        flowPrefix1 = DAEUtil.toFlow(flowPrefix, ci_state);
        streamPrefix1 = DAEUtil.toStream(streamPrefix, ci_state);
        dae = daeDeclare2(vn, ty, flowPrefix1, streamPrefix1, par, dir,prot, e, inst_dims, start, dae_var_attr, comment,io,finalPrefix,source,declareComplexVars );
      then
        dae;
    case (_,_,_,_,_,_,_,_,_,_,_,_,source,_)
      equation 
        Debug.fprintln("failtrace", "- Inst.daeDeclare failed");
      then
        fail();
  end matchcontinue;
end daeDeclare;

protected function daeDeclare2 
"function: daeDeclare2  
  Helper function to daeDeclare."
  input DAE.ComponentRef inComponentRef;
  input DAE.Type inType;
  input DAE.Flow inFlow;
  input DAE.Stream inStream;  
  input SCode.Variability inVariability;
  input Absyn.Direction inDirection;
  input Boolean protection;
  input Option<DAE.Exp> inExpExpOption;
  input InstDims inInstDims;
  input DAE.StartValue inStartValue;
  input Option<DAE.VariableAttributes> inDAEVariableAttributesOption;
  input Option<SCode.Comment> inAbsynCommentOption;
	input Absyn.InnerOuter io;
	input Boolean finalPrefix;
	input DAE.ElementSource source "the origin of the element";
	input Boolean declareComplexVars;
  output DAE.DAElist outDae;
algorithm 
  outDae := matchcontinue (inComponentRef,inType,inFlow,inStream,inVariability,inDirection,protection,inExpExpOption,
                                     inInstDims,inStartValue,inDAEVariableAttributesOption,inAbsynCommentOption,io,finalPrefix,
                                     source,declareComplexVars)
    local
      DAE.DAElist dae;
      DAE.ComponentRef vn;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Absyn.Direction dir;
      Option<DAE.Exp> e,start;
      InstDims inst_dims;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      Boolean prot;
      
    case (vn,ty,flowPrefix,streamPrefix,SCode.VAR(),dir,prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars)
      equation 
        dae = daeDeclare3(vn, ty, flowPrefix, streamPrefix, DAE.VARIABLE(), dir,prot, e, inst_dims, start, dae_var_attr, comment,io,finalPrefix,source,declareComplexVars);
      then
        dae;
    case (vn,ty,flowPrefix,streamPrefix,SCode.DISCRETE(),dir,prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars )
      equation 
        dae = daeDeclare3(vn, ty, flowPrefix, streamPrefix, DAE.DISCRETE(), dir,prot, e, inst_dims, start, dae_var_attr, comment,io,finalPrefix,source,declareComplexVars );
      then
        dae;
    case (vn,ty,flowPrefix,streamPrefix,SCode.PARAM(),dir,prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars )
      equation 
        dae = daeDeclare3(vn, ty, flowPrefix, streamPrefix, DAE.PARAM(), dir,prot, e, inst_dims, start, dae_var_attr, comment,io,finalPrefix,source,declareComplexVars );
      then
        dae;
    case (vn,ty,flowPrefix,streamPrefix,SCode.CONST(),dir,prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars )
      equation 
        dae = daeDeclare3(vn, ty, flowPrefix, streamPrefix,DAE.CONST(), dir,prot, e, inst_dims, start, dae_var_attr, comment,io,finalPrefix,source,declareComplexVars );
      then
        dae;
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,source,_)
      equation 
        Debug.fprintln("failtrace", "- Inst.daeDeclare2 failed");
      then
        fail();
  end matchcontinue;
end daeDeclare2;

protected function daeDeclare3 
"function: daeDeclare3  
  Helper function to daeDeclare2."
  input DAE.ComponentRef inComponentRef;
  input DAE.Type inType;
  input DAE.Flow inFlow;
  input DAE.Stream inStream;  
  input DAE.VarKind inVarKind;
  input Absyn.Direction inDirection;
  input Boolean protection;
  input Option<DAE.Exp> inExpExpOption;
  input InstDims inInstDims;
  input DAE.StartValue inStartValue;
  input Option<DAE.VariableAttributes> inDAEVariableAttributesOption;
  input Option<SCode.Comment> inAbsynCommentOption;
  input Absyn.InnerOuter io;
  input Boolean finalPrefix;
  input DAE.ElementSource source "the origin of the element";
  input Boolean declareComplexVars;
  output DAE.DAElist outDae;
algorithm 
  outDae := matchcontinue (inComponentRef,inType,inFlow,inStream,inVarKind,inDirection,protection,inExpExpOption,inInstDims,
                                     inStartValue,inDAEVariableAttributesOption,inAbsynCommentOption,io,finalPrefix,source,declareComplexVars)
    local
      DAE.DAElist dae;
      DAE.ComponentRef vn;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Flow fl;
      DAE.Stream st;
      DAE.VarKind vk;
      Option<DAE.Exp> e,start;
      InstDims inst_dims;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      Boolean prot;
      DAE.VarProtection prot1;
    case (vn,ty,fl,st,vk,Absyn.INPUT(),prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars)
      equation 
        prot1 = makeDaeProt(prot);
        dae = daeDeclare4(vn, ty, fl, st, vk, DAE.INPUT(),prot1, e, inst_dims, start, dae_var_attr, comment,io,finalPrefix,source,declareComplexVars);
      then
        dae;
    case (vn,ty,fl,st,vk,Absyn.OUTPUT(),prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars)
      equation 
        prot1 = makeDaeProt(prot);
        dae = daeDeclare4(vn, ty, fl, st, vk, DAE.OUTPUT(),prot1, e, inst_dims, start, dae_var_attr, comment,io,finalPrefix,source,declareComplexVars);
      then
        dae;
    case (vn,ty,fl,st,vk,Absyn.BIDIR(),prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars)
      equation 
        prot1 = makeDaeProt(prot);
        dae = daeDeclare4(vn, ty, fl, st, vk, DAE.BIDIR(),prot1, e, inst_dims, start, dae_var_attr, comment,io,finalPrefix,source,declareComplexVars);
      then
        dae;
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,source,_)
      equation 
        //Debug.fprintln("failtrace", "- Inst.daeDeclare3 failed");
      then
        fail();
  end matchcontinue;
end daeDeclare3;

protected function makeDaeProt 
"Creates a DAE.VarProtection from a Boolean"
 input Boolean prot;
 output DAE.VarProtection res;
algorithm
  res := Util.if_(prot,DAE.PROTECTED(),DAE.PUBLIC());
end makeDaeProt;

protected function daeDeclare4 
"function: daeDeclare4  
  Helper function to daeDeclare3."
  input DAE.ComponentRef inComponentRef;
  input DAE.Type inType;
  input DAE.Flow inFlow;
  input DAE.Stream inStream;  
  input DAE.VarKind inVarKind;
  input DAE.VarDirection inVarDirection;
  input DAE.VarProtection protection;
  input Option<DAE.Exp> inExpExpOption;
  input InstDims inInstDims;
  input DAE.StartValue inStartValue;
  input Option<DAE.VariableAttributes> inDAEVariableAttributesOption;
  input Option<SCode.Comment> inAbsynCommentOption;
  input Absyn.InnerOuter io;
  input Boolean finalPrefix;
  input DAE.ElementSource source "the origin of the element";
  input Boolean declareComplexVars;
  output DAE.DAElist outDAe;
algorithm 
  outDAe :=
  matchcontinue (inComponentRef,inType,inFlow,inStream,inVarKind,inVarDirection,protection,inExpExpOption,inInstDims,
                 inStartValue,inDAEVariableAttributesOption,inAbsynCommentOption,io,finalPrefix,source,declareComplexVars)
    local
      DAE.ComponentRef vn,c;
      DAE.Flow fl;
      DAE.Stream st;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      Option<DAE.Exp> e,start;
      InstDims inst_dims;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      list<String> l;
      DAE.DAElist dae;
      ClassInf.State ci;
      tuple<DAE.TType, Option<Absyn.Path>> tp,ty;
      Integer dim;
      String s;
      DAE.Type ty;
      DAE.VarProtection prot;
      list<DAE.Subscript> finst_dims;
      DAE.FunctionTree funcs;

    case (vn,ty as(DAE.T_INTEGER(varLstInt = _),_),fl,st,kind,dir,prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars) 
      equation 
        finst_dims = Util.listFlatten(inst_dims);
        dae_var_attr = DAEUtil.setFinalAttr(dae_var_attr,finalPrefix);
        funcs = DAEUtil.avlTreeNew();
      then DAE.DAE({DAE.VAR(vn,kind,dir,prot,DAE.T_INTEGER_DEFAULT,e,finst_dims,fl,st,source,dae_var_attr,comment,io)},funcs);
         
    case (vn,ty as(DAE.T_REAL(varLstReal = _),_),fl,st,kind,dir,prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars)
      equation 
        finst_dims = Util.listFlatten(inst_dims);
        dae_var_attr = DAEUtil.setFinalAttr(dae_var_attr,finalPrefix);
        funcs = DAEUtil.avlTreeNew();
      then DAE.DAE({DAE.VAR(vn,kind,dir,prot,DAE.T_REAL_DEFAULT,e,finst_dims,fl,st,source,dae_var_attr,comment,io)},funcs);
         
    case (vn,ty as(DAE.T_BOOL(varLstBool = _),_),fl,st,kind,dir,prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars) 
      equation 
        finst_dims = Util.listFlatten(inst_dims);
        dae_var_attr = DAEUtil.setFinalAttr(dae_var_attr,finalPrefix);
        funcs = DAEUtil.avlTreeNew();
      then DAE.DAE({DAE.VAR(vn,kind,dir,prot,DAE.T_BOOL_DEFAULT,e,finst_dims,fl,st,source,dae_var_attr,comment,io)},funcs);
         
    case (vn,ty as(DAE.T_STRING(varLstString = _),_),fl,st,kind,dir,prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars) 
      equation 
        finst_dims = Util.listFlatten(inst_dims);
        dae_var_attr = DAEUtil.setFinalAttr(dae_var_attr,finalPrefix);
        funcs = DAEUtil.avlTreeNew();
      then DAE.DAE({DAE.VAR(vn,kind,dir,prot,DAE.T_STRING_DEFAULT,e,finst_dims,fl,st,source,dae_var_attr,comment,io)},funcs);
         
    case (vn,ty as(DAE.T_ENUMERATION(SOME(_),_,_,_),_),fl,st,kind,dir,prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars) 
    then DAEUtil.emptyDae; 
//    case (vn,ty as(DAE.T_ENUM(),_),fl,st,kind,dir,prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars) then {}; 

    /* We should not declare each enumeration value of an enumeration when instantiating,
  	 * e.g Myenum my !=> constant EnumType my.enum1,... {DAE.VAR(vn, kind, dir, DAE.ENUM, e, inst_dims)} 
  	 * instantiation of complex type extending from basic type 
     */ 
    case (vn,ty as(DAE.T_ENUMERATION(names = l),_),fl,st,kind,dir,prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars)
      equation 
        finst_dims = Util.listFlatten(inst_dims);
        dae_var_attr = DAEUtil.setFinalAttr(dae_var_attr,finalPrefix);
        funcs = DAEUtil.avlTreeNew();
      then DAE.DAE({DAE.VAR(vn,kind,dir,prot,ty,e,finst_dims,fl,st,source,dae_var_attr,comment,io)},funcs);  

          /* Complex type that is ExternalObject*/
     case (vn, ty as (DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path)),_),fl,st,kind,dir,prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars)
       local Absyn.Path path;
       equation 
         finst_dims = Util.listFlatten(inst_dims);
         dae_var_attr = DAEUtil.setFinalAttr(dae_var_attr,finalPrefix);
         funcs = DAEUtil.avlTreeNew();
       then DAE.DAE({DAE.VAR(vn,kind,dir,prot,ty,e,finst_dims,fl,st,source,dae_var_attr,comment,io)},funcs);
            
      /* instantiation of complex type extending from basic type */ 
    case (vn,(DAE.T_COMPLEX(complexClassType = ci,complexTypeOption = SOME(tp)),_),fl,st,kind,dir,prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars)
      equation
        (_,dae_var_attr) = instDaeVariableAttributes(Env.emptyCache(),Env.emptyEnv, DAE.NOMOD(), tp, {});
        dae_var_attr = DAEUtil.setFinalAttr(dae_var_attr,finalPrefix);
        dae = daeDeclare4(vn,tp,fl,st,kind,dir,prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars);
    then dae;
		
		/* Array that extends basic type */          
    case (vn,(DAE.T_ARRAY(arrayDim = DAE.DIM(integerOption = SOME(dim)),arrayType = tp),_),fl,st,kind,dir,prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars)
      equation 
        dae = daeDeclare4(vn, tp, fl, st, kind, dir, prot,e, inst_dims, start, dae_var_attr,comment,io,finalPrefix,source,declareComplexVars);
      then dae;

    /* Report an error */
    case (vn,(DAE.T_ARRAY(arrayDim = DAE.DIM(integerOption = NONE),arrayType = tp),_),fl,st,kind,dir,prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars)
      equation 
        s = Exp.printComponentRefStr(vn);
        Error.addMessage(Error.DIMENSION_NOT_KNOWN, {s});
      then
        fail();
        
        /* Complex/Record components, only if declareComplexVars is true */
    case(vn,ty as (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)),_),fl,st,kind,dir,prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,true)
      equation
        finst_dims = Util.listFlatten(inst_dims);
        funcs = DAEUtil.avlTreeNew();
      then DAE.DAE({DAE.VAR(vn,kind,dir,prot,ty,e,finst_dims,fl,st,source,dae_var_attr,comment,io)},funcs);
     
    /* MetaModelica extensions */
    case (vn,(tty as DAE.T_FUNCTION(_,_,_),_),fl,st,kind,dir,prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars)
      local
        DAE.TType tty;
        Absyn.Path path;
      equation
        finst_dims = Util.listFlatten(inst_dims);
        dae_var_attr = DAEUtil.setFinalAttr(dae_var_attr,finalPrefix);
        path = Exp.crefToPath(vn);
        ty = (tty,SOME(path));
        funcs = DAEUtil.avlTreeNew();
      then DAE.DAE({DAE.VAR(vn,kind,dir,prot,ty,e,finst_dims,fl,st,source,dae_var_attr,comment,io)},funcs);
    
    // MetaModelica extension
    case (vn,ty,fl,st,kind,dir,prot,e,inst_dims,start,dae_var_attr,comment,io,finalPrefix,source,declareComplexVars)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        true = Types.isBoxedType(ty);
        finst_dims = Util.listFlatten(inst_dims);
        dae_var_attr = DAEUtil.setFinalAttr(dae_var_attr,finalPrefix);      
        funcs = DAEUtil.avlTreeNew();      
      then DAE.DAE({DAE.VAR(vn,kind,dir,prot,ty,e,finst_dims,fl,st,source,dae_var_attr,comment,io)},funcs);
    /*----------------------------*/
    
    case (c,ty,_,_,_,_,_,_,_,_,_,_,_,_,source,_) then DAEUtil.emptyDae; 
  end matchcontinue;
end daeDeclare4;

protected function instEquation 
"function instEquation
  author: LS, ELN
   
  Instantiates an equation by calling 
  instEquationCommon with Inital set 
  to NON_INITIAL."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.Equation inEquation;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph) := 
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEquation,inBoolean,inGraph)
    local
      list<Env.Frame> env_1,env;
      DAE.DAElist dae;
      Connect.Sets csets_1,csets;
      ClassInf.State ci_state_1,ci_state;
      DAE.Mod mods;
      Prefix.Prefix pre;
      SCode.EEquation eq;
      SCode.OptBaseClass bc;
      Boolean impl;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      
    case (cache,env,ih,mods,pre,csets,ci_state,SCode.EQUATION(eEquation = eq,baseClassPath = bc),impl,graph) /* impl */ 
      equation 
        (cache,env_1,ih) = getDerivedEnv(cache,env,ih, bc) "Equation inherited from base class" ;
        (cache,_,ih,dae,csets_1,ci_state_1,graph) = 
                   instEquationCommon(cache,env_1,ih, mods, pre, csets, ci_state, eq, SCode.NON_INITIAL(), impl,graph);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);
        
    case (_,_,_,_,_,_,_,SCode.EQUATION(eEquation = eqn),impl,graph)
      local SCode.EEquation eqn; String str;
      equation 
				true = RTOpts.debugFlag("failtrace");
        str= SCode.equationStr(eqn);
        Debug.fprint("failtrace", "- instEquation failed eqn:");
        Debug.fprint("failtrace", str);
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end instEquation;

protected function instEEquation 
"function: instEEquation 
  Instantiation of EEquation, used in for loops and if-equations."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.EEquation inEEquation;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache cache;
  output Env outEnv;
  output InstanceHierarchy outIH;  
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outDae,outSets,outState, outGraph) :=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEEquation,inBoolean,inGraph)
    local
      DAE.DAElist dae;
      Connect.Sets csets_1,csets;
      ClassInf.State ci_state_1,ci_state;
      list<Env.Frame> env;
      DAE.Mod mods;
      Prefix.Prefix pre;
      SCode.EEquation eq;
      Boolean impl;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      
    case (cache,env,ih,mods,pre,csets,ci_state,eq,impl,graph) /* impl */ 
      equation 
        (cache,_,ih,dae,csets_1,ci_state_1,graph) = 
        instEquationCommon(cache,env,ih, mods, pre, csets, ci_state, eq, SCode.NON_INITIAL(), impl, graph);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);
  end matchcontinue;
end instEEquation;

protected function instInitialequation 
"function: instInitialequation
  author: LS, ELN 
  Instantiates initial equation by calling inst_equation_common with Inital 
  set to INITIAL."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.Equation inEquation;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDAe;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEquation,inBoolean,inGraph)
    local
      list<Env.Frame> env_1,env;
      DAE.DAElist dae;
      Connect.Sets csets_1,csets;
      ClassInf.State ci_state_1,ci_state;
      DAE.Mod mods;
      Prefix.Prefix pre;
      SCode.EEquation eq;
      SCode.OptBaseClass bc;
      Boolean impl;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      
    case (cache,env,ih,mods,pre,csets,ci_state,SCode.EQUATION(eEquation = eq,baseClassPath = bc),impl,graph) /* impl */ 
      equation 
        (cache,env_1,ih) = getDerivedEnv(cache,env,ih, bc) "Equation inherited from base class" ;
        (cache,_,ih,dae,csets_1,ci_state_1,graph) = instEquationCommon(cache,env_1,ih, mods, pre, csets, ci_state, eq, SCode.INITIAL(), impl, graph);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);
        
    case (_,_,ih,_,_,_,_,_,impl,_)
      equation 
        Debug.fprint("failtrace", "- instInitialequation failed\n");
      then
        fail();
  end matchcontinue;
end instInitialequation;

protected function instEInitialequation 
"function: instEInitialequation 
  Instantiates initial EEquation used in for loops and if equations "
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.EEquation inEEquation;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEEquation,inBoolean,inGraph)
    local
      DAE.DAElist dae;
      Connect.Sets csets_1,csets;
      ClassInf.State ci_state_1,ci_state;
      list<Env.Frame> env;
      DAE.Mod mods;
      Prefix.Prefix pre;
      SCode.EEquation eq;
      Boolean impl;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      
    case (cache,env,ih,mods,pre,csets,ci_state,eq,impl,graph) /* impl */ 
      equation 
        (cache,_,ih,dae,csets_1,ci_state_1,graph) = instEquationCommon(cache,env,ih, mods, pre, csets, ci_state, eq, SCode.INITIAL(), impl, graph);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);
  end matchcontinue;
end instEInitialequation;

protected function instEquationCommon 
"function: instEquationCommon 
  The DAE output of the translation contains equations which
  in most cases directly corresponds to equations in the source.
  Some of them are also generated from `connect\' clauses.
 
  This function takes an equation from the source and generates DAE
  equations and connection sets."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.EEquation inEEquation;
  input SCode.Initial inInitial;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEEquation,inInitial,inBoolean,inGraph)
    local
      list<DAE.Properties> props;
      Connect.Sets csets_1,csets;
      DAE.DAElist dae,dae1,dae2,dae3;
      list<DAE.DAElist> dael;
      ClassInf.State ci_state_1,ci_state,ci_state_2;
      list<Env.Frame> env,env_1,env_2;
      DAE.Mod mods,mod;
      Prefix.Prefix pre;
      Absyn.ComponentRef c1,c2,cr;
      SCode.Initial initial_;
      Boolean impl,cond;
      String n,i,s;
      Absyn.Exp e2,e1,e,ee;
      list<Absyn.Exp> conditions;
      DAE.Exp e1_1,e2_1,e1_2,e2_2,e_1,e_2;
      DAE.Properties prop1,prop2;
      list<SCode.EEquation> b,tb1,fb,el,eel;
      list<list<SCode.EEquation>> tb; 
      list<tuple<Absyn.Exp, list<SCode.EEquation>>> eex;
      tuple<DAE.TType, Option<Absyn.Path>> id_t;
      Values.Value v;
      DAE.ComponentRef cr_1;
      SCode.EEquation eqn,eq;
      Env.Cache cache;
      list<Values.Value> valList;
      list<DAE.Exp> expl1;
      list<Boolean> blist;
      Absyn.ComponentRef arrName;
      list<Absyn.Ident> idList;
      Absyn.Exp itExp;
      Absyn.ForIterators rangeIdList;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      list<tuple<Absyn.ComponentRef, Integer>> lst;
      tuple<Absyn.ComponentRef, Integer> tpl;
      DAE.ElementSource source "the origin of the element";
      list<DAE.Element> daeElts1,daeElts2;
      list<list<DAE.Element>> daeLLst;
      DAE.DAElist fdae,fdae1,fdae11,fdae2,fdae3;
      DAE.FunctionTree funcs;
    /* connect statements */
    case (cache,env,ih,mods,pre,csets,ci_state,SCode.EQ_CONNECT(crefLeft = c1,crefRight = c2),initial_,impl,graph) 
      equation 
        (cache,_,ih,csets_1,dae,graph) = instConnect(cache, env, ih, csets,  pre, c1, c2, impl, graph);
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);
        
        //------------------------------------------------------
        // Part of the MetaModelica extension
        /* equality equations cref = array(...) */
        // Should be removed??
        // case (cache,env,ih,mods,pre,csets,ci_state,SCode.EQ_EQUALS(e1 as Absyn.CREF(cr),Absyn.ARRAY(expList)),initial_,impl)
        //   local Option<Interactive.InteractiveSymbolTable> c1,c2;
        //     list<Absyn.Exp> expList;
        //    Absyn.ComponentRef cr;
        //     DAE.Properties cprop;
        //   equation
        //     true = RTOpts.acceptMetaModelicaGrammar();
        // If this is a list assignment, then the Absyn.ARRAY expression should
        // be evaluated to DAE.LIST
        //   (cache,_,cprop,_) = Static.elabCref(cache,env, cr, impl,false);
        //   true = MetaUtil.isList(cprop);
        // Do static analysis and constant evaluation of expressions.
        // Gives expression and properties
	      // (Type  bool | (Type  Const as (bool | Const list))).
	      // For a function, it checks the funtion name.
	      // Also the function call\'s in parameters are type checked with
	      // the functions definition\'s inparameters. This is done with
	      // regard to the position of the input arguments.
        // Returns the output parameters from the function.
        // (cache,e1_1,prop1,c1) = Static.elabExp(cache,env, e1, impl, NONE,true /*do vectorization*/);
        // (cache,e2_1,prop2,c2) = Static.elabListExp(cache,env, expList, cprop, impl, NONE,true/* do vectorization*/);
        // (cache,e1_1,e2_1) = condenseArrayEquation(cache,env,e1,e2,e1_1,e2_1,prop1,impl);
        //  (cache,e1_2) = PrefixUtil.prefixExp(cache,env, e1_1, pre);
        //  (cache,e2_2) = PrefixUtil.prefixExp(cache,env, e2_1, pre);
        // Check that the lefthandside and the righthandside get along.
        // dae = instEqEquation(e1_2, prop1, e2_2, prop2, initial_, impl);
        // ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
        // then
        // (cache,env,ih,dae,csets,ci_state_1);
        //------------------------------------------------------

    /* v = array(For-constructor)  */
    case (cache,env,ih,mods,pre,csets,ci_state,SCode.EQ_EQUALS(Absyn.CREF(arrName),
     //  Absyn.CALL(Absyn.CREF_IDENT("array",{}),Absyn.FOR_ITER_FARG(itExp,id,e2))),initial_,impl)
         Absyn.CALL(Absyn.CREF_IDENT("array",{}),Absyn.FOR_ITER_FARG(itExp,rangeIdList)),_),initial_,impl,graph)
      equation
        // rangeIdList = {(id,e2)};
        idList = extractLoopVars(rangeIdList,{});
        // Transform this function call into a number of nested for-loops
        (eq,dae1) = createForIteratorEquations(itExp,rangeIdList,idList,arrName);
        (cache,env,ih,dae2,csets_1,ci_state_1,graph) = instEquationCommon(cache,env,ih,mods,pre,csets,ci_state,eq,initial_,impl,graph);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);
        
    /* equality equations e1 = e2 */
    case (cache,env,ih,mods,pre,csets,ci_state,SCode.EQ_EQUALS(expLeft = e1,expRight = e2),initial_,impl,graph)
      local Option<Interactive.InteractiveSymbolTable> c1,c2;
      equation 
	 			// Do static analysis and constant evaluation of expressions. 
			  // Gives expression and properties 
	      // (Type  bool | (Type  Const as (bool | Const list))).
	      // For a function, it checks the funtion name. 
	      // Also the function call\'s in parameters are type checked with
	      // the functions definition\'s inparameters. This is done with
	      // regard to the position of the input arguments.

        //  Returns the output parameters from the function.
        (cache,e1_1,prop1,c1,fdae1) = Static.elabExp(cache,env, e1, impl, NONE,true /*do vectorization*/); 
        (cache,e2_1,prop2,c2,fdae2) = Static.elabExp(cache,env, e2, impl, NONE,true/* do vectorization*/);
        (cache,e1_1,e2_1,prop1,fdae3) = condenseArrayEquation(cache,env,e1,e2,e1_1,e2_1,prop1,prop2,impl);
        (cache,e1_2) = PrefixUtil.prefixExp(cache,env, e1_1, pre);
        (cache,e2_2) = PrefixUtil.prefixExp(cache,env, e2_1, pre);
        
        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        //Check that the lefthandside and the righthandside get along.
        dae = instEqEquation(e1_2, prop1, e2_2, prop2, source, initial_, impl);
        dae = DAEUtil.joinDaeLst({dae,fdae1,fdae2,fdae3});
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
      then
        (cache,env,ih,dae,csets,ci_state_1,graph);

    /* if-equation	 	    
	     If the condition is constant this case will select the correct branch and remove the if-equation*/ 
     
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_IF(condition = conditions,thenBranch = tb,elseBranch = fb),SCode.NON_INITIAL(),impl,graph)
      equation 
        (cache, expl1,props,_,fdae1) = Static.elabExpList(cache,env, conditions, impl, NONE,true);
        (DAE.PROP((DAE.T_BOOL(_),_),_)) = Types.propsAnd(props);
        (cache,valList) = Ceval.cevalList(cache,env, expl1, impl, NONE, Ceval.NO_MSG());
        blist = Util.listMap(valList,ValuesUtil.valueBool);
        b = selectList(blist, tb, fb);
        (cache,env_1,ih,dae,csets_1,ci_state_1,graph) = instList(cache,env,ih, mod, pre, csets, ci_state, instEEquation, b, impl, graph);
        dae = DAEUtil.joinDaes(dae,fdae1);
      then
        (cache,env_1,ih,dae,csets_1,ci_state_1,graph);

    /* initial if-equation 
    If the condition is constant this case will select the correct branch and remove the initial if-equation */ 
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_IF(condition = conditions,thenBranch = tb,elseBranch = fb),SCode.INITIAL(),impl,graph) 
      equation 
        (cache, expl1,props,_,fdae1) = Static.elabExpList(cache,env, conditions, impl, NONE,true);
        (DAE.PROP((DAE.T_BOOL(_),_),_)) = Types.propsAnd(props);
        (cache,valList) = Ceval.cevalList(cache,env, expl1, impl, NONE, Ceval.NO_MSG());
        blist = Util.listMap(valList,ValuesUtil.valueBool);
        b = selectList(blist, tb, fb);
        (cache,env_1,ih,dae,csets_1,ci_state_1,graph) = instList(cache,env,ih, mod, pre, csets, ci_state, instEInitialequation, b, impl,graph);
        dae = DAEUtil.joinDaes(dae,fdae1);
      then
        (cache,env_1,ih,dae,csets_1,ci_state_1,graph);

        // IF_EQUATION when condition is not constant 
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_IF(condition = conditions,thenBranch = tb,elseBranch = fb),SCode.NON_INITIAL(),impl,graph)
      equation 
        (cache, expl1,props,_,fdae1) = Static.elabExpList(cache,env, conditions, impl, NONE,true);
        (DAE.PROP((DAE.T_BOOL(_),_),DAE.C_VAR())) = Types.propsAnd(props);
        (cache,expl1) = PrefixUtil.prefixExpList(cache,env, expl1, pre);
        
        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        (cache,env_1,ih,daeLLst,_,ci_state_1,graph) = instIfTrueBranches(cache,env,ih, mod, pre, csets, ci_state,tb, false, impl,graph);
        (cache,env_2,ih,DAE.DAE(daeElts2,_),_,ci_state_2,graph) = instList(cache,env_1,ih, mod, pre, csets, ci_state, instEEquation, fb, impl,graph) "There are no connections inside if-clauses." ;
        funcs = DAEUtil.avlTreeNew();
        dae = DAEUtil.joinDaes(DAE.DAE({DAE.IF_EQUATION(expl1,daeLLst,daeElts2,source)},funcs),fdae1); 
      then
        (cache,env_1,ih,dae,csets,ci_state_1,graph);

        // Initial IF_EQUATION  when condition is not constant
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_IF(condition = conditions,thenBranch = tb,elseBranch = fb),SCode.INITIAL(),impl,graph)
      equation 
        (cache, expl1,props,_,fdae1) = Static.elabExpList(cache,env, conditions, impl, NONE,true);
        (DAE.PROP((DAE.T_BOOL(_),_),DAE.C_VAR())) = Types.propsAnd(props);
        (cache,expl1) = PrefixUtil.prefixExpList(cache,env, expl1, pre);

        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        (cache,env_1,ih,daeLLst,_,ci_state_1,graph) = instIfTrueBranches(cache,env,ih, mod, pre, csets, ci_state, tb, true, impl,graph);
        (cache,env_2,ih,DAE.DAE(daeElts2,_),_,ci_state_2,graph) = instList(cache,env_1,ih, mod, pre, csets, ci_state, instEInitialequation, fb, impl,graph) "There are no connections inside if-clauses." ;
        funcs = DAEUtil.avlTreeNew(); /* No functions instantiated from equation sections */
        dae = DAEUtil.joinDaes(DAE.DAE({DAE.INITIAL_IF_EQUATION(expl1,daeLLst,daeElts2,source)},funcs),fdae1);
      then
        (cache,env_1,ih,dae,csets,ci_state_1,graph);

        /* `when equation\' statement, modelica 1.1 
         When statements are instantiated by evaluating the
         conditional expression.
         */ 
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_WHEN(condition = e,eEquationLst = el,tplAbsynExpEEquationLstLst = ((ee,eel) :: eex)),(initial_ as SCode.NON_INITIAL()),impl,graph) 
      local DAE.Element daeElt2; list<DAE.ComponentRef> lhsCrefs,lhsCrefsRec; Integer i1; list<DAE.Element> daeElts3;
      equation 
        (cache,e_1,_,_,fdae1) = Static.elabExp(cache,env, e, impl, NONE,true);
        (cache,e_2) = PrefixUtil.prefixExp(cache,env, e_1, pre);

        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        (cache,env_1,ih,DAE.DAE(daeElts1,_),_,_,graph) = instList(cache,env,ih, mod, pre, csets, ci_state, instEEquation, el, impl, graph);
        lhsCrefs = DAEUtil.verifyWhenEquation(daeElts1);
        (cache,env_2,ih,DAE.DAE(daeElts3 as (daeElt2 :: _),funcs),_,ci_state_1,graph) = instEquationCommon(cache,env_1,ih, mod, pre, csets, ci_state, 
          SCode.EQ_WHEN(ee,eel,eex,NONE), initial_, impl, graph);
        lhsCrefsRec = DAEUtil.verifyWhenEquation(daeElts3);
        i1 = listLength(lhsCrefs);
        lhsCrefs = Util.listUnionOnTrue(lhsCrefs,lhsCrefsRec,Exp.crefEqual);
        //TODO: fix error reporting print(" listLength pre:" +& intString(i1) +& " post: " +& intString(listLength(lhsCrefs)) +& "\n");
        true = intEq(listLength(lhsCrefs),i1);
        ci_state_2 = instEquationCommonCiTrans(ci_state_1, initial_);
        funcs = DAEUtil.avlTreeNew(); 
        dae = DAEUtil.joinDaes(DAE.DAE({DAE.WHEN_EQUATION(e_2,daeElts1,SOME(daeElt2),source)},funcs),fdae1);
      then
        (cache,env_2,ih,dae,csets,ci_state_2,graph);
        
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_WHEN(condition = e,eEquationLst = el,tplAbsynExpEEquationLstLst = {}),(initial_ as SCode.NON_INITIAL()),impl,graph)
      local list<DAE.ComponentRef> lhsCrefs; 
      equation 
        (cache,e_1,_,_,fdae1) = Static.elabExp(cache,env, e, impl, NONE,true);
        (cache,e_2) = PrefixUtil.prefixExp(cache,env, e_1, pre);

        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        (cache,env_1,ih,DAE.DAE(daeElts1,funcs),_,_,graph) = instList(cache,env,ih, mod, pre, csets, ci_state, instEEquation, el, impl, graph);
        lhsCrefs = DAEUtil.verifyWhenEquation(daeElts1);
        //TODO: fix error reporting, print(" exps: " +& Util.stringDelimitList(Util.listMap(lhsCrefs,Exp.printComponentRefStr),", ") +& "\n");
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
        dae = DAEUtil.joinDaes(DAE.DAE({DAE.WHEN_EQUATION(e_2,daeElts1,NONE,source)},funcs),fdae1);
      then
        (cache,env_1,ih,dae,csets,ci_state_1,graph);


/* seems unnecessary to handle when equations that are initial `for\' loops
	  The loop expression is evaluated to a constant array of
	  integers, and then the loop is unrolled.	 
          FIXME: Why lookup after add_for_loop_scope ?
	 */ 

    // adrpo: handle the case where range is a enumeration!
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_FOR(index = i,range = Absyn.CREF(cr),eEquationLst = el),initial_,impl,graph)
      local 
        Absyn.ComponentRef cr;
        Absyn.Path typePath;
        Integer len;
        list<SCode.Element> elementLst;
        list<Values.Value> vals;
      equation 
        typePath = Absyn.crefToPath(cr);
        // make sure is an enumeration!
        (_, SCode.CLASS(restriction = SCode.R_ENUMERATION(), classDef = SCode.PARTS(elementLst, {}, {}, {}, {}, _, _, _)), _) = 
             Lookup.lookupClass(cache, env, typePath, false);
        len = listLength(elementLst);        
        env_1 = addForLoopScope(env, i, DAE.T_INTEGER_DEFAULT);
        (cache,DAE.ATTR(false,false,SCode.RW(),SCode.VAR(),_,_),(DAE.T_INTEGER(_),_),DAE.UNBOUND(),_,_) 
        = Lookup.lookupVar(cache,env_1, DAE.CREF_IDENT(i,DAE.ET_OTHER(),{}));
        vals = Ceval.cevalRange(1,1,len);
        (cache,dae,csets_1,graph) = unroll(cache,env_1, mod, pre, csets, ci_state, i, Values.ARRAY(vals,{len}), el, initial_, impl,graph);
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);
    // Frenkel TUD: enumeration again 
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_FOR(index = i,range = Absyn.CREF(cr),eEquationLst = el),initial_,impl,graph)
      local 
        Absyn.ComponentRef cr;
        Absyn.Path typePath;
        Integer len;
        list<SCode.Enum> enumLst;
        list<Values.Value> vals;
      equation 
        typePath = Absyn.crefToPath(cr);
        // make sure is an enumeration! 
        (_, SCode.CLASS(restriction = SCode.R_TYPE(), classDef = SCode.ENUMERATION(enumLst = enumLst)), _) = 
             Lookup.lookupClass(cache, env, typePath, false);
        len = listLength(enumLst);        
        env_1 = addForLoopScope(env, i, DAE.T_INTEGER_DEFAULT);
        (cache,DAE.ATTR(false,false,SCode.RW(),SCode.VAR(),_,_),(DAE.T_INTEGER(_),_),DAE.UNBOUND(),_,_) 
        = Lookup.lookupVar(cache,env_1, DAE.CREF_IDENT(i,DAE.ET_OTHER(),{}));
        vals = Ceval.cevalRange(1,1,len);
        (cache,dae,csets_1,graph) = unroll(cache,env_1, mod, pre, csets, ci_state, i, Values.ARRAY(vals,{len}), el, initial_, impl,graph);
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);
    // Implicit range
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_FOR(index = i,range = Absyn.END(),eEquationLst = el),initial_,impl,graph)  
      equation 
        lst=SCode.findIteratorInEEquationLst(i,el);
        equality(lst={});
        Error.addMessage(Error.IMPLICIT_ITERATOR_NOT_FOUND_IN_LOOP_BODY,{i});        
      then
        fail();
        
        /* for i loop ... end for; NOTE: This construct is encoded as range being Absyn.END() */
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_FOR(index = i,range = Absyn.END(),eEquationLst = el),initial_,impl,graph) 
      equation 
        lst=SCode.findIteratorInEEquationLst(i,el);
        failure(equality(lst={}));
        tpl=Util.listFirst(lst);
        e=rangeExpression(tpl);
        (cache,e_1,DAE.PROP((DAE.T_ARRAY(DAE.DIM(_),id_t),_),_),_,fdae1) = Static.elabExp(cache,env, e, impl, NONE,true);
        env_1 = addForLoopScope(env, i, id_t);
        (cache,DAE.ATTR(false,false,SCode.RW(),SCode.VAR(),_,_),(DAE.T_INTEGER(_),_),DAE.UNBOUND(),_,_) 
        = Lookup.lookupVar(cache,env_1, DAE.CREF_IDENT(i,DAE.ET_OTHER(),{}));
        (cache,v,_) = Ceval.ceval(cache,env, e_1, impl, NONE, NONE, Ceval.MSG()) "FIXME: Check bounds" ;
        (cache,dae,csets_1,graph) = unroll(cache,env_1, mod, pre, csets, ci_state, i, v, el, initial_, impl,graph);
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
        dae = DAEUtil.joinDaes(dae,fdae1);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);

    /* for i in <expr> loop .. end for; */
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_FOR(index = i,range = e,eEquationLst = el),initial_,impl,graph) 
      equation 
        (cache,e_1,DAE.PROP((DAE.T_ARRAY(DAE.DIM(_),id_t),_),_),_,fdae1) = Static.elabExp(cache,env, e, impl, NONE,true);
        env_1 = addForLoopScope(env, i, id_t);
        (cache,DAE.ATTR(false,false,SCode.RW(),SCode.VAR(),_,_),(DAE.T_INTEGER(_),_),DAE.UNBOUND(),_,_) 
        = Lookup.lookupVar(cache,env_1, DAE.CREF_IDENT(i,DAE.ET_OTHER(),{}));
        (cache,v,_) = Ceval.ceval(cache,env, e_1, impl, NONE, NONE, Ceval.MSG()) "FIXME: Check bounds" ;
        (cache,dae,csets_1,graph) = unroll(cache,env_1, mod, pre, csets, ci_state, i, v, el, initial_, impl,graph);
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
        dae = DAEUtil.joinDaes(dae,fdae1);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);
        
      /* for i in <expr> loop .. end for; 
      where <expr> is not constant or parameter expression */  
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_FOR(index = i,range = e,eEquationLst = el),initial_,impl,graph)
      equation 
        (cache,DAE.ATTR(false,false,SCode.RW(),SCode.VAR(),_,_),(DAE.T_INTEGER(_),_),DAE.UNBOUND(),_,_) 
        	= Lookup.lookupVar(cache,env, DAE.CREF_IDENT(i,DAE.ET_OTHER(),{})) "for loops with non-constant iteration bounds" ;
        (cache,e_1,DAE.PROP((DAE.T_ARRAY(DAE.DIM(_),(DAE.T_INTEGER(_),_)),_),DAE.C_VAR()),_,_) 
        	= Static.elabExp(cache,env, e, impl, NONE,true);
        Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, 
          {"Non-constant iteration bounds","No suggestion"});
      then
        fail();
    /* assert statements*/
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_ASSERT(condition = e1,message= e2),initial_,impl,graph)
      equation 
        (cache,e1_1,DAE.PROP((DAE.T_BOOL(_),_),_),_,fdae1) = Static.elabExp(cache,env, e1, impl, NONE,true) "assert statement" ;
        (cache,e2_1,DAE.PROP((DAE.T_STRING(_),_),_),_,fdae2) = Static.elabExp(cache,env, e2, impl, NONE,true);
        (cache,e1_2) = PrefixUtil.prefixExp(cache,env, e1_1, pre);                
        (cache,e2_2) = PrefixUtil.prefixExp(cache,env, e2_1, pre); 

        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        funcs = DAEUtil.avlTreeNew();
        dae = DAEUtil.joinDaeLst({DAE.DAE({DAE.ASSERT(e1_2,e2_2,source)},funcs),fdae1,fdae2});
      then
        (cache,env,ih,dae,csets,ci_state,graph);

    /* terminate statements */
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_TERMINATE(message= e1),initial_,impl,graph)
      equation 
        (cache,e1_1,DAE.PROP((DAE.T_STRING(_),_),_),_,fdae1) = Static.elabExp(cache,env, e1, impl, NONE,true);
        (cache,e1_2) = PrefixUtil.prefixExp(cache,env, e1_1, pre);

        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        funcs = DAEUtil.avlTreeNew();
        dae = DAEUtil.joinDaes(DAE.DAE({DAE.TERMINATE(e1_2,source)},funcs),fdae1);
      then
        (cache,env,ih,dae,csets,ci_state,graph);

    /* reinit statement */
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_REINIT(cref = cr,expReinit = e2),initial_,impl,graph)
      local  DAE.DAElist trDae; list<DAE.Element> daeElts; 
        DAE.ComponentRef cr_2; DAE.ExpType t; DAE.Properties tprop1,tprop2;
        DAE.FunctionTree funcs;
      equation 
        (cache,e1_1,_,_,fdae1) = Static.elabExp(cache,env, Absyn.CREF(cr), impl, NONE,true);
        (cache,DAE.CREF(cr_1,t),tprop1,_,fdae11) = Static.elabCref(cache,env, cr, impl,false) "reinit statement" ;
        (cache,e2_1,tprop2,_,fdae2) = Static.elabExp(cache,env, e2, impl, NONE,true);
        (e2_1,_) = Types.matchProp(e2_1,tprop2,tprop1,true);
        (cache,e1_1,e2_1,tprop1,fdae2) = condenseArrayEquation(cache,env,Absyn.CREF(cr),e2,e1_1,e2_1,tprop1,tprop2,impl);
        (cache,e2_2) = PrefixUtil.prefixExp(cache,env, e2_1, pre);
        (cache,e1_2) = PrefixUtil.prefixExp(cache,env, e1_1, pre);

        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());

        DAE.DAE(daeElts,funcs) = instEqEquation(e1_2, tprop1, e2_2, tprop2, source, initial_, impl);
        daeElts = Util.listMap(daeElts,makeDAEArrayEqToReinitForm);
        dae = DAEUtil.joinDaeLst({DAE.DAE(daeElts,funcs), fdae1,fdae11,fdae2});
      then
        (cache,env,ih,dae,csets,ci_state,graph);
        
      /* Connections.root(cr) */  
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_NORETCALL(
              Absyn.CREF_QUAL("Connections", {}, Absyn.CREF_IDENT("root", {})),
              Absyn.FUNCTIONARGS({Absyn.CREF(cr)}, {}),_),initial_,impl,graph)
      local Absyn.ComponentRef cr; DAE.ComponentRef cr_; DAE.ExpType t; 
      equation 
        (cache,DAE.CREF(cr_,t),_,_,fdae) = Static.elabCref(cache,env, cr, false /* ??? */,false);
        cr_ = PrefixUtil.prefixCref(pre, cr_);
        graph = ConnectionGraph.addDefiniteRoot(graph, cr_);
      then
        (cache,env,ih,fdae,csets,ci_state,graph);    
            
      /* Connections.potentialRoot(cr) 
      TODO: Merge all cases for potentialRoot below using standard way of handling named/positional arguments and type conversion Integer->Real
      */     
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_NORETCALL(
              Absyn.CREF_QUAL("Connections", {}, Absyn.CREF_IDENT("potentialRoot", {})),
              Absyn.FUNCTIONARGS({Absyn.CREF(cr)}, {}),_),initial_,impl,graph)
      local Absyn.ComponentRef cr; DAE.ComponentRef cr_; DAE.ExpType t; 
      equation 
        (cache,DAE.CREF(cr_,t),_,_,fdae) = Static.elabCref(cache,env, cr, false /* ??? */,false);
        cr_ = PrefixUtil.prefixCref(pre, cr_);
        graph = ConnectionGraph.addPotentialRoot(graph, cr_, 0.0);
      then
        (cache,env,ih,fdae,csets,ci_state,graph);        
         
         /* Connections.potentialRoot(cr,priority =prio ) - priority as named argument */
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_NORETCALL(
              Absyn.CREF_QUAL("Connections", {}, Absyn.CREF_IDENT("potentialRoot", {})),
              Absyn.FUNCTIONARGS({Absyn.CREF(cr)}, {Absyn.NAMEDARG("priority", Absyn.REAL(priority))}),_),initial_,impl,graph)
      local Absyn.ComponentRef cr; DAE.ComponentRef cr_; DAE.ExpType t; Real priority;
      equation 
        (cache,DAE.CREF(cr_,t),_,_,fdae) = Static.elabCref(cache,env, cr, false /* ??? */,false);
        cr_ = PrefixUtil.prefixCref(pre, cr_);
        graph = ConnectionGraph.addPotentialRoot(graph, cr_, priority);
      then
        (cache,env,ih,fdae,csets,ci_state,graph);             

        /* Connections.potentialRoot(cr,priority) - priority as positional argument*/
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_NORETCALL(
              Absyn.CREF_QUAL("Connections", {}, Absyn.CREF_IDENT("potentialRoot", {})),
              Absyn.FUNCTIONARGS({Absyn.CREF(cr),Absyn.REAL(priority)}, {}),_),initial_,impl,graph)
      local Absyn.ComponentRef cr; DAE.ComponentRef cr_; DAE.ExpType t; Real priority;
      equation 
        (cache,DAE.CREF(cr_,t),_,_,fdae) = Static.elabCref(cache,env, cr, false /* ??? */,false);
        cr_ = PrefixUtil.prefixCref(pre, cr_);
        graph = ConnectionGraph.addPotentialRoot(graph, cr_, priority);
      then
        (cache,env,ih,fdae,csets,ci_state,graph);

        /* Connections.potentialRoot(cr,priority) - priority as Integer positinal argument*/
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_NORETCALL(
              Absyn.CREF_QUAL("Connections", {}, Absyn.CREF_IDENT("potentialRoot", {})),
              Absyn.FUNCTIONARGS({Absyn.CREF(cr),Absyn.INTEGER(priority)}, {}),_),initial_,impl,graph)
      local Absyn.ComponentRef cr; DAE.ComponentRef cr_; DAE.ExpType t; Integer priority;
      equation 
        (cache,DAE.CREF(cr_,t),_,_,fdae) = Static.elabCref(cache,env, cr, false /* ??? */,false);
        cr_ = PrefixUtil.prefixCref(pre, cr_);
        graph = ConnectionGraph.addPotentialRoot(graph, cr_, intReal(priority));
      then
        (cache,env,ih,fdae,csets,ci_state,graph);

        /*Connections.branch(cr1,cr2) */        
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_NORETCALL(
              Absyn.CREF_QUAL("Connections", {}, Absyn.CREF_IDENT("branch", {})),
              Absyn.FUNCTIONARGS({Absyn.CREF(cr1), Absyn.CREF(cr2)}, {}),_),initial_,impl,graph)
      local Absyn.ComponentRef cr1, cr2; DAE.ComponentRef cr1_, cr2_; DAE.ExpType t; 
      equation 
        (cache,DAE.CREF(cr1_,t),_,_,fdae1) = Static.elabCref(cache,env, cr1, false /* ??? */,false);
        (cache,DAE.CREF(cr2_,t),_,_,fdae2) = Static.elabCref(cache,env, cr2, false /* ??? */,false);
        cr1_ = PrefixUtil.prefixCref(pre, cr1_);
        cr2_ = PrefixUtil.prefixCref(pre, cr2_);
        graph = ConnectionGraph.addBranch(graph, cr1_, cr2_);
        fdae = DAEUtil.joinDaes(fdae1,fdae2);
      then
        (cache,env,ih,fdae,csets,ci_state,graph);
        
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_NORETCALL(cr,fargs,_),initial_,impl,graph)
      local DAE.ComponentRef cr_2; DAE.ExpType t; Absyn.Path path; list<DAE.Exp> expl; Absyn.FunctionArgs fargs;
        DAE.Exp exp;
      equation 
        (cache,exp,_,_,fdae1) = Static.elabExp(cache,env,Absyn.CALL(cr,fargs),impl,NONE,false);
        (cache,exp) = PrefixUtil.prefixExp(cache,env,exp,pre);

        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        dae = instEquationNoRetCallVectorization(exp,source);
        dae = DAEUtil.joinDaes(dae, fdae1);
      then
        (cache,env,ih,dae,csets,ci_state,graph);
               
    case (_,env,ih,_,_,_,_,eqn,_,impl,graph) 
      equation 
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "- instEquationCommon failed for eqn: ");
        s = SCode.equationStr(eqn);
        Debug.fprint("failtrace", s +& " in scope:" +& Env.getScopeName(env) +& "\n");
      then
        fail();
  end matchcontinue;
end instEquationCommon;

protected function instEquationNoRetCallVectorization "creates DAE for NORETCALLs and also performs vectorization if needed"
  input DAE.Exp expCall;
  input DAE.ElementSource source "the origin of the element";
  output DAE.DAElist dae;
algorithm
  dae := matchcontinue(expCall,source)
  local Absyn.Path fn; list<DAE.Exp> expl; DAE.ExpType ty; Boolean s; DAE.Exp e;
    DAE.DAElist dae1,dae2; 
    DAE.FunctionTree funcs;
    case(expCall as DAE.CALL(path=fn,expLst=expl),source) equation
      funcs = DAEUtil.avlTreeNew();
    then DAE.DAE({DAE.NORETCALL(fn,expl,source)},funcs);
    case(DAE.ARRAY(ty,s,e::expl),source) equation
      dae1 = instEquationNoRetCallVectorization(DAE.ARRAY(ty,s,expl),source);
      dae2 = instEquationNoRetCallVectorization(e,source);
      dae = DAEUtil.joinDaes(dae1,dae2);
    then dae;
    case(DAE.ARRAY(ty,s,{}),source) equation
    then DAEUtil.emptyDae;
  end matchcontinue;
end instEquationNoRetCallVectorization;

protected function makeDAEArrayEqToReinitForm "
Author: BZ, 2009-02 
Function for transforming DAE equations into DAE.REINIT form, used by instEquationCommon   "
  input DAE.Element inEq;
  output DAE.Element outEqn;
algorithm outEqn := matchcontinue(inEq)
  local
    DAE.ComponentRef cr,cr2; 
    DAE.Exp e1,e2,e;
    DAE.ExpType t;
    DAE.ElementSource source "the origin of the element";
    
  case(DAE.EQUATION(DAE.CREF(cr,_),e,source)) then DAE.REINIT(cr,e,source);
  case(DAE.DEFINE(cr,e,source)) then DAE.REINIT(cr,e,source);
  case(DAE.EQUEQUATION(cr,cr2,source))
    equation
      t = Exp.crefLastType(cr2);
      then DAE.REINIT(cr,DAE.CREF(cr2,t),source);
  case(_) equation print("Failure in: makeDAEArrayEqToReinitForm\n"); then fail();
end matchcontinue;
end makeDAEArrayEqToReinitForm;

protected function condenseArrayEquation "This function transforms makes the two sides of an array equation
into its condensed form. By default, most array variables are vectorized,
i.e. v becomes {v[1],v[2],..,v[n]}. But for array equations containing function calls this is not wanted.
This function detect this case and elaborates expressions without vectorization."
	input Env.Cache inCache;
	input Env.Env env;
	input Absyn.Exp e1;
	input Absyn.Exp e2;
	input DAE.Exp elabedE1;
	input DAE.Exp elabedE2;
	input DAE.Properties prop "To determine if array equation";
	input DAE.Properties prop2 "To determine if array equation";
	input Boolean impl;
	output Env.Cache outCache;
  output DAE.Exp outE1;
  output DAE.Exp outE2;
  output DAE.Properties oprop "If we have an expandable tuple";
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outE1,outE2,oprop,outDae) := matchcontinue(inCache,env,e1,e2,elabedE1,elabedE2,prop,prop2,impl)
    local Env.Cache cache;
      Boolean b1,b2,b3,b4; 
      DAE.DAElist fdae1,fdae2,dae;
      DAE.Exp elabedE1_2, elabedE2_2;
    case(cache,env,e1,e2,elabedE1,elabedE2,prop,prop2,impl) equation
      b3 = Types.isPropTupleArray(prop);
      b4 = Types.isPropTupleArray(prop2);
      true = boolOr(b3,b4);
      true = Exp.containFunctioncall(elabedE2);
      (e1,prop) = expandTupleEquationWithWild(e1,prop2,prop);
      (cache,elabedE1_2,_,_,fdae1) = Static.elabExp(cache,env, e1, impl, NONE,false);
      (cache,elabedE2_2,_,_,fdae2) = Static.elabExp(cache,env, e2, impl, NONE,false);
      dae = DAEUtil.joinDaes(fdae1,fdae2);
      then
        (cache,elabedE1_2,elabedE2_2,prop,dae);      
    case(cache,env,e1,e2,elabedE1,elabedE2,prop,prop2,impl)
    then (cache,elabedE1,elabedE2,prop,DAEUtil.emptyDae);      
  end matchcontinue;
end condenseArrayEquation;

protected function expandTupleEquationWithWild 
"Author BZ 2008-06
The function expands the inExp, Absyn.EXP, to contain as many elements as the, DAE.Properties, propCall does.
The expand adds the elements at the end and they are containing Absyn.WILD() exps with type Types.ANYTYPE. "
  input Absyn.Exp inExp;
  input DAE.Properties propCall;
  input DAE.Properties propTuple;
  output Absyn.Exp outExp;  
  output DAE.Properties oprop;
algorithm 
  (outExp,oprop) := matchcontinue(inExp,propCall,propTuple)
  local 
    list<Absyn.Exp> aexpl,aexpl2;
    list<DAE.Type> typeList;
    Integer fillValue "The amount of elements to add";
    DAE.Type propType;
    list<DAE.Type> lst,lst2;
    Option<Absyn.Path> op;
    list<DAE.TupleConst> tupleConst,tupleConst2;
    DAE.Const tconst;
  case(Absyn.TUPLE(aexpl), 
    DAE.PROP_TUPLE( (DAE.T_TUPLE(typeList),_) , _),
    (propTuple as DAE.PROP_TUPLE((DAE.T_TUPLE(lst),op),DAE.TUPLE_CONST(tupleConst)
    )))
    equation
      fillValue = (listLength(typeList)-listLength(aexpl));
      lst2 = Util.listFill((DAE.T_ANYTYPE(NONE),NONE),fillValue) "types"; 
      aexpl2 = Util.listFill(Absyn.CREF(Absyn.WILD()),fillValue) "epxressions"; 
      tupleConst2 = Util.listFill(DAE.SINGLE_CONST(DAE.C_VAR),fillValue) "TupleConst's"; 
      aexpl = listAppend(aexpl,aexpl2);      
      lst = listAppend(lst,lst2);
      tupleConst = listAppend(tupleConst,tupleConst2);
    then
      (Absyn.TUPLE(aexpl),DAE.PROP_TUPLE((DAE.T_TUPLE(lst),op),DAE.TUPLE_CONST(tupleConst)));
  case(inExp, DAE.PROP_TUPLE(  (DAE.T_TUPLE(typeList),_) , _),DAE.PROP(propType,tconst))
    equation
      fillValue = (listLength(typeList)-1);
      aexpl2 = Util.listFill(Absyn.CREF(Absyn.WILD()),fillValue) "epxressions"; 
      lst2 = Util.listFill((DAE.T_ANYTYPE(NONE),NONE),fillValue) "types";  
      tupleConst2 = Util.listFill(DAE.SINGLE_CONST(DAE.C_VAR),fillValue) "TupleConst's"; 
      aexpl = listAppend({inExp},aexpl2);
      lst = listAppend({propType},lst2); 
      tupleConst = listAppend({DAE.SINGLE_CONST(tconst)},tupleConst2);
    then
      (Absyn.TUPLE(aexpl),DAE.PROP_TUPLE((DAE.T_TUPLE(lst),NONE),DAE.TUPLE_CONST(tupleConst)));
  case(inExp,propCall,propTuple)
    equation
      false = Types.isPropTuple(propCall);
      then (inExp,propTuple);
      case(_,_,_) equation print("expand_Tuple_Equation_With_Wild failed \n");then fail();
  end matchcontinue;
end expandTupleEquationWithWild;


protected function instEquationCommonCiTrans 
"function: instEquationCommonCiTrans  
  updats The ClassInf state machine when an equation is instantiated."
  input ClassInf.State inState;
  input SCode.Initial inInitial;
  output ClassInf.State outState;
algorithm 
  outState := matchcontinue (inState,inInitial)
    local ClassInf.State ci_state_1,ci_state;
    case (ci_state,SCode.NON_INITIAL())
      equation 
        ci_state_1 = ClassInf.trans(ci_state, ClassInf.FOUND_EQUATION());
      then
        ci_state_1;
    case (ci_state,SCode.INITIAL()) then ci_state; 
  end matchcontinue;
end instEquationCommonCiTrans;

protected function addForLoopScope
	"Adds a scope to the environment used in for loops."
	input Env env;
	input Ident iterName;
	input DAE.Type iterType;
	output Env newEnv;
algorithm
	newEnv := Env.openScope(env, false, SOME(Env.forScopeName));
	newEnv := Env.extendFrameForIterator(newEnv, iterName, iterType, DAE.UNBOUND(), SCode.VAR()); 
end addForLoopScope;

protected function instEqEquation "function: instEqEquation
  author: LS, ELN 
  Equations follow the same typing rules as equality expressions.
  This function adds the equation to the DAE."
  input DAE.Exp inExp1;
  input DAE.Properties inProperties2;
  input DAE.Exp inExp3;
  input DAE.Properties inProperties4;
  input DAE.ElementSource source "the origin of the element";
  input SCode.Initial inInitial5;
  input Boolean inBoolean6;
  output DAE.DAElist outDae;
algorithm 
  outDae := matchcontinue (inExp1,inProperties2,inExp3,inProperties4,source,inInitial5,inBoolean6)
    local
      DAE.Exp e1_1,e1,e2,e2_1;
      tuple<DAE.TType, Option<Absyn.Path>> t_1,t1,t2,t;
      DAE.DAElist dae;
      DAE.Properties p1,p2;
      SCode.Initial initial_;
      Boolean impl;
      String e1_str,t1_str,e2_str,t2_str,s1,s2;
    case (e1,(p1 as DAE.PROP(type_ = t1)),e2,(p2 as DAE.PROP(type_ = t2)),source,initial_,impl) /* impl PR. e1= lefthandside, e2=righthandside
	 This seem to be a strange function. 
	 wich rule is matched? or is both rules matched?
	 LS: Static.type_convert in Static.match_prop can probably fail,
	  then the first rule will not match. Question if whether the second
	  rule can match in that case.
	 This rule is matched first, if it fail the next rule is matched.
	 If it fails then this rule is matched. 
	 BZ(2007-05-30): Not so strange it checks for eihter exp1 or exp2 to be from expected type.*/ 
      equation 
        (e1_1,DAE.PROP(t_1,_)) = Types.matchProp(e1, p1, p2, false);
        dae = instEqEquation2(e1_1, e2, t_1, source, initial_);
      then
        dae;
    case (e1,(p1 as DAE.PROP(type_ = t1)),e2,(p2 as DAE.PROP(type_ = t2)),source,initial_,impl) /* If it fails then this rule is matched. */ 
      equation 
        (e2_1,DAE.PROP(t_1,_)) = Types.matchProp(e2, p2, p1, true);
        dae = instEqEquation2(e1, e2_1, t_1, source, initial_);
      then
        dae;
    case (e1,(p1 as DAE.PROP_TUPLE(type_ = t1)),e2,(p2 as DAE.PROP_TUPLE(type_ = t2)),source,initial_,impl) /* PR. */ 
      equation 
        (e1_1,DAE.PROP_TUPLE(t_1,_)) = Types.matchProp(e1, p1, p2, false);
        dae = instEqEquation2(e1_1, e2, t_1, source, initial_);
      then
        dae;
    case (e1,(p1 as DAE.PROP_TUPLE(type_ = t1)),e2,(p2 as DAE.PROP_TUPLE(type_ = t2)),source,initial_,impl) /* PR. 
	    An assignment to a varaible of T_ENUMERATION type is an explicit 
	    assignment to the value componnent of the enumeration, i.e. having 
	    a type T_ENUM
	 */ 
      equation 
        (e2_1,DAE.PROP_TUPLE(t_1,_)) = Types.matchProp(e2, p2, p1, true);
        dae = instEqEquation2(e1, e2_1, t_1, source, initial_);
      then
        dae;

    case ((e1 as DAE.CREF(componentRef = _)),DAE.PROP(type_ = (DAE.T_ENUMERATION(names = _),_)),
           e2,DAE.PROP(type_ = (t as (DAE.T_ENUMERATION(names = _),_))),source,initial_,impl)
      equation 
        dae = instEqEquation2(e1, e2, t, source, initial_);
      then
        dae;
    case (e1,DAE.PROP(type_ = t1),e2,DAE.PROP(type_ = t2),source,initial_,impl)
      equation
        e1_str = Exp.printExpStr(e1);
        t1_str = Types.unparseType(t1);
        e2_str = Exp.printExpStr(e2);
        t2_str = Types.unparseType(t2);
        s1 = Util.stringAppendList({e1_str,"=",e2_str});
        s2 = Util.stringAppendList({t1_str,"=",t2_str});
        Error.addMessage(Error.EQUATION_TYPE_MISMATCH_ERROR, {s1,s2});
        Debug.fprintln("failtrace", "- Inst.instEqEquation failed with type mismatch in equation: " +& s1 +& " tys: " +& s2);
      then
        fail();        
  end matchcontinue;
end instEqEquation;

protected function instEqEquation2 
"function: instEqEquation2
  author: LS, ELN
  This is the second stage of instEqEquation, when the types are checked."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Type inType3;
  input DAE.ElementSource source "the origin of the element";
  input SCode.Initial inInitial4;
  output DAE.DAElist outDae;
algorithm 
  outDae := matchcontinue (inExp1,inExp2,inType3,source,inInitial4)
    local
      DAE.DAElist dae; DAE.Exp e1,e2;
      SCode.Initial initial_;
      DAE.ComponentRef cr,c1_1,c2_1,c1,c2,assignedCr;
      DAE.ExpType t,t1,t2,tp,ty,lsty,elabedType;
      list<Integer> ds;
      tuple<DAE.TType, Option<Absyn.Path>> bc;
      DAE.DAElist dae1,dae2,decl;
      DAE.ArrayDim ad; ClassInf.State cs;
      String n; list<DAE.Var> vs; 
      Option<Absyn.Path> p;
      DAE.Type tt;
      Values.Value value;
      list<DAE.Element> dael;
      DAE.FunctionTree funcs;

    case (e1,e2,(DAE.T_INTEGER(varLstInt = _),_),source,initial_)
      equation 
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    case (e1,e2,(DAE.T_REAL(varLstReal = _),_),source,initial_)
      equation 
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    case (e1,e2,(DAE.T_STRING(varLstString = _),_),source,initial_)
      equation 
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    case (e1,e2,(DAE.T_BOOL(varLstBool = _),_),source,initial_)
      equation 
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;

    case (DAE.CREF(componentRef = cr,ty = t),e2,(DAE.T_ENUMERATION(names = _),_),source,initial_)
      equation 
        dae = makeDaeDefine(cr, e2, source, initial_);
      then
        dae;

    /* arrays with function calls => array equations */
    case (e1,e2,(t as (DAE.T_ARRAY(arrayDim = _),_)),source,initial_) 
      local tuple<DAE.TType, Option<Absyn.Path>> t; Boolean b1,b2;
      equation 
        b1 = Exp.containVectorFunctioncall(e2);
        b2 = Exp.containVectorFunctioncall(e2);
        true = boolOr(b1,b2);
        ds = Types.getDimensionSizes(t);
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
        funcs = DAEUtil.avlTreeNew();
      then
        DAE.DAE({DAE.ARRAY_EQUATION(ds,e1,e2,source)},funcs);
    /* arrays that are splitted */
    case (e1,e2,(DAE.T_ARRAY(arrayDim = ad,arrayType = t),_),source,initial_) 
      local
        tuple<DAE.TType, Option<Absyn.Path>> t;
      equation 
        dae = instArrayEquation(e1, e2, ad, t, source, initial_);
      then
        dae;
    /* tuples */
    case (e1,e2,(DAE.T_TUPLE(tupleType = _),_),source,initial_) 
      equation 
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;

    /* MetaModelica types */
    case (e1,e2,(DAE.T_LIST(_),_),source,initial_)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    case (e1,e2,(DAE.T_METATUPLE(_),_),source,initial_)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    case (e1,e2,(DAE.T_METAOPTION(_),_),source,initial_)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    case (e1,e2,(DAE.T_UNIONTYPE(_),_),source,initial_)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    /* -------------- */
    /* Complex types extending basic type */
    case (e1,e2,(DAE.T_COMPLEX(complexTypeOption = SOME(bc)),_),source,initial_) 
      equation 
        dae = instEqEquation2(e1, e2, bc, source, initial_);
      then
       dae;
  
  /* Complex equation for records on form e1 = e2, expand to equality over record elements*/
    case (DAE.CREF(componentRef=_),DAE.CREF(componentRef=_),(DAE.T_COMPLEX(complexVarLst = {}),_),source,initial_) 
      then DAEUtil.emptyDae; 
    case (DAE.CREF(componentRef = c1,ty = t1),DAE.CREF(componentRef = c2,ty = t2),
          (DAE.T_COMPLEX(complexClassType = cs,complexVarLst = (DAE.TYPES_VAR(name = n,type_ = t) :: vs),
          complexTypeOption = bc, equalityConstraint = ec),p),source,initial_)
      local
        tuple<DAE.TType, Option<Absyn.Path>> t;
        Option<tuple<DAE.TType, Option<Absyn.Path>>> bc;
        DAE.ExpType ty22,ty2;
        DAE.EqualityConstraint ec;
      equation 
        ty2 = Types.elabType(t);
        c1_1 = Exp.extendCref(c1,ty2, n, {});
        c2_1 = Exp.extendCref(c2,ty2, n, {});
        dae1 = instEqEquation2(DAE.CREF(c1_1,t1), DAE.CREF(c2_1,t2), t, source, initial_);
        dae2 = instEqEquation2(DAE.CREF(c1,t1), DAE.CREF(c2,t2), (DAE.T_COMPLEX(cs,vs,bc,ec),p), source, initial_);
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        dae; 
        
        // split a constant complex equation to its elements 
    case ((e1 as DAE.CREF(assignedCr,_)),(e2 as DAE.CALL(path=_,ty=ty)),tt as (DAE.T_COMPLEX(complexVarLst = _),_),source,initial_)
      local DAE.AvlTree dav; 
      equation
        elabedType = Types.elabType(tt);
        true = Exp.equalTypes(elabedType,ty);        
        // adrpo: 2010-02-18, bug: https://openmodelica.org:8443/cb/issue/1175?navigation=true
        // DO NOT USE Ceval.MSG() here to generate messages 
        // as it will print error messages such as:
        //   Error: Variable body.sequence_start[1] not found in scope <global scope>
        //   Error: No constant value for variable body.sequence_start[1] in scope <global scope>.
        //   Error: Variable body.sequence_angleStates[1] not found in scope <global scope>
        //   Error: No constant value for variable body.sequence_angleStates[1] in scope <global scope>.
        // These errors happen because WE HAVE NO ENVIRONMENT, so we cannot lookup or ceval any cref!
        (_,value,_) = Ceval.ceval(Env.emptyCache(),Env.emptyEnv, e2, false, NONE, NONE, Ceval.NO_MSG());
        dael = assignComplexConstantConstruct(value,assignedCr,source);
        dav = DAEUtil.avlTreeNew();
        //print(" SplitComplex \n ");DAEUtil.printDAE(DAE.DAE(dael,dav)); 
      then DAE.DAE(dael,dav); 
        
   /* all other COMPLEX equations */
   case (e1,e2, t as (DAE.T_COMPLEX(complexVarLst = _),_),source,initial_)
     local DAE.Type t;     
      equation        
     dae = instComplexEquation(e1,e2,t,source,initial_);
    then dae;
   
    case (e1,e2,t,source,initial_)
      local tuple<DAE.TType, Option<Absyn.Path>> t;
      equation 
        Debug.fprintln("failtrace", "- Inst.instEqEquation2 failed");
      then
        fail();
  end matchcontinue;
end instEqEquation2; 

protected function assignComplexConstantConstruct "
Author BZ 2010
Function for assigning contrctor calls to variables inside complex var.
Helperfunction for instEqEquation2
ex.
Person p
 Real a[3,3]
 Real b[3]
end p
equation
 p = Person(identity(3),zeros(3))
 
 this function will flatten this to;
p.a = identity(3);
p.b = zeros(3); 
"

input Values.Value constantValue;
input DAE.ComponentRef assigned;
input DAE.ElementSource source;
output list<DAE.Element> eqns;
algorithm 
  eqns := matchcontinue(constantValue,assigned,source)
  local
    DAE.ComponentRef cr,cr2,cr3;
    Integer i,index;
    Real r;
    String s,n;
    Boolean b; 
    Absyn.Path p;    
    list<String> names;
    Values.Value v; 
    list<Values.Value> vals,arrVals;
    list<DAE.Element> eqnsArray,eqns2;
    case(Values.RECORD(orderd = {},comp = {}),cr,source) then {};
    case(Values.RECORD(p, Values.RECORD(comp=_)::vals,n::names,index),cr,source)
      equation
        print(" implement assignComplexConstantConstruct for records of records\n");
      then fail();

    case(Values.RECORD(p, (v as Values.ARRAY(valueLst = arrVals))::vals, n::names, index),cr,source)
      equation
        cr2 = Exp.crefAppend(cr,DAE.CREF_IDENT(n,DAE.ET_OTHER,{}));
        eqns = assignComplexConstantConstruct(Values.RECORD(p,vals,names,index),cr,source);
        eqnsArray = assignComplexConstantConstructToArray(arrVals,cr2,source,1);
        eqns = listAppend(eqns,eqnsArray);
      then
        eqns;
    case(Values.RECORD(p, v::vals, n::names, index),cr,source)
      equation
        cr2 = Exp.crefAppend(cr,DAE.CREF_IDENT(n,DAE.ET_INT,{}));
        eqns2 = assignComplexConstantConstruct(v,cr2,source);
        eqns = assignComplexConstantConstruct(Values.RECORD(p,vals,names,index),cr,source);
        eqns = listAppend(eqns,eqns2);
      then
        eqns;
          
        // REAL
    case(Values.REAL(r),cr,source)
    then {DAE.EQUATION(DAE.CREF(cr,DAE.ET_REAL),DAE.RCONST(r),source)};
      
    case(Values.INTEGER(i),cr,source)
    then {DAE.EQUATION(DAE.CREF(cr,DAE.ET_INT),DAE.ICONST(i),source)};
        
    case(Values.STRING(s),cr,source)
    then {DAE.EQUATION(DAE.CREF(cr,DAE.ET_STRING),DAE.SCONST(s),source)};
        
    case(Values.BOOL(b),cr,source)
    then {DAE.EQUATION(DAE.CREF(cr,DAE.ET_BOOL),DAE.BCONST(b),source)};

    case(constantValue,cr,source)
      equation
        print(" failure to assign: "  +& Exp.printComponentRefStr(cr) +& " to " +& ValuesUtil.valString(constantValue) +& "\n");
      then
        fail();
  end matchcontinue;
end assignComplexConstantConstruct;

protected function assignComplexConstantConstructToArray "
Helper function for assignComplexConstantConstruct
Does array indexing and assignement 
"
input list<Values.Value> arr;
input DAE.ComponentRef assigned;
input DAE.ElementSource source;
input Integer subPos;
output list<DAE.Element> eqns;
algorithm eqns := matchcontinue(arr,assigned,source,subPos)
  local
    Values.Value v;
    list<Values.Value> arrVals; 
    list<DAE.Element> eqns2;
  case({},_,_,_) then {};
  case((v  as Values.ARRAY(valueLst = arrVals))::arr,assigned,source,subPos)
    equation      
      eqns = assignComplexConstantConstructToArray(arr,assigned,source,subPos+1);
      assigned = Exp.addSubscriptsLast(assigned,subPos);
      eqns2 = assignComplexConstantConstructToArray(arrVals,assigned,source,1);
      eqns = listAppend(eqns,eqns2);
    then 
      eqns;
  case(v::arr,assigned,source,subPos)
    equation      
      eqns = assignComplexConstantConstructToArray(arr,assigned,source,subPos+1);
      assigned = Exp.addSubscriptsLast(assigned,subPos);
      eqns2 = assignComplexConstantConstruct(v,assigned,source);
      eqns = listAppend(eqns,eqns2);
      then 
        eqns;
end matchcontinue;
end assignComplexConstantConstructToArray;

protected function makeDaeEquation 
"function: makeDaeEquation
  author: LS, ELN  
  Constructs an equation in the DAE, they can be 
  either an initial equation or an ordinary equation."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.ElementSource source "the origin of the element";  
  input SCode.Initial inInitial3;
  output DAE.DAElist outDae;
algorithm 
  outDae := matchcontinue (inExp1,inExp2,source,inInitial3)
    local DAE.Exp e1,e2;
      DAE.FunctionTree funcs;
    case (e1,e2,source,SCode.NON_INITIAL()) equation
      funcs = DAEUtil.avlTreeNew();
    then DAE.DAE({DAE.EQUATION(e1,e2,source)},funcs); 
    case (e1,e2,source,SCode.INITIAL()) equation
      funcs = DAEUtil.avlTreeNew();  
    then DAE.DAE({DAE.INITIALEQUATION(e1,e2,source)},funcs); 
  end matchcontinue;
end makeDaeEquation;

protected function makeDaeDefine 
"function: makeDaeDefine
  author: LS, ELN "
  input DAE.ComponentRef inComponentRef;
  input DAE.Exp inExp;
  input DAE.ElementSource source "the origin of the element";
  input SCode.Initial inInitial;
  output DAE.DAElist outDae;
algorithm 
  outDae := matchcontinue (inComponentRef,inExp,source,inInitial)
    local DAE.ComponentRef cr; DAE.Exp e2;
      DAE.FunctionTree funcs;
    case (cr,e2,source,SCode.NON_INITIAL()) equation
      funcs = DAEUtil.avlTreeNew();
    then DAE.DAE({DAE.DEFINE(cr,e2,source)},funcs); 
    case (cr,e2,source,SCode.INITIAL()) equation
      funcs = DAEUtil.avlTreeNew();  
    then DAE.DAE({DAE.INITIALDEFINE(cr,e2,source)},funcs); 
  end matchcontinue;
end makeDaeDefine;

protected function instArrayEquation 
"function: instArrayEquation 
  This checks the array size and creates an array equation in DAE."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.ArrayDim inArrayDim3;
  input DAE.Type inType4;
  input DAE.ElementSource source "the origin of the element";
  input SCode.Initial inInitial5;
  output DAE.DAElist outDae;
algorithm 
  outDae := matchcontinue (inExp1,inExp2,inArrayDim3,inType4,source,inInitial5)
    local
      String e1_str,e2_str,s1; DAE.Exp e1,e2;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      SCode.Initial initial_; DAE.DAElist dae; Integer sz;

    /* Array equation of unknown size, e.g. Real x[:],y[:]; equation x=y; */
    case (e1,e2,DAE.DIM(integerOption = NONE),t,source,initial_)  
      equation 
        e1_str = Exp.printExpStr(e1);
        e2_str = Exp.printExpStr(e1);
        s1 = Util.stringAppendList({e1_str,"=",e2_str});
        Error.addMessage(Error.INST_ARRAY_EQ_UNKNOWN_SIZE, {s1});
      then
        fail();
        
      /* Array equation of size sz */  
    case (e1,e2,DAE.DIM(integerOption = SOME(sz)),t,source,initial_)
      equation 
        dae = instArrayElEq(e1, e2, t, 1, sz, source, initial_);
      then
        dae;
    case (_,_,_,_,_,_)
      equation 
        Debug.fprintln("failtrace", "- Inst.instArrayEquation failed");
      then
        fail();
  end matchcontinue;
end instArrayEquation;

protected function instArrayElEq 
"function: instArrayElEq 
  This function loops recursively through all indexes in the two
  arrays and generates an equation for each pair of elements."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Type inType3;
  input Integer inInteger4;
  input Integer inInteger5;
  input DAE.ElementSource source "the origin of the element";
  input SCode.Initial inInitial6;
  output DAE.DAElist outDae;
algorithm 
  outDae:= matchcontinue (inExp1,inExp2,inType3,inInteger4,inInteger5,source,inInitial6)
    local
      DAE.Exp e1_1,e2_1,e1,e2; DAE.DAElist dae1,dae2,dae;
      Integer i_1,i,sz; tuple<DAE.TType, Option<Absyn.Path>> t;
      SCode.Initial initial_;
      
      /* array equation for index start<=i<=end */
    case (e1,e2,t,i,sz,source,initial_)  
      local DAE.Exp ae1;
      equation 
        (i <= sz) = true;
        ae1 = DAE.ICONST(i);
        e1_1 = Exp.simplify(DAE.ASUB(e1,{ae1}));
        e2_1 = Exp.simplify(DAE.ASUB(e2,{ae1}));
        dae1 = instEqEquation2(e1_1, e2_1, t, source, initial_);
        i_1 = i + 1;
        dae2 = instArrayElEq(e1, e2, t, i_1, sz, source, initial_);
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        dae;
        
    /* array equation for index i>end, stop iteration */
    case (e1,e2,t,i,sz,source,initial_)
      equation 
        (i <= sz) = false;
      then
        DAEUtil.emptyDae;
    case (_,_,_,_,_,_,_)
      equation 
        Debug.fprintln("failtrace", "- Inst.instArrayElEq failed");
      then
        fail();
  end matchcontinue;
end instArrayElEq;

protected function unroll "function: unroll
  Unrolling a loop is a way of removing the non-linear structure of
  the FOR clause by explicitly repeating the body of the loop once
  for each iteration."
	input Env.Cache inCache;
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input Ident inIdent;
  input Values.Value inValue;
  input list<SCode.EEquation> inSCodeEEquationLst;
  input SCode.Initial inInitial;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outDae,outSets,outGraph):=
  matchcontinue (inCache,inEnv,inMod,inPrefix,inSets,inState,inIdent,inValue,inSCodeEEquationLst,inInitial,inBoolean,inGraph)
    local
      Connect.Sets csets,csets_1,csets_2;
      list<Env.Frame> env_1,env_2,env_3,env;
      DAE.DAElist dae1,dae2,dae;
      ClassInf.State ci_state_1,ci_state;
      DAE.Mod mods;
      Prefix.Prefix pre;
      String i;
      Values.Value fst,v;
      list<Values.Value> rest;
      list<SCode.EEquation> eqs;
      SCode.Initial initial_;
      Boolean impl;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      list<Integer> dims;
      Integer dim;
    case (cache,_,_,_,csets,_,_,Values.ARRAY(valueLst = {}),_,_,_,graph) 
    then (cache,DAEUtil.emptyDae,csets,graph);  /* impl */ 
    
    /* array equation, use instEEquation */
    case (cache,env,mods,pre,csets,ci_state,i,Values.ARRAY(valueLst = (fst :: rest), dimLst = dim :: dims),eqs,(initial_ as SCode.NON_INITIAL()),impl,graph)
      equation
        dim = dim-1;
        dims = dim::dims;
        env_1 = Env.openScope(env, false, SOME(Env.forScopeName));
				env_2 = Env.extendFrameForIterator(env_1, i, DAE.T_INTEGER_DEFAULT, DAE.VALBOUND(fst), SCode.CONST());
				/* use instEEquation*/ 
        (cache,env_3,_,dae1,csets_1,ci_state_1,graph) = instList(cache,env_2,InnerOuter.emptyInstHierarchy, mods, pre, csets, ci_state, instEEquation, eqs, impl,graph);
        (cache,dae2,csets_2,graph) = unroll(cache,env, mods, pre, csets_1, ci_state_1, i, Values.ARRAY(rest,dims), eqs, initial_, impl,graph);
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache,dae,csets_2,graph);
        
     /* initial array equation, use instEInitialequation */
    case (cache,env,mods,pre,csets,ci_state,i,Values.ARRAY(valueLst = (fst :: rest), dimLst = dim :: dims),eqs,(initial_ as SCode.INITIAL()),impl,graph)
      equation 
        dim = dim-1;
        dims = dim::dims;
        env_1 = Env.openScope(env, false, SOME(Env.forScopeName));
				env_2 = Env.extendFrameForIterator(env_1, i, DAE.T_INTEGER_DEFAULT, DAE.VALBOUND(fst), SCode.CONST());
				/* Use instEInitialequation*/
        (cache,env_3,_,dae1,csets_1,ci_state_1,graph) = instList(cache,env_2,InnerOuter.emptyInstHierarchy, mods, pre, csets, ci_state, instEInitialequation, eqs, impl,graph);
        (cache,dae2,csets_2,graph) = unroll(cache,env, mods, pre, csets_1, ci_state_1, i, Values.ARRAY(rest,dims), eqs, initial_, impl,graph);
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache,dae,csets_2,graph);
    case (_,_,_,_,_,_,_,v,_,_,_,_)
      equation 
				true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- Inst.unroll failed: " +& ValuesUtil.valString(v));
      then
        fail();
  end matchcontinue;
end unroll;

protected function instAlgorithm 
"function: instAlgorithm 
  Algorithms are converted to the representation defined in 
  the module Algorithm, and the added to the DAE result.
  This function converts an algorithm section."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.Algorithm inAlgorithm;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph) := 
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inAlgorithm,inBoolean,inGraph)
    local
      list<Env.Frame> env_1,env;
      list<DAE.Statement> statements_1;
      Connect.Sets csets;
      ClassInf.State ci_state;
      list<Absyn.Algorithm> statements;
      SCode.OptBaseClass bc;
      Boolean impl;
      Env.Cache cache;
      Prefix pre;
      SCode.Algorithm algSCode;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      DAE.FunctionTree funcs;
      DAE.DAElist dae,fdae;
      
    case (cache,env,ih,_,pre,csets,ci_state,SCode.ALGORITHM(statements = statements,baseClassPath = bc),impl,graph) /* impl */ 
      equation 
        (cache,env_1,ih) = getDerivedEnv(cache,env,ih, bc) "If algorithm is inherited, find base class environment" ;
        (cache,statements_1,fdae) = instStatements(cache,env_1,pre, statements, SCode.NON_INITIAL(),impl);

        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        funcs = DAEUtil.avlTreeNew();
        dae = DAEUtil.joinDaes(DAE.DAE({DAE.ALGORITHM(DAE.ALGORITHM_STMTS(statements_1),source)},funcs),fdae);
      then
        (cache,env,ih,dae,csets,ci_state,graph);

    case (_,_,_,_,_,_,_,algSCode,_,_)
      equation 
        Debug.fprintln("failtrace", "- Inst.instAlgorithm failed");
      then
        fail();
  end matchcontinue;
end instAlgorithm;

protected function instInitialalgorithm 
"function: instInitialalgorithm 
  Algorithms are converted to the representation defined 
  in the module Algorithm, and the added to the DAE result.
  This function converts an algorithm section."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.Algorithm inAlgorithm;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inAlgorithm,inBoolean,inGraph)
    local
      list<Env.Frame> env_1,env;
      list<DAE.Statement> statements_1;
      Connect.Sets csets;
      ClassInf.State ci_state;
      list<Absyn.Algorithm> statements;
      SCode.OptBaseClass bc;
      Boolean impl;
      Env.Cache cache;
      Prefix pre;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      DAE.FunctionTree funcs;
      DAE.DAElist fdae,dae;
      
    case (cache,env,ih,_,pre,csets,ci_state,SCode.ALGORITHM(statements = statements,baseClassPath = bc),impl,graph)
      equation 
        (cache,env_1,ih) = getDerivedEnv(cache,env,ih, bc);
        (cache,statements_1,fdae) = instStatements(cache,env, pre,statements, SCode.INITIAL(), impl);
        
        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        funcs = DAEUtil.avlTreeNew();
        dae = DAEUtil.joinDaes(DAE.DAE({DAE.INITIALALGORITHM(DAE.ALGORITHM_STMTS(statements_1),source)},funcs),fdae);
      then
        (cache,env,ih,dae,csets,ci_state,graph);

    case (_,_,_,_,_,_,_,_,_,_)
      equation 
        Debug.fprintln("failtrace", "- Inst.instInitialAlgorithm failed");
      then
        fail();
  end matchcontinue;
end instInitialalgorithm;

protected function instStatements 
"function: instStatements 
  This function converts a list of algorithm statements."
	input Env.Cache inCache;
  input Env inEnv;
  input Prefix inPre;
  input list<Absyn.Algorithm> inAbsynAlgorithmLst;
  input SCode.Initial initial_;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output list<DAE.Statement> outAlgorithmStatementLst;
  output DAE.DAElist outDae "contain functions";
algorithm 
  (outCache,outAlgorithmStatementLst,outDae) := matchcontinue (inCache,inEnv,inPre,inAbsynAlgorithmLst,initial_,inBoolean)
    local
      list<Env.Frame> env;
      Boolean impl;
      DAE.Statement x_1;
      list<DAE.Statement> xs_1;
      Absyn.Algorithm x;
      list<Absyn.Algorithm> xs;
      Env.Cache cache;
      Prefix pre;
      DAE.DAElist dae,dae1,dae2;
    case (cache,env,pre,{},initial_,impl) then (cache,{},DAEUtil.emptyDae); 
    case (cache,env,pre,(x :: xs),initial_,impl)
      equation 
        (cache,x_1,dae1) = instStatement(cache,env, pre, x, initial_, impl);
        (cache,xs_1,dae2) = instStatements(cache,env, pre, xs, initial_, impl);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,x_1 :: xs_1,dae);
  end matchcontinue;
end instStatements;

public function instAlgorithmitems 
"function: instAlgorithmitems 
  Helper function to instStatement."
	input Env.Cache inCache;
  input Env inEnv;
  input Prefix inPre;
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  input SCode.Initial initial_;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output list<DAE.Statement> outAlgorithmStatementLst;
  output DAE.DAElist outDae "contain functions";
algorithm 
  (outCache,outAlgorithmStatementLst,outDae) := matchcontinue (inCache,inEnv,inPre,inAbsynAlgorithmItemLst,initial_,inBoolean)
    local
      list<Env.Frame> env;
      Boolean impl;
      DAE.Statement x_1;
      list<DAE.Statement> xs_1;
      Absyn.Algorithm x;
      list<Absyn.AlgorithmItem> xs;
      Env.Cache cache;
      Prefix pre;
      DAE.DAElist dae,dae1,dae2;
      
    case (cache,env,pre,{},initial_,impl) then (cache,{},DAEUtil.emptyDae);  /* impl */ 
    case (cache,env,pre,(Absyn.ALGORITHMITEM(algorithm_ = x) :: xs),initial_,impl)
      equation 
        (cache,x_1,dae1) = instStatement(cache,env, pre, x,initial_, impl);
        (cache,xs_1,dae2) = instAlgorithmitems(cache,env, pre, xs, initial_,impl);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,x_1 :: xs_1,dae);
        
    case (cache,env,pre,(Absyn.ALGORITHMITEMANN(annotation_ = _) :: xs),initial_,impl)
      equation         
        (cache,xs_1,dae) = instAlgorithmitems(cache,env, pre, xs, initial_, impl);
      then
        (cache,xs_1,dae);
  end matchcontinue;
end instAlgorithmitems;

protected function instStatement "
function: instStatement 
  This function Looks at an algorithm statement and uses functions
  in the Algorithm module to build a representation of it that can
  be used in the DAE output."
	input Env.Cache inCache;
  input Env inEnv;
  input Prefix inPre;
  input Absyn.Algorithm inAlgorithm;
  input SCode.Initial initial_;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output DAE.Statement outStatement;
  output DAE.DAElist outDae "contain functions";
algorithm 
  (outCache,outStatement,outDAe) := matchcontinue (inCache,inEnv,inPre,inAlgorithm,initial_,inBoolean)
    local
      DAE.ComponentRef ce,ce_1;
      DAE.ExpType t;
      DAE.Properties cprop,eprop,prop,msgprop,varprop,valprop;
      SCode.Accessibility acc;
      DAE.Exp e_1,e_2,cond_1,cond_2,msg_1,msg_2,var_1,var_2,value_1,value_2,cre,cre2;
      DAE.Statement stmt, stmt1;
      list<Env.Frame> env,env_1;
      Absyn.ComponentRef cr;
      Absyn.Exp e,cond,msg, assignComp,var,value,elseWhenC;
      Boolean impl;
      list<DAE.Exp> expl_1,expl_2;
      list<DAE.Properties> cprops;
      list<Absyn.Exp> expl;
      String s,i;
      list<DAE.Statement> tb_1,fb_1,sl_1;
      list<tuple<DAE.Exp, DAE.Properties, list<DAE.Statement>>> eib_1;
      list<Absyn.AlgorithmItem> tb,fb,sl,elseWhenSt;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> eib,el,elseWhenRest;
      Absyn.Algorithm alg;
      Env.Cache cache;
      Prefix pre; 
      Absyn.ForIterators forIterators;
      DAE.DAElist dae,dae1,dae2,dae3,dae4;

    //------------------------------------------
    // Part of MetaModelica list extension. KS
    //------------------------------------------
    /* v := Array(...); */
    case (cache,env,pre,Absyn.ALG_ASSIGN(assignComponent = Absyn.CREF(cr),value = Absyn.ARRAY(expList)),initial_,impl)
      local
        list<Absyn.Exp> expList;
        DAE.Type t2;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();

        // If this is a list assignment, then the Array(...) expression should
        // be evaluated to DAE.LIST

        (cache,cre,cprop,acc,_) = Static.elabCref(cache,env, cr, impl,false);
        true = MetaUtil.isList(cprop);

        (cache,DAE.CREF(ce,t)) = PrefixUtil.prefixExp(cache,env, cre, pre);
        (cache,ce_1) = Static.canonCref(cache,env, ce, impl);

        // In case we have a nested list expression
        expList = MetaUtil.transformArrayNodesToListNodes(expList,{});

        (cache,e_1,eprop,_) = Static.elabListExp(cache,env, expList, cprop, impl, NONE,true);

        (cache,e_2) = PrefixUtil.prefixExp(cache,env, e_1, pre);
        stmt = Algorithm.makeAssignment(DAE.CREF(ce_1,t), cprop, e_2, eprop, acc, initial_);
      then 
        (cache,stmt,DAEUtil.emptyDae);
    //-----------------------------------------//

    /* v := array(for-iterator); */
    case (cache,env,pre,Absyn.ALG_ASSIGN(Absyn.CREF(c),
      // Absyn.CALL(Absyn.CREF_IDENT("array",{}),Absyn.FOR_ITER_FARG(e1,id,e2))),impl)
         Absyn.CALL(Absyn.CREF_IDENT("array",{}),Absyn.FOR_ITER_FARG(e1,rangeList))),initial_,impl)
      local
        Absyn.Exp e1,vb;
        Absyn.ForIterators rangeList;
        Absyn.ComponentRef c;
        list<Absyn.Ident> tempLoopVarNames;
        list<Absyn.AlgorithmItem> vb_body,tempLoopVarsInit;
        list<Absyn.ElementItem> tempLoopVars;
        DAE.Exp vb2;
      equation
        // rangeList = {(id,e2)};
        (tempLoopVarNames,tempLoopVars,tempLoopVarsInit) = createTempLoopVars(rangeList,{},{},{},1);

        //Transform this function call into a number of nested for-loops
        (vb_body,dae1) = createForIteratorAlgorithm(e1,rangeList,tempLoopVarNames,tempLoopVarNames,c);

        vb_body = listAppend(tempLoopVarsInit,vb_body);
        vb = Absyn.VALUEBLOCK(tempLoopVars,Absyn.VALUEBLOCKALGORITHMS(vb_body),Absyn.BOOL(true));
        (cache,vb2,_,_,dae2) = Static.elabExp(cache,env,vb,impl,NONE,true);

        // _ := { ... }, this will be handled in Codegen.algorithmStatement
        stmt = DAE.STMT_ASSIGN(DAE.ET_BOOL(),
                                DAE.CREF(DAE.WILD,DAE.ET_OTHER()),
                                vb2);
        dae = DAEUtil.joinDaes(dae1,dae2);                        
      then
        (cache,stmt,dae);

    /* v := Function(for-iterator); */
    case (cache,env,pre,Absyn.ALG_ASSIGN(Absyn.CREF(c1),
      // Absyn.CALL(c2,Absyn.FOR_ITER_FARG(e1,id,e2))),impl)
         Absyn.CALL(c2,Absyn.FOR_ITER_FARG(e1,rangeList))),initial_,impl)
      local
        Absyn.Exp e1,vb;
        Absyn.ForIterators rangeList;
        Absyn.Algorithm absynStmt;
        list<Absyn.Ident> tempLoopVarNames;
        Absyn.ComponentRef c1,c2;
        list<Absyn.ElementItem> declList,tempLoopVars;
        list<Absyn.AlgorithmItem> vb_body,tempLoopVarsInit;
      equation
        // rangeList = {(id,e2)};
        (tempLoopVarNames,tempLoopVars,tempLoopVarsInit) = createTempLoopVars(rangeList,{},{},{},1);

        // Create temporary array to store the result from the for-iterator construct
        (cache,declList,dae1) = createForIteratorArray(cache,env,e1,rangeList,impl);

        declList = listAppend(declList,tempLoopVars);

        // Create for-statements
        (vb_body,dae2) = createForIteratorAlgorithm(e1,rangeList,tempLoopVarNames,tempLoopVarNames,Absyn.CREF_IDENT("VEC__",{}));

        vb_body = listAppend(tempLoopVarsInit,vb_body);
        vb = Absyn.VALUEBLOCK(declList,Absyn.VALUEBLOCKALGORITHMS(vb_body),
        Absyn.CALL(c2,Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT("VEC__",{}))},{})));
        absynStmt = Absyn.ALG_ASSIGN(Absyn.CREF(c1),vb);

        (cache,stmt,dae3) = instStatement(cache,env,pre,absynStmt,initial_,impl);
        dae = DAEUtil.joinDaeLst({dae1,dae2,dae3});
      then
        (cache,stmt,dae);

    /* v := expr; */       
    case (cache,env,pre,Absyn.ALG_ASSIGN(assignComponent = Absyn.CREF(cr),value = e),initial_,impl) 
      equation 
        (cache,cre,cprop,acc,dae1) = Static.elabCref(cache,env, cr, impl,false);
        (cache,DAE.CREF(ce,t)) = PrefixUtil.prefixExp(cache,env, cre, pre);        
        (cache,ce_1) = Static.canonCref(cache,env, ce, impl);        
        (cache,e_1,eprop,_,dae2) = Static.elabExp(cache,env, e, impl, NONE,true);
        (cache,e_2) = PrefixUtil.prefixExp(cache,env, e_1, pre);                
        stmt = Algorithm.makeAssignment(DAE.CREF(ce_1,t), cprop, e_2, eprop, acc, initial_);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,stmt,dae);
        /* der(x) := ... */
    case (cache,env,pre,Absyn.ALG_ASSIGN(assignComponent = 
      (e2 as Absyn.CALL(function_ = Absyn.CREF_IDENT(name="der"),functionArgs=(Absyn.FUNCTIONARGS(args={Absyn.CREF(cr)})) )),value = e),initial_,impl)
      local
        Absyn.Exp e2;
        DAE.Exp e2_2,e2_2_2; 
      equation 
        (cache,_,cprop,acc,dae) = Static.elabCref(cache,env, cr, impl,false);
        (cache,(e2_2 as DAE.CALL(path=_)),_,_,dae1) = Static.elabExp(cache,env, e2, impl, NONE,true);
         (cache,e2_2_2) = PrefixUtil.prefixExp(cache,env, e2_2, pre);
        (cache,e_1,eprop,_,dae2) = Static.elabExp(cache,env, e, impl, NONE,true);
        (cache,e_2) = PrefixUtil.prefixExp(cache,env, e_1, pre);                
        stmt = Algorithm.makeAssignment(e2_2_2, cprop, e_2, eprop, SCode.RW() ,initial_);
        dae = DAEUtil.joinDaeLst({dae,dae1,dae2});
      then
        (cache,stmt,dae);
		// v[i] := expr (in e.g. for loops)
    case (cache,env,pre,Absyn.ALG_ASSIGN(assignComponent = Absyn.CREF(cr),value = e),initial_,impl)
      equation 
        (cache,cre,cprop,acc,dae1) = Static.elabCref(cache,env, cr, impl,false);
       (cache,cre2) = PrefixUtil.prefixExp(cache,env, cre, pre);
        (cache,e_1,eprop,_,dae2) = Static.elabExp(cache,env, e, impl, NONE,true);
       (cache,e_2) = PrefixUtil.prefixExp(cache,env, e_1, pre);        
        stmt = Algorithm.makeAssignment(cre2, cprop, e_2, eprop, acc,initial_);
        dae = DAEUtil.joinDaes(dae1,dae2);      
      then
        (cache,stmt,dae);

    // (v1,v2,..,vn) := func(...)
    case (cache,env,pre,Absyn.ALG_ASSIGN(assignComponent = Absyn.TUPLE(expressions = expl),value = e),initial_,impl)
      equation 
        (cache,(e_1 as DAE.CALL(path=_)),eprop,_,dae1) = Static.elabExp(cache,env, e, impl, NONE,true);
         (cache,e_2) = PrefixUtil.prefixExp(cache,env, e_1, pre);
        (cache,expl_1,cprops,_,dae2) = Static.elabExpList(cache,env, expl, impl, NONE,false);
        (cache,expl_2) = PrefixUtil.prefixExpList(cache,env,expl_1,pre);        
        stmt = Algorithm.makeTupleAssignment(expl_2, cprops, e_2, eprop,initial_);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,stmt,dae);

      // MetaModelica Matchcontinue - should come before the error message about tuple assignment
    case (cache,env,pre,e as Absyn.ALG_ASSIGN(_,Absyn.MATCHEXP(_,_,_,_,_)),initial_,impl)
      local
        Absyn.Algorithm e;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cache,stmt) = createMatchStatement(cache,env,pre,e,impl);
      then (cache,stmt,DAEUtil.emptyDae);

    /* Tuple with rhs constant */
    case (cache,env,pre,Absyn.ALG_ASSIGN(assignComponent = Absyn.TUPLE(expressions = expl),value = e),initial_,impl)
      local DAE.Exp unvectorisedExpl;
      equation 
        (cache,(e_1 as DAE.TUPLE(_)),eprop,_,dae1) = Static.elabExp(cache,env, e, impl, NONE,true);
        (_,_,_) = Ceval.ceval(Env.emptyCache(),Env.emptyEnv, e_1, false, NONE, NONE, Ceval.MSG());
        (cache,expl_1,cprops,_,dae2) = Static.elabExpList(cache,env, expl, impl, NONE,false);
        (cache,expl_2) = PrefixUtil.prefixExpList(cache,env,expl_1,pre);
        stmt = Algorithm.makeTupleAssignment(expl_2, cprops, e_1, eprop,initial_);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,stmt,dae);

    /* Tuple with rhs not CALL or CONSTANT => Error */
    case (cache,env,pre,Absyn.ALG_ASSIGN(assignComponent = Absyn.TUPLE(expressions = expl),value = e),initial_,impl)
      equation 
        s = Dump.printExpStr(e);
        Error.addMessage(Error.TUPLE_ASSIGN_FUNCALL_ONLY, {s});
      then
        fail();
        
    /* If statement*/
    case (cache,env,pre,Absyn.ALG_IF(ifExp = e,trueBranch = tb,elseIfAlgorithmBranch = eib,elseBranch = fb),initial_,impl)
      equation 
        (cache,e_1,prop,_,dae1) = Static.elabExp(cache,env, e, impl, NONE,true);
        (cache,e_2) = PrefixUtil.prefixExp(cache,env, e_1, pre);        
        (cache,tb_1 ,dae2)= instAlgorithmitems(cache,env,pre, tb, initial_,impl);
        (cache,eib_1,dae3) = instElseifs(cache,env,pre, eib, initial_,impl);
        (cache,fb_1,dae4) = instAlgorithmitems(cache,env,pre, fb, initial_,impl);
        stmt = Algorithm.makeIf(e_2, prop, tb_1, eib_1, fb_1);
        dae = DAEUtil.joinDaeLst({dae1,dae2,dae3,dae4});
      then
        (cache,stmt,dae);
        
    /* For loop */
    case (cache,env,pre,Absyn.ALG_FOR(iterators = forIterators,forBody = sl),initial_,impl)
//      local tuple<DAE.TType, Option<Absyn.Path>> t;
      equation 
//        (cache,e_1,(prop as DAE.PROP((DAE.T_ARRAY(_,t),_),_)),_) = Static.elabExp(cache,env, e, impl, NONE,true);
//        (cache,e_2) = PrefixUtil.prefixExp(cache,env, e_1, pre);
//        env_1 = addForLoopScope(env, i, t);
//        (cache,sl_1) = instAlgorithmitems(cache,env_1,pre, sl,initial_,impl);
//        stmt = Algorithm.makeFor(i, e_2, prop, sl_1);
        (cache,stmt,dae)=instForStatement(cache,env,pre,forIterators,sl,initial_,impl);
      then
        (cache,stmt,dae);
        
    /* While loop */
    case (cache,env,pre,Absyn.ALG_WHILE(boolExpr = e,whileBody = sl),initial_,impl)
      equation 
        (cache,e_1,prop,_,dae1) = Static.elabExp(cache,env, e, impl, NONE,true);
        (cache,e_2) = PrefixUtil.prefixExp(cache,env, e_1, pre);        
        (cache,sl_1,dae2) = instAlgorithmitems(cache,env,pre, sl,initial_,impl);        
        stmt = Algorithm.makeWhile(e_2, prop, sl_1);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,stmt,dae);

    /* When clause without elsewhen */
    case (cache,env,pre,Absyn.ALG_WHEN_A(boolExpr = e,whenBody = sl,elseWhenAlgorithmBranch = {}),initial_,impl)
      equation 
        (cache,e_1,prop,_,dae1) = Static.elabExp(cache,env, e, impl, NONE,true);
        (cache,e_2) = PrefixUtil.prefixExp(cache,env, e_1, pre);
        (cache,sl_1,dae2) = instAlgorithmitems(cache,env,pre, sl, initial_,impl);
        stmt = Algorithm.makeWhenA(e_2, prop, sl_1, NONE);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,stmt,dae);
        
    /* When clause with elsewhen branch */
    case (cache,env,pre,Absyn.ALG_WHEN_A(boolExpr = e,whenBody = sl,
          elseWhenAlgorithmBranch = (elseWhenC,elseWhenSt)::elseWhenRest),initial_,impl)
      equation 
        (cache,stmt1,dae1) = instStatement(cache,env,pre,Absyn.ALG_WHEN_A(elseWhenC,elseWhenSt,elseWhenRest),initial_,impl);
        (cache,e_1,prop,_,dae2) = Static.elabExp(cache,env, e, impl, NONE,true);
        (cache,e_2) = PrefixUtil.prefixExp(cache,env, e_1, pre);        
        (cache,sl_1,dae3) = instAlgorithmitems(cache,env, pre, sl, initial_, impl);
        stmt = Algorithm.makeWhenA(e_2, prop, sl_1, SOME(stmt1));
        dae = DAEUtil.joinDaeLst({dae1,dae2,dae3});
      then
        (cache,stmt,dae);
        
    /* assert(cond,msg) */
    case (cache,env,pre,Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "assert"),
          functionArgs = Absyn.FUNCTIONARGS(args = {cond,msg},argNames = {})),initial_,impl)
      equation 
        (cache,cond_1,cprop,_,dae1) = Static.elabExp(cache,env, cond, impl, NONE,true);
        (cache,cond_2) = PrefixUtil.prefixExp(cache,env, cond_1, pre);        
        (cache,msg_1,msgprop,_,dae2) = Static.elabExp(cache,env, msg, impl, NONE,true);
        (cache,msg_2) = PrefixUtil.prefixExp(cache,env, msg_1, pre);        
        stmt = Algorithm.makeAssert(cond_2, msg_2, cprop, msgprop);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,stmt,dae);
        
    /* terminate(msg) */
    case (cache,env,pre,Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "terminate"),
          functionArgs = Absyn.FUNCTIONARGS(args = {msg},argNames = {})),initial_,impl)
      equation 
        (cache,msg_1,msgprop,_,dae) = Static.elabExp(cache,env, msg, impl, NONE,true);
        (cache,msg_2) = PrefixUtil.prefixExp(cache,env, msg_1, pre);        
        stmt = Algorithm.makeTerminate(msg_2, msgprop);
      then
        (cache,stmt,dae);
        
    /* reinit(variable,value) */
    case (cache,env,pre,Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "reinit"),
          functionArgs = Absyn.FUNCTIONARGS(args = {var,value},argNames = {})),initial_,impl)
      equation 
        (cache,var_1,varprop,_,dae1) = Static.elabExp(cache,env, var, impl, NONE,true);
        (cache,var_2) = PrefixUtil.prefixExp(cache,env, var_1, pre);                
        (cache,value_1,valprop,_,dae2) = Static.elabExp(cache,env, value, impl, NONE,true);
        (cache,value_2) = PrefixUtil.prefixExp(cache,env, value_1, pre);                        
        stmt = Algorithm.makeReinit(var_2, value_2, varprop, valprop);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,stmt,dae);
        
    /* generic NORETCALL */
    case (cache,env,pre,(Absyn.ALG_NORETCALL(callFunc,callArgs)),initial_,impl)
      local 
        Absyn.ComponentRef callFunc;
        Absyn.FunctionArgs callArgs;
        Absyn.Exp aea;
        list<DAE.Exp> eexpl;
        Absyn.Path ap;
        Boolean tuple_, builtin;
        DAE.InlineType inline;
        DAE.ExpType tp;
      equation 
        (cache,DAE.CALL(ap,eexpl,tuple_,builtin,tp,inline),varprop,_,dae) = Static.elabExp(cache,env, Absyn.CALL(callFunc,callArgs), impl, NONE,true);
        ap = PrefixUtil.prefixPath(ap,pre);
      then
        (cache,DAE.STMT_NORETCALL(DAE.CALL(ap,eexpl,tuple_,builtin,tp,inline)),dae);
	       
    /* break */
    case (cache,env,pre,Absyn.ALG_BREAK,initial_,impl)
      equation 
        stmt = DAE.STMT_BREAK();
      then
        (cache,stmt,DAEUtil.emptyDae);
        
    /* return */
    case (cache,env,pre,Absyn.ALG_RETURN,initial_,impl)
      equation 
        stmt = DAE.STMT_RETURN();
      then
        (cache,stmt,DAEUtil.emptyDae);
        
        //------------------------------------------
    // Part of MetaModelica extension. KS
    //------------------------------------------
    /* try */
    case (cache,env,pre,Absyn.ALG_TRY(sl),initial_,impl)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cache,sl_1,dae) = instAlgorithmitems(cache, env, pre, sl, initial_, impl);
        stmt = DAE.STMT_TRY(sl_1);
      then
        (cache,stmt,dae);
        
    /* catch */
    case (cache,env,pre,Absyn.ALG_CATCH(sl),initial_,impl)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cache,sl_1,dae) = instAlgorithmitems(cache, env, pre, sl, initial_, impl);
        stmt = DAE.STMT_CATCH(sl_1);
      then
        (cache,stmt,dae);

    /* throw */
    case (cache,env,pre,Absyn.ALG_THROW(),initial_,impl)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        stmt = DAE.STMT_THROW();
      then
        (cache,stmt,DAEUtil.emptyDae);

	  /* GOTO */
    case (cache,env,pre,Absyn.ALG_GOTO(s),initial_,impl)
      local
        String s;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        stmt = DAE.STMT_GOTO(s);
      then
        (cache,stmt,DAEUtil.emptyDae);

    case (cache,env,pre,Absyn.ALG_LABEL(s),initial_,impl)
      local
        String s;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        stmt = DAE.STMT_LABEL(s);
      then
        (cache,stmt,DAEUtil.emptyDae);
    
      // Helper statement for matchcontinue
    case (cache,env,pre,Absyn.ALG_MATCHCASES(absynExpList),_,impl)
      local
        list<Absyn.Exp> absynExpList;
        list<DAE.Exp> expExpList;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cache,expExpList,_,_,dae) = Static.elabExpList(cache,env, absynExpList, impl, NONE,true);        
      then (cache,DAE.STMT_MATCHCASES(expExpList),dae);

    //------------------------------------------
        
    case (cache,env,pre,alg,initial_,impl)
      local String str;
      equation 
				true = RTOpts.debugFlag("failtrace");
        str = Dump.unparseAlgorithmStr(0,Absyn.ALGORITHMITEM(alg,NONE()));
        Debug.fprintln("failtrace", "- Inst.instStatement failed: " +& str);
        //Debug.fcall("failtrace", Dump.printAlgorithm, alg);
        //Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end instStatement;

protected function instForStatement 
"Helper function for instStatement"
  input Env.Cache inCache;
  input Env inEnv;
  input Prefix inPrefix;
  input Absyn.ForIterators inIterators;
  input list<Absyn.AlgorithmItem> inForBody;
  input SCode.Initial inInitial;
  input Boolean inBool;
  output Env.Cache outCache;
  output DAE.Statement outStatement;
  output DAE.DAElist outDae;
algorithm
  (outCache,outStatement,outDae):=matchcontinue(inCache,inEnv,inPrefix,inIterators,inForBody,inInitial,inBool)
  local
    Env.Cache cache;
    list<Env.Frame> env,env_1;
    Prefix pre;
    list<Absyn.ForIterator> restIterators;
    list<Absyn.AlgorithmItem> sl;
    SCode.Initial initial_;
    Boolean impl;
    tuple<DAE.TType, Option<Absyn.Path>> t;
    DAE.Exp e_1,e_2;
    list<DAE.Statement> sl_1;
    String i;
    Absyn.Exp e;
    DAE.Statement stmt,stmt_1;
    DAE.Properties prop;
    list<tuple<Absyn.ComponentRef,Integer>> lst;
    DAE.DAElist dae,dae1,dae2;
    tuple<Absyn.ComponentRef, Integer> tpl;
    
    // Frenkel TUD: handle the case where range is a enumeration!
    case (cache,env,pre,{(i,SOME(e as Absyn.CREF(cr)))},sl,initial_,impl)    
      local 
        Absyn.ComponentRef cr;
        Absyn.Path typePath;
        Integer len;
        list<SCode.Element> elementLst;
        list<Values.Value> vals;
        
      equation 
        typePath = Absyn.crefToPath(cr);
        /* make sure is an enumeration! */
       (_, SCode.CLASS(restriction=SCode.R_ENUMERATION(), classDef=SCode.PARTS(elementLst, {}, {}, {}, {}, _, _, _)), _) = 
             Lookup.lookupClass(cache, env, typePath, false);
        len = listLength(elementLst);     
        // replace the enumeration with a range 
        // ToDo do not replace the enumeration use the enumeration literals   
        (cache,stmt,dae) = instForStatement(cache,env,pre,{(i,SOME(Absyn.RANGE(Absyn.INTEGER(1),NONE(),Absyn.INTEGER(len)) ))},sl,initial_,impl);
      then
        (cache,stmt,dae);    
    case (cache,env,pre,{(i,SOME(e))},sl,initial_,impl)
      equation 
        (cache,e_1,(prop as DAE.PROP((DAE.T_ARRAY(_,t),_),_)),_,dae1) = Static.elabExp(cache,env, e, impl, NONE,true);
        (cache,e_2) = PrefixUtil.prefixExp(cache,env, e_1, pre);
        env_1 = addForLoopScope(env, i, t);
        (cache,sl_1,dae2) = instAlgorithmitems(cache,env_1,pre, sl,initial_,impl);
        stmt = Algorithm.makeFor(i, e_2, prop, sl_1);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,stmt,dae);
    case (cache,env,pre,(i,SOME(e))::restIterators,sl,initial_,impl)
      equation
        (cache,e_1,(prop as DAE.PROP((DAE.T_ARRAY(_,t),_),_)),_,dae1) = Static.elabExp(cache,env, e, impl, NONE,true);
        (cache,e_2) = PrefixUtil.prefixExp(cache,env, e_1, pre);
        env_1 = addForLoopScope(env, i, t);
        (cache,stmt_1,dae2)=instForStatement(cache,env_1,pre,restIterators,sl,initial_,impl);
        sl_1={stmt_1};
        stmt = Algorithm.makeFor(i, e_2, prop, sl_1);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,stmt,dae);
/*  case (cache,env,pre,{(i,NONE)},sl,initial_,impl)
      equation 
        lst=Absyn.findIteratorInAlgorithmItemLst(i,sl);
//        len=listLength(lst);
//        zero=0;
//        equality(zero=len);
        equality(lst={});
        Error.addMessage(Error.IMPLICIT_ITERATOR_NOT_FOUND_IN_LOOP_BODY,{i});        
      then
        fail();*/
    case (cache,env,pre,(i,NONE)::restIterators,sl,initial_,impl)
      equation 
        lst=Absyn.findIteratorInAlgorithmItemLst(i,sl);
        equality(lst={});
        Error.addMessage(Error.IMPLICIT_ITERATOR_NOT_FOUND_IN_LOOP_BODY,{i});        
      then
        fail();
    case (cache,env,pre,{(i,NONE)},sl,initial_,impl) //The verison w/o assertions
      equation 
        lst=Absyn.findIteratorInAlgorithmItemLst(i,sl);
        failure(equality(lst={}));
        tpl=Util.listFirst(lst);
//        e=Absyn.RANGE(1,NONE,Absyn.CALL(Absyn.CREF_IDENT("size",{}),Absyn.FUNCTIONARGS({Absyn.CREF(acref),Absyn.INTEGER(dimNum)},{})));
        e=rangeExpression(tpl);
        (cache,e_1,(prop as DAE.PROP((DAE.T_ARRAY(_,t),_),_)),_,dae1) = Static.elabExp(cache,env, e, impl, NONE,true);
        (cache,e_2) = PrefixUtil.prefixExp(cache,env, e_1, pre);
        env_1 = addForLoopScope(env, i, t);
        (cache,sl_1,dae2) = instAlgorithmitems(cache,env_1,pre, sl,initial_,impl);
        stmt = Algorithm.makeFor(i, e_2, prop, sl_1);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,stmt,dae);
    case (cache,env,pre,(i,NONE)::restIterators,sl,initial_,impl) //The verison w/o assertions
      equation 
        lst=Absyn.findIteratorInAlgorithmItemLst(i,sl);
        failure(equality(lst={}));
        tpl=Util.listFirst(lst);
//        e=Absyn.RANGE(1,NONE,Absyn.CALL(Absyn.CREF_IDENT("size",{}),Absyn.FUNCTIONARGS({Absyn.CREF(acref),Absyn.INTEGER(dimNum)},{})));
        e=rangeExpression(tpl);
        (cache,e_1,(prop as DAE.PROP((DAE.T_ARRAY(_,t),_),_)),_,dae1) = Static.elabExp(cache,env, e, impl, NONE,true);
        (cache,e_2) = PrefixUtil.prefixExp(cache,env, e_1, pre);
        env_1 = addForLoopScope(env, i, t);
        (cache,stmt_1,dae2)=instForStatement(cache,env_1,pre,restIterators,sl,initial_,impl);
        sl_1={stmt_1};
        stmt = Algorithm.makeFor(i, e_2, prop, sl_1);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,stmt,dae);
        
  end matchcontinue;
end instForStatement;

protected function rangeExpression "
The function takes a tuple of Absyn.ComponentRef (an array variable) and an integer i and constructs 
the range expression (Absyn.Exp) for the ith dimension of the variable
"
  input tuple<Absyn.ComponentRef, Integer> inTuple;
  output Absyn.Exp outExp;
algorithm
  outExp:=matchcontinue(inTuple)
  local
    Absyn.Exp e;
    Absyn.ComponentRef acref;
    Integer dimNum;           
    tuple<Absyn.ComponentRef, Integer> tpl;
    case (tpl as (acref,dimNum))
      equation
        e=Absyn.RANGE(Absyn.INTEGER(1),NONE,Absyn.CALL(Absyn.CREF_IDENT("size",{}),Absyn.FUNCTIONARGS({Absyn.CREF(acref),Absyn.INTEGER(dimNum)},{})));
      then e;
  end matchcontinue;
end rangeExpression;              

/* MetaModelica Language Extension */
protected function createMatchStatement 
"function: createMatchStatement
  Author: KS
  Function called by instStatement"
  input Env.Cache cache;
  input Env.Env env;
  input Prefix pre;
  input Absyn.Algorithm alg;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output DAE.Statement outStmt;
algorithm
  (outCache,outStmt) := matchcontinue (cache,env,pre,alg,inBoolean)
    local
      DAE.Properties cprop,eprop;
      DAE.Statement stmt;
      Env.Cache localCache;
      Env.Env localEnv;
      Prefix localPre;
      Absyn.Exp exp,e;
      DAE.ComponentRef ce;
      DAE.Exp cre;
      Boolean impl;
      SCode.Accessibility acc;
      Absyn.ComponentRef cr;
      DAE.ExpType t;
      list<Absyn.Exp> expl;

      // TODO: Someone with MetaModelica interests needs to collect the dae:s from elabExp and propagate them upwards.

    // _ := matchcontinue(...) ...
    case (localCache,localEnv,localPre,Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.WILD()),e as Absyn.MATCHEXP(_,_,_,_,_)),impl)
      local
        Absyn.Exp exp;
        DAE.Exp e_1,e_2;
      equation
        expl = {};
        (localCache,e) = Patternm.matchMain(e,expl,localCache,localEnv);
        (localCache,e_1,eprop,_,_) = Static.elabExp(localCache,localEnv, e, impl, NONE,true);
        (localCache,e_2) = PrefixUtil.prefixExp(localCache,localEnv, e_1, localPre);
        stmt = DAE.STMT_ASSIGN(
                  DAE.ET_OTHER(),
                  DAE.CREF(DAE.WILD,DAE.ET_OTHER()),
                  e_2);
      then (localCache,stmt);

    // v1 := matchcontinue(...). Part of MetaModelica extension. KS
    case (localCache,localEnv,localPre,Absyn.ALG_ASSIGN(Absyn.CREF(cr),e as Absyn.MATCHEXP(_,_,_,_,_)),impl)
      local
        DAE.Exp e_1,e_2;
      equation
        expl = {Absyn.CREF(cr)};
        (localCache,e) = Patternm.matchMain(e,expl,localCache,localEnv);
        (localCache,e_1,eprop,_,_) = Static.elabExp(localCache,localEnv, e, impl, NONE,true);
        (localCache,e_2) = PrefixUtil.prefixExp(localCache,localEnv, e_1, localPre);        
        stmt = DAE.STMT_ASSIGN(
                  DAE.ET_OTHER(),
                  DAE.CREF(DAE.WILD,DAE.ET_OTHER()),
                  e_2);
      then
        (localCache,stmt);

    // (v1,v2,..,vn) := matchcontinue(...). Part of MetaModelica extension. KS
    case (localCache,localEnv,localPre,Absyn.ALG_ASSIGN(Absyn.TUPLE(expl),e as Absyn.MATCHEXP(_,_,_,_,_)),impl)
      local
        DAE.Exp e_1,e_2;
      equation
        //Absyn.CREF(cr) = Util.listFirst(expl);
        //(localCache,cre,cprop,acc) = Static.elabCref(localCache,localEnv, cr, impl,false);
        //(localCache,DAE.CREF(ce,t)) = PrefixUtil.prefixExp(localCache,localEnv, cre, localPre);
        (localCache,e) = Patternm.matchMain(e,expl,localCache,localEnv);
        (localCache,e_1,eprop,_,_) = Static.elabExp(localCache,localEnv, e, impl, NONE,true);
        (localCache,e_2) = PrefixUtil.prefixExp(localCache,localEnv, e_1, localPre);        
        stmt = DAE.STMT_ASSIGN(
                 DAE.ET_OTHER(),
                 DAE.CREF(DAE.WILD,DAE.ET_OTHER()),
                 e_2);
      then
        (localCache,stmt);
    case (_,_,_,_,_)
      equation
        Debug.fprintln("matchcase", "- Inst.createMatchStatement failed");
      then fail();
  end matchcontinue;
end createMatchStatement;

protected function instElseifs 
"function: instElseifs 
  This function helps instStatement to handle elseif parts."
	input Env.Cache inCache;
  input Env inEnv;
  input Prefix inPre;
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inTplAbsynExpAbsynAlgorithmItemLstLst;
  input SCode.Initial initial_;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output list<tuple<DAE.Exp, DAE.Properties, list<DAE.Statement>>> outTplExpExpTypesPropertiesAlgorithmStatementLstLst;
  output DAE.DAElist outDae "contain functions";
algorithm 
  (outCache,outTplExpExpTypesPropertiesAlgorithmStatementLstLst,outDae) :=
  matchcontinue (inCache,inEnv,inPre,inTplAbsynExpAbsynAlgorithmItemLstLst,initial_,inBoolean)
    local
      list<Env.Frame> env;
      Boolean impl;
      DAE.Exp e_1,e_2;
      DAE.Properties prop;
      list<DAE.Statement> stmts;
      list<tuple<DAE.Exp, DAE.Properties, list<DAE.Statement>>> tail_1;
      Absyn.Exp e;
      list<Absyn.AlgorithmItem> l;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> tail;
      Env.Cache cache;
      Prefix pre;
      DAE.DAElist dae,dae1,dae2,dae3;
      
    case (cache,env,pre,{},initial_,impl) then (cache,{},DAEUtil.emptyDae); 
    case (cache,env,pre,((e,l) :: tail),initial_,impl)
      equation 
        (cache,e_1,prop,_,dae1) = Static.elabExp(cache,env, e, impl, NONE,true);
        (cache,e_2) = PrefixUtil.prefixExp(cache,env, e_1, pre);                            
        (cache,stmts,dae2) = instAlgorithmitems(cache,env,pre, l,initial_, impl);
        (cache,tail_1,dae3) = instElseifs(cache,env,pre,tail, initial_, impl);
        dae = DAEUtil.joinDaeLst({dae1,dae2,dae3});
      then
        (cache,(e_2,prop,stmts) :: tail_1,dae);
    case (_,_,_,_,_,_)
      equation 
        Debug.fprintln("failtrace", "- Inst.instElseifs failed");
      then
        fail();
  end matchcontinue;
end instElseifs;

protected function instConnect "
  Generates connectionsets for connections.
  Parameters and constants in connectors should generate appropriate assert statements.
  Hence, a DAE.Element list is returned as well."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;	
  input Connect.Sets inSets;
  input Prefix inPrefix3;
  input Absyn.ComponentRef inComponentRef4;
  input Absyn.ComponentRef inComponentRef5;
  input Boolean inBoolean6;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output Connect.Sets outSets;
  output DAE.DAElist outDae;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outSets,outDae,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inSets,inPrefix3,inComponentRef4,inComponentRef5,inBoolean6,inGraph)
    local
      DAE.ComponentRef c1_1,c2_1,c1_2,c2_2;
      DAE.ExpType t1,t2;
      DAE.Properties prop1,prop2;
      SCode.Accessibility acc;
      DAE.Attributes attr1,attr2;
      Boolean flow1,impl;
      tuple<DAE.TType, Option<Absyn.Path>> ty1,ty2;
      Connect.Face f1,f2;
      Connect.Sets sets_1,sets,sets_2,sets_3;
      DAE.DAElist dae;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      Absyn.ComponentRef c1,c2;
      Env.Cache cache;
      Absyn.InnerOuter io1,io2;
      SCode.Variability vt1,vt2;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      
    case (cache,env,ih,sets,pre,c1,c2,impl,graph) /* impl */ 
      equation
        /* Skip collection of dae functions here they can not be present in connector references*/
        (cache,DAE.CREF(c1_1,t1),prop1,acc,_) = Static.elabCref(cache,env, c1, impl, false);
        (cache,DAE.CREF(c2_1,t2),prop2,acc,_) = Static.elabCref(cache,env, c2, impl, false);
        
        (cache,c1_2) = Static.canonCref(cache,env, c1_1, impl);
        (cache,c2_2) = Static.canonCref(cache,env, c2_1, impl);
        (cache,attr1 as DAE.ATTR(flow1,_,_,vt1,_,io1),ty1) = Lookup.lookupConnectorVar(cache,env,c1_2);
        (cache,attr2 as DAE.ATTR(_,_,_,vt2,_,io2),ty2) = Lookup.lookupConnectorVar(cache,env,c2_2);
        validConnector(ty1) "Check that the type of the connectors are good." ;
        validConnector(ty2);
        checkConnectTypes(env,ih,c1_2, ty1, attr1, c2_2, ty2, attr2, io1, io2);
        f1 = ConnectUtil.componentFace(env,ih,c1_2);
        f2 = ConnectUtil.componentFace(env,ih,c2_2);        
        sets_1 = ConnectUtil.updateConnectionSetTypes(sets,c1_1);
        sets_2 = ConnectUtil.updateConnectionSetTypes(sets_1,c2_1);
        /*print("add connect(");print(Exp.printComponentRefStr(c1_2));print(", ");print(Exp.printComponentRefStr(c2_2));
        print(") with ");print(Dump.unparseInnerouterStr(io1));print(", ");print(Dump.unparseInnerouterStr(io2));
        print("\n");*/
        (cache,_,ih,sets_3,dae,graph) = 
        connectComponents(cache,env,ih, sets_2, pre, c1_2, f1, ty1,vt1, c2_2, f2, ty2,vt2, flow1,io1,io2,graph);
      then
        (cache,env,ih,sets_3,dae,graph);
        
    /* adrpo: FIXME! handle expandable connectors! */
    
    // Case to display error for non constant subscripts in connectors
    case (cache,env,ih,sets,pre,c1,c2,impl,graph) 
      local
        list<Absyn.Subscript> subs1,subs2;
        list<Absyn.ComponentRef> crefs1,crefs2; 
        list<DAE.Properties> props1,props2;
        DAE.Const const;    
        Boolean b1,b2;
        String s1,s2,s3,s4;
      equation 
        subs1 = Absyn.getSubsFromCref(c1);
        crefs1 = Absyn.getCrefsFromSubs(subs1);
        subs2 = Absyn.getSubsFromCref(c2);
        crefs2 = Absyn.getCrefsFromSubs(subs2);
        //print("Crefs in " +& Dump.printComponentRefStr(c1) +& ": " +& Util.stringDelimitList(Util.listMap(crefs1,Dump.printComponentRefStr),", ") +& "\n");
        //print("Crefs in " +& Dump.printComponentRefStr(c2) +& ": " +& Util.stringDelimitList(Util.listMap(crefs2,Dump.printComponentRefStr),", ") +& "\n");
        s1 = Dump.printComponentRefStr(c1);
        s2 = Dump.printComponentRefStr(c2);
        s1 = "connect("+&s1+&", "+&s2+&")";
        checkConstantVariability(crefs1,cache,env,s1);
        checkConstantVariability(crefs2,cache,env,s1);
      then
        fail();
        
    case (cache,env,ih,sets,pre,c1,c2,impl,_)
      equation 
        Debug.fprintln("failtrace", "- Inst.instConnect failed");
      then
        fail();
  end matchcontinue;
end instConnect;

protected function checkConstantVariability "
Author BZ, 2009-09
  Helper function for instConnect, prints error message for the case with non constant(or parameter) subscript(/s) 
"
  input list<Absyn.ComponentRef> inrefs;
  input Env.Cache cache;
  input Env.Env env;
  input String affectedConnector;
algorithm props := matchcontinue(inrefs,cache,env,affectedConnector)
  local
    Absyn.ComponentRef cr;
    Boolean b2;
    DAE.Properties prop;
    DAE.Const const;
  case({},_,_,_) then ();
  case(cr::inrefs,cache,env,affectedConnector)
    equation
      (_,_,prop,_,_) = Static.elabCref(cache,env,cr,false,false);
      const = Types.elabTypePropToConst({prop});
      true = Types.isParameterOrConstant(const);
      checkConstantVariability(inrefs,cache,env,affectedConnector);
    then
      ();
  case(cr::inrefs,cache,env,affectedConnector)
    local String s1;
    equation
      (_,_,prop,_,_) = Static.elabCref(cache,env,cr,false,false);
      const = Types.elabTypePropToConst({prop});
      false = Types.isParameterOrConstant(const);
      //print(" error for: " +& affectedConnector +& " subscript: " +& Dump.printComponentRefStr(cr) +& " non constant \n");
      s1 = Dump.printComponentRefStr(cr);
      Error.addMessage(Error.CONNECTOR_ARRAY_NONCONSTANT, {affectedConnector,s1});
    then 
      ();
end matchcontinue;
end checkConstantVariability;

protected function getVectorizedCref 
"for a vectorized cref, return the originial cref without vector subscripts"
input DAE.Exp crefOrArray;
output DAE.Exp cref;
algorithm
   cref := matchcontinue(crefOrArray)
   local 
     DAE.ComponentRef cr;
     DAE.ExpType t;
     case (cref as DAE.CREF(_,_)) then cref;
     case (DAE.ARRAY(_,_,DAE.CREF(cr,t)::_)) equation
       cr = Exp.crefStripLastSubs(cr);
       then DAE.CREF(cr,t);
   end matchcontinue;
end getVectorizedCref;

protected function validConnector 
"function: validConnector 
  This function tests whether a type is a eligible to be used in connections."
  input DAE.Type inType;
algorithm 
  _ := matchcontinue (inType)
    local
      ClassInf.State state;
      tuple<DAE.TType, Option<Absyn.Path>> tp,t;
      String str;
    case ((DAE.T_REAL(varLstReal = _),_)) then (); 
    case ((DAE.T_INTEGER(_),_)) then ();
    case ((DAE.T_STRING(_),_)) then ();
    case ((DAE.T_BOOL(_),_)) then ();
    case ((DAE.T_COMPLEX(complexClassType = state),_))
      equation 
        ClassInf.valid(state, SCode.R_CONNECTOR(false));
      then
        ();
    case ((DAE.T_COMPLEX(complexClassType = state),_))
      equation 
        ClassInf.valid(state, SCode.R_CONNECTOR(true));
      then
        ();        
    case ((DAE.T_ARRAY(arrayType = tp),_))
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

protected function checkConnectTypes 
"function: checkConnectTypes 
  Check that the type and type attributes of two 
  connectors match, so that they really may be connected."
  input Env.Env env;
  input InstanceHierarchy inIH;
  input DAE.ComponentRef inComponentRef1;
  input DAE.Type inType2;
  input DAE.Attributes inAttributes3;
  input DAE.ComponentRef inComponentRef4;
  input DAE.Type inType5;
  input DAE.Attributes inAttributes6;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
algorithm 
  _ := matchcontinue (env,inIH,inComponentRef1,inType2,inAttributes3,inComponentRef4,inType5,inAttributes6,io1,io2)
    local
      String c1_str,c2_str;
      DAE.ComponentRef c1,c2;
      tuple<DAE.TType, Option<Absyn.Path>> t1,t2;
      Boolean flow1,flow2,stream1,stream2,outer1,outer2;
      InstanceHierarchy ih;
    /* If two input connectors are connected they must have different faces */
    case (env,ih,c1,_,DAE.ATTR(direction = Absyn.INPUT()),c2,_,DAE.ATTR(direction = Absyn.INPUT()),io1,io2)
      equation 
        InnerOuter.assertDifferentFaces(env, ih, c1, c2);
        c1_str = Exp.printComponentRefStr(c1);
        c2_str = Exp.printComponentRefStr(c2);
        Error.addMessage(Error.CONNECT_TWO_INPUTS, {c1_str,c2_str});
      then
        fail();

    /* If two output connectors are connected they must have different faces */
    case (env,ih,c1,_,DAE.ATTR(direction = Absyn.OUTPUT()),c2,_,DAE.ATTR(direction = Absyn.OUTPUT()),io1,io2)
      equation 
        InnerOuter.assertDifferentFaces(env, ih, c1, c2);
        c1_str = Exp.printComponentRefStr(c1);
        c2_str = Exp.printComponentRefStr(c2);
        Error.addMessage(Error.CONNECT_TWO_OUTPUTS, {c1_str,c2_str});
      then
        fail();

    /* The type must be identical and flow of connected variables must be same */
    case (env,ih,_,t1,DAE.ATTR(flowPrefix = flow1),_,t2,DAE.ATTR(flowPrefix = flow2),io1,io2)
      equation 
        equality(flow1 = flow2);
        true = Types.equivtypes(t1, t2) "we do not check arrays here";
        outer1 = ModUtil.isPureOuter(io1);
        outer2 = ModUtil.isPureOuter(io2);
        false = boolAnd(outer2,outer1) "outer to outer illegal";
      then
        ();

    case (_,_,c1,_,_,c2,_,_,io1,io2)
      equation 
        true = ModUtil.isPureOuter(io1);
        true = ModUtil.isPureOuter(io2);
        c1_str = Exp.printComponentRefStr(c1);
        c2_str = Exp.printComponentRefStr(c2);
        Error.addMessage(Error.CONNECT_OUTER_OUTER, {c1_str,c2_str});
      then
        fail();
        
    case (env,ih,c1,_,DAE.ATTR(flowPrefix = true),c2,_,DAE.ATTR(flowPrefix = false),io1,io2)
      equation
        c1_str = Exp.printComponentRefStr(c1);
        c2_str = Exp.printComponentRefStr(c2);
        Error.addMessage(Error.CONNECT_FLOW_TO_NONFLOW, {c1_str,c2_str});
      then
        fail();
        
    case (env,ih,c1,_,DAE.ATTR(flowPrefix = false),c2,_,DAE.ATTR(flowPrefix = true),io1,io2)
      equation 
        c1_str = Exp.printComponentRefStr(c1);
        c2_str = Exp.printComponentRefStr(c2);
        Error.addMessage(Error.CONNECT_FLOW_TO_NONFLOW, {c2_str,c1_str});
      then
        fail();
        
    case (env,ih,_,t1,DAE.ATTR(streamPrefix = stream1, flowPrefix = false),_,t2,DAE.ATTR(streamPrefix = stream2, flowPrefix = false),io1,io2)
      equation
        equality(stream1 = stream2);
        true = Types.equivtypes(t1, t2);
      then
        ();
        
    case (env,ih,c1,_,DAE.ATTR(streamPrefix = true, flowPrefix = false),c2,_,DAE.ATTR(streamPrefix = false, flowPrefix = false),io1,io2)
      equation
        c1_str = Exp.printComponentRefStr(c1);
        c2_str = Exp.printComponentRefStr(c2);
        Error.addMessage(Error.CONNECT_STREAM_TO_NONSTREAM, {c1_str,c2_str});
      then
        fail();
        
    case (env,ih,c1,_,DAE.ATTR(streamPrefix = false, flowPrefix = false),c2,_,DAE.ATTR(streamPrefix = true, flowPrefix = false),io1,io2)
      equation
        c1_str = Exp.printComponentRefStr(c1);
        c2_str = Exp.printComponentRefStr(c2);
        Error.addMessage(Error.CONNECT_STREAM_TO_NONSTREAM, {c2_str,c1_str});
      then
        fail(); 
    /* The type is not identical hence error */
    case (env,ih,c1,t1,DAE.ATTR(flowPrefix = flow1),c2,t2,DAE.ATTR(flowPrefix = flow2),io1,io2)
      local String s1,s2,s3,s4,s1_1,s2_2;
      equation
        (t1,_) = Types.flattenArrayType(t1);
        (t2,_) = Types.flattenArrayType(t2);
        false = Types.equivtypes(t1, t2) "we do not check arrays here";        
        (s1,s1_1) = Types.printConnectorTypeStr(t1);
        (s2,s2_2) = Types.printConnectorTypeStr(t2);
        s3 = Exp.printComponentRefStr(c1);
        s4 = Exp.printComponentRefStr(c2);
        Error.addMessage(Error.CONNECT_INCOMPATIBLE_TYPES, {s3,s4,s3,s1_1,s4,s2_2});
      then
        fail();
        
    /* Different dimensionality */
    case (env,ih,c1,t1,DAE.ATTR(flowPrefix = flow1),c2,t2,DAE.ATTR(flowPrefix = flow2),io1,io2)
      local 
        String s1,s2,s3,s4,s1_1,s2_2;
        list<Integer> iLst1,iLst2;
      equation
        (t1,iLst1) = Types.flattenArrayType(t1);
        (t2,iLst2) = Types.flattenArrayType(t2);
        false = Util.isListEqualWithCompareFunc(iLst1,iLst2,intEq);
        false = (listLength(iLst1)+listLength(iLst2) ==0);
        s1 = Exp.printComponentRefStr(c1);
        s2 = Exp.printComponentRefStr(c2);
        Error.addMessage(Error.CONNECTOR_ARRAY_DIFFERENT, {s1,s2});
      then
        fail();
        
    case (env,_,c1,_,_,c2,_,_,io1,io2)
      equation
				true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- Inst.checkConnectTypes(" +& 
          Exp.printComponentRefStr(c1) +& " <-> " +& 
          Exp.printComponentRefStr(c2) +& " failed");
      then
        fail();

    case (env,ih,c1,t1,DAE.ATTR(flowPrefix = flow1),c2,t2,DAE.ATTR(flowPrefix = flow2),io1,io2)
      local DAE.Type t1,t2; Boolean flow1,flow2,b0; String s0,s1,s2;
      equation 
				true = RTOpts.debugFlag("failtrace");
        b0 = Types.equivtypes(t1, t2);
        s0 = Util.if_(b0,"types equivalent;","types NOT equivalent");
        s1 = Util.if_(flow1,"flow "," ");
        s2 = Util.if_(flow2,"flow "," ");        
        Debug.fprint("failtrace", "- check_connect_types(");
        Debug.fprint("failtrace", s0);        
        Debug.fprint("failtrace", Exp.printComponentRefStr(c1));
        Debug.fprint("failtrace", " : ");        
        Debug.fprint("failtrace", s1);        
        Debug.fprint("failtrace", Types.unparseType(t1));        
        
        Debug.fprint("failtrace", Exp.printComponentRefStr(c1));        
        Debug.fprint("failtrace", " <-> ");
        Debug.fprint("failtrace", Exp.printComponentRefStr(c2));
        Debug.fprint("failtrace", " : ");     
        Debug.fprint("failtrace", s2);                   
        Debug.fprint("failtrace", Types.unparseType(t2));
        Debug.fprint("failtrace", ") failed\n");
      then
        fail();
  end matchcontinue;
end checkConnectTypes;

public function connectComponents " 
  This function connects two components and generates connection
  sets along the way.  For simple components (of type Real) it
  adds the components to the set, and for complex types it traverses
  the subcomponents and recursively connects them to each other.
  A DAE.Element list is returned for assert statements."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Connect.Sets inSets;
  input Prefix inPrefix3;
  input DAE.ComponentRef cr1;
  input Connect.Face inFace5;
  input DAE.Type inType6;
  input SCode.Variability vt1;
  input DAE.ComponentRef cr2;
  input Connect.Face inFace8;
  input DAE.Type inType9;
  input SCode.Variability vt2;  
  input Boolean inBoolean10;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output Connect.Sets outSets;
  output DAE.DAElist outDae;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outSets,outDae,outGraph) := 
  matchcontinue (inCache,inEnv,inIH,inSets,inPrefix3,cr1,inFace5,inType6,vt1,cr2,inFace8,inType9,vt2,inBoolean10,io1,io2,inGraph)
    local
      DAE.ComponentRef c1_1,c2_1,c1,c2;
      list<DAE.ComponentRef> dc;
      Connect.Sets sets_1,sets;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      Connect.Face f1,f2;
      tuple<DAE.TType, Option<Absyn.Path>> t1,t2,bc_tp1,bc_tp2;
      SCode.Variability vr;
      Integer dim1,dim2;
      DAE.DAElist dae, dae2;
      list<DAE.Var> l1,l2;
      Boolean flowPrefix;
      String c1_str,t1_str,t2_str,c2_str;
      Env.Cache cache;
      Absyn.InnerOuter io1,io2;
      Boolean c1outer,c2outer;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      DAE.FunctionTree funcs;
      
    /* connections to outer components */      
    case(cache,env,ih,sets,pre,c1,f1,t1,vt1,c2,f2,t2,vt2,flowPrefix,io1,io2,graph) 
      equation      
        true = InnerOuter.outerConnection(io1,io2);
        c1_1 = PrefixUtil.prefixCref(pre, c1);
        c2_1 = PrefixUtil.prefixCref(pre, c2);
        /* The cref that is outer should not be prefixed */
        (c1outer,c2outer) = InnerOuter.referOuter(io1,io2);
        c1_1 = Util.if_(c1outer,c1,c1_1);
        c2_1 = Util.if_(c2outer,c2,c2_1);

        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());
        
        sets = ConnectUtil.addOuterConnection(pre,sets,c1_1,c2_1,io1,io2,f1,f2,source);

      then (cache,env,ih,sets,DAEUtil.emptyDae,graph);

    /* flow - with a subtype of Real */ 
    case (cache,env,ih,sets,pre,c1,f1,(DAE.T_REAL(varLstReal = _),_),vt1,c2,f2,(DAE.T_REAL(varLstReal = _),_),vt2,true,io1,io2,graph) 
      equation 
        c1_1 = PrefixUtil.prefixCref(pre, c1);
        c2_1 = PrefixUtil.prefixCref(pre, c2);
        
        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());
                
        sets_1 = ConnectUtil.addFlow(sets, c1_1, f1, c2_1, f2, source);
      then
        (cache,env,ih,sets_1,DAEUtil.emptyDae,graph);
        
    /* flow - with arrays */ 
    case (cache,env,ih,sets,pre,c1,f1,(DAE.T_ARRAY(arrayDim = DAE.DIM(integerOption = SOME(dim1)),arrayType = t1),_),vt1,c2,f2,(DAE.T_ARRAY(arrayType = t2),_),vt2,true,io1,io2,graph)
      equation 
        ((DAE.T_REAL(_),_)) = Types.arrayElementType(t1);
        ((DAE.T_REAL(_),_)) = Types.arrayElementType(t2);
        c1_1 = PrefixUtil.prefixCref(pre, c1);
        c2_1 = PrefixUtil.prefixCref(pre, c2);
        
        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());
        
        sets_1 = ConnectUtil.addArrayFlow(sets, c1_1, f1, c2_1, f2, dim1, source);
      then
        (cache,env,ih,sets_1,DAEUtil.emptyDae,graph);

    /* Non-flow type Parameters and constants generate assert statements */ 
    case (cache,env,ih,sets as(Connect.SETS(deletedComponents=dc)),pre,c1,f1,t1,vt1,c2,f2,t2,vt2,false,io1,io2,graph)
      local list<Boolean> bolist,bolist2;
      equation        
        c1_1 = PrefixUtil.prefixCref(pre, c1);
        c2_1 = PrefixUtil.prefixCref(pre, c2);
        bolist = Util.listMap1(dc,Exp.crefNotPrefixOf,c1_1);
        bolist2 = Util.listMap1(dc,Exp.crefNotPrefixOf,c2_1);
        bolist = listAppend(bolist,bolist2);
        true = Util.listFold(bolist,boolAnd,true);
        true = SCode.isParameterOrConst(vt1) and SCode.isParameterOrConst(vt2) ;
        true = Types.basicType(t1);
        true = Types.basicType(t2);
        
        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());
        
        funcs = DAEUtil.avlTreeNew();
      then
        (cache,env,ih,sets,DAE.DAE({
          DAE.ASSERT(
            DAE.RELATION(DAE.CREF(c1_1,DAE.ET_REAL()),DAE.EQUAL(DAE.ET_BOOL()),DAE.CREF(c2_1,DAE.ET_REAL())),
            DAE.SCONST("automatically generated from connect"),
            source) // set the origin of the element
          },funcs),graph);

    /* Same as above, but returns empty (removed conditional var) */ 
    case (cache,env,ih,sets,pre,c1,f1,t1,vt1,c2,f2,t2,vt2,false,io1,io2,graph)
      equation
        c1_1 = PrefixUtil.prefixCref(pre, c1);
        c2_1 = PrefixUtil.prefixCref(pre, c2);
        true = SCode.isParameterOrConst(vt1) and SCode.isParameterOrConst(vt2) ;
        true = Types.basicType(t1);
        true = Types.basicType(t2);
        //print("  Same as above, but returns empty (removed conditional var)\n");
      then
        (cache,env,ih,sets,DAEUtil.emptyDae,graph);

    /* connection of two Reals */
    case (cache,env,ih,sets,pre,c1,_,(DAE.T_REAL(varLstReal = _),_),vt1,c2,_,(DAE.T_REAL(varLstReal = _),_),vt2,false,io1,io2,graph)
      equation         
        c1_1 = PrefixUtil.prefixCref(pre, c1);
        c2_1 = PrefixUtil.prefixCref(pre, c2);
        
        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());
                
        sets_1 = ConnectUtil.addEqu(sets, c1_1, c2_1, source);
      then
        (cache,env,ih,sets_1,DAEUtil.emptyDae,graph);

    /* connection of to Integers */        
    case (cache,env,ih,sets,pre,c1,_,(DAE.T_INTEGER(varLstInt = _),_),vt1,c2,_,(DAE.T_INTEGER(varLstInt = _),_),vt2,false,io1,io2,graph)
      equation         
        c1_1 = PrefixUtil.prefixCref(pre, c1);
        c2_1 = PrefixUtil.prefixCref(pre, c2);
        
        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());
        
        sets_1 = ConnectUtil.addEqu(sets, c1_1, c2_1, source);
      then
        (cache,env,ih,sets_1,DAEUtil.emptyDae,graph);
        
    /* connection of two Booleans */
    case (cache,env,ih,sets,pre,c1,_,(DAE.T_BOOL(_),_),vt1,c2,_,(DAE.T_BOOL(_),_),vt2,false,io1,io2,graph)
      equation 
        c1_1 = PrefixUtil.prefixCref(pre, c1);
        c2_1 = PrefixUtil.prefixCref(pre, c2); 
        
        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());
        
        sets_1 = ConnectUtil.addEqu(sets, c1_1, c2_1, source);
      then
        (cache,env,ih,sets_1,DAEUtil.emptyDae,graph);

    /* Connection of two Strings */
    case (cache,env,ih,sets,pre,c1,_,(DAE.T_STRING(_),_),vt1,c2,_,(DAE.T_STRING(_),_),vt2,false,io1,io2,graph)
      equation 
        c1_1 = PrefixUtil.prefixCref(pre, c1);
        c2_1 = PrefixUtil.prefixCref(pre, c2);

        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());
        
        sets_1 = ConnectUtil.addEqu(sets, c1_1, c2_1, source);
      then
        (cache,env,ih,sets_1,DAEUtil.emptyDae,graph);

    /* Connection of arrays of complex types */        
    case (cache,env,ih,sets,pre,c1,f1,(DAE.T_ARRAY(arrayDim = DAE.DIM(integerOption = SOME(dim1)),arrayType = t1),_),vt1,c2,f2,(DAE.T_ARRAY(arrayDim = DAE.DIM(integerOption = SOME(dim2)),arrayType = t2),_),vt2,flowPrefix,io1,io2,graph)
      equation         
        ((DAE.T_COMPLEX(complexClassType=_),_)) = Types.arrayElementType(t1);
        ((DAE.T_COMPLEX(complexClassType=_),_)) = Types.arrayElementType(t2);        

        equality(dim1 = dim2);
        
        (cache,_,ih,sets_1,dae,graph) = connectArrayComponents(cache,env,ih,sets,pre,c1,f1,t1,vt1,c2,f2,t2,vt2,flowPrefix,io1,io2,dim1,1,graph);
      then
        (cache,env,ih,sets_1,dae,graph);
        
    /* Connection of arrays */
    case (cache,env,ih,sets,pre,c1,f1,(DAE.T_ARRAY(arrayDim = DAE.DIM(integerOption = SOME(dim1)),arrayType = t1),_),vt1,c2,f2,(DAE.T_ARRAY(arrayDim = DAE.DIM(integerOption = SOME(dim2)),arrayType = t2),_),vt2,false,io1,io2,graph)
      local
        list<Option<Integer>> odims,odims2;
        list<Integer> dims,dims2;
      equation         
        c1_1 = PrefixUtil.prefixCref(pre, c1);
        c2_1 = PrefixUtil.prefixCref(pre, c2); 
        DAE.ET_ARRAY(_,odims) = Types.elabType(inType6);
        DAE.ET_ARRAY(_,odims2) = Types.elabType(inType9);
        dims = Util.listFlatten(Util.listMap(odims,Util.genericOption));
        dims2 = Util.listFlatten(Util.listMap(odims2,Util.genericOption));        
        equality(dims = dims2);
        
        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());
                
        sets_1 = ConnectUtil.addMultiArrayEqu(sets, c1_1, c2_1, dims, source);
      then
        (cache,env,ih,sets_1,DAEUtil.emptyDae,graph);
        
    /* Connection of connectors with an equality constraint.*/
    case (cache,env,ih,sets,pre,c1,f1,t1 as (DAE.T_COMPLEX(equalityConstraint=SOME((fpath1,dim1))),_),vt1,
                                c2,f2,t2 as (DAE.T_COMPLEX(equalityConstraint=SOME((fpath2,dim2))),_),vt2,
                                flowPrefix,io1,io2,
        (graph as ConnectionGraph.GRAPH(updateGraph = true))) 
      local
        Absyn.Path fpath1, fpath2;
        Integer dim1, dim2;
        DAE.Exp zeroVector;
      equation
        c1_1 = PrefixUtil.prefixCref(pre, c1);
        c2_1 = PrefixUtil.prefixCref(pre, c2);
        // Connect components ignoring equality constraints 
        (cache,env,ih,sets_1,dae,_) = 
        connectComponents(
          cache,env,ih,sets, pre, 
          c1, f1, t1, vt1, 
          c2, f2, t2, vt2, 
          flowPrefix, io1, io2, ConnectionGraph.NOUPDATE_EMPTY);
          
        /* We can form the daes from connection set already at this point
           because there must not be flow components in types having equalityConstraint. 
           TODO Is this correct if inner/outer has been used? */
        //dae2 = ConnectUtil.equations(sets_1,pre);
        //dae = listAppend(dae, dae2);
        //DAE.printDAE(DAE.DAE(dae));

        // set the source of this element
        source = DAEUtil.createElementSource(Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());
        
        /* Add an edge to connection graph. The edge contains daes to be added in 
           both cases whether the edge remains or is broken.
         */
        zeroVector = Exp.makeRealArrayOfZeros(dim1);
        graph = ConnectionGraph.addConnection(graph, c1_1, c2_1,  
          {DAE.EQUATION(zeroVector, 
                        DAE.CALL(fpath1,{DAE.CREF(c1_1, DAE.ET_OTHER()), DAE.CREF(c2_1, DAE.ET_OTHER())}, 
                                 false, false, DAE.ET_REAL,DAE.NO_INLINE),
                        source // set the origin of the element
          )});
      then
        (cache,env,ih,sets_1,dae,graph);

    /* Complex types t1 extending basetype */ 
    case (cache,env,ih,sets,pre,c1,f1,(DAE.T_COMPLEX(complexVarLst = l1,complexTypeOption = SOME(bc_tp1)),_),vt1,c2,f2,t2,vt2,flowPrefix,io1,io2,graph) 
      equation         
        (cache,_,ih,sets_1,dae,graph) = connectComponents(cache,env,ih, sets, pre, c1, f1, bc_tp1,vt1, c2, f2, t2,vt2, flowPrefix,io1,io2,graph);
      then
        (cache,env,ih,sets_1,dae,graph);

    /* Complex types t2 extending basetype */ 
    case (cache,env,ih,sets,pre,c1,f1,t1,vt1,c2,f2,(DAE.T_COMPLEX(complexVarLst = l1,complexTypeOption = SOME(bc_tp2)),_),vt2,flowPrefix,io1,io2,graph) 
      equation        
        (cache,_,ih,sets_1,dae,graph) = connectComponents(cache,env,ih, sets, pre, c1, f1, t1, vt1,c2, f2, bc_tp2,vt2, flowPrefix,io1,io2,graph);
      then
        (cache,env,ih,sets_1,dae,graph);
        
    /* Connection of complex connector, e.g. Pin */
    case (cache,env,ih,sets,pre,c1,f1,(DAE.T_COMPLEX(complexVarLst = l1),_),vt1,c2,f2,(DAE.T_COMPLEX(complexVarLst = l2),_),vt2,_,io1,io2,graph) 
      equation         
        c1_1 = PrefixUtil.prefixCref(pre, c1);
        c2_1 = PrefixUtil.prefixCref(pre, c2);
        (cache,_,ih,sets_1,dae,graph) = connectVars(cache,env,ih, sets, c1_1, f1, l1,vt1, c2_1, f2, l2,vt2,io1,io2,graph);
      then
        (cache,env,ih,sets_1,dae,graph);

    /* Error */ 
    case (cache,env,ih,_,pre,c1,_,t1,vt1,c2,_,t2,vt2,_,io1,io2,_) 
      equation         
        c1_1 = PrefixUtil.prefixCref(pre, c1);
        c2_1 = PrefixUtil.prefixCref(pre, c2);
        c1_str = Exp.printComponentRefStr(c1);
        t1_str = Types.unparseType(t1);
        c2_str = Exp.printComponentRefStr(c2);
        t2_str = Types.unparseType(t2);
        c1_str = Util.stringAppendList({c1_str," and ",c2_str});
        t1_str = Util.stringAppendList({t1_str," and ",t2_str});
        Error.addMessage(Error.INVALID_CONNECTOR_VARIABLE, {c1_str,t1_str});
      then
        fail();
        
    case (cache,env,ih,_,pre,c1,_,t1,vt1,c2,_,t2,vt2,_,_,_,_)
      equation 
        print("-Inst.connectComponents failed\n");
      then
        fail();
  end matchcontinue;
end connectComponents;

protected function connectArrayComponents "
 Help functino to connectComponents 
Traverses arrays of complex connectors and calls connectComponents for each index
"
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;	
  input Connect.Sets inSets;
  input Prefix inPrefix3;
  input DAE.ComponentRef cr1;
  input Connect.Face inFace5;
  input DAE.Type inType6;
  input SCode.Variability vt1;  
  input DAE.ComponentRef cr2;
  input Connect.Face inFace8;
  input DAE.Type inType9;
  input SCode.Variability vt2;  
  input Boolean inBoolean10;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  input Integer dim1;
  input Integer i "current index";
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output Connect.Sets outSets;
  output DAE.DAElist outDae;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outSets,outDae,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inSets,inPrefix3,cr1,inFace5,inType6,vt1,cr2,inFace8,inType9,vt2,inBoolean10,io1,io2,dim1,i,inGraph)
    local
      DAE.ComponentRef c1_1,c2_1,c1,c2,c21,c11;
      Connect.Sets sets_1,sets;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      Connect.Face f1,f2;
      tuple<DAE.TType, Option<Absyn.Path>> t1,t2,bc_tp1,bc_tp2;
      SCode.Variability vr;
      Integer dim1,dim2;
      DAE.DAElist dae,dae1,dae2;
      list<DAE.Var> l1,l2;
      Boolean flowPrefix;
      String c1_str,t1_str,t2_str,c2_str;
      Env.Cache cache;
      Absyn.InnerOuter io1,io2;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      
    case(cache,env,ih,sets,pre,c1,f1,t1,vt1,c2,f2,t2,vt2,flowPrefix,io1,io2,dim1,i,graph)
      equation
        true = (dim1 == i);
        c1 = Exp.replaceCrefSliceSub(c1,{DAE.INDEX(DAE.ICONST(i))});
        c2 = Exp.replaceCrefSliceSub(c2,{DAE.INDEX(DAE.ICONST(i))});
        (cache,_,ih,sets_1,dae,graph)= connectComponents(cache,env,ih,sets,pre,c1,f1,t1,vt1,c2,f2,t2,vt2,flowPrefix,io1,io2,graph);
      then (cache,env,ih,sets_1,dae,graph);

    case(cache,env,ih,sets,pre,c1,f1,t1,vt1,c2,f2,t2,vt2,flowPrefix,io1,io2,dim1,i,graph)
      equation     
        c11 = Exp.replaceCrefSliceSub(c1,{DAE.INDEX(DAE.ICONST(i))});
        c21 = Exp.replaceCrefSliceSub(c2,{DAE.INDEX(DAE.ICONST(i))});
        (cache,_,ih,sets_1,dae1,graph)= connectComponents(cache,env,ih,sets,pre,c11,f1,t1,vt1,c21,f2,t2,vt2,flowPrefix,io1,io2,graph);
        (cache,_,ih,sets_1,dae2,graph) = connectArrayComponents(cache,env,ih,sets_1,pre,c1,f1,t1,vt1,c2,f2,t2,vt2,flowPrefix,io1,io2,dim1,i+1,graph);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then (cache,env,ih,sets_1,dae,graph);
  end matchcontinue;
end connectArrayComponents;

protected function connectVars
"function: connectVars 
  This function connects two subcomponents by adding the component
  name to the current path and recursively connecting the components
  using the function connectComponents."
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Connect.Sets inSets;
  input DAE.ComponentRef inComponentRef3;
  input Connect.Face inFace4;
  input list<DAE.Var> inTypesVarLst5;
  input SCode.Variability vt1;
  input DAE.ComponentRef inComponentRef6;
  input Connect.Face inFace7;
  input list<DAE.Var> inTypesVarLst8;
  input SCode.Variability vt2;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;  
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output Connect.Sets outSets;
  output DAE.DAElist outDae;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outSets,outDae,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inSets,inComponentRef3,inFace4,inTypesVarLst5,vt1,inComponentRef6,inFace7,inTypesVarLst8,vt2,io1,io2,inGraph)
    local
      Connect.Sets sets,sets_1,sets_2;
      list<Env.Frame> env;
      DAE.ComponentRef c1_1,c2_1,c1,c2;
      DAE.DAElist dae,dae2,dae_1;
      Connect.Face f1,f2;
      String n;
      DAE.Attributes attr1,attr2;
      Boolean flow1,flow2,stream1,stream2;
      SCode.Variability vt1,vt2;
      tuple<DAE.TType, Option<Absyn.Path>> ty1,ty2;
      list<DAE.Var> xs1,xs2;
      SCode.Variability vta,vtb;
      DAE.ExpType ty_2,ty_22;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      
    case (cache,env,ih,sets,_,_,{},vt1,_,_,{},vt2,io1,io2,graph) 
      then (cache,env,ih,sets,DAEUtil.emptyDae,graph); 
    case (cache,env,ih,sets,c1,f1,(DAE.TYPES_VAR(name = n,attributes = (attr1 as DAE.ATTR(flowPrefix = flow1,parameter_ = vta)),type_ = ty1) :: xs1),vt1,
                         c2,f2,(DAE.TYPES_VAR(attributes = (attr2 as DAE.ATTR(flowPrefix = flow2,parameter_ = vtb)),type_ = ty2) :: xs2),vt2,io1,io2,graph)
      equation 
        ty_2 = Types.elabType(ty1);
        c1_1 = Exp.extendCref(c1, ty_2, n, {});
        c2_1 = Exp.extendCref(c2, ty_2, n, {});
        checkConnectTypes(env,ih, c1_1, ty1, attr1, c2_1, ty2, attr2,io1,io2);
        (cache,_,ih,sets_1,dae,graph) = connectComponents(cache,env,ih,sets, Prefix.NOPRE(), c1_1, f1, ty1,vta, c2_1, f2, ty2,vtb,flow1,io1,io2,graph);
        (cache,_,ih,sets_2,dae2,graph) = connectVars(cache,env,ih,sets_1, c1, f1, xs1,vt1, c2, f2, xs2,vt2,io1,io2,graph);
        dae_1 = DAEUtil.joinDaes(dae, dae2);
      then
        (cache,env,ih,sets_2,dae_1,graph);
  end matchcontinue;
end connectVars;

public function mktype 
"function: mktype
  From a class typename, its inference state, and a list of subcomponents,
  this function returns DAE.Type.  If the class inference state
  indicates that the type should be a built-in type, one of the
  built-in type constructors is used.  Otherwise, a T_COMPLEX is
  built."
  input Absyn.Path inPath;
  input ClassInf.State inState;
  input list<DAE.Var> inTypesVarLst;
  input Option<DAE.Type> inTypesTypeOption;
  input DAE.EqualityConstraint inEqualityConstraint;
  input SCode.Class inClass;
  output DAE.Type outType;
algorithm 
  outType := matchcontinue (inPath,inState,inTypesVarLst,inTypesTypeOption,inEqualityConstraint,inClass)
    local
      Option<Absyn.Path> somep;
      Absyn.Path p;
      list<DAE.Var> v,vl,v1,l;
      tuple<DAE.TType, Option<Absyn.Path>> functype,enumtype;
      ClassInf.State st;
      String name;
      Option<tuple<DAE.TType, Option<Absyn.Path>>> bc;
      SCode.Class cl;
    case (p,ClassInf.TYPE_INTEGER(path = _),v,_,_,_)
      equation 
        somep = getOptPath(p);
      then
        ((DAE.T_INTEGER(v),somep));
    case (p,ClassInf.TYPE_REAL(path = _),v,_,_,_)
      equation 
        somep = getOptPath(p);
      then
        ((DAE.T_REAL(v),somep));
    case (p,ClassInf.TYPE_STRING(path = _),v,_,_,_)
      equation
        somep = getOptPath(p);
      then
        ((DAE.T_STRING(v),somep));
    case (p,ClassInf.TYPE_BOOL(path = _),v,_,_,_)
      equation
        somep = getOptPath(p);
      then
        ((DAE.T_BOOL(v),somep));
    case (p,ClassInf.TYPE_ENUM(path = _),_,_,_,_)
//        local SCode.Class sclass; list<SCode.Element> eLst; list<String> names;
      equation 
        
//       (_,sclass as SCode.CLASS(_,_,_,SCode.R_ENUMERATION(),SCode.PARTS(eLst,_,_,_,_,_,_)),_) = Lookup.lookupClass(cache,env,Absyn.IDENT(id),true);
        somep = getOptPath(p);
      then
        ((DAE.T_ENUMERATION(SOME(0),Absyn.IDENT(""),{},{}),somep));
//        ((DAE.T_ENUM(),somep));
    /* Insert function type construction here after checking input/output arguments? see Types.mo T_FUNCTION */        
    case (p,(st as ClassInf.FUNCTION(path = _)),vl,_,_,cl)
      equation
        functype = Types.makeFunctionType(p, vl, isInlineFunc2(cl));
      then
        functype;
    case (p,ClassInf.ENUMERATION(path = _),v1,_,_,_)
      equation 
        enumtype = Types.makeEnumerationType(p, v1);
      then
        enumtype;
		/* Array of type extending from base type. */
		case (_, ClassInf.TYPE(path = _), _, SOME((DAE.T_ARRAY(_, (arrayType, _)), _)), _, _)
			local
				DAE.TType arrayType;
				DAE.Type resType;
				ClassInf.State classState;
			equation
				classState = arrayTTypeToClassInfState(arrayType);
				resType = mktype(inPath, classState, inTypesVarLst, inTypesTypeOption, inEqualityConstraint, inClass);
			then resType;

    /* MetaModelica extension */
    case (p,ClassInf.META_TUPLE(_),_,SOME(bc2),_,_)local DAE.Type bc2; equation then bc2;
    case (p,ClassInf.META_OPTION(_),_,SOME(bc2),_,_) local DAE.Type bc2; equation then bc2;
    case (p,ClassInf.META_LIST(_),_,SOME(bc2),_,_) local DAE.Type bc2; equation then bc2;
    case (p,ClassInf.META_POLYMORPHIC(_),_,SOME(bc2),_,_) local DAE.Type bc2; equation then bc2;
    case (p,ClassInf.META_ARRAY(_),_,SOME(bc2),_,_) local DAE.Type bc2; equation then bc2;
    /*------------------------*/

    case (p,st,l,bc,equalityConstraint,_)
      local
        DAE.EqualityConstraint equalityConstraint;
      equation 
        somep = getOptPath(p);
      then
        ((DAE.T_COMPLEX(st,l,bc,equalityConstraint),somep));
  end matchcontinue;
end mktype;

protected function arrayTTypeToClassInfState
	input DAE.TType arrayType;
	output ClassInf.State classInfState;
algorithm
	classInfState := matchcontinue(arrayType)
		case (DAE.T_INTEGER(_)) then ClassInf.TYPE_INTEGER(Absyn.IDENT(""));
		case (DAE.T_REAL(_)) then ClassInf.TYPE_REAL(Absyn.IDENT(""));
		case (DAE.T_STRING(_)) then ClassInf.TYPE_STRING(Absyn.IDENT(""));
		case (DAE.T_BOOL(_)) then ClassInf.TYPE_BOOL(Absyn.IDENT(""));
		case (DAE.T_ARRAY(arrayType = (t, _)))
		  local
		    DAE.TType t;
		    ClassInf.State cs;
		  equation
		    cs = arrayTTypeToClassInfState(t);
		  then cs;
	end matchcontinue;
end arrayTTypeToClassInfState;

protected function mktypeWithArrays 
"function: mktypeWithArrays
  author: PA
  This function is similar to mktype with the exception
  that it will create array types based on the last argument,
  which indicates wheter the class extends from a basictype.
  It is used only in the inst_class_basictype function."
  input Absyn.Path inPath;
  input ClassInf.State inState;
  input list<DAE.Var> inTypesVarLst;
  input Option<DAE.Type> inTypesTypeOption;
  input SCode.Class inClass;
  output DAE.Type outType;
algorithm 
  outType := matchcontinue (inPath,inState,inTypesVarLst,inTypesTypeOption,inClass)
    local
      Absyn.Path p;
      ClassInf.State ci,st;
      list<DAE.Var> vs,v,vl,v1,l;
      tuple<DAE.TType, Option<Absyn.Path>> tp,functype,enumtype;
      Option<Absyn.Path> somep;
      String name;
      SCode.Class cl;
      Option<tuple<DAE.TType, Option<Absyn.Path>>> bc;
    case (p,ci,vs,SOME(tp),_)
      equation 
        true = Types.isArray(tp);
        failure(ClassInf.isConnector(ci));
      then
        tp;
    case (p,ClassInf.TYPE_INTEGER(path = _),v,_,_)
      equation 
        somep = getOptPath(p);
      then
        ((DAE.T_INTEGER(v),somep));
    case (p,ClassInf.TYPE_REAL(path = _),v,_,_)
      equation 
        somep = getOptPath(p);
      then
        ((DAE.T_REAL(v),somep));
    case (p,ClassInf.TYPE_STRING(path = _),v,_,_)
      equation 
        somep = getOptPath(p);
      then
        ((DAE.T_STRING(v),somep));
    case (p,ClassInf.TYPE_BOOL(path = _),v,_,_)
      equation 
        somep = getOptPath(p);
      then
        ((DAE.T_BOOL(v),somep));
    case (p,ClassInf.TYPE_ENUM(path = _),_,_,_)
      equation 
        somep = getOptPath(p);
      then
        ((DAE.T_ENUMERATION(SOME(0),p,{},{}),somep));
//        ((DAE.T_ENUM(),somep));
    /* Insert function type construction here after checking input/output arguments? see Types.mo T_FUNCTION */ 
    case (p,(st as ClassInf.FUNCTION(path = _)),vl,_,cl)
      equation 
        functype = Types.makeFunctionType(p, vl, isInlineFunc2(cl));
      then
        functype;
    case (p,ClassInf.ENUMERATION(path = _),v1,_,_)
      equation 
        enumtype = Types.makeEnumerationType(p, v1);
      then
        enumtype;
    case (p,st,l,bc,_)
      equation 
        somep = getOptPath(p);
      then
        ((DAE.T_COMPLEX(st,l,bc,NONE /* HN ??? */),somep));

    case (p,st,l,bc,_)
      equation 
        print("Inst.mktypeWithArrays failed\n");
      then fail();
        
  end matchcontinue;
end mktypeWithArrays;

protected function getOptPath 
"function: getOptPath  
  Helper function to mktype
  Transforms a Path into a Path option."
  input Absyn.Path inPath;
  output Option<Absyn.Path> outAbsynPathOption;
algorithm 
  outAbsynPathOption := matchcontinue (inPath)
    local Absyn.Path p;
    case Absyn.IDENT(name = "") then NONE; 
    case p then SOME(p); 
  end matchcontinue;
end getOptPath;

protected function instList 
"function: instList 
  This is a utility used to do instantiation of list
  of things, collecting the result in another list."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input InstFunc instFunc;
  input list<Type_a> inTypeALst;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;  
  partial function InstFunc
  	input Env.Cache inCache;
    input Env inEnv;
    input InstanceHierarchy inIH;
    input Mod inMod;
    input Prefix inPrefix;
    input Connect.Sets inSets;
    input ClassInf.State inState;
    input Type_a inTypeA;
    input Boolean inBoolean;
    input ConnectionGraph.ConnectionGraph inGraph;
    output Env.Cache outCache;
    output Env outEnv;
    output InstanceHierarchy outIH;
    output DAE.DAElist outDAe;
    output Connect.Sets outSets;
    output ClassInf.State outState;
    output ConnectionGraph.ConnectionGraph outGraph;
    replaceable type Type_a subtypeof Any;
  end InstFunc;
  replaceable type Type_a subtypeof Any;
algorithm 
  (outCache,outEnv,outIH,outTypeBLst,outSets,outState,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,instFunc,inTypeALst,inBoolean,inGraph)
    local
      partial function InstFunc2
      	input Env.Cache inCache;
        input Env inEnvFrameLst;
        input InstanceHierarchy inIH;
        input DAE.Mod inMod;
        input Prefix.Prefix inPrefix;
        input Connect.Sets inSets;
        input ClassInf.State inState;
        input Type_a inTypeA;
        input Boolean inBoolean;
        input ConnectionGraph.ConnectionGraph inGraph;
        output Env.Cache outCache;
        output Env outEnvFrameLst;
        output InstanceHierarchy outIH;
        output DAE.DAElist outDae;        
        output Connect.Sets outSets;
        output ClassInf.State outState;
        output ConnectionGraph.ConnectionGraph outGraph;  
      end InstFunc2;
      list<Env.Frame> env,env_1,env_2;
      DAE.Mod mod;
      Prefix.Prefix pre;
      Connect.Sets csets,csets_1,csets_2;
      ClassInf.State ci_state,ci_state_1,ci_state_2;
      InstFunc2 r;
      Boolean impl;
      DAE.DAElist dae1,dae2,dae;
      Type_a e;
      list<Type_a> es;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      
    case (cache,env,ih,mod,pre,csets,ci_state,r,{},impl,graph) 
      then (cache,env,ih,DAEUtil.emptyDae,csets,ci_state,graph);  
         
    case (cache,env,ih,mod,pre,csets,ci_state,r,(e :: es),impl,graph)
      equation 
        (cache,env_1,ih,dae1,csets_1,ci_state_1,graph) = r(cache,env,ih, mod, pre, csets, ci_state, e, impl,graph);
        (cache,env_2,ih,dae2,csets_2,ci_state_2,graph) = instList(cache,env_1,ih, mod, pre, csets_1, ci_state_1, r, es, impl,graph);
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache,env_2,ih,dae,csets_2,ci_state_2,graph);
  end matchcontinue;
end instList;

protected function instBinding 
"function: instBinding 
  This function investigates a modification and extracts the 
  <...> modification. E.g. Real x(<...>=1+3) => 1+3
  It also handles the case Integer T0[2](final <...>={5,6})={9,10} becomes
  Integer T0[1](<...>=5); Integer T0[2](<...>=6);
 
 	If no modifier is given it also investigates the type to check for binding there.
 	I.e. type A = Real(start=1); A a; will set the start attribute since it's found in the type.
 
  Arg 1 is the modification  
  Arg 2 are the type variables.
  Arg 3 is the expected type that the modification should have
  Arg 4 is the index list for the element: for T0{1,2} is {1,2}"
  input Mod inMod;
  input list<DAE.Var> varLst;
  input DAE.Type inType;
  input list<Integer> inIntegerLst;
  input String inString;
  input Boolean useConstValue "if true use constant value present in TYPED (if present)";
  output Option<DAE.Exp> outExpExpOption;
algorithm 
  outExpExpOption := matchcontinue (inMod,varLst,inType,inIntegerLst,inString,useConstValue)
    local
      DAE.Mod mod2,mod;
      DAE.Exp e,e_1;
      tuple<DAE.TType, Option<Absyn.Path>> ty2,ty_1,expected_type,etype;
      String bind_name;
      Option<DAE.Exp> result;
      list<Integer> index_list;
      DAE.Binding binding;
      Ident name;
      Option<Values.Value> optVal;
    case (mod,varLst,expected_type,{},bind_name,useConstValue) /* No subscript/index */ 
      equation 
        mod2 = Mod.lookupCompModification(mod, bind_name);
        SOME(DAE.TYPED(e,optVal,DAE.PROP(ty2,_))) = Mod.modEquation(mod2);
        (e_1,ty_1) = Types.matchType(e, ty2, expected_type, true);
        e_1 = checkUseConstValue(useConstValue,e_1,optVal);
      then
        SOME(e_1);
    case (mod,varLst,etype,index_list,bind_name,useConstValue) /* Have subscript/index */ 
      equation 
        mod2 = Mod.lookupCompModification(mod, bind_name);
        result = instBinding2(mod2, etype, index_list, bind_name,useConstValue);
      then
        result;
    case (mod,varLst,expected_type,{},bind_name,useConstValue) /* No modifier for this name. */ 
      equation 
        failure(mod2 = Mod.lookupCompModification(mod, bind_name));
      then
        NONE;
    case (mod,DAE.TYPES_VAR(name,binding=binding)::_,etype,index_list,bind_name,useConstValue) equation
      equality(name=bind_name);      
      then bindingExp(binding);
    case (mod,_::varLst,etype,index_list,bind_name,useConstValue)      
    then instBinding(mod,varLst,etype,index_list,bind_name,useConstValue);  
    case (mod,{},etype,index_list,bind_name,useConstValue)
    then NONE;                
  end matchcontinue;
end instBinding;

protected function bindingExp 
"help function to instBinding, returns the expression of a binding"
input DAE.Binding bind;
output Option<DAE.Exp> exp;
algorithm
  exp := matchcontinue(bind)
  local DAE.Exp e; Values.Value v;
    case(DAE.UNBOUND()) then NONE;
    case(DAE.EQBOUND(exp=e)) then SOME(e);
    case(DAE.VALBOUND(v)) equation
      e = Static.valueExp(v);
    then SOME(e);  
  end matchcontinue;
end bindingExp;

protected function instBinding2 
"function: instBinding2 
  This function investigates a modification and extracts the <...> 
  modification if the modification is in array of components. 
  Help-function to instBinding"
  input Mod inMod;
  input DAE.Type inType;
  input list<Integer> inIntegerLst;
  input String inString;
  input Boolean useConstValue "if true, use constant value in TYPED (if present)";
  output Option<DAE.Exp> outExpExpOption;
algorithm 
  outExpExpOption:=
  matchcontinue (inMod,inType,inIntegerLst,inString,useConstValue)
    local
      DAE.Mod mod2,mod;
      DAE.Exp e,e_1;
      tuple<DAE.TType, Option<Absyn.Path>> ty2,ty_1,etype;
      Integer index;
      String bind_name;
      Option<DAE.Exp> result;
      list<Integer> res;
      Option<Values.Value> optVal;
    case (mod,etype,(index :: {}),bind_name,useConstValue) /* Only one element in the index-list */ 
      equation 
        mod2 = Mod.lookupIdxModification(mod, index); 
        SOME(DAE.TYPED(e,optVal,DAE.PROP(ty2,_))) = Mod.modEquation(mod2);
        (e_1,ty_1) = Types.matchType(e, ty2, etype, true);
        e_1 = checkUseConstValue(useConstValue,e_1,optVal);
      then
        SOME(e_1);
    case (mod,etype,(index :: res),bind_name,useConstValue) /* Several elements in the index-list */ 
      equation 
        mod2 = Mod.lookupIdxModification(mod, index);
        result = instBinding2(mod2, etype, res, bind_name,useConstValue);
      then
        result;
    case (mod,etype,(index :: res),bind_name,useConstValue)
      equation 
        failure(mod2 = Mod.lookupIdxModification(mod, index));
      then
        NONE;
    case (_,_,_,_,_) 
      then fail(); 
  end matchcontinue;
end instBinding2;

protected function instStartBindingExp 
"function: instStartBindingExp 
  This function investigates a modification and extracts the 
  start modification. E.g. Real x(start=1+3) => 1+3
  It also handles the case Integer T0{2}(final start={5,6})={9,10} becomes
  Integer T0{1}(start=5); Integer T0{2}(start=6);
 
  Arg 1 is the start modification  
  Arg 2 is the expected type that the modification should have
  Arg 3 is the index list for the element: for T0[1,2] it is {1,2}"
  input Mod mod;
  input DAE.Type etype;
  input list<Integer> index_list;
  output DAE.StartValue result;
protected DAE.Type eltType;
algorithm 
  eltType := Types.arrayElementType(etype); 
  // When instantiating arrays, the array type is passed
  // But binding is performed on the element type.
	// Also removed index, since indexing is already performed on the modifier.
  result := instBinding(mod, {},eltType, {}, "start",false);
end instStartBindingExp;

protected function instDaeVariableAttributes 
"function: instDaeVariableAttributes  
  this function extracts the attributes from the modification
  It returns a DAE.VariableAttributes option because 
  somtimes a varible does not contain the variable-attr."
	input Env.Cache inCache;
  input Env inEnv;
  input Mod inMod;
  input DAE.Type inType;
  input list<Integer> inIntegerLst;
  output Env.Cache outCache;
  output Option<DAE.VariableAttributes> outDAEVariableAttributesOption;
algorithm 
  (outCache,outDAEVariableAttributesOption) :=
  matchcontinue (inCache,inEnv,inMod,inType,inIntegerLst)
    local
      Option<DAE.Exp> quantity_str,unit_str,displayunit_str;
      Option<DAE.Exp> min_val,max_val,start_val,nominal_val;
      Option<DAE.Exp> fixed_val;
      Option<DAE.Exp> exp_bind_select,exp_bind_min,exp_bind_max,exp_bind_start;
      Option<DAE.StateSelect> stateSelect_value;
      list<Env.Frame> env;
      DAE.Mod mod;
      Option<Absyn.Path> path;
      list<Integer> index_list;
      tuple<DAE.TType, Option<Absyn.Path>> enumtype;
      Env.Cache cache;
      DAE.Type tp;
      list<DAE.Var> varLst;
    /* Real */
    case (cache,env,mod,tp as (DAE.T_REAL(varLstReal = varLst),path),index_list)  
      equation 
        (quantity_str) = instBinding(mod, varLst, DAE.T_STRING_DEFAULT,index_list, "quantity",false);
        (unit_str) = instBinding( mod, varLst, DAE.T_STRING_DEFAULT, index_list, "unit",false);
        (displayunit_str) = instBinding(mod, varLst,DAE.T_STRING_DEFAULT, index_list, "displayUnit",false);
        (min_val) = instBinding( mod, varLst, DAE.T_REAL_DEFAULT,index_list, "min",false);
        (max_val) = instBinding(mod, varLst, DAE.T_REAL_DEFAULT,index_list, "max",false);
        (start_val) = instBinding(mod, varLst, DAE.T_REAL_DEFAULT,index_list, "start",false);
        (fixed_val) = instBinding( mod, varLst, DAE.T_BOOL_DEFAULT,index_list, "fixed",false);
        (nominal_val) = instBinding(mod, varLst, DAE.T_REAL_DEFAULT,index_list, "nominal",false);
        (cache,exp_bind_select) = instEnumerationBinding(cache,env, mod, varLst, index_list, "stateSelect",true);
        (stateSelect_value) = getStateSelectFromExpOption(exp_bind_select);
        //TODO: check for protected attribute (here and below matches)
      then
        (cache,SOME(
          DAE.VAR_ATTR_REAL(quantity_str,unit_str,displayunit_str,(min_val,max_val),
          start_val,fixed_val,nominal_val,stateSelect_value,NONE,NONE,NONE)));
    /* Integer */
    case (cache,env,mod,tp as (DAE.T_INTEGER(varLstInt = varLst),_),index_list) 
      local Option<DAE.Exp> min_val,max_val,start_val;
      equation 
        (quantity_str) = instBinding(mod, varLst, DAE.T_STRING_DEFAULT, index_list, "quantity",false);
        (min_val) = instBinding(mod, varLst, DAE.T_INTEGER_DEFAULT, index_list, "min",false);
        (max_val) = instBinding(mod, varLst, DAE.T_INTEGER_DEFAULT, index_list, "max",false);
        (start_val) = instBinding(mod, varLst, DAE.T_INTEGER_DEFAULT, index_list, "start",false);
        (fixed_val) = instBinding(mod, varLst, DAE.T_BOOL_DEFAULT,index_list, "fixed",false);
      then
        (cache,SOME(DAE.VAR_ATTR_INT(quantity_str,(min_val,max_val),start_val,fixed_val,NONE,NONE,NONE)));
    /* Boolean */
    case (cache,env,mod,tp as (DAE.T_BOOL(varLstBool = varLst),_),index_list) 
      local Option<DAE.Exp> start_val;
      equation 
        (quantity_str) = instBinding( mod, varLst, DAE.T_STRING_DEFAULT, index_list, "quantity",false);
        (start_val) = instBinding(mod, varLst, tp, index_list, "start",false);
        (fixed_val) = instBinding(mod, varLst, tp, index_list, "fixed",false);
      then
        (cache,SOME(DAE.VAR_ATTR_BOOL(quantity_str,start_val,fixed_val,NONE,NONE,NONE)));
    /* String */
    case (cache,env,mod,tp as (DAE.T_STRING(varLstString = varLst),_),index_list)  
      local Option<DAE.Exp> start_val;
      equation 
        (quantity_str) = instBinding(mod, varLst, tp, index_list, "quantity",false);
        (start_val) = instBinding(mod, varLst, tp, index_list, "start",false);
      then
        (cache,SOME(DAE.VAR_ATTR_STRING(quantity_str,start_val,NONE,NONE,NONE)));
    /* Enumeration */
    case (cache,env,mod,(enumtype as (DAE.T_ENUMERATION(names = _,varLst=varLst),_)),index_list) 
      equation  
        (quantity_str) = instBinding(mod, varLst, DAE.T_STRING_DEFAULT,index_list, "quantity",false);        
        (exp_bind_min) = instBinding(mod, varLst, enumtype, index_list, "min",false);
        (exp_bind_max) = instBinding(mod, varLst, enumtype, index_list, "max",false);
        (exp_bind_start) = instBinding(mod, varLst, enumtype, index_list, "start",false);
        (fixed_val) = instBinding( mod, varLst, DAE.T_BOOL_DEFAULT, index_list, "fixed",false);
      then
        (cache,SOME(DAE.VAR_ATTR_ENUMERATION(quantity_str,(exp_bind_min,exp_bind_max),exp_bind_start,fixed_val,NONE,NONE,NONE)));
    case (cache,env,mod,_,_)        
      then (cache,NONE); 
  end matchcontinue;
end instDaeVariableAttributes;

protected function instBoolBinding 
"function instBoolBinding
  author: LP
  instantiates a bool binding and retrieves the value.
  FIXME: check the type of variable for the fixed because 
         there is a difference between parameters and variables."
  input Env.Cache inCache;
  input Env inEnv;
  input Mod inMod;
  input list<DAE.Var> varLst;
  input list<Integer> inIntegerLst;
  input String inString;
  output Env.Cache outCache;
  output Option<Boolean> outBooleanOption;
algorithm 
  (outCache,outBooleanOption) := matchcontinue (inCache,inEnv,inMod,varLst,inIntegerLst,inString)
    local
      DAE.Exp e;
      Boolean result;
      list<Env.Frame> env;
      DAE.Mod mod;
      list<Integer> index_list;
      String bind_name;
      Env.Cache cache;
    case (cache,env,mod,varLst,index_list,bind_name)
      equation 
        SOME(e) = instBinding(mod,varLst, DAE.T_BOOL_DEFAULT, index_list, bind_name,false);
        (cache,Values.BOOL(result),_) = Ceval.ceval(cache,env, e, false, NONE, NONE, Ceval.NO_MSG());
      then
        (cache,SOME(result));
    /* Non constant expression return NONE */
    case (cache,env,mod,varLst,index_list,bind_name)  
      equation 
        SOME(e) = instBinding(mod, varLst,DAE.T_BOOL_DEFAULT, index_list, bind_name,false);
      then
        (cache,NONE);
    case (cache,env,mod,varLst,index_list,bind_name)
      equation 
        NONE = instBinding(mod, varLst, DAE.T_BOOL_DEFAULT, index_list, bind_name,false);
      then
        (cache,NONE);
    case (cache,env,mod,varLst,index_list,bind_name)
      equation 
        Error.addMessage(Error.TYPE_ERROR, {bind_name,"Boolean"});
      then
        fail();
  end matchcontinue;
end instBoolBinding;

protected function instRealBinding 
"function: instRealBinding
  author: LP
  instantiates a real binding and retrieves the value."
	input Env.Cache inCache;
  input Env inEnv;
  input Mod inMod;
  input list<DAE.Var> varLst;
  input list<Integer> inIntegerLst;
  input String inString;
  output Env.Cache outCache;
  output Option<Real> outRealOption;
algorithm 
  (outCache,outRealOption) := matchcontinue (outCache,inEnv,inMod,varLst,inIntegerLst,inString)
    local
      DAE.Exp e;
      Real result;
      list<Env.Frame> env;
      DAE.Mod mod;
      list<Integer> index_list;
      String bind_name;
      Env.Cache cache;
    case (cache,env,mod,varLst,index_list,bind_name)
      equation 
        SOME(e) = instBinding(mod, varLst, DAE.T_REAL_DEFAULT, index_list, bind_name,false);
        (cache,Values.REAL(result),_) = Ceval.ceval(cache,env, e, false, NONE, NONE, Ceval.NO_MSG());
      then
        (cache,SOME(result));
    /* non constant expression, return NONE */ 
    case (cache,env,mod,varLst,index_list,bind_name)
      equation 
        SOME(e) = instBinding(mod, varLst,DAE.T_REAL_DEFAULT, index_list, bind_name,false);
      then
        (cache,NONE);
    case (cache,env,mod,varLst,index_list,bind_name)
      equation 
        NONE = instBinding(mod, varLst,DAE.T_REAL_DEFAULT, index_list, bind_name,false);
      then
        (cache,NONE);
    case (cache,env,mod,varLst,index_list,bind_name)
      equation 
        Error.addMessage(Error.TYPE_ERROR, {bind_name,"Real"});
      then
        fail();
  end matchcontinue;
end instRealBinding;

protected function instIntBinding 
"function: instIntBinding
  author: LP
  instantiates an int binding and retrieves the value."
	input Env.Cache inCache;
  input Env inEnv;
  input Mod inMod;
  input list<DAE.Var> varLst;
  input list<Integer> inIntegerLst;
  input String inString;
  output Env.Cache outCache;
  output Option<Integer> outIntegerOption;
algorithm 
  (outCache,outIntegerOption) := matchcontinue (outCache,inEnv,inMod,varLst,inIntegerLst,inString)
    local
      DAE.Exp e;
      Integer result;
      list<Env.Frame> env;
      DAE.Mod mod;
      list<Integer> index_list;
      String bind_name;
      Env.Cache cache;
    case (cache,env,mod,varLst,index_list,bind_name)
      equation 
        SOME(e) = instBinding(mod, varLst, DAE.T_INTEGER_DEFAULT, index_list, bind_name,false);
        (cache,Values.INTEGER(result),_) = Ceval.ceval(cache,env, e, false, NONE, NONE, Ceval.NO_MSG());
      then
        (cache,SOME(result));
    /* got non-constant expression, return NONE */
    case (cache,env,mod,varLst,index_list,bind_name) 
      equation 
        SOME(e) = instBinding(mod, varLst,DAE.T_INTEGER_DEFAULT, index_list, bind_name,false);
      then
        (cache,NONE);
    case (cache,env,mod,varLst,index_list,bind_name)
      equation 
        NONE = instBinding(mod, varLst,DAE.T_INTEGER_DEFAULT, index_list, bind_name,false);
      then
        (cache,NONE);
    case (cache,env,mod,varLst,index_list,bind_name)
      equation 
        Error.addMessage(Error.TYPE_ERROR, {bind_name,"Integer"});
      then
        fail();
  end matchcontinue;
end instIntBinding;

protected function instStringBinding 
"function: instStringBinding
  author: LP
  instantiates a string binding and retrieves the value."
	input Env.Cache inCache;
  input Env inEnv;
  input Mod inMod;
  input list<DAE.Var> varLst;
  input list<Integer> inIntegerLst;
  input String inString;
  output Env.Cache outCache;
  output Option<String> outStringOption;
algorithm 
  (outCache,outStringOption) :=
  matchcontinue (inCache,inEnv,inMod,varLst,inIntegerLst,inString)
    local
      DAE.Exp e;
      String result,bind_name;
      list<Env.Frame> env;
      DAE.Mod mod;
      list<Integer> index_list;
      Env.Cache cache;
    case (cache,env,mod,varLst,index_list,bind_name)
      equation 
        SOME(e) = instBinding(mod, varLst,DAE.T_STRING_DEFAULT, index_list, bind_name,false);
        (cache,Values.STRING(result),_) = Ceval.ceval(cache,env, e, false, NONE, NONE, Ceval.NO_MSG());
      then
        (cache,SOME(result));
    /* Non constant expression return NONE */
    case (cache,env,mod,varLst,index_list,bind_name) 
      equation 
        SOME(e) = instBinding(mod, varLst,DAE.T_STRING_DEFAULT, index_list, bind_name,false);
      then
        (cache,NONE);
    case (cache,env,mod,varLst,index_list,bind_name)
      equation 
        NONE = instBinding(mod, varLst,DAE.T_STRING_DEFAULT, index_list, bind_name,false);
      then
        (cache,NONE);
    case (cache,env,mod,varLst,index_list,bind_name)
      equation 
        Error.addMessage(Error.TYPE_ERROR, {bind_name,"String"});
      then
        fail();
  end matchcontinue;
end instStringBinding;

protected function instEnumerationBinding 
"function: instEnumerationBinding
  author: LP
  instantiates a enumeration binding and retrieves the value."
	input Env.Cache inCache;
  input Env inEnv;
  input Mod inMod;
  input list<DAE.Var> varLst;
  input list<Integer> inIntegerLst;
  input String inString;
  input Boolean useConstValue "if true, use constant value in TYPED (if present)";
  output Env.Cache outCache;
  output Option<DAE.Exp> outExpExpOption;
algorithm 
  (outCache,outExpExpOption) := matchcontinue (inCache,inEnv,inMod,varLst,inIntegerLst,inString,useConstValue)
    local
      Option<DAE.Exp> result;
      list<Env.Frame> env;
      DAE.Mod mod;
      list<Integer> index_list;
      String bind_name;
      Env.Cache cache;
    case (cache,env,mod,varLst,index_list,bind_name,useConstValue)
      equation 
        result = instBinding(mod, varLst, (DAE.T_ENUMERATION(NONE(),Absyn.IDENT(""),{},{}),NONE), index_list, bind_name,useConstValue);
      then
        (cache,result);
    case (cache,env,mod,varLst,index_list,bind_name,useConstValue)
      equation 
        Error.addMessage(Error.TYPE_ERROR, {bind_name,"enumeration type"});
      then
        fail();
  end matchcontinue;
end instEnumerationBinding;

protected function getStateSelectFromExpOption 
"function: getStateSelectFromExpOption
  author: LP
  Retrieves the stateSelect value, as defined in DAE,  from an Expression option."
  input Option<DAE.Exp> inExpExpOption;
  output Option<DAE.StateSelect> outDAEStateSelectOption;
algorithm 
  outDAEStateSelectOption:=
  matchcontinue (inExpExpOption)
    case (SOME(DAE.CREF(DAE.CREF_QUAL("StateSelect",_,{},DAE.CREF_IDENT("never",DAE.ET_ENUMERATION(SOME(_),_,_,_),{})),_))) then SOME(DAE.NEVER()); 
    case (SOME(DAE.CREF(DAE.CREF_QUAL("StateSelect",_,{},DAE.CREF_IDENT("avoid",DAE.ET_ENUMERATION(SOME(_),_,_,_),{})),_))) then SOME(DAE.AVOID()); 
    case (SOME(DAE.CREF(DAE.CREF_QUAL("StateSelect",_,{},DAE.CREF_IDENT("default",DAE.ET_ENUMERATION(SOME(_),_,_,_),{})),_))) then SOME(DAE.DEFAULT()); 
    case (SOME(DAE.CREF(DAE.CREF_QUAL("StateSelect",_,{},DAE.CREF_IDENT("prefer",DAE.ET_ENUMERATION(SOME(_),_,_,_),{})),_))) then SOME(DAE.PREFER()); 
    case (SOME(DAE.CREF(DAE.CREF_QUAL("StateSelect",_,{},DAE.CREF_IDENT("always",DAE.ET_ENUMERATION(SOME(_),_,_,_),{})),_))) then SOME(DAE.ALWAYS()); 
//    case (SOME(DAE.CREF(DAE.CREF_QUAL("StateSelect",_,{},DAE.CREF_IDENT("never",_,{})),Exp.ENUM()))) then SOME(DAE.NEVER()); 
//    case (SOME(DAE.CREF(DAE.CREF_QUAL("StateSelect",_,{},DAE.CREF_IDENT("avoid",_,{})),Exp.ENUM()))) then SOME(DAE.AVOID()); 
//    case (SOME(DAE.CREF(DAE.CREF_QUAL("StateSelect",_,{},DAE.CREF_IDENT("default",_,{})),Exp.ENUM()))) then SOME(DAE.DEFAULT()); 
//    case (SOME(DAE.CREF(DAE.CREF_QUAL("StateSelect",_,{},DAE.CREF_IDENT("prefer",_,{})),Exp.ENUM()))) then SOME(DAE.PREFER()); 
//    case (SOME(DAE.CREF(DAE.CREF_QUAL("StateSelect",_,{},DAE.CREF_IDENT("always",_,{})),Exp.ENUM()))) then SOME(DAE.ALWAYS()); 
    case (NONE) then NONE; 
    case (_) then NONE; 
  end matchcontinue;
end getStateSelectFromExpOption;

protected function instModEquation 
"function: instModEquation 
  This function adds the equation in the declaration 
  of a variable, if such an equation exists."
  input DAE.ComponentRef inComponentRef;
  input DAE.Type inType;
  input Mod inMod;
  input DAE.ElementSource source "the origin of the element";
  input Boolean inBoolean;
  output DAE.DAElist outDae;
algorithm 
  outDae:= matchcontinue (inComponentRef,inType,inMod,source,inBoolean)
    local
      DAE.ExpType t;
      DAE.DAElist dae;
      DAE.ComponentRef cr,c;
      tuple<DAE.TType, Option<Absyn.Path>> ty1;
      DAE.Mod mod,m;
      DAE.Exp e;
      DAE.Properties prop2;
      Boolean impl;
      
      // Record constructors are different
      // If it's a constant binding, all fields will already be bound correctly. Don't return a DAE.
    case (cr,(DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)),_),(DAE.MOD(eqModOption = SOME(DAE.TYPED(e,_,DAE.PROP(_,DAE.C_CONST()))))),source,impl) 
    then DAEUtil.emptyDae;
      
     // Regular cases
    case (cr,ty1,(mod as DAE.MOD(eqModOption = SOME(DAE.TYPED(e,_,prop2)))),source,impl)
      equation 
        t = Types.elabType(ty1);
        dae = instEqEquation(DAE.CREF(cr,t), DAE.PROP(ty1,DAE.C_VAR()), e, prop2, source, SCode.NON_INITIAL(), impl);
      then
        dae;
    case (_,_,DAE.MOD(eqModOption = NONE),_,impl) then DAEUtil.emptyDae; 
    case (_,_,DAE.NOMOD(),_,impl) then DAEUtil.emptyDae; 
    case (_,_,DAE.REDECL(finalPrefix = _),_,impl) then DAEUtil.emptyDae; 
    case (c,ty1,m,source,impl)
      equation 
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "- Inst.instModEquation failed\n type: ");
        Debug.fprint("failtrace", Types.printTypeStr(ty1));
        Debug.fprint("failtrace", "\n  cref: ");
        Debug.fprint("failtrace", Exp.printComponentRefStr(c));
        Debug.fprint("failtrace", "\n mod:");
        Debug.fprint("failtrace", Mod.printModStr(m));
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end instModEquation;

protected function checkProt 
"function: checkProt 
  This function is used to check that a 
  protected element is not modified."
  input Boolean inBoolean;
  input Mod inMod;
  input DAE.ComponentRef inComponentRef;
algorithm 
  _:=
  matchcontinue (inBoolean,inMod,inComponentRef)
    local
      DAE.ComponentRef cref;
      String str;
    case (false,_,cref) then (); 
    case (_,DAE.NOMOD(),_) then (); 
    case (true,_,cref)
      equation 
        str = Exp.printComponentRefStr(cref);
        Error.addMessage(Error.MODIFY_PROTECTED, {str});
      then
        fail();
  end matchcontinue;
end checkProt;

public function makeBinding 
"function: makeBinding 
  This function looks at the equation part of a modification, and 
  if there is a declaration equation builds a DAE.Binding for it."
	input Env.Cache inCache;
  input Env inEnv;
  input SCode.Attributes inAttributes;
  input Mod inMod;
  input DAE.Type inType;
  output Env.Cache outCache;
  output DAE.Binding outBinding;
algorithm 
  (outCache,outBinding) :=
  matchcontinue (inCache,inEnv,inAttributes,inMod,inType)
    local
      tuple<DAE.TType, Option<Absyn.Path>> tp,e_tp;
      DAE.Exp e_1,e;
      Values.Value v;
      list<Env.Frame> env;
      Option<Values.Value> e_val;
      DAE.Const c;
      String e_tp_str,tp_str,e_str,e_str_1;
      Env.Cache cache;
      DAE.Properties prop;
    case (cache,_,_,DAE.NOMOD(),tp) then (cache,DAE.UNBOUND()); 
    case (cache,_,_,DAE.REDECL(finalPrefix = _),tp) then (cache,DAE.UNBOUND()); 
    case (cache,_,_,DAE.MOD(eqModOption = NONE),tp) then (cache,DAE.UNBOUND());
    /* adrpo: CHECK! do we need this here? numerical values 
    case (cache,env,_,DAE.MOD(eqModOption = SOME(DAE.TYPED(e,_,DAE.PROP(e_tp,_)))),tp) 
      equation
        (e_1,_) = Types.matchType(e, e_tp, tp);
        (cache,v,_) = Ceval.ceval(cache,env, e_1, false, NONE, NONE, Ceval.NO_MSG());
      then
        (cache,DAE.VALBOUND(v));
    */
    case (cache,_,_,DAE.MOD(eqModOption = SOME(DAE.TYPED(e,e_val,prop))),tp) /* default */ 
      equation 
        e_tp = Types.getPropType(prop);
        c = Types.propAllConst(prop);
        (e_1,_) = Types.matchType(e, e_tp, tp, true);
        e_1 = Exp.simplify(e_1);
      then
        (cache,DAE.EQBOUND(e_1,e_val,c));
    case (cache,_,_,DAE.MOD(eqModOption = SOME(DAE.TYPED(e,e_val,prop))),tp)
      equation 
        e_tp = Types.getPropType(prop);
        c = Types.propAllConst(prop);
        (e_1,_) = Types.matchType(e, e_tp, tp, false);
      then
        (cache,DAE.EQBOUND(e_1,e_val,c));
    case (cache,_,_,DAE.MOD(eqModOption = SOME(DAE.TYPED(e,e_val,prop))),tp)
      equation 
        e_tp = Types.getPropType(prop);
        c = Types.propAllConst(prop);
        failure((_,_) = Types.matchType(e, e_tp, tp, false));
        e_tp_str = Types.unparseType(e_tp);
        tp_str = Types.unparseType(tp);
        e_str = Exp.printExpStr(e);
        e_str_1 = stringAppend("=", e_str);
        Error.addMessage(Error.MODIFIER_TYPE_MISMATCH_ERROR, 
          {tp_str,e_str_1,e_tp_str});
      then
        fail();
    case (_,_,_,_,_)
      equation 
        Debug.fprint("failtrace", "- Inst.makeBinding failed\n");
      then
        fail();
  end matchcontinue;
end makeBinding;

public function instRecordConstructorElt 
"function: instRecordConstructorElt
  author: PA
  This function takes an Env and an Element and builds a input argument to 
  a record constructor.
  E.g if the element is Real x; the resulting Var is \"input Real x;\""
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input SCode.Element inElement;
  input DAE.Mod outerMod;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output InstanceHierarchy outIH;
  output DAE.Var outVar;
algorithm 
  (outCache,outIH,outVar):=
  matchcontinue (inCache,inEnv,inIH,inElement,outerMod,inBoolean)
    local
      SCode.Class cl;
      list<Env.Frame> cenv,env;
      DAE.Mod mod_1;
      Absyn.ComponentRef owncref;
      list<DimExp> dimexp;
      tuple<DAE.TType, Option<Absyn.Path>> tp_1;
      DAE.Binding bind;
      String id,str;
      Boolean repl,prot,f,impl,s;
      SCode.Attributes attr;
      list<Absyn.Subscript> dim;
      SCode.Accessibility acc;
      SCode.Variability var;
      Absyn.Direction dir;
      Absyn.Path t;
      SCode.Mod mod;
      SCode.OptBaseClass bc;
      Option<SCode.Comment> comment;
      SCode.Element elt;
      Env.Cache cache;
      Absyn.InnerOuter io;
      Boolean finalPrefix;
      Option<Absyn.Info> info;
      InstanceHierarchy ih;
      Option<Absyn.ConstrainClass> cc;
      
    case (cache,env,ih,
          SCode.COMPONENT(info = info, component = id,replaceablePrefix = repl,protectedPrefix = prot,
                          attributes = (attr as SCode.ATTR(arrayDims = dim,flowPrefix = f,streamPrefix=s,
                          accesibility = acc, variability = var,direction = dir)),
                          typeSpec = Absyn.TPATH(t, _),modifications = mod,
                          baseClassPath = bc,comment = comment,innerOuter=io,
                          finalPrefix = finalPrefix,cc=cc),outerMod,impl)
      equation
        // - Prefixes (constant, parameter, final, discrete, input, output, ...) of the remaining record components are removed.
        var = SCode.VAR();
        dir = Absyn.INPUT();
        attr = SCode.ATTR(dim,f,s,acc,var,dir);

        //Debug.fprint("recconst", "inst_record_constructor_elt called\n");
        (cache,cl,cenv) = Lookup.lookupClass(cache,env, t, true);
        //Debug.fprint("recconst", "looked up class\n");
        (cache,mod_1,_) = Mod.elabMod(cache,env, Prefix.NOPRE(), mod, impl);
        mod_1 = Mod.merge(outerMod,mod_1,cenv,Prefix.NOPRE());
        owncref = Absyn.CREF_IDENT(id,{});
        (cache,dimexp,_) = elabArraydim(cache,env, owncref,t, dim, NONE, false, NONE,true);
        //Debug.fprint("recconst", "calling inst_var\n");
        (cache,_,ih,_,_,_,tp_1,_) = instVar(cache,cenv, ih, UnitAbsyn.noStore,ClassInf.FUNCTION(Absyn.IDENT("")), mod_1, Prefix.NOPRE(), 
          Connect.emptySet, id, cl, attr, prot,dimexp, {}, {}, impl, comment,io,finalPrefix,info,ConnectionGraph.EMPTY);
        //Debug.fprint("recconst", "Type of argument:");
        Debug.fprint("recconst", Types.printTypeStr(tp_1));
        //Debug.fprint("recconst", "\nMod=");
        Debug.fcall("recconst", Mod.printMod, mod_1);
        (cache,bind) = makeBinding(cache,env, attr, mod_1, tp_1);
      then
        (cache,ih,DAE.TYPES_VAR(id,DAE.ATTR(f,s,acc,var,dir,Absyn.UNSPECIFIED()),prot,tp_1,bind));
        
    case (cache,env,ih,elt,outerMod,impl)
      equation 
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "- instRecordConstructorElt failed.,elt:");
        str = SCode.printElementStr(elt);
        Debug.fprint("failtrace", str);
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end instRecordConstructorElt;

protected function isTopCall 
"function: isTopCall
  author: PA
  The topmost instantiation call is treated specially with for instance unconnected connectors.
  This function returns true if the CallingScope indicates the top call."
  input CallingScope inCallingScope;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inCallingScope)
    case TOP_CALL() then true; 
    case INNER_CALL() then false; 
  end matchcontinue;
end isTopCall;

/* ------------------------------------------------------ */
// The following functions are used in the instantiation of
// array iterator constructors. For instance,
// v := { 3*i*j for i in 1:5, j in 1:n }

protected function createForIteratorEquations 
"function: createForIteratorEquations
	author: KS
  Function that creates for equations to be used in the for iterator construct assignment."
  input Absyn.Exp iterExp;
  input Absyn.ForIterators rangeIdList;
  input list<Absyn.Ident> idList;
  input Absyn.ComponentRef arrayId;
  output SCode.EEquation outEq;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outEq,outDae) :=
  matchcontinue (iterExp,rangeIdList,idList,arrayId)
    local
      Absyn.Ident id;
      Absyn.Exp rangeExp,localIterExp;
      list<Absyn.Ident> localIdList;
      Absyn.ComponentRef localArrayId;
    case (localIterExp,(id,SOME(rangeExp)) :: {},localIdList,localArrayId)
      local
        list<Absyn.Subscript> subList;
        Absyn.Exp arrayRef;
        list<SCode.EEquation> eqList;
        SCode.EEquation eq1,eq2;
      equation
        subList = createArrayIndexing(localIdList,{});
        arrayRef = createArrayReference(localArrayId,subList);
        eq1 = SCode.EQ_EQUALS(arrayRef,localIterExp,NONE);
        eqList = {eq1};
        eq2 = SCode.EQ_FOR(id,rangeExp,eqList,NONE);
      then (eq2,DAEUtil.emptyDae);
    case (localIterExp,(id,SOME(rangeExp)) :: rest,localIdList,localArrayId)
      local
        Absyn.ForIterators rest;
        list<SCode.EEquation> eqList;
        SCode.EEquation eq1,eq2;
      equation
        (eq1,_) = createForIteratorEquations(localIterExp,rest,localIdList,localArrayId);
        eqList = {eq1};
        eq2 = SCode.EQ_FOR(id,rangeExp,eqList,NONE);
      then (eq2,DAEUtil.emptyDae);
  end matchcontinue;
end createForIteratorEquations;

protected function extractLoopVars 
"function: extractLoopVars
	author: KS"
  input Absyn.ForIterators rangeIdList;
  input list<Absyn.Ident> accList;
  output list<Absyn.Ident> outList;
algorithm
  outList :=
  matchcontinue (rangeIdList,accList)
    local
      list<Absyn.Ident> localAccList;
      list<Absyn.ElementItem> localAccVars2;
    case ({},localAccList)
      then localAccList;
    case ((id,_) :: restIdRange,localAccList)
      local
        Absyn.ForIterators restIdRange;
        Absyn.Ident id;
      equation
        localAccList = listAppend(localAccList,{id});
        localAccList = extractLoopVars(restIdRange,localAccList);
      then localAccList;
  end matchcontinue;
end extractLoopVars;

protected function createArrayIndexing 
"function: createArrayIndexing
	author: KS
  Function that creates a list of subscripts to be used when indexing an array."
  input list<Absyn.Ident> idList;
  input list<Absyn.Subscript> accList;
  output list<Absyn.Subscript> outSubList;
algorithm
  outSubList :=
  matchcontinue (idList,accList)
    local
      list<Absyn.Subscript> localAccList;
    case ({},localAccList) then localAccList;
    case (firstId :: restId,localAccList)
      local
        Absyn.Ident firstId;
        Absyn.Subscript subExp;
        list<Absyn.Ident> restId;
      equation
        subExp = Absyn.SUBSCRIPT(Absyn.CREF(Absyn.CREF_IDENT(firstId,{})));
        localAccList = listAppend(localAccList,Util.listCreate(subExp));
        localAccList = createArrayIndexing(restId,localAccList);
      then localAccList;
  end matchcontinue;
end createArrayIndexing;

protected function createArrayReference 
"function: createArrayReference
	author: KS"
  input Absyn.ComponentRef c;
  input list<Absyn.Subscript> subList;
  output Absyn.Exp outExp;
algorithm
  outExp :=
  matchcontinue (c,subList)
    case (Absyn.CREF_IDENT(id,sl),localSubList)
      local
        Absyn.Ident id;
        list<Absyn.Subscript> sl,localSubList;
        Absyn.Exp c2;
      equation
        sl = listAppend(sl,localSubList);
        c2 = Absyn.CREF(Absyn.CREF_IDENT(id,sl));
      then c2;
    case (Absyn.CREF_QUAL(id,sl,c),localSubList)
      local
        Absyn.Ident id;
        list<Absyn.Subscript> sl,localSubList;
        Absyn.ComponentRef c;
        Absyn.Exp c2;
      equation
        sl = listAppend(sl,localSubList);
        c2 = Absyn.CREF(Absyn.CREF_QUAL(id,sl,c));
      then c2;
  end matchcontinue;
end createArrayReference;

protected function createTempLoopVars 
"function: createTempLoopVars
	author: KS
  Function used for creating loop variables, used in the for iterator constructs."
  input Absyn.ForIterators rangeIdList;
  input list<Absyn.Ident> accTempLoopVars1;
  input list<Absyn.ElementItem> accTempLoopVars2;
  input list<Absyn.AlgorithmItem> accTempLoopInit;
  input Integer count;
  output list<Absyn.Ident> outList1;
  output list<Absyn.ElementItem> outList2;
  output list<Absyn.AlgorithmItem> outList3;
algorithm
  (outList1,outList2,outList3) := matchcontinue (rangeIdList,accTempLoopVars1,accTempLoopVars2,accTempLoopInit,count)
    local
      list<Absyn.Ident> localAccVars1;
      list<Absyn.ElementItem> localAccVars2;
      list<Absyn.AlgorithmItem> localAccTempLoopInit;
    case ({},localAccVars1,localAccVars2,localAccTempLoopInit,_)
      then (localAccVars1,localAccVars2,localAccTempLoopInit);
    case (_ :: restIdRange,localAccVars1,localAccVars2,localAccTempLoopInit,n)
      local
        Absyn.ForIterators restIdRange;
        Absyn.Ident id2;
        Integer n;
        list<Absyn.ElementItem> elem;
        list<Absyn.AlgorithmItem> elem2;
      equation
        id2 = stringAppend("LOOPVAR__",intString(n));
        localAccVars1 = listAppend(localAccVars1,{id2});
        elem = {Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TPATH(Absyn.IDENT("Integer"),NONE()),
            {Absyn.COMPONENTITEM(Absyn.COMPONENT(id2,{},NONE()),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0,Absyn.TIMESTAMP(0.0,0.0)),NONE()))};
        localAccVars2 = listAppend(localAccVars2,elem);
        elem2 = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT(id2,{})),Absyn.INTEGER(0)),NONE())};
        localAccTempLoopInit = listAppend(localAccTempLoopInit,elem2);
        n = n+1;
        (localAccVars1,localAccVars2,localAccTempLoopInit) = createTempLoopVars(restIdRange,localAccVars1,localAccVars2,localAccTempLoopInit,n);
      then (localAccVars1,localAccVars2,localAccTempLoopInit);
  end matchcontinue;
end createTempLoopVars;

protected function createForIteratorAlgorithm 
"function: createForIteratorAlgorithm
	author: KS
	Function that creates for algorithm statements to be used in the for iterator constructor assignment."
  input Absyn.Exp iterExp;
  input Absyn.ForIterators rangeIdList;
  input list<Absyn.Ident> idList;
  input list<Absyn.Ident> tempLoopVars;
  input Absyn.ComponentRef arrayId;
  output list<Absyn.AlgorithmItem> outAlg;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outAlg,outDae) :=
  matchcontinue (iterExp,rangeIdList,idList,tempLoopVars,arrayId)
    local
      list<Absyn.AlgorithmItem> stmt1,stmt2,stmt3;
      Absyn.Ident id,tempLoopVar;
      Absyn.Exp rangeExp,localIterExp;
      list<Absyn.Ident> localIdList,restTempLoopVars;
      Absyn.ComponentRef localArrayId;
      DAE.DAElist dae,dae1,dae2;
    case (localIterExp,(id,SOME(rangeExp)) :: {},localIdList,tempLoopVar :: _,localArrayId)
      local
        list<Absyn.Subscript> subList;
        Absyn.Exp arrayRef;
      equation
        subList = createArrayIndexing(localIdList,{});
        arrayRef = createArrayReference(localArrayId,subList);
        stmt1 = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT(tempLoopVar,{})),
          Absyn.BINARY(Absyn.CREF(Absyn.CREF_IDENT(tempLoopVar,{})),Absyn.ADD(),Absyn.INTEGER(1))),NONE())};
        stmt2 = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(arrayRef,localIterExp),NONE())};
        stmt1 = listAppend(stmt1,stmt2);
        stmt2 = {Absyn.ALGORITHMITEM(Absyn.ALG_FOR({(id,SOME(rangeExp))},stmt1),NONE())};
        stmt1 = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT(tempLoopVar,{})),
          Absyn.INTEGER(0)),NONE())};
        stmt3 = listAppend(stmt2,stmt1);
      then (stmt3,DAEUtil.emptyDae);
        
    case (localIterExp,(id,SOME(rangeExp)) :: rest,localIdList,tempLoopVar :: restTempLoopVars,localArrayId)
      local
        Absyn.ForIterators rest;
      equation
        (stmt2,_) = createForIteratorAlgorithm(localIterExp,rest,localIdList,restTempLoopVars,localArrayId);
        stmt1 = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT(tempLoopVar,{})),
          Absyn.BINARY(Absyn.CREF(Absyn.CREF_IDENT(tempLoopVar,{})),Absyn.ADD(),Absyn.INTEGER(1))),NONE())};
        stmt1 = listAppend(stmt1,stmt2);
        stmt2 = {Absyn.ALGORITHMITEM(Absyn.ALG_FOR({(id,SOME(rangeExp))},stmt1),NONE())};
        stmt1 = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT(tempLoopVar,{})),
          Absyn.INTEGER(0)),NONE())};
        stmt3 = listAppend(stmt2,stmt1);
      then (stmt3,DAEUtil.emptyDae);
  end matchcontinue;
end createForIteratorAlgorithm;


protected function createForIteratorArray 
"function: createForIteratorArray
	author: KS
  Creates an array that will be used for storing temporary results in the for-iterator construct. "
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.Exp iterExp;
  input Absyn.ForIterators rangeIdList;
  input Boolean b;
  output Env.Cache outCache;
  output list<Absyn.ElementItem> outDecls;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outDecls,outDae) := matchcontinue (cache,env,iterExp,rangeIdList,b)
    case (localCache,localEnv,localIterExp,localRangeIdList,impl)
      local
        Env.Env env2,localEnv;
        Env.Cache localCache,cache2;
        Absyn.ForIterators localRangeIdList;
        list<Absyn.Subscript> subscriptList;
        DAE.Type t;
        Absyn.Path t2;
        list<Absyn.ElementItem> ld;
        list<SCode.Element> ld2;
        list<tuple<SCode.Element, DAE.Mod>> ld_mod;
        list<Absyn.ElementItem> decls;
        Boolean impl;
        Integer i;
        Absyn.Exp localIterExp;
        InstanceHierarchy ih;
        DAE.DAElist dae,dae1,dae2;
        
      equation
        (localCache,subscriptList,ld,dae1) = deriveArrayDimAndTempVars(localCache,localEnv,localRangeIdList,impl,{},{});

        // Temporarily add the loop variables to the environment so that we can later
        // elaborate the main for-iterator construct expression, in order to get the array type
        env2 = Env.openScope(localEnv, false, NONE());
        ld2 = SCodeUtil.translateEitemlist(ld,false);
        ld2 = componentElts(ld2);
        ld_mod = addNomod(ld2);
        (localCache,env2,ih,dae) = addComponentsToEnv(localCache, env2, InnerOuter.emptyInstHierarchy, DAE.NOMOD(), Prefix.NOPRE(),
        Connect.SETS({},{},{},{}), ClassInf.UNKNOWN(Absyn.IDENT("temp")), ld_mod, {}, {}, {}, impl);
			 (cache2,env2,ih,_,_,_,_,_,_) = instElementList(localCache,env2,ih,UnitAbsyn.noStore,
			  DAE.NOMOD(), Prefix.NOPRE(), Connect.SETS({},{},{},{}), ClassInf.UNKNOWN(Absyn.IDENT("temp")),
			  ld_mod,{},impl,ConnectionGraph.EMPTY);

        (cache2,_,DAE.PROP(t,_),_,dae2) = Static.elabExp(cache2,env2,localIterExp,
          impl,NONE(),false);

        t2 = convertType(t);

        decls = {Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TPATH(t2,NONE()),
            {Absyn.COMPONENTITEM(Absyn.COMPONENT("VEC__",subscriptList,NONE()),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0,Absyn.TIMESTAMP(0.0,0.0)),NONE()))};
        dae = DAEUtil.joinDaes(dae1,dae2);
      then (localCache,decls,dae);
  end matchcontinue;
end createForIteratorArray;

protected function convertType 
"function: convertType
  author: KS"
  input DAE.Type t;
  output Absyn.Path t2;
algorithm
  t2 := matchcontinue (t)
    local
      String s;
      Absyn.Path extObj;
    case ((DAE.T_INTEGER(_),_)) then Absyn.IDENT("Integer");
    case ((DAE.T_REAL(_),_)) then Absyn.IDENT("Real");
    case ((DAE.T_STRING(_),_)) then Absyn.IDENT("String");
    case ((DAE.T_BOOL(_),_)) then Absyn.IDENT("Boolean");
    case ((DAE.T_ENUMERATION(SOME(_),_,_,_),_)) then Absyn.IDENT("Enum");
//    case ((DAE.T_ENUM(),_)) then Absyn.IDENT("Enum");
    /* 
    case ((DAE.T_COMPLEX(ClassInf.MODEL(s),_,_),_)) then Absyn.IDENT(s);
    case ((DAE.T_COMPLEX(ClassInf.RECORD(s),_,_),_)) then Absyn.IDENT(s);
    case ((DAE.T_COMPLEX(ClassInf.BLOCK(s),_,_),_)) then Absyn.IDENT(s);
    case ((DAE.T_COMPLEX(ClassInf.CONNECTOR(s),_,_),_)) then Absyn.IDENT(s);
    case ((DAE.T_COMPLEX(ClassInf.EXTERNAL_OBJ(extObj),_,_),_)) then extObj; 
    */
 end matchcontinue;
end convertType;

protected function deriveArrayDimAndTempVars 
"function: deriveArrayDimAndTempVars.
	author: KS
	Given a list of range-expressions (tagged with loop variable identifiers), we derive the dimension of each range."
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.ForIterators rangeList;
  input Boolean impl;
  input list<Absyn.Subscript> accList;
  input list<Absyn.ElementItem> accTempVars;
  output Env.Cache cache;
  output list<Absyn.Subscript> outList1;
  output list<Absyn.ElementItem> outList2;
  output DAE.DAElist outDae "contain functions";
algorithm
  (cache,outList1,outList2,outDae) := matchcontinue (cache,env,rangeList,impl,accList,accTempVars)
    local
      list<Absyn.Subscript> localAccList;
      list<Absyn.ElementItem> localAccTempVars;
      Env.Env localEnv;
      Env.Cache localCache;
    case (localCache,_,{},_,localAccList,localAccTempVars) then (localCache,localAccList,localAccTempVars,DAEUtil.emptyDae);
    case (localCache,localEnv,(id,SOME(e)) :: restList,localImpl,localAccList,localAccTempVars)
      local
        Absyn.Exp e;
        Absyn.ForIterators restList;
        Boolean localImpl;
        list<Absyn.Subscript> elem;
        list<Absyn.ElementItem> elem2;
        Integer i;
        Absyn.Ident id;
        DAE.Type t;
        Absyn.Path t2;
        DAE.DAElist dae,dae1,dae2;
        
      equation
        (localCache,_,DAE.PROP((DAE.T_ARRAY(DAE.DIM(SOME(i)),t),NONE()),_),_,dae1) = Static.elabExp(localCache,localEnv,e,localImpl,NONE(),false);
        elem = {Absyn.SUBSCRIPT(Absyn.INTEGER(i))};
        localAccList = listAppend(localAccList,elem);
        t2 = convertType(t);
        elem2 = {Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TPATH(t2,NONE()),
            {Absyn.COMPONENTITEM(Absyn.COMPONENT(id,{},NONE()),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0,Absyn.TIMESTAMP(0.0,0.0)),NONE()))};
        localAccTempVars = listAppend(localAccTempVars,elem2);
        (localCache,localAccList,localAccTempVars,dae2) =
        deriveArrayDimAndTempVars(localCache,localEnv,restList,localImpl,localAccList,localAccTempVars);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then (localCache,localAccList,localAccTempVars,dae);
  end matchcontinue;
end deriveArrayDimAndTempVars;
/* ------------------------------------------------------ */

public function instantiateBoschClass "
Author BZ 2008-06, 
Instantiate a class, but _allways_ as inner class. This due to that we do not want flow equations equal to zero.
Called from Interactive.mo, boschsection.
"
	input Env.Cache inCache;
	input InstanceHierarchy inIH;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;  
  output DAE.DAElist outDAElist;
algorithm 
  (outCache,outEnv,outIH,outDAElist) :=
  matchcontinue (inCache,inIH,inProgram,inPath)
    local
      Absyn.Path cr,path;
      list<Env.Frame> env,env_1,env_2;
      DAE.DAElist dae1,dae;
      list<SCode.Class> cdecls;
      String name2,n,pathstr,name,cname_str;
      SCode.Class cdef;
      Env.Cache cache;
      InstanceHierarchy ih;
      
    case (cache,ih,{},cr)
      equation 
        Error.addMessage(Error.NO_CLASSES_LOADED, {});
      then
        fail();
        
    case (cache,ih,(cdecls as (_ :: _)),(path as Absyn.IDENT(name = name2))) /* top level class */ 
      equation 
        (cache,env) = Builtin.initialEnv(cache);
        (cache,env_1,ih,dae1) = instClassDecls(cache,env,ih, cdecls, path);
        (cache,env_2,ih,dae) = instBoschClassInProgram(cache,env_1,ih, cdecls, path);
      then
        (cache,env_2,ih,dae);
        
    case (cache,ih,(cdecls as (_ :: _)),(path as Absyn.QUALIFIED(name = name))) /* class in package */ 
      equation 
        (cache,env) = Builtin.initialEnv(cache);
        (cache,env_1,ih,_) = instClassDecls(cache,env,ih, cdecls, path);
        (cache,(cdef as SCode.CLASS(name = n)),env_2) = Lookup.lookupClass(cache,env_1, path, true);
        (cache,env_2,ih,_,dae,_,_,_,_,_) = 
          instClass(cache,env_2,ih,UnitAbsyn.noStore, DAE.NOMOD(), Prefix.NOPRE(), 
                    Connect.emptySet, cdef, {}, false, INNER_CALL(), ConnectionGraph.EMPTY) "impl" ;
        pathstr = Absyn.pathString(path);
      then
        (cache,env_2,ih,dae);
        
    case (cache,ih,cdecls,path) /* error instantiating */ 
      equation 
        cname_str = Absyn.pathString(path);
        Error.addMessage(Error.ERROR_FLATTENING, {cname_str});
      then
        fail();
  end matchcontinue;
end instantiateBoschClass;

protected function instBoschClassInProgram 
"Helper function for instantiateBoschClass"
	input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
algorithm 
  (outCache,outEnv,outIH,outDae):=
  matchcontinue (inCache,inEnv,inIH,inProgram,inPath)
    local
      DAE.DAElist dae;
      list<Env.Frame> env_1,env;
      SCode.Class c;
      String name,name2;
      list<SCode.Class> cs;
      Absyn.Path path;
      Env.Cache cache;
      InstanceHierarchy ih;
      
    case (cache,env,ih,((c as SCode.CLASS(name = name)) :: cs),Absyn.IDENT(name = name2))
      equation 
        equality(name = name2);
        (cache,env_1,ih,_,dae,_,_,_,_,_) = 
          instClass(cache,env,ih, UnitAbsyn.noStore, DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, c, 
                    {}, false, INNER_CALL(), ConnectionGraph.EMPTY) "impl" ;
      then
        (cache,env_1,ih,dae);
        
    case (cache,env,ih,((c as SCode.CLASS(name = name)) :: cs),(path as Absyn.IDENT(name = name2)))
      equation 
        failure(equality(name = name2));
        (cache,env,ih,dae) = instBoschClassInProgram(cache,env,ih, cs, path);
      then
        (cache,env,ih,dae);
        
    case (cache,env,ih,{},_) then (cache,env,ih,DAEUtil.emptyDae);
       
    case (cache,env,ih,_,_) 
      /* //Debug.fprint(\"failtrace\", \"inst_class_in_program failed\\n\") */  
      then fail(); 
  end matchcontinue;
end instBoschClassInProgram;

protected function selectList 
"function: select
Author BZ, 2008-09 
  This utility function selects one of two objects depending on a list of boolean variables.
  Used to constant evaluate if-equations."
  input list<Boolean> inBools;
  input list<Type_a> inList;
  input Type_a inFalse;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeA:=
  matchcontinue (inBools,inList,inFalse)
    local 
      Type_a x,head;
      case({},{},x) then x;
    case (true::_,head::_,_) then head; 
    case (false::inBools,_::inList,x) 
      equation
        head = selectList(inBools,inList,x);
      then head; 
  end matchcontinue;
end selectList;

protected function extractCurrentName 
"function: extractCurrentName
 Extracts SCode.Element name."
  input SCode.Element sele;
  output String ostring;
  output Option<Absyn.Info> oinfo;
algorithm 
  (ostring ,oinfo) := matchcontinue(sele)
    local
      Absyn.Path path;
      String name_,ret; 
      Absyn.Import imp;
      Option<Absyn.Info> info;
      
  case(SCode.EXTENDS(path,_,_)) 
    equation ret = Absyn.pathString(path); 
    then (ret,NONE);
  case(SCode.CLASSDEF(name = name_)) 
    then (name_,NONE);
  case(SCode.COMPONENT(component = name_, info=info)) 
    then (name_,info);
  case(SCode.IMPORT(imp)) 
    equation name_ = Absyn.printImportString(imp); 
      then (name_,NONE);
end matchcontinue;
end extractCurrentName;

public function splitElts "
This function splits the Element list into four lists
  1. Class definitions , imports and defineunits
  2. Class-extends class definitions
  3. Extends elements
  4. Components"
  input list<SCode.Element> elts;
  output list<SCode.Element> cdefImpElts;
  output list<SCode.Element> classextendsElts;
  output list<SCode.Element> extElts;
  output list<SCode.Element> compElts;  
algorithm 
  (cdefImpElts,classextendsElts,extElts,compElts) := matchcontinue (elts)
    local
      list<SCode.Element> innerComps,otherComps,comps;
      SCode.Element cdef,imp,ext;
      Absyn.InnerOuter io;
      
    case (elts)
      equation 
        (cdefImpElts,classextendsElts,extElts,innerComps,otherComps) = splitEltsInnerAndOther(elts);
        // put inner elements first in the list of 
        // elements so they are instantiated first!
        comps = listAppend(innerComps, otherComps);
      then 
        (cdefImpElts,classextendsElts,extElts,comps);        
  end matchcontinue;
end splitElts;

public function splitEltsInnerAndOther "
 @author: adrpo
  Splits elements into these categories:
  1. Class definitions, imports and defineunits
  2. Class-extends class definitions
  3. Extends elements
  4. Inner Components
  5. Any Other Components"
  input list<SCode.Element> elts;
  output list<SCode.Element> cdefImpElts;
  output list<SCode.Element> classextendsElts;
  output list<SCode.Element> extElts;
  output list<SCode.Element> innerCompElts;
  output list<SCode.Element> otherCompElts;  
algorithm 
  (cdefImpElts,classextendsElts,extElts,innerCompElts,otherCompElts) := matchcontinue (elts)
    local
      list<SCode.Element> res,xs,innerComps,otherComps;
      SCode.Element cdef,imp,ext,comp;
      Absyn.InnerOuter io;
      
    // empty case
    case ({}) then ({},{},{},{},{}); 

    // class definitions with class extends  
    case ((cdef as SCode.CLASSDEF(classDef = SCode.CLASS(classDef = SCode.CLASS_EXTENDS(baseClassName = _))))::xs)
      equation
        (cdefImpElts,classextendsElts,extElts,innerComps,otherComps) = splitEltsInnerAndOther(xs);
      then 
        (cdefImpElts,cdef :: classextendsElts,extElts,innerComps,otherComps);

    // class definitions without class extends
    case (((cdef as SCode.CLASSDEF(name = _)) :: xs))
      equation 
        (cdefImpElts,classextendsElts,extElts,innerComps,otherComps) = splitEltsInnerAndOther(xs);
      then 
        (cdef :: cdefImpElts,classextendsElts,extElts,innerComps,otherComps);

    // imports
    case (((imp as SCode.IMPORT(imp = _)) :: xs))
      equation 
        (cdefImpElts,classextendsElts,extElts,innerComps,otherComps) = splitEltsInnerAndOther(xs);
      then 
        (imp :: cdefImpElts,classextendsElts,extElts,innerComps,otherComps);

    // units        
    case (((imp as SCode.DEFINEUNIT(name = _)) :: xs))
      equation 
        (cdefImpElts,classextendsElts,extElts,innerComps,otherComps) = splitEltsInnerAndOther(xs);
      then 
        (imp :: cdefImpElts,classextendsElts,extElts,innerComps,otherComps);

    // extends elements
    case((ext as SCode.EXTENDS(baseClassPath =_))::xs)
      equation
        (cdefImpElts,classextendsElts,extElts,innerComps,otherComps) = splitEltsInnerAndOther(xs);
      then 
        (cdefImpElts,classextendsElts,ext::extElts,innerComps,otherComps);

    // inner components
    case ((comp as SCode.COMPONENT(component=_,innerOuter = io) ) :: xs)
      equation 
        true = Absyn.isInner(io);
        (cdefImpElts,classextendsElts,extElts,innerComps,otherComps) = splitEltsInnerAndOther(xs);
      then 
        (cdefImpElts,classextendsElts,extElts,comp::innerComps,otherComps);

    // any other components
    case ((comp as SCode.COMPONENT(component=_) ) :: xs)
      equation 
        (cdefImpElts,classextendsElts,extElts,innerComps,otherComps) = splitEltsInnerAndOther(xs);
      then 
        (cdefImpElts,classextendsElts,extElts,innerComps,comp::otherComps);        
  end matchcontinue;
end splitEltsInnerAndOther;

protected function orderComponents
"@author: adrpo
 this functions puts the component in front of the list if
 is inner or innerouter and at the end of the list otherwise"
  input SCode.Element inComp;
  input list<SCode.Element> inCompElts;
  output list<SCode.Element> outCompElts;
algorithm
  outCompElts := matchcontinue(inComp, inCompElts)
    local
      list<SCode.Element> compElts;
    
    // input/output come first!
    case (SCode.COMPONENT(component=_,attributes = SCode.ATTR(direction = Absyn.INPUT())), inCompElts)
      then inComp::inCompElts;
    case (SCode.COMPONENT(component=_,attributes = SCode.ATTR(direction = Absyn.OUTPUT())), inCompElts)
      then inComp::inCompElts;    
    // put inner/outer in front.
    case (SCode.COMPONENT(component=_,innerOuter = Absyn.INNER()), inCompElts)
      then inComp::inCompElts;
    case (SCode.COMPONENT(component=_,innerOuter = Absyn.INNEROUTER()), inCompElts)
      then inComp::inCompElts;
    // put constants in front
    case (SCode.COMPONENT(component=_,attributes = SCode.ATTR(variability = SCode.CONST())), inCompElts)
      then inComp::inCompElts;
    // put parameters in front
    case (SCode.COMPONENT(component=_,attributes = SCode.ATTR(variability = SCode.PARAM())), inCompElts)
      then inComp::inCompElts;
    // all other append to the end.
    case (SCode.COMPONENT(component=_), inCompElts)
      equation
        compElts = listAppend(inCompElts, {inComp});
      then compElts;
  end matchcontinue; 
end orderComponents;

protected function splitClassExtendsElts 
"This function splits the Element list into two lists
1. Class-extends class definitions
2. Any other element"
  input list<SCode.Element> elts;
  output list<SCode.Element> classextendsElts;
  output list<SCode.Element> outElts;
algorithm 
  (classextendsElts,outElts) := matchcontinue (elts)
    local
      list<SCode.Element> res,xs;
      SCode.Element cdef;
    case ({}) then ({},{}); 
      
    case ((cdef as SCode.CLASSDEF(classDef = SCode.CLASS(classDef = SCode.CLASS_EXTENDS(baseClassName = _))))::xs)
      equation
        (classextendsElts,res) = splitClassExtendsElts(xs);
      then (cdef :: classextendsElts, res);
    
    case cdef::xs
      equation 
        (classextendsElts,res) = splitClassExtendsElts(xs);
      then (classextendsElts, cdef :: res);
        
  end matchcontinue;
end splitClassExtendsElts;

protected function addClassdefsToEnv3 
"function: addClassdefsToEnv3 " 
  input Env.Env env;
  input InstanceHierarchy inIH;
  input Option<Mod> inMod;
  input SCode.Element sele;
  output Env.Env oenv;
  output InstanceHierarchy outIH;
  output SCode.Class osele;
algorithm 
  (oenv,outIH,osele) := matchcontinue(env,inIH,inMod,sele)
    local 
	    Mod mo,mo2; 
	    SCode.Element sele2;
	    Env.Env env2;
	    String str; 
	    SCode.Class retcl;
	    InstanceHierarchy ih;
	    list<DAE.SubMod> lsm,lsm2;
    
    case(_,ih,NONE,_) then fail();
            
    case(env,ih, SOME(mo as DAE.MOD(_,_, lsm ,_)), sele as SCode.CLASSDEF(name=str)) 
      equation
        (mo2,lsm2) =  extractCorrectClassMod2(lsm,str,{});
        // TODO: classinf below should be FQ
      (_,env2,ih, sele2 as SCode.CLASSDEF(classDef = retcl) , _, _,_) = 
      redeclareType(Env.emptyCache(),env,ih, mo2,sele, Prefix.NOPRE(), ClassInf.MODEL(Absyn.IDENT(str)),Connect.emptySet, true,DAE.NOMOD());
      then 
        (env2,ih,retcl);
  end matchcontinue;
end addClassdefsToEnv3;

protected function extractCorrectClassMod2 
"function: extractCorrectClassMod2
 This function extracts a modifier on a specific component.
 Referenced by the name." 
  input list<DAE.SubMod> smod;
  input String name;
  input list<DAE.SubMod> premod;
  output Mod omod;
  output list<DAE.SubMod> restmods;
algorithm (omod,restmods) := matchcontinue( smod , name , premod) 
  local 
    Mod mod;
    DAE.SubMod sub;
    String id;
    list<DAE.SubMod> rest,rest2;
    case({},_,premod) then (DAE.NOMOD(),premod);
  case(DAE.NAMEMOD(id, mod) :: rest, name, premod)
    equation 
    equality(id = name);
    rest2 = listAppend(premod,rest);
    then
      (mod, rest2);
  case(sub::rest,name,premod)
    equation 
    (mod,rest2) = extractCorrectClassMod2(rest,name,premod);
    then
      (mod, sub::rest2);
  case(_,_,_)
    equation
      Debug.fprint("failtrace", "- extract_Correct_Class_Mod_2 failed\n");
    then
      fail();
  end matchcontinue; 
end extractCorrectClassMod2;

protected function traverseModAddFinal 
"This function takes a modifer and a bool 
 to represent wheter it is final or not.
 If it is final, traverses down in the 
 modifier setting all final elements to true."
  input SCode.Mod mod;
  input Boolean finalPrefix;
  output SCode.Mod mod2;
algorithm mod2 := matchcontinue(mod,finalPrefix)
  case(mod, false) then mod;
  case(mod, true) 
    equation mod = traverseModAddFinal2(mod);
    then
      mod;
  case(_,_) 
    equation print(" we failed with traverseModAddFinal\n"); 
      then fail();
end matchcontinue;
end traverseModAddFinal;

protected function traverseModAddFinal2 
"Helper function for traverseModAddFinal"
  input SCode.Mod mod;
  output SCode.Mod mod2;
algorithm mod2 := matchcontinue(mod)
  case(SCode.NOMOD()) then SCode.NOMOD();
  case(SCode.REDECL(_,lelement))
    local list<SCode.Element> lelement;
    equation
      lelement = traverseModAddFinal3(lelement);
    then
      SCode.REDECL(true,lelement);
  case(SCode.MOD(_,each_,subs,eq))
    local 
      Absyn.Each each_;
      list<SCode.SubMod> subs;
      Option<tuple<Absyn.Exp,Boolean>> eq;
    equation
      subs = traverseModAddFinal4(subs);      
    then
      SCode.MOD(true,each_,subs,eq);
  case(_) equation print(" we failed with traverseModAddFinal2\n"); then fail();
end matchcontinue;
end traverseModAddFinal2;

protected function traverseModAddFinal3 
"Helper function for traverseModAddFinal2"
  input list<SCode.Element> ltuple;
  output list<SCode.Element> oltuple;
algorithm oltuple := matchcontinue(ltuple)
  local 
    list<SCode.Element> rest;
    SCode.Element ele;
    SCode.Attributes c6;
    Absyn.TypeSpec c7;
    SCode.Mod c8,mod;
    Option<Absyn.ConstrainClass> c13;
  case({}) then {};
  case(SCode.COMPONENT(c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13)::rest )
    local
      Ident c1;
      Absyn.InnerOuter c2;
      Boolean c3,c4,c5;
      SCode.OptBaseClass c9;
      Option<SCode.Comment> c10;
      Option<Absyn.Exp> c11;
      Option<Absyn.Info> c12;
    equation
      rest = traverseModAddFinal3(rest);
      mod = traverseModAddFinal2(c8);
    then
      SCode.COMPONENT(c1,c2,c3,c4,c5,c6,c7,mod,c9,c10,c11,c12,c13)::rest;
  case((ele as SCode.IMPORT(_))::rest) 
    equation
      rest = traverseModAddFinal3(rest);
    then ele::rest;
  case((ele as SCode.CLASSDEF(name = _))::rest) 
    equation
      rest = traverseModAddFinal3(rest);
    then ele::rest;
  case(SCode.EXTENDS(p,mod,ann)::rest) 
    local Absyn.Path p;Option<SCode.Annotation> ann;
    equation
       mod = traverseModAddFinal2(mod);
    then SCode.EXTENDS(p,mod,ann)::rest;
  case(_) equation print(" we failed with traverseModAddFinal3\n"); then fail();
end matchcontinue;
end traverseModAddFinal3;

protected function traverseModAddFinal4 
"Helper function for traverseModAddFinal2"
  input list<SCode.SubMod> subs;
  output list<SCode.SubMod> osubs; 
algorithm osubs:= matchcontinue(subs)
  local 
    String ident;
    SCode.Mod mod;
    list<Absyn.Subscript> intList;
    list<SCode.SubMod> rest; 
  case({}) then {};
  case((SCode.NAMEMOD(ident,mod))::rest )
    equation
      rest = traverseModAddFinal4(rest);
      mod = traverseModAddFinal2(mod);
    then
      SCode.NAMEMOD(ident,mod)::rest;
  case((SCode.IDXMOD(intList,mod))::rest )
    equation
      rest = traverseModAddFinal4(rest);
      mod = traverseModAddFinal2(mod);
    then
      SCode.IDXMOD(intList, mod)::rest;
  case(_) 
    equation print(" we failed with traverseModAddFinal4\n"); 
    then fail();
end matchcontinue;
end traverseModAddFinal4;

protected function modifyInstantiateClass 
"function: modifyInstantiateClass
 Here we check a modifier and a path, 
 if we have a redeclaration of the class 
 pointed by the path, we add this to a 
 special reclaration modifier.
 Function returning 2 modifiers: 
 - one (first output) to represent the redeclaration of 
                      'current' class (class-name equal to path)
 - two (second output) to represent any other modifier." 
  input DAE.Mod inMod;
  input Absyn.Path path;
  output DAE.Mod omod1;
  output DAE.Mod omod2;
algorithm 
  (omod1,omod2) := matchcontinue(inMod,path)
    local 
      Boolean fn;
      list<tuple<SCode.Element, DAE.Mod>> redecls,p1,p2;
      Integer i1;
    case(DAE.REDECL(fn,redecls), path)
      equation
        (p1,p2) = modifyInstantiateClass2(redecls,path);
        i1 = listLength(p1);
        omod1 = Util.if_(i1==0,DAE.NOMOD(), DAE.REDECL(fn,p1));
        i1 = listLength(p2);
        omod2 = Util.if_(i1==0,DAE.NOMOD(), DAE.REDECL(fn,p2));
      then
        (omod1,omod2);
    case(inMod,_) 
      then (DAE.NOMOD(), inMod);
  end matchcontinue;
end modifyInstantiateClass;

protected function modifyInstantiateClass2 
"Helper function for modifyInstantiateClass" 
  input list<tuple<SCode.Element, DAE.Mod>> redecls;
  input Absyn.Path path;
  output list<tuple<SCode.Element, DAE.Mod>> omod1;
  output list<tuple<SCode.Element, DAE.Mod>> omod2;
algorithm 
  (omod1,omod2) := matchcontinue(redecls,path)
    local 
      Boolean fn;
      list<tuple<SCode.Element, DAE.Mod>> rest,rec2,rec1;
      tuple<SCode.Element, DAE.Mod> head;
      DAE.Mod m;
      String id1,id2;
    case({},_) then ({},{});
    case( (head as  (SCode.CLASSDEF(name = id1),m))::rest, path)
      equation
        id2 = Absyn.pathString(path);
        true = stringEqual(id1,id2);
        (rec1,rec2) = modifyInstantiateClass2(rest,path);
      then
        (head::rec1,rec2);
    case(head::rest,path)
      equation
        (rec1,rec2) = modifyInstantiateClass2(rest,path);
      then
        (rec1,head::rec2);
  end matchcontinue;
end modifyInstantiateClass2;

protected function removeSelfReferenceAndUpdate 
"function removeSelfReferenceAndUpdate
 BZ 2007-07-03
 This function checks if there is a reference to itself. 
 If it is, it removes the reference.
 But also instantiate the declared type, if any. 
 If it fails (declarations of array dimensions using 
 the size of itself) it will just remove the element."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input UnitAbsyn.InstStore store;
  input list<Absyn.ComponentRef> inRefs;
  input Absyn.ComponentRef inRef;
  input Absyn.Path inPath;
  input ClassInf.State inState;
  input Connect.Sets icsets;
  input Boolean p;
  input SCode.Attributes iattr;
  input Boolean impl;
  input Absyn.InnerOuter io;
  input InstDims inst_dims;
  input Prefix.Prefix pre;
  input DAE.Mod mods;
  input Boolean finalPrefix;
  input Option<Absyn.Info> info;
  output Env.Cache o3;  
  output Env.Env o2;
  output InstanceHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output list<Absyn.ComponentRef> o1;  
algorithm 
  (o2,o3,outIH,outStore,o1) :=  
  matchcontinue(cache,inEnv,inIH,store,inRefs,inRef,inPath,inState,icsets,p,iattr,impl,io,inst_dims,pre,mods,finalPrefix,info)
    local 
      Absyn.Path sty;
      Absyn.ComponentRef c1,c2;
      list<Absyn.ComponentRef> cl1,cl2;
      Env.Env env,compenv,cenv;
      Env.Cache cache;
      Integer i1,i2;
      list<Absyn.Subscript> ad;
      SCode.Accessibility acc;
      SCode.Variability param;
      Absyn.Direction dir; 
      Ident n;
      SCode.Class c;
      DAE.Type ty;
      ClassInf.State state;
      DAE.Attributes attr;
      Boolean prot,flowPrefix,streamPrefix;
      Connect.Sets csets;
      SCode.Attributes attr;
      list<DimExp> dims;
      DAE.Var new_var;
      InstanceHierarchy ih;
      
    case(cache,env,ih,store,cl1,c1,_,_,_,_,_,_,_,_,_,_,_,_)
      equation 
        cl2 = removeCrefFromCrefs(cl1, c1);
        i1 = listLength(cl2);
        i2 = listLength(cl1); 
        true = ( i1 == i2);
      then
        (cache,env,ih,store,cl2);
        
    case(cache,env,ih,store,cl1,c1 as Absyn.CREF_IDENT(name = n) ,sty,state,csets,prot,
         (attr as SCode.ATTR(arrayDims = ad, flowPrefix = flowPrefix, streamPrefix = streamPrefix, 
                             accesibility = acc, variability = param, direction = dir)), 
         impl,io,inst_dims,pre,mods,finalPrefix,info) 
         // we have reference to ourself, try to instantiate type.  
      equation 
        cl2 = removeCrefFromCrefs(cl1, c1);
        (cache,c,cenv) = Lookup.lookupClass(cache,env, sty, true);
        (cache,dims,_) = elabArraydim(cache,cenv, c1, sty, ad, NONE, impl, NONE,true)  ;
        (cache,compenv,ih,store,_,_,ty,_) = instVar(cache, cenv, ih, store, state, DAE.NOMOD(), pre, csets, n, c, attr, prot, dims, {}, inst_dims, true, NONE, io, finalPrefix, info, ConnectionGraph.EMPTY);
        new_var = DAE.TYPES_VAR(n,DAE.ATTR(flowPrefix,streamPrefix,acc,param,dir,io),prot,ty,DAE.UNBOUND());
        env = Env.updateFrameV(env, new_var, Env.VAR_TYPED(), compenv)  ;
      then
        (cache,env,ih,store,cl2);
            
    case(cache,env,ih,store,cl1,c1,_,_,_,_,_,_,_,_,_,_,_,_)
      equation 
        cl2 = removeCrefFromCrefs(cl1, c1);
      then
        (cache,env,ih,store,cl2);
        
  end matchcontinue;
end removeSelfReferenceAndUpdate;

protected function replaceClassname 
"function to replace the class name"
  input SCode.Class isc;
  input Ident name;
  output SCode.Class osc;
algorithm
  (osc) := matchcontinue(isc,name)
    local 
      SCode.Class sc1;
      Boolean b2,b3;
      SCode.Restriction r;
      SCode.ClassDef p;
      Absyn.Info i;

    case( sc1 as SCode.CLASS(_,b2,b3,r,p,i),name)
      then
        SCode.CLASS(name,b2,b3,r,p,i);
  end matchcontinue;
end replaceClassname;

protected function  instConditionalDeclaration 
"checks the declaration condition. 
 If true, the dae elements are removed and 
 connections to and from the component are removed."
  input Env.Cache cache;  
  input Env.Env env;
  input Option<Absyn.Exp> cond;
  input Ident compName;
  input DAE.DAElist dae;
  input Connect.Sets sets;
  input Prefix.Prefix pre;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ConnectionGraph.ConnectionGraph outGraph;
  output DAE.DAElist outDae;
algorithm
  (outCache,outDae,outSets,outGraph,outDae) := matchcontinue(cache,env,cond,compName,dae,sets,pre,inGraph)
    local 
      Absyn.Exp condExp; DAE.Exp e;
      DAE.Type t; DAE.Const c;
      String s1,s2;
      Boolean b;
      DAE.ComponentRef cr;
      ConnectionGraph.ConnectionGraph graph;
      DAE.DAElist dae,dae1,dae2;
      
    // no condition ... keep the same
    case(cache,env,NONE,compName,dae,sets,_,graph) then (cache,dae,sets,graph,DAEUtil.emptyDae);
    // we have some condition, deal with it
    case(cache,env,SOME(condExp),compName,dae,sets,pre,graph) equation
      (cache,e,DAE.PROP(t,c ),_,dae1) = Static.elabExp(cache, env, condExp, false, NONE, false);
      true = Types.isBoolean(t);
      true = Types.isParameterOrConstant(c);
      (cache,Values.BOOL(b),_) = Ceval.ceval(cache, env, e, false, NONE, NONE, Ceval.MSG());
      dae = Util.if_(b,dae,DAEUtil.emptyDae);
      cr = PrefixUtil.prefixCref(pre,DAE.CREF_IDENT(compName,DAE.ET_OTHER(),{}));
      sets = ConnectUtil.addDeletedComponent(b,cr,sets);
    then (cache,dae,sets,graph,dae1);

    // Error: Wrong type on condition
    case(cache,env,SOME(condExp),compName,dae,sets,_,graph) equation
      (cache,e,DAE.PROP(t,c ),_,_) = Static.elabExp(cache, env, condExp, false, NONE, false);
      false = Types.isBoolean(t);
      s1 = Exp.printExpStr(e);
      s2 = Types.unparseType(t);
      Error.addMessage(Error.IF_CONDITION_TYPE_ERROR,{s1,s2});
    then fail();

    // Error: condition not parameter or constant
    case(cache,env,SOME(condExp),compName,dae,sets,_,graph) equation
      (cache,e,DAE.PROP(t,c ),_,_) = Static.elabExp(cache, env, condExp, false, NONE, false);
      true = Types.isBoolean(t);
      false = Types.isParameterOrConstant(c);
      s1 = Exp.printExpStr(e);
      Error.addMessage(Error.COMPONENT_CONDITION_VARIABILITY,{s1});
    then fail();
    // failtrace
    case(cache,env,SOME(condExp),compName,dae,sets,_,graph)
      equation
        Debug.fprintln("failtrace", "- Inst.instConditionalDeclaration failed on component: " +& compName +& " for cond: " +& Dump.printExpStr(condExp));
      then fail();      
  end matchcontinue;
end instConditionalDeclaration;

protected function removeCrefFromCrefs2 
"function: removeCrefFromCrefs 
  Removes a variable from a variable list"
  input list<Absyn.ComponentRef> inAbsynComponentRefLst;
  input Absyn.ComponentRef inComponentRef;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm 
  outAbsynComponentRefLst:=
  matchcontinue (inAbsynComponentRefLst,inComponentRef)
    local
      list<Absyn.ComponentRef> rest_1,rest;
      Absyn.ComponentRef cr1,cr2;
    case ({},_) then {}; 
    case ((cr1 :: rest),cr2)
      equation 
        true = Absyn.crefEqual(cr1,cr2);
        rest_1 = removeCrefFromCrefs2(rest, cr2);
      then
        rest_1;
      case ((cr1 :: rest),cr2) 
      equation 
        rest_1 = removeCrefFromCrefs2(rest,cr2);
      then
        (cr1::rest_1);
  end matchcontinue;
end removeCrefFromCrefs2;

protected function checkRecursiveDefinitionRecConst 
"help function to checkRecursiveDefinition
 Makes exception for record constructor 
 functions which have the output record 
 name being the same as the function name.
 
 This function returns false if class 
 restriction is record and ci_state 
 is function"
  input ClassInf.State ci_state;
  input SCode.Class cl;
  output Boolean res;
algorithm
  res := matchcontinue(ci_state,cl)
    case(ClassInf.FUNCTION(_),SCode.CLASS(restriction=SCode.R_RECORD())) then false; 
    case(_,_) then true;
  end matchcontinue;
end checkRecursiveDefinitionRecConst;

protected function propagateClassPrefix 
"Propagate ClassPrefix, i.e. variability to a component.
 This is needed to make sure that e.g. a parameter does 
 not generate an equation but a binding."
  input SCode.Attributes attr;
  input Prefix.Prefix pre;
  output SCode.Attributes outAttr;
algorithm
  outAttr := matchcontinue(attr,pre)
    local 
      Absyn.ArrayDim ad;
      Boolean fl,st;
      SCode.Accessibility acc;
      Absyn.Direction dir;
      SCode.Variability vt;
    
    /* If classprefix is variable, keep component variability*/
    case(attr,Prefix.PREFIX(_,Prefix.CLASSPRE(SCode.VAR()))) then attr;
    /* If variability is constant, do not override it! */
    case(attr as SCode.ATTR(variability = SCode.CONST()),_) then attr;
    /* If classprefix is parameter or constant, override component variabilty */
    case(SCode.ATTR(ad,fl,st,acc,_,dir),Prefix.PREFIX(_,Prefix.CLASSPRE(vt))) 
      then SCode.ATTR(ad,fl,st,acc,vt,dir);
        
    case(attr,_) 
      then attr;
  end matchcontinue;
end propagateClassPrefix;  

protected function checkUseConstValue 
"help function to instBinding. 
 If first arg is true, it returns the constant expression found in Value option.
 This is used to ensure that e.g. stateSelect attribute gets a constant value 
 and not a parameter expression." 
  input Boolean useConstValue;
  input DAE.Exp e;
  input Option<Values.Value> v;
  output DAE.Exp outE;
algorithm
  outE := matchcontinue(useConstValue,e,v)
    local Values.Value val;
    case(false,e,v) then e;
    case(true,_,SOME(val)) equation
      e = Static.valueExp(val);
    then e;
    case(_,e,_) then e;      
  end matchcontinue;
end checkUseConstValue;

protected function instIfTrueBranches 
"Author: BZ, 2008-09
 Initialise a list of if-equations, 
 if, elseif-1 ... elseif-n."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input list<list<SCode.EEquation>> inTypeALst;
  input Boolean IE;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output list<list<DAE.Element>> outDaeLst;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outDaeLst,outSets,outState,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inTypeALst,IE,inBoolean,inGraph)
    local
      list<Env.Frame> env,env_1,env_2;
      DAE.Mod mod;
      Prefix.Prefix pre;
      Connect.Sets csets,csets_1,csets_2;
      ClassInf.State ci_state,ci_state_1,ci_state_2;
      Boolean impl;
      list<list<DAE.Element>> llb;
      list<list<SCode.EEquation>> es;
      list<SCode.EEquation> la,e;
      DAE.DAElist lb;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      SCode.EEquation eee;
      list<DAE.Element> elts;
      
    case (cache,env,ih,mod,pre,csets,ci_state,{},_,impl,graph) 
      then 
        (cache,env,ih,{},csets,ci_state,graph);  
    case (cache,env,ih,mod,pre,csets,ci_state,(e :: es),false,impl,graph)
      equation 
        (cache,env_1,ih,DAE.DAE(elts,_),csets_1,ci_state_1,graph) = instList(cache,env,ih, mod, pre, csets, ci_state, instEEquation, e, impl,graph);
        (cache,env_2,ih,llb,csets_2,ci_state_2,graph) = instIfTrueBranches(cache,env_1,ih, mod, pre, csets_1, ci_state_1,  es, false, impl,graph);        
      then
        (cache,env_2,ih,elts::llb,csets_2,ci_state_2,graph);
    case (cache,env,ih,mod,pre,csets,ci_state,(e :: es),true,impl,graph)
      equation 
        (cache,env_1,ih,DAE.DAE(elts,_),csets_1,ci_state_1,graph) = instList(cache,env,ih, mod, pre, csets, ci_state, instEInitialequation, e, impl,graph);
        (cache,env_2,ih,llb,csets_2,ci_state_2,graph) = instIfTrueBranches(cache,env_1,ih, mod, pre, csets_1, ci_state_1,  es, true, impl,graph);        
      then
        (cache,env_2,ih,elts::llb,csets_2,ci_state_2,graph);
    case (cache,env,ih,mod,pre,csets,ci_state,(e :: es),_,impl,graph)
      equation 
				true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "Inst.instIfTrueBranches failed on equations: " +& 
                       Util.stringDelimitList(Util.listMap(e, SCode.equationStr), "\n"));
      then
        fail();
  end matchcontinue;
end instIfTrueBranches;
 
public function propagateAbSCDirection "
Author BZ 2008-05
This function merged derived Absyn.ElementAttributes with the current input SCode.ElementAttributes."
  input Absyn.Direction v1;
  input Option<Absyn.ElementAttributes> optDerAttr;
  output Absyn.Direction v3;
algorithm v3 := matchcontinue(v1,optDerAttr)
  local Absyn.Direction v2;
  case(v1,NONE) then v1;
  case(Absyn.BIDIR(),SOME(Absyn.ATTR(direction=v2))) then v2;
  case(v1,SOME(Absyn.ATTR(direction=Absyn.BIDIR()))) then v1;
  case(v1,SOME(Absyn.ATTR(direction=v2)))
    equation
      equality(v1 = v2);
    then v1;
  case(_,_) 
    equation 
      print(" failure in propagateAbSCDirection, Absyn.DIRECTION mismatch");
      Error.addMessage(Error.COMPONENT_INPUT_OUTPUT_MISMATCH, {"",""});
    then 
      fail();
end matchcontinue;
end propagateAbSCDirection;

protected function makeCrefBaseType "Function: makeCrefBaseType" 
  input DAE.Type baseType;
  input InstDims dims;
  output DAE.ExpType ety;
algorithm ety := matchcontinue(baseType,dims)
  local 
    DAE.ExpType ty; 
    DAE.Type tp_1;
    list<Option<Integer>> lst;
  case(baseType, dims) 
    equation
      lst = instdimsIntOptList(Util.listLast(dims));
      tp_1 = arrayBasictypeBaseclass2(lst, baseType);
      ty = Types.elabType(tp_1); 
    then 
      ty;
  case(baseType, dims) 
    equation
      failure(_ = instdimsIntOptList(Util.listLast(dims)));
      ty = Types.elabType(baseType); 
    then 
      ty;
  case(baseType, dims) 
    equation
      lst = instdimsIntOptList(Util.listLast(dims));
      tp_1 = liftNonBasicTypesNDimensions(baseType,lst);
      ty = Types.elabType(tp_1); 
    then 
      ty;   
  case(baseType, dims) 
    equation
      failure(_ = instdimsIntOptList(Util.listLast(dims)));
      ty = Types.elabType(baseType); 
    then 
      ty;
  case(_,_)
    equation 
    Debug.fprint("failtrace", "- make_makeCrefBaseType failed\n");
    then
      fail();
end matchcontinue;
end makeCrefBaseType;

protected function liftNonBasicTypesNDimensions "Function: liftNonBasicTypesNDimensions
This is to handle a Option<integer> list of dimensions. 
"
  input DAE.Type tp;
  input  list<Option<Integer>> dimt;
  output DAE.Type otype;
algorithm otype := matchcontinue(tp,dimt)
  local Option<Integer> x;
  case(tp,{}) then tp;
  case(tp, x::dimt) 
    equation
      tp = liftNonBasicTypes(tp,x);
      tp = liftNonBasicTypesNDimensions(tp,dimt);
      then 
        tp;      
end matchcontinue;
end liftNonBasicTypesNDimensions;

protected function instComplexEquation "instantiate a comlex equation, i.e. c = Complex(1.0,-1.0) when Complex is a record"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input DAE.Type tp;
  input DAE.ElementSource source "the origin of the element";
  input SCode.Initial initial_;
  output DAE.DAElist dae;
algorithm
  dae := matchcontinue(lhs,rhs,tp,source,initial_)
    local DAE.Element daeEl; String s;
    // Records 
    case(lhs,rhs,tp,source,initial_) 
      equation
        true = Types.isRecord(tp);
        dae = makeComplexDaeEquation(lhs,rhs,source,initial_);
      then dae;
        
    // External objects are treated as ordinary equations
    case (lhs,rhs,tp,source,initial_) 
      equation
        true = Types.isExternalObject(tp);
        dae = makeDaeEquation(lhs,rhs,source,initial_);
        // adrpo: TODO! FIXME! shouldn't we return the dae here??!!
      then DAEUtil.emptyDae;

    // adrpo 2009-05-15: also T_COMPLEX that is NOT record but TYPE should be allowed
    //                   as is used in Modelica.Mechanics.MultiBody (Orientation type)
    case(lhs,rhs,tp,source,initial_) equation 
      // adrpo: TODO! check if T_COMPLEX(ClassInf.TYPE)!     
      dae = makeComplexDaeEquation(lhs,rhs,source,initial_);
    then dae;               
                                  
    // complex equation that is not of restriction record is not allowed 
    case(lhs,rhs,tp,source,initial_) 
      equation 
        false = Types.isRecord(tp);     
        s = Exp.printExpStr(lhs) +& " = " +& Exp.printExpStr(rhs);
        Error.addMessage(Error.ILLEGAL_EQUATION_TYPE,{s});
      then fail();        
  end matchcontinue;
end instComplexEquation;
  
protected function makeComplexDaeEquation "Creates a DAE.COMPLEX_EQUATION for equations involving records"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input DAE.ElementSource source "the origin of the element";  
  input SCode.Initial initial_;
  output DAE.DAElist dae;
algorithm
  dae := matchcontinue(lhs,rhs,source,initial_)
  local DAE.FunctionTree funcs;
    case(lhs,rhs,source,SCode.NON_INITIAL()) equation
      funcs = DAEUtil.avlTreeNew();
    then DAE.DAE({DAE.COMPLEX_EQUATION(lhs,rhs,source)},funcs);

    case(lhs,rhs,source,SCode.INITIAL()) equation
      funcs = DAEUtil.avlTreeNew();        
    then DAE.DAE({DAE.INITIAL_COMPLEX_EQUATION(lhs,rhs,source)},funcs);
  end matchcontinue;
end makeComplexDaeEquation;

protected function getCrefFromComp "
Author: BZ"
  input SCode.Element inEle;
  output list<Absyn.ComponentRef> cref;
algorithm cref := matchcontinue(inEle)
  local String crefName;
  case(SCode.CLASSDEF(name=crefName)) then {Absyn.CREF_IDENT(crefName,{})};
  case(SCode.COMPONENT(component=crefName)) then {Absyn.CREF_IDENT(crefName,{})};
  case(SCode.EXTENDS(_,_,_)) 
    equation Debug.fprint("inst", "-Inst.get_Cref_From_Comp not implemented for SCode.EXTENDS(_,_)\n"); then {};
  case(SCode.IMPORT(_)) 
    equation Debug.fprint("inst", "-Inst.get_Cref_From_Comp not implemented for SCode.IMPORT(_,_)\n"); then {};
end matchcontinue;
end getCrefFromComp;

protected function getCrefFromCompDim "
Author: BZ, 2009-07
Get Absyn.ComponentRefs from dimension in SCode.COMPONENT"
  input SCode.Element inEle;
  output list<Absyn.ComponentRef> cref;
algorithm cref := matchcontinue(inEle)
  local 
    String crefName;
    list<Absyn.Subscript> ads;
  case(SCode.COMPONENT(attributes = SCode.ATTR(arrayDims = ads))) 
    then 
      Absyn.getCrefsFromSubs(ads);
  case(_) then {};
end matchcontinue;
end getCrefFromCompDim;

protected function getCrefFromCond "
  author: PA
  Return all variables in a conditional component clause.
  Done to instantiate components referenced in other components, See also getCrefFromMod and
  updateComponentsInEnv."
  input Option<Absyn.Exp> cond;
  output list<Absyn.ComponentRef> crefs;
algorithm 
  crefs := matchcontinue(cond)
    local  Absyn.Exp e;
    case(NONE) then {};
    case SOME(e) then Absyn.getCrefFromExp(e,true);
  end matchcontinue;
end getCrefFromCond;

protected function updateComponentsInEnv2 
"function updateComponentsInEnv2
  author: PA
  Help function to updateComponentsInEnv."
  input Env.Cache cache;
  input Env env;
  input InstanceHierarchy inIH;
  input Prefix.Prefix pre;
  input Mod mod;
  input list<Absyn.ComponentRef> crefs;
  input ClassInf.State ci_state;
  input Connect.Sets csets;
  input Boolean impl;
  input HashTable5.HashTable updatedComps;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output Connect.Sets outSets;
  output HashTable5.HashTable outUpdatedComps;
  output DAE.DAElist outDae;
algorithm 
  (outCache,outEnv,outIH,outSets,outUpdatedComps,outDae) :=
  matchcontinue (cache,env,inIH,pre,mod,crefs,ci_state,csets,impl,updatedComps)
    local
      list<Env.Frame> env_1,env_2,env;
      Connect.Sets csets;
      DAE.Mod mods;
      Absyn.ComponentRef cr;
      list<Absyn.ComponentRef> rest;
      InstanceHierarchy ih;
      String n;
      DAE.DAElist dae,dae1,dae2;
      
      // two first cases catches when we want to update an already typed and bound var.
    case (cache,env,ih,pre,mods,(cr :: rest),ci_state,csets,impl,updatedComps) 
      equation
        n = Absyn.printComponentRefStr(cr);
        (_,DAE.TYPES_VAR(binding = DAE.VALBOUND(_)),SOME((_,_)),_,_) = Lookup.lookupIdentLocal(cache,env, n);
        (cache,env_2,ih,csets,updatedComps,dae) = updateComponentsInEnv2(cache, env, ih, pre, mods, rest, ci_state, csets, impl, updatedComps);
      then
        (cache,env_2,ih,csets,updatedComps,dae);
        
    case (cache,env,ih,pre,mods,(cr :: rest),ci_state,csets,impl,updatedComps) 
      equation
        n = Absyn.printComponentRefStr(cr);
        (_,DAE.TYPES_VAR(binding = DAE.EQBOUND(exp=_)),SOME((_,_)),_,_) = Lookup.lookupIdentLocal(cache,env, n);
        (cache,env_2,ih,csets,updatedComps,dae) = updateComponentsInEnv2(cache, env, ih, pre, mods, rest, ci_state, csets, impl, updatedComps);
      then
        (cache,env_2,ih,csets,updatedComps,dae);
        
    case (cache,env,ih,pre,mods,(cr :: rest),ci_state,csets,impl,updatedComps) /* Implicit instantiation */ 
      equation 
        //ErrorExt.setCheckpoint(); 
        // this line below "updateComponentInEnv" can not fail so no need to catch that checkpoint(error).
        //print(" Updating component: " +& Absyn.printComponentRefStr(cr) +& " mods: " +& Mod.printModStr(mods)+& "\n");
        (cache,env_1,ih,csets,updatedComps,dae1) = updateComponentInEnv(cache, env, ih, pre, mods, cr, ci_state, csets, impl,updatedComps);
        //ErrorExt.rollBack();
        (cache,env_2,ih,csets,updatedComps,dae2) = updateComponentsInEnv2(cache, env_1, ih, pre, mods, rest, ci_state, csets, impl, updatedComps);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,env_2,ih,csets,updatedComps,dae);

    case (cache,env,ih,pre,_,{},ci_state,csets,impl,updatedComps) 
      then (cache,env,ih,csets,updatedComps,DAEUtil.emptyDae);
         
    case (cache,env,ih,pre,_,_,ci_state,csets,impl,updatedComps) equation
        Debug.fprint("failtrace","-updateComponentsInEnv failed\n");
      then fail();
  end matchcontinue;
end updateComponentsInEnv2;

protected function noModForUpdatedComponents "help function for updateComponentInEnv,

For components that already have been visited by updateComponentsInEnv, they must be instantiated without 
modifiers to prevent infinite recursion"
  input HashTable5.HashTable updatedComps;
  input Absyn.ComponentRef cref;
  input  DAE.Mod mods;
  input  DAE.Mod cmod;
  input  SCode.Mod m;
  output DAE.Mod outMods;
  output DAE.Mod outCmod;
  output SCode.Mod outM;
algorithm
  (outMods,outCmod,outM) := matchcontinue(updatedComps,cref,mods,cmod,m)
    case(updatedComps,cref,mods,cmod,m) equation
      _ = HashTable5.get(cref,updatedComps);
    then (DAE.NOMOD(),DAE.NOMOD(),SCode.NOMOD());
      
    case(updatedComps,cref,mods,cmod,m) then (mods,cmod,m);
  end matchcontinue;
end noModForUpdatedComponents;

protected function makeFullyQualified2 
"help function to makeFullyQualified"
  input Env.Env env;
  input Ident  className;
output Absyn.Path path;
algorithm
  path := matchcontinue(env,className)
  local String className; Absyn.Path scope; 
    case(env,className) equation
      SOME(scope) = Env.getEnvPath(env);        
        path = Absyn.joinPaths(scope, Absyn.IDENT(className));
      then path;
    case(env,className) equation
      NONE = Env.getEnvPath(env);      
    then Absyn.IDENT(className);
  end matchcontinue;
end makeFullyQualified2;

protected function propagateBinding "
This function modifies equations into bindings for parameters"
  input DAE.DAElist inVarsDae;
  input DAE.DAElist inEquationsDae "Note: functions from here are not considered";
  output DAE.DAElist outVarsDae;
algorithm
  outVars := matchcontinue(inVarsDae,inEquationsDae)
  local
    list<DAE.Element> vars, vars1, equations;
    DAE.Element var; DAE.Exp e; DAE.ComponentRef componentRef;
    DAE.VarKind kind; DAE.VarDirection direction; 
    DAE.VarProtection protection; DAE.Type ty;
    Option<DAE.Exp> binding; DAE.InstDims  dims;
    DAE.Flow flowPrefix; DAE.Stream streamPrefix;
    list<Absyn.Path> pathLst;
    Option<DAE.VariableAttributes> variableAttributesOption;
    Option<SCode.Comment> absynCommentOption;
    Absyn.InnerOuter innerOuter;
    DAE.ElementSource source "the origin of the element";
    DAE.FunctionTree funcs,funcs2;
    case (DAE.DAE(vars,funcs),DAE.DAE({},_)) then DAE.DAE(vars,funcs);
    case (DAE.DAE({},funcs),_) then DAE.DAE({},funcs);  
    case (DAE.DAE(DAE.VAR(componentRef,kind,direction,protection,ty,NONE(),dims,
                  flowPrefix,streamPrefix,source,variableAttributesOption,
                  absynCommentOption,innerOuter)::vars,funcs), DAE.DAE(equations,_))
      equation
        SOME(e)=findCorrespondingBinding(componentRef, equations);
        DAE.DAE(vars1,funcs) = propagateBinding(DAE.DAE(vars,funcs),DAE.DAE(equations,funcs));
      then  
        DAE.DAE(DAE.VAR(componentRef,kind,direction,protection,ty,SOME(e),dims,
                flowPrefix,streamPrefix,source,variableAttributesOption,
                absynCommentOption,innerOuter)::vars1,funcs);

    case (DAE.DAE(var::vars,funcs), DAE.DAE(equations,_))
      equation        
        DAE.DAE(vars1,_)=propagateBinding(DAE.DAE(vars,funcs),DAE.DAE(equations,funcs));
      then  
        DAE.DAE(var::vars1,funcs);
  end matchcontinue;
end propagateBinding;

protected function findCorrespondingBinding "
Helper function for propagateBinding"
  input DAE.ComponentRef inCref;
  input list<DAE.Element> inEquations;
  output Option<DAE.Exp> outExp;
algorithm
  outExp:=matchcontinue(inCref, inEquations)
  local
    DAE.ComponentRef cref,cref2,cref3;
    DAE.Exp e;
    list<DAE.Element> equations;
    
    case (_, {}) then NONE();
    case (cref, DAE.DEFINE(componentRef=cref2, exp=e)::_)
      equation
        true=Exp.crefEqual(cref,cref2);
      then
        SOME(e);
    case (cref, DAE.EQUATION(exp=DAE.CREF(cref2,_),scalar=e)::_)          
      equation
        true=Exp.crefEqual(cref,cref2);
      then
        SOME(e);
    case (cref, DAE.EQUEQUATION(cr1=cref2,cr2=cref3)::_)          
      equation
        true=Exp.crefEqual(cref,cref2);
        e=Exp.crefExp(cref3);
      then
        SOME(e);
    case (cref, DAE.COMPLEX_EQUATION(lhs=DAE.CREF(cref2,_),rhs=e)::_)          
      equation
        true=Exp.crefEqual(cref,cref2);
      then
        SOME(e);
    case (cref, _::equations)
      then findCorrespondingBinding(cref,equations);    
  end matchcontinue;
end findCorrespondingBinding;



// *********************************************************************
//    hash table implementation for cashing instantiation results
// *********************************************************************

function addToInstCache
  input Absyn.Path fullEnvPathPlusClass;  
  input Option<CachedInstItem> fullInstOpt;
  input Option<CachedInstItem> partialInstOpt;
algorithm
  _ := matchcontinue(fullEnvPathPlusClass,fullInstOpt, partialInstOpt)
    local
      CachedInstItem fullInst, partialInst;
      InstHashTable instHash;

    // nothing is we have +d=noCache
    case (_, _, _)
      equation
        true = RTOpts.debugFlag("noCache"); 
       then 
         ();

    // we have them both  
    case (fullEnvPathPlusClass, SOME(fullInst), SOME(partialInst))
      equation
        instHash = System.getFromRoots(0);
        instHash = add((fullEnvPathPlusClass,{fullInstOpt,partialInstOpt}),instHash);
        System.addToRoots(0, instHash);
      then
        ();

    // we have a partial inst result and the full in the cache
    case (fullEnvPathPlusClass, NONE(), SOME(partialInst))
      equation
        instHash = System.getFromRoots(0);
        // see if we have a full inst here
        {SOME(fullInst),_} = get(fullEnvPathPlusClass, instHash);
        instHash = add((fullEnvPathPlusClass,{SOME(fullInst),partialInstOpt}),instHash);
        System.addToRoots(0, instHash);
      then
        ();

    // we have a partial inst result and the full is NOT in the cache
    case (fullEnvPathPlusClass, NONE(), SOME(partialInst))
      equation
        instHash = System.getFromRoots(0);
        // see if we have a full inst here
        // failed above {SOME(fullInst),_} = get(fullEnvPathPlusClass, instHash);
        instHash = add((fullEnvPathPlusClass,{NONE(),partialInstOpt}),instHash);
        System.addToRoots(0, instHash);
      then
        ();

    // we have a full inst result and the partial in the cache
    case (fullEnvPathPlusClass, SOME(fullInst), NONE())
      equation
        instHash = System.getFromRoots(0);
        // see if we have a partial inst here
        {_,SOME(partialInst)} = get(fullEnvPathPlusClass, instHash);
        instHash = add((fullEnvPathPlusClass,{fullInstOpt,SOME(partialInst)}),instHash);
        System.addToRoots(0, instHash);
      then
        ();

    // we have a full inst result and the partial is NOT in the cache
    case (fullEnvPathPlusClass, SOME(fullInst), NONE())
      equation
        instHash = System.getFromRoots(0);
        // see if we have a partial inst here
        // failed above {_,SOME(partialInst)} = get(fullEnvPathPlusClass, instHash);
        instHash = add((fullEnvPathPlusClass,{fullInstOpt,NONE()}),instHash);
        System.addToRoots(0, instHash);
      then
        ();
        
    // we failed above??!!
    case (fullEnvPathPlusClass, fullInstOpt, partialInstOpt)
      equation
      then
        ();
  end matchcontinue;
end addToInstCache;


public 
uniontype CachedInstItem
  // *important* inputs/outputs for instClassIn 
  record FUNC_instClassIn
    tuple<Env.Cache, Env, InstanceHierarchy, UnitAbsyn.InstStore,
          Mod, Prefix, Connect.Sets, ClassInf.State, SCode.Class,
          Boolean, InstDims, Boolean,ConnectionGraph.ConnectionGraph,
          Option<DAE.ComponentRef>> inputs;
    tuple<Env.Cache, Env, InstanceHierarchy, UnitAbsyn.InstStore,  
          DAE.DAElist, Connect.Sets, ClassInf.State, list<DAE.Var>, 
          Option<DAE.Type>, Option<Absyn.ElementAttributes>, DAE.EqualityConstraint,
          ConnectionGraph.ConnectionGraph> outputs;
  end FUNC_instClassIn;
  
  // *important* inputs/outputs for partialInstClassIn
  record FUNC_partialInstClassIn
    tuple<Env.Cache, Env, InstanceHierarchy, Mod, Prefix, 
          Connect.Sets, ClassInf.State, SCode.Class, Boolean, 
          InstDims> inputs;
    tuple<Env.Cache, Env, InstanceHierarchy, ClassInf.State> outputs;
  end FUNC_partialInstClassIn;
  
end CachedInstItem;

public
type CachedInstItems = list<Option<CachedInstItem>>;
constant Option<InstHashTable> instHashTable = NONE();

public
type Key = Absyn.Path "the env path + '.' + the class name";
type Value = CachedInstItems "the inputs of the instantiation function and the results";

public function hashFunc 
"author: PA
  Calculates a hash value for Absyn.Path"
  input Absyn.Path p;
  output Integer res;
algorithm 
  res := System.hash(Absyn.pathString(p));
end hashFunc;

public function keyEqual
  input Key key1;
  input Key key2;
  output Boolean res;
algorithm
     res := stringEqual(Absyn.pathString(key1),Absyn.pathString(key2));
end keyEqual;

public function dumpInstHashTable ""
  input InstHashTable t;
algorithm
  print("InstHashTable:\n");
  print(Util.stringDelimitList(Util.listMap(hashTableList(t),dumpTuple),"\n"));
  print("\n");
end dumpInstHashTable;

public function dumpTuple
  input tuple<Key,Value> tpl;
  output String str;
algorithm
  str := matchcontinue(tpl)
    local 
      Absyn.Path p; // CachedInstItems i;
    case((p,_)) equation
      str = "{" +& Absyn.pathString(p) +& ", OPAQUE_VALUE}";
    then str;
  end matchcontinue;
end dumpTuple;

/* end of InstHashTable instance specific code */

/* Generic hashtable code below!! */
public  
uniontype InstHashTable
  record HASHTABLE
    list<tuple<Key,Integer>>[:] hashTable " hashtable to translate Key to array indx" ;
    ValueArray valueArr "Array of values" ;
    Integer bucketSize "bucket size" ;
    Integer numberOfEntries "number of entries in hashtable" ;   
  end HASHTABLE;
end InstHashTable; 

uniontype ValueArray 
"array of values are expandable, to amortize the 
 cost of adding elements in a more efficient manner"
  record VALUE_ARRAY
    Integer numberOfElements "number of elements in hashtable" ;
    Integer arrSize "size of crefArray" ;
    Option<tuple<Key,Value>>[:] valueArray "array of values";
  end VALUE_ARRAY;
end ValueArray;

public function cloneInstHashTable 
"Author BZ 2008-06
 Make a stand-alone-copy of hashtable."
input InstHashTable inHash;
output InstHashTable outHash;
algorithm outHash := matchcontinue(inHash)
  local 
    list<tuple<Key,Integer>>[:] arg1,arg1_2;
    Integer arg3,arg4,arg3_2,arg4_2,arg21,arg21_2,arg22,arg22_2;
    Option<tuple<Key,Value>>[:] arg23,arg23_2;
  case(HASHTABLE(arg1,VALUE_ARRAY(arg21,arg22,arg23),arg3,arg4))
    equation
      arg1_2 = arrayCopy(arg1);
      arg21_2 = arg21;
      arg22_2 = arg22;
      arg23_2 = arrayCopy(arg23);
      arg3_2 = arg3;
      arg4_2 = arg4;
      then
        HASHTABLE(arg1_2,VALUE_ARRAY(arg21_2,arg22_2,arg23_2),arg3_2,arg4_2);
end matchcontinue;
end cloneInstHashTable;

public function emptyInstHashTable 
"author: PA
  Returns an empty InstHashTable.
  Using the bucketsize 100 and array size 10."
  output InstHashTable hashTable;
  list<tuple<Key,Integer>>[:] arr;
  list<Option<tuple<Key,Value>>> lst;
  Option<tuple<Key,Value>>[:] emptyarr;
algorithm 
  arr := fill({}, 1000);
  emptyarr := fill(NONE(), 100);
  hashTable := HASHTABLE(arr,VALUE_ARRAY(0,100,emptyarr),1000,0);
end emptyInstHashTable;

public function isEmpty "Returns true if hashtable is empty"
  input InstHashTable hashTable;
  output Boolean res;
algorithm
  res := matchcontinue(hashTable)
    case(HASHTABLE(_,_,_,0)) then true;
    case(_) then false;  
  end matchcontinue;
end isEmpty;

public function add 
"author: PA
  Add a Key-Value tuple to hashtable.
  If the Key-Value tuple already exists, the function updates the Value."
  input tuple<Key,Value> entry;
  input InstHashTable hashTable;
  output InstHashTable outHahsTable;
algorithm 
  outVariables:=
  matchcontinue (entry,hashTable)
    local     
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      list<tuple<Key,Integer>>[:] hashvec_1,hashvec;
      String name_str;      
      tuple<Key,Value> v,newv;
      Key key;
      Value value;
      /* Adding when not existing previously */
    case ((v as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation 
        failure((_) = get(key, hashTable));
        hval = hashFunc(key);
        indx = intMod(hval, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);        
      then HASHTABLE(hashvec_1,varr_1,bsize,n_1);
      
      /* adding when already present => Updating value */
    case ((newv as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation 
        (_,indx) = get1(key, hashTable);
        //print("adding when present, indx =" );print(intString(indx));print("\n");
        indx_1 = indx - 1;
        varr_1 = valueArraySetnth(varr, indx, newv);
      then HASHTABLE(hashvec,varr_1,bsize,n);
    case (_,_)
      equation 
        print("-InstHashTable.add failed\n");
      then
        fail();
  end matchcontinue;
end add;

public function addNoUpdCheck 
"author: PA
  Add a Key-Value tuple to hashtable.
  If the Key-Value tuple already exists, the function updates the Value."
  input tuple<Key,Value> entry;
  input InstHashTable hashTable;
  output InstHashTable outHahsTable;
algorithm 
  outVariables := matchcontinue (entry,hashTable)
    local     
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      list<tuple<Key,Integer>>[:] hashvec_1,hashvec;
      String name_str;      
      tuple<Key,Value> v,newv;
      Key key;
      Value value;
    // Adding when not existing previously
    case ((v as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation 
        hval = hashFunc(key);
        indx = intMod(hval, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);        
      then HASHTABLE(hashvec_1,varr_1,bsize,n_1);
    case (_,_)
      equation 
        print("-InstHashTable.addNoUpdCheck failed\n");
      then
        fail();
  end matchcontinue;
end addNoUpdCheck;

public function delete 
"author: PA
  delete the Value associatied with Key from the InstHashTable.
  Note: This function does not delete from the index table, only from the ValueArray.
  This means that a lot of deletions will not make the InstHashTable more compact, it 
  will still contain a lot of incices information."
  input Key key;
  input InstHashTable hashTable;
  output InstHashTable outHahsTable;
algorithm 
  outVariables := matchcontinue (key,hashTable)
    local     
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      list<tuple<Key,Integer>>[:] hashvec_1,hashvec;
      String name_str;      
      tuple<Key,Value> v,newv;
      Key key;
      Value value;     
    // adding when already present => Updating value
    case (key,(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation 
        (_,indx) = get1(key, hashTable);
        indx_1 = indx - 1;
        varr_1 = valueArrayClearnth(varr, indx);
      then HASHTABLE(hashvec,varr_1,bsize,n);
    case (_,hashTable)
      equation 
        print("-InstHashTable.delete failed\n");
        print("content:"); dumpInstHashTable(hashTable);
      then
        fail();
  end matchcontinue;
end delete;

public function get 
"author: PA 
  Returns a Value given a Key and a InstHashTable."
  input Key key;
  input InstHashTable hashTable;
  output Value value;
algorithm 
  (value,_):= get1(key,hashTable);
end get;

public function get1 "help function to get"
  input Key key;
  input InstHashTable hashTable;
  output Value value;
  output Integer indx;
algorithm 
  (value,indx):= matchcontinue (key,hashTable)
    local
      Integer hval,hashindx,indx,indx_1,bsize,n;
      list<tuple<Key,Integer>> indexes;
      Value v;      
      list<tuple<Key,Integer>>[:] hashvec;     
      ValueArray varr;
      Key key2;
    case (key,(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation 
        hval = hashFunc(key);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = get2(key, indexes);
        v = valueArrayNth(varr, indx);
      then
        (v,indx);
  end matchcontinue;
end get1;

public function get2 
"author: PA 
  Helper function to get"
  input Key key;
  input list<tuple<Key,Integer>> keyIndices;
  output Integer index;
algorithm 
  index := matchcontinue (key,keyIndices)
    local
      Key key2;
      Value res;
      list<tuple<Key,Integer>> xs;
    case (key,((key2,index) :: _))
      equation 
        true = keyEqual(key, key2);
      then
        index;
    case (key,(_ :: xs))      
      equation 
        index = get2(key, xs);
      then
        index;
  end matchcontinue;
end get2;

public function hashTableValueList "return the Value entries as a list of Values"
  input InstHashTable hashTable;
  output list<Value> valLst;
algorithm
   valLst := Util.listMap(hashTableList(hashTable),Util.tuple22);
end hashTableValueList;

public function hashTableKeyList "return the Key entries as a list of Keys"
  input InstHashTable hashTable;
  output list<Key> valLst;
algorithm
   valLst := Util.listMap(hashTableList(hashTable),Util.tuple21);
end hashTableKeyList;

public function hashTableList "returns the entries in the hashTable as a list of tuple<Key,Value>"
  input InstHashTable hashTable;
  output list<tuple<Key,Value>> tplLst;
algorithm
  tplLst := matchcontinue(hashTable)
  local ValueArray varr;
    case(HASHTABLE(valueArr = varr)) equation
      tplLst = valueArrayList(varr);
    then tplLst; 
  end matchcontinue;
end hashTableList;

public function valueArrayList 
"author: PA
  Transforms a ValueArray to a tuple<Key,Value> list"
  input ValueArray valueArray;
  output list<tuple<Key,Value>> tplLst;
algorithm 
  tplLst := matchcontinue (valueArray)
    local
      Option<tuple<Key,Value>>[:] arr;
      tuple<Key,Value> elt;
      Integer lastpos,n,size;
      list<tuple<Key,Value>> lst;
    case (VALUE_ARRAY(numberOfElements = 0,valueArray = arr)) then {}; 
    case (VALUE_ARRAY(numberOfElements = 1,valueArray = arr))
      equation 
        SOME(elt) = arr[0 + 1];
      then
        {elt};
    case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr))
      equation 
        lastpos = n - 1;
        lst = valueArrayList2(arr, 0, lastpos);
      then
        lst;
  end matchcontinue;
end valueArrayList;

public function valueArrayList2 "Helper function to valueArrayList"
  input Option<tuple<Key,Value>>[:] inVarOptionArray1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<tuple<Key,Value>> outVarLst;
algorithm 
  outVarLst := matchcontinue (inVarOptionArray1,inInteger2,inInteger3)
    local
      tuple<Key,Value> v;
      Option<tuple<Key,Value>>[:] arr;
      Integer pos,lastpos,pos_1;
      list<tuple<Key,Value>> res;
    case (arr,pos,lastpos)
      equation 
        (pos == lastpos) = true;
        SOME(v) = arr[pos + 1];
      then
        {v};
    case (arr,pos,lastpos)
      equation 
        pos_1 = pos + 1;
        SOME(v) = arr[pos + 1];
        res = valueArrayList2(arr, pos_1, lastpos);
      then
        (v :: res);
    case (arr,pos,lastpos)
      equation 
        pos_1 = pos + 1;
        NONE = arr[pos + 1];
        res = valueArrayList2(arr, pos_1, lastpos);
      then
        (res);
  end matchcontinue;
end valueArrayList2;

public function valueArrayLength 
"author: PA
  Returns the number of elements in the ValueArray"
  input ValueArray valueArray;
  output Integer size;
algorithm 
  size := matchcontinue (valueArray)
    case (VALUE_ARRAY(numberOfElements = size)) then size; 
  end matchcontinue;
end valueArrayLength;

public function valueArrayAdd 
"function: valueArrayAdd
  author: PA 
  Adds an entry last to the ValueArray, increasing 
  array size if no space left by factor 1.4"
  input ValueArray valueArray;
  input tuple<Key,Value> entry;
  output ValueArray outValueArray;
algorithm 
  outValueArray := matchcontinue (valueArray,entry)
    local
      Integer n_1,n,size,expandsize,expandsize_1,newsize;
      Option<tuple<Key,Value>>[:] arr_1,arr,arr_2;
      Real rsize,rexpandsize;
    case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr),entry)
      equation 
        (n < size) = true "Have space to add array elt." ;
        n_1 = n + 1;
        arr_1 = arrayUpdate(arr, n + 1, SOME(entry));
      then
        VALUE_ARRAY(n_1,size,arr_1);
        
    case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr),entry)
      equation 
        (n < size) = false "Do NOT have splace to add array elt. Expand with factor 1.4" ;
        rsize = intReal(size);
        rexpandsize = rsize*.0.4;
        expandsize = realInt(rexpandsize);
        expandsize_1 = intMax(expandsize, 1);
        newsize = expandsize_1 + size;
        arr_1 = Util.arrayExpand(expandsize_1, arr, NONE);
        n_1 = n + 1;
        arr_2 = arrayUpdate(arr_1, n + 1, SOME(entry));
      then
        VALUE_ARRAY(n_1,newsize,arr_2);
    case (_,_)
      equation 
        print("-InstHashTable.valueArrayAdd failed\n");
      then
        fail();
  end matchcontinue;
end valueArrayAdd;

public function valueArraySetnth 
"function: valueArraySetnth
  author: PA 
  Set the n:th variable in the ValueArray to value."
  input ValueArray valueArray;
  input Integer pos;
  input tuple<Key,Value> entry;
  output ValueArray outValueArray;
algorithm 
  outValueArray := matchcontinue (valueArray,pos,entry)
    local
      Option<tuple<Key,Value>>[:] arr_1,arr;
      Integer n,size,pos;      
    case (VALUE_ARRAY(n,size,arr),pos,entry)
      equation 
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1, SOME(entry));
      then
        VALUE_ARRAY(n,size,arr_1);
    case (_,_,_)
      equation 
        print("-InstHashTable.valueArraySetnth failed\n");
      then
        fail();
  end matchcontinue;
end valueArraySetnth;

public function valueArrayClearnth 
"author: PA
  Clears the n:th variable in the ValueArray (set to NONE)."
  input ValueArray valueArray;
  input Integer pos;
  output ValueArray outValueArray;
algorithm 
  outValueArray := matchcontinue (valueArray,pos)
    local
      Option<tuple<Key,Value>>[:] arr_1,arr;
      Integer n,size,pos;      
    case (VALUE_ARRAY(n,size,arr),pos)
      equation 
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1, NONE);
      then
        VALUE_ARRAY(n,size,arr_1);
    case (_,_)
      equation 
        print("-InstHashTable.valueArrayClearnth failed\n");
      then
        fail();
  end matchcontinue;
end valueArrayClearnth;

public function valueArrayNth 
"function: valueArrayNth
  author: PA 
  Retrieve the n:th Vale from ValueArray, index from 0..n-1."
  input ValueArray valueArray;
  input Integer pos;
  output Value value;
algorithm 
  value := matchcontinue (valueArray,pos)
    local
      Value v;
      Integer n,pos,len;
      Option<tuple<Key,Value>>[:] arr;
      String ps,lens,ns;
    case (VALUE_ARRAY(numberOfElements = n,valueArray = arr),pos)
      equation 
        (pos < n) = true;
        SOME((_,v)) = arr[pos + 1];
      then
        v;
    case (VALUE_ARRAY(numberOfElements = n,valueArray = arr),pos)
      equation 
        (pos < n) = true;
        NONE = arr[pos + 1];
      then
        fail();
  end matchcontinue;
end valueArrayNth;

/*protected function checkModelBalancing
"@author adrpo
 this function checks the balancing of the given model"
  input Option<Absyn.Path> classNameOpt;
  input DAE.DAElist inDae; 
algorithm
  _ := matchcontinue(classNameOpt, inDae)
    local
      DAE.DAElist dae;
      Integer eqnSize,varSize,simpleEqnSize;
      String warnings,eqnSizeStr,varSizeStr,retStr,classNameStr,simpleEqnSizeStr;
      DAELow.EquationArray eqns;
      Integer elimLevel; 
      DAELow.DAELow dlow,dlow_1,indexed_dlow,indexed_dlow_1;
    // check the balancing of the instantiated model
    // special case for no elements!
    case (classNameOpt, DAE.DAE({},_))
      equation
        //classNameStr = Absyn.optPathString(classNameOpt);
        //warnings = Error.printMessagesStr();
        //retStr= Util.stringAppendList({"# CHECK: ", classNameStr, " inst has 0 equation(s) and 0 variable(s)", warnings, "."});
        // do not show empty elements with 0 vars and 0 equs
        // Debug.fprintln("checkModel", retStr);
    then ();      
    // check the balancing of the instantiated model
    case (classNameOpt, dae)
      equation
        dae = DAEUtil.transformIfEqToExpr(dae,false);
        elimLevel = RTOpts.eliminationLevel();
        RTOpts.setEliminationLevel(0); // No variable elimination
        (dlow as DAELow.DAELOW(orderedVars = DAELow.VARIABLES(numberOfVars = varSize),orderedEqs = eqns)) 
        = DAELow.lower(dae, false, true);
        // Debug.fcall("dumpdaelow", DAELow.dump, dlow);
        RTOpts.setEliminationLevel(elimLevel); // reset elimination level.
        eqnSize = DAELow.equationSize(eqns);
        (eqnSize,varSize) = CevalScript.subtractDummy(DAELow.daeVars(dlow),eqnSize,varSize);
        simpleEqnSize = DAELow.countSimpleEquations(eqns);
        eqnSizeStr = intString(eqnSize);
        varSizeStr = intString(varSize);
        simpleEqnSizeStr = intString(simpleEqnSize);
        classNameStr = Absyn.optPathString(classNameOpt);
        warnings = Error.printMessagesStr();
        retStr= Util.stringAppendList({"# CHECK: ", classNameStr, " inst has ", eqnSizeStr, 
                                       " equation(s) and ", varSizeStr," variable(s). ",
                                       simpleEqnSizeStr, " of these are trivial equation(s).", 
                                       warnings});
        Debug.fprintln("checkModel", retStr);
    then ();
    // we might fail, show a message
    case (classNameOpt, inDAEElements)
      equation
        classNameStr = Absyn.optPathString(classNameOpt);
        Debug.fprintln("checkModel", "# CHECK: " +& classNameStr +& " inst failed!");
      then ();      
  end matchcontinue;
end checkModelBalancing;
*/


/*protected function checkModelBalancingFilterByRestriction
"@author: adrpo 
 filter out some restricted classes"
  input SCode.Restriction r;
  input Option<Absyn.Path> pathOpt;
  input list<DAE.Element> dae;
algorithm
  _ := matchcontinue(r, pathOpt, dae)
    // no checking for these!
    case (SCode.R_FUNCTION(), _, _) then ();
    case (SCode.R_EXT_FUNCTION(), _, _) then ();
    case (SCode.R_TYPE(), _, _) then ();
    case (SCode.R_RECORD(), _, _) then ();
    case (SCode.R_PACKAGE(), _, _) then ();
    case (SCode.R_ENUMERATION(), _, _) then ();
    case (SCode.R_PREDEFINED_BOOL(), _, _) then ();
    case (SCode.R_PREDEFINED_INT(), _, _) then ();
    case (SCode.R_PREDEFINED_REAL(), _, _) then ();
    case (SCode.R_PREDEFINED_STRING(), _, _) then ();
    // check anything else
    case (_, pathOpt, dae)
      equation
        true = RTOpts.debugFlag("checkModel");
        checkModelBalancing(pathOpt, dae);
      then ();
    // do nothing if the debug flag checkModel is not set
    case (_, pathOpt, dae) then (); 
  end matchcontinue;
end checkModelBalancingFilterByRestriction;
*/
end Inst;
