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

encapsulated package InstVar
" file:        InstVar.mo
  package:     InstVar
  description: Model instantiation

  RCS: $Id: InstVar.mo 17556 2013-10-05 23:58:57Z adrpo $

  This module is responsible for instantiation of Modelica components.

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

protected import Config;
protected import Debug;
protected import Dump;
protected import DAEUtil;
protected import Inst;
protected import InstBinding;
protected import InstDAE;
protected import InstFunction;
protected import InstSection;
protected import InstUtil;
protected import Util;
protected import Types;
protected import PrefixUtil;
protected import List;
protected import ComponentReference;
protected import NFInstUtil;
protected import UnitAbsynBuilder;
protected import Flags;
protected import Expression;
protected import ExpressionDump;
protected import Error;
protected import ErrorExt;
protected import Lookup;
protected import SCodeDump;

protected type Ident = DAE.Ident "an identifier";
protected type InstanceHierarchy = InnerOuter.InstHierarchy "an instance hierarchy";
protected type InstDims = list<list<DAE.Subscript>>;

public function instVar
"this function will look if a variable is inner/outer and depending on that will:
  - lookup for inner in the instanance hieararchy if we have ONLY outer
  - instantiate normally via instVar_dispatch otherwise
  - report an error if we have modifications on outer"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input ClassInf.State inState;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input String inIdent;
  input SCode.Element inClass;
  input SCode.Attributes inAttributes;
  input SCode.Prefixes inPrefixes;
  input DAE.Dimensions inDimensionLst;
  input list<DAE.Subscript> inIntegerLst;
  input list<list<DAE.Subscript>>inInstDims;
  input Boolean inImpl;
  input SCode.Comment inComment;
  input Absyn.Info info;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  input Env.Env componentDefinitionParentEnv;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output DAE.Type outType;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
    (outCache,outEnv,outIH,outStore,outDae,outSets,outType,outGraph):=
    matchcontinue (inCache, inEnv, inIH, inStore, inState, inMod, inPrefix,
      inIdent, inClass, inAttributes, inPrefixes, inDimensionLst,
      inIntegerLst, inInstDims, inImpl, inComment, info, inGraph, inSets,
      componentDefinitionParentEnv)
    local
      DAE.Dimensions dims;
      list<Env.Frame> compenv,env,innerCompEnv,outerCompEnv;
      DAE.DAElist dae, outerDAE, innerDAE;
      Connect.Sets csets,csetsInner,csetsOuter;
      DAE.Type ty;
      ClassInf.State ci_state;
      DAE.Mod mod;
      Prefix.Prefix pre, innerPrefix;
      String n,s1,s2,s3,s;
      SCode.Element cl;
      SCode.Attributes attr;
      list<DAE.Subscript> idxs;
      InstDims inst_dims;
      Boolean impl;
      SCode.Comment comment;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      DAE.ComponentRef cref, crefOuter, crefInner;
      list<DAE.ComponentRef> outers;
      String nInner, typeName, fullName;
      Absyn.Path typePath;
      String innerScope;
      Absyn.InnerOuter io, ioInner;
      Option<InnerOuter.InstResult> instResult;
      SCode.Prefixes pf;
      UnitAbsyn.InstStore store;

    // is ONLY inner
    case (cache,env,ih,store,ci_state,mod,pre,n,cl as SCode.CLASS(name=typeName),attr,pf,dims,idxs,inst_dims,impl,comment,_,graph,csets,_)
      equation
        // only inner!
        io = SCode.prefixesInnerOuter(pf);
        true = Absyn.isOnlyInner(io);

        // Debug.fprintln(Flags.INNER_OUTER, "- Inst.instVar inner: " +& PrefixUtil.printPrefixStr(pre) +& "/" +& n +& " in env: " +& Env.printEnvPathStr(env));

        // instantiate as inner
        (cache,innerCompEnv,ih,store,dae,csets,ty,graph) =
          instVar_dispatch(cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,info,graph,csets);

        (cache,cref) = PrefixUtil.prefixCref(cache,env,ih,pre, ComponentReference.makeCrefIdent(n, DAE.T_UNKNOWN_DEFAULT, {}));
        fullName = ComponentReference.printComponentRefStr(cref);
        (cache, typePath) = Inst.makeFullyQualified(cache, env, Absyn.IDENT(typeName));

        // also all the components in the environment should be updated to be outer!
        // switch components from inner to outer in the component env.
        outerCompEnv = InnerOuter.switchInnerToOuterInEnv(innerCompEnv, cref);

        // outer doesn't generate a visible DAE
        outerDAE = DAE.emptyDae;

        innerScope = Env.printEnvPathStr(componentDefinitionParentEnv);

        // add to instance hierarchy
        ih = InnerOuter.updateInstHierarchy(ih, pre, io,
               InnerOuter.INST_INNER(
                  pre, // prefix
                  n, // component name,
                  io, // inner outer atttributes
                  fullName, // full component name
                  typePath, // fully qual type path
                  innerScope, // the scope,
                  SOME(InnerOuter.INST_RESULT(cache,outerCompEnv,store,outerDAE,csets,ty,graph)), // instantiation result
                  {}, // outers connected to this inner
                  NONE()
                  ));
      then
        (cache,innerCompEnv,ih,store,dae,csets,ty,graph);

    // is ONLY outer and it has modifications on it!
    case (cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,_,graph,csets,_)
      equation
        // only outer!
        io = SCode.prefixesInnerOuter(pf);
        true = Absyn.isOnlyOuter(io);

        // we should have here any kind of modification!
        false = Mod.modEqual(mod, DAE.NOMOD());
        (cache,cref) = PrefixUtil.prefixCref(cache,env,ih,pre, ComponentReference.makeCrefIdent(n, DAE.T_UNKNOWN_DEFAULT, {}));
        s1 = ComponentReference.printComponentRefStr(cref);
        s2 = Mod.prettyPrintMod(mod, 0);
        s = s1 +&  " " +& s2;
        // add a warning!
        Error.addSourceMessage(Error.OUTER_MODIFICATION, {s}, info);

        // call myself without any modification!
        (cache,compenv,ih,store,dae,csets,ty,graph) =
          instVar(cache,env,ih,store,ci_state,DAE.NOMOD(),pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,info,graph,csets,componentDefinitionParentEnv);
     then
        (cache,compenv,ih,store,dae,csets,ty,graph);

    // is ONLY outer
    case (cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,_,graph,csets,_)
      equation
        // only outer!
        io = SCode.prefixesInnerOuter(pf);
        true = Absyn.isOnlyOuter(io);

        // we should have NO modifications on only outer!
        true = Mod.modEqual(mod, DAE.NOMOD());

        // Debug.fprintln(Flags.INNER_OUTER, "- Inst.instVar outer: " +& PrefixUtil.printPrefixStr(pre) +& "/" +& n +& " in env: " +& Env.printEnvPathStr(env));

        // lookup in IH
        InnerOuter.INST_INNER(
           innerPrefix,
           nInner,
           ioInner,
           fullName,
           typePath,
           innerScope,
           instResult as SOME(InnerOuter.INST_RESULT(cache,compenv,store,outerDAE,_,ty,graph)),
           outers,_) =
          InnerOuter.lookupInnerVar(cache, env, ih, pre, n, io);

        // add outer prefix + component name and its corresponding inner prefix to the IH
        (cache,crefOuter) = PrefixUtil.prefixCref(cache,env,ih,pre, ComponentReference.makeCrefIdent(n, DAE.T_UNKNOWN_DEFAULT, {}));
        (cache,crefInner) = PrefixUtil.prefixCref(cache,env,ih,innerPrefix, ComponentReference.makeCrefIdent(n, DAE.T_UNKNOWN_DEFAULT, {}));
        ih = InnerOuter.addOuterPrefixToIH(ih, crefOuter, crefInner);
        outers = List.unionElt(crefOuter, outers);
        // update the inner with the outer for easy reference
        ih = InnerOuter.updateInstHierarchy(ih, innerPrefix, ioInner,
               InnerOuter.INST_INNER(
                  innerPrefix, // prefix
                  nInner, // component name,
                  ioInner, // inner outer atttributes
                  fullName, // full component name
                  typePath, // fully qual type path
                  innerScope, // the scope,
                  instResult,
                  outers, // outers connected to this inner
                  NONE()
                  ));

        // outer dae has no meaning!
        outerDAE = DAE.emptyDae;
      then
        (inCache /* we don't want to return the old, crappy cache as ours was newer */,compenv,ih,store,outerDAE,csets,ty,graph);

    // is ONLY outer and the inner was not yet set in the IH or we have no inner declaration!
    case (cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,_,graph, csets, _)
      equation
        // only outer!
        io = SCode.prefixesInnerOuter(pf);
        true = Absyn.isOnlyOuter(io);

        // no modifications!
        true = Mod.modEqual(mod, DAE.NOMOD());

        // lookup in IH, crap, we couldn't find it!
        // lookup in IH
        InnerOuter.INST_INNER(
           innerPrefix,
           nInner,
           ioInner,
           fullName,
           typePath,
           innerScope,
           instResult as NONE(),
           outers,_) =
          InnerOuter.lookupInnerVar(cache, env, ih, pre, n, io);

        // Debug.fprintln(Flags.INNER_OUTER, "- Inst.instVar failed to lookup inner: " +& PrefixUtil.printPrefixStr(pre) +& "/" +& n +& " in env: " +& Env.printEnvPathStr(env));

        // display an error message!
        (cache,crefOuter) = PrefixUtil.prefixCref(cache,env,ih,pre, ComponentReference.makeCrefIdent(n, DAE.T_UNKNOWN_DEFAULT, {}));
        s1 = ComponentReference.printComponentRefStr(crefOuter);
        s2 = Dump.unparseInnerouterStr(io);
        s3 = InnerOuter.getExistingInnerDeclarations(ih, componentDefinitionParentEnv);
        typeName = SCode.className(cl);
        (cache, typePath) = Inst.makeFullyQualified(cache, env, Absyn.IDENT(typeName));
        s1 = Absyn.pathString(typePath) +& " " +& s1;
        // adrpo: do NOT! display an error message if impl = true and prefix is Prefix.NOPRE()
        // print(Util.if_(impl, "impl crap\n", "no impl\n"));
        Debug.bcall(impl and listMember(pre, {Prefix.NOPRE()}), ErrorExt.setCheckpoint, "innerouter-instVar-implicit");
        Error.addSourceMessage(Error.MISSING_INNER_PREFIX,{s1, s2, s3}, info);
        Debug.bcall(impl and listMember(pre, {Prefix.NOPRE()}), ErrorExt.rollBack, "innerouter-instVar-implicit");

        // call it normaly
        (cache,compenv,ih,store,dae,_,ty,graph) =
          instVar_dispatch(cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,info,graph, csets);
      then
        (cache,compenv,ih,store,dae,csets,ty,graph);

    // is ONLY outer and the inner was not yet set in the IH or we have no inner declaration!
    case (cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,_,graph,csets,_)
      equation
        // only outer!
        io = SCode.prefixesInnerOuter(pf);
        true = Absyn.isOnlyOuter(io);

        // no modifications!
        true = Mod.modEqual(mod, DAE.NOMOD());

        // lookup in IH, crap, we couldn't find it!
        failure(_ = InnerOuter.lookupInnerVar(cache, env, ih, pre, n, io));

        // Debug.fprintln(Flags.INNER_OUTER, "- Inst.instVar failed to lookup inner: " +& PrefixUtil.printPrefixStr(pre) +& "/" +& n +& " in env: " +& Env.printEnvPathStr(env));

        // display an error message!
        (cache,crefOuter) = PrefixUtil.prefixCref(cache,env,ih,pre, ComponentReference.makeCrefIdent(n, DAE.T_UNKNOWN_DEFAULT, {}));
        s1 = ComponentReference.printComponentRefStr(crefOuter);
        s2 = Dump.unparseInnerouterStr(io);
        s3 = InnerOuter.getExistingInnerDeclarations(ih,componentDefinitionParentEnv);
        typeName = SCode.className(cl);
        (cache, typePath) = Inst.makeFullyQualified(cache, env, Absyn.IDENT(typeName));
        s1 = Absyn.pathString(typePath) +& " " +& s1;
        // print(Util.if_(impl, "impl crap\n", "no impl\n"));
        // adrpo: do NOT! display an error message if impl = true and prefix is Prefix.NOPRE()
        Debug.bcall(impl and listMember(pre, {Prefix.NOPRE()}), ErrorExt.setCheckpoint, "innerouter-instVar-implicit");
        Error.addSourceMessage(Error.MISSING_INNER_PREFIX,{s1, s2, s3}, info);
        Debug.bcall(impl and listMember(pre, {Prefix.NOPRE()}), ErrorExt.rollBack, "innerouter-instVar-implicit");

        // call it normally
        (cache,compenv,ih,store,dae,_,ty,graph) =
           instVar_dispatch(cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,info,graph, csets);
      then
        (cache,compenv,ih,store,dae,csets,ty,graph);

    // is inner outer!
    case (cache,env,ih,store,ci_state,mod,pre,n,cl as SCode.CLASS(name=typeName),attr,pf,dims,idxs,inst_dims,impl,comment,_,graph, csets, _)
      equation
        // both inner and outer
        io = SCode.prefixesInnerOuter(pf);
        true = Absyn.isInnerOuter(io);

        // Debug.fprintln(Flags.INNER_OUTER, "- Inst.instVar inner outer: " +& PrefixUtil.printPrefixStr(pre) +& "/" +& n +& " in env: " +& Env.printEnvPathStr(env));

        (cache,innerCompEnv,ih,store,dae,csetsInner,ty,graph) =
           instVar_dispatch(cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,info,graph, csets);

        // add it to the instance hierarchy
        (cache,cref) = PrefixUtil.prefixCref(cache,env,ih,pre, ComponentReference.makeCrefIdent(n, DAE.T_UNKNOWN_DEFAULT, {}));
        fullName = ComponentReference.printComponentRefStr(cref);
        (cache, typePath) = Inst.makeFullyQualified(cache, env, Absyn.IDENT(typeName));

        // also all the components in the environment should be updated to be outer!
        // switch components from inner to outer in the component env.
        outerCompEnv = InnerOuter.switchInnerToOuterInEnv(innerCompEnv, cref);

        // keep the dae we get from the instantiation of the inner
        innerDAE = dae;

        innerScope = Env.printEnvPathStr(componentDefinitionParentEnv);

        // add inner to the instance hierarchy
        ih = InnerOuter.updateInstHierarchy(ih, pre, io,
               InnerOuter.INST_INNER(
                  pre,
                  n,
                  io,
                  fullName,
                  typePath,
                  innerScope,
                  SOME(InnerOuter.INST_RESULT(cache,outerCompEnv,store,innerDAE,csetsInner,ty,graph)),
                  {},
                  NONE()));

        // now instantiate it as an outer with no modifications
        pf = SCode.prefixesSetInnerOuter(pf, Absyn.OUTER());
        (cache,compenv,ih,store,dae,csetsOuter,ty,graph) =
          instVar(cache,env,ih,store,ci_state,DAE.NOMOD(),pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,info,graph,csets,componentDefinitionParentEnv);

        // keep the dae we get from the instantiation of the outer
        outerDAE = dae;

        // join the dae's (even thou' the outer is empty)
        dae = DAEUtil.joinDaes(outerDAE, innerDAE);
      then
        (cache,compenv,ih,store,dae,csetsInner,ty,graph);

    // is NO INNER NOR OUTER or it failed before!
    case (cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,_,graph, csets, _)
      equation
        // no inner no outer
        io = SCode.prefixesInnerOuter(pf);
        true = Absyn.isNotInnerOuter(io);

        // Debug.fprintln(Flags.INNER_OUTER, "- Inst.instVar NO inner NO outer: " +& PrefixUtil.printPrefixStr(pre) +& "/" +& n +& " in env: " +& Env.printEnvPathStr(env));

        (cache,compenv,ih,store,dae,csets,ty,graph) =
          instVar_dispatch(cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,info,graph,csets);
      then
        (cache,compenv,ih,store,dae,csets,ty,graph);

    // failtrace
    case (cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,_,graph,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        (cache,cref) = PrefixUtil.prefixCref(cache,env,ih,pre, ComponentReference.makeCrefIdent(n, DAE.T_UNKNOWN_DEFAULT, {}));
        Debug.fprintln(Flags.FAILTRACE, "- Inst.instVar failed while instatiating variable: " +&
          ComponentReference.printComponentRefStr(cref) +& " " +& Mod.prettyPrintMod(mod, 0) +&
          "\nin scope: " +& Env.printEnvPathStr(env) +& " class:\n" +& SCodeDump.unparseElementStr(cl));
      then
        fail();
    end matchcontinue;
end instVar;

protected function instVar_dispatch "A component element in a class may consist of several subcomponents
  or array elements.  This function is used to instantiate a
  component, instantiating all subcomponents and array elements
  separately.
  P.A: Most of the implementation is moved to instVar2. instVar collects
  dimensions for userdefined types, such that these can be correctly
  handled by instVar2 (using instArray)"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input ClassInf.State inState;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input String inIdent;
  input SCode.Element inClass;
  input SCode.Attributes inAttributes;
  input SCode.Prefixes inPrefixes;
  input DAE.Dimensions inDimensionLst;
  input list<DAE.Subscript> inIntegerLst;
  input list<list<DAE.Subscript>>inInstDims;
  input Boolean inBoolean;
  input SCode.Comment inSCodeComment;
  input Absyn.Info info;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output DAE.Type outType;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outStore,outDae,outSets,outType,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inStore,inState,inMod,inPrefix,inIdent,inClass,inAttributes,inPrefixes,inDimensionLst,inIntegerLst,inInstDims,inBoolean,inSCodeComment,info,inGraph,inSets)
    local
      DAE.Dimensions dims;
      list<Env.Frame> compenv,env;
      DAE.DAElist dae;
      Connect.Sets csets;
      DAE.Type ty;
      ClassInf.State ci_state;
      DAE.Mod mod;
      Prefix.Prefix pre;
      String n,id;
      SCode.Element cl;
      SCode.Attributes attr;
      list<DAE.Subscript> idxs;
      InstDims inst_dims;
      Boolean impl;
      SCode.Comment comment;
      Env.Cache cache;
      Absyn.Path p1;
      String str;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      DAE.Mod type_mods;
      SCode.Prefixes pf;
      UnitAbsyn.InstStore store;
      DAE.ElementSource source;
      SCode.Variability vt;

    // impl component environment dae elements for component Variables of userdefined type,
    // e.g. Point p => Real p[3]; These must be handled separately since even if they do not
    // appear to be an array, they can. Therefore we need to collect
    // the full dimensionality and call instVar2
    case (cache,env,ih,store,ci_state,mod,pre,n,(cl as SCode.CLASS(name = id)),attr as SCode.ATTR(variability = vt),pf,dims,idxs,inst_dims,impl,comment,_,graph,csets)
      equation
        // Collect dimensions
        p1 = Absyn.IDENT(n);
        p1 = PrefixUtil.prefixPath(p1,pre);
        str = Absyn.pathString(p1);
        Error.updateCurrentComponent(str,info);
        (cache, dims as (_ :: _),cl,type_mods) = InstUtil.getUsertypeDimensions(cache, env, ih, pre, cl, inst_dims, impl);

        //type_mods = Mod.addEachIfNeeded(type_mods, dims);
        //mod = Mod.addEachIfNeeded(mod, inDimensionLst);

        dims = listAppend(inDimensionLst, dims);
        mod = Mod.merge(mod, type_mods, env, pre);

        attr = InstUtil.propagateClassPrefix(attr,pre);
        (cache,compenv,ih,store,dae,csets,ty,graph) =
          instVar2(cache, env, ih, store, ci_state, mod, pre, n, cl, attr,
            pf, dims, idxs, inst_dims, impl, comment, info, graph, csets);
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        (cache,dae) = addArrayVarEquation(cache, env, ih, ci_state, dae, ty, mod, NFInstUtil.toConst(vt), pre, n, source);
        cache = InstFunction.addRecordConstructorFunction(cache,env,Types.arrayElementType(ty));
        Error.updateCurrentComponent("",Absyn.dummyInfo);
      then
        (cache,compenv,ih,store,dae,csets,ty,graph);

    // Generic case: fall through
    case (cache,env,ih,store,ci_state,mod,pre,n,(cl as SCode.CLASS(name = id)),attr as SCode.ATTR(variability = vt),pf,dims,idxs,inst_dims,impl,comment,_,graph, csets)
      equation
        p1 = Absyn.IDENT(n);
        p1 = PrefixUtil.prefixPath(p1,pre);
        str = Absyn.pathString(p1);
        Error.updateCurrentComponent(str,info);
        // print("instVar: " +& str +& " in scope " +& Env.printEnvPathStr(env) +& "\t mods: " +& Mod.printModStr(mod) +& "\n");

        // The prefix is handled in other parts of the code. Applying it too soon gives wrong results: // attr = InstUtil.propagateClassPrefix(attr,pre);
        (cache,compenv,ih,store,dae,csets,ty,graph) =
          instVar2(cache,env,ih,store, ci_state, mod, pre, n, cl, attr,
            pf, dims, idxs, inst_dims, impl, comment, info, graph, csets);
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        (cache,dae) = addArrayVarEquation(cache,compenv,ih,ci_state, dae, ty, mod, NFInstUtil.toConst(vt), pre, n, source);
        cache = InstFunction.addRecordConstructorFunction(cache,env,Types.arrayElementType(ty));
        Error.updateCurrentComponent("",Absyn.dummyInfo);
      then
        (cache,compenv,ih,store,dae,csets,ty,graph);

    else
      equation
        Error.updateCurrentComponent("",Absyn.dummyInfo);
      then fail();
  end matchcontinue;
