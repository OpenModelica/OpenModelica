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
public import AbsynUtil;
public import ClassInf;
public import DAE.Connect;
public import ConnectionGraph;
public import DAE;
public import FCore;
public import InnerOuter;
public import InstTypes;
public import Mod;
public import SCode;
public import UnitAbsyn;

// **
// These type aliases are introduced to make the code a little more readable.
// **

protected type Ident = DAE.Ident "an identifier";

protected type InstanceHierarchy = InnerOuter.InstHierarchy "an instance hierarchy";

protected type InstDims = InstTypes.InstDims;

protected partial function BasicTypeAttrTyper
  input String inAttrName;
  input DAE.Type inClassType;
  input SourceInfo inInfo;
  output DAE.Type outType;
end BasicTypeAttrTyper;

// protected imports
protected

import BaseHashTable;
import Builtin;
import Ceval;
import ConnectUtil;
import ComponentReference;
import Config;
import DAEUtil;
import Debug;
import Dump;
import ElementSource;
import Error;
import ErrorExt;
import ExecStat;
import Expression;
import ExpressionDump;
import Flags;
import FGraph;
import FGraphBuildEnv;
import FNode;
import GC;
import Global;
import HashTable;
import HashTable5;
import InstHashTable;
import InstMeta;
import InstSection;
import InstBinding;
import InstVar;
import InstFunction;
import InstUtil;
import InstExtends;
import List;
import Lookup;
import Mutable;
import PrefixUtil;
import SCodeUtil;
import SCodeInstUtil;
import StringUtil;
import Static;
import Types;
import UnitParserExt;
import Util;
import Values;
import ValuesUtil;
import System;
import SCodeDump;
import UnitAbsynBuilder;
import InstStateMachineUtil;
import UnitCheck = FUnitCheck;

import DAEDump; // BTH

protected function instantiateClass_dispatch
" instantiate a class.
 if this function fails with stack overflow, it will be caught in the caller"
  input FCore.Cache inCache;
  input InnerOuter.InstHierarchy inIH;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  input Boolean doSCodeDep "Do SCode dependency (if the debug flag is also enabled)";
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
        if doSCodeDep then
          cdecls = InstUtil.scodeFlatten(cdecls, inPath);
          ExecStat.execStat("FrontEnd - scodeFlatten");
        end if;
        (cache,env) = Builtin.initialGraph(cache);
        env = FGraphBuildEnv.mkProgramGraph(cdecls, FCore.USERDEFINED(), env);

        // set the source of this element
        source = ElementSource.addElementSourcePartOfOpt(DAE.emptyElementSource, FGraph.getScopePath(env));

        if Flags.isSet(Flags.GC_PROF) then
          print(GC.profStatsStr(GC.getProfStats(), head="GC stats after pre-frontend work (building graphs):") + "\n");
        end if;
        ExecStat.execStat("FrontEnd - mkProgramGraph");

        (cache,env,ih,dae2) = instClassInProgram(cache, env, ih, cdecls, path, source);
        // check the models for balancing
        //Debug.fcall2(Flags.CHECK_MODEL_BALANCE, checkModelBalancing, SOME(path), dae1);
        //Debug.fcall2(Flags.CHECK_MODEL_BALANCE, checkModelBalancing, SOME(path), dae2);

        // let the GC collect these as they are used only by Inst!
        InstHashTable.release();
      then
        (cache,env,ih,dae2);

    // class in package
    case (cache,ih,(cdecls as (_ :: _)),(path as Absyn.QUALIFIED()))
      equation
        cache = FCore.setCacheClassName(cache,path);
        if doSCodeDep then
          cdecls = InstUtil.scodeFlatten(cdecls, inPath);
          ExecStat.execStat("FrontEnd - scodeFlatten");
        end if;
        pathstr = AbsynUtil.pathString(path);

        //System.startTimer();
        //print("\nBuiltinMaking");
        (cache,env) = Builtin.initialGraph(cache);
        //System.stopTimer();
        //print("\nBuiltinMaking: " + realString(System.getTimerIntervalTime()));

        //System.startTimer();
        //print("\nInstClassDecls");
        env = FGraphBuildEnv.mkProgramGraph(cdecls, FCore.USERDEFINED(), env);
        //System.stopTimer();
        //print("\nInstClassDecls: " + realString(System.getTimerIntervalTime()));

        //System.startTimer();
        //print("\nLookupClass");
        (cache,(cdef as SCode.CLASS(name = n)),env) = Lookup.lookupClass(cache, env, path, SOME(AbsynUtil.dummyInfo));

        //System.stopTimer();
        //print("\nLookupClass: " + realString(System.getTimerIntervalTime()));

        //System.startTimer();
        //print("\nInstClass");
        if Flags.isSet(Flags.GC_PROF) then
          print(GC.profStatsStr(GC.getProfStats(), head="GC stats after pre-frontend work (building graphs):") + "\n");
        end if;
        ExecStat.execStat("FrontEnd - mkProgramGraph");

        (cache,env,ih,_,dae,_,_,_,_,_) = instClass(cache,env,ih,
          UnitAbsynBuilder.emptyInstStore(),DAE.NOMOD(), makeTopComponentPrefix(env, n), cdef,
          {}, false, InstTypes.TOP_CALL(), ConnectionGraph.EMPTY, Connect.emptySet) "impl";
        //System.stopTimer();
        //print("\nInstClass: " + realString(System.getTimerIntervalTime()));

        //System.startTimer();
        //print("\nReEvaluateIf");
        //print(" ********************** backpatch 1 **********************\n");
        dae = InstUtil.reEvaluateInitialIfEqns(cache,env,dae,true);
        //System.stopTimer();
        //print("\nReEvaluateIf: " + realString(System.getTimerIntervalTime()));

        // check the model for balancing
        // Debug.fcall2(Flags.CHECK_MODEL_BALANCE, checkModelBalancing, SOME(path), dae);

        //System.startTimer();
        //print("\nSetSource+DAE");
        // set the source of this element
        source = ElementSource.addElementSourcePartOfOpt(DAE.emptyElementSource, FGraph.getScopePath(env));
        daeElts = DAEUtil.daeElements(dae);
        cmt = SCodeUtil.getElementComment(cdef);
        dae = DAE.DAE({DAE.COMP(pathstr,daeElts,source,cmt)});
        //System.stopTimer();
        //print("\nSetSource+DAE: " + realString(System.getTimerIntervalTime()));

        // let the GC collect these as they are used only by Inst!
        InstHashTable.release();
      then
        (cache, env, ih, dae);

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
  input Boolean doSCodeDep=true "Do SCode dependency (if the debug flag is also enabled)";
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
      algorithm
        (outCache,outEnv,outIH,outDAElist) := instantiateClass_dispatch(cache,ih,cdecls,path,doSCodeDep);
        outDAElist := UnitCheck.checkUnits(outDAElist,FCore.getFunctionTree(outCache));
      then
        (outCache,outEnv,outIH,outDAElist);

    // error instantiating
    case (_,_,_::_,path)
      equation
        // if we got a stack overflow remove the stack-overflow flag
        // adrpo: NOTE THAT THE NEXT FUNCTION CALL MUST BE THE FIRST IN THIS CASE, otherwise the stack overflow will not be caught!
        stackOverflow = setStackOverflowSignal(false);

        cname_str = AbsynUtil.pathString(path) + (if stackOverflow then ". The compiler got into Stack Overflow!" else "");
        if not Config.getGraphicsExpMode() then
          Error.addMessage(Error.ERROR_FLATTENING, {cname_str});
        end if;

        // let the GC collect these as they are used only by Inst!
        InstHashTable.release();
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
        cdecls = List.map1(cdecls,SCodeUtil.classSetPartial,SCode.NOT_PARTIAL());
        source = ElementSource.addElementSourcePartOfOpt(DAE.emptyElementSource, FGraph.getScopePath(env));
        (cache,env_2,ih,dae) = instClassInProgram(cache, env_1, ih, cdecls, path, source);
      then
        (cache,env_2,ih,dae);

    case (cache,ih,(cdecls as (_ :: _)),(path as Absyn.QUALIFIED())) /* class in package */
      equation
        (cache,env) = Builtin.initialGraph(cache);
        env_1 = FGraphBuildEnv.mkProgramGraph(cdecls, FCore.USERDEFINED(), env);
        (cache,(cdef as SCode.CLASS(name = n)),env_2) = Lookup.lookupClass(cache,env_1, path, SOME(AbsynUtil.dummyInfo));

        cdef = SCodeUtil.classSetPartial(cdef, SCode.NOT_PARTIAL());

        (cache,env_2,ih,_,dae,_,_,_,_,_) =
          instClass(cache, env_2, ih, UnitAbsynBuilder.emptyInstStore(),DAE.NOMOD(), makeTopComponentPrefix(env_2, n),
            cdef, {}, false, InstTypes.TOP_CALL(), ConnectionGraph.EMPTY, Connect.emptySet) "impl" ;
        pathstr = AbsynUtil.pathString(path);

        // set the source of this element
        source = ElementSource.addElementSourcePartOfOpt(DAE.emptyElementSource, FGraph.getScopePath(env));
        daeElts = DAEUtil.daeElements(dae);
        cmt = SCodeUtil.getElementComment(cdef);
        dae = DAE.DAE({DAE.COMP(pathstr,daeElts,source,cmt)});
      then
        (cache,env_2,ih,dae);

    case (_,_,_,path) /* error instantiating */
      guard not Config.getGraphicsExpMode()
      equation
        cname_str = AbsynUtil.pathString(path);
        //print(" Error flattening partial, errors: " + ErrorExt.printMessagesStr() + "\n");
        Error.addMessage(Error.ERROR_FLATTENING, {cname_str});
      then
        fail();
  end matchcontinue;
end instantiatePartialClass;

protected function makeTopComponentPrefix
  input FGraph.Graph inGraph;
  input Absyn.Ident inName;
  output DAE.Prefix outPrefix;
protected
  Absyn.Path p;
algorithm
  //p := FGraph.joinScopePath(inGraph, Absyn.IDENT(inName));
  //outPrefix := DAE.PREFIX(DAE.PRE("$i", {}, {}, DAE.NOCOMPPRE(), ClassInf.MODEL(p)), DAE.CLASSPRE(SCode.VAR()));
  outPrefix := DAE.NOPRE();
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

        cmt = SCodeUtil.getElementComment(cls);
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
  input DAE.Prefix inPrefix;
  input SCode.Element inClass;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean inImplicit;
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
  matchcontinue (inCache,inEnv,inIH,inStore,inMod,inPrefix,inClass,inInstDims,inImplicit,inCallingScope,inGraph,inSets)
    local
      FCore.Graph env,env_1,env_3;
      DAE.Mod mod;
      DAE.Prefix pre;
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
        false = SCodeUtil.isFunctionRestriction(r); // Partial functions are handled below (used for partially evaluated functions; do not want the checkModel warning)
        c = SCodeUtil.setClassPartialPrefix(SCode.NOT_PARTIAL(), inClass);
        // add a warning
        if not Config.getGraphicsExpMode() then
          Error.addSourceMessage(Error.INST_PARTIAL_CLASS_CHECK_MODEL_WARNING, {n}, info);
        end if;
        // call normal instantiation
        (cache,env,ih,store,dae,csets,ty,ci_state_1,oDA,graph) =
           instClass(inCache, inEnv, inIH, store, inMod, inPrefix, c, inInstDims, inImplicit, inCallingScope, inGraph, inSets);
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
        isFn = SCodeUtil.isFunctionRestriction(r);
        notIsPartial = not SCodeUtil.partialBool(partialPrefix);
        isPartialFn = isFn and SCodeUtil.partialBool(partialPrefix);
        true = notIsPartial or isPartialFn;

        env_1 = FGraph.openScope(env, encflag, n, FGraph.restrictionToScopeType(r));

        ci_state = ClassInf.start(r,FGraph.getGraphName(env_1));
        csets = ConnectUtil.newSet(pre, inSets);
        (cache,env_3,ih,store,dae1,csets,ci_state_1,tys,bc_ty,oDA,equalityConstraint, graph)
          = instClassIn(cache, env_1, ih, store, mod, pre, ci_state, c, SCode.PUBLIC(), inst_dims, impl, callscope, graph, csets, NONE());
        csets = ConnectUtil.addSet(inSets, csets);
        (cache,fq_class) = makeFullyQualifiedIdent(cache, env, n);

        // is top level?
        callscope_1 = InstUtil.isTopCall(callscope);

        dae1_1 = DAEUtil.addComponentType(dae1, fq_class);

        InstUtil.reportUnitConsistency(callscope_1,store);
        (csets, _, graph) = InnerOuter.retrieveOuterConnections(cache,env_3,ih,pre,csets,callscope_1, graph);

        //System.startTimer();
        //print("\nConnect equations and the OverConstrained graph in one step");
        dae = ConnectUtil.equations(callscope_1, csets, dae1_1, graph, AbsynUtil.pathString(AbsynUtil.makeNotFullyQualified(fq_class)));
        //System.stopTimer();
        //print("\nConnect and Overconstrained: " + realString(System.getTimerIntervalTime()) + "\n");
        ty = InstUtil.mktype(fq_class, ci_state_1, tys, bc_ty, equalityConstraint, c, InstUtil.extractComment(dae.elementLst));
        dae = InstUtil.updateDeducedUnits(callscope_1,store,dae);

        ty = markDerivedRecordOutsideBindings(ty, c);
        ty = markTypesVarsOutsideBindings(ty,mod);

        // Fixes partial functions.
        ty = InstUtil.fixInstClassType(ty,isPartialFn);
        // env_3 = FGraph.updateScope(env_3);
      then
        (cache,env_3,ih,store,dae,csets,ty,ci_state_1,oDA,graph);

    //  Classes with the keyword partial can not be instantiated. They can only be inherited
    case (cache,_,_,_,_,_,SCode.CLASS(name = n,partialPrefix = SCode.PARTIAL(), info = info),_,(false),_,_,_)
      equation
        if not Config.getGraphicsExpMode() then
          Error.addSourceMessage(Error.INST_PARTIAL_CLASS, {n}, info);
        end if;
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
  input DAE.Prefix inPrefix;
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
      DAE.Prefix pre;
      String n;
      SCode.Restriction r;
      InstDims inst_dims;
      InstTypes.CallingScope callscope;
      FCore.Cache cache;
      InstanceHierarchy ih;
      UnitAbsyn.InstStore store;

    case (cache,env,ih,store,mod,pre,(c as SCode.CLASS(name = n,encapsulatedPrefix = encflag,restriction = r)),inst_dims,impl,_,_) /* impl */
      equation
        env_1 = FGraph.openScope(env, encflag, n, FGraph.restrictionToScopeType(r));
        ci_state = ClassInf.start(r, FGraph.getGraphName(env_1));
        c_1 = SCodeUtil.classSetPartial(c, SCode.NOT_PARTIAL());
        (cache,env_3,ih,store,dae1,csets,ci_state_1,tys,bc_ty,_,_,_)
        = instClassIn(cache, env_1, ih, store, mod, pre, ci_state, c_1, SCode.PUBLIC(), inst_dims, impl, InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, inSets, NONE());
        (cache,fq_class) = makeFullyQualifiedIdent(cache,env_3, n);
        dae1_1 = DAEUtil.addComponentType(dae1, fq_class);
        dae = dae1_1;
        ty = InstUtil.mktypeWithArrays(fq_class, ci_state_1, tys, bc_ty, c, InstUtil.extractComment(dae.elementLst));
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
  input DAE.Prefix inPrefix;
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
  output list<DAE.Var> outVars;
  output Option<DAE.Type> outType;
  output Option<SCode.Attributes> optDerAttr;
  output DAE.EqualityConstraint outEqualityConstraint;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outStore,outDae,outSets,outState,outVars,outType,optDerAttr,outEqualityConstraint,outGraph):=
  matchcontinue inClass
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
    case SCode.CLASS(prefixes = SCode.PREFIXES(innerOuter = io))
      equation
        true = boolOr(AbsynUtil.isNotInnerOuter(io), AbsynUtil.isOnlyInner(io));
        (cache,env,ih,store,ci_state,graph,csets,dae,tys,bc,oDA,equalityConstraint) =
          instClassIn2(inCache,inEnv,inIH,inStore,inMod,inPrefix,inState,inClass,inVisibility,inInstDims,implicitInstantiation,inCallingScope,inGraph,inSets,instSingleCref);
      then
        (cache,env,ih,store,dae,csets,ci_state,tys,bc,oDA,equalityConstraint,graph);

    // if the class is inner or innerouter and an instance, use the original name and original scope
    case SCode.CLASS(name = n, restriction=r, encapsulatedPrefix = encflag, prefixes = SCode.PREFIXES(innerOuter = io))
      equation
        true = boolOr(AbsynUtil.isInnerOuter(io), AbsynUtil.isOnlyOuter(io));
        FCore.CL(status = FCore.CLS_INSTANCE(n)) = FNode.refData(FGraph.lastScopeRef(inEnv));
        (env, _) = FGraph.stripLastScopeRef(inEnv);

        env = FGraph.openScope(env, encflag, n, FGraph.restrictionToScopeType(r));
        ci_state = ClassInf.start(r,FGraph.getGraphName(env));

        // lookup in IH
        InnerOuter.INST_INNER(innerElement = SOME(c)) =
          InnerOuter.lookupInnerVar(inCache, env, inIH, inPrefix, n, io);

        (cache,env,ih,store,ci_state,graph,csets,dae,tys,bc,oDA,equalityConstraint) =
          instClassIn2(inCache,env,inIH,inStore,inMod,inPrefix,ci_state,c,inVisibility,inInstDims,implicitInstantiation,inCallingScope,inGraph,inSets,instSingleCref);
      then
        (cache,env,ih,store,dae,csets,ci_state,tys,bc,oDA,equalityConstraint,graph);

    // if the class is inner or innerouter we need to instantiate the inner!
    case SCode.CLASS(name = n, prefixes = SCode.PREFIXES(innerOuter = io))
      equation
        true = boolOr(AbsynUtil.isInnerOuter(io), AbsynUtil.isOnlyOuter(io));
        n = FGraph.getInstanceOriginalName(inEnv, n);

        // lookup in IH
        InnerOuter.INST_INNER(innerElement = SOME(c)) =
          InnerOuter.lookupInnerVar(inCache, inEnv, inIH, inPrefix, n, io);

        (cache,env,ih,store,ci_state,graph,csets,dae,tys,bc,oDA,equalityConstraint) =
          instClassIn2(inCache,inEnv,inIH,inStore,inMod,inPrefix,inState,c,inVisibility,inInstDims,implicitInstantiation,inCallingScope,inGraph,inSets,instSingleCref);
      then
        (cache,env,ih,store,dae,csets,ci_state,tys,bc,oDA,equalityConstraint,graph);

    // we could not find the inner, use the outer as it is!
    case SCode.CLASS(name = n, prefixes = SCode.PREFIXES(innerOuter = io), info = info)
      equation
        true = boolOr(AbsynUtil.isInnerOuter(io), AbsynUtil.isOnlyOuter(io));

        if not Config.getGraphicsExpMode() then
          s1 = n;
          s2 = Dump.unparseInnerouterStr(io);
          Error.addSourceMessage(Error.MISSING_INNER_CLASS,{s1, s2}, info);
        end if;

        (cache,env,ih,store,ci_state,graph,csets,dae,tys,bc,oDA,equalityConstraint) =
          instClassIn2(inCache,inEnv,inIH,inStore,inMod,inPrefix,inState,inClass,inVisibility,inInstDims,implicitInstantiation,inCallingScope,inGraph,inSets,instSingleCref);
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
  input output FCore.Cache cache;
  input output FCore.Graph env;
  input output InnerOuter.InstHierarchy ih;
  input output UnitAbsyn.InstStore store;
  input        DAE.Mod mod;
  input        DAE.Prefix prefix;
  input output ClassInf.State state;
  input        SCode.Element cls;
  input        SCode.Visibility visibility;
  input        list<list<DAE.Dimension>> instDims;
  input        Boolean implicitInst;
  input        InstTypes.CallingScope callingScope;
  input output ConnectionGraph.ConnectionGraph graph;
  input output Connect.Sets sets;
  input        Option<DAE.ComponentRef> instSingleCref;
        output DAE.DAElist dae;
        output list<DAE.Var> vars;
        output Option<DAE.Type> ty;
        output Option<SCode.Attributes> optDerAttr;
        output DAE.EqualityConstraint equalityConstraint;
