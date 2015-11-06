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

encapsulated package Inst
" file:        Inst.mo
  package:     Inst
  description: Model instantiation

  RCS: $Id$

  This module is responsible for instantiation of Modelica models.
  The instantation is the process of instantiating model components,
  flattening inheritance and generating equations from connect statements.
  The instantiation process takes Modelica AST as defined in SCode and
  produces variables and equations and algorithms, etc. as defined in DAE.

  This module uses Lookup to lookup classes and variables from the
  environment defined in Env. It uses Connect for generating equations from
  connect statements. The type system defined in Types is used for
  variable instantiation and type. DAE.Mod is used for modifiers and
  merging of modifiers.

  The extends language feature is performed by InstExtends. Instantiation of
  algorithm sections and equation sections (including connections) is done
  by InstSection.

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

  4. ???"

// public imports
public import Absyn;
public import ClassInf;
public import Connect;
public import ConnectionGraph;
public import DAE;
public import FCore;
public import InnerOuter;
public import InstTypes;
public import Mod;
public import Prefix;
public import SCode;
public import UnitAbsyn;

// **
// These type aliases are introduced to make the code a little more readable.
// **

protected type Ident = DAE.Ident "an identifier";

protected type InstanceHierarchy = InnerOuter.InstHierarchy "an instance hierarchy";

protected type InstDims = list<list<DAE.Dimension>>
"Changed from list<Subscript> to list<list<Subscript>>. One list for each scope.
 This so when instantiating classes extending from primitive types can collect the dimension of -one- surrounding scope to create type.
 E.g. RealInput p[3]; gives the list {3} for this scope and other lists for outer (in instance hierachy) scopes";

protected partial function BasicTypeAttrTyper
  input String inAttrName;
  input DAE.Type inClassType;
  input SourceInfo inInfo;
  output DAE.Type outType;
end BasicTypeAttrTyper;

// protected imports
protected import BaseHashTable;
protected import Builtin;
protected import Ceval;
protected import ConnectUtil;
protected import ComponentReference;
protected import Config;
protected import DAEUtil;
protected import Debug;
protected import Dump;
protected import Error;
protected import ErrorExt;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import FGraph;
protected import FGraphBuildEnv;
protected import FNode;
protected import Global;
protected import HashTable;
protected import HashTable5;
protected import InstSection;
protected import InstBinding;
protected import InstVar;
protected import InstFunction;
protected import InstUtil;
protected import InstExtends;
protected import List;
protected import Lookup;
protected import MetaUtil;
protected import PrefixUtil;
protected import SCodeUtil;
protected import Static;
protected import Types;
protected import UnitParserExt;
protected import Util;
protected import Values;
protected import ValuesUtil;
protected import System;
protected import SCodeDump;
protected import UnitAbsynBuilder;
protected import NFSCodeFlattenRedeclare;
protected import InstStateMachineUtil;
protected import HashTableSM1;

protected import DAEDump; // BTH

protected function instantiateClass_dispatch
" instantiate a class.
 if this function fails with stack overflow, it will be caught in the caller"
  input FCore.Cache inCache;
  input InnerOuter.InstHierarchy inIH;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output DAE.DAElist outDAElist;
algorithm
  (outCache,outEnv,outIH,outDAElist) := match (inCache,inIH,inProgram,inPath)
    local
      Absyn.Path path;
      FCore.Graph env,env_1,env_2;
      DAE.DAElist dae1,dae,dae2;
      list<SCode.Element> cdecls;
      String name2,n,pathstr,name;
      SCode.Element cdef;
      FCore.Cache cache;
      InstanceHierarchy ih;
      ConnectionGraph.ConnectionGraph graph;
      DAE.ElementSource source "the origin of the element";
      list<DAE.Element> daeElts;
      Option<SCode.Comment> cmt;

     // top level class
    case (cache,ih,(cdecls as (_ :: _)),(path as Absyn.IDENT()))
      equation
        cache = FCore.setCacheClassName(cache,path);
        cdecls = InstUtil.scodeFlatten(cdecls, inPath);
        (cache,env) = Builtin.initialGraph(cache);
        env_1 = FGraphBuildEnv.mkProgramGraph(cdecls, FCore.USERDEFINED(), env);

        // set the source of this element
        source = DAEUtil.addElementSourcePartOfOpt(DAE.emptyElementSource, FGraph.getScopePath(env));
        (cache,env_2,ih,dae2) = instClassInProgram(cache, env_1, ih, cdecls, path, source);
        // check the models for balancing
        //Debug.fcall2(Flags.CHECK_MODEL_BALANCE, checkModelBalancing, SOME(path), dae1);
        //Debug.fcall2(Flags.CHECK_MODEL_BALANCE, checkModelBalancing, SOME(path), dae2);

        // let the GC collect these as they are used only by Inst!
        setGlobalRoot(Global.instHashIndex, emptyInstHashTable());
      then
        (cache,env_2,ih,dae2);

    // class in package
    case (cache,ih,(cdecls as (_ :: _)),(path as Absyn.QUALIFIED()))
      equation
        cache = FCore.setCacheClassName(cache,path);
        cdecls = InstUtil.scodeFlatten(cdecls, inPath);
        pathstr = Absyn.pathString(path);

        //System.startTimer();
        //print("\nBuiltinMaking");
        (cache,env) = Builtin.initialGraph(cache);
        //System.stopTimer();
        //print("\nBuiltinMaking: " + realString(System.getTimerIntervalTime()));

        //System.startTimer();
        //print("\nInstClassDecls");
        env_1 = FGraphBuildEnv.mkProgramGraph(cdecls, FCore.USERDEFINED(), env);
        //System.stopTimer();
        //print("\nInstClassDecls: " + realString(System.getTimerIntervalTime()));

        //System.startTimer();
        //print("\nLookupClass");
        (cache,(cdef as SCode.CLASS(name = n)),env_2) = Lookup.lookupClass(cache, env_1, path, true);

        //System.stopTimer();
        //print("\nLookupClass: " + realString(System.getTimerIntervalTime()));

        //System.startTimer();
        //print("\nInstClass");
        (cache,env_2,ih,_,dae,_,_,_,_,_) = instClass(cache,env_2,ih,
          UnitAbsynBuilder.emptyInstStore(),DAE.NOMOD(), makeTopComponentPrefix(env_2, n), cdef,
          {}, false, InstTypes.TOP_CALL(), ConnectionGraph.EMPTY, Connect.emptySet) "impl";
        //System.stopTimer();
        //print("\nInstClass: " + realString(System.getTimerIntervalTime()));

        //System.startTimer();
        //print("\nReEvaluateIf");
        //print(" ********************** backpatch 1 **********************\n");
        dae = InstUtil.reEvaluateInitialIfEqns(cache,env_2,dae,true);
        //System.stopTimer();
        //print("\nReEvaluateIf: " + realString(System.getTimerIntervalTime()));

        // check the model for balancing
        // Debug.fcall2(Flags.CHECK_MODEL_BALANCE, checkModelBalancing, SOME(path), dae);

        //System.startTimer();
        //print("\nSetSource+DAE");
        // set the source of this element
        source = DAEUtil.addElementSourcePartOfOpt(DAE.emptyElementSource, FGraph.getScopePath(env));
        daeElts = DAEUtil.daeElements(dae);
        cmt = SCode.getElementComment(cdef);
        dae = DAE.DAE({DAE.COMP(pathstr,daeElts,source,cmt)});
        //System.stopTimer();
        //print("\nSetSource+DAE: " + realString(System.getTimerIntervalTime()));

        // let the GC collect these as they are used only by Inst!
        setGlobalRoot(Global.instHashIndex, emptyInstHashTable());
      then
        (cache, env_2, ih, dae);

  end match;
end instantiateClass_dispatch;

public function instantiateClass
"To enable interactive instantiation, an arbitrary class in the program
  needs to be possible to instantiate. This function performs the same
  action as instProgram, but given a specific class to instantiate.

   First, all the class definitions are added to the environment without
  modifications, and then the specified class is instantiated in the
  function instClassInProgram"
  input FCore.Cache inCache;
  input InnerOuter.InstHierarchy inIH;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output DAE.DAElist outDAElist;
algorithm
  (outCache,outEnv,outIH,outDAElist) := matchcontinue (inCache,inIH,inProgram,inPath)
    local
      Absyn.Path cr,path;
      list<SCode.Element> cdecls;
      String cname_str;
      FCore.Cache cache;
      InstanceHierarchy ih;
      Boolean stackOverflow;

    case (_,_,{},_)
      equation
        Error.addMessage(Error.NO_CLASSES_LOADED, {});
      then
        fail();

    // instantiate a class
    case (cache,ih,cdecls as _::_,path)
      equation
        (outCache,outEnv,outIH,outDAElist) = instantiateClass_dispatch(cache,ih,cdecls,path);
      then
        (outCache,outEnv,outIH,outDAElist);

    // error instantiating
    case (_,_,_::_,path)
      equation
        // if we got a stack overflow remove the stack-overflow flag
        // adrpo: NOTE THAT THE NEXT FUNCTION CALL MUST BE THE FIRST IN THIS CASE, otherwise the stack overflow will not be caught!
        stackOverflow = setStackOverflowSignal(false);

        cname_str = Absyn.pathString(path) + (if stackOverflow then ". The compiler got into Stack Overflow!" else "");
        Error.addMessage(Error.ERROR_FLATTENING, {cname_str});

        // let the GC collect these as they are used only by Inst!
        setGlobalRoot(Global.instHashIndex, emptyInstHashTable());
      then
        fail();
  end matchcontinue;
end instantiateClass;

public function instantiatePartialClass
"Author: BZ, 2009-07
 This is a function for instantiating partial 'top' classes.
 It does so by converting the partial class into a non partial class.
 Currently used by: MathCore.modelEquations, CevalScript.checkModel"
  input FCore.Cache inCache;
  input InnerOuter.InstHierarchy inIH;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output DAE.DAElist outDAElist;
algorithm
  (outCache,outEnv,outIH,outDAElist) := matchcontinue (inCache,inIH,inProgram,inPath)
    local
      Absyn.Path cr,path;
      FCore.Graph env,env_1,env_2;
      DAE.DAElist dae1,dae;
      list<SCode.Element> cdecls;
      String name2,n,pathstr,name,cname_str;
      SCode.Element cdef;
      FCore.Cache cache;
      InstanceHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      list<DAE.Element> daeElts;
      DAE.FunctionTree funcs;
      Option<SCode.Comment> cmt;

    case (_,_,{},_)
      equation
        Error.addMessage(Error.NO_CLASSES_LOADED, {});
      then
        fail();

    case (cache,ih,(cdecls as (_ :: _)),(path as Absyn.IDENT())) /* top level class */
      equation
        (cache,env) = Builtin.initialGraph(cache);
        env_1 = FGraphBuildEnv.mkProgramGraph(cdecls, FCore.USERDEFINED(), env);
        cdecls = List.map1(cdecls,SCode.classSetPartial,SCode.NOT_PARTIAL());
        source = DAEUtil.addElementSourcePartOfOpt(DAE.emptyElementSource, FGraph.getScopePath(env));
        (cache,env_2,ih,dae) = instClassInProgram(cache, env_1, ih, cdecls, path, source);
      then
        (cache,env_2,ih,dae);

    case (cache,ih,(cdecls as (_ :: _)),(path as Absyn.QUALIFIED())) /* class in package */
      equation
        (cache,env) = Builtin.initialGraph(cache);
        env_1 = FGraphBuildEnv.mkProgramGraph(cdecls, FCore.USERDEFINED(), env);
        (cache,(cdef as SCode.CLASS(name = n)),env_2) = Lookup.lookupClass(cache,env_1, path, true);

        cdef = SCode.classSetPartial(cdef, SCode.NOT_PARTIAL());

        (cache,env_2,ih,_,dae,_,_,_,_,_) =
          instClass(cache, env_2, ih, UnitAbsynBuilder.emptyInstStore(),DAE.NOMOD(), makeTopComponentPrefix(env_2, n),
            cdef, {}, false, InstTypes.TOP_CALL(), ConnectionGraph.EMPTY, Connect.emptySet) "impl" ;
        pathstr = Absyn.pathString(path);

        // set the source of this element
        source = DAEUtil.addElementSourcePartOfOpt(DAE.emptyElementSource, FGraph.getScopePath(env));
        daeElts = DAEUtil.daeElements(dae);
        cmt = SCode.getElementComment(cdef);
        dae = DAE.DAE({DAE.COMP(pathstr,daeElts,source,cmt)});
      then
        (cache,env_2,ih,dae);

    case (_,_,_,path) /* error instantiating */
      equation
        cname_str = Absyn.pathString(path);
        //print(" Error flattening partial, errors: " + ErrorExt.printMessagesStr() + "\n");
        Error.addMessage(Error.ERROR_FLATTENING, {cname_str});
      then
        fail();
  end matchcontinue;
end instantiatePartialClass;

protected function makeTopComponentPrefix
  input FGraph.Graph inGraph;
  input Absyn.Ident inName;
  output Prefix.Prefix outPrefix;
protected
  Absyn.Path p;
algorithm
  //p := FGraph.joinScopePath(inGraph, Absyn.IDENT(inName));
  //outPrefix := Prefix.PREFIX(Prefix.PRE("$i", {}, {}, Prefix.NOCOMPPRE(), ClassInf.MODEL(p)), Prefix.CLASSPRE(SCode.VAR()));
  outPrefix := Prefix.NOPRE();
end makeTopComponentPrefix;

protected function instClassInProgram
  "Instantiates a specific top level class in a Program."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  input DAE.ElementSource inSource;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output DAE.DAElist outDae;
algorithm
  (outCache, outEnv, outIH, outDae) :=
  matchcontinue(inCache, inEnv, inIH, inProgram, inPath, inSource)
    local
      String name;
      SCode.Element cls;
      FCore.Cache cache;
      FCore.Graph env;
      InstanceHierarchy ih;
      DAE.DAElist dae;
      list<DAE.Element> elts;
      Option<SCode.Comment> cmt;

    case (_, _, _, {}, _, _)
      then (inCache, inEnv, inIH, DAE.emptyDae);

    case (_, _, _, _, Absyn.IDENT(name = ""), _)
      then (inCache, inEnv, inIH, DAE.emptyDae);

    case (_, _, _, _, Absyn.IDENT(name = name), _)
      equation
        cls = InstUtil.lookupTopLevelClass(name, inProgram, true);

        (cache, env, ih, _, dae, _, _, _, _, _) = instClass(inCache, inEnv,
          inIH, UnitAbsynBuilder.emptyInstStore(), DAE.NOMOD(), makeTopComponentPrefix(inEnv, name),
          cls, {}, false, InstTypes.TOP_CALL(), ConnectionGraph.EMPTY, Connect.emptySet);
        dae = InstUtil.reEvaluateInitialIfEqns(cache, env, dae, true);
        elts = DAEUtil.daeElements(dae);

        cmt = SCode.getElementComment(cls);
        dae = DAE.DAE({DAE.COMP(name, elts, inSource, cmt)});
      then
        (cache, env, ih, dae);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("Inst.instClassInProgram failed\n");
      then
        fail();

  end matchcontinue;
end instClassInProgram;

public function instClass
"Instantiation of a class can be either implicit or normal.
  This function is used in both cases. When implicit instantiation
  is performed, the last argument is true, otherwise it is false.

  Instantiating a class consists of the following steps:
   o Create a new frame on the environment
   o Initialize the class inference state machine
   o Instantiate all the elements and equations
   o Generate equations from the connection sets built during instantiation"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input SCode.Element inClass;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean inBoolean;
  input InstTypes.CallingScope inCallingScope;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  output FCore.Cache cache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output DAE.Type outType;
  output ClassInf.State outState;
  output Option<SCode.Attributes> optDerAttr;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (cache,outEnv,outIH,outStore,outDae,outSets,outType,outState,optDerAttr,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inStore,inMod,inPrefix,inClass,inInstDims,inBoolean,inCallingScope,inGraph,inSets)
    local
      FCore.Graph env,env_1,env_3;
      DAE.Mod mod;
      Prefix.Prefix pre;
      Connect.Sets csets;
      String n,scopeName,strDepth;
      Boolean impl,callscope_1,isFn,notIsPartial,isPartialFn,recursionDepthReached;
      SCode.Partial partialPrefix;
      SCode.Encapsulated encflag;
      ClassInf.State ci_state,ci_state_1;
      DAE.DAElist dae1,dae1_1,dae;
      list<DAE.Var> tys;
      Option<DAE.Type> bc_ty;
      Absyn.Path fq_class;
      DAE.Type ty;
      SCode.Element c;
      SCode.Restriction r;
      InstDims inst_dims;
      InstTypes.CallingScope callscope;
      Option<SCode.Attributes> oDA;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      DAE.EqualityConstraint equalityConstraint;
      SourceInfo info;
      UnitAbsyn.InstStore store;

    // adrpo: ONLY when running checkModel we should be able to instantiate partial classes
    case (cache,_,_,store,_,_,
          SCode.CLASS(name=n, partialPrefix = SCode.PARTIAL(), restriction = r, info = info),
          _,_,_,_,_)
      equation
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        false = SCode.isFunctionRestriction(r); // Partial functions are handled below (used for partially evaluated functions; do not want the checkModel warning)
        c = SCode.setClassPartialPrefix(SCode.NOT_PARTIAL(), inClass);
        // add a warning
        Error.addSourceMessage(Error.INST_PARTIAL_CLASS_CHECK_MODEL_WARNING, {n}, info);
        // call normal instantiation
        (cache,env,ih,store,dae,csets,ty,ci_state_1,oDA,graph) =
           instClass(inCache, inEnv, inIH, store, inMod, inPrefix, c, inInstDims, inBoolean, inCallingScope, inGraph, inSets);
      then
        (cache,env,ih,store,dae,csets,ty,ci_state_1,oDA,graph);

    // Instantiation of a class. Create new scope and call instClassIn.
    //  Then generate equations from connects.
    case (cache,env,ih,store,mod,pre,
          (c as SCode.CLASS(name = n,encapsulatedPrefix = encflag,restriction = r, partialPrefix = partialPrefix, info = info)),
          inst_dims,impl,callscope,graph,_)
      equation
        recursionDepthReached = listLength(FGraph.currentScope(env)) < Global.recursionDepthLimit;
        if not recursionDepthReached then
          scopeName = FGraph.printGraphPathStr(env);
          strDepth = intString(Global.recursionDepthLimit);
          Error.addSourceMessage(Error.RECURSION_DEPTH_REACHED,{strDepth, scopeName},info);
          fail();
        end if;
        //print("---- CLASS: "); print(n);print(" ----\n"); print(SCodeDump.printClassStr(c)); //Print out the input SCode class
        //str = SCodeDump.printClassStr(c); print("------------------- CLASS instClass-----------------\n");print(str);print("\n===============================================\n");

        // First check if the class is non-partial or a partial function
        isFn = SCode.isFunctionRestriction(r);
        notIsPartial = not SCode.partialBool(partialPrefix);
        isPartialFn = isFn and SCode.partialBool(partialPrefix);
        true = notIsPartial or isPartialFn;

        env_1 = FGraph.openScope(env, encflag, SOME(n), FGraph.restrictionToScopeType(r));

        ci_state = ClassInf.start(r,FGraph.getGraphName(env_1));
        csets = ConnectUtil.newSet(pre, inSets);

        (cache,env_3,ih,store,dae1,csets,ci_state_1,tys,bc_ty,oDA,equalityConstraint, graph)
          = instClassIn(cache, env_1, ih, store, mod, pre, ci_state, c, SCode.PUBLIC(), inst_dims, impl, callscope, graph, csets, NONE());
        csets = ConnectUtil.addSet(inSets, csets);
        (cache,fq_class) = makeFullyQualified(cache, env, Absyn.IDENT(n));

        // is top level?
        callscope_1 = InstUtil.isTopCall(callscope);

        dae1_1 = DAEUtil.addComponentType(dae1, fq_class);

        InstUtil.reportUnitConsistency(callscope_1,store);
        (csets, _, graph) = InnerOuter.retrieveOuterConnections(cache,env_3,ih,pre,csets,callscope_1, graph);

        //System.startTimer();
        //print("\nConnect equations and the OverConstrained graph in one step");
        dae = ConnectUtil.equations(callscope_1, csets, dae1_1, graph, Absyn.pathString(Absyn.makeNotFullyQualified(fq_class)));
        //System.stopTimer();
        //print("\nConnect and Overconstrained: " + realString(System.getTimerIntervalTime()) + "\n");
        ty = InstUtil.mktype(fq_class, ci_state_1, tys, bc_ty, equalityConstraint, c);
        dae = InstUtil.updateDeducedUnits(callscope_1,store,dae);

        // Fixes partial functions.
        ty = InstUtil.fixInstClassType(ty,isPartialFn);
        // env_3 = FGraph.updateScope(env_3);
      then
        (cache,env_3,ih,store,dae,csets,ty,ci_state_1,oDA,graph);

    //  Classes with the keyword partial can not be instantiated. They can only be inherited
    case (cache,_,_,_,_,_,SCode.CLASS(name = n,partialPrefix = SCode.PARTIAL(), info = info),_,(false),_,_,_)
      equation
        Error.addSourceMessage(Error.INST_PARTIAL_CLASS, {n}, info);
      then
        fail();

    case (_,env,_,_,_,_,SCode.CLASS(name = n),_,_,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Inst.instClass: " + n + " in env: " + FGraph.printGraphPathStr(env) + " failed\n");
      then
        fail();
  end matchcontinue;
end instClass;

protected function instClassBasictype
"author: PA
  This function instantiates a basictype class, e.g. Real, Integer, Real[2],
  etc. This function has the same functionality as instClass except that
  it will create array types when needed. (instClass never creates array
  types). This is needed because this function is used to instantiate classes
  extending from basic types. See instBasictypeBaseclass.
  NOTE: This function should only be called from instBasictypeBaseclass.
  This is new functionality in Modelica v 2.2."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input SCode.Element inClass;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean inImplicit;
  input InstTypes.CallingScope inCallingScope;
  input Connect.Sets inSets;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output DAE.Type outType;
  output list<DAE.Var>  outTypeVars "attributes of builtin types";
  output ClassInf.State outState;
algorithm
  (outCache,outEnv,outIH,outStore,outDae,outSets,outType,outTypeVars,outState):=
  match (inCache,inEnv,inIH,inStore,inMod,inPrefix,inClass,inInstDims,inImplicit,inCallingScope,inSets)
    local
      FCore.Graph env_1,env_3,env;
      ClassInf.State ci_state,ci_state_1;
      SCode.Element c_1,c;
      DAE.DAElist dae1,dae1_1,dae;
      Connect.Sets csets;
      list<DAE.Var> tys;
      Option<DAE.Type> bc_ty;
      Absyn.Path fq_class;
      SCode.Encapsulated encflag;
      Boolean impl;
      DAE.Type ty;
      DAE.Mod mod;
      Prefix.Prefix pre;
      String n;
      SCode.Restriction r;
      InstDims inst_dims;
      InstTypes.CallingScope callscope;
      FCore.Cache cache;
      InstanceHierarchy ih;
      UnitAbsyn.InstStore store;

    case (cache,env,ih,store,mod,pre,(c as SCode.CLASS(name = n,encapsulatedPrefix = encflag,restriction = r)),inst_dims,impl,_,_) /* impl */
      equation
        env_1 = FGraph.openScope(env, encflag, SOME(n), FGraph.restrictionToScopeType(r));
        ci_state = ClassInf.start(r, FGraph.getGraphName(env_1));
        c_1 = SCode.classSetPartial(c, SCode.NOT_PARTIAL());
        (cache,env_3,ih,store,dae1,csets,ci_state_1,tys,bc_ty,_,_,_)
        = instClassIn(cache, env_1, ih, store, mod, pre, ci_state, c_1, SCode.PUBLIC(), inst_dims, impl, InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, inSets, NONE());
        (cache,fq_class) = makeFullyQualified(cache,env_3, Absyn.IDENT(n));
        dae1_1 = DAEUtil.addComponentType(dae1, fq_class);
        dae = dae1_1;
        ty = InstUtil.mktypeWithArrays(fq_class, ci_state_1, tys, bc_ty, c);
      then
        (cache,env_3,ih,store,dae,csets,ty,tys,ci_state_1);

    case (_,_,_,_,_,_,SCode.CLASS(),_,_,_,_)
      equation
        //fprintln(Flags.FAILTRACE, "- Inst.instClassBasictype: " + n + " failed");
      then
        fail();

  end match;
end instClassBasictype;

public function instClassIn "
  This rule instantiates the contents of a class definition, with a new
  environment already setup.
  The *implicitInstantiation* boolean indicates if the class should be
  instantiated implicit, i.e. without generating DAE.
  The last option is a even stronger indication of implicit instantiation,
  used when looking up variables in packages. This must be used because
  generation of functions in implicit instanitation (according to
  *implicitInstantiation* boolean) can cause circular dependencies
  (e.g. if a function uses a constant in its body)"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input ClassInf.State inState;
  input SCode.Element inClass;
  input SCode.Visibility inVisibility;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean implicitInstantiation;
  input InstTypes.CallingScope inCallingScope;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  input Option<DAE.ComponentRef> instSingleCref;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output list<DAE.Var> outTypesVarLst;
  output Option<DAE.Type> outTypesTypeOption;
  output Option<SCode.Attributes> optDerAttr;
  output DAE.EqualityConstraint outEqualityConstraint;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outStore,outDae,outSets,outState,outTypesVarLst,outTypesTypeOption,optDerAttr,outEqualityConstraint,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inStore,inMod,inPrefix,inState,inClass,inVisibility,inInstDims,implicitInstantiation,inCallingScope,inGraph,inSets,instSingleCref)
    local
      Option<DAE.Type> bc;
      FCore.Graph env;
      ClassInf.State ci_state;
      SCode.Element c;
      SCode.Restriction r;
      String n;
      DAE.DAElist dae;
      Connect.Sets csets;
      list<DAE.Var> tys;
      FCore.Cache cache;
      Option<SCode.Attributes> oDA;
      DAE.EqualityConstraint equalityConstraint;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      String  s1, s2;
      UnitAbsyn.InstStore store;
      Absyn.InnerOuter io;
      SourceInfo info;
      SCode.Encapsulated encflag;

    // if the class is no outer: regular, or inner
    case (_,_,_,_,_,_,_,SCode.CLASS(prefixes = SCode.PREFIXES(innerOuter = io)),_,_,_,_,_,_,_)
      equation
        true = boolOr(Absyn.isNotInnerOuter(io), Absyn.isOnlyInner(io));
        (cache,env,ih,store,dae,csets,ci_state,tys,bc,oDA,equalityConstraint,graph) =
          instClassIn2(inCache,inEnv,inIH,inStore,inMod,inPrefix,inState,inClass,inVisibility,inInstDims,implicitInstantiation,inCallingScope,inGraph,inSets,instSingleCref);
      then
        (cache,env,ih,store,dae,csets,ci_state,tys,bc,oDA,equalityConstraint,graph);

    // if the class is inner or innerouter and an instance, use the original name and original scope
    case (_,_,_,_,_,_,_,SCode.CLASS(name = n, restriction=r, encapsulatedPrefix = encflag, prefixes = SCode.PREFIXES(innerOuter = io)),_,_,_,_,_,_,_)
      equation
        true = boolOr(Absyn.isInnerOuter(io), Absyn.isOnlyOuter(io));
        FCore.CL(status = FCore.CLS_INSTANCE(n)) = FNode.refData(FGraph.lastScopeRef(inEnv));
        (env, _) = FGraph.stripLastScopeRef(inEnv);

        env = FGraph.openScope(env, encflag, SOME(n), FGraph.restrictionToScopeType(r));
        ci_state = ClassInf.start(r,FGraph.getGraphName(env));

        // lookup in IH
        InnerOuter.INST_INNER(innerElement = SOME(c)) =
          InnerOuter.lookupInnerVar(inCache, env, inIH, inPrefix, n, io);

        (cache,env,ih,store,dae,csets,ci_state,tys,bc,oDA,equalityConstraint,graph) =
          instClassIn2(inCache,env,inIH,inStore,inMod,inPrefix,ci_state,c,inVisibility,inInstDims,implicitInstantiation,inCallingScope,inGraph,inSets,instSingleCref);
      then
        (cache,env,ih,store,dae,csets,ci_state,tys,bc,oDA,equalityConstraint,graph);

    // if the class is inner or innerouter we need to instantiate the inner!
    case (_,_,_,_,_,_,_,SCode.CLASS(name = n, prefixes = SCode.PREFIXES(innerOuter = io)),_,_,_,_,_,_,_)
      equation
        true = boolOr(Absyn.isInnerOuter(io), Absyn.isOnlyOuter(io));
        n = FGraph.getInstanceOriginalName(inEnv, n);

        // lookup in IH
        InnerOuter.INST_INNER(innerElement = SOME(c)) =
          InnerOuter.lookupInnerVar(inCache, inEnv, inIH, inPrefix, n, io);

        (cache,env,ih,store,dae,csets,ci_state,tys,bc,oDA,equalityConstraint,graph) =
          instClassIn2(inCache,inEnv,inIH,inStore,inMod,inPrefix,inState,c,inVisibility,inInstDims,implicitInstantiation,inCallingScope,inGraph,inSets,instSingleCref);
      then
        (cache,env,ih,store,dae,csets,ci_state,tys,bc,oDA,equalityConstraint,graph);

    // we could not find the inner, use the outer as it is!
    case (_,_,_,_,_,_,_,c as SCode.CLASS(name = n, prefixes = SCode.PREFIXES(innerOuter = io), info = info),_,_,_,_,_,_,_)
      equation
        true = boolOr(Absyn.isInnerOuter(io), Absyn.isOnlyOuter(io));

        s1 = n;
        s2 = Dump.unparseInnerouterStr(io);
        Error.addSourceMessage(Error.MISSING_INNER_CLASS,{s1, s2}, info);

        (cache,env,ih,store,dae,csets,ci_state,tys,bc,oDA,equalityConstraint,graph) =
          instClassIn2(inCache,inEnv,inIH,inStore,inMod,inPrefix,inState,c,inVisibility,inInstDims,implicitInstantiation,inCallingScope,inGraph,inSets,instSingleCref);
      then
        (cache,env,ih,store,dae,csets,ci_state,tys,bc,oDA,equalityConstraint,graph);

  end matchcontinue;
end instClassIn;