end instVar_dispatch;

protected function addArrayVarEquation
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input ClassInf.State inState;
  input DAE.DAElist inDae;
  input DAE.Type inType;
  input DAE.Mod mod;
  input DAE.Const const;
  input Prefix.Prefix pre;
  input String n;
  input DAE.ElementSource source;
  output Env.Cache outCache;
  output DAE.DAElist outDae;
algorithm
  (outCache,outDae) := matchcontinue (inCache,inEnv,inIH,inState,inDae,inType,mod,const,pre,n,source)
    local
      Env.Cache cache;
      list<DAE.Element> dae;
      DAE.Exp exp;
      DAE.Element eq;
      DAE.Dimensions dims;
      DAE.ComponentRef cr;
      DAE.Type ty;

    // Don't add array equations if +scalarizeBindings is set.
    case (_, _, _, _, _, _, _, _, _, _, _)
      equation
        true = Config.scalarizeBindings();
      then
        (inCache, inDae);

    case (_,_,_,_,DAE.DAE(dae),_,_,DAE.C_VAR(),_,_,_)
      equation
        false = ClassInf.isFunctionOrRecord(inState);
        ty = Types.simplifyType(inType);
        false = Types.isExternalObject(Types.arrayElementType(ty));
        false = Types.isComplexType(Types.arrayElementType(ty));
        (dims as _::_) = Types.getDimensions(ty);
        SOME(exp) = InstBinding.makeVariableBinding(ty, mod, const, pre, n, source);
        cr = ComponentReference.makeCrefIdent(n,ty,{});
        (cache,cr) = PrefixUtil.prefixCref(inCache,inEnv,inIH,pre,cr);
        eq = DAE.ARRAY_EQUATION(dims, DAE.CREF(cr,ty), exp, source);
        // print("Creating array equation for " +& PrefixUtil.printPrefixStr(pre) +& "." +& n +& " of const " +& DAEUtil.constStr(const) +& " in classinf " +& ClassInf.printStateStr(inState) +& "\n");
      then (cache,DAE.DAE(eq::dae));
    else (inCache,inDae);
  end matchcontinue;
