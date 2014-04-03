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

encapsulated package InstFunction
" file:        InstFunction.mo
  package:     InstFunction
  description: Function instantiation

  RCS: $Id: InstFunction.mo 17556 2013-10-05 23:58:57Z adrpo $

  This module is responsible for instantiation of Modelica functions.

"

public import Absyn;
public import ClassInf;
public import Connect;
public import ConnectionGraph;
public import DAE;
public import Env;
public import InnerOuter;
public import InstTypes;
public import Mod;
public import Prefix;
public import SCode;
public import UnitAbsyn;

protected import Lookup;
protected import MetaUtil;
protected import Inst;
protected import InstBinding;
protected import InstVar;
protected import InstUtil;
protected import UnitAbsynBuilder;
protected import List;
protected import Types;
protected import Flags;
protected import Debug;
protected import SCodeDump;
protected import Util;
protected import Config;
protected import DAEUtil;
protected import PrefixUtil;
protected import Error;
protected import Builtin;

protected type Ident = DAE.Ident "an identifier";
protected type InstanceHierarchy = InnerOuter.InstHierarchy "an instance hierarchy";
protected type InstDims = list<list<DAE.Subscript>>;

public function instantiateFunctionImplicit
"author: PA
  Similar to instantiateClassImplict, i.e. instantation of arbitrary
  classes but this one instantiates the class implicit for functions."
  input Env.Cache inCache;
  input InnerOuter.InstHierarchy inIH;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
algorithm
  (outCache,outEnv,outIH) := matchcontinue (inCache,inIH,inProgram,inPath)
    local
      Absyn.Path cr,path;
      list<Env.Frame> env,env_1,env_2;
      list<SCode.Element> cdecls;
      String name2,n,name;
      SCode.Element cdef;
      Env.Cache cache;
      InstanceHierarchy ih;

    // Fully qualified paths
    case (cache,ih,cdecls,Absyn.FULLYQUALIFIED(path))
      equation
        (cache,env,ih) = instantiateFunctionImplicit(cache,ih,cdecls,path);
      then
        (cache,env,ih);

    case (_,_,{},_)
      equation
        Error.addMessage(Error.NO_CLASSES_LOADED, {});
      then
        fail();

    case (cache,ih,(cdecls as (_ :: _)),(path as Absyn.IDENT(name = _))) /* top level class */
      equation
        (cache,env) = Builtin.initialEnv(cache);
        (cache,env_1,ih,_) = Inst.instClassDecls(cache, env, ih, cdecls);
        (cache,env_2,ih) = instFunctionInProgramImplicit(cache, env_1, ih, cdecls, path);
      then
        (cache,env_2,ih);

    case (cache,ih,(cdecls as (_ :: _)),(path as Absyn.QUALIFIED(name = name))) /* class in package */
      equation
        (cache,env) = Builtin.initialEnv(cache);
        (cache,env_1,ih,_) = Inst.instClassDecls(cache, env, ih, cdecls);
        (cache,(cdef as SCode.CLASS(name = _)),env_2) = Lookup.lookupClass(cache,env_1, path, true);
        env_2 = Env.extendFrameC(env_2, cdef);
        (cache,env,ih) = implicitFunctionInstantiation(cache, env_2, ih, DAE.NOMOD(), Prefix.NOPRE(), cdef, {});
      then
        (cache,env,ih);

    case (_,_,_,path)
      equation
        //print("-instantiateFunctionImplicit ");print(Absyn.pathString(path));print(" failed\n");
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprint(Flags.FAILTRACE, "-Inst.instantiateFunctionImplicit " +& Absyn.pathString(path) +& " failed\n");
      then
        fail();
  end matchcontinue;
end instantiateFunctionImplicit;

protected function instFunctionInProgramImplicit
  "Implicitly instantiates a specific top level function in a Program."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input SCode.Program inProgram;
  input SCode.Path inPath;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
algorithm
  (outCache,outEnv,outIH) := matchcontinue (inCache,inEnv,inIH,inProgram,inPath)
    local
      list<Env.Frame> env;
      SCode.Element c;
      String name;
      Env.Cache cache;
      InstanceHierarchy ih;

    case (_, _, _, {}, _) then (inCache, inEnv, inIH);

    case (cache, env, ih, _, Absyn.IDENT(name = name))
      equation
        c = InstUtil.lookupTopLevelClass(name, inProgram, false);
        env = Env.extendFrameC(env, c);
        (cache, env, ih) = implicitFunctionInstantiation(cache, env, ih,
          DAE.NOMOD(), Prefix.NOPRE(), c, {});
      then
        (cache, env, ih);

  end matchcontinue;
end instFunctionInProgramImplicit;

public function instantiateExternalObject
"instantiate an external object.
 This is done by instantiating the destructor and constructor
 functions and create a DAE element containing these two."
  input Env.Cache inCache;
  input Env.Env env "environment";
  input InnerOuter.InstHierarchy inIH;
  input list<SCode.Element> els "elements";
  input Boolean impl;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output DAE.DAElist dae "resulting dae";
  output ClassInf.State ciState;