public function instClassIn2
"This rule instantiates the contents of a class definition, with a new
 environment already setup.
 The *implicitInstantiation* boolean indicates if the class should be
 instantiated implicit, i.e. without generating DAE.
 The last option is a even stronger indication of implicit instantiation,
 used when looking up variables in packages. This must be used because
 generation of functions in implicit instanitation (according to
 *implicitInstantiation* boolean) can cause circular dependencies
 (e.g. if a function uses a constant in its body)"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input ClassInf.State inState;
  input SCode.Element inClass;
  input SCode.Visibility inVisibility;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean implicitInstantiation;
  input InstTypes.CallingScope inCallingScope;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  input Option<DAE.ComponentRef> instSingleCref;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output list<DAE.Var> outTypesVarLst;
  output Option<DAE.Type> outTypesTypeOption;
  output Option<SCode.Attributes> optDerAttr;
  output DAE.EqualityConstraint outEqualityConstraint;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outStore,outDae,outSets,outState,outTypesVarLst,outTypesTypeOption,optDerAttr,outEqualityConstraint,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inStore,inMod,inPrefix,inState,inClass,inVisibility,inInstDims,implicitInstantiation,inCallingScope,inGraph,inSets,instSingleCref)
    local
      Option<DAE.Type> bc;
      FCore.Graph env;
      DAE.Mod mods;
      Prefix.Prefix pre;
      ClassInf.State ci_state;
      SCode.Element c;
      InstDims inst_dims;
      Boolean impl;
      SCode.Visibility vis;
      String n;
      DAE.DAElist dae;
      Connect.Sets csets;
      list<DAE.Var> tys;
      SCode.Restriction r,rCached;
      SCode.ClassDef d;
      FCore.Cache cache;
      Option<SCode.Attributes> oDA;
      DAE.EqualityConstraint equalityConstraint;
      InstTypes.CallingScope callscope, ccs;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      InstHashTable instHash;
      CachedInstItemInputs inputs;
      CachedInstItemOutputs outputs;
      Absyn.Path fullEnvPathPlusClass;
      String className;
      UnitAbsyn.InstStore store;

      DAE.Mod aa_1;
      Prefix.Prefix aa_2;
      Connect.Sets aa_3;
      ClassInf.State aa_4;
      SCode.Element aa_5;
      InstDims aa_7;
      Boolean aa_8;
      Option<DAE.ComponentRef> aa_9;
      tuple<InstDims,Boolean,DAE.Mod,Connect.Sets,ClassInf.State,SCode.Element,Option<DAE.ComponentRef>> bbx, bby;
      ConnectionGraph.ConnectionGraph graphCached;
      DAE.FunctionTree functionTree;

    // packages derived from partial packages should do partialInstClass, since it filters out a lot of things.
    case (cache,env,ih,store,mods,pre,ci_state,
      c as SCode.CLASS(restriction = SCode.R_PACKAGE(), partialPrefix = SCode.PARTIAL()),
      vis,inst_dims,_,_,graph,_,_)
      equation
        (cache,env,ih,ci_state,_) = partialInstClassIn(cache, env, ih, mods, pre, ci_state, c, vis, inst_dims, 0);
      then
        (cache,env,ih,store,DAE.emptyDae, inSets,ci_state,{},NONE(),NONE(),NONE(),graph);

    //  see if we have it in the cache
    case (cache, env, ih, store, mods, pre, ci_state,
        c as SCode.CLASS(), _, inst_dims, impl,
        callscope, graph, csets, _)
      equation
        true = Flags.isSet(Flags.CACHE);
        instHash = getGlobalRoot(Global.instHashIndex);
        fullEnvPathPlusClass = generateCachePath(inEnv, c, pre, callscope);
        {SOME(FUNC_instClassIn(inputs, outputs)),_} = BaseHashTable.get(fullEnvPathPlusClass, instHash);
        (_, _, _, _, aa_1, aa_2, aa_3, aa_4, aa_5 as SCode.CLASS(), _, aa_7, aa_8, _, aa_9, ccs) = inputs;
        // are the important inputs the same??
        InstUtil.prefixEqualUnlessBasicType(aa_2, pre, c);
        bbx = (aa_7,      aa_8, aa_1, aa_3, aa_4,     aa_5, aa_9);
        bby = (inst_dims, impl, mods, csets, ci_state, c,    instSingleCref);
        equality(bbx = bby);
        true = callingScopeCacheEq(ccs, callscope);
        (_,env,dae,csets,ci_state,tys,bc,oDA,equalityConstraint,graphCached) = outputs;
        graph = ConnectionGraph.merge(graph, graphCached);

        // cache = FCore.setCachedFunctionTree(cache, DAEUtil.joinAvlTrees(functionTree, FCore.getFunctionTree(cache)));
        showCacheInfo("Full Inst Hit: ", fullEnvPathPlusClass);
        /*
        fprintln(Flags.CACHE, "IIII->got from instCache: " + Absyn.pathString(fullEnvPathPlusClass) +
          "\n\tpre: " + PrefixUtil.printPrefixStr(pre) + " class: " +  className +
          "\n\tmods: " + Mod.printModStr(mods) +
          "\n\tenv: " + FGraph.printGraphPathStr(inEnv) +
          "\n\tsingle cref: " + Expression.printComponentRefOptStr(instSingleCref) +
          "\n\tdims: [" + stringDelimitList(List.map1(inst_dims, DAEDump.unparseDimensions, true), ", ") + "]" +
          "\n\tdae:\n" + DAEDump.dump2str(dae));
        */
      then
        (cache,env,ih,store,dae,csets,ci_state,tys,bc,oDA,equalityConstraint,graph);

    // call the function and then add it in the cache
    case (cache,env,ih,store,_,_,ci_state,
      SCode.CLASS(),
      _,_,_,callscope,graph,_,_)
      equation
        //System.startTimer();
        (cache,env,ih,store,dae,csets,ci_state,tys,bc,oDA,equalityConstraint,graph) =
          instClassIn_dispatch(inCache,inEnv,inIH,store,inMod,inPrefix,inState,inClass,inVisibility,inInstDims,implicitInstantiation,callscope,inGraph,inSets,instSingleCref);

        fullEnvPathPlusClass = generateCachePath(inEnv, inClass, inPrefix, callscope);

        inputs = (inCache,inEnv,inIH,store,inMod,inPrefix,inSets,inState,inClass,inVisibility,inInstDims,implicitInstantiation,inGraph,instSingleCref,callscope);
        outputs = (FCore.getFunctionTree(cache),env,dae,csets,ci_state,tys,bc,oDA,equalityConstraint,graph);

        showCacheInfo("Full Inst Add: ", fullEnvPathPlusClass);
        addToInstCache(fullEnvPathPlusClass,
           SOME(FUNC_instClassIn( // result for full instantiation
             inputs,
             outputs)),
           /*SOME(FUNC_partialInstClassIn( // result for partial instantiation
             (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inClass,inVisibility,inInstDims),
             (env,ci_state)))*/ NONE());
        /*
        fprintln(Flags.CACHE, "IIII->added to instCache: " + Absyn.pathString(fullEnvPathPlusClass) +
          "\n\tpre: " + PrefixUtil.printPrefixStr(pre) + " class: " +  className +
          "\n\tmods: " + Mod.printModStr(mods) +
          "\n\tenv: " + FGraph.printGraphPathStr(inEnv) +
          "\n\tsingle cref: " + Expression.printComponentRefOptStr(instSingleCref) +
          "\n\tdims: [" + stringDelimitList(List.map1(inst_dims, DAEDump.unparseDimensions, true), ", ") + "]" +
          "\n\tdae:\n" + DAEDump.dump2str(dae));
        */
        //checkModelBalancingFilterByRestriction(r, envPathOpt, dae);
        //System.stopTimer();
        //_ = Database.query(0, "insert into Inst values(\"" + Absyn.pathString(fullEnvPathPlusClass) + "\", " + realString(System.getTimerIntervalTime()) + ");");
        // _ = FGraph.updateClass(inEnv, inClass, inPrefix, inMod, FCore.CLS_FULL(), env);
      then
        (cache,env,ih,store,dae,csets,ci_state,tys,bc,oDA,equalityConstraint,graph);

    // failure
    case (_, env, _, _, _, _, _, SCode.CLASS(name = n), _, _, _, _, _, _, _)
      equation
        //print("instClassIn(");print(n);print(") failed\n");
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Inst.instClassIn2 failed on class:" + n + " in environment: " + FGraph.printGraphPathStr(env));
      then
        fail();

  end matchcontinue;
end instClassIn2;

protected function callingScopeCacheEq
  input InstTypes.CallingScope inCallingScope1;
  input InstTypes.CallingScope inCallingScope2;
  output Boolean outIsEq;
algorithm
  outIsEq := match(inCallingScope1, inCallingScope2)
    case (InstTypes.TYPE_CALL(), InstTypes.TYPE_CALL()) then true;
    case (InstTypes.TYPE_CALL(), _) then false;
    case (_, InstTypes.TYPE_CALL()) then false;
    else true;
  end match;
end callingScopeCacheEq;

public function instClassIn_dispatch
"This rule instantiates the contents of a class definition, with a new
  environment already setup.
  The *implicitInstantiation* boolean indicates if the class should be
  instantiated implicit, i.e. without generating DAE.
  The last option is a even stronger indication of implicit instantiation,
  used when looking up variables in packages. This must be used because
  generation of functions in implicit instanitation (according to
  *implicitInstantiation* boolean) can cause circular dependencies
  (e.g. if a function uses a constant in its body)"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input ClassInf.State inState;
  input SCode.Element inClass;
  input SCode.Visibility inVisibility;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean implicitInstantiation;
  input InstTypes.CallingScope inCallingScope;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  input Option<DAE.ComponentRef> instSingleCref;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output list<DAE.Var> outTypesVarLst;
  output Option<DAE.Type> outTypesTypeOption;
  output Option<SCode.Attributes> optDerAttr;
  output DAE.EqualityConstraint outEqualityConstraint;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outStore,outDae,outSets,outState,outTypesVarLst,outTypesTypeOption,optDerAttr,outEqualityConstraint,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inStore,inMod,inPrefix,inState,inClass,inVisibility,inInstDims,implicitInstantiation,inCallingScope,inGraph,inSets,instSingleCref)
    local
      Option<DAE.Type> bc;
      FCore.Graph env,env_1;
      DAE.Mod mods;
      Prefix.Prefix pre;
      ClassInf.State ci_state,ci_state_1;
      SCode.Element c;
      InstDims inst_dims;
      Boolean impl;
      SCode.Visibility vis;
      String implstr,n;
      Connect.Sets csets;
      list<DAE.Var> tys;
      SCode.Restriction r;
      SCode.ClassDef d;
      FCore.Cache cache;
      Option<SCode.Attributes> oDA;
      InstTypes.CallingScope callscope;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      DAE.DAElist dae,dae1,dae1_1;
      SourceInfo info;
      DAE.Type typ;
      FCore.Graph env_2, env_3;
      list<SCode.Element> els;
      list<tuple<SCode.Element, DAE.Mod>> comp;
      list<String> names;
      DAE.EqualityConstraint eqConstraint;
      DAE.Type ty, ty2;
      Absyn.Path fq_class;
      list<DAE.Var> tys1,tys2;
      SCode.Partial partialPrefix;
      SCode.Encapsulated encapsulatedPrefix;
      UnitAbsyn.InstStore store;
      Boolean b;
      BasicTypeAttrTyper typer;
      SCode.Comment comment;

    // Builtin type (Real, Integer, etc.).
    case (cache, env, ih, store, mods, pre, ci_state,
        SCode.CLASS(name = n), _, inst_dims, _, _, graph, _, _)
      equation
        ty = getBasicTypeType(n);
        typer = getBasicTypeAttrTyper(n);
        ty = liftNonExpType(ty, inst_dims, Config.splitArrays());
        tys = instBasicTypeAttributes(cache, env, mods, ty, typer, pre);
        ty = Types.setTypeVars(ty, tys);
        bc = arrayBasictypeBaseclass(inst_dims, ty);
      then
        (cache, env, ih, store, DAE.emptyDae, inSets, ci_state, tys, bc, NONE(), NONE(), graph);

    // adrpo: 2010-09-27: here we do two things at once, but not correctly!
    // Instantiate enumeration class at top level Prefix.NOPRE()
    //   when we are instantiating with no prefix, it means we are instantiating the enumeration class!
    //   and we don't care about modifications!
    // Instantiate enumeration VARIABLE with a prefix!
    //   when we are instantiating with a prefix, it means we are instantiating a variable of an enumeration type!
    //   and we care about modifications!
    //   this does not work!
    //   T = enumeration(x, y, z);
    //   T c(start = T.x) should generate an enumeration variable with and the type should contain the
    //                    start value, but we have no place to put it as the var list in the T_ENUMERATION is for names!
    case (cache,env,ih,store,mods,pre, ci_state,
      (c as SCode.CLASS(name = n,restriction = SCode.R_ENUMERATION(),classDef =
      SCode.PARTS(elementLst = els),info = info)),_,inst_dims,impl,callscope,graph,_,_)
      equation
        names = SCode.componentNames(c);
        Types.checkEnumDuplicateLiterals(names, info);

        tys = instBasicTypeAttributes(cache, env, mods,
          DAE.T_ENUMERATION_DEFAULT, getEnumAttributeType, pre);
        /* uncomment this and see how checkAllModelsRecursive(Modelica.Electrical.Digital) looks like
           especially MUX.Or1.auxiliary doesn't get its start/fixed bindings
        print("Inst enumeration class (empty prefix) / variable (some pre): " + n +
          "\npre: " + PrefixUtil.printPrefixStr(pre) +
          "\nenv: " + FGraph.printGraphPathStr(env) +
          "\nmods: " + Mod.printModStr(mods) +
          "\ninst_dims: [" + stringDelimitList(List.map1(inst_dims, DAEDump.unparseDimensions, true), ", ") + "]" + "\n");
        */
        ci_state_1 = ClassInf.trans(ci_state, ClassInf.NEWDEF());
        comp = InstUtil.addNomod(els);
        (cache,env_1,ih) = InstUtil.addComponentsToEnv(cache,env,ih, mods, pre, ci_state_1, comp, comp, {}, inst_dims, impl);

        // we should instantiate with no modifications, they don't belong to the class, they belong to the component!
        (cache,env_2,ih,store,_,csets,ci_state_1,tys1,graph) =
          instElementList(cache,env_1,ih,store, /* DAE.NOMOD() */ mods, pre,
            ci_state_1, comp, inst_dims, impl,callscope,graph, inSets, true);

        (cache,fq_class) = makeFullyQualified(cache,env_2, Absyn.IDENT(n));
        eqConstraint = InstUtil.equalityConstraint(env_2, els, info);
        // DAEUtil.addComponentType(dae1, fq_class);
        ty2 = DAE.T_ENUMERATION(NONE(), fq_class, names, tys1, tys, {fq_class});
        bc = arrayBasictypeBaseclass(inst_dims, ty2);
        bc = if isSome(bc) then bc else SOME(ty2);
        ty = InstUtil.mktype(fq_class, ci_state_1, tys1, bc, eqConstraint, c);
        // update Enumerationtypes in environment
        (cache,env_3) = InstUtil.updateEnumerationEnvironment(cache,env_2,ty,c,ci_state_1);
        tys2 = listAppend(tys, tys1); // <--- this is wrong as the tys belong to the component variable not the Enumeration Class!
      then
        (cache,env_3,ih,store,DAE.emptyDae,csets,ci_state_1,tys2,bc /* NONE() */,NONE(),NONE(),graph);

    // Instantiate a class definition made of parts
    case (cache,env,ih,store,mods,pre,ci_state,
          c as SCode.CLASS(name = n,restriction = r,classDef = d, cmt = comment, info=info, partialPrefix = partialPrefix,encapsulatedPrefix = encapsulatedPrefix),
          vis,inst_dims,impl,callscope,graph,_,_)
      equation
        ErrorExt.setCheckpoint("instClassParts");
        false = InstUtil.isBuiltInClass(n) "If failed above, no need to try again";
        _ = match r
          case SCode.R_ENUMERATION() then fail();
          else ();
        end match;
        // fprint(Flags.INSTTR, "ICLASS [");
        // _ = if_(impl, "impl] ", "expl] ");
        // fprint(Flags.INSTTR, implstr);
        // fprintln(Flags.INSTTR, FGraph.printGraphPathStr(env) + "." + n + " mods: " + Mod.printModStr(mods));
        // t1 = clock();
        (cache,env_1,ih,store,dae,csets,ci_state_1,tys,bc,oDA,eqConstraint,graph) =
          instClassdef(cache, env, ih, store, mods, pre, ci_state, n, d, r, vis,
            partialPrefix, encapsulatedPrefix, inst_dims, impl, callscope,
            graph, inSets, instSingleCref, comment, info);
        // t2 = clock();
        // time = t2 -. t1;
        // b=realGt(time,0.05);
        // s = realString(time);
        // fprintln(Flags.INSTTR, " -> ICLASS " + n + " inst time: " + s + " in env: " + FGraph.printGraphPathStr(env) + " mods: " + Mod.printModStr(mods));
        dae = if SCode.isFunction(c) and not impl then DAE.DAE({}) else dae;
        ErrorExt.delCheckpoint("instClassParts");
      then
        (cache,env_1,ih,store,dae,csets,ci_state_1,tys,bc,oDA,eqConstraint,graph);

     /* Ignore functions if not implicit instantiation, and doing checkModel - some dimensions might not be complete... */
    case (cache,env,ih,store,_,_,ci_state,c as SCode.CLASS(),_,_,impl,_,graph,_,_)
      equation
        b = Flags.getConfigBool(Flags.CHECK_MODEL) and (not impl) and SCode.isFunction(c);
        if not b then
          ErrorExt.delCheckpoint("instClassParts");
          fail();
        else
          ErrorExt.rollBack("instClassParts");
        end if;
        // clsname = SCode.className(cls);
        // print("Ignore function" + clsname + "\n");
      then
        (cache,env,ih,store,DAE.emptyDae, inSets,ci_state,{},NONE(),NONE(),NONE(),graph);

    // failure
    else
      equation
        //print("instClassIn(");print(n);print(") failed\n");
        //fprintln(Flags.FAILTRACE, "- Inst.instClassIn failed" + n);
      then
        fail();
  end matchcontinue;
end instClassIn_dispatch;

protected function liftNonExpType
  input DAE.Type inType;
  input InstDims inInstDims;
  input Boolean inSplitArrays;
  output DAE.Type outType;
algorithm
  outType := match(inType, inInstDims, inSplitArrays)
    local
      list<DAE.Dimension> dims;

    case (_, dims :: _, false)
      then Types.liftArrayListDims(inType, dims);

    else inType;

  end match;
end liftNonExpType;

protected function getBasicTypeType
  input String inName;
  output DAE.Type outType;
algorithm
  outType := match(inName)
    case "Real" then DAE.T_REAL_DEFAULT;
    case "Integer" then DAE.T_INTEGER_DEFAULT;
    case "String" then DAE.T_STRING_DEFAULT;
    case "Boolean" then DAE.T_BOOL_DEFAULT;
    // BTH
    case "Clock"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then DAE.T_CLOCK_DEFAULT;
  end match;
end getBasicTypeType;

protected function getBasicTypeAttrTyper
  input String inName;
  output BasicTypeAttrTyper outTyper;
algorithm
  outTyper := match(inName)
    case "Real" then getRealAttributeType;
    case "Integer" then getIntAttributeType;
    case "String" then getStringAttributeType;
    case "Boolean" then getBoolAttributeType;
    // BTH
    case "Clock"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then getClockAttributeType;
  end match;
end getBasicTypeAttrTyper;

protected function getRealAttributeType
  input String inAttrName;
  input DAE.Type inBaseType;
  input SourceInfo inInfo;
  output DAE.Type outType;
algorithm
  outType := match(inAttrName, inBaseType, inInfo)
    case ("quantity", _, _) then DAE.T_STRING_DEFAULT;
    case ("unit", _, _) then DAE.T_STRING_DEFAULT;
    case ("displayUnit", _, _) then DAE.T_STRING_DEFAULT;
    case ("min", _, _) then inBaseType;
    case ("max", _, _) then inBaseType;
    case ("start", _, _) then inBaseType;
    case ("fixed", _, _) then DAE.T_BOOL_DEFAULT;
    case ("nominal", _, _) then inBaseType;
    case ("stateSelect", _, _) then InstBinding.stateSelectType;
    case ("uncertain", _, _) then InstBinding.uncertaintyType;
    case ("distribution", _, _) then InstBinding.distributionType;
    else
      equation
        Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
          {inAttrName, "Real"}, inInfo);
      then
        fail();
  end match;
end getRealAttributeType;

protected function getIntAttributeType
  input String inAttrName;
  input DAE.Type inBaseType;
  input SourceInfo inInfo;
  output DAE.Type outType;
algorithm
  outType := match(inAttrName, inBaseType, inInfo)
    case ("quantity", _, _) then DAE.T_STRING_DEFAULT;
    case ("min", _, _) then inBaseType;
    case ("max", _, _) then inBaseType;
    case ("start", _, _) then inBaseType;
    case ("fixed", _, _) then DAE.T_BOOL_DEFAULT;
    case ("nominal", _, _) then inBaseType;
    case ("uncertain", _, _) then InstBinding.uncertaintyType;
    case ("distribution", _, _) then InstBinding.distributionType;
    else
      equation
        Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
          {inAttrName, "Integer"}, inInfo);
      then
        fail();
  end match;
end getIntAttributeType;

protected function getStringAttributeType
  input String inAttrName;
  input DAE.Type inBaseType;
  input SourceInfo inInfo;
  output DAE.Type outType;
algorithm
  outType := match(inAttrName, inBaseType, inInfo)
    case ("quantity", _, _) then DAE.T_STRING_DEFAULT;
    case ("start", _, _) then inBaseType;
    else
      equation
        Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
          {inAttrName, "String"}, inInfo);
      then
        fail();
  end match;
end getStringAttributeType;

protected function getBoolAttributeType
  input String inAttrName;
  input DAE.Type inBaseType;
  input SourceInfo inInfo;
  output DAE.Type outType;
algorithm
  outType := match(inAttrName, inBaseType, inInfo)
    case ("quantity", _, _) then DAE.T_STRING_DEFAULT;
    case ("start", _, _) then inBaseType;
    case ("fixed", _, _) then DAE.T_BOOL_DEFAULT;
    else
      equation
        Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
          {inAttrName, "Boolean"}, inInfo);
      then
        fail();
  end match;
end getBoolAttributeType;


protected function getClockAttributeType "
Author: BTH
This function is supposed to fail since clock variables don't have attributes.
"
  input String inAttrName;
  input DAE.Type inBaseType;
  input SourceInfo inInfo;
  output DAE.Type outType;
algorithm
  outType := match(inAttrName, inBaseType, inInfo)
    case (_, _, _) then fail();
  end match;
end getClockAttributeType;


protected function getEnumAttributeType
  input String inAttrName;
  input DAE.Type inBaseType;
  input SourceInfo inInfo;
  output DAE.Type outType;
algorithm
  outType := match(inAttrName, inBaseType, inInfo)
    case ("quantity", _, _) then DAE.T_STRING_DEFAULT;
    case ("min", _, _) then inBaseType;
    case ("max", _, _) then inBaseType;
    case ("start", _, _) then inBaseType;
    case ("fixed", _, _) then DAE.T_BOOL_DEFAULT;
    else
      equation
        Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
          {inAttrName, "enumeration(:)"}, inInfo);
      then
        fail();
  end match;
end getEnumAttributeType;

protected function instBasicTypeAttributes
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Mod inMod;
  input DAE.Type inBaseType;
  input BasicTypeAttrTyper inTypeFunc;
  input Prefix.Prefix inPrefix;
  output list<DAE.Var> outVars;
algorithm
  outVars := match(inCache, inEnv, inMod, inBaseType, inTypeFunc, inPrefix)
    local
      list<DAE.SubMod> submods;

    case (_, _, DAE.MOD(subModLst = submods), _, _, _)
      then List.map4(submods, instBasicTypeAttributes2, inCache, inEnv, inBaseType, inTypeFunc);

    case (_, _, DAE.NOMOD(), _, _, _) then {};
    case (_, _, DAE.REDECL(), _, _, _) then {};
  end match;
end instBasicTypeAttributes;

protected function instBasicTypeAttributes2
  input DAE.SubMod inSubMod;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Type inBaseType;
  input BasicTypeAttrTyper inTypeFunc;
  output DAE.Var outVar;
algorithm
  outVar := match(inSubMod, inCache, inEnv, inBaseType, inTypeFunc)
    local
      DAE.Ident name;
      DAE.Type ty;
      DAE.Exp exp;
      Option<Values.Value> val;
      DAE.Properties p;
      SourceInfo info;

    case (DAE.NAMEMOD(ident = name, mod = DAE.MOD(eqModOption = SOME(DAE.TYPED(
        modifierAsExp = exp, modifierAsValue = val, properties = p, info = info)))), _, _, _, _)
      equation
        ty = getRealAttributeType(name, inBaseType, info);
      then
        instBuiltinAttribute(inCache, inEnv, name, val, exp, ty, p);

    case (DAE.NAMEMOD(ident = name), _, _, _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Inst.instBasicTypeAttributes2 failed on " + name);
      then
        fail();

  end match;
end instBasicTypeAttributes2;

protected function instBuiltinAttribute
"Help function to e.g. instRealClass, etc."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input String id;
  input Option<Values.Value> optVal;
  input DAE.Exp bind;
  input DAE.Type inExpectedTp;
  input DAE.Properties bindProp;
  output DAE.Var var;
algorithm
  var := matchcontinue(inCache,inEnv,id,optVal,bind,inExpectedTp,bindProp)
    local
      Values.Value v;
      DAE.Type t_1,bindTp;
      DAE.Exp bind1,vbind;
      DAE.Const c;
      DAE.Dimension d;
      String s,s1,s2;
      DAE.Type expectedTp;
      FCore.Cache cache;
      FCore.Graph env;

    case (_,_,_,SOME(v),_,expectedTp,DAE.PROP(bindTp,c))
      equation
        false = valueEq(c,DAE.C_VAR());
        (bind1,t_1) = Types.matchType(bind,bindTp,expectedTp,true);
        // convert the value also if needed!!
        (vbind,_) = Types.matchType(ValuesUtil.valueExp(v),bindTp,expectedTp,true);
        v = ValuesUtil.expValue(vbind);
      then DAE.TYPES_VAR(id,DAE.dummyAttrParam,t_1,
        DAE.EQBOUND(bind1,SOME(v),DAE.C_PARAM(),DAE.BINDING_FROM_DEFAULT_VALUE()),NONE());

    case (_,_,_,SOME(v),_,expectedTp,DAE.PROP(bindTp as DAE.T_ARRAY(dims = {d}),c))
      equation
        false = valueEq(c,DAE.C_VAR());
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        expectedTp = Types.liftArray(expectedTp, d);
        (bind1,t_1) = Types.matchType(bind,bindTp,expectedTp,true);
        // convert the value also if needed!!
        (vbind,_) = Types.matchType(ValuesUtil.valueExp(v),bindTp,expectedTp,true);
        v = ValuesUtil.expValue(vbind);
      then DAE.TYPES_VAR(id,DAE.dummyAttrParam,t_1,
        DAE.EQBOUND(bind1,SOME(v),DAE.C_PARAM(),DAE.BINDING_FROM_DEFAULT_VALUE()),NONE());

    case (cache,env,_,_,_,expectedTp,DAE.PROP(bindTp,c))
      equation
        false = valueEq(c,DAE.C_VAR());
        (bind1,t_1) = Types.matchType(bind,bindTp,expectedTp,true);
        (cache,v,_) = Ceval.ceval(cache, env, bind1, false, NONE(), Absyn.NO_MSG(), 0);
      then DAE.TYPES_VAR(id,DAE.dummyAttrParam,t_1,
        DAE.EQBOUND(bind1,SOME(v),DAE.C_PARAM(),DAE.BINDING_FROM_DEFAULT_VALUE()),NONE());

    case (cache,env,_,_,_,expectedTp,DAE.PROP(bindTp as DAE.T_ARRAY(dims = {d}),c))
      equation
        false = valueEq(c,DAE.C_VAR());
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        expectedTp = Types.liftArray(expectedTp, d);
        (bind1,t_1) = Types.matchType(bind,bindTp,expectedTp,true);
        (cache,v,_) = Ceval.ceval(cache,env, bind1, false,NONE(), Absyn.NO_MSG(), 0);
      then DAE.TYPES_VAR(id,DAE.dummyAttrParam,t_1,
        DAE.EQBOUND(bind1,SOME(v),DAE.C_PARAM(),DAE.BINDING_FROM_DEFAULT_VALUE()),NONE());

    case(_,_,_,_,_,expectedTp,DAE.PROP(bindTp,c))
      equation
        false = valueEq(c,DAE.C_VAR());
        (bind1,t_1) = Types.matchType(bind,bindTp,expectedTp,true);
      then DAE.TYPES_VAR(id,DAE.dummyAttrParam,t_1,
        DAE.EQBOUND(bind1,NONE(),DAE.C_PARAM(),DAE.BINDING_FROM_DEFAULT_VALUE()),NONE());

    case(_,_,_,_,_,_,DAE.PROP(_,c))
      equation
        true = valueEq(c,DAE.C_VAR());
        s = ExpressionDump.printExpStr(bind);
        Error.addMessage(Error.HIGHER_VARIABILITY_BINDING,{id,"PARAM",s,"VAR"});
      then fail();

    case(_,_,_,_,_,expectedTp,DAE.PROP(bindTp,_))
      equation
        failure((_,_) = Types.matchType(bind,bindTp,expectedTp,true));
        s1 = "builtin attribute " + id + " of type "+Types.unparseType(bindTp);
        s2 = Types.unparseType(expectedTp);
        Error.addMessage(Error.TYPE_ERROR,{s1,s2});
      then fail();

    case(_,_,_,SOME(v),_,expectedTp,_) equation
      true = Flags.isSet(Flags.FAILTRACE);
      Debug.traceln("instBuiltinAttribute failed for: " + id +
                                  " value binding: " + ValuesUtil.printValStr(v) +
                                  " binding: " + ExpressionDump.printExpStr(bind) +
                                  " expected type: " + Types.printTypeStr(expectedTp) +
                                  " type props: " + Types.printPropStr(bindProp));
    then fail();
    case(_,_,_,_,_,expectedTp,_) equation
      true = Flags.isSet(Flags.FAILTRACE);
      Debug.traceln("instBuiltinAttribute failed for: " + id +
                                  " value binding: NONE()" +
                                  " binding: " + ExpressionDump.printExpStr(bind) +
                                  " expected type: " + Types.printTypeStr(expectedTp) +
                                  " type props: " + Types.printPropStr(bindProp));
    then fail();
  end matchcontinue;
end instBuiltinAttribute;

protected function arrayBasictypeBaseclass
"author: PA"
  input list<list<DAE.Dimension>> inInstDims;
  input DAE.Type inType;
  output Option<DAE.Type> outOptType;
algorithm
  outOptType := match(inInstDims, inType)
    local
      DAE.Type ty;
      DAE.Dimensions dims;

    case ({}, _) then NONE();

    else
      equation
        dims = List.last(inInstDims);
        ty = Expression.liftArrayLeftList(inType, dims);
      then
        SOME(ty);

  end match;
end arrayBasictypeBaseclass;

public function partialInstClassIn
"This function is used when instantiating classes in lookup of other classes.
  The only work performed by this function is to instantiate local classes and
  inherited classes."
  input FCore.Cache inCache;
  input .FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input ClassInf.State inState;
  input SCode.Element inClass;
  input SCode.Visibility inVisibility;
  input list<list<DAE.Dimension>> inInstDims;
  input Integer numIter;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output ClassInf.State outState;
  output list<DAE.Var> outTys;
algorithm
  (outCache,outEnv,outIH,outState,outTys) := matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inState,inClass,inVisibility,inInstDims,numIter)
    local
      FCore.Graph env;
      DAE.Mod mods;
      Prefix.Prefix pre;
      ClassInf.State ci_state,ci_state_1;
      SCode.Element c;
      String n, strDepth;
      SCode.Restriction r, rCached;
      SCode.ClassDef d;
      SCode.Visibility vis;
      InstDims inst_dims;
      FCore.Cache cache;
      InstanceHierarchy ih;
      InstHashTable instHash;
      CachedPartialInstItemInputs inputs;
      CachedPartialInstItemOutputs outputs;
      Absyn.Path fullEnvPathPlusClass;
      String className;
      DAE.Mod aa_1;
      Prefix.Prefix aa_2;
      ClassInf.State aa_4;
      SCode.Element aa_5;
      InstDims aa_7;
      tuple<InstDims,DAE.Mod,ClassInf.State,SCode.Element> bbx,bby;
      Boolean partialInst;
      list<DAE.Var> vars;
      DAE.FunctionTree functionTree;

    // see if we find a partial class inst
    case (cache,env,ih,mods,pre,ci_state,c as SCode.CLASS(),_,inst_dims,_)
      equation
        true = Flags.isSet(Flags.CACHE);
        instHash = getGlobalRoot(Global.instHashIndex);
        _ = SCode.className(c);

        fullEnvPathPlusClass = generateCachePath(inEnv, c, pre, InstTypes.INNER_CALL());

        {_,SOME(FUNC_partialInstClassIn(inputs, outputs))} = BaseHashTable.get(fullEnvPathPlusClass, instHash);
        (_, _, _, aa_1, aa_2, aa_4, aa_5 as SCode.CLASS(), _, aa_7) = inputs;
        // are the important inputs the same??
        InstUtil.prefixEqualUnlessBasicType(aa_2, pre, c);
        bbx = (aa_7,      aa_1, aa_4,     aa_5);
        bby = (inst_dims, mods, ci_state, c);
        equality(bbx = bby);
        (_,env,ci_state_1,vars) = outputs;

        // cache = FCore.setCachedFunctionTree(cache, DAEUtil.joinAvlTrees(functionTree, FCore.getFunctionTree(cache)));
        showCacheInfo("Partial Inst Hit: ", fullEnvPathPlusClass);
      then
        (cache,env,ih,ci_state_1,vars);

    /*/ adrpo: TODO! FIXME! see if we find a full instantiation!
    // this fails for 2-3 examples, so disable it for now and check it later
    case (cache,env,ih,mods,pre,csets,ci_state,c as SCode.CLASS(name = className, restriction=r),vis,inst_dims,_)
      local
      tuple<FCore.Cache, Env, InstanceHierarchy, UnitAbsyn.InstStore, DAE.Mod, Prefix.Prefix,
            Connect.Sets, ClassInf.State, SCode.Element, Boolean, InstDims, Boolean,
            ConnectionGraph.ConnectionGraph, Option<DAE.ComponentRef>> inputs;
      tuple<FCore.Cache, Env, InstanceHierarchy, UnitAbsyn.InstStore, DAE.DAElist,
            Connect.Sets, ClassInf.State, list<DAE.Var>, Option<DAE.Type>,
            Option<SCode.Attributes>, DAE.EqualityConstraint,
            ConnectionGraph.ConnectionGraph> outputs;
      equation
        true = Flags.isSet(Flags.CACHE);
        instHash = getGlobalRoot(Global.instHashIndex);

        fullEnvPathPlusClass = generateCachePath(inEnv, c, pre, InstTypes.INNER_CALL());

        {SOME(FUNC_instClassIn(inputs, outputs)), _} = get(fullEnvPathPlusClass, instHash);
        (_, _, _, _, aa_1, aa_2, aa_3, aa_4, aa_5  as SCode.CLASS(restriction=rCached), _, aa_7, _, _, _) = inputs;
        // are the important inputs the same??
        equality(rCached = r); // restrictions should be the same
        InstUtil.prefixEqualUnlessBasicType(aa_2, pre, c); // check if class is enum as then prefix doesn't matter!
        bbx = (aa_7,      aa_1, aa_4,     a5);
        bby = (inst_dims, mods, ci_state, c);
        equality(bbx = bby);
        // true = checkClassEqual(aa_5, c);
        (cache,env,_,_,_,_,ci_state_1,_,_,_,_,_) = outputs;
        //fprintln(Flags.CACHE, "IIIIPARTIAL->got FULL from instCache: " + Absyn.pathString(fullEnvPathPlusClass));
      then
        (inCache,env,ih,ci_state_1);*/

    /* call the function and then add it in the cache */
    case (cache,env,ih,_,_,ci_state,_,vis,_,_)
      equation
        true = numIter < Global.recursionDepthLimit;
        partialInst = System.getPartialInstantiation();
        System.setPartialInstantiation(true);

        (cache,env,ih,ci_state,vars) =
           partialInstClassIn_dispatch(inCache,inEnv,inIH,inMod,inPrefix,inState,inClass,vis,inInstDims,partialInst,numIter+1);

        fullEnvPathPlusClass = generateCachePath(inEnv, inClass, inPrefix, InstTypes.INNER_CALL());

        inputs = (inCache,inEnv,inIH,inMod,inPrefix,inState,inClass,vis,inInstDims);
        outputs = (FCore.getFunctionTree(cache),env,ci_state,vars);

        showCacheInfo("Partial Inst Add: ", fullEnvPathPlusClass);

        addToInstCache(fullEnvPathPlusClass,
           NONE(),
           SOME(FUNC_partialInstClassIn( // result for partial instantiation
             inputs,outputs)));
        // fprintln(Flags.CACHE, "IIIIPARTIAL->added to instCache: " + Absyn.pathString(fullEnvPathPlusClass));
        // _ = FGraph.updateClass(inEnv, inClass, inPrefix, inMod, FCore.CLS_PARTIAL(), env);
      then
        (cache,env,ih,ci_state,vars);

    case (_,env,_,_,_,_,c,_,_,_)
      equation
        false = numIter < Global.recursionDepthLimit;
        n = FGraph.printGraphPathStr(env);
        // print("partialInstClassIn recursion depth... " + n + "\n");
        Error.addSourceMessage(Error.RECURSION_DEPTH_REACHED,{n},SCode.elementInfo(c));
      then fail();

    case (_,env,_,_,_,_,(SCode.CLASS(name = n)),_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Inst.partialInstClassIn failed on class:" +
           n + " in environment: " + FGraph.printGraphPathStr(env));
      then
        fail();
  end matchcontinue;