protected
  Absyn.Path cache_path;
  InstHashTable.CachedInstItemInputs inputs;
  InstHashTable.CachedInstItemOutputs outputs;
  tuple<InstDims, Boolean, DAE.Mod, Connect.Sets, ClassInf.State, SCode.Element, Option<DAE.ComponentRef>> bbx, bby;
  DAE.Mod m;
  DAE.Prefix pre;
  Connect.Sets csets;
  ClassInf.State st;
  SCode.Element e;
  InstDims dims;
  Boolean impl;
  Option<DAE.ComponentRef> scr;
  InstTypes.CallingScope cs;
  ConnectionGraph.ConnectionGraph cached_graph;
algorithm
  // Packages derived from partial packages should do partialInstClass, since it
  // filters out a lot of things.
  if SCodeUtil.isPackage(cls) and SCodeUtil.isPartial(cls) then
    (cache, env, ih, state) := partialInstClassIn(cache, env, ih, mod, prefix,
      state, cls, visibility, instDims, 0);
    dae := DAE.emptyDae;
    vars := {};
    ty := NONE();
    optDerAttr := NONE();
    equalityConstraint := NONE();
    return;
  end if;

  cache_path := generateCachePath(env, cls, prefix, callingScope);

  // See if we have it in the cache.
  if Flags.isSet(Flags.CACHE) then
    try
      {SOME(InstHashTable.FUNC_instClassIn(inputs, outputs)), _} := InstHashTable.get(cache_path);
      (m, pre, csets, st, e as SCode.CLASS(), dims, impl, scr, cs) := inputs;

      // Are the important inputs the same?
      InstUtil.prefixEqualUnlessBasicType(prefix, pre, cls);
      if (valueEq(dims,instDims) and (impl==implicitInst) and valueEq(m, mod) and valueEq(csets, sets) and valueEq(st, state) and valueEq(e, cls) and valueEq(scr, instSingleCref) and callingScopeCacheEq(cs, callingScope)) then
        (env, dae, sets, state, vars, ty, optDerAttr, equalityConstraint, cached_graph) := outputs;
        graph := ConnectionGraph.merge(graph, cached_graph);
        showCacheInfo("Full Inst Hit: ", cache_path);
        return;
      end if;
    else
      // Not found in cache, continue.
    end try;
  end if;

  // If not found in the cache, instantiate the class and add it to the cache.
  try
    inputs := (mod, prefix, sets, state, cls, instDims, implicitInst, instSingleCref, callingScope);

    (cache, env, ih, store, dae, sets, state, vars, ty, optDerAttr, equalityConstraint, graph) :=
      instClassIn_dispatch(cache, env, ih, store, mod, prefix, state, cls,
        visibility, instDims, implicitInst, callingScope, graph, sets, instSingleCref);

    outputs := (env, dae, sets, state, vars, ty, optDerAttr, equalityConstraint, graph);

    showCacheInfo("Full Inst Add: ", cache_path);
    InstHashTable.addToInstCache(cache_path, SOME(InstHashTable.FUNC_instClassIn(inputs, outputs)), NONE());
  else
    true := Flags.isSet(Flags.FAILTRACE);
    Debug.traceln("- Inst.instClassIn2 failed on class: " + SCodeUtil.elementName(cls) +
        " in environment: " + FGraph.printGraphPathStr(env));
    fail();
  end try;
end instClassIn2;


protected function markDerivedRecordOutsideBindings
  input DAE.Type inType;
  input SCode.Element inClass;
  output DAE.Type outType;
protected
  SCode.Mod derMod;
  list<SCode.SubMod> submods;
algorithm

  if not SCodeUtil.isRecord(inClass)
     or not SCodeUtil.isDerivedClass(inClass) then
    outType := inType;
    return;
  end if;

  derMod := SCodeUtil.getDerivedMod(inClass);
  if SCodeUtil.isEmptyMod(derMod) then
    outType := inType;
    return;
  end if;

  try
    SCode.MOD(subModLst = submods) := derMod;
  else
    Error.addMessage(Error.INTERNAL_ERROR, {"Unexpected Mod structure in collectAndFixDerivedComplexOutsideBindings."});
    fail();
  end try;

  outType := match inType
    local
      list<DAE.Var> tvars;
      Option<DAE.Exp> obind;
      DAE.Exp bind_exp;

    case DAE.T_COMPLEX() algorithm
      tvars := {};
      for var in inType.varLst loop

        for submod in submods loop
          if varIsModifiedInDerivedMod(var.name, submod) then
            var.bind_from_outside := true;
            var.binding := markBindingFromDerivedRecordMods(var.binding);
            break;
          end if;
        end for;

        tvars := var::tvars;
      end for;
      tvars := listReverse(tvars);

    then DAE.T_COMPLEX(inType.complexClassType, tvars, inType.equalityConstraint);
  end match;

end markDerivedRecordOutsideBindings;

function markBindingFromDerivedRecordMods
  input output DAE.Binding bind;
algorithm
  _ := match bind
    case DAE.EQBOUND() algorithm
      bind.source := DAE.BINDING_FROM_DERIVED_RECORD_DECL();
    then ();

    else ();
  end match;
end markBindingFromDerivedRecordMods;

function varIsModifiedInDerivedMod
  input String inName;
  input SCode.SubMod inSubmod;
  output Boolean b;
algorithm
  b := match inSubmod
    case SCode.NAMEMOD(mod=SCode.REDECL()) then false;
    case SCode.NAMEMOD() then stringEqual(inSubmod.ident, inName);
  end match;
end varIsModifiedInDerivedMod;

protected function markTypesVarsOutsideBindings
  input DAE.Type inType;
  input DAE.Mod inMod;
  output DAE.Type outType = inType;
protected
  list<DAE.SubMod> submods;
algorithm

  if not Types.isRecord(inType) then
     return;
  end if;

  try
    DAE.MOD(subModLst = submods) := inMod;
  else
    return;
  end try;

  if listEmpty(submods) then
    return;
  end if;


  outType := match inType
    local
      list<DAE.Var> tvars;
      Option<DAE.Exp> obind;
      DAE.Exp bind_exp;

    case DAE.T_COMPLEX() algorithm
      tvars := {};
      for var in inType.varLst loop

        for submod in submods loop
          if varIsModifiedInMod(var.name, submod) then
            var.bind_from_outside := true;
            break;
          end if;
        end for;

        tvars := var::tvars;
      end for;
      tvars := listReverse(tvars);

    then DAE.T_COMPLEX(inType.complexClassType, tvars, inType.equalityConstraint);
  end match;

end markTypesVarsOutsideBindings;

function varIsModifiedInMod
  input String inName;
  input DAE.SubMod inSubmod;
  output Boolean b;
algorithm
  b := match inSubmod
    case DAE.NAMEMOD() then stringEqual(inSubmod.ident, inName);
  end match;
end varIsModifiedInMod;


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
  input DAE.Prefix inPrefix;
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
      DAE.Prefix pre;
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
    // Instantiate enumeration class at top level DAE.NOPRE()
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
        names = SCodeUtil.componentNames(c);
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
        (cache,env_1,ih) = InstUtil.addComponentsToEnv(cache,env,ih, mods, pre, ci_state_1, comp, impl);

        // we should instantiate with no modifications, they don't belong to the class, they belong to the component!
        (cache,env_2,ih,store,_,csets,ci_state_1,tys1,graph,_) =
          instElementList(cache,env_1,ih,store, /* DAE.NOMOD() */ mods, pre,
            ci_state_1, comp, inst_dims, impl,callscope,graph, inSets, true);

        (cache,fq_class) = makeFullyQualifiedIdent(cache,env_2, n);
        eqConstraint = InstUtil.equalityConstraint(env_2, els, info);
        // DAEUtil.addComponentType(dae1, fq_class);
        ty2 = DAE.T_ENUMERATION(NONE(), fq_class, names, tys1, tys);
        bc = arrayBasictypeBaseclass(inst_dims, ty2);
        bc = if isSome(bc) then bc else SOME(ty2);
        ty = InstUtil.mktype(fq_class, ci_state_1, tys1, bc, eqConstraint, c, SCode.noComment);
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
        dae = if SCodeUtil.isFunction(c) and not impl then DAE.DAE({}) else dae;
        ErrorExt.delCheckpoint("instClassParts");
      then
        (cache,env_1,ih,store,dae,csets,ci_state_1,tys,bc,oDA,eqConstraint,graph);

     /* Ignore functions if not implicit instantiation, and doing checkModel - some dimensions might not be complete... */
    case (cache,env,ih,store,_,_,ci_state,c as SCode.CLASS(),_,_,impl,_,graph,_,_)
      equation
        b = Flags.getConfigBool(Flags.CHECK_MODEL) and (not impl) and SCodeUtil.isFunction(c);
        if not b then
          ErrorExt.delCheckpoint("instClassParts");
          fail();
        else
          ErrorExt.rollBack("instClassParts");
        end if;
        // clsname = SCodeUtil.className(cls);
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
        true = Config.synchronousFeaturesAllowed();
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
        true = Config.synchronousFeaturesAllowed();
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
  input DAE.Prefix inPrefix;
  output list<DAE.Var> outVars;
algorithm
  outVars := match inMod
    local
      list<DAE.SubMod> submods;

    case DAE.MOD(subModLst = submods)
      then List.map4(submods, instBasicTypeAttributes2, inCache, inEnv, inBaseType, inTypeFunc);

    case DAE.NOMOD() then {};
    case DAE.REDECL() then {};
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
  outVar := match(inSubMod)
    local
      DAE.Ident name;
      DAE.Type ty;
      DAE.Exp exp;
      Option<Values.Value> val;
      DAE.Properties p;
      SourceInfo info;

    case (DAE.NAMEMOD(ident = name, mod = DAE.MOD(binding = SOME(DAE.TYPED(
        modifierAsExp = exp, modifierAsValue = val, properties = p)), info = info)))
      equation
        ty = getRealAttributeType(name, inBaseType, info);
      then
        instBuiltinAttribute(inCache, inEnv, name, val, exp, ty, p);

    case (DAE.NAMEMOD(ident = name))
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
        DAE.EQBOUND(bind1,SOME(v),DAE.C_PARAM(),DAE.BINDING_FROM_DEFAULT_VALUE()),false,NONE());

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
        DAE.EQBOUND(bind1,SOME(v),DAE.C_PARAM(),DAE.BINDING_FROM_DEFAULT_VALUE()),false,NONE());

    case (cache,env,_,_,_,expectedTp,DAE.PROP(bindTp,c))
      equation
        false = valueEq(c,DAE.C_VAR());
        (bind1,t_1) = Types.matchType(bind,bindTp,expectedTp,true);
        (cache,v) = Ceval.ceval(cache, env, bind1, false, Absyn.NO_MSG(), 0);
      then DAE.TYPES_VAR(id,DAE.dummyAttrParam,t_1,
        DAE.EQBOUND(bind1,SOME(v),DAE.C_PARAM(),DAE.BINDING_FROM_DEFAULT_VALUE()),false,NONE());

    case (cache,env,_,_,_,expectedTp,DAE.PROP(bindTp as DAE.T_ARRAY(dims = {d}),c))
      equation
        false = valueEq(c,DAE.C_VAR());
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        expectedTp = Types.liftArray(expectedTp, d);
        (bind1,t_1) = Types.matchType(bind,bindTp,expectedTp,true);
        (cache,v) = Ceval.ceval(cache,env, bind1, false, Absyn.NO_MSG(), 0);
      then DAE.TYPES_VAR(id,DAE.dummyAttrParam,t_1,
        DAE.EQBOUND(bind1,SOME(v),DAE.C_PARAM(),DAE.BINDING_FROM_DEFAULT_VALUE()),false,NONE());

    case(_,_,_,_,_,expectedTp,DAE.PROP(bindTp,c))
      equation
        if Flags.getConfigBool(Flags.CT_STATE_MACHINES) then
          // BTH Hack to allow variable modification of "start" attribute for ct SM re-initialization
          // This is is forbidden in standard Modelica! Standard Modelica is the "else" branch!
          true = valueEq(c,DAE.C_VAR());
        else
          false = valueEq(c,DAE.C_VAR());
        end if;
        (bind1,t_1) = Types.matchType(bind,bindTp,expectedTp,true);
      then DAE.TYPES_VAR(id,DAE.dummyAttrParam,t_1,
        DAE.EQBOUND(bind1,NONE(),DAE.C_PARAM(),DAE.BINDING_FROM_DEFAULT_VALUE()),false,NONE());

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
  input output FCore.Cache cache;
  input output FCore.Graph env;
  input output InnerOuter.InstHierarchy ih;
  input        DAE.Mod mod;
  input        DAE.Prefix prefix;
  input output ClassInf.State state;
  input        SCode.Element cls;
  input        SCode.Visibility visibility;
  input        list<list<DAE.Dimension>> instDims;
  input        Integer numIter;
        output list<DAE.Var> vars;
protected
  Absyn.Path cache_path;
  InstHashTable.CachedPartialInstItemInputs inputs;
  InstHashTable.CachedPartialInstItemOutputs outputs;
  tuple<InstDims, DAE.Mod, ClassInf.State, SCode.Element> bbx, bby;
  DAE.Mod m;
  DAE.Prefix pre;
  ClassInf.State st;
  SCode.Element e;
  InstDims dims;
  Boolean partial_inst;
algorithm
  cache_path := generateCachePath(env, cls, prefix, InstTypes.INNER_CALL());

  // See if we have it in the cache.
  if Flags.isSet(Flags.CACHE) then

    try
      {_, SOME(InstHashTable.FUNC_partialInstClassIn(inputs, outputs))} := InstHashTable.get(cache_path);
      (m, pre, st, e as SCode.CLASS(), dims) := inputs;

      // Are the important inputs the same?
      InstUtil.prefixEqualUnlessBasicType(pre, prefix, cls);
      if (valueEq(dims,instDims) and valueEq(m, mod) and valueEq(st, state) and valueEq(e, cls)) then
        (env, state, vars) := outputs;
        showCacheInfo("Partial Inst Hit: ", cache_path);
        return;
      end if;
    else
      // Not in cache, continue.
    end try;
  end if;

  // Check that we don't have an instantiation loop.
  if numIter >= Global.recursionDepthLimit then
    Error.addSourceMessage(Error.RECURSION_DEPTH_REACHED,
      {String(Global.recursionDepthLimit), FGraph.printGraphPathStr(env)}, SCodeUtil.elementInfo(cls));
    fail();
  end if;

  // Instantiate the class and add it to the cache.
  try
    partial_inst := System.getPartialInstantiation();
    System.setPartialInstantiation(true);

    inputs := (mod, prefix, state, cls, instDims);

    (cache, env, ih, state, vars) :=
      partialInstClassIn_dispatch(cache, env, ih, mod, prefix, state, cls,
        visibility, instDims, partial_inst, numIter + 1);

    outputs := (env, state, vars);

    showCacheInfo("Partial Inst Add: ", cache_path);
    InstHashTable.addToInstCache(cache_path, NONE(), SOME(InstHashTable.FUNC_partialInstClassIn(inputs, outputs)));
  else
    true := Flags.isSet(Flags.FAILTRACE);
    Debug.traceln("- Inst.partialInstClassIn failed on class: " +
       SCodeUtil.elementName(cls) + " in environment: " + FGraph.printGraphPathStr(env));
    fail();
  end try;
end partialInstClassIn;

protected function partialInstClassIn_dispatch
"This function is used when instantiating classes in lookup of other classes.
  The only work performed by this function is to instantiate local classes and
  inherited classes."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input DAE.Prefix inPrefix;
  input ClassInf.State inState;
  input SCode.Element inClass;
  input SCode.Visibility inVisibility;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean partialInst;
  input Integer numIter;
  output FCore.Cache outCache = inCache;
  output FCore.Graph outEnv = inEnv;
  output InnerOuter.InstHierarchy outIH = inIH;
  output ClassInf.State outState = inState;
  output list<DAE.Var> outVars = {};
protected
  Boolean success;