algorithm
  (outCache,outEnv,outIH,dae,ciState) := matchcontinue(inCache,env,inIH,els,impl)
    local
      SCode.Element destr,constr;
      Env.Env env1;
      Env.Cache cache;
      Ident className;
      Absyn.Path classNameFQ;
      DAE.Type functp;
      Env.Frame f;
      list<Env.Frame> fs,fs1;
      InstanceHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      // Explicit instantiation, generate constructor and destructor and the function type.
    case  (cache,_,ih,_,false)
      equation
        destr = SCode.getExternalObjectDestructor(els);
        constr = SCode.getExternalObjectConstructor(els);
        (cache,ih) = instantiateExternalObjectDestructor(cache,env,ih,destr);
        (cache,ih,functp) = instantiateExternalObjectConstructor(cache,env,ih,constr);
        className=Env.getClassName(env); // The external object classname is in top frame of environment.
        SOME(classNameFQ)= Env.getEnvPath(env); // Fully qualified classname
        // Extend the frame with the type, one frame up at the same place as the class.
        f::fs = env;
        fs1 = Env.extendFrameT(fs,className,functp);
        env1 = f::fs1;

        // set the  of this element
       source = DAEUtil.addElementSourcePartOfOpt(DAE.emptyElementSource, Env.getEnvPath(env));
      then
        (cache,env1,ih,DAE.DAE({DAE.EXTOBJECTCLASS(classNameFQ,source)}),ClassInf.EXTERNAL_OBJ(classNameFQ));

    // Implicit, do not instantiate constructor and destructor.
    case (cache,_,ih,_,true)
      equation
        SOME(classNameFQ)= Env.getEnvPath(env); // Fully qualified classname
      then
        (cache,env,ih,DAE.emptyDae,ClassInf.EXTERNAL_OBJ(classNameFQ));

    // failed
    case (_,_,_,_,_)
      equation
        print("Inst.instantiateExternalObject failed\n");
      then fail();
  end matchcontinue;
end instantiateExternalObject;

protected function instantiateExternalObjectDestructor
"instantiates the destructor function of an external object"
  input Env.Cache inCache;
  input Env.Env env;
  input InnerOuter.InstHierarchy inIH;
  input SCode.Element cl;
  output Env.Cache outCache;
  output InnerOuter.InstHierarchy outIH;
algorithm
  (outCache,outIH) := matchcontinue (inCache,env,inIH,cl)
    local
      Env.Cache cache;
      Env.Env env1;
      InstanceHierarchy ih;

    case (cache,_,ih,_)
      equation
        (cache,env1,ih) = implicitFunctionInstantiation(cache,env,ih,DAE.NOMOD(),Prefix.NOPRE(),cl,{});
      then
        (cache,ih);
    // failure
    case (_,_,_,_)
      equation
        print("Inst.instantiateExternalObjectDestructor failed\n");
      then fail();
   end matchcontinue;
end instantiateExternalObjectDestructor;

protected function instantiateExternalObjectConstructor
"instantiates the constructor function of an external object"
  input Env.Cache inCache;
  input Env.Env env;
  input InnerOuter.InstHierarchy inIH;
  input SCode.Element cl;
  output Env.Cache outCache;
  output InnerOuter.InstHierarchy outIH;
  output DAE.Type outType;
algorithm
  (outCache,outIH,outType) := matchcontinue (inCache,env,inIH,cl)
    local
      Env.Cache cache;
      Env.Env env1;
      DAE.Type ty;
      InstanceHierarchy ih;

    case (cache,_,ih,_)
      equation
        (cache,env1,ih) = implicitFunctionInstantiation(cache,env,ih, DAE.NOMOD(), Prefix.NOPRE(), cl, {});
        (cache,ty,_) = Lookup.lookupType(cache,env1,Absyn.IDENT("constructor"),NONE());
      then
        (cache,ih,ty);
    case (_,_,_,_)
      equation
        print("Inst.instantiateExternalObjectConstructor failed\n");
      then fail();
  end matchcontinue;
end instantiateExternalObjectConstructor;

public function implicitFunctionInstantiation
"This function instantiates a function, which is performed *implicitly*
  since the variables of a function should not be instantiated as for an
  ordinary class."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input SCode.Element inClass;
  input list<list<DAE.Subscript>>inInstDims;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