end partialInstClassIn;

protected function partialInstClassIn_dispatch
"This function is used when instantiating classes in lookup of other classes.
  The only work performed by this function is to instantiate local classes and
  inherited classes."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input ClassInf.State inState;
  input SCode.Element inClass;
  input SCode.Visibility inVisibility;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean partialInst;
  input Integer numIter;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output ClassInf.State outState;
  output list<DAE.Var> outVars;
algorithm
  (outCache,outEnv,outIH,outState,outVars) := matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inState,inClass,inVisibility,inInstDims,partialInst,numIter)
    local
      FCore.Graph env,env_1;
      DAE.Mod mods;
      Prefix.Prefix pre;
      ClassInf.State ci_state,ci_state_1;
      SCode.Element c;
      String n, str;
      SCode.Restriction r;
      SCode.ClassDef d;
      SCode.Visibility vis;
      SCode.Partial partialPrefix;
      InstDims inst_dims;
      FCore.Cache cache;
      InstanceHierarchy ih;
      SourceInfo info;
      list<DAE.Var> vars;

    case (cache,env,ih,_,_,ci_state,(SCode.CLASS(name = "Real")),_,_,_,_)
      equation
        System.setPartialInstantiation(partialInst);
      then (cache,env,ih,ci_state,{});

    case (cache,env,ih,_,_,ci_state,(SCode.CLASS(name = "Integer")),_,_,_,_)
      equation
        System.setPartialInstantiation(partialInst);
      then (cache,env,ih,ci_state,{});

    case (cache,env,ih,_,_,ci_state,(SCode.CLASS(name = "String")),_,_,_,_)
      equation
        System.setPartialInstantiation(partialInst);
      then (cache,env,ih,ci_state,{});

    case (cache,env,ih,_,_,ci_state,(SCode.CLASS(name = "Boolean")),_,_,_,_)
      equation
        System.setPartialInstantiation(partialInst);
      then (cache,env,ih,ci_state,{});

    // BTH
    case (cache,env,ih,_,_,ci_state,(SCode.CLASS(name = "Clock")),_,_,_,_)
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
        System.setPartialInstantiation(partialInst);
      then (cache,env,ih,ci_state,{});

    case (cache,env,ih,mods,pre,ci_state,(c as SCode.CLASS(classDef = d)),vis,inst_dims,_,_)
      equation
        // t1 = clock();

        // str = if_(valueEq(r, SCode.R_PACKAGE()), "", "Instantiating non package: " + FGraph.getGraphNameStr(env) + "/" + n + "\n");
        // print(str);

        (cache,env_1,ih,ci_state_1,vars) =
          partialInstClassdef(cache,env,ih, mods, pre, ci_state, c, d, vis, inst_dims, numIter);

        System.setPartialInstantiation(partialInst);

        // t2 = clock();
        // time = t2 -. t1;
        //b=realGt(time,0.05);
        // s = realString(time);
        // s2 = FGraph.printGraphPathStr(env);
        // fprintln(Flags.INSTTR, "ICLASSPARTIAL " + n + " inst time: " + s + " in env " + s2 + " mods: " + Mod.printModStr(mods));
      then
        (cache,env_1,ih,ci_state_1,vars);

    else
      equation
        System.setPartialInstantiation(partialInst);
      then
        fail();
  end matchcontinue;
end partialInstClassIn_dispatch;

public function instClassdef "
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore store;
  input DAE.Mod inMod2;
  input Prefix.Prefix inPrefix3;
  input ClassInf.State inState5;
  input String className;
  input SCode.ClassDef inClassDef6;
  input SCode.Restriction inRestriction7;
  input SCode.Visibility inVisibility;
  input SCode.Partial inPartialPrefix;
  input SCode.Encapsulated inEncapsulatedPrefix;
  input list<list<DAE.Dimension>> inInstDims9;
  input Boolean inBoolean10;
  input InstTypes.CallingScope inCallingScope;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  input Option<DAE.ComponentRef> instSingleCref;
  input SCode.Comment comment;
  input SourceInfo info;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output list<DAE.Var> outTypesVarLst;
  output Option<DAE.Type> outTypesTypeOption;
  output Option<SCode.Attributes> optDerAttr;
  output DAE.EqualityConstraint outEqualityConstraint;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outStore,outDae,outSets,outState,outTypesVarLst,outTypesTypeOption,optDerAttr,outEqualityConstraint,outGraph):=
  instClassdef2(inCache,inEnv,inIH,store,inMod2,inPrefix3,inState5,className,inClassDef6,inRestriction7,inVisibility,
    inPartialPrefix,inEncapsulatedPrefix,inInstDims9,inBoolean10,inCallingScope,inGraph,inSets,instSingleCref,comment,info,Util.makeStatefulBoolean(false));
end instClassdef;

protected function instClassdefBasicType "
This function will try to instantiate the
class definition as a it would extend a basic
type"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input DAE.Mod inMod2;
  input Prefix.Prefix inPrefix3;
  input ClassInf.State inState5;
  input String className;
  input SCode.ClassDef inClassDef6;
  input SCode.Restriction inRestriction7;
  input SCode.Visibility inVisibility;
  input list<list<DAE.Dimension>> inInstDims9;
  input Boolean inBoolean10;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  input Option<DAE.ComponentRef> instSingleCref;
  input SourceInfo info;
  input Util.StatefulBoolean stopInst "prevent instantiation of classes adding components to primary types";
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output list<DAE.Var> outTypesVarLst;
  output Option<DAE.Type> outTypesTypeOption;
  output Option<SCode.Attributes> optDerAttr;
  output DAE.EqualityConstraint outEqualityConstraint;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outStore,outDae,outSets,outState,outTypesVarLst,outTypesTypeOption,optDerAttr,outEqualityConstraint,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inStore,inMod2,inPrefix3,inState5,className,inClassDef6,inRestriction7,inVisibility,inInstDims9,inBoolean10,inGraph,inSets,instSingleCref,info,stopInst)
    local
      list<SCode.Element> cdefelts,compelts,extendselts,els;
      FCore.Graph env1,env2,env3,env;
      list<tuple<SCode.Element, DAE.Mod>> cdefelts_1,cdefelts_2;
      Connect.Sets csets;
      DAE.DAElist dae1,dae2,dae;
      ClassInf.State ci_state1,ci_state;
      list<DAE.Var> tys;
      Option<DAE.Type> bc;
      DAE.Mod mods;
      Prefix.Prefix pre;
      SCode.Restriction re;
      Boolean impl;
      SCode.Visibility vis;
      InstDims inst_dims;
      FCore.Cache cache;
      DAE.EqualityConstraint eqConstraint;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      UnitAbsyn.InstStore store;

    // This rule describes how to instantiate a class definition
    // that extends a basic type. (No equations or algorithms allowed)
    case (cache,env,ih,store,mods,pre,ci_state,_,
          SCode.PARTS(elementLst = els,
                      normalEquationLst = {}, initialEquationLst = {},
                      normalAlgorithmLst = {}, initialAlgorithmLst = {}),
          _,_,inst_dims,impl,graph,_,_,_,_)
      equation
        // set this to get rid of the error messages that might happen and WE FAIL BEFORE we actually call instBasictypeBaseclass
        ErrorExt.setCheckpoint("instClassdefBasicType1");

        // we should have just ONE extends, but it might have more like one class containing just annotations
        (cdefelts,{},extendselts as _::_ /*{one}*/,compelts) = InstUtil.splitElts(els) "components should be empty, checked in instBasictypeBaseclass type below";
        // adrpo: TODO! DO SOME CHECKS HERE!
        // 1. a type extending basic types cannot have components, and only a function definition (equalityConstraint!)
        // {} = compelts; // no components!

        // adrpo: VERY decisive check!
        //        only CONNECTOR and TYPE can be extended by basic types!
        // true = listMember(re, {SCode.R_TYPE, SCode.R_CONNECTOR(false), SCode.R_CONNECTOR(true)});

        // InstUtil.checkExtendsForTypeRestiction(cache, env, ih, re, extendselts);

        (cache,env1,ih) = InstUtil.addClassdefsToEnv(cache, env, ih, pre, cdefelts, impl, SOME(mods)) "1. CLASS & IMPORT nodes and COMPONENT nodes(add to env)" ;
        cdefelts_1 = InstUtil.addNomod(cdefelts) "instantiate CDEFS so redeclares are carried out" ;
        env2 = env1;
        cdefelts_2 = cdefelts_1;

        //(cache, cdefelts_2) = removeConditionalComponents(cache, env2, cdefelts_2, pre);
        (cache,env3,ih,store,dae1,csets,_,tys,graph) =
          instElementList(cache, env2, ih, store, mods , pre, ci_state,
            cdefelts_2, inst_dims, impl, InstTypes.INNER_CALL(), graph, inSets, true);
        mods = Mod.removeFirstSubsRedecl(mods);

        ErrorExt.rollBack("instClassdefBasicType1"); // rollback before going into instBasictypeBaseclass

        // oh, the horror of backtracking! we need this to make sure that this case failed BEFORE or AFTER it went into instBasictypeBaseclass
        (cache,ih,store,dae2,bc,tys)= instBasictypeBaseclass(cache, env3, ih, store, extendselts, compelts, mods, inst_dims, className, info, stopInst);
        // Search for equalityConstraint
        eqConstraint = InstUtil.equalityConstraint(env3, els, info);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,env3,ih,store,dae,csets,ci_state,tys,bc,NONE(),eqConstraint,graph);

    // VERY COMPLICATED CHECKPOINT! TODO! try to simplify it, maybe by sending Prefix.TYPE and checking in instVar!
    // did the previous
    case (_,_,_,_,_,_,_,_,
          SCode.PARTS(
                      normalEquationLst = {}, initialEquationLst = {},
                      normalAlgorithmLst = {}, initialAlgorithmLst = {}),
          _,_,_,_,_,_,_,_,_)
      equation
        true = ErrorExt.isTopCheckpoint("instClassdefBasicType1");
        ErrorExt.rollBack("instClassdefBasicType1");
      then
        fail();
  end matchcontinue;
end instClassdefBasicType;