algorithm
  success := matchcontinue inClass
    case SCode.CLASS(name = "Real")    then true;
    case SCode.CLASS(name = "Integer") then true;
    case SCode.CLASS(name = "String")  then true;
    case SCode.CLASS(name = "Boolean") then true;
    // BTH
    case SCode.CLASS(name = "Clock")
      guard(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD) == 33) then true;

    case SCode.CLASS()
      equation
        (outCache, outEnv, outIH, outState, outVars) =
          partialInstClassdef(inCache, inEnv, inIH, inMod, inPrefix, inState,
              inClass, inClass.classDef, inVisibility, inInstDims, numIter);
      then
        true;

    else false;
  end matchcontinue;

  System.setPartialInstantiation(partialInst);
  if not success then fail(); end if;
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
  input DAE.Prefix inPrefix3;
  input ClassInf.State inState5;
  input String className;
  input SCode.ClassDef inClassDef6;
  input SCode.Restriction inRestriction7;
  input SCode.Visibility inVisibility;
  input SCode.Partial inPartialPrefix;
  input SCode.Encapsulated inEncapsulatedPrefix;
  input list<list<DAE.Dimension>> inInstDims9;
  input Boolean inImplicit;
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
    inPartialPrefix,inEncapsulatedPrefix,inInstDims9,inImplicit,inCallingScope,inGraph,inSets,instSingleCref,comment,info,Mutable.create(false));
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
  input DAE.Prefix inPrefix3;
  input ClassInf.State inState5;
  input String className;
  input SCode.ClassDef inClassDef6;
  input SCode.Restriction inRestriction7;
  input SCode.Visibility inVisibility;
  input list<list<DAE.Dimension>> inInstDims9;
  input Boolean inImplicit;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  input Option<DAE.ComponentRef> instSingleCref;
  input SourceInfo info;
  input Mutable<Boolean> stopInst "prevent instantiation of classes adding components to primary types";
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
  matchcontinue (inCache,inEnv,inIH,inStore,inMod2,inPrefix3,inState5,className,inClassDef6,inRestriction7,inVisibility,inInstDims9,inImplicit,inGraph,inSets,instSingleCref,info,stopInst)
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
      DAE.Prefix pre;
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
        (cache,env3,ih,store,dae1,csets,_,tys,graph,_) =
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

    // VERY COMPLICATED CHECKPOINT! TODO! try to simplify it, maybe by sending DAE.TYPE and checking in instVar!
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
  input DAE.Prefix inPrefix3;
  input ClassInf.State inState5;
  input String className;
  input SCode.ClassDef inClassDef6;
  input SCode.Restriction inRestriction7;
  input SCode.Visibility inVisibility;
  input SCode.Partial inPartialPrefix;
  input SCode.Encapsulated inEncapsulatedPrefix;
  input list<list<DAE.Dimension>> inInstDims9;
  input Boolean inImplicit;
  input InstTypes.CallingScope inCallingScope;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  input Option<DAE.ComponentRef> instSingleCref;
  input SCode.Comment comment;
  input SourceInfo info;
  input Mutable<Boolean> stopInst "prevent instantiation of classes adding components to primary types";
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
  matchcontinue (inCache,inEnv,inIH,inStore,inMod2,inPrefix3,inState5,className,inClassDef6,inRestriction7,inVisibility,inPartialPrefix,inEncapsulatedPrefix,inInstDims9,inImplicit,inCallingScope,inGraph,inSets,instSingleCref,comment,info,stopInst)
    local
      list<SCode.Element> cdefelts,compelts,extendselts,els,extendsclasselts,compelts_2_elem;
      FCore.Graph env1,env2,env3,env,env5,cenv,cenv_2,env_2,parentEnv,parentClassEnv;
      list<tuple<SCode.Element, DAE.Mod>> cdefelts_1,extcomps,compelts_1,compelts_2, comp_cond, derivedClassesWithConstantMods;
      Connect.Sets csets,csets1,csets2,csets3,csets4,csets5,csets_1;
      DAE.DAElist dae1,dae2,dae3,dae4,dae5,dae6,dae7,dae8,dae;
      ClassInf.State ci_state1,ci_state,ci_state2,ci_state3,ci_state4,ci_state5,ci_state6,ci_state7,new_ci_state,ci_state_1;
      list<DAE.Var> vars;
      Option<DAE.Type> bc;
      DAE.Mod mods,emods,mod_1,mods_1,checkMods;
      DAE.Prefix pre;
      list<SCode.Equation> eqs,initeqs,eqs2,initeqs2,eqs_1,initeqs_1;
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
      SCode.ClassDef classDef, classDefParent;
      Option<DAE.EqMod> eq;
      DAE.Dimensions dims;
      Absyn.Path cn, fq_class;
      Option<list<Absyn.Subscript>> ad;
      SCode.Mod mod;
      FCore.Cache cache;
      Option<SCode.Attributes> oDA;
      list<SCode.Comment> comments;
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
      //List<tuple<Absyn.ComponentRef,DAE.ComponentRef>> fieldDomLst;
      InstUtil.DomainFieldsLst domainFieldsLst;
      list<String> typeVars;