algorithm
  (outCache,outEnv,outIH):= match (inCache,inEnv,inIH,inMod,inPrefix,inClass,inInstDims)
    local
      DAE.Type ty1;
      list<Env.Frame> env,cenv;
      Absyn.Path fpath;
      DAE.Mod mod;
      Prefix.Prefix pre;
      SCode.Element c;
      String n;
      InstDims inst_dims;
      Env.Cache cache;
      InstanceHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      list<DAE.Function> funs;
      DAE.Function fun;
      SCode.Restriction r;
      SCode.Partial pPrefix;

    case (cache,env,ih,mod,pre,(c as SCode.CLASS(name = n,restriction = SCode.R_RECORD(_), partialPrefix = pPrefix)),inst_dims)
      equation
        (cache,c,cenv) = Lookup.lookupRecordConstructorClass(cache,env,Absyn.IDENT(n));
        (cache,env,ih,{DAE.FUNCTION(fpath,_,ty1,_,_,_,source,_)}) = implicitFunctionInstantiation2(cache,cenv,ih,mod,pre,c,inst_dims,true);
        // fpath = Absyn.makeFullyQualified(fpath);
        fun = DAE.RECORD_CONSTRUCTOR(fpath,ty1,source);
        cache = InstUtil.addFunctionsToDAE(cache, {fun}, pPrefix);
      then (cache,env,ih);

    case (cache,env,ih,mod,pre,(c as SCode.CLASS(name = _,restriction = r,partialPrefix = pPrefix)),inst_dims)
      equation
        failure(SCode.R_RECORD(_) = r);
        true = MetaUtil.strictRMLCheck(Flags.isSet(Flags.STRICT_RML),c);
        (cache,env,ih,funs) = implicitFunctionInstantiation2(cache,env,ih,mod,pre,c,inst_dims,false);
        cache = InstUtil.addFunctionsToDAE(cache, funs, pPrefix);
      then (cache,env,ih);

    // handle failure
    case (_,env,_,_,_,SCode.CLASS(name=n),_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Inst.implicitFunctionInstantiation failed " +& n);
        Debug.traceln("  Scope: " +& Env.printEnvPathStr(env));
      then fail();
  end match;
end implicitFunctionInstantiation;

protected function implicitFunctionInstantiation2
"This function instantiates a function, which is performed *implicitly*
  since the variables of a function should not be instantiated as for an
  ordinary class."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input SCode.Element inClass;
  input list<list<DAE.Subscript>>inInstDims;
  input Boolean instFunctionTypeOnly "if true, do no additional checking of the function";
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output list<DAE.Function> funcs;
algorithm
  (outCache,outEnv,outIH,funcs):= matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inClass,inInstDims,instFunctionTypeOnly)
    local
      DAE.Type ty,ty1;
      ClassInf.State st;
      list<Env.Frame> env_1,env,tempenv,cenv;
      Absyn.Path fpath;
      DAE.Mod mod;
      Prefix.Prefix pre;
      SCode.Element c;
      String n;
      InstDims inst_dims;
      SCode.Visibility vis;
      SCode.Partial partialPrefix;
      SCode.Encapsulated encapsulatedPrefix;
      DAE.ExternalDecl extdecl;
      SCode.Restriction restr;
      SCode.ClassDef parts;
      list<SCode.Element> els;
      list<Absyn.Path> funcnames;
      Env.Cache cache;
      InstanceHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      list<DAE.Element> daeElts;
      list<DAE.Function> resfns;
      list<DAE.FunctionDefinition> derFuncs;
      Absyn.Info info;
      DAE.InlineType inlineType;
      SCode.ClassDef cd;
      Boolean partialPrefixBool, isImpure;
      SCode.Comment cmt;
      SCode.FunctionRestriction funcRest;

    // normal functions
    case (cache,env,ih,mod,pre,SCode.CLASS(classDef=cd,partialPrefix = partialPrefix, name = n,restriction = SCode.R_FUNCTION(funcRest),info = info,cmt=cmt),inst_dims,_)
      equation
        false = SCode.isExternalFunctionRestriction(funcRest);
        isImpure = SCode.isImpureFunctionRestriction(funcRest);

        // if we're not MetaModelica set it to non-partial
        c = Util.if_(Config.acceptMetaModelicaGrammar(),
                     inClass,
                     SCode.setClassPartialPrefix(SCode.NOT_PARTIAL(), inClass));
        (cache,cenv,ih,_,DAE.DAE(daeElts),_,ty,_,_,_) =
          Inst.instClass(cache, env, ih, UnitAbsynBuilder.emptyInstStore(), mod, pre,
            c, inst_dims, true, InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, Connect.emptySet);
        List.map2_0(daeElts,InstUtil.checkFunctionElement,false,info);
        env_1 = Env.extendFrameC(env,c);
        (cache,fpath) = Inst.makeFullyQualified(cache, env_1, Absyn.IDENT(n));
        cmt = InstUtil.extractClassDefComment(cache, env, cd, cmt);
        derFuncs = InstUtil.getDeriveAnnotation(cd, cmt,fpath,cache,cenv,ih,pre,info);

        (cache) = instantiateDerivativeFuncs(cache,env,ih,derFuncs,fpath,info);

        ty1 = InstUtil.setFullyQualifiedTypename(ty,fpath);
        env_1 = Env.extendFrameT(env_1, n, ty1);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        inlineType = InstUtil.isInlineFunc(c);
        partialPrefixBool = SCode.partialBool(partialPrefix);

        daeElts = InstUtil.optimizeFunctionCheckForLocals(fpath,daeElts,NONE(),{},{},{});
        InstUtil.checkFunctionDefUse(daeElts,info);
        /* Not working 100% yet... Also, a lot of code has unused inputs :( */
        Debug.bcall3(
          false and Config.acceptMetaModelicaGrammar() and not instFunctionTypeOnly,
          InstUtil.checkFunctionInputUsed,daeElts,NONE(),Absyn.pathString(fpath));
      then
        (cache,env_1,ih,{DAE.FUNCTION(fpath,DAE.FUNCTION_DEF(daeElts)::derFuncs,ty1,partialPrefixBool,isImpure,inlineType,source,SOME(cmt))});

    // External functions should also have their type in env, but no dae.
    case (cache,env,ih,mod,pre,(c as SCode.CLASS(partialPrefix=partialPrefix,name = n,restriction = (restr as SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION(isImpure))),
        classDef = cd as (parts as SCode.PARTS(elementLst = _)), cmt=cmt, info=info, encapsulatedPrefix = encapsulatedPrefix)),inst_dims,_)
      equation
        (cache,cenv,ih,_,DAE.DAE(daeElts),_,ty,_,_,_) =
          Inst.instClass(cache,env,ih, UnitAbsynBuilder.emptyInstStore(),mod, pre,
            c, inst_dims, true, InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, Connect.emptySet);
        List.map2_0(daeElts,InstUtil.checkFunctionElement,true,info);
        //env_11 = Env.extendFrameC(cenv,c);
        // Only created to be able to get FQ path.
        (cache,fpath) = Inst.makeFullyQualified(cache,cenv, Absyn.IDENT(n));

        cmt = InstUtil.extractClassDefComment(cache, env, cd, cmt);
        derFuncs = InstUtil.getDeriveAnnotation(cd,cmt,fpath,cache,env,ih,pre,info);

        (cache) = instantiateDerivativeFuncs(cache,env,ih,derFuncs,fpath,info);

        ty1 = InstUtil.setFullyQualifiedTypename(ty,fpath);
        ((ty1,_)) = Types.traverseType((ty1,-1),Types.makeExpDimensionsUnknown);
        env_1 = Env.extendFrameT(cenv, n, ty1);
        vis = SCode.PUBLIC();
        (cache,tempenv,ih,_,_,_,_,_,_,_,_,_) =
          Inst.instClassdef(cache, env_1, ih, UnitAbsyn.noStore, mod, pre,
            ClassInf.FUNCTION(fpath,isImpure), n,parts, restr, vis, partialPrefix,
            encapsulatedPrefix, inst_dims, true, InstTypes.INNER_CALL(),
            ConnectionGraph.EMPTY, Connect.emptySet, NONE(),info) "how to get this? impl" ;
        (cache,ih,extdecl) = instExtDecl(cache, tempenv,ih, n, parts, true, pre,info) "impl" ;

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        partialPrefixBool = SCode.partialBool(partialPrefix);
        InstUtil.checkExternalFunction(daeElts,extdecl,Absyn.pathString(fpath));
      then
        (cache,env_1,ih,{DAE.FUNCTION(fpath,DAE.FUNCTION_EXT(daeElts,extdecl)::derFuncs,ty1,partialPrefixBool,isImpure,DAE.NO_INLINE(),source,SOME(cmt))});

    // Instantiate overloaded functions
    case (cache,env,ih,_,pre,(SCode.CLASS(name = n,restriction = (SCode.R_FUNCTION(SCode.FR_NORMAL_FUNCTION(isImpure))),
          classDef = SCode.OVERLOAD(pathLst = funcnames),cmt=cmt)),_,_)
      equation
        (cache,env,ih,resfns) = instOverloadedFunctions(cache,env,ih,pre,funcnames) "Overloaded functions" ;
        (cache,fpath) = Inst.makeFullyQualified(cache,env,Absyn.IDENT(n));
        resfns = DAE.FUNCTION(fpath,{DAE.FUNCTION_DEF({})},DAE.T_UNKNOWN_DEFAULT,true,isImpure,DAE.NO_INLINE(),DAE.emptyElementSource,SOME(cmt))::resfns;
      then
        (cache,env,ih,resfns);

    // handle failure
    case (_,env,_,_,_,SCode.CLASS(name=n),_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Inst.implicitFunctionInstantiation2 failed " +& n);
        Debug.traceln("  Scope: " +& Env.printEnvPathStr(env));
      then fail();
  end matchcontinue;
end implicitFunctionInstantiation2;

protected function instantiateDerivativeFuncs "instantiates all functions found in derivative annotations so they are also added to the
dae and can be generated code for in case they are required"
  input Env.Cache cache;
  input Env.Env env;
  input InnerOuter.InstHierarchy ih;
  input list<DAE.FunctionDefinition> funcs;
  input Absyn.Path path "the function name itself, must be added to derivative functions mapping to be able to search upwards";
  input Absyn.Info info;
  output Env.Cache outCache;
algorithm
 // print("instantiate deriative functions for "+&Absyn.pathString(path)+&"\n");
 (outCache) := instantiateDerivativeFuncs2(cache,env,ih,DAEUtil.getDerivativePaths(funcs),path,info);
 // print("instantiated derivative functions for "+&Absyn.pathString(path)+&"\n");
end instantiateDerivativeFuncs;

protected function instantiateDerivativeFuncs2 "help function"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input list<Absyn.Path> inPaths;
  input Absyn.Path path "the function name itself, must be added to derivative functions mapping to be able to search upwards";
  input Absyn.Info info;
  output Env.Cache outCache;
algorithm
  (outCache) := matchcontinue(inCache,inEnv,inIH,inPaths,path,info)
    local
      list<DAE.Function> funcs;
      Absyn.Path p;
      Env.Cache cache;
      Env.Env cenv,env;
      InstanceHierarchy ih;
      SCode.Element cdef;
      list<Absyn.Path> paths;
      String fun,scope;

    case(cache,_,_,{},_,_) then (cache);

    // Skipped recursive calls (by looking in cache)
    case(cache,env,ih,p::paths,_,_)
      equation
        (cache,cdef,cenv) = Lookup.lookupClass(cache,env,p,true);
        (cache,p) = Inst.makeFullyQualified(cache,cenv,p);
        Env.checkCachedInstFuncGuard(cache,p);
      then instantiateDerivativeFuncs2(cache,env,ih,paths,path,info);

    case(cache,env,ih,p::paths,_,_)
      equation
        (cache,cdef,cenv) = Lookup.lookupClass(cache,env,p,true);
        (cache,p) = Inst.makeFullyQualified(cache,cenv,p);
        // add to cache before instantiating, to break recursion for recursive definitions.
        cache = Env.addCachedInstFuncGuard(cache,p);
        (cache,_,ih,funcs) =
        implicitFunctionInstantiation2(cache,cenv,ih,DAE.NOMOD(),Prefix.NOPRE(),cdef,{},false);

        funcs = InstUtil.addNameToDerivativeMapping(funcs,path);
        cache = Env.addDaeFunction(cache, funcs);
      then instantiateDerivativeFuncs2(cache,env,ih,paths,path,info);

    else
      equation
        p :: _ = inPaths;
        fun = Absyn.pathString(p);
        scope = Env.printEnvPathStr(inEnv);
        Error.addSourceMessage(Error.LOOKUP_FUNCTION_ERROR,{fun,scope},info);
      then fail();

  end matchcontinue;
end instantiateDerivativeFuncs2;

public function implicitFunctionTypeInstantiation
"author: PA
  When looking up a function type it is sufficient to only instantiate the input and output arguments of the function.
  The implicitFunctionInstantiation function will instantiate the function body, resulting in a DAE for the body.
  This function does not do that. Therefore this function is the only solution available for recursive functions,
  where the function body contain a call to the function itself.

  Extended 2007-06-29, BZ
  Now this function also handles Derived function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input SCode.Element inClass;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
algorithm
  (outCache,outEnv,outIH) := matchcontinue (inCache,inEnv,inIH,inClass)
    local
      SCode.Element stripped_class;
      list<Env.Frame> env_1,env;
      String id,cn2;
      SCode.Partial p;
      SCode.Encapsulated e;
      SCode.Restriction r;
      Option<SCode.ExternalDecl> extDecl;
      list<SCode.Element> elts, stripped_elts;
      Env.Cache cache;
      InstanceHierarchy ih;
      list<SCode.Annotation> annotationLst;
      Absyn.Info info;
      DAE.DAElist dae;
      list<DAE.Function> funs;
      Absyn.Path cn,fpath;
      Option<list<Absyn.Subscript>> ad;
      SCode.Mod mod1;
      DAE.Mod mod2;
      Env.Env cenv;
      SCode.Element c;
      DAE.Type ty1,ty;
      SCode.Prefixes prefixes;
      SCode.Comment cmt;
      list<Absyn.Path> paths;

    // For external functions, include everything essential
    case (cache,env,ih,SCode.CLASS(name = _,prefixes = prefixes,
                                   encapsulatedPrefix = _,partialPrefix = _,restriction = SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION(_)),
                                   classDef = SCode.PARTS(elementLst = _,externalDecl=_),cmt=cmt, info = info))
      equation
        // stripped_class = SCode.CLASS(id,prefixes,e,p,r,SCode.PARTS(elts,{},{},{},{},{},{},extDecl),cmt,info);
        (cache,env_1,ih,funs) = implicitFunctionInstantiation2(cache, env, ih, DAE.NOMOD(), Prefix.NOPRE(), inClass, {}, true);
        // Only external functions are valid without an algorithm section... 
        cache = Env.addDaeExtFunction(cache, funs);
      then
        (cache,env_1,ih);

    // The function type can be determined without the body. Annotations need to be preserved though.
    case (cache,env,ih,SCode.CLASS(name = id,prefixes = prefixes,
                                   encapsulatedPrefix = e,partialPrefix = p,restriction = _,
                                   classDef = SCode.PARTS(elementLst = elts,externalDecl=_),cmt=cmt, info = info))
      equation
        elts = List.select(elts,isElementImportForFunctions);
        stripped_class = SCode.CLASS(id,prefixes,e,p,SCode.R_FUNCTION(SCode.FR_NORMAL_FUNCTION(false)),SCode.PARTS(elts,{},{},{},{},{},{},NONE()),cmt,info);
        (cache,env_1,ih,funs) = implicitFunctionInstantiation2(cache, env, ih, DAE.NOMOD(), Prefix.NOPRE(), stripped_class, {}, true);
        // Only external functions are valid without an algorithm section... 
        // cache = Env.addDaeExtFunction(cache, funs);
      then
        (cache,env_1,ih);

    // Short class definitions.
    case (cache,env,ih,SCode.CLASS(name = id,partialPrefix = _,encapsulatedPrefix = _,restriction = _,
                                   classDef = SCode.DERIVED(typeSpec = Absyn.TPATH(path = cn,arrayDim = _),
                                                            modifications = mod1),info = info))
      equation
        (cache,(c as SCode.CLASS(name = _, restriction = _)),cenv) = Lookup.lookupClass(cache, env, cn, false /* Makes MultiBody gravityacceleration hacks shit itself */);
        (cache,mod2) = Mod.elabMod(cache, env, ih, Prefix.NOPRE(), mod1, false, info);
        
        (cache,_,ih,_,dae,_,ty,_,_,_) =
          Inst.instClass(cache,cenv,ih,UnitAbsynBuilder.emptyInstStore(), mod2,
            Prefix.NOPRE(), c, {}, true, InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, Connect.emptySet);
        
        env_1 = Env.extendFrameC(env,c);
        (cache,fpath) = Inst.makeFullyQualified(cache,env_1, Absyn.IDENT(id));
        ty1 = InstUtil.setFullyQualifiedTypename(ty,fpath);
        env_1 = Env.extendFrameT(env_1, id, ty1);
      then
        (cache,env_1,ih);

    case (cache,env,ih,SCode.CLASS(name = _,partialPrefix = _,encapsulatedPrefix = _,restriction = _,
                                   classDef = SCode.OVERLOAD(pathLst=_),info = info))
      equation
         //(cache,env,ih,_) = implicitFunctionInstantiation2(cache, env, ih, DAE.NOMOD(), Prefix.NOPRE(), inClass, {}, true);          
      then
        (cache,env,ih);

    case (_,_,_,SCode.CLASS(name=id))
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Inst.implicitFunctionTypeInstantiation failed " +& id +& "\nenv: " +& Env.getEnvNameStr(inEnv) +& "\nelelement: " +& SCodeDump.unparseElementStr(inClass,SCodeDump.defaultOptions));
      then fail();
  end matchcontinue;