end addArrayVarEquation;

protected function instVar2
"Helper function to instVar, does the main work."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input ClassInf.State inState;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input String inName;
  input SCode.Element inClass;
  input SCode.Attributes inAttributes;
  input SCode.Prefixes inPrefixes;
  input DAE.Dimensions inDimensions;
  input list<DAE.Subscript> inSubscripts;
  input list<list<DAE.Subscript>>inInstDims;
  input Boolean inImpl;
  input SCode.Comment inComment;
  input Absyn.Info inInfo;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output DAE.Type outType;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outStore,outDae,outSets,outType,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inStore,inState,inMod,inPrefix,inName,inClass,inAttributes,inPrefixes,inDimensions,inSubscripts,inInstDims,inImpl,inComment,inInfo,inGraph,inSets)
    local
      InstDims inst_dims,inst_dims_1;
      list<DAE.Subscript> dims_1;
      DAE.Exp e,e_1;
      DAE.Properties p;
      list<Env.Frame> env_1,env,compenv;
      Connect.Sets csets;
      DAE.Type ty,ty_1,arrty;
      ClassInf.State st,ci_state;
      DAE.ComponentRef cr;
      DAE.Type ty_2;
      DAE.DAElist dae1,dae;
      DAE.Mod mod;
      Prefix.Prefix pre;
      String n;
      SCode.Element cl;
      SCode.Attributes attr;
      DAE.Dimensions dims;
      list<DAE.Subscript> idxs;
      Boolean impl;
      SCode.Comment comment;
      Option<DAE.VariableAttributes> dae_var_attr;
      DAE.Subscript dime;
      DAE.Dimension dim;
      Env.Cache cache;
      SCode.Visibility vis;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      String n2;
      Integer deduced_dim;
      DAE.Subscript dime2;
      SCode.Prefixes pf;
      SCode.Final fin;
      Absyn.Info info;
      Absyn.InnerOuter io;
      UnitAbsyn.InstStore store;
      list<DAE.SubMod> subMods;
      Absyn.Path path;
      list<DAE.Var> vars;
    
    /*
    case (cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,info,graph,csets)
      equation
        true = SCode.isPartial(cl);

        //Do not flatten because it is a function
        dims_1 = InstUtil.instDimExpLst(dims, impl);

        (cache,env_1,ih,ci_state,vars) = Inst.partialInstClassIn(cache, env, ih, mod, pre, ci_state, cl, SCode.PUBLIC(), inst_dims, 0);
        dae = DAE.emptyDae;
        (cache, path) = Inst.makeFullyQualified(cache, env, Absyn.IDENT(n));
        ty = DAE.T_COMPLEX(ci_state, vars, NONE(), {path});
        ty = InstUtil.makeArrayType(dims, ty);
      then
        (cache,env_1,ih,store,dae,csets,ty,graph);*/


    // Rules for instantation of function variables (e.g. input and output

    // Function variables with modifiers (outputs or local/protected variables)
    // For Functions we cannot always find dimensional sizes. e.g.
    // input Real x[:]; component environement The class is instantiated
    // with the calculated modification, and an extended prefix.
    //

    // mahge: Function variables with subMod modifications. This can happen for records with inline constructions (and maybe other stuff too???)
     // now only for records.
        // e.g.
        // function out
        //   output R1 r(v1=3,v2=3);  // <= Here
        // protected
        //   R1 r2(v1=1, v1=2);     // <= Here
        // end out;
        // see testsuit/mofiles/RecordBindings.mo.
     case (cache,env,ih,store,ci_state,mod as DAE.MOD(subModLst = subMods, eqModOption = NONE()),pre,n,cl as SCode.CLASS(restriction = SCode.R_RECORD(_)),attr,pf,dims,idxs,inst_dims,impl,comment,info,graph,csets)
      equation
        true = ClassInf.isFunction(ci_state);
        InstUtil.checkFunctionVar(n, attr, pf, info);

        //Do not flatten because it is a function
        dims_1 = InstUtil.instDimExpLst(dims, impl);

        //Instantiate type of the component, skip dae/not flattening (but extract functions)
        // adrpo: do not send in the modifications as it will fail if the modification is an ARRAY.
        //        anyhow the modifications are handled below.
        //        input Integer sequence[3](min = {1,1,1}, max = {3,3,3}) = {1,2,3}; // this will fail if we send in the mod.
        //        see testsuite/mofiles/Sequence.mo
        (cache,env_1,ih,store,dae1,csets,ty,st,_,graph) =
          Inst.instClass(cache, env, ih, store, /* mod */ DAE.NOMOD(), pre, cl, inst_dims, impl, InstTypes.INNER_CALL(), graph, csets);
        //Make it an array type since we are not flattening
        ty_1 = InstUtil.makeArrayType(dims, ty);
        InstUtil.checkFunctionVarType(ty_1, ci_state, n, info);

        (cache,dae_var_attr) = InstBinding.instDaeVariableAttributes(cache,env, mod, ty, {});

        //Generate variable with default binding
        ty_2 = Types.simplifyType(ty_1);
        (cache,cr) = PrefixUtil.prefixCref(cache,env,ih,pre, ComponentReference.makeCrefIdent(n,ty_2,{}));

        //We should get a call exp from here
        (cache, DAE.EQBOUND(e,_,_,_/*source*/)) = InstBinding.makeBinding(cache,env,attr,mod,ty_2,pre,n,info);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());


        SCode.PREFIXES(visibility = vis, finalPrefix = fin, innerOuter = io) = pf;
        dae = InstDAE.daeDeclare(cr, ci_state, ty, attr, vis, SOME(e), {dims_1}, NONE(), dae_var_attr, SOME(comment), io, fin, source, true);
        store = UnitAbsynBuilder.instAddStore(store,ty,cr);
      then
        (cache,env_1,ih,store,dae,csets,ty_1,graph);

    // mahge: function variables with eqMod modifications.
    // FIXHERE: They might have subMods too (variable attributes). see testsuite/mofiles/Sequence.mo
    case (cache,env,ih,store,ci_state,mod as DAE.MOD(subModLst = subMods, eqModOption = SOME(_)),pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,info,graph,csets)
      equation
        true = ClassInf.isFunction(ci_state);
        InstUtil.checkFunctionVar(n, attr, pf, info);

        //Do not flatten because it is a function
        dims_1 = InstUtil.instDimExpLst(dims, impl);

        //get the equation modification
        SOME(DAE.TYPED(e,_,p,_,_)) = Mod.modEquation(mod);
        //Instantiate type of the component, skip dae/not flattening (but extract functions)
        // adrpo: do not send in the modifications as it will fail if the modification is an ARRAY.
        //        anyhow the modifications are handled below.
        //        input Integer sequence[3](min = {1,1,1}, max = {3,3,3}) = {1,2,3}; // this will fail if we send in the mod.
        //        see testsuite/mofiles/Sequence.mo
        (cache,env_1,ih,store,dae1,csets,ty,st,_,graph) =
          Inst.instClass(cache, env, ih, store, /* mod */ DAE.NOMOD(), pre, cl, inst_dims, impl, InstTypes.INNER_CALL(), graph, csets);
        //Make it an array type since we are not flattening
        ty_1 = InstUtil.makeArrayType(dims, ty);
        InstUtil.checkFunctionVarType(ty_1, ci_state, n, info);

        (cache,dae_var_attr) = InstBinding.instDaeVariableAttributes(cache,env, mod, ty, {});
        // Check binding type matches variable type
        (e_1,_) = Types.matchProp(e,p,DAE.PROP(ty_1,DAE.C_VAR()),true);

        //Generate variable with default binding
        ty_2 = Types.simplifyType(ty_1);
        (cache,cr) = PrefixUtil.prefixCref(cache,env,ih,pre, ComponentReference.makeCrefIdent(n,ty_2,{}));

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());


        SCode.PREFIXES(visibility = vis, finalPrefix = fin, innerOuter = io) = pf;
        dae = InstDAE.daeDeclare(cr, ci_state, ty, attr, vis, SOME(e_1), {dims_1}, NONE(), dae_var_attr, SOME(comment), io, fin, source, true);
        store = UnitAbsynBuilder.instAddStore(store,ty,cr);
      then
        (cache,env_1,ih,store,dae,csets,ty_1,graph);


    // Function variables without binding
    case (cache,env,ih,store,ci_state,mod,pre,n,(cl as SCode.CLASS(name=n2)),attr,pf,dims,idxs,inst_dims,impl,comment,info,graph,csets)
       equation
        true = ClassInf.isFunction(ci_state);
        InstUtil.checkFunctionVar(n, attr, pf, info);

         //Instantiate type of the component, skip dae/not flattening
        (cache,env_1,ih,store,dae1,csets,ty,st,_,_) =
          Inst.instClass(cache, env, ih, store, mod, pre, cl, inst_dims, impl, InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, csets);
        arrty = InstUtil.makeArrayType(dims, ty);
        InstUtil.checkFunctionVarType(arrty, ci_state, n, info);
        (cache,cr) = PrefixUtil.prefixCref(cache,env,ih,pre, ComponentReference.makeCrefIdent(n,DAE.T_UNKNOWN_DEFAULT,{}));
        (cache,dae_var_attr) = InstBinding.instDaeVariableAttributes(cache,env, mod, ty, {});
        //Do all dimensions...
        // print("dims: " +& stringDelimitList(List.map(dims,ExpressionDump.dimensionString),",") +& "\n");
        dims_1 = InstUtil.instDimExpLst(dims, impl);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());

        SCode.PREFIXES(visibility = vis, finalPrefix = fin, innerOuter = io) = pf;
        dae = InstDAE.daeDeclare(cr, ci_state, ty, attr,vis,NONE(), {dims_1},NONE(), dae_var_attr, SOME(comment),io,fin,source,true);
        store = UnitAbsynBuilder.instAddStore(store,ty,cr);
      then
        (cache,env_1,ih,store,dae,csets,arrty,graph);

    // Scalar variables.
    case (_, _, _, _, _, _, _, _, _, _, _, {}, _, _, _, _, _, _, _)
      equation
        false = ClassInf.isFunction(inState);
        (cache, env, ih, store, dae, csets, ty, graph) = instScalar(
            inCache, inEnv, inIH, inStore, inState, inMod, inPrefix,
            inName, inClass, inAttributes, inPrefixes, inSubscripts,
            inInstDims, inImpl, SOME(inComment), inInfo, inGraph, inSets);
      then
        (cache, env, ih, store, dae, csets, ty, graph);

    // Array variables with unknown dimensions, e.g. Real x[:] = [some expression that can be used to determine dimension].
    case (cache,env,ih,store,ci_state,(mod as DAE.MOD(eqModOption = SOME(DAE.TYPED(e,_,_,_,_)))),pre,n,cl,attr,pf,
        ((dim as DAE.DIM_UNKNOWN()) :: dims),idxs,inst_dims,impl,comment,info,graph, csets)
      equation
        true = Config.splitArrays();
        false = ClassInf.isFunction(ci_state);
        // Try to deduce the dimension from the modifier.
        (dime as DAE.INDEX(DAE.ICONST(integer = deduced_dim))) =
          InstUtil.instWholeDimFromMod(dim, mod, n, info);
        dim = DAE.DIM_INTEGER(deduced_dim);
        inst_dims_1 = List.appendLastList(inst_dims, {dime});
        (cache,compenv,ih,store,dae,csets,ty,graph) =
          instArray(cache,env,ih,store, ci_state, mod, pre, n, (cl,attr), pf, 1, dim, dims, idxs, inst_dims_1, impl, comment,info,graph, csets);
        ty_1 = InstUtil.liftNonBasicTypes(ty,dim); // Do not lift types extending basic type, they are already array types.
      then
        (cache,compenv,ih,store,dae,csets,ty_1,graph);

    // Array variables with unknown dimensions, non-expanding case
    case (cache,env,ih,store,ci_state,(mod as DAE.MOD(eqModOption = SOME(DAE.TYPED(e,_,_,_,_)))),pre,n,cl,attr,pf,
      ((dim as DAE.DIM_UNKNOWN()) :: dims),idxs,inst_dims,impl,comment,info,graph, csets)
      equation
        false = Config.splitArrays();
        false = ClassInf.isFunction(ci_state);
        // Try to deduce the dimension from the modifier.
        dime = InstUtil.instWholeDimFromMod(dim, mod, n, info);
        dime2 = InstUtil.makeNonExpSubscript(dime);
        dim = Expression.subscriptDimension(dime);
        inst_dims_1 = List.appendLastList(inst_dims, {dime2});
        (cache,compenv,ih,store,dae,csets,ty,graph) =
          instVar2(cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,dime2::idxs,inst_dims_1,impl,comment,info,graph,csets);
        ty_1 = InstUtil.liftNonBasicTypes(ty,dim); // Do not lift types extending basic type, they are already array types.
      then
        (cache,compenv,ih,store,dae,csets,ty_1,graph);

    // Array variables , e.g. Real x[3]
    case (cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,(dim :: dims),idxs,inst_dims,impl,comment,info,graph,csets)
      equation
        true = Config.splitArrays();
        false = ClassInf.isFunction(ci_state);
        dime = InstUtil.instDimExp(dim, impl);
        inst_dims_1 = List.appendLastList(inst_dims, {dime});
        (cache,compenv,ih,store,dae,csets,ty,graph) =
          instArray(cache,env,ih,store, ci_state, mod, pre, n, (cl,attr), pf, 1, dim, dims, idxs, inst_dims_1, impl, comment,info,graph,csets);
        ty_1 = InstUtil.liftNonBasicTypes(ty,dim); // Do not lift types extending basic type, they are already array types.
      then
        (cache,compenv,ih,store,dae,csets,ty_1,graph);

    // Array variables , non-expanding case
    case (cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,(dim :: dims),idxs,inst_dims,impl,comment,info,graph,csets)
      equation
        false = Config.splitArrays();
        false = ClassInf.isFunction(ci_state);
        dime = InstUtil.instDimExpNonSplit(dim, impl);
        inst_dims_1 = List.appendLastList(inst_dims, {dime});
        (cache,compenv,ih,store,dae,csets,ty,graph) =
          instVar2(cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,dime::idxs,inst_dims_1,impl,comment,info,graph,csets);
        // Type lifting is done in the "scalar" case
        //ty_1 = InstUtil.liftNonBasicTypes(ty,dim); // Do not lift types extending basic type, they are already array types.
      then
        (cache,compenv,ih,store,dae,csets,ty,graph);

    // Array variable with unknown dimensions, but no binding
    case (cache,env,ih,store,ci_state,DAE.NOMOD(),pre,n,cl,attr,pf,
      ((dim as DAE.DIM_UNKNOWN()) :: dims),idxs,inst_dims,impl,comment,info,graph,csets)
      equation
        Error.addSourceMessage(Error.FAILURE_TO_DEDUCE_DIMS_NO_MOD,{n},info);
      then
        fail();

    // failtrace
    case (_,env,ih,_,_,mod,pre,n,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprintln(Flags.FAILTRACE, "- Inst.instVar2 failed: " +&
          PrefixUtil.printPrefixStr(pre) +& "." +&
          n +& "(" +& Mod.prettyPrintMod(mod, 0) +& ")\n  Scope: " +&
          Env.printEnvPathStr(env));
      then
        fail();
  end matchcontinue;
end instVar2;

public function instScalar
  "Instantiates a scalar variable."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input ClassInf.State inState;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input String inName;
  input SCode.Element inClass;
  input SCode.Attributes inAttributes;
  input SCode.Prefixes inPrefixes;
  input list<DAE.Subscript> inSubscripts;
  input list<list<DAE.Subscript>>inInstDims;
  input Boolean inImpl;
  input Option<SCode.Comment> inComment;
  input Absyn.Info inInfo;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output DAE.Type outType;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache, outEnv, outIH, outStore, outDae, outSets, outType, outGraph) :=
  matchcontinue(inCache, inEnv, inIH, inStore, inState, inMod, inPrefix,
      inName, inClass, inAttributes, inPrefixes, inSubscripts,
      inInstDims, inImpl, inComment, inInfo, inGraph, inSets)

    local
      String cls_name;
      Env.Cache cache;
      Env.Env env;
      InstanceHierarchy ih;
      UnitAbsyn.InstStore store;
      Connect.Sets csets;
      SCode.Restriction res;
      SCode.Variability vt;
      list<DAE.Subscript> idxs;
      Prefix.Prefix pre;
      ClassInf.State ci_state;
      ConnectionGraph.ConnectionGraph graph;
      DAE.DAElist dae, dae1, dae2;
      DAE.Type ty;
      DAE.Type ident_ty;
      DAE.ComponentRef cr;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<DAE.Exp> opt_binding;
      DAE.ElementSource source;
      SCode.Attributes attr;
      SCode.Visibility vis;
      SCode.Final fin;
      Absyn.InnerOuter io;
      DAE.StartValue start;
      Option<SCode.Attributes> opt_attr;
      DAE.Mod mod;

    case (cache, env, ih, store, _, mod, _, _,
        SCode.CLASS(name = cls_name, restriction = res), SCode.ATTR(variability = vt),
        SCode.PREFIXES(visibility = vis, finalPrefix = fin, innerOuter = io),
        idxs, _, _, _, _, _, _)
      equation
        // Instantiate the components class.
        idxs = listReverse(idxs);
        ci_state = ClassInf.start(res, Absyn.IDENT(cls_name));
        pre = PrefixUtil.prefixAdd(inName, idxs, inPrefix, vt, ci_state);
        (cache, env, ih, store, dae1, csets, ty, ci_state, opt_attr, graph) =
          Inst.instClass(cache, env, ih, store, inMod, pre, inClass, inInstDims,
            inImpl, InstTypes.INNER_CALL(), inGraph, inSets);

        // Propagate and instantiate attributes.
        dae1 = InstUtil.propagateAttributes(dae1, inAttributes, inPrefixes, inInfo);
        (cache, dae_var_attr) = InstBinding.instDaeVariableAttributes(cache, env, inMod, ty, {});
        attr = InstUtil.propagateAbSCDirection(vt, inAttributes, opt_attr, inInfo);
        attr = SCode.removeAttributeDimensions(attr);

        // Attempt to set the correct type for array variable if splitArrays is
        // false. Does not work correctly yet.
        ty = Debug.bcallret2(not Config.splitArrays(), Types.liftArraySubscriptList,
          ty, List.flatten(inInstDims), ty);

        // Make a component reference for the component.
        ident_ty = InstUtil.makeCrefBaseType(ty, inInstDims);
        cr = ComponentReference.makeCrefIdent(inName, ident_ty, idxs);
        (cache, cr) = PrefixUtil.prefixCref(cache, env, ih, inPrefix, cr);

        // adrpo: we cannot check this here as:
        //        we might have modifications on inner that we copy here
        //        Dymola doesn't report modifications on outer as error!
        //        instead we check here if the modification is not the same
        //        as the one on inner
        InstUtil.checkModificationOnOuter(cache, env, ih, inPrefix, inName, cr, inMod,
          vt, io, inImpl, inInfo);

        // Set the source of this element.
        source = DAEUtil.createElementSource(inInfo, Env.getEnvPath(env),
          PrefixUtil.prefixToCrefOpt(inPrefix), NONE(), NONE());

        // Instantiate the components binding.
        mod = Util.if_(listLength(inSubscripts) > 0 and not SCode.isParameterOrConst(vt) and not ClassInf.isFunctionOrRecord(inState) and not Types.isComplexType(Types.arrayElementType(ty)) and not Types.isExternalObject(Types.arrayElementType(ty)) and not Config.scalarizeBindings(),DAE.NOMOD(),inMod);
        opt_binding = InstBinding.makeVariableBinding(ty, mod, NFInstUtil.toConst(vt), inPrefix, inName, source);
        start = InstBinding.instStartBindingExp(inMod /* Yup, let's keep the start-binding. It seems sane. */, ty, vt);

        // Add the component to the DAE.
        dae2 = InstDAE.daeDeclare(cr, inState, ty, attr, vis, opt_binding, inInstDims,
          start, dae_var_attr, inComment, io, fin, source, false);
        dae2 = DAEUtil.addComponentTypeOpt(dae2, Types.getClassnameOpt(ty));
        store = UnitAbsynBuilder.instAddStore(store, ty, cr);

        // The remaining work is done in instScalar2.
        dae = instScalar2(cr, ty, vt, inMod, dae2, dae1, source, inImpl);
      then
        (cache, env, ih, store, dae, csets, ty, graph);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprintln(Flags.FAILTRACE, "- Inst.instScalar failed on " +& inName +& " in scope " +& PrefixUtil.printPrefixStr(inPrefix) +& " env: " +& Env.printEnvPathStr(inEnv) +& "\n");
      then
        fail();
  end matchcontinue;