//      list<tuple<String,Integer>> domainNLst;

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
        false = Mutable.access(stopInst);
        // adpro: if is a model, package, function, external function, record is not a basic type!
        false = valueEq(SCode.R_MODEL(), re);
        false = valueEq(SCode.R_PACKAGE(), re);
        false = SCodeUtil.isFunctionRestriction(re);
        false = valueEq(SCode.R_RECORD(true), re);
        false = valueEq(SCode.R_RECORD(false), re);
        // no components and at least one extends!

        (cdefelts,extendsclasselts,extendselts as _::_,{}) = InstUtil.splitElts(els);
        extendselts = SCodeInstUtil.addRedeclareAsElementsToExtends(extendselts, List.select(els, SCodeUtil.isRedeclareElement));
        (cache,env1,ih) = InstUtil.addClassdefsToEnv(cache, env, ih, pre, cdefelts, impl, SOME(mods));
        (cache,_,_,_,extcomps,{},{},{},{},_) =
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
        false = Mutable.access(stopInst);
         true = SCodeUtil.isExternalObject(els);
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
        false = Mutable.access(stopInst);
        false = SCodeUtil.isExternalObject(els);
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

        extendselts = SCodeInstUtil.addRedeclareAsElementsToExtends(extendselts, List.select(els, SCodeUtil.isRedeclareElement));

        (cache, env1,ih) = InstUtil.addClassdefsToEnv(cache, env, ih, pre,
          cdefelts, impl, SOME(mods), FGraph.isEmptyScope(env));

        //// fprintln(Flags.INST_TRACE, "after InstUtil.addClassdefsToEnv ENV: " + if_(stringEq(className, "PortVolume"), FGraph.printGraphStr(env1), " no env print "));

        // adrpo: TODO! DO SOME CHECKS HERE!
        // restriction on what can inherit what, see 7.1.3 Restrictions on the Kind of Base Class
        // if a type   -> no components, can extends only another type
        // if a record -> components ok
        // checkRestrictionsOnTheKindOfBaseClass(cache, env, ih, re, extendselts);

        (cache,env2,ih,emods,extcomps,eqs2,initeqs2,alg2,initalg2,comments) =
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
        if intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.PDEMODELICA) then
          compelts_1 = InstUtil.addGhostCells(compelts_1, eqs_1);
        end if;

        //(csets, env2, ih) = InstUtil.addConnectionCrefsFromEqs(csets, eqs_1, pre, env2, ih);

        //// fprintln(Flags.INST_TRACE, "Emods to InstUtil.addComponentsToEnv: " + Mod.printModStr(emods));

        //Add variables to env, wihtout type and binding, which will be added
        //later in instElementList (where update_variable is called)"
        checkMods = Mod.merge(mods,emods, className);
        mods = checkMods;
        (cache,env3,ih) = InstUtil.addComponentsToEnv(cache, env2, ih, mods, pre, ci_state, compelts_1, impl);

        //Instantiate components
        compelts_2_elem = List.map(compelts_1,Util.tuple21);
        InstUtil.matchModificationToComponents(compelts_2_elem,checkMods,FGraph.printGraphPathStr(env3));

        // Move any conditional components to the end of the component list, to
        // make sure that any dependencies of the condition are instantiated first.
        (comp_cond, compelts_1) = List.splitOnTrue(compelts_1, InstUtil.componentHasCondition);
        compelts_2 = listAppend(compelts_1, comp_cond);

        // BTH: Search for state machine components and update ih correspondingly.
        (smCompCrefs, smInitialCrefs) = InstStateMachineUtil.getSMStatesInContext(eqs_1, pre);
        //ih = List.fold1(smCompCrefs, InnerOuter.updateSMHierarchy, inPrefix3, ih);
        ih = List.fold(smCompCrefs, InnerOuter.updateSMHierarchy, ih);

        (cache,env5,ih,store,dae1,csets,ci_state2,vars,graph,domainFieldsLst) =
          instElementList(cache, env3, ih, store, mods, pre, ci_state1,
            compelts_2, inst_dims, impl, callscope, graph, csets, true);

        // If we are currently instantiating a connector, add all flow variables
        // in it as inside connectors.
        zero_dims = InstUtil.instDimsHasZeroDims(inst_dims);
        elementSource = ElementSource.createElementSource(info, FGraph.getScopePath(env3), pre);
        csets1 = ConnectUtil.addConnectorVariablesFromDAE(zero_dims, ci_state1, pre, vars, info, elementSource, csets);

        (cache, eqs_1) = InstUtil.reorderConnectEquationsExpandable(cache, env5, eqs_1);

        //Discretization of PDEs:
        if intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.PDEMODELICA) then
          eqs_1 = List.fold1(eqs_1, InstUtil.discretizePDE, domainFieldsLst, {});
        end if;
        //Instantiate equations (see function "instEquation")
        (cache,env5,ih,dae2,csets2,ci_state3,graph) =
          instList(cache, env5, ih, pre, csets1, ci_state2, InstSection.instEquation, eqs_1, impl, InstTypes.alwaysUnroll, graph);
        DAEUtil.verifyEquationsDAE(dae2);

        //Discretization of initial equations of fields:
        if intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.PDEMODELICA) then
          initeqs_1 = List.fold1(initeqs_1, InstUtil.discretizePDE, domainFieldsLst,/* domainNLst,*/ {});
        end if;
        //Instantiate inital equations (see function "instInitialEquation")
        (cache,env5,ih,dae3,csets3,ci_state4,graph) =
          instList(cache, env5, ih, pre, csets2, ci_state3, InstSection.instInitialEquation, initeqs_1, impl, InstTypes.alwaysUnroll, graph);

        // do NOT unroll for loops for functions!
        unrollForLoops = if SCodeUtil.isFunctionRestriction(re) then InstTypes.neverUnroll else InstTypes.alwaysUnroll;

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

        dae8 = instFunctionAnnotations(comment::comments, ci_state6);

        // BTH: Relate state machine components to the flat state machine that they are part of
        smCompToFlatSM = InstStateMachineUtil.createSMNodeToFlatSMGroupTable(dae2);
        // BTH: Wrap state machine components (including transition statements) into corresponding flat state machine containers
        (dae1,dae2) = InstStateMachineUtil.wrapSMCompsInFlatSMs(ih, dae1, dae2, smCompToFlatSM, smInitialCrefs);

        //Collect the DAE's
        dae = DAEUtil.joinDaeLst({dae1,dae2,dae3,dae4,dae5,dae6,dae7,dae8});

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
        (cache,oty) = InstMeta.fixUniontype(cache, env5, ci_state6, inClassDef6);
        _ = match oty
          case SOME(ty as DAE.T_METAUNIONTYPE(typeVars=_::_))
            algorithm
              Error.addSourceMessage(Error.UNIONTYPE_MISSING_TYPEVARS, {Types.unparseType(ty)}, info);
            then fail();
          else ();
        end match;
      then
        (cache,env5,ih,store,dae,csets5,ci_state6,vars,oty,NONE(),eqConstraint,graph);

    // This rule describes how to instantiate class definition derived from an enumeration
    case (cache,env,ih,store,mods,pre,_,_,
          SCode.DERIVED(typeSpec=Absyn.TPATH(path = cn,arrayDim = ad),modifications = mod,attributes=DA),
          re,vis,_,_,inst_dims,impl,callscope,graph,_,_,_,_,_)
      equation
        false = Mutable.access(stopInst);

        (cache,(c as SCode.CLASS(name=cn2,encapsulatedPrefix=enc2,restriction=r as SCode.R_ENUMERATION())), cenv) =
          Lookup.lookupClass(cache, env, cn, SOME(info));

        // keep the old behaviour
        env3 = FGraph.openScope(cenv, enc2, cn2, SOME(FCore.CLASS_SCOPE()));
        ci_state2 = ClassInf.start(r, FGraph.getGraphName(env3));
        new_ci_state = ClassInf.start(r, FGraph.getGraphName(env3));

        // print("Enum Env: " + FGraph.printGraphPathStr(env3) + "\n");
        (cache,cenv_2,_,_,_,_,_,_,_,_,_,_) =
        instClassIn(
          cache,env3,InnerOuter.emptyInstHierarchy,UnitAbsyn.noStore,
          DAE.NOMOD(), DAE.NOPRE(), ci_state2, c, SCode.PUBLIC(), {}, false,
          callscope, ConnectionGraph.EMPTY, Connect.emptySet, NONE());

        (cache,mod_1) = Mod.elabMod(cache, cenv_2, ih, pre, mod, impl, Mod.DERIVED(cn), info);

        mods_1 = Mod.merge(mods, mod_1, className);
        eq = Mod.modEquation(mods_1) "instantiate array dimensions" ;
        (cache,dims) = InstUtil.elabArraydimOpt(cache,cenv_2, Absyn.CREF_IDENT("",{}),cn, ad, eq, impl,true,pre,info,inst_dims) "owncref not valid here" ;
        // inst_dims2 = InstUtil.instDimExpLst(dims, impl);
        inst_dims_1 = List.appendLastList(inst_dims, dims);

        (cache,env_2,ih,store,dae,csets_1,ci_state_1,vars,bc,oDA,eqConstraint,graph) = instClassIn(cache, cenv_2, ih, store, mods_1, pre, new_ci_state, c, vis,
          inst_dims_1, impl, callscope, graph, inSets, instSingleCref) "instantiate class in opened scope.";
        ClassInf.assertValid(ci_state_1, re, info) "Check for restriction violations";
        oDA = SCodeUtil.mergeAttributes(DA,oDA);
      then
        (cache,env_2,ih,store,dae,csets_1,ci_state_1,vars,bc,oDA,eqConstraint,graph);

    // This rule describes how to instantiate a derived class definition from basic types
    case (cache,env,ih,store,mods,pre,ci_state,_,
          SCode.DERIVED(typeSpec=Absyn.TPATH(path = cn,arrayDim = ad),modifications = mod,attributes=DA),
          re,vis,_,_,inst_dims,impl,callscope,graph,_,_,_,_,_)
      equation
        false = Mutable.access(stopInst);

        (cache,(c as SCode.CLASS(name=cn2,encapsulatedPrefix=enc2,restriction=r)),cenv) = Lookup.lookupClass(cache, env, cn, SOME(info));

        // if is a basic type or derived from it, follow the normal path
        true = InstUtil.checkDerivedRestriction(re, r, cn2);

        // If it's a connector, check that it's valid.
        valid_connector = ConnectUtil.checkShortConnectorDef(ci_state, DA, info);
        Mutable.update(stopInst, not valid_connector);
        true = valid_connector;

        cenv_2 = FGraph.openScope(cenv, enc2, cn2, FGraph.classInfToScopeType(ci_state));
        new_ci_state = ClassInf.start(r, FGraph.getGraphName(cenv_2));

        // chain the redeclares
        mod = InstUtil.chainRedeclares(mods, mod);

        // elab the modifiers in the parent environment!
        (parentEnv, _) = FGraph.stripLastScopeRef(env);
        (cache,mod_1) = Mod.elabMod(cache, parentEnv, ih, pre, mod, impl, Mod.DERIVED(cn), info);
        mods_1 = Mod.merge(mods, mod_1, className);

        eq = Mod.modEquation(mods_1) "instantiate array dimensions";
        (cache,dims) = InstUtil.elabArraydimOpt(cache, parentEnv, Absyn.CREF_IDENT("",{}), cn, ad, eq, impl, true, pre, info, inst_dims) "owncref not valid here" ;
        // inst_dims2 = InstUtil.instDimExpLst(dims, impl);
        inst_dims_1 = List.appendLastList(inst_dims, dims);

        _ = AbsynUtil.getArrayDimOptAsList(ad);
        (cache,env_2,ih,store,dae,csets_1,ci_state_1,vars,bc,oDA,eqConstraint,graph) = instClassIn(cache, cenv_2, ih, store, mods_1, pre, new_ci_state, c, vis,
          inst_dims_1, impl, callscope, graph, inSets, instSingleCref) "instantiate class in opened scope. " ;

        ClassInf.assertValid(ci_state_1, re, info) "Check for restriction violations" ;
        oDA = SCodeUtil.mergeAttributes(DA,oDA);
      then
        (cache,env_2,ih,store,dae,csets_1,ci_state_1,vars,bc,oDA,eqConstraint,graph);

    // This rule describes how to instantiate a derived class definition without array dims
    case (cache,env,ih,store,mods,pre,ci_state,_,
          SCode.DERIVED(typeSpec = Absyn.TPATH(path = cn,arrayDim = ad), modifications = mod, attributes=DA),
          re,vis,partialPrefix,encapsulatedPrefix,inst_dims,impl,callscope,graph,_,_,_,_,_)
      equation
        false = Mutable.access(stopInst);
        false = valueEq(re, SCode.R_TYPE());
        false = valueEq(re, SCode.R_ENUMERATION());
        false = valueEq(re, SCode.R_PREDEFINED_ENUMERATION());
        false = SCodeUtil.isConnector(re);
        // check empty array dimensions
        true = boolOr(valueEq(ad, NONE()), valueEq(ad, SOME({})));
        (cache,SCode.CLASS(name=cn2,restriction=r,classDef=classDefParent),parentClassEnv) = Lookup.lookupClass(cache, env, cn, SOME(info));

        false = InstUtil.checkDerivedRestriction(re, r, cn2);

        if match r
            case SCode.Restriction.R_PACKAGE() then false;
            else if SCodeUtil.restrictionEqual(r,re) then Mod.isInvariantMod(mod) and Mod.isInvariantDAEMod(mods) else false;
          end match then
          // Is a very simple modification on an operator record; we do not need to handle it by adding SCode.EXTENDS
          // print("Short-circuit: " + SCodeDump.restrString(r)+" "+SCodeDump.restrString(re)+" : "+SCodeDump.printModStr(mod)+"\n");

          // TODO: Is this safe in more cases?

          // chain the redeclares
          mod = InstUtil.chainRedeclares(mods, mod);

          // elab the modifiers in the parent environment!!
          (parentEnv,_) = FGraph.stripLastScopeRef(env);
          // adrpo: as we do this IN THE SAME ENVIRONMENT (no open scope), clone it before doing changes
          // env = FGraph.pushScopeRef(parentEnv, FNode.copyRefNoUpdate(lastRef));
          (cache, mod_1) = Mod.elabMod(cache, parentEnv, ih, pre, mod, false, Mod.DERIVED(cn), info);
          // print("mods: " + AbsynUtil.pathString(cn) + " " + Mod.printModStr(mods_1) + "\n");
          mods_1 = Mod.merge(mods, mod_1, className);

          (cache, env, ih, store, dae, csets, ci_state, vars, bc, oDA, eqConstraint, graph) =
          instClassdef2(cache, parentClassEnv, ih, store, mods_1, pre, ci_state, className, classDefParent,
             re /* = r */,
             vis, partialPrefix, encapsulatedPrefix, // TODO: Do we need to merge these?
             inst_dims, impl,
             callscope, graph, inSets, instSingleCref,comment,info,stopInst);
          oDA = SCodeUtil.mergeAttributes(DA,oDA);

        else
          // chain the redeclares
          mod = InstUtil.chainRedeclares(mods, mod);

          // elab the modifiers in the parent environment!!
          (parentEnv,_) = FGraph.stripLastScopeRef(env);
          // adrpo: as we do this IN THE SAME ENVIRONMENT (no open scope), clone it before doing changes
          // env = FGraph.pushScopeRef(parentEnv, FNode.copyRefNoUpdate(lastRef));
          (cache, mod_1) = Mod.elabMod(cache, parentEnv, ih, pre, mod, false, Mod.DERIVED(cn), info);
          // print("mods: " + AbsynUtil.pathString(cn) + " " + Mod.printModStr(mods_1) + "\n");
          mods_1 = Mod.merge(mods, mod_1, className);

          (cache, env, ih, store, dae, csets, ci_state, vars, bc, oDA, eqConstraint, graph) =
          instClassdef2(cache, env, ih, store, mods_1, pre, ci_state, className,
             SCode.PARTS({SCode.EXTENDS(cn, vis, SCode.NOMOD(), NONE(), info)},{},{},{},{},{},{},NONE()),
             re, vis, partialPrefix, encapsulatedPrefix, inst_dims, impl,
             callscope, graph, inSets, instSingleCref,comment,info,stopInst);
          oDA = SCodeUtil.mergeAttributes(DA,oDA);
        end if;
      then
        (cache,env,ih,store,dae,csets,ci_state,vars,bc,oDA,eqConstraint,graph);

    // This rule describes how to instantiate a derived class definition with array dims
    case (cache,env,ih,store,mods,pre,ci_state,_,
          SCode.DERIVED(typeSpec=Absyn.TPATH(path = cn,arrayDim = ad),modifications = mod,attributes=DA),
          re,vis,_,_,inst_dims,impl,callscope,graph,_,_,_,_,_)
      equation
        false = Mutable.access(stopInst);
        (cache,(c as SCode.CLASS(name=cn2,encapsulatedPrefix=enc2,restriction=r)),cenv) = Lookup.lookupClass(cache, env, cn, SOME(info));

        // not a basic type, change class name!
        false = InstUtil.checkDerivedRestriction(re, r, cn2);

        cenv_2 = FGraph.openScope(cenv, enc2, className, FGraph.classInfToScopeType(ci_state));
        new_ci_state = ClassInf.start(r, FGraph.getGraphName(cenv_2));

        c = SCodeUtil.setClassName(className, c);
        // chain the redeclares
        mod = InstUtil.chainRedeclares(mods, mod);
        // elab the modifiers in the parent environment!
        (parentEnv, _) = FGraph.stripLastScopeRef(env);
        (cache,mod_1) = Mod.elabMod(cache, parentEnv, ih, pre, mod, impl, Mod.DERIVED(cn), info);
        mods_1 = Mod.merge(mods, mod_1, className);
        eq = Mod.modEquation(mods_1) "instantiate array dimensions" ;
        (cache,dims) = InstUtil.elabArraydimOpt(cache, parentEnv, Absyn.CREF_IDENT("",{}), cn, ad, eq, impl, true, pre, info, inst_dims) "owncref not valid here" ;
        inst_dims_1 = List.appendLastList(inst_dims, dims);
        (cache,env_2,ih,store,dae,csets_1,ci_state_1,vars,bc,oDA,eqConstraint,graph) = instClassIn(cache, cenv_2, ih, store, mods_1, pre, new_ci_state, c, vis, inst_dims_1, impl, callscope, graph, inSets, instSingleCref) "instantiate class in opened scope. " ;
        ClassInf.assertValid(ci_state_1, re, info) "Check for restriction violations" ;
        oDA = SCodeUtil.mergeAttributes(DA,oDA);
      then
        (cache,env_2,ih,store,dae,csets_1,ci_state_1,vars,bc,oDA,eqConstraint,graph);

    // MetaModelica extension
    case (_,_,_,_,mods,_,_,_,
          SCode.DERIVED(typeSpec=Absyn.TCOMPLEX(),modifications = mod),
          _,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        false = Mod.emptyModOrEquality(mods) and SCodeUtil.emptyModOrEquality(mod);
        Error.addSourceMessage(Error.META_COMPLEX_TYPE_MOD, {}, info);
      then fail();

    case (cache,env,ih,store,mods,pre,_,_,
          SCode.DERIVED(typeSpec=Absyn.TCOMPLEX(Absyn.IDENT("list"),{tSpec},NONE()),modifications = mod, attributes=DA),
          _,_,_,_,inst_dims,impl,_,graph,_,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        false = Mutable.access(stopInst);
        true = Mod.emptyModOrEquality(mods) and SCodeUtil.emptyModOrEquality(mod);
        (cache,_,ih,tys,csets,oDA) =
        instClassDefHelper(cache,env,ih,{tSpec},pre,inst_dims,impl,{}, inSets,info);
        ty = listHead(tys);
        ty = Types.boxIfUnboxedType(ty);
        bc = SOME(DAE.T_METALIST(ty));
        oDA = SCodeUtil.mergeAttributes(DA,oDA);
      then (cache,env,ih,store,DAE.emptyDae,csets,ClassInf.META_LIST(Absyn.IDENT("")),{},bc,oDA,NONE(),graph);

    case (cache,env,ih,store,mods,pre,_,_,
          SCode.DERIVED(typeSpec=Absyn.TCOMPLEX(Absyn.IDENT("Option"),{tSpec},NONE()),modifications = mod, attributes=DA),
          _,_,_,_,inst_dims,impl,_,graph,_,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        false = Mutable.access(stopInst);
        true = Mod.emptyModOrEquality(mods) and SCodeUtil.emptyModOrEquality(mod);
        (cache,_,ih,{ty},csets,oDA) =
        instClassDefHelper(cache,env,ih,{tSpec},pre,inst_dims,impl,{}, inSets,info);
        ty = Types.boxIfUnboxedType(ty);
        bc = SOME(DAE.T_METAOPTION(ty));
        oDA = SCodeUtil.mergeAttributes(DA,oDA);
      then (cache,env,ih,store,DAE.emptyDae,csets,ClassInf.META_OPTION(Absyn.IDENT("")),{},bc,oDA,NONE(),graph);

    case (cache,env,ih,store,mods,pre,_,_,
          SCode.DERIVED(typeSpec=Absyn.TCOMPLEX(Absyn.IDENT("tuple"),tSpecs,NONE()),modifications = mod, attributes=DA),
          _,_,_,_,inst_dims,impl,_,graph,_,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        false = Mutable.access(stopInst);
        true = Mod.emptyModOrEquality(mods) and SCodeUtil.emptyModOrEquality(mod);
        (cache,_,ih,tys,csets,oDA) = instClassDefHelper(cache,env,ih,tSpecs,pre,inst_dims,impl,{}, inSets,info);
        tys = List.map(tys, Types.boxIfUnboxedType);
        bc = SOME(DAE.T_METATUPLE(tys));
        oDA = SCodeUtil.mergeAttributes(DA,oDA);
      then (cache,env,ih,store,DAE.emptyDae,csets,ClassInf.META_TUPLE(Absyn.IDENT("")),{},bc,oDA,NONE(),graph);

    case (cache,env,ih,store,mods,pre,_,_,
          SCode.DERIVED(typeSpec=Absyn.TCOMPLEX(Absyn.IDENT("array"),{tSpec},NONE()),modifications = mod, attributes=DA),
          _,_,_,_,inst_dims,impl,_,graph,_,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        false = Mutable.access(stopInst);
        true = Mod.emptyModOrEquality(mods) and SCodeUtil.emptyModOrEquality(mod);
        (cache,_,ih,{ty},csets,oDA) = instClassDefHelper(cache,env,ih,{tSpec},pre,inst_dims,impl,{}, inSets,info);
        ty = Types.boxIfUnboxedType(ty);
        bc = SOME(DAE.T_METAARRAY(ty));
        oDA = SCodeUtil.mergeAttributes(DA,oDA);
      then (cache,env,ih,store,DAE.emptyDae,csets,ClassInf.META_ARRAY(Absyn.IDENT(className)),{},bc,oDA,NONE(),graph);

    case (cache,env,ih,store,mods,pre,_,_,
          SCode.DERIVED(typeSpec=Absyn.TCOMPLEX(Absyn.IDENT("polymorphic"),{Absyn.TPATH(Absyn.IDENT("Any"),NONE())},NONE()),modifications = mod, attributes=DA),
          _,_,_,_,inst_dims,impl,_,graph,_,_,_,_,_)
      equation
        // true = Config.acceptMetaModelicaGrammar(); // We use this for builtins also
        false = Mutable.access(stopInst);
        true = Mod.emptyModOrEquality(mods) and SCodeUtil.emptyModOrEquality(mod);
        (cache,_,ih,_,csets,oDA) = instClassDefHelper(cache,env,ih,{},pre,inst_dims,impl,{}, inSets,info);
        bc = SOME(DAE.T_METAPOLYMORPHIC(className));
        oDA = SCodeUtil.mergeAttributes(DA,oDA);
      then (cache,env,ih,store,DAE.emptyDae,csets,ClassInf.META_POLYMORPHIC(Absyn.IDENT(className)),{},bc,oDA,NONE(),graph);

    case (_,_,_,_,mods,_,_,_,
          SCode.DERIVED(typeSpec=Absyn.TCOMPLEX(path=Absyn.IDENT("polymorphic")),modifications=mod),
          _,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // true = Config.acceptMetaModelicaGrammar(); // We use this for builtins also
        true = Mod.emptyModOrEquality(mods) and SCodeUtil.emptyModOrEquality(mod);
        Error.addSourceMessage(Error.META_POLYMORPHIC, {className}, info);
      then fail();

    case (cache,env,ih,store,mods,pre,ci_state,_,
          SCode.DERIVED(typeSpec=Absyn.TCOMPLEX(Absyn.IDENT(str),tSpecs,NONE()),modifications = mod, attributes=DA),
          re,vis,partialPrefix,encapsulatedPrefix,inst_dims,impl,_,graph,_,_,_,_,_)
      equation
        str = Util.assoc(str,{("List","list"),("Tuple","tuple"),("Array","array")});
        (outCache,outEnv,outIH,outStore,outDae,outSets,outState,outTypesVarLst,oty,optDerAttr,outEqualityConstraint,outGraph)
        = instClassdef2(cache,env,ih,store,mods,pre,ci_state,className,SCode.DERIVED(Absyn.TCOMPLEX(Absyn.IDENT(str),tSpecs,NONE()),mod,DA),re,vis,partialPrefix,encapsulatedPrefix,inst_dims,impl,inCallingScope,graph,inSets,instSingleCref,comment,info,stopInst);
      then (outCache,outEnv,outIH,outStore,outDae,outSets,outState,outTypesVarLst,oty,optDerAttr,outEqualityConstraint,outGraph);

    case (cache,env,ih,store,mods,pre,_,_,
          SCode.DERIVED(typeSpec=Absyn.TCOMPLEX(cn,tSpecs,NONE()),modifications = mod, attributes=DA),
          _,_,_,_,inst_dims,impl,_,graph,_,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        false = Mutable.access(stopInst);
        true = Mod.emptyModOrEquality(mods) and SCodeUtil.emptyModOrEquality(mod);
        false = listMember(AbsynUtil.pathString(cn), {"tuple","Tuple","array","Array","Option","list","List"});
        (cache,(SCode.CLASS(name=cn2,restriction=SCode.R_UNIONTYPE(typeVars=typeVars),classDef=classDef)),cenv) = Lookup.lookupClass(cache, env, cn, SOME(info));
        (cache,fq_class) = makeFullyQualifiedIdent(cache,cenv,cn2);
        new_ci_state = ClassInf.META_UNIONTYPE(fq_class, typeVars);
        (cache,SOME(ty as DAE.T_METAUNIONTYPE())) = InstMeta.fixUniontype(cache, env, new_ci_state, classDef);
        (cache,_,ih,tys,csets,oDA) = instClassDefHelper(cache,env,ih,tSpecs,pre,inst_dims,impl,{}, inSets,info);
        tys = list(Types.boxIfUnboxedType(t) for t in tys);
        if not (listLength(tys)==listLength(typeVars)) then
          Error.addSourceMessage(Error.UNIONTYPE_WRONG_NUM_TYPEVARS,{AbsynUtil.pathString(fq_class),String(listLength(typeVars)),String(listLength(tys))},info);
          fail();
        end if;
        ty = Types.setTypeVariables(ty, tys);
        oDA = SCodeUtil.mergeAttributes(DA,oDA);
        bc = SOME(ty);
      then (cache,env,ih,store,DAE.emptyDae,csets,new_ci_state,{},bc,oDA,NONE(),graph);

    case (_,_,_,_,_,_,_,_,
          SCode.DERIVED(typeSpec=tSpec as Absyn.TCOMPLEX(arrayDim=SOME(_))),
          _,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        cns = Dump.unparseTypeSpec(tSpec);
        Error.addSourceMessage(Error.META_INVALID_COMPLEX_TYPE, {cns}, info);
      then fail();

    case (_,_,_,_,_,_,_,_,
          SCode.DERIVED(typeSpec=tSpec as Absyn.TCOMPLEX(path=cn,typeSpecs=tSpecs)),
          _,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        false = listMember((AbsynUtil.pathString(cn),listLength(tSpecs)==1), {("tuple",false),("array",true),("Option",true),("list",true)});
        cns = Dump.unparseTypeSpec(tSpec);
        Error.addSourceMessage(Error.META_INVALID_COMPLEX_TYPE, {cns}, info);
      then fail();

    /* ----------------------- */

    /* If the class is derived from a class that can not be found in the environment, this rule prints an error message. */
    case (cache,env,_,_,_,_,_,_,
          SCode.DERIVED(Absyn.TPATH(path = cn)),
          _,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        false = Mutable.access(stopInst);
        failure((_,_,_) = Lookup.lookupClass(cache,env, cn));
        cns = AbsynUtil.pathString(cn);
        scope_str = FGraph.printGraphPathStr(env);
        Error.addSourceMessage(Error.LOOKUP_ERROR, {cns,scope_str}, info);
      then
        fail();

    case (cache,env,_,_,_,_,_,_,
          SCode.DERIVED(Absyn.TPATH(path = cn)),
          _,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        failure((_,_,_) = Lookup.lookupClass(cache,env, cn));
        Debug.trace("- Inst.instClassdef DERIVED( ");
        Debug.trace(AbsynUtil.pathString(cn));
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
    else listAppend(inEq, inExtEq);
  end match;
end joinExtEquations;

protected function joinExtAlgorithms
  input list<SCode.AlgorithmSection> inAlg;
  input list<SCode.AlgorithmSection> inExtAlg;
  input InstTypes.CallingScope inCallingScope;
  output list<SCode.AlgorithmSection> outAlg;
algorithm
  outAlg := match inCallingScope
    case InstTypes.TYPE_CALL() then {};
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
  input DAE.Prefix inPre;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean inImpl;
  input list<DAE.Type> accTypes;
  input Connect.Sets inSets;
  input SourceInfo inInfo;
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
      DAE.Prefix pre;
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
        (cache,(c as SCode.CLASS()),cenv) = Lookup.lookupClass(cache,env, cn, SOME(inInfo));
        false = SCodeUtil.isFunction(c);
        (cache,cenv,ih,_,_,csets,ty,_,oDA,_)=instClass(cache,cenv,ih,UnitAbsyn.noStore,DAE.NOMOD(),pre,c,dims,impl,InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, inSets);
        localAccTypes = ty::localAccTypes;
        (cache,env,ih,localAccTypes,csets,_) =
        instClassDefHelper(cache,env,ih,restTypeSpecs,pre,dims,impl,localAccTypes, csets,inInfo);
      then (cache,env,ih,localAccTypes,csets,oDA);

    case (cache,env,ih, Absyn.TPATH(cn,_) :: restTypeSpecs,pre,dims,impl,localAccTypes,_)
      equation
        (cache,ty,_) = Lookup.lookupType(cache,env,cn,NONE()) "For functions, etc";
        localAccTypes = ty::localAccTypes;
        (cache,env,ih,localAccTypes,csets,_) =
        instClassDefHelper(cache,env,ih,restTypeSpecs,pre,dims,impl,localAccTypes, inSets,inInfo);
      then (cache,env,ih,localAccTypes,csets,NONE());

    case (cache,env,ih, (tSpec as Absyn.TCOMPLEX(p,_,_)) :: restTypeSpecs,pre,dims,impl,localAccTypes,_)
      equation
        id=AbsynUtil.pathString(p);
        c = SCode.CLASS(id,SCode.defaultPrefixes,
                        SCode.NOT_ENCAPSULATED(),
                        SCode.NOT_PARTIAL(),
                        SCode.R_TYPE(),
                        SCode.DERIVED(
                          tSpec,SCode.NOMOD(),
                          SCode.ATTR({}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(), Absyn.BIDIR(), Absyn.NONFIELD())),
                        SCode.noComment,
                        AbsynUtil.dummyInfo);
        (cache,_,ih,_,_,csets,ty,_,oDA,_)=instClass(cache,env,ih,UnitAbsyn.noStore,DAE.NOMOD(),pre,c,dims,impl,InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, inSets);
        localAccTypes = ty::localAccTypes;
        (cache,env,ih,localAccTypes,csets,_) =
        instClassDefHelper(cache,env,ih,restTypeSpecs,pre,dims,impl,localAccTypes, csets,inInfo);
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
  input Mutable<Boolean> stopInst "prevent instantiation of classes adding components to primary types";
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
        //Debug.traceln("Try instbasic 1 " + AbsynUtil.pathString(path));
        ErrorExt.setCheckpoint("instBasictypeBaseclass");
        (cache,m_1) = Mod.elabModForBasicType(cache, env, ih, DAE.NOPRE(), mod, true, Mod.DERIVED(path), info);
        m_2 = Mod.merge(mods, m_1, className);
        (cache,cdef,cenv) = Lookup.lookupClass(cache,env, path, SOME(info));
        //Debug.traceln("Try instbasic 2 " + AbsynUtil.pathString(path) + " " + Mod.printModStr(m_2));
        (cache,_,ih,store,dae,_,ty,tys,_) =
        instClassBasictype(cache,cenv,ih, store,m_2, DAE.NOPRE(), cdef, inst_dims, false, InstTypes.INNER_CALL(), Connect.emptySet);
        //Debug.traceln("Try instbasic 3 " + AbsynUtil.pathString(path) + " " + Mod.printModStr(m_2));
        b1 = Types.basicType(ty);
        b2 = Types.arrayType(ty);
        b3 = Types.extendsBasicType(ty);
        true = boolOr(b1, boolOr(b2, b3));

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
      n = AbsynUtil.pathString(p);
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
  input SourceInfo inInfo;
  input Mutable<Boolean> stopInst "prevent instantiation of classes adding components to primary types";
algorithm
  _ := matchcontinue(inCache,inEnv1,inIH,store,inSCodeElementLst2,inSCodeElementLst3,inMod4,inInstDims5,className,stopInst)
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
      SourceInfo info;

    case (cache,env,ih,_,{SCode.EXTENDS(baseClassPath = path,modifications = mod, info = info)},(_ :: _),_,inst_dims,_,_) /* Inherits baseclass -and- has components */
      equation
        (cache,m_1) = Mod.elabModForBasicType(cache, env, ih, DAE.NOPRE(), mod, true, Mod.DERIVED(path), inInfo);
        (cache,cdef,cenv) = Lookup.lookupClass(cache,env, path, SOME(info));
        cdef_1 = SCodeUtil.classSetPartial(cdef, SCode.NOT_PARTIAL());

        (cache,_,ih,_,_,_,ty,_,_,_) = instClass(cache,cenv,ih,store, m_1,
          DAE.NOPRE(), cdef_1, inst_dims, false, InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, Connect.emptySet) "impl" ;

        b1 = Types.basicType(ty);
        b2 = Types.arrayType(ty);
        true = boolOr(b1, b2);
        classname = FGraph.printGraphPathStr(env);
        ErrorExt.rollBack("instBasictypeBaseclass2");
        Error.addSourceMessage(Error.INHERIT_BASIC_WITH_COMPS, {classname}, inInfo);
        Mutable.update(stopInst,true);
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
  "This function is used by partialInstClassIn for instantiating local class
   definitions and inherited class definitions only."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input DAE.Prefix inPrefix;
  input ClassInf.State inState;
  input SCode.Element inClass "The class this definition comes from.";
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
  (outCache, outEnv, outIH, outState, outVars) := match inClassDef
    local
      SCode.Partial partial_prefix;
      String class_name, scope_str;
      list<SCode.Element> cdef_els, class_ext_els, extends_els;
      DAE.Mod emods, mod;
      SCode.Mod class_mod, smod;
      list<tuple<SCode.Element, DAE.Mod>> ext_comps, const_els;
      Absyn.Path class_path;
      Option<list<Absyn.Subscript>> class_dims;
      SCode.Element cls;
      SCode.ClassDef cdef;
      FCore.Graph cenv, parent_env;
      SCode.Restriction der_re, parent_re;
      SCode.Encapsulated enc;
      SourceInfo info;
      Option<DAE.EqMod> eq;
      list<DAE.Dimension> dims = {};
      Boolean has_dims, is_basic_type;
      InstDims inst_dims;
      Option<FCore.ScopeType> scope_ty;

    case SCode.PARTS()
      algorithm
        partial_prefix := SCodeUtil.getClassPartialPrefix(inClass);
        partial_prefix := InstUtil.isPartial(partial_prefix, inMod);
        class_name := SCodeUtil.elementName(inClass);
        outState := ClassInf.trans(inState, ClassInf.NEWDEF());

        (cdef_els, class_ext_els, extends_els) := InstUtil.splitElts(inClassDef.elementLst);
        extends_els := SCodeInstUtil.addRedeclareAsElementsToExtends(extends_els,
          List.select(inClassDef.elementLst, SCodeUtil.isRedeclareElement));

        // Classes and imports are added to env.
        (outCache, outEnv, outIH) := InstUtil.addClassdefsToEnv(inCache, inEnv,
          inIH, inPrefix, cdef_els, true, SOME(inMod), FGraph.isEmptyScope(inEnv));
        // Inherited elements are added to env.
        (outCache, outEnv, outIH, emods, ext_comps) := InstExtends.instExtendsAndClassExtendsList(
          outCache, outEnv, outIH, inMod, inPrefix, extends_els, class_ext_els,
          inClassDef.elementLst, inState, class_name, true, true);

        // If we partially instantiate a partial package, we filter out
        // constants (maybe we should also filter out functions) /sjoelund
        const_els := listAppend(ext_comps,
          InstUtil.addNomod(InstUtil.constantEls(inClassDef.elementLst)));

        // Since partial instantiation is done in lookup, we need to add
        // inherited classes here.  Otherwise when looking up e.g. A.B where A
        // inherits the definition of B, and without having a base class context
        // (since we do not have any element to find it in), the class must be
        // added to the environment here.

        mod := Mod.merge(inMod, emods, class_name);

        (cdef_els, ext_comps) := InstUtil.classdefElts2(ext_comps, partial_prefix);
        (outCache, outEnv, outIH) := InstUtil.addClassdefsToEnv(outCache,
          outEnv, outIH, inPrefix, cdef_els, true, SOME(mod));

        // Add inherited classes to env.
        (outCache, outEnv, outIH) := InstUtil.addComponentsToEnv(outCache,
          outEnv, outIH, mod, inPrefix, inState, const_els, false);

        // Instantiate constants.
        (outCache, outEnv, outIH, _, _, _, outState, outVars, _, _) := instElementList(
          outCache, outEnv, outIH, UnitAbsyn.noStore, mod, inPrefix, outState,
          const_els, inInstDims, true, InstTypes.INNER_CALL(),
          ConnectionGraph.EMPTY, Connect.emptySet, false);
      then
        (outCache, outEnv, outIH, outState, outVars);

    case SCode.DERIVED(typeSpec = Absyn.TPATH(path = class_path, arrayDim = class_dims),
                       modifications = class_mod)
      algorithm
        info := SCodeUtil.elementInfo(inClass);
        has_dims := not (isNone(class_dims) or valueEq(class_dims, SOME({})));

        try
          (outCache, cls as SCode.CLASS(), cenv) :=
            Lookup.lookupClass(inCache, inEnv, class_path, SOME(info));
        else
          class_name := AbsynUtil.pathString(class_path);
          scope_str := FGraph.printGraphPathStr(inEnv);
          Error.addSourceMessageAndFail(Error.LOOKUP_ERROR, {class_name, scope_str}, info);
        end try;

        SCode.CLASS(name = class_name, encapsulatedPrefix = enc, restriction = der_re) := cls;
        parent_re := SCodeUtil.getClassRestriction(inClass);
        is_basic_type := InstUtil.checkDerivedRestriction(parent_re, der_re, class_name);

        smod := InstUtil.chainRedeclares(inMod, class_mod);

        // The mod is elaborated in the parent of this class.
        parent_env := FGraph.stripLastScopeRef(inEnv);
        (outCache, mod) := Mod.elabMod(outCache, parent_env, inIH, inPrefix,
          smod, false, Mod.DERIVED(class_path), info);
        mod := Mod.merge(inMod, mod, class_name);

        if has_dims and not is_basic_type then
          cls := SCodeUtil.setClassName(class_name, cls);
          eq := Mod.modEquation(mod);
          (outCache, dims) := InstUtil.elabArraydimOpt(outCache, parent_env,
            Absyn.CREF_IDENT("", {}), class_path, class_dims, eq, false,
            true, inPrefix, info, inInstDims);
          inst_dims := List.appendLastList(inInstDims, dims);
        else
          inst_dims := inInstDims;
        end if;

        if is_basic_type or has_dims then
          scope_ty := if is_basic_type then FGraph.restrictionToScopeType(der_re) else
                                            FGraph.classInfToScopeType(inState);
          cenv := FGraph.openScope(cenv, enc, class_name, scope_ty);
          outState := ClassInf.start(der_re, FGraph.getGraphName(cenv));
          (outCache, outEnv, outIH, outState, outVars) :=
            partialInstClassIn(outCache, cenv, inIH, mod, inPrefix, outState, cls,
              inVisibility, inst_dims, numIter);
        else
          cdef := SCode.PARTS({SCode.EXTENDS(class_path, inVisibility,
            SCode.NOMOD(), NONE(), info)}, {}, {}, {}, {}, {}, {}, NONE());
          (outCache, outEnv, outIH, outState, outVars) :=
            partialInstClassdef(outCache, inEnv, inIH, mod, inPrefix, inState,
              inClass, cdef, inVisibility, inInstDims, numIter);
        end if;

        if SCodeUtil.isPartial(cls) then
          outEnv := FGraph.makeScopePartial(inEnv);
        end if;
      then
        (outCache, outEnv, outIH, outState, outVars);

  end match;
end partialInstClassdef;

public function instElementList
  "Instantiates a list of elements."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input DAE.Mod inMod;
  input DAE.Prefix inPrefix;
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
  //output List<tuple<Absyn.ComponentRef,DAE.ComponentRef>> fieldDomLst = {};
  output InstUtil.DomainFieldsLst domainFieldsListOut = {};
protected
  list<tuple<SCode.Element, DAE.Mod>> el;
  FCore.Cache cache;
  list<DAE.Var> vars;
  list<DAE.Element> dae;
  list<list<DAE.Var>> varsl = {};
  list<list<DAE.Element>> dael = {};
  InstUtil.DomainFieldOpt fieldDomOpt;
  list<Integer> element_order;
  array<tuple<SCode.Element, DAE.Mod>> el_arr;
  array<list<DAE.Var>> var_arr;
  array<list<DAE.Element>> dae_arr;
  Integer length;
algorithm
  cache := InstUtil.pushStructuralParameters(inCache);

  // Sort elements based on their dependencies. This is not done for MetaModelica
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
    length := listLength(el);
    var_arr := arrayCreate(length, {});
    dae_arr := arrayCreate(length, {});

    // Instantiate the elements.
    for idx in element_order loop
      (cache, outEnv, outIH, outStore, dae, outSets, outState, vars, outGraph, fieldDomOpt) :=
        instElement2(cache, outEnv, outIH, outStore, inMod, inPrefix, outState, el_arr[idx],
          inInstDims, inImplInst, inCallingScope, outGraph, outSets, inStopOnError);
      // Store the elements in reverse order to make the list flattening simpler
      arrayUpdate(var_arr, length-idx+1, vars);
      arrayUpdate(dae_arr, length-idx+1, dae);
      if intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.PDEMODELICA) then
        domainFieldsListOut := InstUtil.optAppendField(domainFieldsListOut,fieldDomOpt);
      end if;
    end for;

    outVars := listAppend(lst for lst in var_arr);
    outDae := DAE.DAE(listAppend(lst for lst in dae_arr));
    GC.free(var_arr);
    GC.free(dae_arr);
  else
    // For functions, use the sorted elements instead, otherwise things break.
    for e in el loop
      (cache, outEnv, outIH, outStore, dae, outSets, outState, vars, outGraph, fieldDomOpt) :=
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
  output Boolean outEqual = SCodeUtil.elementNameEqual(inElement1, Util.tuple21(inElement2));
end getSortedElementOrdering_comp;

public function instElement2
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input DAE.Mod inMod;
  input DAE.Prefix inPrefix;
  input ClassInf.State inState;
  input tuple<SCode.Element, DAE.Mod> inElement;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean inImplicit;
  input InstTypes.CallingScope inCallingScope;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  input Boolean inStopOnError;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH = inIH;
  output UnitAbsyn.InstStore outStore = inStore;
  output list<DAE.Element> outDae = {};
  output Connect.Sets outSets = inSets;
  output ClassInf.State outState = inState;
  output list<DAE.Var> outVars = {};
  output ConnectionGraph.ConnectionGraph outGraph = inGraph;
  output InstUtil.DomainFieldOpt outFieldDomOpt = NONE();
protected
  tuple<SCode.Element, DAE.Mod> elt;
  Boolean is_deleted;
algorithm
  // Check if the component has a conditional expression that evaluates to false.
  (is_deleted, outEnv, outCache) := isDeletedComponent(inElement, inPrefix,
      inStopOnError, inEnv, inCache);

  // Skip the component if it was deleted by a conditional expression.
  if is_deleted then
    return;
  end if;

  try // Try to instantiate the element.
    ErrorExt.setCheckpoint("instElement2");
    (outCache, outEnv, outIH, {elt}) := updateCompeltsMods(inCache, outEnv,
      outIH, inPrefix, {inElement}, outState, inImplicit);
    (outCache, outEnv, outIH, outStore, DAE.DAE(outDae), outSets, outState, outVars, outGraph, outFieldDomOpt) :=
      instElement(outCache, outEnv, outIH, outStore, inMod, inPrefix, outState, elt, inInstDims,
        inImplicit, inCallingScope, outGraph, inSets);
    Error.clearCurrentComponent();
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
  input tuple<SCode.Element, DAE.Mod> element;
  input DAE.Prefix prefix;
  input Boolean stopOnError;
        output Boolean isDeleted;
  input output FCore.Graph env;
  input output FCore.Cache cache;
protected
  SCode.Element el;
  String el_name;
  SourceInfo info;
  Option<Boolean> cond_val_opt;
  Boolean cond_val;
  DAE.Var var;
algorithm
  // If the element has a conditional expression, try to evaluate it.
  if InstUtil.componentHasCondition(element) then
    (el, _) := element;
    (el_name, info) := InstUtil.extractCurrentName(el);

    // An element redeclare may not have a condition.
    if SCodeUtil.isElementRedeclare(el) then
      Error.addSourceMessage(Error.REDECLARE_CONDITION, {el_name}, info);
      fail();
    end if;

    (cond_val_opt, cache) :=
      InstUtil.instElementCondExp(cache, env, el, prefix, info);

    // If a conditional expression was present but couldn't be instantiatied, stop.
    if isNone(cond_val_opt) then
      if stopOnError then // We should stop instantiation completely, fail.
        fail();
      else  // We should continue instantiation, pretend that it was deleted.
        isDeleted := false;
        return;
      end if;
    end if;

    // If we succeeded, check if the condition is true or false.
    SOME(cond_val) := cond_val_opt;
    isDeleted := not cond_val;

    // The component was deleted, update its status in the environment so we can
    // look it up when instantiating connections.
    if isDeleted == true then
      var := DAE.TYPES_VAR(el_name, DAE.dummyAttrVar, DAE.T_UNKNOWN_DEFAULT, DAE.UNBOUND(), false, NONE());
      env := FGraph.updateComp(env, var, FCore.VAR_DELETED(), FGraph.emptyGraph);
    end if;
  else
    isDeleted := false;
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
  input DAE.Prefix inPrefix;
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
  output InstUtil.DomainFieldOpt outFieldDomOpt = NONE();
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
      DAE.Prefix pre;
      SCode.Attributes attr;
      SCode.Element cls, comp, comp2, el;
      SCode.Final final_prefix;
      SCode.ConnectorType ct;
      SCode.Mod m,oldmod;
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
      Option<DAE.ComponentRef> domainCROpt;


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
        m = SCodeUtil.mergeModifiers(m, SCodeUtil.getConstrainedByModifiers(prefixes));

        if SCodeUtil.finalBool(final_prefix) then
          m = InstUtil.traverseModAddFinal(m);
        end if;
        comp = if referenceEq(el.modifications, m) then el else SCode.COMPONENT(name, prefixes, attr, ts, m, comment, cond, info);
        oldmod = m;

        // Fails if multiple decls not identical
        already_declared = InstUtil.checkMultiplyDeclared(cache, env, mods, pre, ci_state, (comp, cmod), inst_dims, impl);

        // chain the redeclares AFTER checking of elements identical
        // if we have an outer modification: redeclare X = Y
        // and a component modification redeclare X = Z
        // update the component modification to redeclare X = Y
        m = InstUtil.chainRedeclares(mods, m);
        m = SCodeInstUtil.expandEnumerationMod(m);
        m = InstUtil.traverseModAddDims(cache, env, pre, m, inst_dims);
        comp = if referenceEq(oldmod,m) then comp else SCode.COMPONENT(name, prefixes, attr, ts, m, comment, cond, info);
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

        mod = Mod.merge(mm, class_mod, name);
        mod = Mod.merge(mod, m_1, name, not ClassInf.isRecord(ci_state));
        mod = Mod.merge(cmod, mod, name);

        /* (BZ part:2/2) here we merge the redeclared class modifier.
         * Redeclaration has lowest priority and if we have any local modifiers,
         * they will be used before "global" modifers.
         */
        mod = Mod.merge(mod, var_class_mod, name);

        // fprintln(Flags.INST_TRACE, "INST ELEMENT: name: " + name + " mod: " + Mod.printModStr(mod));

        // Apply redeclaration modifier to component
        (cache, env2, ih, SCode.COMPONENT(name,
          prefixes as SCode.PREFIXES(innerOuter = io),
          attr as SCode.ATTR(arrayDims = ad, direction = dir),
          Absyn.TPATH(t, _), _, comment, _, _), mod_1)
          = redeclareType(cache, env2, ih, mod, comp, pre, ci_state, impl, DAE.NOMOD());

        (cache, cls, cenv) = Lookup.lookupClass(cache, env2 /* env */, t, SOME(info));

        cls_mod = Mod.getClassModifier(cenv, SCodeUtil.className(cls));
        if not Mod.isEmptyMod(cls_mod)
        then
          if not listEmpty(ad) // add each if needed
          then
            cls_mod = Mod.addEachIfNeeded(cls_mod, {DAE.DIM_INTEGER(1)});
          end if;
          mod_1 = Mod.merge(mod_1, cls_mod, name);
        end if;
        attr = SCodeUtil.mergeAttributesFromClass(attr, cls);

        // If the element is protected, and an external modification
        // is applied, it is an error.
        // this does not work as we don't know from where the modification came (component modif or extends modif)
        // checkProt(vis, mm, vn, info);

        //Instantiate the component
        // Start a new "set" of inst_dims for this component (in instance hierarchy), see InstDims
        inst_dims = List.appendElt({}, inst_dims);

        (cache,mod) = Mod.updateMod(cache, env2 /* cenv */, ih, pre, mod, impl, info);
        (cache,mod_1) = Mod.updateMod(cache, env2 /* cenv */, ih, pre, mod_1, impl, info);

        // print("Before InstUtil.selectModifiers:\n\tmod: " + Mod.printModStr(mod) + "\n\t" +"mod_1: " + Mod.printModStr(mod_1) + "\n\t" +"comp: " + SCodeDump.unparseElementStr(comp) + "\n");

        (mod, mod_1) = InstUtil.selectModifiers(mod, mod_1, t);

        // print("After InstUtil.selectModifiers:\n\tmod: " + Mod.printModStr(mod) + "\n\t" +"mod_1: " + Mod.printModStr(mod_1) + "\n");

        eq = Mod.modEquation(mod);
        // The variable declaration and the (optional) equation modification are inspected for array dimensions.
        is_function_input = InstUtil.isFunctionInput(ci_state, dir);
        (cache, dims) = InstUtil.elabArraydim(cache, env2, own_cref, t, ad, eq, impl,
          true, is_function_input, pre, info, inst_dims);

        //PDEModelica:
        if intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.PDEMODELICA) then
          (dims, mod_1, outFieldDomOpt) = InstUtil.elabField(inCache, inEnv, name, attr, dims, mod_1, info);
        end if;

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

        dae_attr = DAEUtil.translateSCodeAttrToDAEAttr(attr, prefixes);
        ty = Types.traverseType(ty, 1, Types.setIsFunctionPointer);

        binding = removePrefixFromBinding(binding, pre);
        new_var = DAE.TYPES_VAR(name, dae_attr, ty, binding, false, NONE());

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
        if SCodeUtil.finalBool(final_prefix) then
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
        id = AbsynUtil.pathString(type_name);

        cls = SCode.CLASS(id, SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(),
          SCode.NOT_PARTIAL(), SCode.R_TYPE(), SCode.DERIVED(ts, SCode.NOMOD(),
          SCode.ATTR(ad, ct, SCode.NON_PARALLEL(), SCode.VAR(), Absyn.BIDIR(), Absyn.NONFIELD())), SCode.noComment, info);

        // The variable declaration and the (optional) equation modification are inspected for array dimensions.
        // Gather all the dimensions
        // (Absyn.IDENT("Integer") is used as a dummy)
        (cache, dims) = InstUtil.elabArraydim(cache, env, own_cref, Absyn.IDENT("Integer"),
          ad, NONE(), impl, true, false, pre, info, inst_dims);

        // Instantiate the component
        (cache, comp_env, ih, store, dae, csets, ty, graph_new) =
          InstVar.instVar(cache, env, ih, store,ci_state, m_1, pre, name, cls, attr,
            prefixes, dims, {}, inst_dims, impl, comment, info, graph, csets, env);

        // print("instElement -> component: " + n + " ty: " + Types.printTypeStr(ty) + "\n");

        // The environment is extended (updated) with the new variable binding.
        (cache, binding) = InstBinding.makeBinding(cache, env, attr, m_1, ty, pre, name, info);

        // true in update_frame means the variable is now instantiated.
        dae_attr = DAEUtil.translateSCodeAttrToDAEAttr(attr, prefixes);
        ty = Types.traverseType(ty, 1, Types.setIsFunctionPointer);
        new_var = DAE.TYPES_VAR(name, dae_attr, ty, binding, false, NONE()) ;

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
        failure((_, _, _) = Lookup.lookupClass(cache, env, t));
        // good for GDB debugging to re-run the instElement again
        // (cache, env, ih, store, dae, csets, ci_state, vars, graph) = instElement(inCache, inEnv, inIH, inUnitStore, inMod, inPrefix, inState, inElement, inInstDims, inImplicit, inCallingScope, inGraph, inSets);
        s = AbsynUtil.pathString(t);
        scope_str = FGraph.printGraphPathStr(env);
        pre = PrefixUtil.prefixAdd(name, {}, {}, pre, vt, ci_state, info);
        ns = PrefixUtil.printPrefixStrIgnoreNoPre(pre);
        Error.addSourceMessage(Error.LOOKUP_ERROR_COMPNAME, {s, scope_str, ns}, info);
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("Lookup class failed:" + AbsynUtil.pathString(t));
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

protected function removePrefixFromBinding
  input DAE.Binding inBind;
  input DAE.Prefix inPrefix;
  output DAE.Binding outBind;
algorithm
  outBind := match (inBind, inPrefix)
    local
      DAE.Binding bind;
      DAE.Prefix pref;

      case (bind as DAE.EQBOUND(), pref as DAE.PREFIX(compPre=DAE.PRE())) algorithm
        bind.exp := PrefixUtil.removeCompPrefixFromExps(bind.exp, pref.compPre);
      then
        bind;

      else inBind;
    end match;
end removePrefixFromBinding;

protected function updateCompeltsMods
"never fail and *NEVER* display any error messages as this function
 prints non-true error messages and even so instElementList dependency
 analysis might work fine and still instantiate."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Prefix inPrefix;
  input list<tuple<SCode.Element, DAE.Mod>> inComponents;
  input ClassInf.State inState;
  input Boolean inImplicit;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output list<tuple<SCode.Element, DAE.Mod>> outComponents;
algorithm
  (outCache,outEnv,outIH,outComponents) :=
  matchcontinue (inCache,inEnv,inIH,inPrefix,inComponents,inState,inImplicit)

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
          updateCompeltsMods_dispatch(inCache,inEnv,inIH,inPrefix,inComponents,inState,inImplicit);
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
  input DAE.Prefix inPrefix;
  input list<tuple<SCode.Element, DAE.Mod>> inComponents;
  input ClassInf.State inState;
  input Boolean inImplicit;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output list<tuple<SCode.Element, DAE.Mod>> outComponents;
algorithm
  (outCache,outEnv,outIH,outComponents):=
  matchcontinue (inCache,inEnv,inIH,inPrefix,inComponents,inState,inImplicit)
    local
      FCore.Graph env,env2,env3;
      DAE.Prefix pre;
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
        name = SCodeUtil.elementName(comp);
        cref = Absyn.CREF_IDENT(name,{});
        (cache,env,ih) = updateComponentsInEnv(cache, env, ih, pre, DAE.NOMOD(), {cref}, ci_state, impl);
        */
        (cache,env,ih,res) = updateCompeltsMods_dispatch(cache, env, ih, pre, xs, ci_state, impl);
      then
        (cache,env,ih,elMod::res);

    // Special case for components being redeclared, we might instantiate partial classes when instantiating var(-> instVar2->instClass) to update component in env.
    case (cache,env,ih,pre,((comp,(cmod as DAE.REDECL(element = redComp))) :: xs),ci_state,impl)
      equation
        info = SCodeUtil.elementInfo(redComp);
        umod = Mod.unelabMod(cmod);
        crefs = InstUtil.getCrefFromMod(umod);
        crefs_1 = InstUtil.getCrefFromCompDim(comp) "get crefs from dimension arguments";
        crefs = List.unionOnTrue(crefs,crefs_1,AbsynUtil.crefEqual);
        name = SCodeUtil.elementName(comp);
        cref = Absyn.CREF_IDENT(name,{});
        ltmod = List.map1(crefs,InstUtil.getModsForDep,xs);
        cmod2 = List.fold2r(cmod::ltmod,Mod.merge,name,true,DAE.NOMOD());
        SCode.PREFIXES(finalPrefix = fprefix) = SCodeUtil.elementPrefixes(comp);

        //print("("+intString(listLength(ltmod))+")UpdateCompeltsMods_(" + stringDelimitList(List.map(crefs,AbsynUtil.printComponentRefStr),",") + ") subs: " + stringDelimitList(List.map(crefs,Absyn.printComponentRefStr),",")+ "\n");
        //print("REDECL     acquired mods: " + Mod.printModStr(cmod2) + "\n");
        (cache,env2,ih) = updateComponentsInEnv(cache, env, ih, pre, cmod2, crefs, ci_state, impl);
        (cache,env2,ih) = updateComponentsInEnv(cache, env2, ih, pre,
          DAE.MOD(fprefix,SCode.NOT_EACH(),{DAE.NAMEMOD(name, cmod)},NONE(),info),
          {cref}, ci_state, impl);
        (cache,cmod_1) = Mod.updateMod(cache, env2, ih, pre, cmod, impl, info);
        (cache,env3,ih,res) = updateCompeltsMods_dispatch(cache, env2, ih, pre, xs, ci_state, impl);
      then
        (cache,env3,ih,((comp,cmod_1) :: res));

    // If the modifier has already been updated, just update the environment with it.
    case (cache,env,ih,pre,((comp, cmod as DAE.MOD()) :: xs),ci_state,impl)
      equation
        false = Mod.isUntypedMod(cmod);
        name = SCodeUtil.elementName(comp);
        cref = Absyn.CREF_IDENT(name,{});
        SCode.PREFIXES(finalPrefix = fprefix) = SCodeUtil.elementPrefixes(comp);

        (cache,env2,ih) = updateComponentsInEnv(cache, env, ih, pre,
          DAE.MOD(fprefix,SCode.NOT_EACH(),{DAE.NAMEMOD(name, cmod)},NONE(),cmod.info),
          {cref}, ci_state, impl);
        (cache,env3,ih,res) = updateCompeltsMods_dispatch(cache, env2, ih, pre, xs, ci_state, impl);
      then
        (cache,env3,ih,((comp,cmod) :: res));

    case (cache,env,ih,pre,((comp, cmod as DAE.MOD()) :: xs),ci_state,impl)
      equation
        info = SCodeUtil.elementInfo(comp);
        umod = Mod.unelabMod(cmod);
        crefs = InstUtil.getCrefFromMod(umod);
        crefs_1 = InstUtil.getCrefFromCompDim(comp);
        crefs = List.unionOnTrue(crefs,crefs_1,AbsynUtil.crefEqual);
        name = SCodeUtil.elementName(comp);
        cref = Absyn.CREF_IDENT(name,{});

        ltmod = List.map1(crefs,InstUtil.getModsForDep,xs);
        cmod2 = List.fold2r(ltmod,Mod.merge,name,true,DAE.NOMOD());
        SCode.PREFIXES(finalPrefix = fprefix) = SCodeUtil.elementPrefixes(comp);

        //print("("+intString(listLength(ltmod))+")UpdateCompeltsMods_(" + stringDelimitList(List.map(crefs,AbsynUtil.printComponentRefStr),",") + ") subs: " + stringDelimitList(List.map(crefs,Absyn.printComponentRefStr),",")+ "\n");
        //print("     acquired mods: " + Mod.printModStr(cmod2) + "\n");

        (cache,env2,ih) = updateComponentsInEnv(cache, env, ih, pre, cmod2, crefs, ci_state, impl);
        (cache,env2,ih) = updateComponentsInEnv(cache, env2, ih, pre,
          DAE.MOD(fprefix,SCode.NOT_EACH(),{DAE.NAMEMOD(name, cmod)},NONE(), cmod.info),
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
  input DAE.Prefix inPrefix;
  input ClassInf.State inState;
  input Boolean inImpl;
  input DAE.Mod inCmod;
  output FCore.Cache outCache = inCache;
  output FCore.Graph outEnv = inEnv;
  output InnerOuter.InstHierarchy outIH = inIH;
  output SCode.Element outElement = inElement;
  output DAE.Mod outMod = DAE.NOMOD();
protected
  SCode.Element redecl_el;
  SCode.Mod mod;
  DAE.Mod redecl_mod, m, old_m;
  String redecl_name, name;
  Boolean found;
  SCode.Replaceable repl;
  Option<SCode.ConstrainClass> cc;
  list<SCode.Element> cc_comps;
  list<Absyn.ComponentRef> crefs;
algorithm
  if not Mod.isRedeclareMod(inMod) then
    outMod := Mod.merge(inMod, inCmod);
    return;
  end if;

  DAE.REDECL(element = redecl_el, mod = redecl_mod) := inMod;
  redecl_name := SCodeUtil.elementName(redecl_el);

  (outElement, outMod) := matchcontinue (redecl_el, inElement)
    // Redeclaration of component.
    case (SCode.COMPONENT(), SCode.COMPONENT(prefixes = SCode.PREFIXES(replaceablePrefix = repl)))
      algorithm
        true := redecl_name == inElement.name;

        mod := InstUtil.chainRedeclares(inMod, redecl_el.modifications);
        crefs := InstUtil.getCrefFromMod(mod);
        (outCache, outEnv, outIH) := updateComponentsInEnv(inCache, inEnv,
          inIH, inPrefix, DAE.NOMOD(), crefs, inState, inImpl);
        (outCache, m) := Mod.elabMod(outCache, outEnv, outIH, inPrefix, mod,
          inImpl, Mod.COMPONENT(redecl_name), redecl_el.info);
        (outCache, old_m) := Mod.elabMod(outCache, outEnv, outIH, inPrefix,
          inElement.modifications, inImpl, Mod.COMPONENT(inElement.name), inElement.info);

        m := match repl
          case SCode.REPLACEABLE(cc = cc as SOME(_))
            algorithm
              // Constraining type on the component:
              // Extract components belonging to constraining class.
              cc_comps := InstUtil.extractConstrainingComps(cc, inEnv, inPrefix);
              // Keep previous constraining class mods.
              redecl_mod := InstUtil.keepConstrainingTypeModifersOnly(redecl_mod, cc_comps);
              old_m := InstUtil.keepConstrainingTypeModifersOnly(old_m, cc_comps);

              m := Mod.merge(m, redecl_mod, redecl_name);
              m := Mod.merge(m, old_m, redecl_name);
              m := Mod.merge(m, inCmod, redecl_name);
            then
              m;

          else
            algorithm
              // No constraining type on comp, throw away modifiers prior to redeclaration:
              m := Mod.merge(redecl_mod, m, redecl_name);
              m := Mod.merge(m, old_m, redecl_name);
              m := Mod.merge(inCmod, m, redecl_name);
            then
              m;
        end match;

        (outCache, outElement) :=
          propagateRedeclCompAttr(outCache, outEnv, inElement, redecl_el);
        outElement := SCodeUtil.setComponentMod(outElement, mod);
      then
        (outElement, m);

    // Redeclaration of class.
    case (SCode.CLASS(), SCode.CLASS())
      algorithm
        true := redecl_name == inElement.name;
        (outCache, outEnv, outIH) := updateComponentsInEnv(inCache, inEnv, inIH,
          inPrefix, inMod, {Absyn.CREF_IDENT(inElement.name, {})}, inState, inImpl);
      then
        (inElement, redecl_mod);

    // Local redeclaration of class type path is an id.
    case (SCode.CLASS(), SCode.COMPONENT())
      algorithm
        name := AbsynUtil.typeSpecPathString(inElement.typeSpec);
        true := redecl_name == name;
        (outCache, outEnv, outIH) := updateComponentsInEnv(inCache, inEnv, inIH,
          inPrefix, inMod, {Absyn.CREF_IDENT(name, {})}, inState, inImpl);
      then
        (inElement, redecl_mod);

    // Local redeclaration of class, type is qualified.
    case (SCode.CLASS(), SCode.COMPONENT())
      algorithm
        name := AbsynUtil.pathFirstIdent(AbsynUtil.typeSpecPath(inElement.typeSpec));
        true := redecl_name == name;
        (outCache, outEnv, outIH) := updateComponentsInEnv(inCache, inEnv, inIH,
          inPrefix, inMod, {Absyn.CREF_IDENT(name, {})}, inState, inImpl);
      then
        (inElement, redecl_mod);

    else (inElement, DAE.NOMOD());
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
  if SCodeUtil.isArrayComponent(inOldComponent) and not SCodeUtil.isArrayComponent(inNewComponent) then
    (outCache, is_array) := Lookup.isArrayType(outCache, inEnv,
      AbsynUtil.typeSpecPath(SCodeUtil.getComponentTypeSpec(inNewComponent)));
  end if;

  outComponent := SCodeUtil.propagateAttributesVar(inOldComponent, inNewComponent, is_array);
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
  input DAE.Prefix pre;
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
  input DAE.Prefix pre;
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
        DAE.MOD(binding = NONE(),
                subModLst = {
                  DAE.NAMEMOD(ident=n,
                  mod = rmod as DAE.REDECL(_, _, {(SCode.COMPONENT(name = name),_)}))}),_,_,_,_,_)
      equation
        id = AbsynUtil.crefFirstIdent(cref);
        true = stringEq(id, name);
        true = stringEq(id, n);
        (outCache,outEnv,outIH,outUpdatedComps) = updateComponentInEnv(inCache,inEnv,inIH,pre,rmod,cref,inCIState,impl,inUpdatedComps,currentCref);
      then
        (outCache,outEnv,outIH,outUpdatedComps);*/

    // if we have a redeclare for a component
    case (cache,env,ih,_,
        DAE.REDECL(element =
         SCode.COMPONENT(
             name = name,
             prefixes = prefixes as SCode.PREFIXES(visibility = visibility),
             attributes = attributes,
             modifications = smod,
             info = info)),_,_,_,_,_)
      equation
        id = AbsynUtil.crefFirstIdent(cref);
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
        io = SCodeUtil.prefixesInnerOuter(pf);
        SCode.ATTR(ad,ct,prl1,var1,dir) = attr;

        (cache,_,SCode.COMPONENT(n,_,_,Absyn.TPATH(t, _),_,_,cond,info),_,_,idENV)
          = Lookup.lookupIdent(cache, env, id);

        ci_state = InstUtil.updateClassInfState(cache, idENV, env, inCIState);

        //Debug.traceln("update comp " + n + " with mods:" + Mod.printModStr(mods) + " m:" + SCodeDump.printModStr(m) + " cm:" + Mod.printModStr(cmod));
        (cache,cl,cenv) = Lookup.lookupClass(cache, env, t);
        //Debug.traceln("got class " + SCodeDump.printClassStr(cl));
        updatedComps = getUpdatedCompsHashTable(inUpdatedComps);
        (mods,cmod,m) = InstUtil.noModForUpdatedComponents(var1,updatedComps,cref,mods,cmod,m);
        crefs = InstUtil.getCrefFromMod(m);
        crefs2 = InstUtil.getCrefFromDim(ad);
        crefs3 = InstUtil.getCrefFromCond(cond);
        crefs_1 = listAppend(crefs, listAppend(crefs2,crefs3));
        crefs_2 = InstUtil.removeCrefFromCrefs(crefs_1, cref);
        updatedComps = BaseHashTable.add((cref,0),updatedComps);
        (cache,env2,ih,SOME(updatedComps)) = updateComponentsInEnv2(cache, env, ih, pre, DAE.NOMOD(), crefs_2, ci_state, impl, SOME(updatedComps), SOME(cref));

        (cache,env_1,ih,updatedComps) = updateComponentInEnv2(cache,env2,cenv,ih,pre,t,n,ad,cl,attr,pf,DAE.ATTR(DAEUtil.toConnectorTypeNoState(ct),prl1,var1,dir,io,visibility),info,m,cmod,mods,cref,ci_state,impl,updatedComps);

        //print("updateComponentInEnv: NEW ENV:\n" + FGraph.printGraphStr(env_1) + "\n");
      then
        (cache,env_1,ih,SOME(updatedComps));

    // redeclare class!
    case (cache,env,ih,_,DAE.REDECL(element = SCode.CLASS(name = name)),_,_,_,_,_)
      equation
        id = AbsynUtil.crefFirstIdent(cref);
        true = stringEq(name, id);
        // fetch the original class!
        (cl, _) = Lookup.lookupClassLocal(env, name);
        env = FGraph.updateClass(env, SCodeUtil.mergeWithOriginal(mod.element, cl), pre, mod, FCore.CLS_UNTYPED(), env);
        updatedComps = getUpdatedCompsHashTable(inUpdatedComps);
        updatedComps = BaseHashTable.add((cref,0),updatedComps);
      then
        (cache,env,ih,SOME(updatedComps));

    // Variable with NONE() element is already instantiated.
    case (cache,env,ih,_,_,_,_,_,_,_)
      equation
        id = AbsynUtil.crefFirstIdent(cref);
        (cache,_,_,_,is,_) = Lookup.lookupIdent(cache,env,id);
        true = FCore.isTyped(is) "If InstStatus is typed, return";
      then
        (cache,env,ih,inUpdatedComps);

    // the default case
    case (cache,env,ih,_,mods,_,_,_,_,_)
      equation
        id = AbsynUtil.crefFirstIdent(cref);
        (cache,_,
          SCode.COMPONENT(
            n,
            pf as SCode.PREFIXES(innerOuter = io, visibility = visibility),
            attr as SCode.ATTR(ad,ct,prl1,var1,dir),
            Absyn.TPATH(t, _),m,_,cond,info),cmod,_,idENV)
          = Lookup.lookupIdent(cache, env, id);

        ci_state = InstUtil.updateClassInfState(cache, idENV, env, inCIState);

        //Debug.traceln("update comp " + n + " with mods:" + Mod.printModStr(mods) + " m:" + SCodeDump.printModStr(m) + " cm:" + Mod.printModStr(cmod));
        (cache,cl,cenv) = Lookup.lookupClass(cache, env, t);
        //Debug.traceln("got class " + SCodeDump.printClassStr(cl));
        updatedComps = getUpdatedCompsHashTable(inUpdatedComps);
        (mods,cmod,m) = InstUtil.noModForUpdatedComponents(var1,updatedComps,cref,mods,cmod,m);
        crefs = List.flatten({
          InstUtil.getCrefFromMod(m),
          InstUtil.getCrefFromDim(ad),
          InstUtil.getCrefFromCond(cond),
          Mod.getUntypedCrefs(cmod)});
        crefs_2 = InstUtil.removeCrefFromCrefs(crefs, cref);
        // Also remove the cref that caused this updateComponentInEnv call, to avoid
        // infinite loops.
        crefs_2 = InstUtil.removeOptCrefFromCrefs(crefs_2, currentCref);
        updatedComps = BaseHashTable.add((cref,0),updatedComps);
        (cache,env2,ih,SOME(updatedComps)) = updateComponentsInEnv2(cache, env, ih, pre, mods, crefs_2, ci_state, impl, SOME(updatedComps), SOME(cref));
        (cache,env_1,ih,updatedComps) = updateComponentInEnv2(cache,env2,cenv,ih,pre,t,n,ad,cl,attr,pf,DAE.ATTR(DAEUtil.toConnectorTypeNoState(ct),prl1,var1,dir,io,visibility),info,m,cmod,mods,cref,ci_state,impl,updatedComps);
      then
        (cache,env_1,ih,SOME(updatedComps));

    // If first part of ident is a class, e.g StateSelect.None, nothing to update
    case (cache,env,ih,_,_,_,_,_,_,_)
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
  input DAE.Prefix pre;
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
  input DAE.Prefix inPrefix;
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
    smod := SCodeUtil.mergeModifiers(inSMod, SCodeUtil.getConstrainedByModifiers(inPrefixes));
    (outCache, mod1) :=
      updateComponentInEnv3(outCache, outEnv, outIH, smod, inImpl, Mod.COMPONENT(inName), inInfo);
    class_mod := Mod.lookupModificationP(inMod, inPath);
    //comp_mod := Mod.lookupCompModification(inMod, inName);
    //mod2 := Mod.merge(class_mod, comp_mod, inName);
    mod2 := Mod.merge(class_mod, mod1, inName);
    mod2 := Mod.merge(inClsMod, mod2, inName);
    (outCache, mod2) :=
      Mod.updateMod(outCache, outEnv, outIH, DAE.NOPRE(), mod2, inImpl, inInfo);

    mod := if InstUtil.redeclareBasicType(inClsMod) then mod1 else mod2;
    eq := Mod.modEquation(mod);

    own_cref := Absyn.CREF_IDENT(inName, {});
    (outCache, dims) := InstUtil.elabArraydim(outCache, outEnv, own_cref, inPath,
      inSubscripts, eq, inImpl, true, false, inPrefix, inInfo, {});

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
    var := DAE.TYPES_VAR(inName, inDAttr, ty, binding, false, NONE());
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
        (cache, mod) = Mod.elabMod(inCache, inEnv, inIH, DAE.NOPRE(), inMod, inImpl, inModScope, inInfo)
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
        mod = Mod.elabUntypedMod(inMod, inEnv, DAE.NOPRE());
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
  input SCode.Program prog;
  output FCore.Cache outCache;
  output FCore.Graph env_1;
protected
  FCore.Graph env;
  FCore.Cache cache;
algorithm
  // prog := scodeFlatten(prog, path);
  (cache, env) := Builtin.initialGraph(FCore.emptyCache());
  env_1 := FGraphBuildEnv.mkProgramGraph(prog, FCore.USERDEFINED(),env);
  outCache := cache;
end makeEnvFromProgram;

public function makeFullyQualified
"author: PA
  Transforms a class name to its fully qualified name by investigating the environment.
  For instance, the model Resistor in Modelica.Electrical.Analog.Basic will given the
  correct environment have the fully qualified name: Modelica.Electrical.Analog.Basic.Resistor"
  input output FCore.Cache cache;
  input FCore.Graph inEnv;
  input output Absyn.Path path;
algorithm
  (cache,path) := match path

    // Special cases: assert and reinit can not be handled by builtin.mo, since they do not have return type
    case Absyn.IDENT()
      algorithm
        (cache,path) := makeFullyQualifiedIdent(cache,inEnv,path.name,path);
      then (cache,path);

    // do NOT fully quallify again a fully qualified path!
    case Absyn.FULLYQUALIFIED() then (cache, path);

    // To make a class fully qualified, the class path is looked up in the environment.
    // The FQ path consist of the simple class name appended to the environment path of the looked up class.
    case Absyn.QUALIFIED()
      algorithm
        (cache,path) := makeFullyQualifiedFromQual(cache,inEnv,path);
      then (cache,path);
  end match;
end makeFullyQualified;

protected function makeFullyQualifiedFromQual
  input output FCore.Cache cache;
  input FCore.Graph inEnv;
  input output Absyn.Path path;
algorithm
  (cache,path) := matchcontinue path
    local
      FCore.Graph env,env_1;
      Absyn.Path path_2,path3;
      String s;
      SCode.Element cl;
      DAE.ComponentRef crPath;
      FCore.Graph fs;
      Absyn.Ident name, ename;
      FCore.Ref r;
    case _
      algorithm
        (cache,SCode.CLASS(name = name),env_1) := Lookup.lookupClass(cache, inEnv, path);
        path_2 := makeFullyQualified2(env_1,name);
      then (cache,AbsynUtil.makeFullyQualified(path_2));
    case _
      algorithm
        crPath := ComponentReference.pathToCref(path);
        (cache,_,_,_,_,_,env,_,name) := Lookup.lookupVarInternal(cache, inEnv, crPath, InstTypes.SEARCH_ALSO_BUILTIN());
        path3 := makeFullyQualified2(env,name);
      then (cache,AbsynUtil.makeFullyQualified(path3));
    case _
      algorithm
        crPath := ComponentReference.pathToCref(path);
        (cache,env,_,_,_,_,_,_,name) := Lookup.lookupVarInPackages(cache, inEnv, crPath, {}, Mutable.create(false));
        path3 := makeFullyQualified2(env,name);
      then (cache,AbsynUtil.makeFullyQualified(path3));
    else (cache,path);
  end matchcontinue;
end makeFullyQualifiedFromQual;

public function makeFullyQualifiedIdent
"author: PA
  Transforms a class name to its fully qualified name by investigating the environment.
  For instance, the model Resistor in Modelica.Electrical.Analog.Basic will given the
  correct environment have the fully qualified name: Modelica.Electrical.Analog.Basic.Resistor"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input String ident;
  input Absyn.Path inPath=Absyn.IDENT("");
  output FCore.Cache outCache;
  output Absyn.Path outPath;
protected
  Boolean isKnownBuiltin;
algorithm
  (outPath,isKnownBuiltin) := makeFullyQualifiedIdentCheckBuiltin(ident);
  if isKnownBuiltin then
    outCache := inCache;
    return;
  end if;
  (outCache,outPath) := matchcontinue (inCache,inEnv,ident)
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

    // To make a class fully qualified, the class path is looked up in the environment.
    // The FQ path consist of the simple class name appended to the environment path of the looked up class.
    case (cache,env,_)
      equation
        (cache,SCode.CLASS(name = name),env_1) = Lookup.lookupClassIdent(cache, env, ident);
        path_2 = makeFullyQualified2(env_1,name);
      then
        (cache,AbsynUtil.makeFullyQualified(path_2));

    // Needed to make external objects fully-qualified
    case (cache,env,s)
      equation
        r = FGraph.lastScopeRef(env);
        false = FNode.isRefTop(r);
        name = FNode.refName(r);
        true = name == s;
        SOME(path_2) = FGraph.getScopePath(env);
      then
        (cache,AbsynUtil.makeFullyQualified(path_2));

    // A type can exist without a class (i.e. builtin functions)
    case (cache,env,s)
      equation
         (cache,_,env_1) = Lookup.lookupTypeIdent(cache,env, s, NONE());
         path_2 = makeFullyQualified2(env_1,s,inPath);
      then
        (cache,AbsynUtil.makeFullyQualified(path_2));

     // A package constant, first try to look it up local (top frame)
    case (cache,env,_)
      equation
        (cache,_,_,_,_,_,env,_,name) = Lookup.lookupVarInternalIdent(cache, env, ident, {}, InstTypes.SEARCH_ALSO_BUILTIN());
        path3 = makeFullyQualified2(env,name);
      then
        (cache,AbsynUtil.makeFullyQualified(path3));

    // TODO! FIXME! what do we do here??!!
    case (cache,env,_)
      equation
        (cache,env,_,_,_,_,_,_,name) = Lookup.lookupVarInPackagesIdent(cache, env, ident, {}, {}, Mutable.create(false));
        path3 = makeFullyQualified2(env,name);
      then
        (cache,AbsynUtil.makeFullyQualified(path3));

    // If it fails, leave name unchanged.
    else (inCache,match inPath case Absyn.IDENT("") then Absyn.IDENT(ident); else inPath; end match);
  end matchcontinue;
end makeFullyQualifiedIdent;

protected function makeFullyQualifiedIdentCheckBuiltin
  input String ident;
  output Absyn.Path path;
  output Boolean isKnownBuiltin=true;
algorithm
  path := match ident
    case "Boolean" then Absyn.FULLYQUALIFIED(Absyn.IDENT("Boolean"));
    case "Integer" then Absyn.FULLYQUALIFIED(Absyn.IDENT("Integer"));
    case "Real" then Absyn.FULLYQUALIFIED(Absyn.IDENT("Real"));
    case "String" then Absyn.FULLYQUALIFIED(Absyn.IDENT("String"));
    case "EnumType" then Absyn.FULLYQUALIFIED(Absyn.IDENT("EnumType"));

    // Builtin functions are handled after lookup of class (in case it is shadowed)

    case "assert" then Absyn.IDENT("assert");
    case "reinit" then Absyn.IDENT("reinit");

    // Other functions that can not be represented in env due to e.g. applicable to any record
    case "smooth" then Absyn.IDENT("smooth");

    // MetaModelica extensions
    case "list" algorithm isKnownBuiltin:=Config.acceptMetaModelicaGrammar(); then Absyn.IDENT("list");
    case "Option" algorithm isKnownBuiltin:=Config.acceptMetaModelicaGrammar(); then Absyn.IDENT("Option");
    case "tuple" algorithm isKnownBuiltin:=Config.acceptMetaModelicaGrammar(); then Absyn.IDENT("tuple");
    case "polymorphic" algorithm isKnownBuiltin:=Config.acceptMetaModelicaGrammar(); then Absyn.IDENT("polymorphic");
    case "array" algorithm isKnownBuiltin:=Config.acceptMetaModelicaGrammar(); then Absyn.IDENT("array");
    else algorithm isKnownBuiltin:=false; then Absyn.IDENT("");
  end match;
end makeFullyQualifiedIdentCheckBuiltin;

public function instList
"This is a utility used to do instantiation of list
  of things, collecting the result in another list."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input InstFunc instFunc;
  input list<Type_a> inTypeALst;
  input Boolean inImplicit;
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
    input DAE.Prefix inPrefix;
    input Connect.Sets inSets;
    input ClassInf.State inState;
    input Type_a inTypeA;
    input Boolean inImplicit;
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
  match (inCache,inEnv,inIH,inPrefix,inSets,inState,instFunc,inTypeALst,inImplicit,unrollForLoops,inGraph)
    local
      FCore.Graph env,env_1,env_2;
      DAE.Mod mod;
      DAE.Prefix pre;
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
  input DAE.Prefix inPrefix;
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
  input DAE.Prefix inPrefix;
  input list<Absyn.NamedArg> inAttrs;
  input Boolean inImplicit;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output DAE.DAElist outDae;
algorithm

  (outCache,outEnv,outDae):=
  match (inCache,inEnv,inPrefix,inAttrs,inImplicit,inInfo)
    local
      FCore.Cache cache;
      FCore.Graph env;
      DAE.DAElist clsAttrs, dae;

    case (cache,env,_,{},_,_)
      then (cache,env,DAE.emptyDae);

    case (_,_,_,_,_,_)
      equation
        clsAttrs = DAE.DAE({DAE.CLASS_ATTRIBUTES(DAE.OPTIMIZATION_ATTRS(NONE(),NONE(),NONE(),NONE()))});
        (cache,env,dae) = instClassAttributes2(inCache,inEnv,inPrefix,inAttrs,inImplicit,inInfo,clsAttrs);
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
  input DAE.Prefix inPrefix;
  input list<Absyn.NamedArg> inAttrs;
  input Boolean inImplicit;
  input SourceInfo inInfo;
  input DAE.DAElist inClsAttrs;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output DAE.DAElist outDae;
algorithm

  (outCache,outEnv,outDae):=
  match (inCache,inEnv,inPrefix,inAttrs,inImplicit,inInfo,inClsAttrs)
    local
      FCore.Graph env,env_2;
      DAE.Prefix pre;
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
        (cache,outExp,_) = Static.elabExp(cache, env, attrExp, impl, false /*vectorize*/, pre, inInfo);
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
        (cache,(cdef as SCode.CLASS()),env_2) = Lookup.lookupClass(cache,env_1, path, SOME(AbsynUtil.dummyInfo));

        (cache,env_2,ih,_,dae,_,_,_,_,_) =
          instClass(cache,env_2,ih,UnitAbsyn.noStore, DAE.NOMOD(), DAE.NOPRE(),
            cdef, {}, false, InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, Connect.emptySet) "impl" ;
        _ = AbsynUtil.pathString(path);
      then
        (cache,env_2,ih,dae);

    case (_,_,_,path) /* error instantiating */
      equation
        cname_str = AbsynUtil.pathString(path);
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
          instClass(cache,env,ih, UnitAbsyn.noStore, DAE.NOMOD(), DAE.NOPRE(), c,
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
  (omod1, omod2) := match inMod
    local
      String id;

    case DAE.REDECL(element = SCode.CLASS(name = id))
      then if id == AbsynUtil.pathString(path) then
        (inMod, DAE.NOMOD()) else (DAE.NOMOD(), inMod);

    else (DAE.NOMOD(), inMod);

  end match;
end modifyInstantiateClass;

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
  input DAE.Prefix pre;
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
        (cache,c,cenv) = Lookup.lookupClass(cache,env, sty, SOME(info));
        (cache,dims) = InstUtil.elabArraydim(cache,cenv, c1, sty, ad, NONE(), impl, true, false, pre, info, inst_dims);

        // we really need to keep at least the redeclare modifications here!!
        smod = SCodeInstUtil.removeSelfReferenceFromMod(scodeMod, c1);
        (cache,m) = Mod.elabMod(cache, env, ih, pre, smod, impl, Mod.COMPONENT(n), info); // m = Mod.elabUntypedMod(smod, env, pre);

        (cenv, c, ih) = FGraph.createVersionScope(env, n, pre, m, cenv, c, ih);
        (cache,compenv,ih,store,_,_,ty,_) =
          InstVar.instVar(cache, cenv, ih, store, state, m, pre, n, c, attr,
            inPrefixes, dims, {}, inst_dims, true, SCode.noComment, info, ConnectionGraph.EMPTY, Connect.emptySet, env);

        // print("component: " + n + " ty: " + Types.printTypeStr(ty) + "\n");

        io = SCodeUtil.prefixesInnerOuter(inPrefixes);
        vis = SCodeUtil.prefixesVisibility(inPrefixes);

        new_var = DAE.TYPES_VAR(n,DAE.ATTR(DAEUtil.toConnectorTypeNoState(ct),prl1,var1,dir,io,vis),ty,DAE.UNBOUND(),false,NONE());
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
        (cache,c,cenv) = Lookup.lookupClass(cache,env, sty, SOME(info));
        (cache,dims) = InstUtil.elabArraydim(cache, cenv, c1, sty, ad, NONE(), impl, true, false, pre, info, inst_dims);

        // we really need to keep at least the redeclare modifications here!!
        smod = SCodeInstUtil.removeNonConstantBindingsKeepRedeclares(scodeMod, false);
        (cache,m) = Mod.elabMod(cache, env, ih, pre, smod, impl, Mod.COMPONENT(n), info); // m = Mod.elabUntypedMod(smod, env, pre);

        (cenv, c, ih) = FGraph.createVersionScope(env, n, pre, m, cenv, c, ih);
        (cache,compenv,ih,store,_,_,ty,_) =
          InstVar.instVar(cache, cenv, ih, store, state, m, pre, n, c, attr,
            inPrefixes, dims, {}, inst_dims, true, SCode.noComment, info, ConnectionGraph.EMPTY, Connect.emptySet, env);

        // print("component: " + n + " ty: " + Types.printTypeStr(ty) + "\n");

        io = SCodeUtil.prefixesInnerOuter(inPrefixes);
        vis = SCodeUtil.prefixesVisibility(inPrefixes);

        new_var = DAE.TYPES_VAR(n,DAE.ATTR(DAEUtil.toConnectorTypeNoState(ct),prl1,var1,dir,io,vis),ty,DAE.UNBOUND(),false,NONE());
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
        (cache,c,cenv) = Lookup.lookupClass(cache,env, sty, SOME(info));
        (cache,dims) = InstUtil.elabArraydim(cache,cenv, c1, sty, ad, NONE(), impl, true, false, pre, info, inst_dims);

        // we really need to keep at least the redeclare modifications here!!
        smod = SCodeInstUtil.removeNonConstantBindingsKeepRedeclares(scodeMod, true);
        (cache,m) = Mod.elabMod(cache, env, ih, pre, smod, impl, Mod.COMPONENT(n), info); // m = Mod.elabUntypedMod(smod, env, pre);

        (cenv, c, ih) = FGraph.createVersionScope(env, n, pre, m, cenv, c, ih);
        (cache,compenv,ih,store,_,_,ty,_) =
          InstVar.instVar(cache, cenv, ih, store, state, m, pre, n, c, attr,
            inPrefixes, dims, {}, inst_dims, true, SCode.noComment, info, ConnectionGraph.EMPTY, Connect.emptySet, env);

        // print("component: " + n + " ty: " + Types.printTypeStr(ty) + "\n");

        io = SCodeUtil.prefixesInnerOuter(inPrefixes);
        vis = SCodeUtil.prefixesVisibility(inPrefixes);

        new_var = DAE.TYPES_VAR(n,DAE.ATTR(DAEUtil.toConnectorTypeNoState(ct),prl1,var1,dir,io,vis),ty,DAE.UNBOUND(),false,NONE());
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
        (cache,c,cenv) = Lookup.lookupClass(cache,env, sty, SOME(info));
        (cache,dims) = InstUtil.elabArraydim(cache,cenv, c1, sty, ad, NONE(), impl, true, false, pre, info, inst_dims);

        // we really need to keep at least the redeclare modifications here!!
        // smod = SCodeInstUtil.removeNonConstantBindingsKeepRedeclares(scodeMod, true);
        // (cache,m) = Mod.elabMod(cache, env, ih, pre, smod, impl, info); // m = Mod.elabUntypedMod(smod, env, pre);
        m = DAE.NOMOD();

        (cenv, c, ih) = FGraph.createVersionScope(env, n, pre, m, cenv, c, ih);
        (cache,compenv,ih,store,_,_,ty,_) =
          InstVar.instVar(cache, cenv, ih, store, state, m, pre, n, c, attr,
            inPrefixes, dims, {}, inst_dims, true, SCode.noComment, info, ConnectionGraph.EMPTY, Connect.emptySet, env);

        // print("component: " + n + " ty: " + Types.printTypeStr(ty) + "\n");

        io = SCodeUtil.prefixesInnerOuter(inPrefixes);
        vis = SCodeUtil.prefixesVisibility(inPrefixes);

        new_var = DAE.TYPES_VAR(n,DAE.ATTR(DAEUtil.toConnectorTypeNoState(ct),prl1,var1,dir,io,vis),ty,DAE.UNBOUND(),false,NONE());
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
        (cache,c,cenv) = Lookup.lookupClass(cache,env, sty, SOME(info));
        (cache,dims) = InstUtil.elabArraydim(cache,cenv, c1, sty, ad, NONE(), impl, NONE(), true, false, pre, info, inst_dims);

        sM = NFSCodeMod.removeCrefPrefixFromModExp(scodeMod, inRef);

        //(cache, dM) = elabMod(cache, env, ih, pre, sM, impl, info);
        dM = Mod.elabUntypedMod(sM, env, pre);

        (cenv, c, ih) = FGraph.createVersionScope(env, n, pre, dM, cenv, c, ih);
        (cache,compenv,ih,store,_,_,ty,_) =
          InstVar.instVar(cache, cenv, ih, store, state, dM, pre, n, c, attr,
            inPrefixes, dims, {}, inst_dims, true, NONE(), info, ConnectionGraph.EMPTY, Connect.emptySet, env);

        // print("component: " + n + " ty: " + Types.printTypeStr(ty) + "\n");

        io = SCodeUtil.prefixesInnerOuter(inPrefixes);
        vis = SCodeUtil.prefixesVisibility(inPrefixes);
        new_var = DAE.TYPES_VAR(n,DAE.ATTR(ct,prl1,var1,dir,io,vis),ty,DAE.UNBOUND(),false,NONE());
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
  input DAE.Prefix pre;
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
  input String name;
  input Absyn.Path cachedPath=Absyn.IDENT("");
  output Absyn.Path path;
protected
  Absyn.Path scope;
  Option<Absyn.Path> oscope;
algorithm
  oscope := FGraph.getScopePath(env);
  if isNone(oscope) then
    path := makeFullyQualified2Builtin(name, cachedPath);
  else
    SOME(scope) := oscope;
    path := AbsynUtil.joinPaths(scope, match cachedPath case Absyn.IDENT("") then Absyn.IDENT(name); else cachedPath; end match);
  end if;
end makeFullyQualified2;

protected function makeFullyQualified2Builtin "Lookup table to avoid memory allocation of common built-in function calls"
  input String ident;
  input Absyn.Path cachedPath;
  output Absyn.Path path;
algorithm
  // TODO: Have annotation asserting that this is a switch-statement
  path := match ident
    case "abs" then Absyn.FULLYQUALIFIED(Absyn.IDENT("abs"));
    case "acos" then Absyn.FULLYQUALIFIED(Absyn.IDENT("acos"));
    case "activeState" then Absyn.FULLYQUALIFIED(Absyn.IDENT("activeState"));
    case "actualStream" then Absyn.FULLYQUALIFIED(Absyn.IDENT("actualStream"));
    case "asin" then Absyn.FULLYQUALIFIED(Absyn.IDENT("asin"));
    case "atan" then Absyn.FULLYQUALIFIED(Absyn.IDENT("atan"));
    case "atan2" then Absyn.FULLYQUALIFIED(Absyn.IDENT("atan2"));
    case "backSample" then Absyn.FULLYQUALIFIED(Absyn.IDENT("backSample"));
    case "cardinality" then Absyn.FULLYQUALIFIED(Absyn.IDENT("cardinality"));
    case "cat" then Absyn.FULLYQUALIFIED(Absyn.IDENT("cat"));
    case "ceil" then Absyn.FULLYQUALIFIED(Absyn.IDENT("ceil"));
    case "change" then Absyn.FULLYQUALIFIED(Absyn.IDENT("change"));
    case "classDirectory" then Absyn.FULLYQUALIFIED(Absyn.IDENT("classDirectory"));
    case "cos" then Absyn.FULLYQUALIFIED(Absyn.IDENT("cos"));
    case "cosh" then Absyn.FULLYQUALIFIED(Absyn.IDENT("cosh"));
    case "cross" then Absyn.FULLYQUALIFIED(Absyn.IDENT("cross"));
    case "delay" then Absyn.FULLYQUALIFIED(Absyn.IDENT("delay"));
    case "der" then Absyn.FULLYQUALIFIED(Absyn.IDENT("der"));
    case "diagonal" then Absyn.FULLYQUALIFIED(Absyn.IDENT("diagonal"));
    case "div" then Absyn.FULLYQUALIFIED(Absyn.IDENT("div"));
    case "edge" then Absyn.FULLYQUALIFIED(Absyn.IDENT("edge"));
    case "exp" then Absyn.FULLYQUALIFIED(Absyn.IDENT("exp"));
    case "fill" then Absyn.FULLYQUALIFIED(Absyn.IDENT("fill"));
    case "firstTick" then Absyn.FULLYQUALIFIED(Absyn.IDENT("firstTick"));
    case "floor" then Absyn.FULLYQUALIFIED(Absyn.IDENT("floor"));
    case "getInstanceName" then Absyn.FULLYQUALIFIED(Absyn.IDENT("getInstanceName"));
    case "hold" then Absyn.FULLYQUALIFIED(Absyn.IDENT("hold"));
    case "homotopy" then Absyn.FULLYQUALIFIED(Absyn.IDENT("homotopy"));
    case "identity" then Absyn.FULLYQUALIFIED(Absyn.IDENT("identity"));
    case "inStream" then Absyn.FULLYQUALIFIED(Absyn.IDENT("inStream"));
    case "initial" then Absyn.FULLYQUALIFIED(Absyn.IDENT("initial"));
    case "initialState" then Absyn.FULLYQUALIFIED(Absyn.IDENT("initialState"));
    case "integer" then Absyn.FULLYQUALIFIED(Absyn.IDENT("integer"));
    case "interval" then Absyn.FULLYQUALIFIED(Absyn.IDENT("interval"));
    case "intAbs" then Absyn.FULLYQUALIFIED(Absyn.IDENT("intAbs"));
    case "linspace" then Absyn.FULLYQUALIFIED(Absyn.IDENT("linspace"));
    case "log" then Absyn.FULLYQUALIFIED(Absyn.IDENT("log"));
    case "log10" then Absyn.FULLYQUALIFIED(Absyn.IDENT("log10"));
    case "matrix" then Absyn.FULLYQUALIFIED(Absyn.IDENT("matrix"));
    case "max" then Absyn.FULLYQUALIFIED(Absyn.IDENT("max"));
    case "min" then Absyn.FULLYQUALIFIED(Absyn.IDENT("min"));
    case "mod" then Absyn.FULLYQUALIFIED(Absyn.IDENT("mod"));
    case "ndims" then Absyn.FULLYQUALIFIED(Absyn.IDENT("ndims"));
    case "noClock" then Absyn.FULLYQUALIFIED(Absyn.IDENT("noClock"));
    case "noEvent" then Absyn.FULLYQUALIFIED(Absyn.IDENT("noEvent"));
    case "ones" then Absyn.FULLYQUALIFIED(Absyn.IDENT("ones"));
    case "outerProduct" then Absyn.FULLYQUALIFIED(Absyn.IDENT("outerProduct"));
    case "pre" then Absyn.FULLYQUALIFIED(Absyn.IDENT("pre"));
    case "previous" then Absyn.FULLYQUALIFIED(Absyn.IDENT("previous"));
    case "print" then Absyn.FULLYQUALIFIED(Absyn.IDENT("print"));
    case "product" then Absyn.FULLYQUALIFIED(Absyn.IDENT("product"));
    case "realAbs" then Absyn.FULLYQUALIFIED(Absyn.IDENT("realAbs"));
    case "rem" then Absyn.FULLYQUALIFIED(Absyn.IDENT("rem"));
    case "rooted" then Absyn.FULLYQUALIFIED(Absyn.IDENT("rooted"));
    case "sample" then Absyn.FULLYQUALIFIED(Absyn.IDENT("sample"));
    case "scalar" then Absyn.FULLYQUALIFIED(Absyn.IDENT("scalar"));
    case "semilinear" then Absyn.FULLYQUALIFIED(Absyn.IDENT("semilinear"));
    case "shiftSample" then Absyn.FULLYQUALIFIED(Absyn.IDENT("shiftSample"));
    case "sign" then Absyn.FULLYQUALIFIED(Absyn.IDENT("sign"));
    case "sin" then Absyn.FULLYQUALIFIED(Absyn.IDENT("sin"));
    case "sinh" then Absyn.FULLYQUALIFIED(Absyn.IDENT("sinh"));
    case "size" then Absyn.FULLYQUALIFIED(Absyn.IDENT("size"));
    case "skew" then Absyn.FULLYQUALIFIED(Absyn.IDENT("skew"));
    case "smooth" then Absyn.FULLYQUALIFIED(Absyn.IDENT("smooth"));
    case "spatialDistribution" then Absyn.FULLYQUALIFIED(Absyn.IDENT("spatialDistribution"));
    case "sqrt" then Absyn.FULLYQUALIFIED(Absyn.IDENT("sqrt"));
    case "subSample" then Absyn.FULLYQUALIFIED(Absyn.IDENT("subSample"));
    case "symmetric" then Absyn.FULLYQUALIFIED(Absyn.IDENT("symmetric"));
    case "tan" then Absyn.FULLYQUALIFIED(Absyn.IDENT("tan"));
    case "tanh" then Absyn.FULLYQUALIFIED(Absyn.IDENT("tanh"));
    case "terminal" then Absyn.FULLYQUALIFIED(Absyn.IDENT("terminal"));
    case "ticksInState" then Absyn.FULLYQUALIFIED(Absyn.IDENT("ticksInState"));
    case "timeInState" then Absyn.FULLYQUALIFIED(Absyn.IDENT("timeInState"));
    case "transition" then Absyn.FULLYQUALIFIED(Absyn.IDENT("transition"));
    case "transpose" then Absyn.FULLYQUALIFIED(Absyn.IDENT("transpose"));
    case "vector" then Absyn.FULLYQUALIFIED(Absyn.IDENT("vector"));
    case "zeros" then Absyn.FULLYQUALIFIED(Absyn.IDENT("zeros"));
    else match cachedPath case Absyn.IDENT("") then Absyn.IDENT(ident); else cachedPath; end match;
  end match;
end makeFullyQualified2Builtin;

public function getCachedInstance
  input output FCore.Cache cache;
  input output FCore.Graph env;
  input String name;
  input FCore.Ref ref;
protected
  Absyn.Path cache_path;
  SCode.Element cls;
  DAE.Prefix prefix, prefix2;
  FCore.Graph env2;
  SCode.Encapsulated enc;
  SCode.Restriction res;
  InstHashTable.CachedInstItemInputs inputs;
algorithm
  true := Flags.isSet(Flags.CACHE);

  FCore.CL(cls as SCode.CLASS(encapsulatedPrefix = enc, restriction = res), prefix) :=
    FNode.refData(ref);
  env2 := FGraph.openScope(env, enc, name, FGraph.restrictionToScopeType(res));

  try
    cache_path := generateCachePath(env2, cls, prefix, InstTypes.INNER_CALL());
    {SOME(InstHashTable.FUNC_instClassIn(inputs, (env, _, _, _, _, _, _, _, _))), _} := InstHashTable.get(cache_path);
    (_, prefix2, _, _, _, _, _, _, _) := inputs;
    true := PrefixUtil.isPrefix(prefix) and PrefixUtil.isPrefix(prefix2);
  else
    env := FGraph.pushScopeRef(env, ref);
  end try;
end getCachedInstance;

protected function generateCachePath
  input FCore.Graph env;
  input SCode.Element cls;
  input DAE.Prefix prefix;
  input InstTypes.CallingScope callScope;
  output Absyn.Path cachePath;
protected
  String name;
algorithm
  name := StringUtil.stringAppend9(InstTypes.callingScopeStr(callScope), "$",
          SCodeDump.restrString(SCodeUtil.getClassRestriction(cls)), "$",
          generatePrefixStr(prefix), "$");
  cachePath := AbsynUtil.joinPaths(Absyn.IDENT(name), FGraph.getGraphName(env));
end generateCachePath;

public function generatePrefixStr
  input DAE.Prefix inPrefix;
  output String str;
algorithm
  try
    str := AbsynUtil.pathString(PrefixUtil.prefixToPath(inPrefix), "$", usefq=false, reverse=true);
  else
    str := "";
  end try;
end generatePrefixStr;

protected function showCacheInfo
  input String inMsg;
  input Absyn.Path inPath;
algorithm
  if Flags.isSet(Flags.SHOW_INST_CACHE_INFO) then
    print(inMsg + AbsynUtil.pathString(inPath) + "\n");
  end if;
end showCacheInfo;

function instFunctionAnnotations "Merges the function's comments from inherited classes"
  input list<SCode.Comment> comments;
  input ClassInf.State state;
  output DAE.DAElist dae=DAE.emptyDae;
protected
  Option<String> comment=NONE();
  SCode.Mod mod=SCode.NOMOD(), mod2;
algorithm
  if not ClassInf.isFunction(state) then
    return;
  end if;

  for cmt in comments loop

    if isNone(comment) then
      comment := cmt.comment;
    end if;

    mod := match cmt
      case SCode.COMMENT(annotation_=SOME(SCode.ANNOTATION(modification=mod2)))
        then SCodeUtil.mergeModifiers(mod2, mod);
      else mod;
    end match;

  end for;
  dae := match mod
    case SCode.NOMOD() then if isNone(comment) then dae else DAE.DAE({DAE.COMMENT(SCode.COMMENT(NONE(),comment))});
    else DAE.DAE({DAE.COMMENT(SCode.COMMENT(SOME(SCode.ANNOTATION(mod)), comment))});
  end match;
end instFunctionAnnotations;

annotation(__OpenModelica_Interface="frontend");
end Inst;