end implicitFunctionTypeInstantiation;

protected function instOverloadedFunctions
"This function instantiates the functions in the overload list of a
  overloading function definition and register the function types using
  the overloaded name. It also creates dae elements for the functions."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix pre;
  input list<Absyn.Path> inAbsynPathLst;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output list<DAE.Function> outFns;
algorithm
  (outCache,outEnv,outIH,outFns) := matchcontinue (inCache,inEnv,inIH,pre,inAbsynPathLst)
    local
      list<Env.Frame> env,cenv;
      SCode.Element c;
      String id;
      SCode.Encapsulated encflag;
      Absyn.Path fn;
      list<Absyn.Path> fns;
      Env.Cache cache;
      InstanceHierarchy ih;
      SCode.Partial partialPrefix;
      Absyn.Info info;
      list<DAE.Function> resfns1,resfns2;
      SCode.Restriction rest;

    case (cache,_,ih,_,{}) then (cache,inEnv,ih,{});

    // Instantiate each function, add its FQ name to the type, needed when deoverloading
    case (cache,env,ih,_,(fn :: fns))
      equation
        // print("instOvl: " +& Absyn.pathString(fn) +& "\n");
        (cache,(c as SCode.CLASS(name=_,partialPrefix=partialPrefix,encapsulatedPrefix=_,restriction=rest,info=info)),cenv) = 
           Lookup.lookupClass(cache, env, fn, true);
        true = SCode.isFunctionRestriction(rest);
        
        (cache,env,ih,resfns1) = implicitFunctionInstantiation2(inCache, cenv, inIH, DAE.NOMOD(), pre, c, {}, false);
        (cache,env,ih,resfns2) = instOverloadedFunctions(cache,env,ih,pre,fns);
      then (cache,env,ih,listAppend(resfns1,resfns2));

    // failure
    case (_,_,_,_,(fn :: _))
      equation
        Debug.fprint(Flags.FAILTRACE, "- Inst.instOverloaded_functions failed " +& Absyn.pathString(fn) +& "\n");
      then
        fail();
  end matchcontinue;