end instScalar;

protected function instScalar2
  "Helper function to instScalar. Some operations needed when instantiating a
  scalar depends on what kind of variable it is, i.e. constant, parameter or
  variable. This function does these operations to keep instScalar simple."
  input DAE.ComponentRef inCref;
  input DAE.Type inType;
  input SCode.Variability inVariability;
  input DAE.Mod inMod;
  input DAE.DAElist inDae;
  input DAE.DAElist inClassDae;
  input DAE.ElementSource inSource;
  input Boolean inImpl;
  output DAE.DAElist outDae;
algorithm
  outDae := match(inCref, inType, inVariability, inMod, inDae, inClassDae, inSource, inImpl)
    local
      DAE.DAElist dae;

    // Constant with binding.
    case (_, _, SCode.CONST(), DAE.MOD(eqModOption = SOME(DAE.TYPED(modifierAsExp = _))),
        _, _, _, _)
      equation
        dae = DAEUtil.joinDaes(inClassDae, inDae);
      then
        dae;

    // mahge
    // Records with Bindings to other records like =>
    // model M
    //   R r1 = R(1);
    //   R r1 = r2;   <= here
    // end M;
    // The dae that will be recived from instClass in instScalar will give the default record bindings for the record r1
    // which is wrong. Fixing it there would need a LOT of changes.
    // So instead we fix it here by moving the equation generated from eqMod modification for each element back to the
    // declaration of the element. Then removing the equation. This is done in the function moveBindings.
    // SEE testsuit/records/RecordBindingsOrdered.mo and RecordBindingsOrderedSimple.mo
    case (_, DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)), _, DAE.MOD(eqModOption = SOME(DAE.TYPED(modifierAsExp = DAE.CREF(_, _)))),
        _, _, _, _)
      equation
        dae = InstBinding.instModEquation(inCref, inType, inMod, inSource, inImpl);
        //move bindings from dae to inClassDae and use the resulting dae
        dae = InstUtil.moveBindings(dae,inClassDae);
        dae = DAEUtil.joinDaes(dae, inDae);
      then
        dae;

    case (_, DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)), _, DAE.MOD(eqModOption = SOME(DAE.TYPED(modifierAsExp = DAE.CAST(exp=DAE.CREF(_, _))))),
        _, _, _, _)
      equation
        dae = InstBinding.instModEquation(inCref, inType, inMod, inSource, inImpl);
        //move bindings from dae to inClassDae and use the resulting dae
        dae = InstUtil.moveBindings(dae,inClassDae);
        dae = DAEUtil.joinDaes(dae, inDae);
      then dae;

    // Parameter with binding.
    case (_, _, SCode.PARAM(), DAE.MOD(eqModOption = SOME(DAE.TYPED(modifierAsExp = _))),
        _, _, _, _)
      equation
        dae = InstBinding.instModEquation(inCref, inType, inMod, inSource, inImpl);
        // The equations generated by InstBinding.instModEquation are used only to modify
        // the bindings of parameters. No extra equations are added. -- alleb
        dae = InstUtil.propagateBinding(inClassDae, dae);
        dae = DAEUtil.joinDaes(dae, inDae);
      then
        dae;

    // All other scalars.
    else
      equation
        dae = InstBinding.instModEquation(inCref, inType, inMod, inSource, inImpl);
        dae = Util.if_(Types.isComplexType(inType), dae, DAE.emptyDae);
        dae = DAEUtil.joinDaes(dae, inDae);
        dae = DAEUtil.joinDaes(inClassDae, dae);
      then
        dae;
  end match;