protected function instClassdef2 "
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input DAE.Mod inMod2;
  input Prefix.Prefix inPrefix3;
  input ClassInf.State inState5;
  input String className;
  input SCode.ClassDef inClassDef6;
  input SCode.Restriction inRestriction7;
  input SCode.Visibility inVisibility;
  input SCode.Partial inPartialPrefix;
  input SCode.Encapsulated inEncapsulatedPrefix;
  input list<list<DAE.Dimension>> inInstDims9;
  input Boolean inBoolean10;
  input InstTypes.CallingScope inCallingScope;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  input Option<DAE.ComponentRef> instSingleCref;
  input SCode.Comment comment;
  input SourceInfo info;
  input Util.StatefulBoolean stopInst "prevent instantiation of classes adding components to primary types";
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output list<DAE.Var> outTypesVarLst;
  output Option<DAE.Type> oty;
  output Option<SCode.Attributes> optDerAttr;
  output DAE.EqualityConstraint outEqualityConstraint;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outStore,outDae,outSets,outState,outTypesVarLst,oty,optDerAttr,outEqualityConstraint,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inStore,inMod2,inPrefix3,inState5,className,inClassDef6,inRestriction7,inVisibility,inPartialPrefix,inEncapsulatedPrefix,inInstDims9,inBoolean10,inCallingScope,inGraph,inSets,instSingleCref,comment,info,stopInst)
    local
      list<SCode.Element> cdefelts,compelts,extendselts,els,extendsclasselts,compelts_2_elem;
      FCore.Graph env1,env2,env3,env,env4,env5,cenv,cenv_2,env_2,parentEnv;
      list<tuple<SCode.Element, DAE.Mod>> cdefelts_1,extcomps,compelts_1,compelts_2, comp_cond, derivedClassesWithConstantMods;
      Connect.Sets csets,csets1,csets2,csets3,csets4,csets5,csets_1;
      DAE.DAElist dae1,dae2,dae3,dae4,dae5,dae6,dae7,dae;
      ClassInf.State ci_state1,ci_state,ci_state2,ci_state3,ci_state4,ci_state5,ci_state6,ci_state7,new_ci_state,ci_state_1;
      list<DAE.Var> vars;
      Option<DAE.Type> bc;
      DAE.Mod mods,emods,mod_1,mods_1,checkMods;
      Prefix.Prefix pre;
      list<SCode.Equation> eqs,initeqs,eqs2,initeqs2,eqs_1,initeqs_1,expandableEqs;
      list<SCode.AlgorithmSection> alg,initalg,alg2,initalg2,alg_1,initalg_1;
      list<SCode.ConstraintSection> constrs;
      list<Absyn.NamedArg> clsattrs;
      SCode.Restriction re,r;
      Boolean impl, valid_connector;
      SCode.Visibility vis;
      SCode.Encapsulated enc2;
      SCode.Partial partialPrefix;
      SCode.Encapsulated encapsulatedPrefix;
      InstDims inst_dims,inst_dims_1;
      list<DAE.Subscript> inst_dims2;
      String cn2,cns,scope_str,s,str;
      SCode.Element c;
      SCode.ClassDef classDef;
      Option<DAE.EqMod> eq;
      DAE.Dimensions dims;
      Absyn.Path cn;
      Option<list<Absyn.Subscript>> ad;
      SCode.Mod mod;
      FCore.Cache cache;
      Option<SCode.Attributes> oDA;
      DAE.EqualityConstraint eqConstraint;
      InstTypes.CallingScope callscope;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      DAE.DAElist fdae;
      Boolean unrollForLoops, zero_dims;
      SourceInfo info2;
      list<Absyn.TypeSpec> tSpecs;
      list<DAE.Type> tys;
      SCode.Attributes DA;
      DAE.Type ty;
      Absyn.TypeSpec tSpec;
      Option<SCode.Comment> cmt;
      UnitAbsyn.InstStore store;
      Option<SCode.ExternalDecl> ed;
      DAE.ElementSource elementSource;
      list<Absyn.Subscript> adno;
      list<DAE.ComponentRef> smCompCrefs "state machine components crefs";
      list<DAE.ComponentRef> smInitialCrefs "state machine crefs of initial states";
      FCore.Ref lastRef;
      InstStateMachineUtil.SMNodeToFlatSMGroupTable smCompToFlatSM;

    /*// uncomment for debugging
    case (cache,env,ih,store,mods,pre,csets,ci_state,className,inClassDef6,
          re,vis,_,_,inst_dims,impl,_,graph,instSingleCref,info,stopInst)
      equation
        // fprintln(Flags.INST_TRACE, "ICD BEGIN: " + FGraph.printGraphPathStr(env) + " cn:" + className + " mods: " + Mod.printModStr(mods));
      then
        fail();*/

    // This rule describes how to instantiate a class definition
    // that extends a basic type. (No equations or algorithms allowed)
    case (cache,env,ih,store,mods,pre,ci_state,_,
          SCode.PARTS(elementLst = els,
                      normalEquationLst = {}, initialEquationLst = {},
                      normalAlgorithmLst = {}, initialAlgorithmLst = {}),
          re,vis,_,_,inst_dims,impl,_,graph,_,_,_,_,_)
      equation
        false = Util.getStatefulBoolean(stopInst);
        // adpro: if is a model, package, function, external function, record is not a basic type!
        false = valueEq(SCode.R_MODEL(), re);
        false = valueEq(SCode.R_PACKAGE(), re);
        false = SCode.isFunctionRestriction(re);
        false = valueEq(SCode.R_RECORD(true), re);
        false = valueEq(SCode.R_RECORD(false), re);
        // no components and at least one extends!

        (cdefelts,extendsclasselts,extendselts as _::_,{}) = InstUtil.splitElts(els);
        extendselts = SCodeUtil.addRedeclareAsElementsToExtends(extendselts, List.select(els, SCodeUtil.isRedeclareElement));
        (cache,env1,ih) = InstUtil.addClassdefsToEnv(cache, env, ih, pre, cdefelts, impl, SOME(mods));
        (cache,_,_,_,extcomps,{},{},{},{}) =
        InstExtends.instExtendsAndClassExtendsList(cache, env1, ih, mods, pre, extendselts, extendsclasselts, els, ci_state, className, impl, false);

        compelts_2_elem = List.map(extcomps,Util.tuple21);
        // no components from the extends!
        (_, _, _, {}) = InstUtil.splitElts(compelts_2_elem);

        (cache,env,ih,store,fdae,csets,ci_state,vars,bc,oDA,eqConstraint,graph) =
          instClassdefBasicType(cache,env,ih,store,mods,pre,ci_state,className,inClassDef6,re,vis,inst_dims,impl,graph,
            inSets, instSingleCref,info,stopInst);
      then
        (cache,env,ih,store,fdae,csets,ci_state,vars,bc,oDA,eqConstraint,graph);

    /*// uncomment for debugging
    case (cache,env,ih,store,mods,pre,csets,ci_state,className,inClassDef6,
          re,vis,_,_,inst_dims,impl,_,graph,instSingleCref,info,stopInst)
      equation
        // fprintln(Flags.INST_TRACE, "ICD AFTER BASIC TYPE: " + FGraph.printGraphPathStr(env) + " cn:" + className + " mods: " + Mod.printModStr(mods));
      then
        fail();*/

    // This case instantiates external objects. An external object inherits from ExternalObject
    // and have two local functions: constructor and destructor (and no other elements).
    case (cache,env,ih,store,mods,_,ci_state,_,
          SCode.PARTS(elementLst = els),
          _,_,_,_,_,impl,_,graph,_,_,_,_,_)
      equation
        false = Util.getStatefulBoolean(stopInst);
         true = SCode.isExternalObject(els);
         (cache,env,ih,dae,ci_state) = InstFunction.instantiateExternalObject(cache,env,ih,els,mods,impl,comment,info);
      then
        (cache,env,ih,store,dae,inSets,ci_state,{},NONE(),NONE(),NONE(),graph);

    // This rule describes how to instantiate an explicit class definition, i.e. made of parts!
    case (cache,env,ih,store,mods,pre,ci_state,_,
          SCode.PARTS(elementLst = els,
                      normalEquationLst = eqs, initialEquationLst = initeqs,
                      normalAlgorithmLst = alg, initialAlgorithmLst = initalg,
                      constraintLst = constrs, clsattrs = clsattrs, externalDecl = ed
                      ),
        re,_,_,_,inst_dims,impl,callscope,graph,csets,_,_,_,_)
      equation
        false = Util.getStatefulBoolean(stopInst);
        false = SCode.isExternalObject(els);
        if Flags.getConfigBool(Flags.UNIT_CHECKING) then
          UnitParserExt.checkpoint();
        end if;
        //Debug.traceln(" Instclassdef for: " + PrefixUtil.printPrefixStr(pre) + "." +  className + " mods: " + Mod.printModStr(mods));
        ci_state1 = ClassInf.trans(ci_state, ClassInf.NEWDEF());
        els = InstUtil.extractConstantPlusDeps(els,instSingleCref,{},className);

        // split elements
        (cdefelts,extendsclasselts,extendselts,compelts) = InstUtil.splitElts(els);

        // remove components from expandable connectors
        // compelts = if_(valueEq(re, SCode.R_CONNECTOR(true)), {}, compelts);

        extendselts = SCodeUtil.addRedeclareAsElementsToExtends(extendselts, List.select(els, SCodeUtil.isRedeclareElement));

        (cache, env1,ih) = InstUtil.addClassdefsToEnv(cache, env, ih, pre, cdefelts, impl, SOME(mods));


        //// fprintln(Flags.INST_TRACE, "after InstUtil.addClassdefsToEnv ENV: " + if_(stringEq(className, "PortVolume"), FGraph.printGraphStr(env1), " no env print "));

        // adrpo: TODO! DO SOME CHECKS HERE!
        // restriction on what can inherit what, see 7.1.3 Restrictions on the Kind of Base Class
        // if a type   -> no components, can extends only another type
        // if a record -> components ok
        // checkRestrictionsOnTheKindOfBaseClass(cache, env, ih, re, extendselts);

        (cache,env2,ih,emods,extcomps,eqs2,initeqs2,alg2,initalg2) =
        InstExtends.instExtendsAndClassExtendsList(cache, env1, ih, mods, pre, extendselts, extendsclasselts, els, ci_state, className, impl, false)
        "2. EXTENDS Nodes inst_extends_list only flatten inhteritance structure. It does not perform component instantiations.";

        // print("Extended Elements inst:\n" + InstUtil.printElementAndModList(extcomps));

        //fprint(Flags.INST_EXT_TRACE, "EXTENDS RETURNS:\n" + Debug.fcallret1(Flags.INST_EXT_TRACE, printElementAndModList, extcomps, "") + "\n");
        //fprint(Flags.INST_EXT_TRACE, "EXTENDS RETURNS EMODS: " + Mod.printModStr(emods) + "\n");

        compelts_1 = InstUtil.addNomod(compelts)
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

        cdefelts_1 = InstUtil.addNomod(cdefelts);

        // Add components from base classes to be instantiated in 3 as well.
        compelts_1 = List.flatten({extcomps,compelts_1,cdefelts_1});

        // Add equation and algorithm sections from base classes.
        eqs_1 = joinExtEquations(eqs, eqs2, callscope);
        initeqs_1 = joinExtEquations(initeqs, initeqs2, callscope);
        alg_1 = joinExtAlgorithms(alg, alg2, callscope);
        initalg_1 = joinExtAlgorithms(initalg, initalg2, callscope);

        (compelts_1, eqs_1, initeqs_1, alg_1, initalg_1) =
          InstUtil.extractConstantPlusDepsTpl(compelts_1, instSingleCref, {}, className, eqs_1, initeqs_1, alg_1, initalg_1);

        //(csets, env2, ih) = InstUtil.addConnectionCrefsFromEqs(csets, eqs_1, pre, env2, ih);

        //// fprintln(Flags.INST_TRACE, "Emods to InstUtil.addComponentsToEnv: " + Mod.printModStr(emods));

        //Add variables to env, wihtout type and binding, which will be added
        //later in instElementList (where update_variable is called)"
        checkMods = Mod.merge(mods,emods,env2,pre);
        mods = checkMods;
        (cache,env3,ih) = InstUtil.addComponentsToEnv(cache, env2, ih, mods, pre, ci_state, compelts_1, compelts_1, eqs_1, inst_dims, impl);
        //Update the modifiers of elements to typed ones, needed for modifiers
        //on components that are inherited.
        compelts_2 = compelts_1;
        env4 = env3;

        //compelts_1 = InstUtil.addNomod(compelts);
        //cdefelts_1 = InstUtil.addNomod(cdefelts);
        //compelts_2 = List.flatten({compelts_2, compelts_1, cdefelts_1});

        //Instantiate components
        compelts_2_elem = List.map(compelts_2,Util.tuple21);

        // fprintln(Flags.INNER_OUTER, "Number of components: " + intString(listLength(compelts_2_elem)));
        // fprintln(Flags.INNER_OUTER, stringDelimitList(List.map(compelts_2_elem, SCodeDump.printElementStr), "\n"));

        //print("To match modifiers,\n" + Mod.printModStr(checkMods) + "\n on components: ");
        //print(" (" + stringDelimitList(List.map(compelts_2_elem,SCode.elementName),", ") + ") \n");
        InstUtil.matchModificationToComponents(compelts_2_elem,checkMods,FGraph.printGraphPathStr(env4));

        // Move any conditional components to the end of the component list, to
        // make sure that any dependencies of the condition are instantiated first.
        (comp_cond, compelts_2) = List.splitOnTrue(compelts_2, InstUtil.componentHasCondition);
        compelts_2 = listAppend(compelts_2, comp_cond);

        // BTH: Search for state machine components and update ih correspondingly.
        (smCompCrefs, smInitialCrefs) = InstStateMachineUtil.getSMStatesInContext(eqs_1, pre);
        //ih = List.fold1(smCompCrefs, InnerOuter.updateSMHierarchy, inPrefix3, ih);
        ih = List.fold(smCompCrefs, InnerOuter.updateSMHierarchy, ih);

        (cache,env5,ih,store,dae1,csets,ci_state2,vars,graph) =
          instElementList(cache, env4, ih, store, mods, pre, ci_state1,
            compelts_2, inst_dims, impl, callscope, graph, csets, true);

        // If we are currently instantiating a connector, add all flow variables
        // in it as inside connectors.
        zero_dims = InstUtil.instDimsHasZeroDims(inst_dims);
        elementSource = DAEUtil.createElementSource(info, FGraph.getScopePath(env4), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        csets1 = ConnectUtil.addConnectorVariablesFromDAE(zero_dims, ci_state1, pre, vars, csets, info, elementSource);

        // Reorder the connect equations to have non-expandable connect first:
        //   connect(non_expandable, non_expandable);
        //   connect(non_expandable, expandable);
        //   connect(expandable, non_expandable);
        //   connect(expandable, expandable);
        ErrorExt.setCheckpoint("expandableConnectorsOrder");
        (cache, eqs_1, expandableEqs) = InstUtil.splitConnectEquationsExpandable(cache, env5, ih, pre, eqs_1, impl, {}, {});
        // put expandable at the begining
        eqs_1 = List.appendNoCopy(expandableEqs, eqs_1);
        // put expandable at the end
        eqs_1 = List.appendNoCopy(eqs_1, expandableEqs);
        // duplicate expandable to get the union
        eqs_1 = InstUtil.addExpandable(eqs_1, expandableEqs);
        ErrorExt.rollBack("expandableConnectorsOrder");

        //Instantiate equations (see function "instEquation")
        (cache,env5,ih,dae2,csets2,ci_state3,graph) =
          instList(cache, env5, ih, pre, csets1, ci_state2, InstSection.instEquation, eqs_1, impl, InstTypes.alwaysUnroll, graph);
        DAEUtil.verifyEquationsDAE(dae2);

        //Instantiate inital equations (see function "instInitialEquation")
        (cache,env5,ih,dae3,csets3,ci_state4,graph) =
          instList(cache, env5, ih, pre, csets2, ci_state3, InstSection.instInitialEquation, initeqs_1, impl, InstTypes.alwaysUnroll, graph);

        // do NOT unroll for loops for functions!
        unrollForLoops = if SCode.isFunctionRestriction(re) then InstTypes.neverUnroll else InstTypes.alwaysUnroll;

        //Instantiate algorithms  (see function "instAlgorithm")
        (cache,env5,ih,dae4,csets4,ci_state5,graph) =
          instList(cache,env5,ih, pre, csets3, ci_state4, InstSection.instAlgorithm, alg_1, impl, unrollForLoops, graph);

        //Instantiate algorithms  (see function "instInitialAlgorithm")
        (cache,env5,ih,dae5,csets5,ci_state6,graph) =
          instList(cache,env5,ih, pre, csets4, ci_state5, InstSection.instInitialAlgorithm, initalg_1, impl, unrollForLoops, graph);

        //Instantiate/Translate class Attributes (currently only allowed for Optimica extensions)
        (cache,env5,dae6) =
          instClassAttributes(cache,env5, pre, clsattrs, impl,info);

        //Instantiate Constraints  (see function "instConstraints")
        (cache,env5,dae7,_) =
          instConstraints(cache,env5, pre, ci_state6, constrs, impl);

        // BTH: Relate state machine components to the flat state machine that they are part of
        smCompToFlatSM = InstStateMachineUtil.createSMNodeToFlatSMGroupTable(dae2);
        // BTH: Wrap state machine components (including transition statements) into corresponding flat state machine containers
        (dae1,dae2) = InstStateMachineUtil.wrapSMCompsInFlatSMs(ih, dae1, dae2, smCompToFlatSM, smInitialCrefs);

        //Collect the DAE's
        dae = DAEUtil.joinDaeLst({dae1,dae2,dae3,dae4,dae5,dae6,dae7});

        //Change outer references to corresponding inner reference
        // adrpo: TODO! FIXME! very very very expensive function, try to get rid of it!
        //t1 = clock();
        //(dae,csets5,ih,graph) = InnerOuter.changeOuterReferences(dae,csets5,ih,graph);
        //t2 = clock();
        //ti = t2 -. t1;
        //fprintln(Flags.INNER_OUTER, " INST_CLASS: (" + realString(ti) + ") -> " + PrefixUtil.printPrefixStr(pre) + "." +  className + " mods: " + Mod.printModStr(mods) + " in env: " + FGraph.printGraphPathStr(env7));

        csets5 = InnerOuter.changeInnerOuterInOuterConnect(csets5);

        // adrpo: moved bunch of a lot of expensive unit checking operations to this function
        (cache,env5,store) = InstUtil.handleUnitChecking(cache,env5,store,pre,dae1,{dae2,dae3,dae4,dae5},className);

        if Flags.getConfigBool(Flags.UNIT_CHECKING) then
          UnitParserExt.rollback(); // print("rollback for "+className+"\n");
        end if;

        // Search for equalityConstraint
        eqConstraint = InstUtil.equalityConstraint(env5, els, info);
        ci_state6 = if isSome(ed) then ClassInf.assertTrans(ci_state6,ClassInf.FOUND_EXT_DECL(),info) else ci_state6;
        (cache,oty) = MetaUtil.fixUniontype(cache, env5, ci_state6, inClassDef6);
      then
        (cache,env5,ih,store,dae,csets5,ci_state6,vars,oty,NONE(),eqConstraint,graph);

    // This rule describes how to instantiate class definition derived from an enumeration
    case (cache,env,ih,store,mods,pre,_,_,
          SCode.DERIVED(Absyn.TPATH(path = cn,arrayDim = ad),modifications = mod,attributes=DA),
          re,vis,_,_,inst_dims,impl,callscope,graph,_,_,_,_,_)
      equation
        false = Util.getStatefulBoolean(stopInst);

        (cache,(c as SCode.CLASS(name=cn2,encapsulatedPrefix=enc2,restriction=r as SCode.R_ENUMERATION())), cenv) =
          Lookup.lookupClass(cache, env, cn, true);

        // keep the old behaviour
        env3 = FGraph.openScope(cenv, enc2, SOME(cn2), SOME(FCore.CLASS_SCOPE()));
        ci_state2 = ClassInf.start(r, FGraph.getGraphName(env3));
        new_ci_state = ClassInf.start(r, FGraph.getGraphName(env3));

        // print("Enum Env: " + FGraph.printGraphPathStr(env3) + "\n");
        (cache,cenv_2,_,_,_,_,_,_,_,_,_,_) =
        instClassIn(
          cache,env3,InnerOuter.emptyInstHierarchy,UnitAbsyn.noStore,
          DAE.NOMOD(), Prefix.NOPRE(), ci_state2, c, SCode.PUBLIC(), {}, false,
          callscope, ConnectionGraph.EMPTY, Connect.emptySet, NONE());

        (cache,mod_1) = Mod.elabMod(cache, cenv_2, ih, pre, mod, impl, Mod.DERIVED(cn), info);

        mods_1 = Mod.merge(mods, mod_1, cenv_2, pre);
        eq = Mod.modEquation(mods_1) "instantiate array dimensions" ;
        (cache,dims) = InstUtil.elabArraydimOpt(cache,cenv_2, Absyn.CREF_IDENT("",{}),cn, ad, eq, impl,NONE(),true,pre,info,inst_dims) "owncref not valid here" ;
        // inst_dims2 = InstUtil.instDimExpLst(dims, impl);
        inst_dims_1 = List.appendLastList(inst_dims, dims);

        (cache,env_2,ih,store,dae,csets_1,ci_state_1,vars,bc,oDA,eqConstraint,graph) = instClassIn(cache, cenv_2, ih, store, mods_1, pre, new_ci_state, c, vis,
          inst_dims_1, impl, callscope, graph, inSets, instSingleCref) "instantiate class in opened scope.";
        ClassInf.assertValid(ci_state_1, re, info) "Check for restriction violations";
        oDA = SCode.mergeAttributes(DA,oDA);
      then
        (cache,env_2,ih,store,dae,csets_1,ci_state_1,vars,bc,oDA,eqConstraint,graph);

    // This rule describes how to instantiate a derived class definition from basic types
    case (cache,env,ih,store,mods,pre,ci_state,_,
          SCode.DERIVED(Absyn.TPATH(path = cn,arrayDim = ad),modifications = mod,attributes=DA),
          re,vis,_,_,inst_dims,impl,callscope,graph,_,_,_,_,_)
      equation
        false = Util.getStatefulBoolean(stopInst);

        (cache,(c as SCode.CLASS(name=cn2,encapsulatedPrefix=enc2,restriction=r)),cenv) = Lookup.lookupClass(cache, env, cn, true);

        // if is a basic type or derived from it, follow the normal path
        true = InstUtil.checkDerivedRestriction(re, r, cn2);

        // If it's a connector, check that it's valid.
        valid_connector = ConnectUtil.checkShortConnectorDef(ci_state, DA, info);
        Util.setStatefulBoolean(stopInst, not valid_connector);
        true = valid_connector;

        cenv_2 = FGraph.openScope(cenv, enc2, SOME(cn2), FGraph.classInfToScopeType(ci_state));
        new_ci_state = ClassInf.start(r, FGraph.getGraphName(cenv_2));

        // chain the redeclares
        mod = InstUtil.chainRedeclares(mods, mod);

        // elab the modifiers in the parent environment!
        (parentEnv, _) = FGraph.stripLastScopeRef(env);
        (cache,mod_1) = Mod.elabMod(cache, parentEnv, ih, pre, mod, impl, Mod.DERIVED(cn), info);
        mods_1 = Mod.merge(mods, mod_1, parentEnv, pre);

        eq = Mod.modEquation(mods_1) "instantiate array dimensions";
        (cache,dims) = InstUtil.elabArraydimOpt(cache, parentEnv, Absyn.CREF_IDENT("",{}), cn, ad, eq, impl, NONE(), true, pre, info, inst_dims) "owncref not valid here" ;
        // inst_dims2 = InstUtil.instDimExpLst(dims, impl);
        inst_dims_1 = List.appendLastList(inst_dims, dims);

        _ = Absyn.getArrayDimOptAsList(ad);
        (cache,env_2,ih,store,dae,csets_1,ci_state_1,vars,bc,oDA,eqConstraint,graph) = instClassIn(cache, cenv_2, ih, store, mods_1, pre, new_ci_state, c, vis,
          inst_dims_1, impl, callscope, graph, inSets, instSingleCref) "instantiate class in opened scope. " ;

        ClassInf.assertValid(ci_state_1, re, info) "Check for restriction violations" ;
        oDA = SCode.mergeAttributes(DA,oDA);
      then
        (cache,env_2,ih,store,dae,csets_1,ci_state_1,vars,bc,oDA,eqConstraint,graph);

    // This rule describes how to instantiate a derived class definition without array dims
    case (cache,env,ih,store,mods,pre,ci_state,_,
          SCode.DERIVED(typeSpec = Absyn.TPATH(path = cn,arrayDim = ad), modifications = mod, attributes=DA),
          re,vis,partialPrefix,encapsulatedPrefix,inst_dims,impl,callscope,graph,_,_,_,_,_)
      equation
        // don't enter here
        // false = true;
        false = Util.getStatefulBoolean(stopInst);

        // no meta-modelica
        // false = Config.acceptMetaModelicaGrammar();
        // no types, enums or connectors please!
        false = valueEq(re, SCode.R_TYPE());
        // false = SCode.isFunctionRestriction(re);
        false = valueEq(re, SCode.R_ENUMERATION());
        false = valueEq(re, SCode.R_PREDEFINED_ENUMERATION());
        false = SCode.isConnector(re);
        // check empty array dimensions
        true = boolOr(valueEq(ad, NONE()), valueEq(ad, SOME({})));
        (cache,SCode.CLASS(name=cn2,restriction=r),_) = Lookup.lookupClass(cache, env, cn, true);

        false = InstUtil.checkDerivedRestriction(re, r, cn2);

        // chain the redeclares
        mod = InstUtil.chainRedeclares(mods, mod);

        // elab the modifiers in the parent environment!!
        (parentEnv,_) = FGraph.stripLastScopeRef(env);
        // adrpo: as we do this IN THE SAME ENVIRONMENT (no open scope), clone it before doing changes
        // env = FGraph.pushScopeRef(parentEnv, FNode.copyRefNoUpdate(lastRef));
        (cache, mod_1) = Mod.elabMod(cache, parentEnv, ih, pre, mod, false, Mod.DERIVED(cn), info);
        // print("mods: " + Absyn.pathString(cn) + " " + Mod.printModStr(mods_1) + "\n");
        mods_1 = Mod.merge(mods, mod_1, parentEnv, pre);

        //print("DEF:--->" + FGraph.printGraphPathStr(env) + " = " + Absyn.pathString(cn) + " mods: " + Mod.printModStr(mods_1) + "\n");
        //System.startTimer();
        // use instExtends for derived with no array dimensions and no modification (given via the mods_1)
        (cache, env, ih, store, dae, csets, ci_state, vars, bc, oDA, eqConstraint, graph) =
        instClassdef2(cache, env, ih, store, mods_1, pre, ci_state, className,
           SCode.PARTS({SCode.EXTENDS(cn, vis, SCode.NOMOD(), NONE(), info)},{},{},{},{},{},{},NONE()),
           re, vis, partialPrefix, encapsulatedPrefix, inst_dims, impl,
           callscope, graph, inSets, instSingleCref,comment,info,stopInst);
        //System.stopTimer();
        //print("DEF:<---" + FGraph.printGraphPathStr(env) + " took: " + realString(System.getTimerIntervalTime()) + "\n");
        oDA = SCode.mergeAttributes(DA,oDA);
      then
        (cache,env,ih,store,dae,csets,ci_state,vars,bc,oDA,eqConstraint,graph);

    // This rule describes how to instantiate a derived class definition with array dims
    case (cache,env,ih,store,mods,pre,ci_state,_,
          SCode.DERIVED(Absyn.TPATH(path = cn,arrayDim = ad),modifications = mod,attributes=DA),
          re,vis,_,_,inst_dims,impl,callscope,graph,_,_,_,_,_)
      equation
        false = Util.getStatefulBoolean(stopInst);
        (cache,(c as SCode.CLASS(name=cn2,encapsulatedPrefix=enc2,restriction=r)),cenv) = Lookup.lookupClass(cache, env, cn, true);

        // not a basic type, change class name!
        false = InstUtil.checkDerivedRestriction(re, r, cn2);

        // change the class name to className!!
        // package A2=A
        // package A3=A(mods)
        // will get you different function implementations for the different packages!
        /*
        fullEnvPath = Absyn.selectPathsOpt(FGraph.getScopePath(env), Absyn.IDENT(""));
        fullClassName = "DE_" + Absyn.pathStringReplaceDot(fullEnvPath, "_") + "_D_" +
                        Absyn.pathStringReplaceDot(Absyn.selectPathsOpt(FGraph.getScopePath(cenv), Absyn.IDENT("")), "_" ) + "." + cn2 + "_ED";
        fullClassName = System.stringReplace(fullClassName, ".", "_");

        // open a scope with a unique name in the base class environment so there is no collision
        cenv_2 = FGraph.openScope(cenv, enc2, SOME(fullClassName), FGraph.classInfToScopeType(ci_state));
        new_ci_state = ClassInf.start(r, FGraph.getGraphName(cenv_2));
        */
        // open a scope with the correct name

        // className = className + "|" + PrefixUtil.printPrefixStr(pre) + "|" + cn2;

        cenv_2 = FGraph.openScope(cenv, enc2, SOME(className), FGraph.classInfToScopeType(ci_state));
        new_ci_state = ClassInf.start(r, FGraph.getGraphName(cenv_2));

        c = SCode.setClassName(className, c);

        //print("Derived Env: " + FGraph.printGraphPathStr(cenv_2) + "\n");

        // chain the redeclares
        mod = InstUtil.chainRedeclares(mods, mod);

        // elab the modifiers in the parent environment!
        (parentEnv, _) = FGraph.stripLastScopeRef(env);
        (cache,mod_1) = Mod.elabMod(cache, parentEnv, ih, pre, mod, impl, Mod.DERIVED(cn), info);
        mods_1 = Mod.merge(mods, mod_1, parentEnv, pre);

        eq = Mod.modEquation(mods_1) "instantiate array dimensions" ;
        (cache,dims) = InstUtil.elabArraydimOpt(cache, parentEnv, Absyn.CREF_IDENT("",{}), cn, ad, eq, impl, NONE(), true, pre, info, inst_dims) "owncref not valid here" ;
        // inst_dims2 = InstUtil.instDimExpLst(dims, impl);
        inst_dims_1 = List.appendLastList(inst_dims, dims);

        _ = Absyn.getArrayDimOptAsList(ad);
        (cache,env_2,ih,store,dae,csets_1,ci_state_1,vars,bc,oDA,eqConstraint,graph) = instClassIn(cache, cenv_2, ih, store, mods_1, pre, new_ci_state, c, vis,
            inst_dims_1, impl, callscope, graph, inSets, instSingleCref) "instantiate class in opened scope. " ;

        ClassInf.assertValid(ci_state_1, re, info) "Check for restriction violations" ;
        oDA = SCode.mergeAttributes(DA,oDA);
      then
        (cache,env_2,ih,store,dae,csets_1,ci_state_1,vars,bc,oDA,eqConstraint,graph);

    // MetaModelica extension
    case (_,_,_,_,mods,_,_,_,
          SCode.DERIVED(Absyn.TCOMPLEX(),modifications = mod),
          _,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        false = Mod.emptyModOrEquality(mods) and SCode.emptyModOrEquality(mod);
        Error.addSourceMessage(Error.META_COMPLEX_TYPE_MOD, {}, info);
      then fail();

    case (cache,env,ih,store,mods,pre,_,_,
          SCode.DERIVED(Absyn.TCOMPLEX(Absyn.IDENT("list"),{tSpec},NONE()),modifications = mod, attributes=DA),
          _,_,_,_,inst_dims,impl,_,graph,_,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        false = Util.getStatefulBoolean(stopInst);
        true = Mod.emptyModOrEquality(mods) and SCode.emptyModOrEquality(mod);
        (cache,_,ih,tys,csets,oDA) =
        instClassDefHelper(cache,env,ih,{tSpec},pre,inst_dims,impl,{}, inSets);
        ty = listHead(tys);
        ty = Types.boxIfUnboxedType(ty);
        bc = SOME(DAE.T_METALIST(ty,DAE.emptyTypeSource));
        oDA = SCode.mergeAttributes(DA,oDA);
      then (cache,env,ih,store,DAE.emptyDae,csets,ClassInf.META_LIST(Absyn.IDENT("")),{},bc,oDA,NONE(),graph);

    case (cache,env,ih,store,mods,pre,_,_,
          SCode.DERIVED(Absyn.TCOMPLEX(Absyn.IDENT("Option"),{tSpec},NONE()),modifications = mod, attributes=DA),
          _,_,_,_,inst_dims,impl,_,graph,_,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        false = Util.getStatefulBoolean(stopInst);
        true = Mod.emptyModOrEquality(mods) and SCode.emptyModOrEquality(mod);
        (cache,_,ih,{ty},csets,oDA) =
        instClassDefHelper(cache,env,ih,{tSpec},pre,inst_dims,impl,{}, inSets);
        ty = Types.boxIfUnboxedType(ty);
        bc = SOME(DAE.T_METAOPTION(ty,DAE.emptyTypeSource));
        oDA = SCode.mergeAttributes(DA,oDA);
      then (cache,env,ih,store,DAE.emptyDae,csets,ClassInf.META_OPTION(Absyn.IDENT("")),{},bc,oDA,NONE(),graph);

    case (cache,env,ih,store,mods,pre,_,_,
          SCode.DERIVED(Absyn.TCOMPLEX(Absyn.IDENT("tuple"),tSpecs,NONE()),modifications = mod, attributes=DA),
          _,_,_,_,inst_dims,impl,_,graph,_,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        false = Util.getStatefulBoolean(stopInst);
        true = Mod.emptyModOrEquality(mods) and SCode.emptyModOrEquality(mod);
        (cache,_,ih,tys,csets,oDA) = instClassDefHelper(cache,env,ih,tSpecs,pre,inst_dims,impl,{}, inSets);
        tys = List.map(tys, Types.boxIfUnboxedType);
        bc = SOME(DAE.T_METATUPLE(tys,DAE.emptyTypeSource));
        oDA = SCode.mergeAttributes(DA,oDA);
      then (cache,env,ih,store,DAE.emptyDae,csets,ClassInf.META_TUPLE(Absyn.IDENT("")),{},bc,oDA,NONE(),graph);

    case (cache,env,ih,store,mods,pre,_,_,
          SCode.DERIVED(Absyn.TCOMPLEX(Absyn.IDENT("array"),{tSpec},NONE()),modifications = mod, attributes=DA),
          _,_,_,_,inst_dims,impl,_,graph,_,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        false = Util.getStatefulBoolean(stopInst);
        true = Mod.emptyModOrEquality(mods) and SCode.emptyModOrEquality(mod);
        (cache,_,ih,{ty},csets,oDA) = instClassDefHelper(cache,env,ih,{tSpec},pre,inst_dims,impl,{}, inSets);
        ty = Types.boxIfUnboxedType(ty);
        bc = SOME(DAE.T_METAARRAY(ty,DAE.emptyTypeSource));
        oDA = SCode.mergeAttributes(DA,oDA);
      then (cache,env,ih,store,DAE.emptyDae,csets,ClassInf.META_ARRAY(Absyn.IDENT(className)),{},bc,oDA,NONE(),graph);

    case (cache,env,ih,store,mods,pre,_,_,
          SCode.DERIVED(Absyn.TCOMPLEX(Absyn.IDENT("polymorphic"),{Absyn.TPATH(Absyn.IDENT("Any"),NONE())},NONE()),modifications = mod, attributes=DA),
          _,_,_,_,inst_dims,impl,_,graph,_,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        false = Util.getStatefulBoolean(stopInst);
        true = Mod.emptyModOrEquality(mods) and SCode.emptyModOrEquality(mod);
        (cache,_,ih,_,csets,oDA) = instClassDefHelper(cache,env,ih,{},pre,inst_dims,impl,{}, inSets);
        bc = SOME(DAE.T_METAPOLYMORPHIC(className,DAE.emptyTypeSource));
        oDA = SCode.mergeAttributes(DA,oDA);
      then (cache,env,ih,store,DAE.emptyDae,csets,ClassInf.META_POLYMORPHIC(Absyn.IDENT(className)),{},bc,oDA,NONE(),graph);

    case (_,_,_,_,mods,_,_,_,
          SCode.DERIVED(typeSpec=Absyn.TCOMPLEX(path=Absyn.IDENT("polymorphic")),modifications=mod),
          _,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        true = Mod.emptyModOrEquality(mods) and SCode.emptyModOrEquality(mod);
        Error.addSourceMessage(Error.META_POLYMORPHIC, {className}, info);
      then fail();

    case (_,_,_,_,_,_,_,_,
          SCode.DERIVED(typeSpec=tSpec as Absyn.TCOMPLEX(arrayDim=SOME(_))),
          _,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        cns = Dump.unparseTypeSpec(tSpec);
        Error.addSourceMessage(Error.META_INVALID_COMPLEX_TYPE, {cns}, info);
      then fail();

    case (cache,env,ih,store,mods,pre,ci_state,_,
          SCode.DERIVED(Absyn.TCOMPLEX(Absyn.IDENT(str),tSpecs,NONE()),modifications = mod, attributes=DA),
          re,vis,partialPrefix,encapsulatedPrefix,inst_dims,impl,_,graph,_,_,_,_,_)
      equation
        str = Util.assoc(str,{("List","list"),("Tuple","tuple"),("Array","array")});
        (outCache,outEnv,outIH,outStore,outDae,outSets,outState,outTypesVarLst,oty,optDerAttr,outEqualityConstraint,outGraph)
        = instClassdef2(cache,env,ih,store,mods,pre,ci_state,className,SCode.DERIVED(Absyn.TCOMPLEX(Absyn.IDENT(str),tSpecs,NONE()),mod,DA),re,vis,partialPrefix,encapsulatedPrefix,inst_dims,impl,inCallingScope,graph,inSets,instSingleCref,comment,info,stopInst);
      then (outCache,outEnv,outIH,outStore,outDae,outSets,outState,outTypesVarLst,oty,optDerAttr,outEqualityConstraint,outGraph);

    case (_,_,_,_,_,_,_,_,
          SCode.DERIVED(typeSpec=tSpec as Absyn.TCOMPLEX(path=cn,typeSpecs=tSpecs)),
          _,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        false = listMember((Absyn.pathString(cn),listLength(tSpecs)==1), {("tuple",false),("array",true),("Option",true),("list",true)});
        cns = Dump.unparseTypeSpec(tSpec);
        Error.addSourceMessage(Error.META_INVALID_COMPLEX_TYPE, {cns}, info);
      then fail();

    /* ----------------------- */

    /* If the class is derived from a class that can not be found in the environment, this rule prints an error message. */
    case (cache,env,_,_,_,_,_,_,
          SCode.DERIVED(Absyn.TPATH(path = cn)),
          _,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        false = Util.getStatefulBoolean(stopInst);
        failure((_,_,_) = Lookup.lookupClass(cache,env, cn, false));
        cns = Absyn.pathString(cn);
        scope_str = FGraph.printGraphPathStr(env);
        Error.addSourceMessage(Error.LOOKUP_ERROR, {cns,scope_str}, info);
      then
        fail();

    case (cache,env,_,_,_,_,_,_,
          SCode.DERIVED(Absyn.TPATH(path = cn)),
          _,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        failure((_,_,_) = Lookup.lookupClass(cache,env, cn, false));
        Debug.trace("- Inst.instClassdef DERIVED( ");
        Debug.trace(Absyn.pathString(cn));
        Debug.trace(") lookup failed\n ENV:");
        Debug.trace(FGraph.printGraphStr(env));
      then
        fail();

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Inst.instClassdef failed");
        s = FGraph.printGraphPathStr(inEnv);
        Debug.traceln("  class :" + s);
        // Debug.traceln("  Env :" + FGraph.printGraphStr(env));
      then
        fail();
  end matchcontinue;
end instClassdef2;

protected function joinExtEquations
  input list<SCode.Equation> inEq;
  input list<SCode.Equation> inExtEq;
  input InstTypes.CallingScope inCallingScope;
  output list<SCode.Equation> outEq;
algorithm
  outEq := match(inEq, inExtEq, inCallingScope)
    case (_, _, InstTypes.TYPE_CALL()) then {};
    // Take the union of the equations in the current scope and equations
    // from extends, to filter out identical equations.
    else List.unionOnTrue(inEq, inExtEq, SCode.equationEqual);
  end match;
end joinExtEquations;

protected function joinExtAlgorithms
  input list<SCode.AlgorithmSection> inAlg;
  input list<SCode.AlgorithmSection> inExtAlg;
  input InstTypes.CallingScope inCallingScope;
  output list<SCode.AlgorithmSection> outAlg;
algorithm
  outAlg := match(inAlg, inExtAlg, inCallingScope)
    case (_, _, InstTypes.TYPE_CALL()) then {};
    else listAppend(inAlg, inExtAlg);
  end match;
end joinExtAlgorithms;

protected function instClassDefHelper
"Function: instClassDefHelper
 MetaModelica extension. KS TODO: Document this function!!!!"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input list<Absyn.TypeSpec> inSpecs;
  input Prefix.Prefix inPre;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean inImpl;
  input list<DAE.Type> accTypes;
  input Connect.Sets inSets;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output list<DAE.Type> outType;
  output Connect.Sets outSets;
  output Option<SCode.Attributes> outAttr;
algorithm
  (outCache,outEnv,outIH,outType,outSets,outAttr) :=
  matchcontinue (inCache,inEnv,inIH,inSpecs,inPre,inInstDims,inImpl,accTypes,inSets)
    local
      FCore.Cache cache;
      FCore.Graph env,cenv;
      Prefix.Prefix pre;
      InstDims dims;
      Boolean impl;
      list<DAE.Type> localAccTypes;
      list<Absyn.TypeSpec> restTypeSpecs;
      Connect.Sets csets;
      Absyn.Path cn;
      DAE.Type ty;
      Absyn.Path p;
      SCode.Element c;
      Absyn.Ident id;
      Absyn.TypeSpec tSpec;
      Option<SCode.Attributes> oDA;
      InstanceHierarchy ih;

    case (cache,env,ih,{},_,_,_,localAccTypes,_)
      then (cache,env,ih,listReverse(localAccTypes),inSets,NONE());

    case (cache,env,ih, Absyn.TPATH(cn,_) :: restTypeSpecs,pre,dims,impl,localAccTypes,_)
      equation
        (cache,(c as SCode.CLASS()),cenv) = Lookup.lookupClass(cache,env, cn, true);
        false = SCode.isFunction(c);
        (cache,cenv,ih,_,_,csets,ty,_,oDA,_)=instClass(cache,cenv,ih,UnitAbsyn.noStore,DAE.NOMOD(),pre,c,dims,impl,InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, inSets);
        localAccTypes = ty::localAccTypes;
        (cache,env,ih,localAccTypes,csets,_) =
        instClassDefHelper(cache,env,ih,restTypeSpecs,pre,dims,impl,localAccTypes, csets);
      then (cache,env,ih,localAccTypes,csets,oDA);

    case (cache,env,ih, Absyn.TPATH(cn,_) :: restTypeSpecs,pre,dims,impl,localAccTypes,_)
      equation
        (cache,ty,_) = Lookup.lookupType(cache,env,cn,NONE()) "For functions, etc";
        localAccTypes = ty::localAccTypes;
        (cache,env,ih,localAccTypes,csets,_) =
        instClassDefHelper(cache,env,ih,restTypeSpecs,pre,dims,impl,localAccTypes, inSets);
      then (cache,env,ih,localAccTypes,csets,NONE());

    case (cache,env,ih, (tSpec as Absyn.TCOMPLEX(p,_,_)) :: restTypeSpecs,pre,dims,impl,localAccTypes,_)
      equation
        id=Absyn.pathString(p);
        c = SCode.CLASS(id,SCode.defaultPrefixes,
                        SCode.NOT_ENCAPSULATED(),
                        SCode.NOT_PARTIAL(),
                        SCode.R_TYPE(),
                        SCode.DERIVED(
                          tSpec,SCode.NOMOD(),
                          SCode.ATTR({}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(), Absyn.BIDIR())),
                        SCode.noComment,
                        Absyn.dummyInfo);
        (cache,_,ih,_,_,csets,ty,_,oDA,_)=instClass(cache,env,ih,UnitAbsyn.noStore,DAE.NOMOD(),pre,c,dims,impl,InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, inSets);
        localAccTypes = ty::localAccTypes;
        (cache,env,ih,localAccTypes,csets,_) =
        instClassDefHelper(cache,env,ih,restTypeSpecs,pre,dims,impl,localAccTypes, csets);
      then (cache,env,ih,localAccTypes,csets,oDA);
  end matchcontinue;
end instClassDefHelper;

protected function instBasictypeBaseclass
"This function finds the type of classes that extends a basic type.
  For instance,
  connector RealSignal
    extends SignalType;
    replaceable type SignalType = Real;
  end RealSignal;
  Such classes can not have any other components,
  and can only inherit one basic type."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input list<SCode.Element> inSCodeElementLst2;
  input list<SCode.Element> inSCodeElementLst3;
  input DAE.Mod inMod4;
  input list<list<DAE.Dimension>> inInstDims5;
  input String className;
  input SourceInfo info;
  input Util.StatefulBoolean stopInst "prevent instantiation of classes adding components to primary types";
  output FCore.Cache outCache;
  output InnerOuter.InstHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae "contain functions";
  output Option<DAE.Type> outTypesTypeOption;
  output list<DAE.Var> outTypeVars;
algorithm
  (outCache,outIH,outStore,outDae,outTypesTypeOption,outTypeVars) :=
  matchcontinue (inCache,inEnv,inIH,inStore,inSCodeElementLst2,inSCodeElementLst3,inMod4,inInstDims5,className,info,stopInst)
    local
      DAE.Mod m_1,m_2,mods;
      SCode.Element cdef;
      FCore.Graph cenv,env_1,env;
      DAE.DAElist dae;
      DAE.Type ty;
      list<DAE.Var> tys;
      ClassInf.State st;
      Boolean b1,b2,b3;
      Absyn.Path path;
      SCode.Mod mod;
      InstDims inst_dims;
      FCore.Cache cache;
      InstanceHierarchy ih;
      UnitAbsyn.InstStore store;

    case (cache,env,ih,store,{SCode.EXTENDS(baseClassPath = path,modifications = mod)},{},mods,inst_dims,_,_,_)
      equation
        //Debug.traceln("Try instbasic 1 " + Absyn.pathString(path));
        ErrorExt.setCheckpoint("instBasictypeBaseclass");
        (cache,m_1) = Mod.elabModForBasicType(cache, env, ih, Prefix.NOPRE(), mod, true, Mod.DERIVED(path), info);
        m_2 = Mod.merge(mods, m_1, env, Prefix.NOPRE());
        (cache,cdef,cenv) = Lookup.lookupClass(cache,env, path, true);
        //Debug.traceln("Try instbasic 2 " + Absyn.pathString(path) + " " + Mod.printModStr(m_2));
        (cache,_,ih,store,dae,_,ty,tys,_) =
        instClassBasictype(cache,cenv,ih, store,m_2, Prefix.NOPRE(), cdef, inst_dims, false, InstTypes.INNER_CALL(), Connect.emptySet);
        //Debug.traceln("Try instbasic 3 " + Absyn.pathString(path) + " " + Mod.printModStr(m_2));
        b1 = Types.basicType(ty);
        b2 = Types.arrayType(ty);
        b3 = Types.extendsBasicType(ty);
        true = Util.boolOrList({b1, b2, b3});

        ErrorExt.rollBack("instBasictypeBaseclass");
      then
        (cache,ih,store,dae,SOME(ty),tys);

    case (_,_,_,_,{SCode.EXTENDS(baseClassPath = path)},{},_,_,_,_,_)
      equation
        rollbackCheck(path) "only rollback errors affecting basic types";
      then fail();

    /* Inherits baseclass -and- has components */
    case (cache,env,ih,store,{SCode.EXTENDS()},_,mods,inst_dims,_,_,_)
      equation
        false = (listEmpty(inSCodeElementLst3));
        ErrorExt.setCheckpoint("instBasictypeBaseclass2") "rolled back or deleted inside call below";
        instBasictypeBaseclass2(cache,env,ih,store,inSCodeElementLst2,inSCodeElementLst3,mods,inst_dims,className,info,stopInst);
      then
        fail();
  end matchcontinue;
end instBasictypeBaseclass;

protected function rollbackCheck "
Author BZ 2009-08
Rollsback errors on builtin classes and deletes checkpoint for other classes."
  input Absyn.Path p;
algorithm _ := matchcontinue(p)
  local String n;
  case _
    equation
      n = Absyn.pathString(p);
      true = InstUtil.isBuiltInClass(n);
      ErrorExt.rollBack("instBasictypeBaseclass");
    then ();
  case _
    equation
      ErrorExt.rollBack("instBasictypeBaseclass"); // ErrorExt.delCheckpoint("instBasictypeBaseclass");
    then ();
end matchcontinue;
end rollbackCheck;

protected function instBasictypeBaseclass2 "
Author: BZ, 2009-02
Helper function for instBasictypeBaseClass
Handles the fail case rollbacks/deleteCheckpoint of errors."
  input FCore.Cache inCache;
  input FCore.Graph inEnv1;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore store;
  input list<SCode.Element> inSCodeElementLst2;
  input list<SCode.Element> inSCodeElementLst3;
  input DAE.Mod inMod4;
  input list<list<DAE.Dimension>> inInstDims5;
  input String className;
  input SourceInfo info;
  input Util.StatefulBoolean stopInst "prevent instantiation of classes adding components to primary types";
algorithm
  _ := matchcontinue(inCache,inEnv1,inIH,store,inSCodeElementLst2,inSCodeElementLst3,inMod4,inInstDims5,className,info,stopInst)
  local
      DAE.Mod m_1,mods;
      SCode.Element cdef,cdef_1;
      FCore.Graph cenv,env_1,env;
      DAE.DAElist dae;
      DAE.Type ty;
      ClassInf.State st;
      Boolean b1,b2;
      Absyn.Path path;
      SCode.Mod mod;
      InstDims inst_dims;
      String classname;
      FCore.Cache cache;
      InstanceHierarchy ih;

    case (cache,env,ih,_,{SCode.EXTENDS(baseClassPath = path,modifications = mod)},(_ :: _),_,inst_dims,_,_,_) /* Inherits baseclass -and- has components */
      equation
        (cache,m_1) = Mod.elabModForBasicType(cache, env, ih, Prefix.NOPRE(), mod, true, Mod.DERIVED(path), info);
        (cache,cdef,cenv) = Lookup.lookupClass(cache,env, path, true);
        cdef_1 = SCode.classSetPartial(cdef, SCode.NOT_PARTIAL());

        (cache,_,ih,_,_,_,ty,_,_,_) = instClass(cache,cenv,ih,store, m_1,
          Prefix.NOPRE(), cdef_1, inst_dims, false, InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, Connect.emptySet) "impl" ;

        b1 = Types.basicType(ty);
        b2 = Types.arrayType(ty);
        true = boolOr(b1, b2);
        classname = FGraph.printGraphPathStr(env);
        ErrorExt.rollBack("instBasictypeBaseclass2");
        Error.addSourceMessage(Error.INHERIT_BASIC_WITH_COMPS, {classname}, info);
        Util.setStatefulBoolean(stopInst,true);
      then
        ();

    // if not error above, then do not report error at all, try another case in instClassdef.
    else
      equation
        ErrorExt.rollBack("instBasictypeBaseclass2");
      then ();
    end matchcontinue;
end instBasictypeBaseclass2;

protected function partialInstClassdef
"This function is used by partialInstClassIn for instantiating local
  class definitons and inherited class definitions only."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input ClassInf.State inState;
  input SCode.Element inClass "the class this definition comes from";
  input SCode.ClassDef inClassDef;
  input SCode.Visibility inVisibility;
  input list<list<DAE.Dimension>> inInstDims;
  input Integer numIter;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output ClassInf.State outState;
  output list<DAE.Var> outVars;
algorithm
  (outCache,outEnv,outIH,outState,outVars):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inState,inClass,inClassDef,inVisibility,inInstDims,numIter)
    local
      ClassInf.State ci_state1,ci_state,new_ci_state,new_ci_state_1,ci_state2;
      list<SCode.Element> cdefelts,extendselts,els,cdefelts2,classextendselts;
      FCore.Graph env1,env2,env,cenv,cenv_2,env_2,env3,parentEnv;
      DAE.Mod emods,mods,mod_1,mods_1;
      list<tuple<SCode.Element, DAE.Mod>> extcomps,lst_constantEls;
      list<SCode.Equation> eqs,initeqs;
      list<SCode.AlgorithmSection> alg,initalg;
      Prefix.Prefix pre;
      SCode.Restriction re,r;
      SCode.Visibility vis;
      SCode.Encapsulated enc2;
      SCode.Partial partialPrefix;
      InstDims inst_dims,inst_dims_1;
      SCode.Element c, parentClass;
      String cn2,cns,scope_str,className;
      Absyn.Path cn;
      Option<list<Absyn.Subscript>> ad;
      SCode.Mod mod;
      FCore.Cache cache;
      InstanceHierarchy ih;
      Option<SCode.Comment> cmt;
      list<DAE.Dimension> inst_dims2;
      DAE.Dimensions dims;
      Option<DAE.EqMod> eq;
      Boolean isPartialInst;
      Absyn.ArrayDim adno;
      list<DAE.Var> vars;
      SourceInfo info;
      FCore.Ref lastRef;

      // long class definition, the normal case, a class with parts
      case (cache,env,ih,mods,pre,ci_state,parentClass,SCode.PARTS(elementLst = els),_,inst_dims,_)
      equation
        isPartialInst = true;

        partialPrefix = SCode.getClassPartialPrefix(parentClass);
        className = SCode.getElementName(parentClass);

        // Debug.traceln(" Partialinstclassdef for: " + PrefixUtil.printPrefixStr(pre) + "." +  className + " mods: " + Mod.printModStr(mods));
        // fprintln(Flags.INST_TRACE, "PARTIALICD: " + FGraph.printGraphPathStr(env) + " cn:" + className + " mods: " + Mod.printModStr(mods));
        partialPrefix = InstUtil.isPartial(partialPrefix, mods);
        ci_state1 = ClassInf.trans(ci_state, ClassInf.NEWDEF());
        (cdefelts,classextendselts,extendselts,_) = InstUtil.splitElts(els);
        extendselts = SCodeUtil.addRedeclareAsElementsToExtends(extendselts, List.select(els, SCodeUtil.isRedeclareElement));
        (cache,env1,ih) = InstUtil.addClassdefsToEnv(cache,env, ih, pre, cdefelts, true, SOME(mods)) " CLASS & IMPORT nodes are added to env" ;
        (cache,env2,ih,emods,extcomps,_,_,_,_) =
        InstExtends.instExtendsAndClassExtendsList(cache, env1, ih, mods, pre, extendselts, classextendselts, els, ci_state, className, true, isPartialInst)
        "2. EXTENDS Nodes inst_Extends_List only flatten inhteritance structure. It does not perform component instantiations." ;

        // this does not work, see Modelica.Media SingleGasNasa!
        // els = if_(SCode.partialBool(partialPrefix), {}, els);

        // If we partially instantiate a partial package, we filter out constants (maybe we should also filter out functions) /sjoelund
        lst_constantEls = listAppend(extcomps,InstUtil.addNomod(InstUtil.constantEls(els))) " Retrieve all constants";

        // if we are not in a package, just remove

        /*
         Since partial instantiation is done in lookup, we need to add inherited classes here.
         Otherwise when looking up e.g. A.B where A inherits the definition of B, and without having a
         base class context (since we do not have any element to find it in), the class must be added
         to the environment here.
        */

        mods = Mod.merge(mods, emods, env2, pre);

        (cdefelts2,extcomps) = InstUtil.classdefElts2(extcomps, partialPrefix);
        (cache,env2,ih) = InstUtil.addClassdefsToEnv(cache, env2, ih, pre, cdefelts2, true, SOME(mods)); // Add inherited classes to env

        (cache,env3,ih) = InstUtil.addComponentsToEnv(cache, env2, ih, mods, pre, ci_state,
                                             lst_constantEls, lst_constantEls, {},
                                             inst_dims, false); // adrpo: here SHOULD BE IMPL=TRUE! not FALSE!

        (cache,env3,ih,_,_,_,ci_state2,vars,_) =
           instElementList(cache, env3, ih, UnitAbsyn.noStore, mods, pre, ci_state1, lst_constantEls,
              inst_dims, true, InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, Connect.emptySet, false) "instantiate constants";

        //ci_state2 = ci_state1;
        //vars = {};

        // Debug.traceln("partialInstClassdef OK " + className);
      then
        (cache,env3,ih,ci_state2,vars);

    // Short class definition, derived from basic types!
    case (cache,env,ih,mods,pre,_,parentClass,
          SCode.DERIVED(Absyn.TPATH(path = cn, arrayDim = ad),modifications = mod),
          vis,inst_dims,_)
      equation
        (cache,(c as SCode.CLASS(name=cn2,encapsulatedPrefix=enc2,restriction=r)),cenv) = Lookup.lookupClass(cache, env, cn, true);

        re = SCode.getClassRestriction(parentClass);
        _ = SCode.getClassPartialPrefix(parentClass);
        _ = SCode.getElementName(parentClass);
        info = SCode.elementInfo(parentClass);

        // if is a basic type, or enum follow the normal path
        true = InstUtil.checkDerivedRestriction(re, r, cn2);

        cenv_2 = FGraph.openScope(cenv, enc2, SOME(cn2), FGraph.restrictionToScopeType(r));
        new_ci_state = ClassInf.start(r, FGraph.getGraphName(cenv_2));

        // chain the redeclares
        mod = InstUtil.chainRedeclares(mods, mod);

        // the mod is elabed in the parent of this class
        (parentEnv, _) = FGraph.stripLastScopeRef(env);
        (cache,mod_1) = Mod.elabMod(cache, parentEnv, ih, pre, mod, false, Mod.DERIVED(cn), info);
        mods_1 = Mod.merge(mods, mod_1, parentEnv, pre);

        eq = Mod.modEquation(mods_1) "instantiate array dimensions" ;
        (cache,dims) = InstUtil.elabArraydimOpt(cache, parentEnv, Absyn.CREF_IDENT("",{}), cn, ad, eq, false, NONE(), true, pre, info, inst_dims) "owncref not valid here" ;
        // inst_dims2 = InstUtil.instDimExpLst(dims, false);
        _ = List.appendLastList(inst_dims, dims);

        _ = Absyn.getArrayDimOptAsList(ad);
        (cache,env_2,ih,new_ci_state_1,vars) = partialInstClassIn(cache, cenv_2, ih, mods_1, pre, new_ci_state, c, vis, inst_dims, numIter);
      then
        (cache,env_2,ih,new_ci_state_1,vars);

    // Short class definition, not derived from basic types!, empty array dims
    case (cache,env,ih,mods,pre,ci_state,parentClass,
          SCode.DERIVED(Absyn.TPATH(path = cn, arrayDim = ad),modifications = mod),
          vis,inst_dims,_)
      equation
        // don't enter here
        // false = true;
        // no meta-modelica
        // false = Config.acceptMetaModelicaGrammar();
        // no types, enums or connectors please!
        re = SCode.getClassRestriction(parentClass);
        _ = SCode.getClassPartialPrefix(parentClass);
        _ = SCode.getElementName(parentClass);
        info = SCode.elementInfo(parentClass);

        false = valueEq(re, SCode.R_TYPE());
        // false = valueEq(re, SCode.R_FUNCTION());
        false = valueEq(re, SCode.R_ENUMERATION());
        false = valueEq(re, SCode.R_PREDEFINED_ENUMERATION());
        // false = SCode.isConnector(re);
        // check empty array dimensions
        true = boolOr(valueEq(ad, NONE()), valueEq(ad, SOME({})));
        (cache,SCode.CLASS(name=cn2,restriction=r),_) = Lookup.lookupClass(cache, env, cn, true);

        false = InstUtil.checkDerivedRestriction(re, r, cn2);


        // chain the redeclares
        mod = InstUtil.chainRedeclares(mods, mod);

        // elab the modifiers in the parent environment!!
        (parentEnv,_) = FGraph.stripLastScopeRef(env);
        // adrpo: as we do this IN THE SAME ENVIRONMENT (no open scope), clone it before doing changes
        // env = FGraph.pushScopeRef(parentEnv, FNode.copyRefNoUpdate(lastRef));
        (cache, mod_1) = Mod.elabMod(cache, parentEnv, ih, pre, mod, false, Mod.DERIVED(cn), info);
        // print("mods: " + Absyn.pathString(cn) + " " + Mod.printModStr(mods_1) + "\n");
        mods_1 = Mod.merge(mods, mod_1, parentEnv, pre);

        // use instExtends for derived with no array dimensions and no modification (given via the mods_1)
        //print("DEP:>>>" + FGraph.printGraphPathStr(env) + " = " + Absyn.pathString(cn) + " mods: " + Mod.printModStr(mods_1) + "\n");
        //System.startTimer();
        (cache, env, ih, ci_state,vars) =
        partialInstClassdef(cache, env, ih, mods_1, pre, ci_state, parentClass,
           SCode.PARTS({SCode.EXTENDS(cn, vis, SCode.NOMOD(), NONE(), info)},{},{},{},{},{},{},NONE()),
           vis, inst_dims, numIter);
        //System.stopTimer();
        //print("DEP:<<<" + FGraph.printGraphPathStr(env) + " took: " + realString(System.getTimerIntervalTime()) + "\n");
      then
        (cache, env, ih, ci_state, vars);

    // Short class definition, not derived from basic types!, non-empty array dims
    case (cache,env,ih,mods,pre,ci_state,parentClass,
          SCode.DERIVED(Absyn.TPATH(path = cn, arrayDim = ad),modifications = mod),
          vis,inst_dims,_)
      equation
        (cache,(c as SCode.CLASS(name=cn2,encapsulatedPrefix=enc2,restriction=r)),cenv) = Lookup.lookupClass(cache, env, cn, true);

        re = SCode.getClassRestriction(parentClass);
        _ = SCode.getClassPartialPrefix(parentClass);
        className = SCode.getElementName(parentClass);
        info = SCode.elementInfo(parentClass);

        // if is not a basic type
        false = InstUtil.checkDerivedRestriction(re, r, cn2);

        // change the class name to className!!
        // package A2=A
        // package A3=A(mods)
        // will get you different function implementations for the different packages!
        /*
        fullEnvPath = Absyn.selectPathsOpt(FGraph.getScopePath(env), Absyn.IDENT(""));
        fullClassName = "DE_" + Absyn.pathStringReplaceDot(fullEnvPath, "_") + "_D_" +
                        Absyn.pathStringReplaceDot(Absyn.selectPathsOpt(FGraph.getScopePath(cenv), Absyn.IDENT("")), "_" ) + "." + cn2 + "_ED";

        // open a scope with a unique name in the base class environment so there is no collision
        cenv_2 = FGraph.openScope(cenv, enc2, SOME(fullClassName), FGraph.classInfToScopeType(ci_state));
        new_ci_state = ClassInf.start(r, FGraph.getGraphName(cenv_2));
        */

        // open a scope with the correct name
        // className = className + "|" + PrefixUtil.printPrefixStr(pre) + "|" + cn2;

        cenv_2 = FGraph.openScope(cenv, enc2, SOME(className), FGraph.classInfToScopeType(ci_state));
        new_ci_state = ClassInf.start(r, FGraph.getGraphName(cenv_2));

        c = SCode.setClassName(className, c);

        //print("Partial Derived Env: " + FGraph.printGraphPathStr(cenv_2) + "\n");

        // chain the redeclares
        mod = InstUtil.chainRedeclares(mods, mod);

        // elab the modifiers in the parent environment!
        (parentEnv, _) = FGraph.stripLastScopeRef(env);
        (cache, mod_1) = Mod.elabMod(cache, parentEnv, ih, pre, mod, false, Mod.DERIVED(cn), info);
        mods_1 = Mod.merge(mods, mod_1, parentEnv, pre);

        eq = Mod.modEquation(mods_1) "instantiate array dimensions" ;
        (cache,dims) = InstUtil.elabArraydimOpt(cache, parentEnv, Absyn.CREF_IDENT("",{}), cn, ad, eq, false, NONE(), true, pre, info, inst_dims) "owncref not valid here" ;
        // inst_dims2 = InstUtil.instDimExpLst(dims, false);
        inst_dims_1 = List.appendLastList(inst_dims, dims);

        _ = Absyn.getArrayDimOptAsList(ad);
        (cache,env_2,ih,new_ci_state_1,vars) = partialInstClassIn(cache, cenv_2, ih, mods_1, pre, new_ci_state, c, vis, inst_dims_1, numIter);
      then
        (cache,env_2,ih,new_ci_state_1,vars);

    /* If the class is derived from a class that can not be found in the environment,
     * this rule prints an error message.
     */
    case (cache,env,_,_,_,_,parentClass,
          SCode.DERIVED(Absyn.TPATH(path = cn)),
          _,_,_)
      equation
        failure((_,_,_) = Lookup.lookupClass(cache,env, cn, false));
        cns = Absyn.pathString(cn);
        scope_str = FGraph.printGraphPathStr(env);
        Error.addSourceMessage(Error.LOOKUP_ERROR, {cns,scope_str},SCode.elementInfo(parentClass));
      then
        fail();
  end matchcontinue;
end partialInstClassdef;

public function instElementList
  "Instantiates a list of elements."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input ClassInf.State inState;
  input list<tuple<SCode.Element, DAE.Mod>> inElements;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean inImplInst;
  input InstTypes.CallingScope inCallingScope;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  input Boolean inStopOnError;
  output FCore.Cache outCache = inCache;
  output FCore.Graph outEnv = inEnv;
  output InnerOuter.InstHierarchy outIH = inIH;
  output UnitAbsyn.InstStore outStore = inStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets = inSets;
  output ClassInf.State outState = inState;
  output list<DAE.Var> outVars;
  output ConnectionGraph.ConnectionGraph outGraph = inGraph;
protected
  list<tuple<SCode.Element, DAE.Mod>> el;
  FCore.Cache cache;
  list<DAE.Var> vars;
  list<DAE.Element> dae;
  list<list<DAE.Var>> varsl = {};
  list<list<DAE.Element>> dael = {};
  list<Integer> element_order;
  array<tuple<SCode.Element, DAE.Mod>> el_arr;
  array<list<DAE.Var>> var_arr;
  array<list<DAE.Element>> dae_arr;
algorithm
  cache := InstUtil.pushStructuralParameters(inCache);

  // Sort elements based on their dependencies.
  el := InstUtil.sortElementList(inElements, inEnv, FGraph.inFunctionScope(inEnv));
  // adrpo: MAKE SURE inner objects ARE FIRST in the list for instantiation!
  el := InstUtil.sortInnerFirstTplLstElementMod(el);

  // For non-functions, don't reorder the elements.
  if not ClassInf.isFunction(inState) then
    // Figure out the ordering of the sorted elements, see getSortedElementOrdering.
    element_order := getSortedElementOrdering(inElements, el);

    // Create arrays so that we can instantiate the elements in the sorted order,
    // while keeping the result in the same order as the elements are declared in.
    el_arr := listArray(inElements);
    var_arr := arrayCreate(listLength(el), {});
    dae_arr := arrayCreate(listLength(el), {});

    // Instantiate the elements.
    for idx in element_order loop
      (cache, outEnv, outIH, outStore, dae, outSets, outState, vars, outGraph) :=
        instElement2(cache, outEnv, outIH, outStore, inMod, inPrefix, outState, el_arr[idx],
          inInstDims, inImplInst, inCallingScope, outGraph, outSets, inStopOnError);
      arrayUpdate(var_arr, idx, vars);
      arrayUpdate(dae_arr, idx, dae);
    end for;

    outVars := List.flatten(arrayList(var_arr));
    outDae := DAE.DAE(List.flatten(arrayList(dae_arr)));
  else
    // For functions, use the sorted elements instead, otherwise things break.
    for e in el loop
      (cache, outEnv, outIH, outStore, dae, outSets, outState, vars, outGraph) :=
        instElement2(cache, outEnv, outIH, outStore, inMod, inPrefix, outState, e,
          inInstDims, inImplInst, inCallingScope, outGraph, outSets, inStopOnError);
      varsl := vars :: varsl;
      dael := dae :: dael;
    end for;

    outVars := List.flattenReverse(varsl);
    outDae := DAE.DAE(List.flattenReverse(dael));
  end if;

  outCache := InstUtil.popStructuralParameters(cache,inPrefix);
end instElementList;

protected function getSortedElementOrdering
  "Takes a list of unsorted elements and a list of sorted elements, and returns
   a list of the sorted elements indices in the unsorted list. E.g.:
    getSortedElementOrdering({a, b, c}, {b, c, a}) => {2, 3, 1}"
  input list<tuple<SCode.Element, DAE.Mod>> inElements;
  input list<tuple<SCode.Element, DAE.Mod>> inSortedElements;
  output list<Integer> outIndices = {};
protected
  list<tuple<SCode.Element, Integer>> index_map = {};
  list<SCode.Element> sorted_el;
  Integer i = 1;
algorithm
  // Pair each unsorted element with its index in the list.
  for e in inElements loop
    index_map := (Util.tuple21(e), i) :: index_map;
    i := i + 1;
  end for;
  index_map := listReverse(index_map);

  // Loop through the sorted elements.
  sorted_el := list(Util.tuple21(e) for e in inSortedElements);
  for e in sorted_el loop
    // Remove the element from the index map, and add its index to the list of
    // indices. Elements are usually not reordered much, so most of the time the
    // sought after element should be first in the list.
    (index_map, SOME((_, i))) :=
      List.deleteMemberOnTrue(e, index_map, getSortedElementOrdering_comp);
    outIndices := i :: outIndices;
  end for;

  outIndices := listReverse(outIndices);
end getSortedElementOrdering;

protected function getSortedElementOrdering_comp
  input SCode.Element inElement1;
  input tuple<SCode.Element, Integer> inElement2;
  output Boolean outEqual = SCode.elementNameEqual(inElement1, Util.tuple21(inElement2));
end getSortedElementOrdering_comp;

public function instElement2
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input ClassInf.State inState;
  input tuple<SCode.Element, DAE.Mod> inElement;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean inImplicit;
  input InstTypes.CallingScope inCallingScope;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  input Boolean inStopOnError;
  output FCore.Cache outCache;
  output FCore.Graph outEnv = inEnv;
  output InnerOuter.InstHierarchy outIH = inIH;
  output UnitAbsyn.InstStore outStore = inStore;
  output list<DAE.Element> outDae = {};
  output Connect.Sets outSets;
  output ClassInf.State outState = inState;
  output list<DAE.Var> outVars = {};
  output ConnectionGraph.ConnectionGraph outGraph = inGraph;
protected
  tuple<SCode.Element, DAE.Mod> elt;
  Boolean is_deleted;
algorithm
  // Check if the component has a conditional expression that evaluates to false.
  (is_deleted, outSets, outCache) := isDeletedComponent(inElement, inCache,
      inEnv, inPrefix, inSets, inStopOnError);

  // Skip the component if it was deleted by a conditional expression.
  if is_deleted then
    return;
  end if;

  try // Try to instantiate the element.
    ErrorExt.setCheckpoint("instElement2");
    (outCache, outEnv, outIH, {elt}) := updateCompeltsMods(inCache, outEnv,
      outIH, inPrefix, {inElement}, outState, inImplicit);
    (outCache, outEnv, outIH, outStore, DAE.DAE(outDae), outSets, outState, outVars, outGraph) :=
      instElement(outCache, outEnv, outIH, outStore, inMod, inPrefix, outState, elt, inInstDims,
        inImplicit, inCallingScope, outGraph, inSets);
    Error.updateCurrentComponent("", Absyn.dummyInfo);
    ErrorExt.delCheckpoint("instElement2");
  else // Instantiation failed, fail or skip the element depending on inStopOnError.
    if inStopOnError then
      ErrorExt.delCheckpoint("instElement2");
      fail();
    else
      ErrorExt.rollBack("instElement2");
      outCache := inCache;
      outEnv := inEnv;
      outIH := inIH;
      return;
    end if;
  end try;
end instElement2;

protected function isDeletedComponent
  "Checks if an element has a conditional expression that evaluates to false,
   and adds it to the set of deleted components if it does. Otherwise the
   function does nothing."
  input tuple<SCode.Element, DAE.Mod> inElement;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Prefix.Prefix inPrefix;
  input Connect.Sets inSets;
  input Boolean inStopOnError;
  output Boolean outIsDeleted;
  output Connect.Sets outSets = inSets;
  output FCore.Cache outCache;
protected
  SCode.Element el;
  String el_name;
  SourceInfo info;
  Option<Boolean> cond_val_opt;
  Boolean cond_val;
algorithm
  // If the element has a conditional expression, try to evaluate it.
  if InstUtil.componentHasCondition(inElement) then
    (el, _) := inElement;
    (el_name, info) := InstUtil.extractCurrentName(el);

    (cond_val_opt, outCache) :=
      InstUtil.instElementCondExp(inCache, inEnv, el, inPrefix, info);

    // If a conditional expression was present but couldn't be instantiatied, stop.
    if isNone(cond_val_opt) then
      if inStopOnError then // We should stop instantiation completely, fail.
        fail();
      else  // We should continue instantiation, pretend that it was deleted.
        outIsDeleted := false;
        return;
      end if;
    end if;

    // If we succeeded, check if the condition is true or false.
    SOME(cond_val) := cond_val_opt;
    outIsDeleted := not cond_val;

    // The component was deleted, add it to the connection set so we can ignore
    // connections to it.
    if outIsDeleted == true then
      outSets := ConnectUtil.addDeletedComponent(el_name, inSets);
    end if;
  else
    outIsDeleted := false;
    outCache := inCache;
  end if;
end isDeletedComponent;

public function instElement "
  This monster function instantiates an element of a class definition.  An
  element is either a class definition, a variable, or an import clause."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inUnitStore;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input ClassInf.State inState;
  input tuple<SCode.Element, DAE.Mod> inElement;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean inImplicit;
  input InstTypes.CallingScope inCallingScope;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output UnitAbsyn.InstStore outUnitStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output list<DAE.Var> outVars;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache, outEnv, outIH, outUnitStore, outDae, outSets, outState, outVars, outGraph):=
  matchcontinue (inCache, inEnv, inIH, inUnitStore, inMod, inPrefix, inState,
      inElement, inInstDims, inImplicit, inCallingScope, inGraph, inSets)
    local
      Absyn.ComponentRef own_cref;
      Absyn.Direction dir;
      SourceInfo info;
      Absyn.InnerOuter io;
      Absyn.Path t, type_name;
      Absyn.TypeSpec ts;
      Boolean already_declared, impl, is_function_input;
      InstTypes.CallingScope callscope;
      ClassInf.State ci_state;
      ConnectionGraph.ConnectionGraph graph, graph_new;
      Connect.Sets csets;
      DAE.Attributes dae_attr;
      DAE.Binding binding;
      DAE.ComponentRef cref, vn, cref2;
      DAE.DAElist dae;
      DAE.Mod mod, mods, class_mod, mm, cmod, mod_1, var_class_mod, m_1, cls_mod;
      DAE.Type ty;
      DAE.Var new_var;
      FCore.Cache cache;
      FCore.Graph env, env2, cenv, comp_env;
      InstanceHierarchy ih;
      InstDims inst_dims;
      list<Absyn.ComponentRef> crefs, crefs1, crefs2, crefs3;
      list<Absyn.Subscript> ad;
      DAE.Dimensions dims;
      list<DAE.Var> vars;
      Option<Absyn.Exp> cond;
      Option<DAE.EqMod> eq;
      SCode.Comment comment;
      Prefix.Prefix pre;
      SCode.Attributes attr;
      SCode.Element cls, comp, comp2, el;
      SCode.Final final_prefix;
      SCode.ConnectorType ct;
      SCode.Mod m;
      SCode.Prefixes prefixes;
      SCode.Variability vt;
      SCode.Visibility vis;
      String name, id, ns, s, scope_str;
      UnitAbsyn.InstStore store;
      FCore.Node node;
      InnerOuter.TopInstance topInstance; // BTH
      HashSet.HashSet sm; // BTH
      Boolean isInSM; // BTH
      list<DAE.Element> elems; // BTH

    // Imports are simply added to the current frame, so that the lookup rule can find them.
    // Import have already been added to the environment so there is nothing more to do here.
    case (_, _, _, _, _, _, _,(SCode.IMPORT(),_), _, _, _, _, _)
      then (inCache, inEnv, inIH, inUnitStore, DAE.emptyDae, inSets, inState, {}, inGraph);

    // class definitions, add the modifiers from the extends to the env
    case (_, _, _, _, _, _, _, (cls as SCode.CLASS(), cmod), _, _, _, _, _)
      equation
        //(cache, cenv, ih, store, dae, csets, ty, ci_state, _, graph) = instClass(cache, env, ih, inUnitStore, inMod, inPrefix, cls, inInstDims, inImplicit, inCallingScope, inGraph, inSets);
        if not Mod.isEmptyMod(cmod) then
          env = FGraph.updateClass(inEnv, cls, inPrefix, cmod, FCore.CLS_UNTYPED(), inEnv);
        else
          env = inEnv;
        end if;
      then
        (inCache, env, inIH, inUnitStore, DAE.emptyDae, inSets, inState, {}, inGraph);
        // (inCache, inEnv, inIH, inUnitStore, DAE.emptyDae, inSets, inState, {}, inGraph);

    // A component
    // This is the rule for instantiating a model component.  A component can be
    // a structured subcomponent or a variable, parameter or constant.  All of
    // these are treated in a similar way. Lookup the class name, apply
    // modifications and add the variable to the current frame in the
    // environment. Then instantiate the class with an extended prefix.
    case (cache, env, ih, store, mods, pre, ci_state, ((el as SCode.COMPONENT(name = name, typeSpec = Absyn.TPATH())), cmod),
        inst_dims, impl, _, graph, csets)
      equation
        //print("  instElement: A component: " + name + "\n");
        //print("instElement: " + name + " in s:" + FGraph.printGraphPathStr(env) + " m: " + SCodeDump.printModStr(m) + " cm: " + Mod.printModStr(cmod) + " mods:" + Mod.printModStr(mods) + "\n");
        //print("Env:\n" + FGraph.printGraphStr(env) + "\n");
        // lookup as it might have been redeclared
        // (_, _, el, _, _, _) = Lookup.lookupIdentLocal(cache, env, name);
        SCode.COMPONENT(
          name = name,
          prefixes = prefixes as SCode.PREFIXES(
            finalPrefix = final_prefix,
            innerOuter = io
            ),
          attributes = attr as SCode.ATTR(arrayDims = ad),
          typeSpec = (ts as Absyn.TPATH(path = t)),
          modifications = m,
          comment = comment,
          condition = cond,
          info = info) = el;

        true = if Config.acceptParModelicaGrammar() then InstUtil.checkParallelismWRTEnv(env,name,attr,info) else true;

        // merge modifers from the component to the modifers from the constrained by
        m = SCode.mergeModifiers(m, SCodeUtil.getConstrainedByModifiers(prefixes));

        if SCode.finalBool(final_prefix) then
          m = InstUtil.traverseModAddFinal(m);
        end if;
        comp = SCode.COMPONENT(name, prefixes, attr, ts, m, comment, cond, info);

        // Fails if multiple decls not identical
        already_declared = InstUtil.checkMultiplyDeclared(cache, env, mods, pre, ci_state, (comp, cmod), inst_dims, impl);

        // chain the redeclares AFTER checking of elements identical
        // if we have an outer modification: redeclare X = Y
        // and a component modification redeclare X = Z
        // update the component modification to redeclare X = Y
        m = InstUtil.chainRedeclares(mods, m);
        m = SCodeUtil.expandEnumerationMod(m);
        m = InstUtil.traverseModAddDims(cache, env, pre, m, inst_dims, ad);
        comp = SCode.COMPONENT(name, prefixes, attr, ts, m, comment, cond, info);
        ci_state = ClassInf.trans(ci_state, ClassInf.FOUND_COMPONENT(name));
        cref = ComponentReference.makeCrefIdent(name, DAE.T_UNKNOWN_DEFAULT, {});
        (cache,_) = PrefixUtil.prefixCref(cache, env, ih, pre, cref); /*mahge: todo: remove me*/

        // The class definition is fetched from the environment. Then the set of
        // modifications is calculated. The modificions is the result of merging
        // the modifications from several sources. The modification stored with
        // the class definition is put in the variable `classmod', the
        // modification passed to the function_ is extracted and put in the
        // variable `mm', and the modification that is included in the variable
        // declaration is in the variable `m'.  All of these are merged so that
        // the correct precedence rules are followed."
        class_mod = Mod.lookupModificationP(mods, t);
        mm = Mod.lookupCompModification(mods, name);

        // The types in the environment does not have correct Binding.
        // We must update those variables that is found in m into a new environment.
        own_cref = Absyn.CREF_IDENT(name, {});
        crefs1 = InstUtil.getCrefFromMod(m);
        crefs2 = InstUtil.getCrefFromDim(ad);
        crefs3 = InstUtil.getCrefFromCond(cond);
        crefs = List.unionList({crefs1, crefs2, crefs3});

        // can call instVar
        (cache, env, ih, store, crefs) = removeSelfReferenceAndUpdate(cache,
          env, ih, store, crefs, own_cref, t, ci_state, attr, prefixes,
          impl, inst_dims, pre, mods, m, info);

        // can call instVar
        (cache, env2, ih) = updateComponentsInEnv(cache, env, ih, pre, mods, crefs, ci_state, impl);
        // env2 = env;

        // Update the untyped modifiers to typed ones, and extract class and
        // component modifiers again.
        (cache, class_mod) = Mod.updateMod(cache, env2, ih, pre, class_mod, impl, info);
        (cache, mm) = Mod.updateMod(cache, env2, ih, pre, mm, impl, info);

        // (BZ part:1/2)
        // If we have a redeclaration of a inner model, we have lowest priority on it.
        // This is while if we instantiate an instance of this redeclared class with a
        // modifier, the modifier should be the value to use.
        (var_class_mod, class_mod) = modifyInstantiateClass(class_mod, t);

        // print("Inst.instElement: before elabMod " + PrefixUtil.printPrefixStr(pre) +
        // "." + name + " component mod: " + SCodeDump.printModStr(m) + " in env: " +
        // FGraph.printGraphPathStr(env2) + "\n");
        (cache, m_1) = Mod.elabMod(cache, env2, ih, pre, m, impl, Mod.COMPONENT(name), info);

        // print("Inst.instElement: after elabMod " + PrefixUtil.printPrefixStr(pre) + "." + name + " component mod: " + Mod.printModStr(m_1) + " in env: " + FGraph.printGraphPathStr(env2) + "\n");

        mod = Mod.merge(mm, class_mod, env2, pre);
        mod = Mod.merge(mod, m_1, env2, pre);
        mod = Mod.merge(cmod, mod, env2, pre);

        /* (BZ part:2/2) here we merge the redeclared class modifier.
         * Redeclaration has lowest priority and if we have any local modifiers,
         * they will be used before "global" modifers.
         */
        mod = Mod.merge(mod, var_class_mod, env2, pre);

        // fprintln(Flags.INST_TRACE, "INST ELEMENT: name: " + name + " mod: " + Mod.printModStr(mod));

        // Apply redeclaration modifier to component
        (cache, env2, ih, SCode.COMPONENT(name,
          prefixes as SCode.PREFIXES(innerOuter = io),
          attr as SCode.ATTR(arrayDims = ad, direction = dir),
          Absyn.TPATH(t, _), _, comment, _, _), mod_1)
          = redeclareType(cache, env2, ih, mod, comp, pre, ci_state, impl, DAE.NOMOD());

        (cache, cls, cenv) = Lookup.lookupClass(cache, env2 /* env */, t, true);
        cls_mod = Mod.getClassModifier(cenv, SCode.className(cls));
        if not Mod.isEmptyMod(cls_mod)
        then
          if not listEmpty(ad) // add each if needed
          then
            cls_mod = Mod.addEachIfNeeded(cls_mod, {DAE.DIM_INTEGER(1)});
          end if;
          mod_1 = Mod.merge(mod_1, cls_mod, env2, pre);
        end if;
        attr = SCode.mergeAttributesFromClass(attr, cls);

        // If the element is protected, and an external modification
        // is applied, it is an error.
        // this does not work as we don't know from where the modification came (component modif or extends modif)
        // checkProt(vis, mm, vn, info);

        //Instantiate the component
        // Start a new "set" of inst_dims for this component (in instance hierarchy), see InstDims
        inst_dims = listAppend(inst_dims,{{}});

        (cache,mod) = Mod.updateMod(cache, env2 /* cenv */, ih, pre, mod, impl, info);
        (cache,mod_1) = Mod.updateMod(cache, env2 /* cenv */, ih, pre, mod_1, impl, info);

        // print("Before InstUtil.selectModifiers:\n\tmod: " + Mod.printModStr(mod) + "\n\t" +"mod_1: " + Mod.printModStr(mod_1) + "\n\t" +"comp: " + SCodeDump.unparseElementStr(comp) + "\n");

        (mod, mod_1) = InstUtil.selectModifiers(mod, mod_1, t);

        // print("After InstUtil.selectModifiers:\n\tmod: " + Mod.printModStr(mod) + "\n\t" +"mod_1: " + Mod.printModStr(mod_1) + "\n");

        eq = Mod.modEquation(mod);
        // The variable declaration and the (optional) equation modification are inspected for array dimensions.
        is_function_input = InstUtil.isFunctionInput(ci_state, dir);
        (cache, dims) = InstUtil.elabArraydim(cache, env2, own_cref, t, ad, eq, impl,
          NONE(), true, is_function_input, pre, info, inst_dims);

        // adrpo: 2011-11-18: see if the component is an INPUT or OUTPUT and class is a record
        //                    and add it to the cache!
        // (cache, _, _) = addRecordConstructorsToTheCache(cache, cenv, ih, mod_1, pre, ci_state, dir, cls, inst_dims);
        (cenv, cls, ih) = FGraph.createVersionScope(env2, name, pre, mod_1, cenv, cls, ih);

        /* Check  whether the current class is part of a state machine */
        (cache, cref2) = PrefixUtil.prefixCref(cache, cenv, ih, pre, cref);
        //print("Inst.instElement: before SM check " + PrefixUtil.printPrefixStr(pre) + "." + name + " cref2: " + ComponentReference.crefStr(cref2) + " in env: " + FGraph.printGraphPathStr(env2) + "\n");
        if not listEmpty(ih) then
          topInstance = listHead(ih);
          InnerOuter.TOP_INSTANCE(sm=sm) = topInstance;
          // print("Inst.instElement: START sm:\n"); BaseHashSet.printHashSet(sm); print("\nInst.instElement: STOP sm:\n");
          if  BaseHashSet.has(cref2, sm) then
            //print("\n Inst.instElement: Found: "+ComponentReference.crefStr(cref2)+"\n");
            isInSM = true;
          else
            isInSM = false;
          end if;
          else
            isInSM = false;
        end if;

        (cache, comp_env, ih, store, dae, csets, ty, graph_new) = InstVar.instVar(cache,
          cenv, ih, store, ci_state, mod_1, pre, name, cls, attr,
          prefixes, dims, {}, inst_dims, impl, comment, info, graph, csets, env2);

        if isInSM then
          // If class is in state machine, wrap its content in a DAE.SM_COMP
          DAE.DAE(elementLst=elems) = dae;
          dae = DAE.DAE({DAE.SM_COMP(cref2, elems)});
          //dae = DAE.DAE({DAE.COMP(ComponentReference.crefStr(cref), elems, DAE.emptyElementSource, NONE())});
        end if;

        // print("instElement -> component: " + name + " ty: " + Types.printTypeStr(ty) + "\n");
        //The environment is extended (updated) with the new variable binding.
        (cache, binding) = InstBinding.makeBinding(cache, env2, attr, mod, ty, pre, name, info);

        /*// uncomment this for debugging of bindings from mods
        print("Created binding for var: " +
           PrefixUtil.printPrefixStr(pre) + "." + name + "\n\t" +
           " binding: " + Types.printBindingStr(binding) + "\n\t" +
           " m: " + SCodeDump.printModStr(m) + "\n\t" +
           " class_mod: " + Mod.printModStr(class_mod) + "\n\t" +
           " mm: " + Mod.printModStr(mm) + "\n\t" +
           " var_class_mod: " + Mod.printModStr(mm) + "\n\t" +
           " m_1: " + Mod.printModStr(m_1) + "\n\t" +
           " cmod: " + Mod.printModStr(cmod) + "\n\t" +
           " mod: " + Mod.printModStr(mod) + "\n\t" +
           " mod_1: " + Mod.printModStr(mod_1) +
           "\n");*/

        dae_attr = DAEUtil.translateSCodeAttrToDAEAttr(attr, prefixes, comment);
        ty = Types.traverseType(ty, 1, Types.setIsFunctionPointer);
        new_var = DAE.TYPES_VAR(name, dae_attr, ty, binding, NONE());

        // Type info present. Now we can also put the binding into the dae.
        // If the type is one of the simple, predifined types a simple variable
        // declaration is added to the DAE.
        env = FGraph.updateComp(env2, new_var, FCore.VAR_DAE(), comp_env);
        vars = if already_declared then {} else {new_var};
        dae = if already_declared then DAE.emptyDae else dae;
        (_, ih, graph) = InnerOuter.handleInnerOuterEquations(io, DAE.emptyDae, ih, graph_new, graph);

      then
        (cache, env, ih, store, dae, csets, ci_state, vars, graph);

    //------------------------------------------------------------------------
    // MetaModelica Complex Types. Part of MetaModelica extension.
    //------------------------------------------------------------------------
    case (cache, env, ih, store, mods, pre, ci_state,
        (comp as SCode.COMPONENT(
          name,
          prefixes as SCode.PREFIXES(
            finalPrefix = final_prefix,
            innerOuter = io
            ),
          attr as SCode.ATTR(arrayDims = ad, connectorType = ct),
          ts as Absyn.TCOMPLEX(path = type_name), m, comment, cond, info), cmod),
        inst_dims, impl, _, graph, csets)
      equation
        true = Config.acceptMetaModelicaGrammar();

        // see if we have a modification on the inner component
        if SCode.finalBool(final_prefix) then
          m = InstUtil.traverseModAddFinal(m);
          comp = SCode.COMPONENT(name, prefixes, attr, ts, m, comment, cond, info);
        end if;

        // Fails if multiple decls not identical
        already_declared = InstUtil.checkMultiplyDeclared(cache, env, mods, pre,
          ci_state, (comp, cmod), inst_dims, impl);
        cref = ComponentReference.makeCrefIdent(name, DAE.T_UNKNOWN_DEFAULT, {});
        (cache,_) = PrefixUtil.prefixCref(cache, env, ih, pre, cref);


        // The types in the environment does not have correct Binding.
        // We must update those variables that is found in m into a new environment.
        own_cref = Absyn.CREF_IDENT(name, {}) ;
        // In case we want to EQBOUND a complex type, e.g. when declaring constants. /sjoelund 2009-10-30
        (cache, m_1) = Mod.elabMod(cache, env, ih, pre, m, impl, Mod.COMPONENT(name), info);

        //---------
        // We build up a class structure for the complex type
        id = Absyn.pathString(type_name);

        cls = SCode.CLASS(id, SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(),
          SCode.NOT_PARTIAL(), SCode.R_TYPE(), SCode.DERIVED(ts, SCode.NOMOD(),
          SCode.ATTR(ad, ct, SCode.NON_PARALLEL(), SCode.VAR(), Absyn.BIDIR())), SCode.noComment, info);

        // The variable declaration and the (optional) equation modification are inspected for array dimensions.
        // Gather all the dimensions
        // (Absyn.IDENT("Integer") is used as a dummy)
        (cache, dims) = InstUtil.elabArraydim(cache, env, own_cref, Absyn.IDENT("Integer"),
          ad, NONE(), impl, NONE(), true, false, pre, info, inst_dims);

        // Instantiate the component
        (cache, comp_env, ih, store, dae, csets, ty, graph_new) =
          InstVar.instVar(cache, env, ih, store,ci_state, m_1, pre, name, cls, attr,
            prefixes, dims, {}, inst_dims, impl, comment, info, graph, csets, env);

        // print("instElement -> component: " + n + " ty: " + Types.printTypeStr(ty) + "\n");

        // The environment is extended (updated) with the new variable binding.
        (cache, binding) = InstBinding.makeBinding(cache, env, attr, m_1, ty, pre, name, info);

        // true in update_frame means the variable is now instantiated.
        dae_attr = DAEUtil.translateSCodeAttrToDAEAttr(attr, prefixes, comment);
        ty = Types.traverseType(ty, 1, Types.setIsFunctionPointer);
        new_var = DAE.TYPES_VAR(name, dae_attr, ty, binding, NONE()) ;

        // type info present Now we can also put the binding into the dae.
        // If the type is one of the simple, predifined types a simple variable
        // declaration is added to the DAE.
        env = FGraph.updateComp(env, new_var, FCore.VAR_DAE(), comp_env);
        vars = if already_declared then {} else {new_var};
        dae = if already_declared then DAE.emptyDae else dae;
        (_, ih, graph) = InnerOuter.handleInnerOuterEquations(io, DAE.emptyDae, ih, graph_new, graph);
      then
        (cache, env, ih, store, dae, csets, ci_state, vars, graph);

    //------------------------------
    // If the class lookup in the previous rule fails, this rule catches the error
    // and prints an error message about the unknown class.
    // Failure => ({},env,csets,ci_state,{})
    case (cache, env, _, _, _, pre, ci_state,
        (SCode.COMPONENT(
          name = name,
          attributes = SCode.ATTR(variability = vt),
          typeSpec = Absyn.TPATH(t,_),
          info = info), _), _, _, _, _, _)
      equation
        failure((_, _, _) = Lookup.lookupClass(cache, env, t, false));
        // good for GDB debugging to re-run the instElement again
        // (cache, env, ih, store, dae, csets, ci_state, vars, graph) = instElement(inCache, inEnv, inIH, inUnitStore, inMod, inPrefix, inState, inElement, inInstDims, inImplicit, inCallingScope, inGraph, inSets);
        s = Absyn.pathString(t);
        scope_str = FGraph.printGraphPathStr(env);
        pre = PrefixUtil.prefixAdd(name, {}, {}, pre, vt, ci_state);
        ns = PrefixUtil.printPrefixStrIgnoreNoPre(pre);
        Error.addSourceMessage(Error.LOOKUP_ERROR_COMPNAME, {s, scope_str, ns}, info);
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("Lookup class failed:" + Absyn.pathString(t));
      then
        fail();

    case (_, env, _, _, _, _, _, (comp, _), _, _, _, _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Inst.instElement failed: " + SCodeDump.unparseElementStr(comp,SCodeDump.defaultOptions));
        Debug.traceln("  Scope: " + FGraph.printGraphPathStr(env));
      then
        fail();
  end matchcontinue;
end instElement;

protected function updateCompeltsMods
"never fail and *NEVER* display any error messages as this function
 prints non-true error messages and even so instElementList dependency
 analysis might work fine and still instantiate."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input list<tuple<SCode.Element, DAE.Mod>> inComponents;
  input ClassInf.State inState;
  input Boolean inBoolean;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output list<tuple<SCode.Element, DAE.Mod>> outComponents;
algorithm
  (outCache,outEnv,outIH,outComponents) :=
  matchcontinue (inCache,inEnv,inIH,inPrefix,inComponents,inState,inBoolean)

    /*
    case (_,_,_,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
      then
        (inCache,inEnv,inIH,inComponents);*/

    case (_,_,_,_,_,_,_)
      equation
        ErrorExt.setCheckpoint("updateCompeltsMods");
        (outCache,outEnv,outIH,outComponents) =
          updateCompeltsMods_dispatch(inCache,inEnv,inIH,inPrefix,inComponents,inState,inBoolean);
        ErrorExt.rollBack("updateCompeltsMods") "roll back any errors";
      then
        (outCache,outEnv,outIH,outComponents);

    else
      equation
        ErrorExt.rollBack("updateCompeltsMods") "roll back any errors";
      then
        (inCache,inEnv,inIH,inComponents);
  end matchcontinue;
end updateCompeltsMods;

protected function updateCompeltsMods_dispatch
"author: PA
  This function updates component modifiers to typed modifiers.
  Typed modifiers are needed  to merge modifiers and to be able to
  fully instantiate a component."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input list<tuple<SCode.Element, DAE.Mod>> inComponents;
  input ClassInf.State inState;
  input Boolean inBoolean;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output list<tuple<SCode.Element, DAE.Mod>> outComponents;
algorithm
  (outCache,outEnv,outIH,outComponents):=
  matchcontinue (inCache,inEnv,inIH,inPrefix,inComponents,inState,inBoolean)
    local
      FCore.Graph env,env2,env3;
      Prefix.Prefix pre;
      SCode.Mod umod;
      list<Absyn.ComponentRef> crefs,crefs_1;
      Absyn.ComponentRef cref;
      DAE.Mod cmod_1,cmod,cmod2,redMod;
      list<DAE.Mod> ltmod;
      list<tuple<SCode.Element, DAE.Mod>> res,xs;
      tuple<SCode.Element, DAE.Mod> elMod;
      SCode.Element comp,redComp;
      ClassInf.State ci_state;
      Boolean impl;
      FCore.Cache cache;
      InstanceHierarchy ih;
      String name;
      SourceInfo info;
      SCode.Final fprefix;

    case (cache,env,ih,_,{},_,_) then (cache,env,ih,{});

    // Instantiate the element if there is no mod
    case (cache,env,ih,pre,((elMod as (_,DAE.NOMOD())) :: xs),ci_state,impl)
      equation
        /*
        name = SCode.elementName(comp);
        cref = Absyn.CREF_IDENT(name,{});
        (cache,env,ih) = updateComponentsInEnv(cache, env, ih, pre, DAE.NOMOD(), {cref}, ci_state, impl);
        */
        (cache,env,ih,res) = updateCompeltsMods_dispatch(cache, env, ih, pre, xs, ci_state, impl);
      then
        (cache,env,ih,elMod::res);

    // Special case for components being redeclared, we might instantiate partial classes when instantiating var(-> instVar2->instClass) to update component in env.
    case (cache,env,ih,pre,((comp,(cmod as DAE.REDECL(_,_,{(redComp,_)}))) :: xs),ci_state,impl)
      equation
        info = SCode.elementInfo(redComp);
        umod = Mod.unelabMod(cmod);
        crefs = InstUtil.getCrefFromMod(umod);
        crefs_1 = InstUtil.getCrefFromCompDim(comp) "get crefs from dimension arguments";
        crefs = List.unionOnTrue(crefs,crefs_1,Absyn.crefEqual);
        name = SCode.elementName(comp);
        cref = Absyn.CREF_IDENT(name,{});
        ltmod = List.map1(crefs,InstUtil.getModsForDep,xs);
        cmod2 = List.fold2r(cmod::ltmod,Mod.merge,env,pre,DAE.NOMOD());
        SCode.PREFIXES(finalPrefix = fprefix) = SCode.elementPrefixes(comp);

        //print("("+intString(listLength(ltmod))+")UpdateCompeltsMods_(" + stringDelimitList(List.map(crefs,Absyn.printComponentRefStr),",") + ") subs: " + stringDelimitList(List.map(crefs,Absyn.printComponentRefStr),",")+ "\n");
        //print("REDECL     acquired mods: " + Mod.printModStr(cmod2) + "\n");
        (cache,env2,ih) = updateComponentsInEnv(cache, env, ih, pre, cmod2, crefs, ci_state, impl);
        (cache,env2,ih) = updateComponentsInEnv(cache, env2, ih, pre,
          DAE.MOD(fprefix,SCode.NOT_EACH(),{DAE.NAMEMOD(name, cmod)},NONE()),
          {cref}, ci_state, impl);
        (cache,cmod_1) = Mod.updateMod(cache, env2, ih, pre, cmod, impl, info);
        (cache,env3,ih,res) = updateCompeltsMods_dispatch(cache, env2, ih, pre, xs, ci_state, impl);
      then
        (cache,env3,ih,((comp,cmod_1) :: res));

    // If the modifier has already been updated, just update the environment with it.
    case (cache,env,ih,pre,((comp, cmod as DAE.MOD()) :: xs),ci_state,impl)
      equation
        false = Mod.isUntypedMod(cmod);
        name = SCode.elementName(comp);
        cref = Absyn.CREF_IDENT(name,{});
        SCode.PREFIXES(finalPrefix = fprefix) = SCode.elementPrefixes(comp);

        (cache,env2,ih) = updateComponentsInEnv(cache, env, ih, pre,
          DAE.MOD(fprefix,SCode.NOT_EACH(),{DAE.NAMEMOD(name, cmod)},NONE()),
          {cref}, ci_state, impl);
        (cache,env3,ih,res) = updateCompeltsMods_dispatch(cache, env2, ih, pre, xs, ci_state, impl);
      then
        (cache,env3,ih,((comp,cmod) :: res));

    case (cache,env,ih,pre,((comp, cmod as DAE.MOD()) :: xs),ci_state,impl)
      equation
        info = SCode.elementInfo(comp);
        umod = Mod.unelabMod(cmod);
        crefs = InstUtil.getCrefFromMod(umod);
        crefs_1 = InstUtil.getCrefFromCompDim(comp);
        crefs = List.unionOnTrue(crefs,crefs_1,Absyn.crefEqual);
        name = SCode.elementName(comp);
        cref = Absyn.CREF_IDENT(name,{});

        ltmod = List.map1(crefs,InstUtil.getModsForDep,xs);
        cmod2 = List.fold2r(ltmod,Mod.merge,env,pre,DAE.NOMOD());
        SCode.PREFIXES(finalPrefix = fprefix) = SCode.elementPrefixes(comp);

        //print("("+intString(listLength(ltmod))+")UpdateCompeltsMods_(" + stringDelimitList(List.map(crefs,Absyn.printComponentRefStr),",") + ") subs: " + stringDelimitList(List.map(crefs,Absyn.printComponentRefStr),",")+ "\n");
        //print("     acquired mods: " + Mod.printModStr(cmod2) + "\n");

        (cache,env2,ih) = updateComponentsInEnv(cache, env, ih, pre, cmod2, crefs, ci_state, impl);
        (cache,env2,ih) = updateComponentsInEnv(cache, env2, ih, pre,
          DAE.MOD(fprefix,SCode.NOT_EACH(),{DAE.NAMEMOD(name, cmod)},NONE()),
          {cref}, ci_state, impl);

        (cache,cmod_1) = Mod.updateMod(cache, env2, ih, pre, cmod, impl, info);
        (cache,env3,ih,res) = updateCompeltsMods_dispatch(cache, env2, ih, pre, xs, ci_state, impl);
      then
        (cache,env3,ih,((comp,cmod_1) :: res));

  end matchcontinue;
end updateCompeltsMods_dispatch;

public function redeclareType
"This function takes a DAE.Mod and an SCode.Element and if the modification
  contains a redeclare of that element, the type is changed and an updated
  element is returned."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input SCode.Element inElement;
  input Prefix.Prefix inPrefix;
  input ClassInf.State inState;
  input Boolean inImplicit;
  input DAE.Mod inCmod;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output SCode.Element outElement;
  output DAE.Mod outMod;
algorithm
  (outCache,outEnv,outIH,outElement,outMod) := matchcontinue (inCache,inEnv,inIH,inMod,inElement,inPrefix,inState,inImplicit,inCmod)
    local
      list<Absyn.ComponentRef> crefs;
      FCore.Graph env_1,env;
      DAE.Mod m_1,old_m_1,m_2,m_3,m,rmod,innerCompMod,compMod;
      SCode.Element redecl,newcomp,comp,redComp, cl;
      String n1,n2;
      SCode.Final finalPrefix,redfin;
      SCode.Each each_;
      SCode.Replaceable repl,repl2;
      SCode.Visibility vis, vis2;
      SCode.Redeclare redeclp;
      Boolean impl;
      Absyn.TypeSpec t,t2;
      SCode.Mod mod,old_mod;
      SCode.Comment comment;
      list<tuple<SCode.Element, DAE.Mod>> rest;
      Prefix.Prefix pre;
      ClassInf.State ci_state;
      FCore.Cache cache;
      InstanceHierarchy ih;
      DAE.Mod cmod;

      Option<SCode.ConstrainClass> cc;
      list<SCode.Element> compsOnConstrain;
      Absyn.InnerOuter io;
      SCode.Attributes at, at2;
      Option<Absyn.Exp> cond;
      SourceInfo info;
      Absyn.TypeSpec apt;
      Absyn.Path path;

    // uncomment for debugging!
    case (_,_,_,DAE.REDECL(),_,
          _,_,_,_)
      equation
        // fprintln(Flags.INST_TRACE, "redeclareType\nmodifier: " + Mod.printModStr(inMod) + "\nelement\n:" + SCodeDump.unparseElementStr(inElement));
      then
        fail();


    // constraining type on the component
    case (cache,env,ih,(DAE.REDECL(tplSCodeElementModLst = ((( redComp as SCode.COMPONENT(name = n1,
                            modifications = mod,
                            info = info
                            )),rmod) :: _))),
          // adrpo: always take the inner outer from the component, not the redeclaration!!!!
          comp as SCode.COMPONENT(name = n2,
                          prefixes = SCode.PREFIXES(
                            finalPrefix = SCode.NOT_FINAL(),
                            replaceablePrefix = SCode.REPLACEABLE((cc as SOME(_)))),
                          modifications = old_mod),
          pre,ci_state,impl,cmod)
      equation
        true = stringEq(n1, n2);
        mod = InstUtil.chainRedeclares(inMod, mod);
        compsOnConstrain = InstUtil.extractConstrainingComps(cc,env,pre) "extract components belonging to constraining class";
        crefs = InstUtil.getCrefFromMod(mod);
        (cache,env_1,ih) = updateComponentsInEnv(cache, env, ih, pre, DAE.NOMOD(), crefs, ci_state, impl);
        (cache,m_1) = Mod.elabMod(cache,env_1, ih, pre, mod, impl, Mod.COMPONENT(n1), info);
        (cache,old_m_1) = Mod.elabMod(cache,env_1, ih, pre, old_mod, impl, Mod.COMPONENT(n2), info);

        rmod = InstUtil.keepConstrainingTypeModifersOnly(rmod, compsOnConstrain) "keep previous constrainingclass mods";
        old_m_1 = InstUtil.keepConstrainingTypeModifersOnly(old_m_1, compsOnConstrain) "keep previous constrainingclass mods";

        m_2 = Mod.merge(m_1, rmod, env_1, pre);
        m_3 = Mod.merge(m_2, old_m_1, env_1, pre);
        m_3 = Mod.merge(m_3, cmod, env_1, pre);

        (cache, redecl) = propagateRedeclCompAttr(cache, env_1, comp, redComp);
        redecl = SCode.setComponentMod(redecl, mod);
      then
        (cache,env_1,ih,redecl,m_3);

    // no constraining type on comp, throw away modifiers prior to redeclaration
    case (cache,env,ih,(DAE.REDECL(tplSCodeElementModLst = (((redComp as
          SCode.COMPONENT(name = n1,
                          modifications = mod,
                          info = info
                          )),rmod) :: _))),
          // adrpo: always take the inner outer from the component, not the redeclaration!!!!
          comp as SCode.COMPONENT(name = n2,
                          prefixes = SCode.PREFIXES(
                            finalPrefix = SCode.NOT_FINAL(),
                            replaceablePrefix = SCode.REPLACEABLE(NONE())),
                          modifications = old_mod),
          pre,ci_state,impl,cmod)
      equation
        true = stringEq(n1, n2);
        mod = InstUtil.chainRedeclares(inMod, mod);
        crefs = InstUtil.getCrefFromMod(mod);
        (cache,env_1,ih) = updateComponentsInEnv(cache,env,ih, pre, DAE.NOMOD(), crefs, ci_state, impl) "m" ;
        (cache,m_1) = Mod.elabMod(cache, env_1, ih, pre, mod, impl, Mod.COMPONENT(n1), info);
        (cache,old_m_1) = Mod.elabMod(cache, env_1, ih, pre, old_mod, impl, Mod.COMPONENT(n2), info);
        m_2 = Mod.merge(rmod, m_1, env_1, pre);
        m_3 = Mod.merge(m_2, old_m_1, env_1, pre);
        m_3 = Mod.merge(cmod, m_3 ,env_1,pre);

        (cache, redecl) = propagateRedeclCompAttr(cache, env_1, comp, redComp);
        redecl = SCode.setComponentMod(redecl, mod);
      then
        (cache,env_1,ih,redecl,m_3);

    // redeclaration of classes:
    case (cache,env,ih,
          (m as DAE.REDECL(tplSCodeElementModLst = (((redecl as SCode.CLASS(name = n1) ),rmod) :: _))),
          SCode.CLASS(name = n2),pre,ci_state,impl,_)
      equation
        true = stringEq(n1, n2);
        //crefs = InstUtil.getCrefFromMod(mod);
        (cache,env_1,ih) = updateComponentsInEnv(cache,env,ih, pre, m, {Absyn.CREF_IDENT(n2,{})}, ci_state, impl) "m" ;
        //(cache,m_1) = Mod.elabMod(cache, env_1, ih, pre, mod, impl);
        //(cache,old_m_1) = Mod.elabMod(cache, env_1, ih, pre, old_mod, impl);
        // m_2 = Mod.merge(rmod, m_1, env_1, pre);
        // m_3 = Mod.merge(m_2, old_m_1, env_1, pre);
      then
        (cache,env_1,ih,redecl,rmod);

    // local redeclaration of class type path is an id
    case (cache,env,ih,(m as DAE.REDECL(tplSCodeElementModLst = (((SCode.CLASS(name = n1) ),rmod) :: _))),
        redecl as SCode.COMPONENT(typeSpec = apt),pre,ci_state,impl,_)
      equation
        n2 = Absyn.typeSpecPathString(apt);
        true = stringEq(n1, n2);
        (cache,env_1,ih) = updateComponentsInEnv(cache,env,ih, pre, m, {Absyn.CREF_IDENT(n2,{})}, ci_state, impl) "m" ;
      then
        (cache,env_1,ih,redecl,rmod);

    // local redeclaration of class, type is qualified
    case (cache,env,ih,(m as DAE.REDECL(tplSCodeElementModLst = (((SCode.CLASS(name = n1) ),rmod) :: _))),
        redecl as SCode.COMPONENT(typeSpec = Absyn.TPATH(path, _)),pre,ci_state,impl,_)
      equation
        n2 = Absyn.pathFirstIdent(path);
        true = stringEq(n1, n2);
        (cache,env_1,ih) = updateComponentsInEnv(cache, env, ih, pre, m, {Absyn.CREF_IDENT(n2,{})}, ci_state, impl) "m" ;
      then
        (cache,env_1,ih,redecl,rmod);

    case (cache,env,ih,(DAE.REDECL(finalPrefix = redfin, eachPrefix = each_, tplSCodeElementModLst = (((          SCode.COMPONENT(name = n1)),_) :: rest))),
          (comp as SCode.COMPONENT(name = n2,prefixes = SCode.PREFIXES(finalPrefix = SCode.NOT_FINAL()))),
          pre,ci_state,impl,cmod)
      equation
        false = stringEq(n1, n2);
        (cache,env_1,ih,newcomp,m) =
          redeclareType(cache, env, ih, DAE.REDECL(redfin,each_,rest), comp, pre, ci_state, impl, cmod);
      then
        (cache,env_1,ih,newcomp,m);

    case (cache,env,ih,DAE.REDECL(finalPrefix = redfin,eachPrefix = each_,tplSCodeElementModLst = (_ :: rest)),comp,pre,ci_state,impl,cmod)
      equation
        (cache,env_1,ih,newcomp,m) =
          redeclareType(cache, env, ih, DAE.REDECL(redfin,each_,rest), comp, pre, ci_state, impl,cmod);
      then
        (cache,env_1,ih,newcomp,m);

    case (cache,env,ih,DAE.REDECL(tplSCodeElementModLst = {}),comp,_,_,_,_)
      then (cache,env,ih,comp,DAE.NOMOD());

    case (cache,env,ih,m,comp,pre,_,_,cmod)
      equation
        m = Mod.merge(m, cmod, env, pre);
      then
        (cache,env,ih,comp,m);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Inst.redeclareType failed\n");
      then
        fail();
  end matchcontinue;
end redeclareType;

protected function propagateRedeclCompAttr
  "Helper function to redeclareType, propagates attributes from the old
   component to the new according to the rules for redeclare."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.Element inOldComponent;
  input SCode.Element inNewComponent;
  output FCore.Cache outCache = inCache;
  output SCode.Element outComponent;
protected
  Boolean is_array = false;
algorithm
  // If the old component has array dimensions but the new one doesn't, then we
  // need to check if the new component's type is an array type. If it is we
  // shouldn't propagate the dimensions from the old component. I.e. we should
  // treat: type Real3 = Real[3]; comp(redeclare Real3 x);
  // in the same way as: comp(redeclare Real x[3]).
  if SCode.isArrayComponent(inOldComponent) and not SCode.isArrayComponent(inNewComponent) then
    (outCache, is_array) := Lookup.isArrayType(outCache, inEnv,
      Absyn.typeSpecPath(SCode.getComponentTypeSpec(inNewComponent)));
  end if;

  outComponent := SCode.propagateAttributesVar(inOldComponent, inNewComponent, is_array);
end propagateRedeclCompAttr;

protected function updateComponentsInEnv
"author: PA
  This function is the second pass of component instantiation, when a
  component can be instantiated fully and the type of the component can be
  determined. The type is added/updated to the environment such that other
  components can use it when they are instantiated."
  input FCore.Cache cache;
  input FCore.Graph env;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix pre;
  input DAE.Mod mod;
  input list<Absyn.ComponentRef> crefs;
  input ClassInf.State ci_state;
  input Boolean impl;
  output FCore.Cache outCache = cache;
  output FCore.Graph outEnv = env;
  output InnerOuter.InstHierarchy outIH = inIH;
algorithm
  ErrorExt.setCheckpoint("updateComponentsInEnv__");

  // do NOT fail and do not display any errors from this function as it tries
  // to type and evaluate dependent things but not with enough information
  try
    (outCache, outEnv, outIH) :=
      updateComponentsInEnv2(cache, env, inIH, pre, mod, crefs, ci_state, impl);
  else
  end try;

  ErrorExt.rollBack("updateComponentsInEnv__") "roll back any errors";
end updateComponentsInEnv;

protected function getUpdatedCompsHashTable
  "Routine to lazily create the hashtable as it usually unused"
  input Option<HashTable5.HashTable> optHT;
  output HashTable5.HashTable ht;
algorithm
  ht := match optHT
    case SOME(ht) then ht;
    else HashTable5.emptyHashTableSized(BaseHashTable.lowBucketSize);
  end match;
end getUpdatedCompsHashTable;

protected function updateComponentInEnv
  "Helper function to updateComponentsInEnv. Does the work for one variable."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix pre;
  input DAE.Mod mod;
  input Absyn.ComponentRef cref;
  input ClassInf.State inCIState;
  input Boolean impl;
  input Option<HashTable5.HashTable> inUpdatedComps;
  input Option<Absyn.ComponentRef> currentCref "The cref that caused this call to updateComponentInEnv.";
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output Option<HashTable5.HashTable> outUpdatedComps;
algorithm
  (outCache,outEnv,outIH,outUpdatedComps) :=
  matchcontinue (inCache,inEnv,inIH,pre,mod,cref,inCIState,impl,inUpdatedComps,currentCref)
    local
      String n,id, nn, name, id2;
      SCode.ConnectorType ct;
      Absyn.InnerOuter io;
      SCode.Attributes attr;
      list<Absyn.Subscript> ad;
      SCode.Parallelism prl1;
      SCode.Variability var1;
      Absyn.Direction dir;
      Absyn.Path t;
      Absyn.TypeSpec tsNew;
      SCode.Mod m;
      SCode.Comment comment;
      DAE.Mod cmod,mods,rmod;
      SCode.Element cl, compNew;
      FCore.Graph cenv,env2,env_1;
      list<Absyn.ComponentRef> crefs,crefs2,crefs3,crefs_1,crefs_2;
      Option<Absyn.Exp> cond;
      DAE.Var tyVar;
      FCore.Status is;
      SourceInfo info;
      InstanceHierarchy ih;
      SCode.Prefixes pf;
      DAE.Attributes dae_attr;
      SCode.Visibility visibility "protected/public";
      DAE.Type ty "type";
      DAE.Binding binding "equation modification";
      Option<DAE.Const> cnstOpt "the constant-ness of the range if this is a for iterator, NONE() if is NOT a for iterator";
      SCode.Mod smod;
      DAE.Mod daeMod;
      SCode.Prefixes prefixes;
      SCode.Attributes attributes;
      FCore.Graph compenv, env, idENV;
      FCore.Status instStatus;
      FCore.Cache cache;
      HashTable5.HashTable updatedComps;
      ClassInf.State ci_state;

    // if there are no modifications, return the same!
    //case (cache,env,ih,pre,DAE.NOMOD(),cref,ci_state,csets,impl,_)
    //  then
    //    (cache,env,ih,csets,updatedComps);

    // if we have a redeclare for a component
    /*case (cache,env,ih,_,
        DAE.MOD(eqModOption = NONE(),
                subModLst = {
                  DAE.NAMEMOD(ident=n,
                  mod = rmod as DAE.REDECL(_, _, {(SCode.COMPONENT(name = name),_)}))}),_,_,_,_,_)
      equation
        id = Absyn.crefFirstIdent(cref);
        true = stringEq(id, name);
        true = stringEq(id, n);
        (outCache,outEnv,outIH,outUpdatedComps) = updateComponentInEnv(inCache,inEnv,inIH,pre,rmod,cref,inCIState,impl,inUpdatedComps,currentCref);
      then
        (outCache,outEnv,outIH,outUpdatedComps);*/

    // if we have a redeclare for a component
    case (cache,env,ih,_,
        DAE.REDECL(_, _, {
         (SCode.COMPONENT(
             name = name,
             prefixes = prefixes as SCode.PREFIXES(visibility = visibility),
             attributes = attributes,
             modifications = smod,
             info = info),_)}),_,_,_,_,_)
      equation
        id = Absyn.crefFirstIdent(cref);
        true = stringEq(id, name);
        // redeclare with modfication!!
        false = valueEq(smod, SCode.NOMOD());

        // get Var
        (cache,DAE.TYPES_VAR(_,_,_,_,_),_,_,_,_) = Lookup.lookupIdentLocal(cache, env, name);
        // types are the same, this means only the binding/visibility, etc was updated!
        //true = valueEq(tsOld, tsNew);

        // update frame in env!
        // fprintln(Flags.INST_TRACE, "updateComponentInEnv: found a redeclaration that only changes bindings and prefixes: NEW:\n" + SCodeDump.unparseElementStr(compNew) + " in env:" + FGraph.printGraphPathStr(env));

        // update the mod then give it to
        (cache, daeMod) = Mod.elabMod(cache, env, ih, pre, smod, impl, Mod.COMPONENT(name), info);

        // take the mods and attributes from the new comp!
        mods = daeMod;
        attr = attributes;
        m = smod;
        cmod = DAE.NOMOD();
        pf = prefixes;
        io = SCode.prefixesInnerOuter(pf);
        SCode.ATTR(ad,ct,prl1,var1,dir) = attr;

        (cache,_,SCode.COMPONENT(n,_,_,Absyn.TPATH(t, _),_,_,cond,info),_,_,idENV)
          = Lookup.lookupIdent(cache, env, id);

        ci_state = InstUtil.updateClassInfState(cache, idENV, env, inCIState);

        //Debug.traceln("update comp " + n + " with mods:" + Mod.printModStr(mods) + " m:" + SCodeDump.printModStr(m) + " cm:" + Mod.printModStr(cmod));
        (cache,cl,cenv) = Lookup.lookupClass(cache, env, t, false);
        //Debug.traceln("got class " + SCodeDump.printClassStr(cl));
        updatedComps = getUpdatedCompsHashTable(inUpdatedComps);
        (mods,cmod,m) = InstUtil.noModForUpdatedComponents(var1,updatedComps,cref,mods,cmod,m);
        crefs = InstUtil.getCrefFromMod(m);
        crefs2 = InstUtil.getCrefFromDim(ad);
        crefs3 = InstUtil.getCrefFromCond(cond);
        crefs_1 = listAppend(listAppend(crefs, crefs2),crefs3);
        crefs_2 = InstUtil.removeCrefFromCrefs(crefs_1, cref);
        updatedComps = BaseHashTable.add((cref,0),updatedComps);
        (cache,env2,ih,SOME(updatedComps)) = updateComponentsInEnv2(cache, env, ih, pre, DAE.NOMOD(), crefs_2, ci_state, impl, SOME(updatedComps), SOME(cref));

        (cache,env_1,ih,updatedComps) = updateComponentInEnv2(cache,env2,cenv,ih,pre,t,n,ad,cl,attr,pf,DAE.ATTR(ct,prl1,var1,dir,io,visibility),info,m,cmod,mods,cref,ci_state,impl,updatedComps);

        //print("updateComponentInEnv: NEW ENV:\n" + FGraph.printGraphStr(env_1) + "\n");
      then
        (cache,env_1,ih,SOME(updatedComps));

    // redeclare class!
    case (cache,env,ih,_,DAE.REDECL(_, _, {(compNew as SCode.CLASS(name = name),_)}),_,_,_,_,_)
      equation
        id = Absyn.crefFirstIdent(cref);
        true = stringEq(name, id);
        // fetch the original class!
        (cl, _) = Lookup.lookupClassLocal(env, name);
        env = FGraph.updateClass(env, SCode.mergeWithOriginal(compNew, cl), pre, mod, FCore.CLS_UNTYPED(), env);
        updatedComps = getUpdatedCompsHashTable(inUpdatedComps);
        updatedComps = BaseHashTable.add((cref,0),updatedComps);
      then
        (cache,env,ih,SOME(updatedComps));

    // Variable with NONE() element is already instantiated.
    case (cache,env,ih,_,_,_,_,_,_,_)
      equation
        id = Absyn.crefFirstIdent(cref);
        (cache,_,_,_,is,_) = Lookup.lookupIdent(cache,env,id);
        true = FCore.isTyped(is) "If InstStatus is typed, return";
      then
        (cache,env,ih,inUpdatedComps);

    // the default case
    case (cache,env,ih,_,mods,_,_,_,_,_)
      equation
        id = Absyn.crefFirstIdent(cref);
        (cache,_,
          SCode.COMPONENT(
            n,
            pf as SCode.PREFIXES(innerOuter = io, visibility = visibility),
            attr as SCode.ATTR(ad,ct,prl1,var1,dir),
            Absyn.TPATH(t, _),m,_,cond,info),cmod,_,idENV)
          = Lookup.lookupIdent(cache, env, id);

        ci_state = InstUtil.updateClassInfState(cache, idENV, env, inCIState);

        //Debug.traceln("update comp " + n + " with mods:" + Mod.printModStr(mods) + " m:" + SCodeDump.printModStr(m) + " cm:" + Mod.printModStr(cmod));
        (cache,cl,cenv) = Lookup.lookupClass(cache, env, t, false);
        //Debug.traceln("got class " + SCodeDump.printClassStr(cl));
        updatedComps = getUpdatedCompsHashTable(inUpdatedComps);
        (mods,cmod,m) = InstUtil.noModForUpdatedComponents(var1,updatedComps,cref,mods,cmod,m);
        crefs = InstUtil.getCrefFromMod(m);
        crefs2 = InstUtil.getCrefFromDim(ad);
        crefs3 = InstUtil.getCrefFromCond(cond);
        crefs_1 = listAppend(listAppend(crefs, crefs2),crefs3);
        crefs = Mod.getUntypedCrefs(cmod);
        crefs_1 = listAppend(crefs_1, crefs);
        crefs_2 = InstUtil.removeCrefFromCrefs(crefs_1, cref);
        // Also remove the cref that caused this updateComponentInEnv call, to avoid
        // infinite loops.
        crefs_2 = InstUtil.removeOptCrefFromCrefs(crefs_2, currentCref);
        updatedComps = BaseHashTable.add((cref,0),updatedComps);
        (cache,env2,ih,SOME(updatedComps)) = updateComponentsInEnv2(cache, env, ih, pre, mods, crefs_2, ci_state, impl, SOME(updatedComps), SOME(cref));
        (cache,env_1,ih,updatedComps) = updateComponentInEnv2(cache,env2,cenv,ih,pre,t,n,ad,cl,attr,pf,DAE.ATTR(ct,prl1,var1,dir,io,visibility),info,m,cmod,mods,cref,ci_state,impl,updatedComps);
      then
        (cache,env_1,ih,SOME(updatedComps));

    // If first part of ident is a class, e.g StateSelect.None, nothing to update
    case (cache,env,ih,_,_,_,_,_,_,_)
      equation
        _ = Absyn.crefFirstIdent(cref);
        // (cache,_,_) = Lookup.lookupClass(cache,env, Absyn.IDENT(id), false);
      then
        (cache,env,ih,inUpdatedComps);
    // report an error!
    case (_,env,_,_,_,_,_,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Inst.updateComponentInEnv failed, cref = " + Dump.printComponentRefStr(cref));
        Debug.traceln(" mods: " + Mod.printModStr(mod));
        Debug.traceln(" scope: " + FGraph.printGraphPathStr(env));
        Debug.traceln(" prefix: " + PrefixUtil.printPrefixStr(pre));
        //print("Env:\n" + FGraph.printGraphStr(env) + "\n");
      then
        fail();

    else (inCache,inEnv,inIH,inUpdatedComps);
  end matchcontinue;
end updateComponentInEnv;

protected function updateComponentInEnv2
" Helper function, checks if the component was already instantiated.
  If it was, don't do it again."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input FCore.Graph cenv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix pre;
  input Absyn.Path path;
  input String name;
  input list<Absyn.Subscript> ad;
  input SCode.Element cl;
  input SCode.Attributes attr;
  input SCode.Prefixes inPrefixes;
  input DAE.Attributes dattr;
  input SourceInfo info;
  input SCode.Mod m;
  input DAE.Mod cmod;
  input DAE.Mod mod;
  input Absyn.ComponentRef cref;
  input ClassInf.State ci_state;
  input Boolean impl;
  input HashTable5.HashTable inUpdatedComps;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output HashTable5.HashTable outUpdatedComps;
algorithm
  try
    ErrorExt.setCheckpoint("Inst.updateComponentInEnv2");
    (outCache, outEnv, outIH, outUpdatedComps) :=
      updateComponentInEnv2_dispatch(inCache, inEnv, cenv, inIH, pre, path,
        name, ad, cl, attr, inPrefixes, dattr, info, m, cmod, mod, cref,
        ci_state, impl, inUpdatedComps);
    ErrorExt.delCheckpoint("Inst.updateComponentInEnv2");
  else
    ErrorExt.rollBack("Inst.updateComponentInEnv2");
    fail();
  end try;
end updateComponentInEnv2;

protected function updateComponentInEnv2_dispatch
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input FCore.Graph inClsEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input Absyn.Path inPath;
  input String inName;
  input list<Absyn.Subscript> inSubscripts;
  input SCode.Element inClass;
  input SCode.Attributes inAttr;
  input SCode.Prefixes inPrefixes;
  input DAE.Attributes inDAttr;
  input SourceInfo inInfo;
  input SCode.Mod inSMod;
  input DAE.Mod inClsMod;
  input DAE.Mod inMod;
  input Absyn.ComponentRef inCref;
  input ClassInf.State inState;
  input Boolean inImpl;
  input HashTable5.HashTable inUpdatedComps;
  output FCore.Cache outCache = inCache;
  output FCore.Graph outEnv = inEnv;
  output InnerOuter.InstHierarchy outIH = inIH;
  output HashTable5.HashTable outUpdatedComps = inUpdatedComps;
protected
  SCode.Mod smod;
  DAE.Mod mod, mod1, mod2, class_mod, comp_mod;
  Option<DAE.EqMod> eq;
  Absyn.ComponentRef own_cref;
  list<DAE.Dimension> dims;
  FCore.Graph cls_env, comp_env;
  SCode.Element cls;
  DAE.Type ty;
  DAE.Binding binding;
  DAE.Var var;
algorithm
  try
    1 := BaseHashTable.get(inCref, inUpdatedComps);
  else
    smod := SCode.mergeModifiers(inSMod, SCodeUtil.getConstrainedByModifiers(inPrefixes));
    (outCache, mod1) :=
      updateComponentInEnv3(outCache, outEnv, outIH, smod, inImpl, Mod.COMPONENT(inName), inInfo);
    class_mod := Mod.lookupModificationP(inMod, inPath);
    comp_mod := Mod.lookupCompModification(inMod, inName);
    mod2 := Mod.merge(class_mod, comp_mod, outEnv, Prefix.NOPRE());
    mod2 := Mod.merge(mod2, mod1, outEnv, Prefix.NOPRE());
    mod2 := Mod.merge(inClsMod, mod2, outEnv, Prefix.NOPRE());
    (outCache, mod2) :=
      Mod.updateMod(outCache, outEnv, outIH, Prefix.NOPRE(), mod2, inImpl, inInfo);

    mod := if InstUtil.redeclareBasicType(comp_mod) then mod1 else mod2;
    eq := Mod.modEquation(mod);

    own_cref := Absyn.CREF_IDENT(inName, {});
    (outCache, dims) := InstUtil.elabArraydim(outCache, outEnv, own_cref, inPath,
      inSubscripts, eq, inImpl, NONE(), true, false, inPrefix, inInfo, {});

    // Instantiate the component.
    (cls_env, cls, outIH) :=
      FGraph.createVersionScope(outEnv, inName, inPrefix, mod, inClsEnv, inClass, outIH);
    (outCache, comp_env, outIH, _, _, _, ty) :=
      InstVar.instVar(outCache, cls_env, outIH, UnitAbsyn.noStore, inState, mod,
        inPrefix, inName, cls, inAttr, inPrefixes, dims, {}, {}, inImpl,
        SCode.noComment, inInfo, ConnectionGraph.EMPTY, Connect.emptySet, outEnv);

    // The environment is extended with the new variable binding.
    (outCache, binding) :=
      InstBinding.makeBinding(outCache, outEnv, inAttr, mod, ty, inPrefix, inName, inInfo);
    var := DAE.TYPES_VAR(inName, inDAttr, ty, binding, NONE());
    outEnv := FGraph.updateComp(outEnv, var, FCore.VAR_TYPED(), comp_env);
    outUpdatedComps := BaseHashTable.add((inCref, 1), outUpdatedComps);
  end try;
end updateComponentInEnv2_dispatch;

protected function updateComponentInEnv3
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input SCode.Mod inMod;
  input Boolean inImpl;
  input Mod.ModScope inModScope;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Mod outMod;
algorithm
  (outCache, outMod) :=
  matchcontinue(inCache, inEnv, inIH, inMod, inImpl, inModScope, inInfo)
    local
      DAE.Mod mod;
      FCore.Cache cache;

    case (_, _, _, _, _, _, _)
      equation
        ErrorExt.setCheckpoint("updateComponentInEnv3");
        (cache, mod) = Mod.elabMod(inCache, inEnv, inIH, Prefix.NOPRE(), inMod, inImpl, inModScope, inInfo)
        "Prefix does not matter, since we only update types
         in env, and does not make any dae elements, etc.." ;
        ErrorExt.rollBack("updateComponentInEnv3")
        "Rollback all error since we are only interested in type, not value at
         this point. Errors that occur in elabMod which does not fail the
         function will be accepted.";
      then
        (cache, mod);

    /*/ did not work, elab it untyped!
    case (cache, _, _, _, _, _)
      equation
        ErrorExt.rollBack("updateComponentInEnv3");
        ErrorExt.setCheckpoint("updateComponentInEnv3");
        mod = Mod.elabUntypedMod(inMod, inEnv, Prefix.NOPRE());
        ErrorExt.rollBack("updateComponentInEnv3")
        "Rollback all error since we are only interested in type, not value at
         this point. Errors that occur in elabMod which does not fail the
         function will be accepted.";
      then
        (cache, mod);*/

    else
      equation
        ErrorExt.rollBack("updateComponentInEnv3");
      then
        fail();
  end matchcontinue;
end updateComponentInEnv3;

public function makeEnvFromProgram
"This function takes a SCode.Program and builds an environment."
  input FCore.Cache inCache;
  input SCode.Program prog;
  input SCode.Path path;
  output FCore.Cache outCache;
  output FCore.Graph env_1;
protected
  FCore.Graph env;
  FCore.Cache cache;
algorithm
  // prog := scodeFlatten(prog, path);
  (cache, env) := Builtin.initialGraph(inCache);
  env_1 := FGraphBuildEnv.mkProgramGraph(prog, FCore.USERDEFINED(),env);
  outCache := cache;
end makeEnvFromProgram;

public function makeFullyQualified
"author: PA
  Transforms a class name to its fully qualified name by investigating the environment.
  For instance, the model Resistor in Modelica.Electrical.Analog.Basic will given the
  correct environment have the fully qualified name: Modelica.Electrical.Analog.Basic.Resistor"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  output FCore.Cache outCache;
  output Absyn.Path outPath;
algorithm
  (outCache,outPath) := matchcontinue (inCache,inEnv,inPath)
    local
      FCore.Graph env,env_1;
      Absyn.Path path,path_2,path3;
      String s;
      FCore.Cache cache;
      SCode.Element cl;
      DAE.ComponentRef crPath;
      FCore.Graph fs;
      Absyn.Ident name, ename;
      FCore.Ref r;

    // Special cases: assert and reinit can not be handled by builtin.mo, since they do not have return type
    case(cache,_,path as Absyn.IDENT("assert")) then (cache,path);
    case(cache,_,path as Absyn.IDENT("reinit")) then (cache,path);

    // Other functions that can not be represented in env due to e.g. applicable to any record
    case(cache,_,path as Absyn.IDENT("smooth")) then (cache,path);

    // MetaModelica extensions
    case (cache,_,path as Absyn.IDENT("list"))        equation true = Config.acceptMetaModelicaGrammar(); then (cache,path);
    case (cache,_,path as Absyn.IDENT("Option"))      equation true = Config.acceptMetaModelicaGrammar(); then (cache,path);
    case (cache,_,path as Absyn.IDENT("tuple"))       equation true = Config.acceptMetaModelicaGrammar(); then (cache,path);
    case (cache,_,path as Absyn.IDENT("polymorphic")) equation true = Config.acceptMetaModelicaGrammar(); then (cache,path);
    case (cache,_,path as Absyn.IDENT("array"))       equation true = Config.acceptMetaModelicaGrammar(); then (cache,path);
    // -------------------------

    // do NOT fully quallify again a fully qualified path!
    case (cache,_,Absyn.FULLYQUALIFIED(_)) then (cache, inPath);

    // To make a class fully qualified, the class path is looked up in the environment.
    // The FQ path consist of the simple class name appended to the environment path of the looked up class.
    case (cache,env,path)
      equation
        (cache,SCode.CLASS(name = name),env_1) = Lookup.lookupClass(cache, env, path, false);
        path_2 = makeFullyQualified2(env_1,Absyn.IDENT(name));
      then
        (cache,Absyn.makeFullyQualified(path_2));

    // Needed to make external objects fully-qualified
    case (cache,env,Absyn.IDENT(s))
      equation
        r = FGraph.lastScopeRef(env);
        false = FNode.isRefTop(r);
        name = FNode.refName(r);
        true = name == s;
        SOME(path_2) = FGraph.getScopePath(env);
      then
        (cache,Absyn.makeFullyQualified(path_2));

    // A type can exist without a class (i.e. builtin functions)
    case (cache,env,path as Absyn.IDENT(s))
      equation
         (cache,_,env_1) = Lookup.lookupType(cache,env, Absyn.IDENT(s), NONE());
         path_2 = makeFullyQualified2(env_1,path);
      then
        (cache,Absyn.makeFullyQualified(path_2));

     // A package constant, first try to look it up local (top frame)
    case (cache,env,path)
      equation
        crPath = ComponentReference.pathToCref(path);
        (cache,_,_,_,_,_,env,_,name) = Lookup.lookupVarInternal(cache, env, crPath, InstTypes.SEARCH_ALSO_BUILTIN());
        path3 = makeFullyQualified2(env,Absyn.IDENT(name));
      then
        (cache,Absyn.makeFullyQualified(path3));

    // TODO! FIXME! what do we do here??!!
    case (cache,env,path)
      equation
          crPath = ComponentReference.pathToCref(path);
         (cache,env,_,_,_,_,_,_,name) = Lookup.lookupVarInPackages(cache, env, crPath, {}, Util.makeStatefulBoolean(false));
          path3 = makeFullyQualified2(env,Absyn.IDENT(name));
      then
        (cache,Absyn.makeFullyQualified(path3));

    // If it fails, leave name unchanged.
    case (cache,_,path)
      equation
        /*true = Flags.isSet(Flags.FAILTRACE);
        print(Absyn.pathString(path));print(" failed to make FQ in env:");
        print("\n");
        print(FGraph.printGraphPathStr(env));
        print("\n");*/
      then
        (cache,path);
  end matchcontinue;
end makeFullyQualified;

public function instList
"This is a utility used to do instantiation of list
  of things, collecting the result in another list."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input InstFunc instFunc;
  input list<Type_a> inTypeALst;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  input ConnectionGraph.ConnectionGraph inGraph;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
  partial function InstFunc
    input FCore.Cache inCache;
    input FCore.Graph inEnv;
    input InnerOuter.InstHierarchy inIH;
    input Prefix.Prefix inPrefix;
    input Connect.Sets inSets;
    input ClassInf.State inState;
    input Type_a inTypeA;
    input Boolean inBoolean;
    input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
    input ConnectionGraph.ConnectionGraph inGraph;
    output FCore.Cache outCache;
    output FCore.Graph outEnv;
    output InnerOuter.InstHierarchy outIH;
    output DAE.DAElist outDAe;
    output Connect.Sets outSets;
    output ClassInf.State outState;
    output ConnectionGraph.ConnectionGraph outGraph;
    replaceable type Type_a subtypeof Any;
  end InstFunc;
  replaceable type Type_a subtypeof Any;
algorithm
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph):=
  match (inCache,inEnv,inIH,inPrefix,inSets,inState,instFunc,inTypeALst,inBoolean,unrollForLoops,inGraph)
    local
      FCore.Graph env,env_1,env_2;
      DAE.Mod mod;
      Prefix.Prefix pre;
      Connect.Sets csets,csets_1,csets_2;
      ClassInf.State ci_state,ci_state_1,ci_state_2;
      Boolean impl;
      DAE.DAElist dae1,dae2,dae;
      Type_a e;
      list<Type_a> es;
      FCore.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;

    case (cache,env,ih,_,csets,ci_state,_,{},_,_,graph)
      then (cache,env,ih,DAE.emptyDae,csets,ci_state,graph);

    case (cache,env,ih,pre,csets,ci_state,_,(e :: es),impl,_,graph)
      equation
        (cache,env_1,ih,dae1,csets_1,ci_state_1,graph) = instFunc(cache, env, ih, pre, csets, ci_state, e, impl, unrollForLoops, graph);
        (cache,env_2,ih,dae2,csets_2,ci_state_2,graph) = instList(cache, env_1, ih, pre, csets_1, ci_state_1, instFunc, es, impl, unrollForLoops, graph);
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache,env_2,ih,dae,csets_2,ci_state_2,graph);
  end match;
end instList;

protected function instConstraints
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Prefix.Prefix inPrefix;
  input ClassInf.State inState;
  input list<SCode.ConstraintSection> inConstraints;
  input Boolean inImpl;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output DAE.DAElist outDae;
  output ClassInf.State outState;
algorithm
  (outCache,outEnv,outDae,outState) := match(inCache,inEnv,inPrefix,inState,inConstraints,inImpl)
    local
      FCore.Graph env1,env2;
      DAE.DAElist constraints_1,constraints_2;
      ClassInf.State ci_state;
      list<SCode.ConstraintSection> rest;
      SCode.ConstraintSection constr;
      FCore.Cache cache;
      DAE.DAElist dae;

    case (_,_,_,_,{},_)
      then (inCache,inEnv,DAE.emptyDae,inState);

    case (_,_,_,_,(constr::rest),_)
      equation
        (cache,env1,constraints_1,ci_state) = InstSection.instConstraint(inCache,inEnv,inPrefix,inState,constr,inImpl);
        (cache,env2,constraints_2,ci_state) = instConstraints(cache,env1,inPrefix,ci_state,rest,inImpl);
        dae = DAEUtil.joinDaes(constraints_1, constraints_2);
      then
        (cache,env2,dae,ci_state);
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Inst.instConstraints failed\n");
      then
        fail();

  end match;
end instConstraints;

protected function instClassAttributes
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Prefix.Prefix inPrefix;
  input list<Absyn.NamedArg> inAttrs;
  input Boolean inBoolean;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output DAE.DAElist outDae;
algorithm

  (outCache,outEnv,outDae):=
  match (inCache,inEnv,inPrefix,inAttrs,inBoolean,inInfo)
    local
      FCore.Cache cache;
      FCore.Graph env;
      DAE.DAElist clsAttrs, dae;

    case (cache,env,_,{},_,_)
      then (cache,env,DAE.emptyDae);

    case (_,_,_,_,_,_)
      equation
        clsAttrs = DAE.DAE({DAE.CLASS_ATTRIBUTES(DAE.OPTIMIZATION_ATTRS(NONE(),NONE(),NONE(),NONE()))});
        (cache,env,dae) = instClassAttributes2(inCache,inEnv,inPrefix,inAttrs,inBoolean,inInfo,clsAttrs);
      then (cache,env,dae);
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Inst.instClassAttributes failed\n");
      then
        fail();
  end match;
end instClassAttributes;

protected function instClassAttributes2
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Prefix.Prefix inPrefix;
  input list<Absyn.NamedArg> inAttrs;
  input Boolean inBoolean;
  input SourceInfo inInfo;
  input DAE.DAElist inClsAttrs;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output DAE.DAElist outDae;
algorithm

  (outCache,outEnv,outDae):=
  match (inCache,inEnv,inPrefix,inAttrs,inBoolean,inInfo,inClsAttrs)
    local
      FCore.Graph env,env_2;
      Prefix.Prefix pre;
      Boolean impl;
      Absyn.NamedArg na;
      list<Absyn.NamedArg> rest;
      FCore.Cache cache;
      Absyn.Ident attrName;
      Absyn.Exp attrExp;
      DAE.Exp outExp;
      DAE.Properties outProps;
      DAE.DAElist clsAttrs;

    case (cache,env,_,{},_,_,clsAttrs)
      then (cache,env,clsAttrs);

    case (cache,env,pre,(na :: rest),impl,_,clsAttrs)
      equation
        Absyn.NAMEDARG(attrName, attrExp) = na;
        (cache,outExp,_,_) = Static.elabExp(cache, env, attrExp, impl, NONE(), false /*vectorize*/, pre, inInfo);
        (clsAttrs) = insertClassAttribute(clsAttrs,attrName,outExp);
        (cache,env_2,clsAttrs) = instClassAttributes2(cache, env, pre, rest, impl, inInfo,clsAttrs);
      then
        (cache,env_2,clsAttrs);

    else
      equation
        Error.addMessage(Error.OPTIMICA_ERROR, {"Class Attributes allowed only for Optimization classes."});
      then fail();
  end match;
end instClassAttributes2;

protected function insertClassAttribute
  input DAE.DAElist inAttrs;
  input Absyn.Ident attrName;
  input DAE.Exp inAttrExp;
  output DAE.DAElist outAttrs;
algorithm
  outAttrs := match(inAttrs, attrName, inAttrExp)
    local
      Option<DAE.Exp> objectiveE,startTimeE,finalTimeE,objectiveIntegrandE;
      DAE.DAElist attrs;

    case (attrs, "objective", _)
      equation
        DAE.DAE({DAE.CLASS_ATTRIBUTES(DAE.OPTIMIZATION_ATTRS(_,objectiveIntegrandE,startTimeE,finalTimeE))}) = attrs;
        attrs = DAE.DAE({DAE.CLASS_ATTRIBUTES(DAE.OPTIMIZATION_ATTRS(SOME(inAttrExp),objectiveIntegrandE,startTimeE,finalTimeE))});
      then attrs;

    case (attrs, "objectiveIntegrand", _)
      equation
        DAE.DAE({DAE.CLASS_ATTRIBUTES(DAE.OPTIMIZATION_ATTRS(objectiveE,_,startTimeE,finalTimeE))}) = attrs;
        attrs = DAE.DAE({DAE.CLASS_ATTRIBUTES(DAE.OPTIMIZATION_ATTRS(objectiveE,SOME(inAttrExp),startTimeE,finalTimeE))});
      then attrs;

    case (attrs, "startTime", _)
      equation
        DAE.DAE({DAE.CLASS_ATTRIBUTES(DAE.OPTIMIZATION_ATTRS(objectiveE,objectiveIntegrandE,_,finalTimeE))}) = attrs;
        attrs = DAE.DAE({DAE.CLASS_ATTRIBUTES(DAE.OPTIMIZATION_ATTRS(objectiveE,objectiveIntegrandE,SOME(inAttrExp),finalTimeE))});
      then attrs;

    case (attrs, "finalTime", _)
      equation
        DAE.DAE({DAE.CLASS_ATTRIBUTES(DAE.OPTIMIZATION_ATTRS(objectiveE,objectiveIntegrandE,startTimeE,_))}) = attrs;
        attrs = DAE.DAE({DAE.CLASS_ATTRIBUTES(DAE.OPTIMIZATION_ATTRS(objectiveE,objectiveIntegrandE,startTimeE,SOME(inAttrExp)))});
      then attrs;
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Inst.insertClassAttribute failed\n");
      then
        fail();

  end match;
end insertClassAttribute;

public function instantiateBoschClass "
Author BZ 2008-06,
Instantiate a class, but _allways_ as inner class. This due to that we do not want flow equations equal to zero.
Called from Interactive.mo, boschsection.
"
  input FCore.Cache inCache;
  input InnerOuter.InstHierarchy inIH;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output DAE.DAElist outDAElist;
algorithm
  (outCache,outEnv,outIH,outDAElist) :=
  matchcontinue (inCache,inIH,inProgram,inPath)
    local
      Absyn.Path cr,path;
      FCore.Graph env,env_1,env_2;
      DAE.DAElist dae1,dae;
      list<SCode.Element> cdecls;
      String name2,n,pathstr,name,cname_str;
      SCode.Element cdef;
      FCore.Cache cache;
      InstanceHierarchy ih;

    case (_,_,{},_)
      equation
        Error.addMessage(Error.NO_CLASSES_LOADED, {});
      then
        fail();

    case (cache,ih,(cdecls as (_ :: _)),(path as Absyn.IDENT())) /* top level class */
      equation
        (cache,env) = Builtin.initialGraph(cache);
        env_1 = FGraphBuildEnv.mkProgramGraph(cdecls, FCore.USERDEFINED(), env);
        (cache,env_2,ih,dae) = instBoschClassInProgram(cache,env_1,ih, cdecls, path);
      then
        (cache,env_2,ih,dae);

    case (cache,ih,(cdecls as (_ :: _)),(path as Absyn.QUALIFIED())) /* class in package */
      equation
        (cache,env) = Builtin.initialGraph(cache);
        env_1 = FGraphBuildEnv.mkProgramGraph(cdecls, FCore.USERDEFINED(), env);
        (cache,(cdef as SCode.CLASS()),env_2) = Lookup.lookupClass(cache,env_1, path, true);

        (cache,env_2,ih,_,dae,_,_,_,_,_) =
          instClass(cache,env_2,ih,UnitAbsyn.noStore, DAE.NOMOD(), Prefix.NOPRE(),
            cdef, {}, false, InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, Connect.emptySet) "impl" ;
        _ = Absyn.pathString(path);
      then
        (cache,env_2,ih,dae);

    case (_,_,_,path) /* error instantiating */
      equation
        cname_str = Absyn.pathString(path);
        Error.addMessage(Error.ERROR_FLATTENING, {cname_str});
      then
        fail();
  end matchcontinue;
end instantiateBoschClass;

protected function instBoschClassInProgram
"Helper function for instantiateBoschClass"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output DAE.DAElist outDae;
algorithm
  (outCache,outEnv,outIH,outDae):=
  matchcontinue (inCache,inEnv,inIH,inProgram,inPath)
    local
      DAE.DAElist dae;
      FCore.Graph env_1,env;
      SCode.Element c;
      String name1,name2;
      list<SCode.Element> cs;
      Absyn.Path path;
      FCore.Cache cache;
      InstanceHierarchy ih;

    case (cache,env,ih,((c as SCode.CLASS(name = name1)) :: _),Absyn.IDENT(name = name2))
      equation
        true = stringEq(name1, name2);
        (cache,env_1,ih,_,dae,_,_,_,_,_) =
          instClass(cache,env,ih, UnitAbsyn.noStore, DAE.NOMOD(), Prefix.NOPRE(), c,
            {}, false, InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, Connect.emptySet) "impl" ;
      then
        (cache,env_1,ih,dae);

    case (cache,env,ih,((SCode.CLASS(name = name1)) :: cs),(path as Absyn.IDENT(name = name2)))
      equation
        false = stringEq(name1, name2);
        (cache,env,ih,dae) = instBoschClassInProgram(cache,env,ih, cs, path);
      then
        (cache,env,ih,dae);

    case (cache,env,ih,{},_) then (cache,env,ih,DAE.emptyDae);

  end matchcontinue;
end instBoschClassInProgram;

protected function modifyInstantiateClass
" Here we check a modifier and a path,
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
      SCode.Final f;
      SCode.Each e;
      list<tuple<SCode.Element, DAE.Mod>> redecls,p1,p2;
      Integer i1;

    case(DAE.REDECL(f,e,redecls), _)
      equation
        (p1,p2) = modifyInstantiateClass2(redecls,path);
        i1 = listLength(p1);
        omod1 = if i1==0 then DAE.NOMOD() else DAE.REDECL(f,e,p1);
        i1 = listLength(p2);
        omod2 = if i1==0 then DAE.NOMOD() else DAE.REDECL(f,e,p2);
      then
        (omod1,omod2);

    else (DAE.NOMOD(), inMod);

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
      list<tuple<SCode.Element, DAE.Mod>> rest,rec2,rec1;
      tuple<SCode.Element, DAE.Mod> head;
      DAE.Mod m;
      String id1,id2;
    case({},_) then ({},{});
    case( (head as  (SCode.CLASS(name = id1),_))::rest, _)
      equation
        id2 = Absyn.pathString(path);
        true = stringEq(id1,id2);
        (rec1,rec2) = modifyInstantiateClass2(rest,path);
      then
        (head::rec1,rec2);
    case(head::rest,_)
      equation
        (rec1,rec2) = modifyInstantiateClass2(rest,path);
      then
        (rec1,head::rec2);
  end matchcontinue;
end modifyInstantiateClass2;

protected function removeSelfReferenceAndUpdate
" BZ 2007-07-03
 This function checks if there is a reference to itself.
 If it is, it removes the reference.
 But also instantiate the declared type, if any.
 If it fails (declarations of array dimensions using
 the size of itself) it will just remove the element."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input list<Absyn.ComponentRef> inRefs;
  input Absyn.ComponentRef inRef;
  input Absyn.Path inPath;
  input ClassInf.State inState;
  input SCode.Attributes iattr;
  input SCode.Prefixes inPrefixes;
  input Boolean impl;
  input list<list<DAE.Dimension>> inInstDims;
  input Prefix.Prefix pre;
  input DAE.Mod mods;
  input SCode.Mod scodeMod;
  input SourceInfo info;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output list<Absyn.ComponentRef> o1;
algorithm
  (outCache,outEnv,outIH,outStore,o1) :=
  matchcontinue(inCache,inEnv,inIH,inStore,inRefs,inRef,inPath,inState,iattr,inPrefixes,impl,inInstDims,pre,mods,scodeMod,info)
    local
      Absyn.Path sty;
      Absyn.ComponentRef c1;
      list<Absyn.ComponentRef> cl1,cl2;
      FCore.Cache cache;
      FCore.Graph env,compenv,cenv;
      Integer i1,i2;
      list<Absyn.Subscript> ad;
      SCode.Parallelism prl1;
      SCode.Variability var1;
      Absyn.Direction dir;
      Ident n;
      SCode.Element c;
      DAE.Type ty;
      ClassInf.State state;
      SCode.Visibility vis;
      SCode.ConnectorType ct;
      SCode.Attributes attr;
      DAE.Dimensions dims;
      InstDims inst_dims;
      DAE.Var new_var;
      InstanceHierarchy ih;
      Absyn.InnerOuter io;
      UnitAbsyn.InstStore store;
      DAE.Mod m;
      SCode.Mod smod;

    case(cache,env,ih,store,cl1,c1,_,_,_,_,_,_,_,_,_,_)
      equation
        cl2 = InstUtil.removeCrefFromCrefs(cl1, c1);
        i1 = listLength(cl2);
        i2 = listLength(cl1);
        true = (i1 == i2);
      then
        (cache,env,ih,store,cl2);

    // we have reference to ourself, try to instantiate type with all but the self reference removed!
    case(cache,env,ih,store,cl1,c1 as Absyn.CREF_IDENT(name = n),sty,state,
         (attr as SCode.ATTR(arrayDims = ad, connectorType = ct,
                             parallelism= prl1, variability = var1, direction = dir)),
         _,_,inst_dims,_,_,_,_)
      equation
        ErrorExt.setCheckpoint("Inst.removeSelfReferenceAndUpdate");
        cl2 = InstUtil.removeCrefFromCrefs(cl1, c1);
        (cache,c,cenv) = Lookup.lookupClass(cache,env, sty, true);
        (cache,dims) = InstUtil.elabArraydim(cache,cenv, c1, sty, ad, NONE(), impl, NONE(), true, false, pre, info, inst_dims);

        // we really need to keep at least the redeclare modifications here!!
        smod = SCodeUtil.removeSelfReferenceFromMod(scodeMod, c1);
        (cache,m) = Mod.elabMod(cache, env, ih, pre, smod, impl, Mod.COMPONENT(n), info); // m = Mod.elabUntypedMod(smod, env, pre);

        (cenv, c, ih) = FGraph.createVersionScope(env, n, pre, m, cenv, c, ih);
        (cache,compenv,ih,store,_,_,ty,_) =
          InstVar.instVar(cache, cenv, ih, store, state, m, pre, n, c, attr,
            inPrefixes, dims, {}, inst_dims, true, SCode.noComment, info, ConnectionGraph.EMPTY, Connect.emptySet, env);

        // print("component: " + n + " ty: " + Types.printTypeStr(ty) + "\n");

        io = SCode.prefixesInnerOuter(inPrefixes);
        vis = SCode.prefixesVisibility(inPrefixes);

        new_var = DAE.TYPES_VAR(n,DAE.ATTR(ct,prl1,var1,dir,io,vis),ty,DAE.UNBOUND(),NONE());
        env = FGraph.updateComp(env, new_var, FCore.VAR_TYPED(), compenv);
        ErrorExt.rollBack("Inst.removeSelfReferenceAndUpdate");
      then
        (cache,env,ih,store,cl2);

    // not working, try again :)
    case(_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        ErrorExt.rollBack("Inst.removeSelfReferenceAndUpdate");
      then
        fail();

    // we have reference to ourself, try to instantiate type with redeclares and constants applied
    case(cache,env,ih,store,cl1,c1 as Absyn.CREF_IDENT(name = n),sty,state,
         (attr as SCode.ATTR(arrayDims = ad, connectorType = ct,
                             parallelism= prl1, variability = var1, direction = dir)),
         _,_,inst_dims,_,_,_,_)
      equation
        ErrorExt.setCheckpoint("Inst.removeSelfReferenceAndUpdate");
        cl2 = InstUtil.removeCrefFromCrefs(cl1, c1);
        (cache,c,cenv) = Lookup.lookupClass(cache,env, sty, true);
        (cache,dims) = InstUtil.elabArraydim(cache, cenv, c1, sty, ad, NONE(), impl, NONE(), true, false, pre, info, inst_dims);

        // we really need to keep at least the redeclare modifications here!!
        smod = SCodeUtil.removeNonConstantBindingsKeepRedeclares(scodeMod, false);
        (cache,m) = Mod.elabMod(cache, env, ih, pre, smod, impl, Mod.COMPONENT(n), info); // m = Mod.elabUntypedMod(smod, env, pre);

        (cenv, c, ih) = FGraph.createVersionScope(env, n, pre, m, cenv, c, ih);
        (cache,compenv,ih,store,_,_,ty,_) =
          InstVar.instVar(cache, cenv, ih, store, state, m, pre, n, c, attr,
            inPrefixes, dims, {}, inst_dims, true, SCode.noComment, info, ConnectionGraph.EMPTY, Connect.emptySet, env);

        // print("component: " + n + " ty: " + Types.printTypeStr(ty) + "\n");

        io = SCode.prefixesInnerOuter(inPrefixes);
        vis = SCode.prefixesVisibility(inPrefixes);

        new_var = DAE.TYPES_VAR(n,DAE.ATTR(ct,prl1,var1,dir,io,vis),ty,DAE.UNBOUND(),NONE());
        env = FGraph.updateComp(env, new_var, FCore.VAR_TYPED(), compenv);
        ErrorExt.rollBack("Inst.removeSelfReferenceAndUpdate");
      then
        (cache,env,ih,store,cl2);

    // not working, try again :)
    case(_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        ErrorExt.rollBack("Inst.removeSelfReferenceAndUpdate");
      then
        fail();

    // we have reference to ourself, try to instantiate type with redeclares only applied
    case(cache,env,ih,store,cl1,c1 as Absyn.CREF_IDENT(name = n),sty,state,
         (attr as SCode.ATTR(arrayDims = ad, connectorType = ct,
                             parallelism= prl1, variability = var1, direction = dir)),
         _,_,inst_dims,_,_,_,_)
      equation
        ErrorExt.setCheckpoint("Inst.removeSelfReferenceAndUpdate");
        cl2 = InstUtil.removeCrefFromCrefs(cl1, c1);
        (cache,c,cenv) = Lookup.lookupClass(cache,env, sty, true);
        (cache,dims) = InstUtil.elabArraydim(cache,cenv, c1, sty, ad, NONE(), impl, NONE(), true, false, pre, info, inst_dims);

        // we really need to keep at least the redeclare modifications here!!
        smod = SCodeUtil.removeNonConstantBindingsKeepRedeclares(scodeMod, true);
        (cache,m) = Mod.elabMod(cache, env, ih, pre, smod, impl, Mod.COMPONENT(n), info); // m = Mod.elabUntypedMod(smod, env, pre);

        (cenv, c, ih) = FGraph.createVersionScope(env, n, pre, m, cenv, c, ih);
        (cache,compenv,ih,store,_,_,ty,_) =
          InstVar.instVar(cache, cenv, ih, store, state, m, pre, n, c, attr,
            inPrefixes, dims, {}, inst_dims, true, SCode.noComment, info, ConnectionGraph.EMPTY, Connect.emptySet, env);

        // print("component: " + n + " ty: " + Types.printTypeStr(ty) + "\n");

        io = SCode.prefixesInnerOuter(inPrefixes);
        vis = SCode.prefixesVisibility(inPrefixes);

        new_var = DAE.TYPES_VAR(n,DAE.ATTR(ct,prl1,var1,dir,io,vis),ty,DAE.UNBOUND(),NONE());
        env = FGraph.updateComp(env, new_var, FCore.VAR_TYPED(), compenv);
        ErrorExt.rollBack("Inst.removeSelfReferenceAndUpdate");
      then
        (cache,env,ih,store,cl2);

    // not working, try again :)
    case(_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        ErrorExt.rollBack("Inst.removeSelfReferenceAndUpdate");
      then
        fail();

    // we have reference to ourself, GEE, nothing worked previously try with NOMOD!
    case(cache,env,ih,store,cl1,c1 as Absyn.CREF_IDENT(name = n),sty,state,
         (attr as SCode.ATTR(arrayDims = ad, connectorType = ct,
                             parallelism= prl1, variability = var1, direction = dir)),
         _,_,inst_dims,_,_,_,_)
      equation
        ErrorExt.setCheckpoint("Inst.removeSelfReferenceAndUpdate");
        cl2 = InstUtil.removeCrefFromCrefs(cl1, c1);
        (cache,c,cenv) = Lookup.lookupClass(cache,env, sty, true);
        (cache,dims) = InstUtil.elabArraydim(cache,cenv, c1, sty, ad, NONE(), impl, NONE(), true, false, pre, info, inst_dims);

        // we really need to keep at least the redeclare modifications here!!
        // smod = SCodeUtil.removeNonConstantBindingsKeepRedeclares(scodeMod, true);
        // (cache,m) = Mod.elabMod(cache, env, ih, pre, smod, impl, info); // m = Mod.elabUntypedMod(smod, env, pre);
        m = DAE.NOMOD();

        (cenv, c, ih) = FGraph.createVersionScope(env, n, pre, m, cenv, c, ih);
        (cache,compenv,ih,store,_,_,ty,_) =
          InstVar.instVar(cache, cenv, ih, store, state, m, pre, n, c, attr,
            inPrefixes, dims, {}, inst_dims, true, SCode.noComment, info, ConnectionGraph.EMPTY, Connect.emptySet, env);

        // print("component: " + n + " ty: " + Types.printTypeStr(ty) + "\n");

        io = SCode.prefixesInnerOuter(inPrefixes);
        vis = SCode.prefixesVisibility(inPrefixes);

        new_var = DAE.TYPES_VAR(n,DAE.ATTR(ct,prl1,var1,dir,io,vis),ty,DAE.UNBOUND(),NONE());
        env = FGraph.updateComp(env, new_var, FCore.VAR_TYPED(), compenv);
        ErrorExt.rollBack("Inst.removeSelfReferenceAndUpdate");
      then
        (cache,env,ih,store,cl2);

    // not working .... really not working, don't bother!
    case(_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        ErrorExt.rollBack("Inst.removeSelfReferenceAndUpdate");
      then
        fail();

    /*
    // adrpo, try to remove the modifier containing the self expression and use that to instantiate the type!
    case(cache,env,ih,store,cl1,c1 as Absyn.CREF_IDENT(name = n), sty, state,
         (attr as SCode.ATTR(arrayDims = ad, connectorType = ct,
                             parallelism= prl1, variability = var1, direction = dir)),
         _,_,_,_,_,_,_)
      equation
        ErrorExt.setCheckpoint("Inst.removeSelfReferenceAndUpdate");
        cl2 = InstUtil.removeCrefFromCrefs(cl1, c1);
        (cache,c,cenv) = Lookup.lookupClass(cache,env, sty, true);
        (cache,dims) = InstUtil.elabArraydim(cache,cenv, c1, sty, ad, NONE(), impl, NONE(), true, false, pre, info, inst_dims);

        sM = NFSCodeMod.removeCrefPrefixFromModExp(scodeMod, inRef);

        //(cache, dM) = elabMod(cache, env, ih, pre, sM, impl, info);
        dM = Mod.elabUntypedMod(sM, env, pre);

        (cenv, c, ih) = FGraph.createVersionScope(env, n, pre, dM, cenv, c, ih);
        (cache,compenv,ih,store,_,_,ty,_) =
          InstVar.instVar(cache, cenv, ih, store, state, dM, pre, n, c, attr,
            inPrefixes, dims, {}, inst_dims, true, NONE(), info, ConnectionGraph.EMPTY, Connect.emptySet, env);

        // print("component: " + n + " ty: " + Types.printTypeStr(ty) + "\n");

        io = SCode.prefixesInnerOuter(inPrefixes);
        vis = SCode.prefixesVisibility(inPrefixes);
        new_var = DAE.TYPES_VAR(n,DAE.ATTR(ct,prl1,var1,dir,io,vis),ty,DAE.UNBOUND(),NONE());
        env = FGraph.updateComp(env, new_var, FCore.VAR_TYPED(), compenv);
        ErrorExt.delCheckpoint("Inst.removeSelfReferenceAndUpdate");
      then
        (cache,env,ih,store,cl2);

    case(_, _, _, _, _, Absyn.CREF_IDENT(name = n), _, _, _, _, _, _, _, _, _, _)
      equation
        ErrorExt.rollBack("Inst.removeSelfReferenceAndUpdate");
      then
        fail();
    */

    case(cache,env,ih,store,cl1,c1,_,_,_,_,_,_,_,_,_,_)
      equation
        cl2 = InstUtil.removeCrefFromCrefs(cl1, c1);
      then
        (cache,env,ih,store,cl2);

  end matchcontinue;
end removeSelfReferenceAndUpdate;

protected function updateComponentsInEnv2
"author: PA
  Help function to updateComponentsInEnv."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix pre;
  input DAE.Mod mod;
  input list<Absyn.ComponentRef> crefs;
  input ClassInf.State ci_state;
  input Boolean impl;
  input Option<HashTable5.HashTable> inUpdatedComps = NONE();
  input Option<Absyn.ComponentRef> currentCref = NONE();
  output FCore.Cache outCache = inCache;
  output FCore.Graph outEnv = inEnv;
  output InnerOuter.InstHierarchy outIH = inIH;
  output Option<HashTable5.HashTable> outUpdatedComps = inUpdatedComps;
protected
  String name;
  DAE.Binding binding;
algorithm
  for cr in crefs loop
    try
      Absyn.CREF_IDENT(name = name, subscripts = {}) := cr;
      (_, DAE.TYPES_VAR(binding = binding), _, _, _, _) :=
        Lookup.lookupIdentLocal(outCache, outEnv, name);
      true := DAEUtil.isBound(binding);
    else
      (outCache, outEnv, outIH, outUpdatedComps) :=
        updateComponentInEnv(outCache, outEnv, outIH, pre, mod, cr, ci_state,
          impl, outUpdatedComps, currentCref);
    end try;
  end for;
end updateComponentsInEnv2;

protected function makeFullyQualified2
"help function to makeFullyQualified"
  input FCore.Graph env;
  input Absyn.Path restPath;
output Absyn.Path path;
algorithm
  path := match(env,restPath)
    local
      Absyn.Path scope;
      Option<Absyn.Path> oscope;
    case(_,_)
      equation
        oscope = FGraph.getScopePath(env);
        if valueEq(oscope, NONE())
        then
          path = restPath;
        else
          SOME(scope) = oscope;
          path = Absyn.joinPaths(scope, restPath);
        end if;
      then
        path;
  end match;
end makeFullyQualified2;


// *********************************************************************
//    hash table implementation for cashing instantiation results
// *********************************************************************

protected function addToInstCache
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
        false = Flags.isSet(Flags.CACHE);
       then
         ();

    // we have them both
    case (_, SOME(_), SOME(_))
      equation
        instHash = getGlobalRoot(Global.instHashIndex);
        instHash = BaseHashTable.add((fullEnvPathPlusClass,{fullInstOpt,partialInstOpt}),instHash);
        setGlobalRoot(Global.instHashIndex, instHash);
      then
        ();

    // we have a partial inst result and the full in the cache
    case (_, NONE(), SOME(_))
      equation
        instHash = getGlobalRoot(Global.instHashIndex);
        // see if we have a full inst here
        {SOME(fullInst),_} = BaseHashTable.get(fullEnvPathPlusClass, instHash);
        instHash = BaseHashTable.add((fullEnvPathPlusClass,{SOME(fullInst),partialInstOpt}),instHash);
        setGlobalRoot(Global.instHashIndex, instHash);
      then
        ();

    // we have a partial inst result and the full is NOT in the cache
    case (_, NONE(), SOME(_))
      equation
        instHash = getGlobalRoot(Global.instHashIndex);
        // see if we have a full inst here
        // failed above {SOME(fullInst),_} = get(fullEnvPathPlusClass, instHash);
        instHash = BaseHashTable.add((fullEnvPathPlusClass,{NONE(),partialInstOpt}),instHash);
        setGlobalRoot(Global.instHashIndex, instHash);
      then
        ();

    // we have a full inst result and the partial in the cache
    case (_, SOME(_), NONE())
      equation
        instHash = getGlobalRoot(Global.instHashIndex);
        // see if we have a partial inst here
        {_,SOME(partialInst)} = BaseHashTable.get(fullEnvPathPlusClass, instHash);
        instHash = BaseHashTable.add((fullEnvPathPlusClass,{fullInstOpt,SOME(partialInst)}),instHash);
        setGlobalRoot(Global.instHashIndex, instHash);
      then
        ();

    // we have a full inst result and the partial is NOT in the cache
    case (_, SOME(_), NONE())
      equation
        instHash = getGlobalRoot(Global.instHashIndex);
        // see if we have a partial inst here
        // failed above {_,SOME(partialInst)} = get(fullEnvPathPlusClass, instHash);
        instHash = BaseHashTable.add((fullEnvPathPlusClass,{fullInstOpt,NONE()}),instHash);
        setGlobalRoot(Global.instHashIndex, instHash);
      then
        ();

    // we failed above??!!
    else ();
  end matchcontinue;
end addToInstCache;

protected type CachedInstItemInputs = tuple<FCore.Cache, FCore.Graph, InstanceHierarchy,
    UnitAbsyn.InstStore, DAE.Mod, Prefix.Prefix, Connect.Sets, ClassInf.State,
    SCode.Element, SCode.Visibility, InstDims, Boolean,
    ConnectionGraph.ConnectionGraph, Option<DAE.ComponentRef>, InstTypes.CallingScope>;

protected type CachedInstItemOutputs = tuple<DAE.FunctionTree, FCore.Graph, DAE.DAElist, Connect.Sets,
    ClassInf.State, list<DAE.Var>, Option<DAE.Type>, Option<SCode.Attributes>,
    DAE.EqualityConstraint, ConnectionGraph.ConnectionGraph>;

protected type CachedPartialInstItemInputs = tuple<FCore.Cache, FCore.Graph,
    InstanceHierarchy, DAE.Mod, Prefix.Prefix, ClassInf.State,
    SCode.Element, SCode.Visibility, InstDims>;

protected type CachedPartialInstItemOutputs = tuple<DAE.FunctionTree, FCore.Graph, ClassInf.State, list<DAE.Var>>;

protected
uniontype CachedInstItem
  // *important* inputs/outputs for instClassIn
  record FUNC_instClassIn
    CachedInstItemInputs inputs;
    CachedInstItemOutputs outputs;
  end FUNC_instClassIn;

  // *important* inputs/outputs for partialInstClassIn
  record FUNC_partialInstClassIn
    CachedPartialInstItemInputs inputs;
    CachedPartialInstItemOutputs outputs;
  end FUNC_partialInstClassIn;

end CachedInstItem;

protected type CachedInstItems = list<Option<CachedInstItem>>;

/* Begin inline HashTable */
protected type Key = Absyn.Path;
protected type Value = CachedInstItems;

protected type HashTableKeyFunctionsType = tuple<FuncHashKey,FuncKeyEqual,FuncKeyStr,FuncValueStr>;
protected type InstHashTable = tuple<
  array<list<tuple<Key,Integer>>>,
  tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>,
  Integer,
  Integer,
  HashTableKeyFunctionsType
>;

protected partial function FuncHashKey
  input Key cr;
  input Integer mod;
  output Integer res;
end FuncHashKey;

protected partial function FuncKeyEqual
  input Key cr1;
  input Key cr2;
  output Boolean res;
end FuncKeyEqual;

protected partial function FuncKeyStr
  input Key cr;
  output String res;
end FuncKeyStr;

protected partial function FuncValueStr
  input Value exp;
  output String res;
end FuncValueStr;

protected function opaqVal
"Don't actually print what is stored in the value... It's too damn long."
  input Value v;
  output String str;
algorithm
  str := "OPAQUE_VALUE";
end opaqVal;

public function initInstHashTable
algorithm
  setGlobalRoot(Global.instHashIndex, emptyInstHashTable());
end initInstHashTable;

protected function emptyInstHashTable
"
  Returns an empty HashTable.
  Using the default bucketsize..
"
  output InstHashTable hashTable;
algorithm
  hashTable := emptyInstHashTableSized(BaseHashTable.defaultBucketSize);
end emptyInstHashTable;

protected function emptyInstHashTableSized
"Returns an empty HashTable.
  Using the bucketsize size"
  input Integer size;
  output InstHashTable hashTable;
algorithm
  hashTable := BaseHashTable.emptyHashTableWork(size,(Absyn.pathHashMod,Absyn.pathEqual,Absyn.pathString,opaqVal));
end emptyInstHashTableSized;

/* end HashTable */

public function getCachedInstance
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input String inName;
  input FCore.Ref inRef;
  output FCore.Cache outCache;
  output FCore.Graph outGraph;
algorithm
  (outCache, outGraph) := matchcontinue(inCache, inEnv, inName, inRef)
    local
      FCore.Cache cache;
      FCore.Graph env;
      DAE.FunctionTree ft;
      InstHashTable instHash;
      Absyn.Path fullEnvPathPlusClass;
      tuple<FCore.Cache, FCore.Graph, InstanceHierarchy,
            UnitAbsyn.InstStore, DAE.Mod, Prefix.Prefix, Connect.Sets, ClassInf.State,
            SCode.Element, SCode.Visibility, InstDims, Boolean,
            ConnectionGraph.ConnectionGraph, Option<DAE.ComponentRef>, InstTypes.CallingScope>
            inputs;
      tuple<DAE.FunctionTree, FCore.Graph, DAE.DAElist, Connect.Sets,
            ClassInf.State, list<DAE.Var>, Option<DAE.Type>, Option<SCode.Attributes>,
            DAE.EqualityConstraint, ConnectionGraph.ConnectionGraph> outputs;
      DAE.Mod m1, m2;
      Prefix.Prefix pre1, pre2;
      SCode.Element e1, e2;
      Boolean b1, b2, b3;
      SCode.Encapsulated encflag;
      SCode.Restriction restr;

    case (cache, _, _, _)
      equation
        true = Flags.isSet(Flags.CACHE);
        instHash = getGlobalRoot(Global.instHashIndex);
        FCore.CL(e2 as SCode.CLASS(restriction = restr, encapsulatedPrefix=encflag), pre2, m2, _, _) = FNode.refData(inRef);
        env = FGraph.openScope(inEnv, encflag, SOME(inName), FGraph.restrictionToScopeType(restr));
        fullEnvPathPlusClass = generateCachePath(env, e2, pre2, InstTypes.INNER_CALL());

        // print("Try cached instance: " + Absyn.pathString(fullEnvPathPlusClass) + "\n");
        {SOME(FUNC_instClassIn(inputs, (_, env, _, _, _, _, _, _, _, _))),_} = BaseHashTable.get(fullEnvPathPlusClass, instHash);

        // do some sanity checks
        (_, _, _, _, m1, pre1, _, _, e1, _, _, _,_ , _, _) = inputs;

        _ = Mod.modEqual(m1, m2);
        _ = SCode.elementEqual(e1, e2);
        _ = Absyn.pathEqual(PrefixUtil.prefixToPath(pre1), PrefixUtil.prefixToPath(pre2));

        // cache = FCore.setCachedFunctionTree(cache, DAEUtil.joinAvlTrees(ft, FCore.getFunctionTree(cache)));
        /*
        print("Got cached instance: " + Absyn.pathString(fullEnvPathPlusClass) +
              " mod: " + boolString(b1) +
              " els: " + boolString(b2) +
              " pre: " + boolString(b3) +
              "\n");*/
      then
        (cache, env);

    else
      equation
        true = Flags.isSet(Flags.CACHE);
        _ = getGlobalRoot(Global.instHashIndex);
        FCore.CL(e2 as SCode.CLASS(restriction = restr, encapsulatedPrefix=encflag), pre2, _, _, _) = FNode.refData(inRef);
        env = FGraph.openScope(inEnv, encflag, SOME(inName), FGraph.restrictionToScopeType(restr));
        _ = generateCachePath(env, e2, pre2, InstTypes.INNER_CALL());

        // print("Could not get the cached instance: " + Absyn.pathString(fullEnvPathPlusClass) + "\n");
        env = FGraph.pushScopeRef(inEnv, inRef);
      then
        (inCache, env);

  end matchcontinue;
end getCachedInstance;

protected function generateCachePath
  input FCore.Graph inEnv;
  input SCode.Element inClass;
  input Prefix.Prefix inPrefix;
  input InstTypes.CallingScope inCallScope;
  output Absyn.Path outCachePath;
algorithm
  outCachePath := matchcontinue(inEnv, inClass, inPrefix, inCallScope)
    local
      String name, n;
      Absyn.Path p;
      SCode.Restriction r;

    case (_, SCode.CLASS(restriction = r), _, _)
      equation
        name = InstTypes.callingScopeStr(inCallScope) + "$" +
               SCodeDump.restrString(r) + "$" +
               generatePrefixStr(inPrefix) + "$";
        p = Absyn.joinPaths(Absyn.IDENT(name), FGraph.getGraphName(inEnv));
      then
        p;

    case (_, SCode.CLASS(name = n), _, _)
      equation
        print("Inst.generateCachePath: failed to generate cache path for: " + n + " in scope: " + FGraph.getGraphNameStr(inEnv) + "\n");
        p = FGraph.joinScopePath(inEnv, Absyn.IDENT(n));
      then
        p;

  end matchcontinue;
end generateCachePath;

public function generatePrefixStr
  input Prefix.Prefix inPrefix;
  output String str;
algorithm
  str := matchcontinue(inPrefix)

    case (_)
      equation
        str = Absyn.pathString2NoLeadingDot(Absyn.stringListPath(listReverse(Absyn.pathToStringList(PrefixUtil.prefixToPath(inPrefix)))), "$");
      then
        str;

    else "";

  end matchcontinue;
end generatePrefixStr;

protected function showCacheInfo
  input String inMsg;
  input Absyn.Path inPath;
algorithm
  _ := matchcontinue(inMsg, inPath)

    case (_, _)
      equation
        true = Flags.isSet(Flags.SHOW_INST_CACHE_INFO);
        print(inMsg + Absyn.pathString(inPath) + "\n");
      then
        ();

    else ();
  end matchcontinue;
end showCacheInfo;

annotation(__OpenModelica_Interface="frontend");
end Inst;