end instOverloadedFunctions;

protected function instExtDecl
"author: LS
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
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input String inIdent;
  input SCode.ClassDef inClassDef;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output InnerOuter.InstHierarchy outIH;
  output DAE.ExternalDecl outExternalDecl;
algorithm
  (outCache,outIH,outExternalDecl) := matchcontinue (inCache,inEnv,inIH,inIdent,inClassDef,inBoolean,inPrefix,info)
    local
      String fname,lang,n;
      list<DAE.ExtArg> fargs;
      DAE.ExtArg rettype;
      Option<SCode.Annotation> ann;
      DAE.ExternalDecl daeextdecl;
      list<Env.Frame> env;
      SCode.ExternalDecl extdecl,orgextdecl;
      Boolean impl;
      list<SCode.Element> els;
      Env.Cache cache;
      InstanceHierarchy ih;
      Prefix.Prefix pre;

    case (cache,env,ih,n,SCode.PARTS(elementLst=_,externalDecl = SOME(extdecl)),impl,pre,_) /* impl */
      equation
        InstUtil.isExtExplicitCall(extdecl);
        fname = InstUtil.instExtGetFname(extdecl, n);
        (cache,fargs) = InstUtil.instExtGetFargs(cache,env, extdecl, impl,pre,info);
        (cache,rettype) = InstUtil.instExtGetRettype(cache,env, extdecl, impl,pre,info);
        lang = InstUtil.instExtGetLang(extdecl);
        ann = InstUtil.instExtGetAnnotation(extdecl);
        daeextdecl = DAE.EXTERNALDECL(fname,fargs,rettype,lang,ann);
      then
        (cache,ih,daeextdecl);

    case (cache,env,ih,n,SCode.PARTS(elementLst = els,externalDecl = SOME(orgextdecl)),impl,pre,_)
      equation
        failure(InstUtil.isExtExplicitCall(orgextdecl));
        extdecl = InstUtil.instExtMakeExternaldecl(n, els, orgextdecl);
        (fname) = InstUtil.instExtGetFname(extdecl, n);
        (cache,fargs) = InstUtil.instExtGetFargs(cache,env, extdecl, impl,pre,info);
        (cache,rettype) = InstUtil.instExtGetRettype(cache,env, extdecl, impl,pre,info);
        lang = InstUtil.instExtGetLang(extdecl);
        ann = InstUtil.instExtGetAnnotation(orgextdecl);
        daeextdecl = DAE.EXTERNALDECL(fname,fargs,rettype,lang,ann);
      then
        (cache,ih,daeextdecl);
    case (_,_,_,_,_,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "#-- Inst.instExtDecl failed");
      then
        fail();
  
  end matchcontinue;