end instScalar2;

protected function instArray
"When an array is instantiated by instVar, this function is used
  to go through all the array elements and instantiate each array
  element separately."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input ClassInf.State inState;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input String inIdent;
  input tuple<SCode.Element, SCode.Attributes> inTplSCodeClassSCodeAttributes;
  input SCode.Prefixes inPrefixes;
  input Integer inInteger;
  input DAE.Dimension inDimension;
  input DAE.Dimensions inDimensionLst;
  input list<DAE.Subscript> inIntegerLst;
  input list<list<DAE.Subscript>>inInstDims;
  input Boolean inBoolean;
  input SCode.Comment inComment;
  input Absyn.Info info;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output DAE.Type outType;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outStore,outDae,outSets,outType,outGraph) :=
  matchcontinue (inCache,inEnv,inIH,inStore,inState,inMod,inPrefix,inIdent,inTplSCodeClassSCodeAttributes,inPrefixes,inInteger,inDimension,inDimensionLst,inIntegerLst,inInstDims,inBoolean,inComment,info,inGraph,inSets)
    local
      DAE.Exp e,lhs,rhs;
      DAE.Properties p;
      Env.Cache cache;
      Env.Env env_1,env_2,env,compenv;
      Connect.Sets csets;
      DAE.Type ty;
      ClassInf.State st,ci_state;
      DAE.ComponentRef cr;
      DAE.Type ty_1;
      DAE.Mod mod,mod_1,mod_2;
      Prefix.Prefix pre;
      String n, str1, str2, str3, str4;
      SCode.Element cl;
      SCode.Attributes attr;
      Integer i,stop,i_1;
      DAE.Dimension dim;
      DAE.Dimensions dims;
      list<DAE.Subscript> idxs;
      InstDims inst_dims;
      Boolean impl;
      SCode.Comment comment;
      DAE.DAElist dae,dae1,dae2,daeLst;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      DAE.Subscript s;
      SCode.Element clBase;
      Absyn.Path path;
      SCode.Attributes absynAttr;
      SCode.Mod scodeMod;
      DAE.Mod mod2, mod3;
      String lit;
      list<String> l;
      Integer enum_size;
      Absyn.Path enum_type, enum_lit;
      SCode.Prefixes pf;
      UnitAbsyn.InstStore store;

    // component environment If is a function var.
    case (cache,env,ih,store,(ci_state as ClassInf.FUNCTION(path = _)),mod,pre,n,(cl,attr),pf,i,dim,dims,idxs,inst_dims,impl,comment,_,graph, csets)
      equation
        true = Expression.dimensionUnknownOrExp(dim);
        SOME(DAE.TYPED(e,_,p,_,_)) = Mod.modEquation(mod);
        (cache,env_1,ih,store,dae1,_,ty,st,_,graph) =
          Inst.instClass(cache,env,ih,store, mod, pre, cl, inst_dims, true, InstTypes.INNER_CALL(), graph, csets) "Which has an expression binding";
        ty_1 = Types.simplifyType(ty);
        (cache,cr) = PrefixUtil.prefixCref(cache,env,ih,pre,ComponentReference.makeCrefIdent(n,ty_1,{})) "check their types";
        (rhs,_) = Types.matchProp(e,p,DAE.PROP(ty,DAE.C_VAR()),true);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());

        lhs = Expression.makeCrefExp(cr,ty_1);

        dae = InstSection.makeDaeEquation(lhs, rhs, source, SCode.NON_INITIAL());
        // dae = DAEUtil.joinDaes(dae,DAEUtil.extractFunctions(dae1));
      then
        (cache,env_1,ih,store,dae,inSets,ty,graph);

    case (cache,env,ih,store,ci_state,mod,pre,n,(cl,attr),pf,i,_,dims,idxs,inst_dims,impl,comment,_,graph,csets)
      equation
        false = Expression.dimensionKnown(inDimension);
        s = DAE.INDEX(DAE.ICONST(i));
        mod = Mod.lookupIdxModification(mod, i);
        (cache,compenv,ih,store,daeLst,csets,ty,graph) =
          instVar2(cache, env, ih, store, ci_state, mod, pre, n, cl, attr, pf, dims, (s :: idxs), inst_dims, impl, comment,info,graph, csets);
      then
        (cache,compenv,ih,store,daeLst,csets,ty,graph);

    // Special case when instantiating Real[0]. We need to know the type
    case (cache,env,ih,store,ci_state,mod,pre,n,(cl,attr),pf,i,DAE.DIM_INTEGER(0),dims,idxs,inst_dims,impl,comment,_,graph, csets)
      equation
        ErrorExt.setCheckpoint("instArray Real[0]");
        s = DAE.INDEX(DAE.ICONST(0));
        (cache,compenv,ih,store,daeLst,csets,ty,graph) =
           instVar2(cache,env,ih,store, ci_state, DAE.NOMOD(), pre, n, cl, attr,pf, dims, (s :: idxs), inst_dims, impl, comment,info,graph, csets);
        ErrorExt.rollBack("instArray Real[0]");
      then
        (cache,compenv,ih,store,DAE.emptyDae,csets,ty,graph);

    // Keep the errors if we somehow fail
    case (_, _, _, _, _, _, _, _, _, _, _, DAE.DIM_INTEGER(0), _, _, _, _, _, _, _, _)
      equation
        ErrorExt.delCheckpoint("instArray Real[0]");
      then
        fail();

    case
      (cache,env,ih,store,ci_state,mod,pre,n,(cl,attr),pf,i,DAE.DIM_INTEGER(integer = stop),dims,idxs,inst_dims,impl,comment,_,graph,csets)
      equation
        (i > stop) = true;
      then
        (cache,env,ih,store,DAE.emptyDae,csets,DAE.T_UNKNOWN_DEFAULT,graph);

    // adrpo: if a class is derived WITH AN ARRAY DIMENSION we should instVar2 the derived from type not the actual type!!!
    case (cache,env,ih,store,ci_state,mod,pre,n,
          (cl as SCode.CLASS(classDef=SCode.DERIVED(typeSpec=Absyn.TPATH(path,SOME(_)),
                                                    modifications=scodeMod,attributes=absynAttr)),
                                                    attr),
          pf,i,DAE.DIM_INTEGER(integer = stop),dims,idxs,inst_dims,impl,comment,_,graph, _)
      equation
        (_,clBase,_) = Lookup.lookupClass(cache, env, path, true);
        /* adrpo: TODO: merge also the attributes, i.e.:
           type A = input discrete flow Integer[3];
           A x; <-- input discrete flow IS NOT propagated even if it should. FIXME!
         */
        //SOME(attr3) = SCode.mergeAttributes(attr,SOME(absynAttr));

        scodeMod = InstUtil.chainRedeclares(mod, scodeMod);

        (_,mod2) = Mod.elabMod(cache, env, ih, pre, scodeMod, impl,info);
        mod3 = Mod.merge(mod, mod2, env, pre);
        mod_1 = Mod.lookupIdxModification(mod3, i);
        s = DAE.INDEX(DAE.ICONST(i));
        (cache,env_1,ih,store,dae1,csets,ty,graph) =
           instVar2(cache,env,ih, store,ci_state, mod_1, pre, n, clBase, attr,
           pf,dims, (s :: idxs), {} /* inst_dims */, impl, comment,info,graph, inSets);
        i_1 = i + 1;
        (cache,_,ih,store,dae2,csets,_,graph) =
          instArray(cache,env,ih,store, ci_state, mod, pre, n, (cl,attr), pf,
          i_1, DAE.DIM_INTEGER(stop), dims, idxs, {} /* inst_dims */, impl, comment,info,graph, csets);
        daeLst = DAEUtil.joinDaeLst({dae1, dae2});
      then
        (cache,env_1,ih,store,daeLst,csets,ty,graph);

    case (cache,env,ih,store,ci_state,mod,pre,n,(cl,attr),pf,i,DAE.DIM_INTEGER(integer = stop),dims,idxs,inst_dims,impl,comment,_,graph,csets)
      equation
        mod_1 = Mod.lookupIdxModification(mod, i);
        s = DAE.INDEX(DAE.ICONST(i));
        (cache,env_1,ih,store,dae1,csets,ty,graph) =
           instVar2(cache,env,ih, store,ci_state, mod_1, pre, n, cl, attr, pf,dims, (s :: idxs), inst_dims, impl, comment,info,graph, csets);
        i_1 = i + 1;
        (cache,_,ih,store,dae2,csets,_,graph) =
          instArray(cache,env,ih,store, ci_state, mod, pre, n, (cl,attr), pf, i_1, DAE.DIM_INTEGER(stop), dims, idxs, inst_dims, impl, comment,info,graph, csets);
        daeLst = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache,env_1,ih,store,daeLst,csets,ty,graph);

    // Instantiate an array whose dimension is determined by an enumeration.
    case (cache, env, ih, store, ci_state, mod, pre, n, (cl, attr), pf,
        i, DAE.DIM_ENUM(enumTypeName = enum_type, literals = lit :: l), dims,
        idxs, inst_dims, impl, comment, _, graph, csets)
      equation
        mod_1 = Mod.lookupIdxModification(mod, i);
        enum_lit = Absyn.joinPaths(enum_type, Absyn.IDENT(lit));
        s = DAE.INDEX(DAE.ENUM_LITERAL(enum_lit, i));
        enum_size = listLength(l);
        (cache, env_1, ih, store, dae1, csets, ty, graph) =
          instVar2(cache, env, ih, store, ci_state, mod_1, pre, n, cl,
          attr, pf, dims, (s :: idxs), inst_dims, impl, comment, info, graph, csets);
        i_1 = i + 1;
        (cache, _, ih, store, dae2, csets, _, graph) =
          instArray(cache, env, ih, store, ci_state, mod, pre, n, (cl,
          attr), pf, i_1, DAE.DIM_ENUM(enum_type, l, enum_size), dims, idxs,
          inst_dims, impl, comment, info, graph, csets);
        daeLst = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache, env_1, ih, store, daeLst, csets, ty, graph);

    case (cache,env,ih,store,ci_state,mod,pre,n,(cl,attr),pf,i,
      DAE.DIM_ENUM(literals = {}),dims,idxs,inst_dims,impl,comment,
      _,graph, csets)
      then
        (cache,env,ih,store,DAE.emptyDae,csets,DAE.T_UNKNOWN_DEFAULT,graph);

    case (cache, env, ih, store, ci_state, mod, pre, n, (cl, attr), pf, i, DAE.DIM_BOOLEAN(), dims, idxs, inst_dims, impl, comment, _, graph, csets)
      equation
        mod_1 = Mod.lookupIdxModification(mod, i);
        mod_2 = Mod.lookupIdxModification(mod, i+1);
        (cache, env_1, ih, store, dae1, csets, ty, graph) =
          instVar2(cache, env, ih, store, ci_state, mod_1, pre, n, cl, attr, pf, dims, (DAE.INDEX(DAE.BCONST(false)) :: idxs), inst_dims, impl, comment, info, graph, csets);
        (cache, _, ih, store, dae2, csets, ty, graph) =
          instVar2(cache, env, ih, store, ci_state, mod_2, pre, n, cl, attr, pf, dims, (DAE.INDEX(DAE.BCONST(true))  :: idxs), inst_dims, impl, comment, info, graph, csets);
        daeLst = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache, env_1, ih, store, daeLst, csets, ty, graph);

    case (cache,env,ih,store,ci_state,mod,pre,n,(cl,attr),pf,i,_,dims,idxs,inst_dims,impl,comment,_,graph,_)
      equation
        failure(_ = Mod.lookupIdxModification(mod, i));
        str1 = PrefixUtil.printPrefixStrIgnoreNoPre(PrefixUtil.prefixAdd(n, {}, pre, SCode.VAR(), ci_state));
        str2 = "[" +& stringDelimitList(List.map(idxs, ExpressionDump.printSubscriptStr), ", ") +& "]";
        str3 = Mod.prettyPrintMod(mod, 1);
        str4 = PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "(" +& n +& str2 +& "=" +& str3 +& ")";
        str2 = str1 +& str2;
        Error.addSourceMessage(Error.MODIFICATION_INDEX_NOT_FOUND, {str1,str4,str2,str3}, info);
      then
        fail();

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprintln(Flags.FAILTRACE, "- Inst.instArray failed: " +& inIdent);
      then
        fail();
  end matchcontinue;
end instArray;

end InstVar;