end instExtDecl;

public function instRecordConstructorElt
"author: PA
  This function takes an Env and an Element and builds a input argument to
  a record constructor.
  E.g if the element is Real x; the resulting Var is \"input Real x;\""
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input SCode.Element inElement;
  input DAE.Mod outerMod;
  input Boolean inImplicit;
  output Env.Cache outCache;
  output InnerOuter.InstHierarchy outIH;
  output DAE.Var outVar;
algorithm
  (outCache,outIH,outVar) :=
  matchcontinue (inCache,inEnv,inIH,inElement,outerMod,inImplicit)
    local
      SCode.Element cl;
      Env.Env cenv,env,compenv;
      DAE.Mod mod_1;
      Absyn.ComponentRef owncref;
      DAE.Dimensions dimexp;
      DAE.Type tp_1;
      DAE.Binding bind;
      String id;
      SCode.Replaceable repl;
      SCode.Visibility vis;
      SCode.ConnectorType ct;
      Boolean impl;
      SCode.Attributes attr;
      list<Absyn.Subscript> dim;
      SCode.Parallelism prl;
      SCode.Variability var;
      Absyn.Direction dir;
      Absyn.Path t;
      SCode.Mod mod;
      SCode.Comment comment;
      SCode.Element elt;
      Env.Cache cache;
      Absyn.InnerOuter io;
      SCode.Final finalPrefix;
      Absyn.Info info;
      InstanceHierarchy ih;
      Option<Absyn.ConstrainClass> cc;
      SCode.Prefixes prefixes;

    case (cache,env,ih,
          SCode.COMPONENT(name = id,
                          prefixes = prefixes as SCode.PREFIXES(
                            replaceablePrefix = _,
                            visibility = vis,
                            finalPrefix = finalPrefix,
                            innerOuter = _
                          ),
                          attributes = (attr as
                          SCode.ATTR(arrayDims = dim, connectorType = ct,
                                     parallelism = prl,variability = var,direction = dir)),
                          typeSpec = Absyn.TPATH(t, _),modifications = mod,
                          comment = comment,
                          info = info),
          _,impl)
      equation
        // - Prefixes (constant, parameter, final, discrete, input, output, ...) of the remaining record components are removed.
        var = SCode.VAR();
        dir = Absyn.INPUT();
        attr = SCode.ATTR(dim,ct,prl,var,dir);

        (cache,cl,cenv) = Lookup.lookupClass(cache,env, t, true);
        (cache,mod_1) = Mod.elabMod(cache, env, ih, Prefix.NOPRE(), mod, impl, info);
        mod_1 = Mod.merge(outerMod,mod_1,cenv,Prefix.NOPRE());
        owncref = Absyn.CREF_IDENT(id,{});
        (cache,dimexp) = InstUtil.elabArraydim(cache, env, owncref, t, dim, NONE(), false, NONE(), true, false, Prefix.NOPRE(), info, {});

        cenv = Env.mergeEnv(cenv, env, id, cl, Env.M(Prefix.NOPRE(), id, dim, mod_1, env, {}));
        cenv = Env.addModification(cenv, Env.M(Prefix.NOPRE(), id, dim, mod_1, env, {}));
        (cache,compenv,ih,_,_,_,tp_1,_) = InstVar.instVar(cache, cenv, ih, UnitAbsyn.noStore, ClassInf.FUNCTION(Absyn.IDENT(""), false), mod_1, Prefix.NOPRE(),
          id, cl, attr, prefixes, dimexp, {}, {}, impl, comment, info, ConnectionGraph.EMPTY, Connect.emptySet, env);
        (compenv, env) = Env.splitEnv(compenv, env, id);
        
        (cache,bind) = InstBinding.makeBinding(cache,env, attr, mod_1, tp_1, Prefix.NOPRE(), id, info);
      then
        (cache,ih,DAE.TYPES_VAR(id,DAE.ATTR(ct,prl,var,dir,Absyn.NOT_INNER_OUTER(),vis),tp_1,bind,NONE()));

    case (_,_,_,elt,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Inst.instRecordConstructorElt failed.,elt:");
        Debug.traceln(SCodeDump.unparseElementStr(elt,SCodeDump.defaultOptions));
      then
        fail();
  end matchcontinue;
end instRecordConstructorElt;

public function getRecordConstructorFunction
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output Env.Cache outCache;
  output DAE.Function outFunc;
algorithm
  (outCache,outFunc)  := matchcontinue (inCache,inEnv,inPath)
    local
      Absyn.Path path;
      SCode.Element recordCl;
      Env.Env recordEnv;
      DAE.Function func;
      Env.Cache cache;
      DAE.Type recType,fixedTy,funcTy;
      list<DAE.Var> vars, inputs, locals;
      list<DAE.FuncArg> fargs;
      DAE.EqualityConstraint eqCo;
      DAE.TypeSource src;

      case(_, _, _)
        equation
          path = Absyn.makeFullyQualified(inPath);
          func = Env.getCachedInstFunc(inCache,path);
        then
          (inCache,func);

      case(_, _, _)
        equation

          (_,recordCl,recordEnv) = Lookup.lookupClass(inCache, inEnv, inPath, false);
          true = SCode.isRecord(recordCl);

          (cache,_,_,_,_,_,recType,_,_,_) = Inst.instClass(inCache,recordEnv, InnerOuter.emptyInstHierarchy,
            UnitAbsynBuilder.emptyInstStore(), DAE.NOMOD(), Prefix.NOPRE(), recordCl,
            {}, true, InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, Connect.emptySet);
          DAE.T_COMPLEX(ClassInf.RECORD(path), vars, eqCo, src) = recType;

          (inputs,locals) = List.extractOnTrue(vars, Types.isModifiableTypesVar);
          inputs = List.map(inputs,Types.setVarDefaultInput);
          locals = List.map(locals,Types.setVarProtected);
          vars = listAppend(inputs,locals);

          path = Absyn.makeFullyQualified(path);

          fixedTy = DAE.T_COMPLEX(ClassInf.RECORD(path), vars, eqCo, src);
          fargs = Types.makeFargsList(inputs);
          funcTy = DAE.T_FUNCTION(fargs, fixedTy, DAE.FUNCTION_ATTRIBUTES_DEFAULT, {path});
          func = DAE.RECORD_CONSTRUCTOR(path,funcTy,DAE.emptyElementSource);

          cache = InstUtil.addFunctionsToDAE(cache, {func}, SCode.NOT_PARTIAL());
        then
          (cache,func);

      case(_, _, _)
        equation
          true = Flags.isSet(Flags.FAILTRACE);
          Debug.fprint(Flags.FAILTRACE, "Inst.getRecordConstructorFunction failed for " +& Absyn.pathString(inPath) +& "\n");
        then
          fail();

  end matchcontinue;

end getRecordConstructorFunction;

public function addRecordConstructorFunction "Add record constructor whenever we instantiate a variable. Needed so we can cast to this constructor freely."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Type inType;
  output Env.Cache outCache;
algorithm
  outCache := matchcontinue (inCache,inEnv,inType)
    local
      list<DAE.Var> vars, inputs, locals;
      DAE.Type ty,recType,fixedTy,funcTy;
      DAE.EqualityConstraint eqCo;
      DAE.TypeSource src;
      Env.Cache cache;
      Absyn.Path path;
      SCode.Element recordCl;
      Env.Env recordEnv;
      DAE.Function func;
      list<DAE.FuncArg> fargs;

    // try to instantiate class
    case (cache, _, DAE.T_COMPLEX(ClassInf.RECORD(path), _, _, _))
      equation
        path = Absyn.makeFullyQualified(path);
        (cache, _) = getRecordConstructorFunction(cache, inEnv, path);
      then
        cache;
    
    // if previous stuff didn't work, try to use the ty directly
    case (cache, _, DAE.T_COMPLEX(ClassInf.RECORD(path), vars, eqCo, src))
      equation
        path = Absyn.makeFullyQualified(path);
        //(cache, _) = getRecordConstructorFunction(cache, inEnv, path);
        
        (inputs,locals) = List.extractOnTrue(vars, Types.isModifiableTypesVar);
        inputs = List.map(inputs,Types.setVarDefaultInput);
        locals = List.map(locals,Types.setVarProtected);
        vars = listAppend(inputs,locals);
                
        fixedTy = DAE.T_COMPLEX(ClassInf.RECORD(path), vars, eqCo, src);
        fargs = Types.makeFargsList(inputs);
        funcTy = DAE.T_FUNCTION(fargs, fixedTy, DAE.FUNCTION_ATTRIBUTES_DEFAULT, {path});
        func = DAE.RECORD_CONSTRUCTOR(path,funcTy,DAE.emptyElementSource);
        
        cache = InstUtil.addFunctionsToDAE(cache, {func}, SCode.NOT_PARTIAL());
      then
        (cache);
    
    else inCache;

  end matchcontinue;
end addRecordConstructorFunction;

protected function isElementImportForFunctions
  input SCode.Element elt;
  output Boolean b;
algorithm
  b := match elt
    case SCode.COMPONENT(prefixes=SCode.PREFIXES(visibility=SCode.PROTECTED()),
                         attributes=SCode.ATTR(direction=Absyn.BIDIR(),variability=SCode.VAR()))
      then false;
    else true;
  end match;
end isElementImportForFunctions;

end InstFunction;
