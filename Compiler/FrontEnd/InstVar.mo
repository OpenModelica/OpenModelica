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
public import FCore;
public import FGraph;
public import InnerOuter;
public import InstTypes;
public import Mod;
public import Prefix;
public import SCode;
public import UnitAbsyn;

protected import Config;
protected import ConnectUtil;
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
protected import BaseHashSet;
protected import HashSet;

protected type Ident = DAE.Ident "an identifier";
protected type InstanceHierarchy = InnerOuter.InstHierarchy "an instance hierarchy";
protected type InstDims = list<list<DAE.Dimension>>;

public function instVar
"this function will look if a variable is inner/outer and depending on that will:
  - lookup for inner in the instanance hieararchy if we have ONLY outer
  - instantiate normally via instVar_dispatch otherwise
  - report an error if we have modifications on outer

BTH: Added cases that handles 'outer' and 'inner outer' variables differently if they
are declared wihin an instance of a synchronous State Machine state: basically, instead of
substituting 'outer' variables through their 'inner' counterparts the 'outer' variable is
declared with a modification equation that sets the 'outer' variable equal to the 'inner'
variable. Hence, the information in which instance an 'outer' variable was declared is
preserved in the flattened code. This information is necessary to handle state machines in
the backend. The current implementation doesn't handle cases in which the
'inner' is not (yet) set.
  "
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
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
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean inImpl;
  input SCode.Comment inComment;
  input SourceInfo info;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  input FCore.Graph componentDefinitionParentEnv;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output DAE.Type outType;
  output ConnectionGraph.ConnectionGraph outGraph;
protected
  Absyn.InnerOuter io;
algorithm
  if match inIdent
    case "Integer" then true;
    case "Real" then true;
    case "Boolean" then true;
    case "String" then true;
    else false; end match then
    Error.addSourceMessage(Error.RESERVED_IDENTIFIER, {inIdent}, info);
    fail();
  end if;

  io := SCode.prefixesInnerOuter(inPrefixes);

  (outCache,outEnv,outIH,outStore,outDae,outSets,outType,outGraph) :=
  matchcontinue (inCache, inEnv, inIH, inStore, inState, inMod, inPrefix,
      inIdent, inClass, inAttributes, inPrefixes, inDimensionLst,
      inIntegerLst, inInstDims, inImpl, inComment, info, inGraph, inSets,
      componentDefinitionParentEnv)
    local
      DAE.Dimensions dims;
      FCore.Graph compenv,env,innerCompEnv,outerCompEnv;
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
      FCore.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      DAE.ComponentRef cref, crefOuter, crefInner;
      DAE.Exp crefExp;
      list<DAE.ComponentRef> outers;
      String nInner, typeName, fullName;
      Absyn.Path typePath;
      String innerScope;
      Absyn.InnerOuter ioInner;
      Option<InnerOuter.InstResult> instResult;
      SCode.Prefixes pf;
      UnitAbsyn.InstStore store;
      InnerOuter.TopInstance topInstance;
      HashSet.HashSet sm;
      Absyn.Exp aexp;


    // is ONLY inner
    case (cache,env,ih,store,ci_state,mod,pre,n,cl as SCode.CLASS(name=typeName),attr,pf,dims,idxs,inst_dims,impl,comment,_,graph,csets,_)
      equation
        // only inner!
        true = Absyn.isOnlyInner(io);

        // fprintln(Flags.INNER_OUTER, "- InstVar.instVar inner: " + PrefixUtil.printPrefixStr(pre) + "/" + n + " in env: " + FGraph.printGraphPathStr(env));

        // instantiate as inner
        (cache,innerCompEnv,ih,store,dae,csets,ty,graph) =
          instVar_dispatch(cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,info,graph,csets);

        (cache,cref) = PrefixUtil.prefixCref(cache,env,ih,pre, ComponentReference.makeCrefIdent(n, DAE.T_UNKNOWN_DEFAULT, {}));
        fullName = ComponentReference.printComponentRefStr(cref);
        (cache, typePath) = Inst.makeFullyQualified(cache, env, Absyn.IDENT(typeName));

        // also all the components in the environment should be updated to be outer!
        // switch components from inner to outer in the component env.
        outerCompEnv = InnerOuter.switchInnerToOuterInGraph(innerCompEnv, cref);

        // outer doesn't generate a visible DAE
        outerDAE = DAE.emptyDae;

        innerScope = FGraph.printGraphPathStr(componentDefinitionParentEnv);

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
        true = Absyn.isOnlyOuter(io);

        // we should have here any kind of modification!
        false = Mod.modEqual(mod, DAE.NOMOD());
        (cache,cref) = PrefixUtil.prefixCref(cache,env,ih,pre, ComponentReference.makeCrefIdent(n, DAE.T_UNKNOWN_DEFAULT, {}));
        s1 = ComponentReference.printComponentRefStr(cref);
        s2 = Mod.prettyPrintMod(mod, 0);
        s = s1 +  " " + s2;
        // add a warning!
        Error.addSourceMessage(Error.OUTER_MODIFICATION, {s}, info);

        // call myself without any modification!
        (cache,compenv,ih,store,dae,csets,ty,graph) =
          instVar(cache,env,ih,store,ci_state,DAE.NOMOD(),pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,info,graph,csets,componentDefinitionParentEnv);
     then
        (cache,compenv,ih,store,dae,csets,ty,graph);

    // is ONLY outer output and is inside an instance of a State Machine state
    case (cache,env,ih,store,ci_state,mod,pre,n,cl,attr as SCode.ATTR(direction=Absyn.OUTPUT()),pf,dims,idxs,inst_dims,impl,comment,_,graph, csets, _)
      equation
        // only outer!
        true = Absyn.isOnlyOuter(io);

        // we should have NO modifications on only outer!
        true = Mod.modEqual(mod, DAE.NOMOD());

        // lookup in IH
        InnerOuter.INST_INNER(
           innerPrefix,
           _,
           _,
           _,
           _,
           _,
           SOME(InnerOuter.INST_RESULT(cache,compenv,store,_,_,ty,graph)),
           _,_) =
          InnerOuter.lookupInnerVar(cache, env, ih, pre, n, io);


        // the outer must be in an instance that is part of a State Machine
        cref = PrefixUtil.prefixToCref(inPrefix);
        topInstance = listHead(ih);
        InnerOuter.TOP_INSTANCE(sm=sm) = topInstance;
        true = BaseHashSet.has(cref, sm);

        (cache,compenv,ih,store,dae,csets,ty,graph) =
          instVar_dispatch(cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,info,graph,csets);
      then
        (inCache,compenv,ih,store,dae,csets,ty,graph);


    // is ONLY outer
    case (cache,env,ih,store,_,mod,pre,n,_,_,pf,_,_,_,_,_,_,graph,csets,_)
      equation
        // only outer!
        true = Absyn.isOnlyOuter(io);

        // we should have NO modifications on only outer!
        true = Mod.modEqual(mod, DAE.NOMOD());

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
        true = Absyn.isOnlyOuter(io);

        // no modifications!
        true = Mod.modEqual(mod, DAE.NOMOD());

        // lookup in IH, crap, we couldn't find it!
        // lookup in IH
        InnerOuter.INST_INNER(
           _,
           _,
           _,
           _,
           typePath,
           _,
           NONE(),
           _,_) =
          InnerOuter.lookupInnerVar(cache, env, ih, pre, n, io);

        // fprintln(Flags.INNER_OUTER, "- InstVar.instVar failed to lookup inner: " + PrefixUtil.printPrefixStr(pre) + "/" + n + " in env: " + FGraph.printGraphPathStr(env));

        // display an error message!
        (cache,crefOuter) = PrefixUtil.prefixCref(cache,env,ih,pre, ComponentReference.makeCrefIdent(n, DAE.T_UNKNOWN_DEFAULT, {}));
        typeName = SCode.className(cl);
        (cache, typePath) = Inst.makeFullyQualified(cache, env, Absyn.IDENT(typeName));
        // adrpo: do NOT! display an error message if impl = true and prefix is Prefix.NOPRE()
        // print(if_(impl, "impl crap\n", "no impl\n"));
        if not (impl and listMember(pre, {Prefix.NOPRE()})) then
          s1 = ComponentReference.printComponentRefStr(crefOuter);
          s2 = Dump.unparseInnerouterStr(io);
          s3 = InnerOuter.getExistingInnerDeclarations(ih, componentDefinitionParentEnv);
          s1 = Absyn.pathString(typePath) + " " + s1;
          Error.addSourceMessage(Error.MISSING_INNER_PREFIX,{s1, s2, s3}, info);
        end if;

        // call it normaly
        (cache,compenv,ih,store,dae,_,ty,graph) =
          instVar_dispatch(cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,info,graph, csets);
      then
        (cache,compenv,ih,store,dae,csets,ty,graph);

    // is ONLY outer and the inner was not yet set in the IH or we have no inner declaration!
    case (cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,_,graph,csets,_)
      equation
        // only outer!
        true = Absyn.isOnlyOuter(io);

        // no modifications!
        true = Mod.modEqual(mod, DAE.NOMOD());

        // lookup in IH, crap, we couldn't find it!
        failure(_ = InnerOuter.lookupInnerVar(cache, env, ih, pre, n, io));

        // fprintln(Flags.INNER_OUTER, "- InstVar.instVar failed to lookup inner: " + PrefixUtil.printPrefixStr(pre) + "/" + n + " in env: " + FGraph.printGraphPathStr(env));

        // display an error message!
        (cache,crefOuter) = PrefixUtil.prefixCref(cache,env,ih,pre, ComponentReference.makeCrefIdent(n, DAE.T_UNKNOWN_DEFAULT, {}));
        typeName = SCode.className(cl);
        (cache, typePath) = Inst.makeFullyQualified(cache, env, Absyn.IDENT(typeName));
        // print(if_(impl, "impl crap\n", "no impl\n"));
        // adrpo: do NOT! display an error message if impl = true and prefix is Prefix.NOPRE()
        if not (impl and listMember(pre, {Prefix.NOPRE()})) then
          s1 = ComponentReference.printComponentRefStr(crefOuter);
          s2 = Dump.unparseInnerouterStr(io);
          s3 = InnerOuter.getExistingInnerDeclarations(ih,componentDefinitionParentEnv);
          s1 = Absyn.pathString(typePath) + " " + s1;
          Error.addSourceMessage(Error.MISSING_INNER_PREFIX,{s1, s2, s3}, info);
        end if;

        // call it normally
        (cache,compenv,ih,store,dae,_,ty,graph) =
           instVar_dispatch(cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,info,graph, csets);
      then
        (cache,compenv,ih,store,dae,csets,ty,graph);

    // is inner outer output and is inside an instance of a State Machine state!
    case (cache,env,ih,store,ci_state,mod,pre,n,cl as SCode.CLASS(name=typeName),attr as SCode.ATTR(direction=Absyn.OUTPUT()) ,pf,dims,idxs,inst_dims,impl,comment,_,graph, csets, _)
      equation
        // both inner and outer
        true = Absyn.isInnerOuter(io);

        // the inner outer must be in an instance that is part of a State Machine
        cref = PrefixUtil.prefixToCref(inPrefix);
        topInstance = listHead(ih);
        InnerOuter.TOP_INSTANCE(sm=sm) = topInstance;
        true = BaseHashSet.has(cref, sm);

        (cache,innerCompEnv,ih,store,dae,csetsInner,ty,graph) =
           instVar_dispatch(cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,info,graph, csets);

        // add it to the instance hierarchy
        (cache,cref) = PrefixUtil.prefixCref(cache,env,ih,pre, ComponentReference.makeCrefIdent(n, DAE.T_UNKNOWN_DEFAULT, {}));
        fullName = ComponentReference.printComponentRefStr(cref);
        (cache, typePath) = Inst.makeFullyQualified(cache, env, Absyn.IDENT(typeName));

        // also all the components in the environment should be updated to be outer!
        // switch components from inner to outer in the component env.
        outerCompEnv = InnerOuter.switchInnerToOuterInGraph(innerCompEnv, cref);

        // keep the dae we get from the instantiation of the inner
        innerDAE = dae;

        innerScope = FGraph.printGraphPathStr(componentDefinitionParentEnv);

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

        // now call it normally
        (cache,compenv,ih,store,dae,_,ty,graph) =
           instVar_dispatch(cache,env,ih,store,ci_state,DAE.NOMOD(),pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,info,graph, csets);
      then
        (cache,compenv,ih,store,dae,csetsInner,ty,graph);

    // is inner outer!
    case (cache,env,ih,store,ci_state,mod,pre,n,cl as SCode.CLASS(name=typeName),attr,pf,dims,idxs,inst_dims,impl,comment,_,graph, csets, _)
      equation
        // both inner and outer
        true = Absyn.isInnerOuter(io);

        // fprintln(Flags.INNER_OUTER, "- InstVar.instVar inner outer: " + PrefixUtil.printPrefixStr(pre) + "/" + n + " in env: " + FGraph.printGraphPathStr(env));

        (cache,innerCompEnv,ih,store,dae,csetsInner,ty,graph) =
           instVar_dispatch(cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,info,graph, csets);

        // add it to the instance hierarchy
        (cache,cref) = PrefixUtil.prefixCref(cache,env,ih,pre, ComponentReference.makeCrefIdent(n, DAE.T_UNKNOWN_DEFAULT, {}));
        fullName = ComponentReference.printComponentRefStr(cref);
        (cache, typePath) = Inst.makeFullyQualified(cache, env, Absyn.IDENT(typeName));

        // also all the components in the environment should be updated to be outer!
        // switch components from inner to outer in the component env.
        outerCompEnv = InnerOuter.switchInnerToOuterInGraph(innerCompEnv, cref);

        // keep the dae we get from the instantiation of the inner
        innerDAE = dae;

        innerScope = FGraph.printGraphPathStr(componentDefinitionParentEnv);

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
        (cache,compenv,ih,store,dae,_,ty,graph) =
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
        true = Absyn.isNotInnerOuter(io);

        // fprintln(Flags.INNER_OUTER, "- InstVar.instVar NO inner NO outer: " + PrefixUtil.printPrefixStr(pre) + "/" + n + " in env: " + FGraph.printGraphPathStr(env));

        (cache,compenv,ih,store,dae,csets,ty,graph) =
          instVar_dispatch(cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,idxs,inst_dims,impl,comment,info,graph,csets);
      then
        (cache,compenv,ih,store,dae,csets,ty,graph);

    // failtrace
    case (cache,env,ih,_,_,mod,pre,n,cl,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        (cache,cref) = PrefixUtil.prefixCref(cache,env,ih,pre, ComponentReference.makeCrefIdent(n, DAE.T_UNKNOWN_DEFAULT, {}));
        Debug.traceln("- InstVar.instVar failed while instatiating variable: " +
          ComponentReference.printComponentRefStr(cref) + " " + Mod.prettyPrintMod(mod, 0) +
          "\nin scope: " + FGraph.printGraphPathStr(env) + " class:\n" + SCodeDump.unparseElementStr(cl));
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input ClassInf.State inState;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input String inName;
  input SCode.Element inClass;
  input SCode.Attributes inAttributes;
  input SCode.Prefixes inPrefixes;
  input list<DAE.Dimension> inDimensions;
  input list<DAE.Subscript> inIndices;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean inImpl;
  input SCode.Comment inComment;
  input SourceInfo inInfo;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output DAE.Type outType;
  output ConnectionGraph.ConnectionGraph outGraph;
protected
  String comp_name;
  list<DAE.Dimension> dims;
  SCode.Element cls;
  DAE.Mod type_mods, mod;
  SCode.Attributes attr;
  DAE.ElementSource source;
algorithm
  try
    comp_name := Absyn.pathString(PrefixUtil.prefixPath(Absyn.IDENT(inName), inPrefix));
    Error.updateCurrentComponent(comp_name, inInfo);

    (outCache, dims, cls, type_mods) :=
      InstUtil.getUsertypeDimensions(inCache, inEnv, inIH, inPrefix, inClass, inInstDims, inImpl);

    if listEmpty(dims) then
      // No dimensions from userdefined type.
      dims := inDimensions;
      cls := inClass;
      mod := inMod;
      attr := inAttributes;
    else
      // Userdefined array type, e.g. type Point = Real[3].
      type_mods := liftUserTypeMod(type_mods, inDimensions);
      dims := listAppend(inDimensions, dims);
      mod := Mod.merge(inMod, type_mods, inEnv, inPrefix);
      attr := InstUtil.propagateClassPrefix(inAttributes, inPrefix);
    end if;

    (outCache, outEnv, outIH, outStore, outDae, outSets, outType, outGraph) :=
      instVar2(outCache, inEnv, inIH, inStore, inState, mod, inPrefix, inName,
        cls, attr, inPrefixes, dims, inIndices, inInstDims, inImpl, inComment,
        inInfo, inGraph, inSets);

    source := DAEUtil.createElementSource(inInfo, FGraph.getScopePath(inEnv),
      PrefixUtil.prefixToCrefOpt(inPrefix), NONE(), NONE());
    (outCache, outDae) := addArrayVarEquation(outCache, inEnv, outIH, inState,
      outDae, outType, mod, NFInstUtil.toConst(SCode.attrVariability(attr)),
      inPrefix, inName, source);
    outCache := InstFunction.addRecordConstructorFunction(outCache, inEnv,
      Types.arrayElementType(outType), SCode.elementInfo(inClass));

    Error.updateCurrentComponent("", Absyn.dummyInfo);
  else
    Error.updateCurrentComponent("", Absyn.dummyInfo);
    fail();
  end try;
end instVar_dispatch;

protected function liftUserTypeMod
  "This function adds dimensions to a modifier. This is a bit of a hack to make
   modifiers on user-defined types behave as expected, e.g.:

     type T = Real[3](start = {1, 2, 3});
     T x[2]; // Modifier from T must be lifted to become [2, 3].
  "
  input DAE.Mod inMod;
  input list<DAE.Dimension> inDims;
  output DAE.Mod outMod = inMod;
algorithm
  if listEmpty(inDims) then
    return;
  end if;

  outMod := matchcontinue outMod
    case DAE.MOD()
      algorithm
        // Only lift modifiers without 'each'.
        if not SCode.eachBool(outMod.eachPrefix) then
          outMod.eqModOption := liftUserTypeEqMod(outMod.eqModOption, inDims);
          outMod.subModLst := list(liftUserTypeSubMod(s, inDims) for s in outMod.subModLst);
        end if;
      then
        outMod;

    else outMod;
  end matchcontinue;
end liftUserTypeMod;

protected function liftUserTypeSubMod
  input DAE.SubMod inSubMod;
  input list<DAE.Dimension> inDims;
  output DAE.SubMod outSubMod = inSubMod;
algorithm
  outSubMod := match outSubMod
    case DAE.NAMEMOD()
      algorithm
        outSubMod.mod := liftUserTypeMod(outSubMod.mod, inDims);
      then
        outSubMod;
  end match;
end liftUserTypeSubMod;

protected function liftUserTypeEqMod
  input Option<DAE.EqMod> inEqMod;
  input list<DAE.Dimension> inDims;
  output Option<DAE.EqMod> outEqMod;
protected
  DAE.EqMod eq;
  DAE.Type ty;
algorithm
  if isNone(inEqMod) then
    outEqMod := inEqMod;
    return;
  end if;

  SOME(eq) := inEqMod;

  eq := match eq
    case DAE.TYPED()
      algorithm
        eq.modifierAsExp := Expression.liftExpList(eq.modifierAsExp, inDims);
        eq.modifierAsValue := Util.applyOption1(eq.modifierAsValue,
          ValuesUtil.liftValueList, inDims);
        ty := Types.getPropType(eq.properties);
        eq.properties := Types.setPropType(eq.properties,
          Types.liftArrayListDims(ty, inDims));
      then
        eq;

    else eq;
  end match;

  outEqMod := SOME(eq);
end liftUserTypeEqMod;

protected function addArrayVarEquation
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input ClassInf.State inState;
  input DAE.DAElist inDae;
  input DAE.Type inType;
  input DAE.Mod mod;
  input DAE.Const const;
  input Prefix.Prefix pre;
  input String n;
  input DAE.ElementSource source;
  output FCore.Cache outCache;
  output DAE.DAElist outDae;
algorithm
  (outCache,outDae) := matchcontinue (inDae, const)
    local
      FCore.Cache cache;
      list<DAE.Element> dae;
      DAE.Exp exp;
      DAE.Element eq;
      DAE.Dimensions dims;
      DAE.ComponentRef cr;
      DAE.Type ty;

    // Don't add array equations if +scalarizeBindings is set.
    case (_, _)
      equation
        true = Config.scalarizeBindings();
      then
        (inCache, inDae);

    case (DAE.DAE(dae), DAE.C_VAR())
      equation
        false = ClassInf.isFunctionOrRecord(inState);
        ty = Types.simplifyType(inType);
        false = Types.isExternalObject(Types.arrayElementType(ty));
        false = Types.isComplexType(Types.arrayElementType(ty));
        (dims as _::_) = Types.getDimensions(ty);
        SOME(exp) = InstBinding.makeVariableBinding(ty, mod, const, pre, n);
        cr = ComponentReference.makeCrefIdent(n,ty,{});
        (cache,cr) = PrefixUtil.prefixCref(inCache,inEnv,inIH,pre,cr);
        eq = DAE.ARRAY_EQUATION(dims, DAE.CREF(cr,ty), exp, source);
        // print("Creating array equation for " + PrefixUtil.printPrefixStr(pre) + "." + n + " of const " + DAEUtil.constStr(const) + " in classinf " + ClassInf.printStateStr(inState) + "\n");
      then (cache,DAE.DAE(eq::dae));

    else (inCache,inDae);
  end matchcontinue;
end addArrayVarEquation;

protected function instVar2
"Helper function to instVar, does the main work."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
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
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean inImpl;
  input SCode.Comment inComment;
  input SourceInfo inInfo;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
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
      list<DAE.Dimension> dims_1;
      DAE.Exp e,e_1;
      DAE.Properties p;
      FCore.Graph env_1,env,compenv;
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
      DAE.Dimension dim,dim2;
      FCore.Cache cache;
      SCode.Visibility vis;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      String n2;
      Integer deduced_dim;
      DAE.Subscript dime2;
      SCode.Prefixes pf;
      SCode.Final fin;
      SourceInfo info;
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
     case (cache,env,ih,store,ci_state,mod as DAE.MOD(eqModOption = NONE()),pre,n,cl as SCode.CLASS(restriction = SCode.R_RECORD(_)),attr,pf,dims,_,inst_dims,impl,comment,info,graph,csets)
      equation
        true = ClassInf.isFunction(ci_state);
        InstUtil.checkFunctionVar(n, attr, pf, info);


        //Instantiate type of the component, skip dae/not flattening (but extract functions)
        // adrpo: do not send in the modifications as it will fail if the modification is an ARRAY.
        //        anyhow the modifications are handled below.
        //        input Integer sequence[3](min = {1,1,1}, max = {3,3,3}) = {1,2,3}; // this will fail if we send in the mod.
        //        see testsuite/mofiles/Sequence.mo
        (cache,env_1,ih,store,_,csets,ty,_,_,graph) =
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
        source = DAEUtil.createElementSource(info, FGraph.getScopePath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());


        SCode.PREFIXES(visibility = vis, finalPrefix = fin, innerOuter = io) = pf;
        dae = InstDAE.daeDeclare(cache, env, env_1, cr, ci_state, ty, attr, vis, SOME(e), {dims}, NONE(), dae_var_attr, SOME(comment), io, fin, source, true);
        store = UnitAbsynBuilder.instAddStore(store,ty,cr);
      then
        (cache,env_1,ih,store,dae,csets,ty_1,graph);

    // mahge: function variables with eqMod modifications.
    // FIXHERE: They might have subMods too (variable attributes). see testsuite/mofiles/Sequence.mo
    case (cache,env,ih,store,ci_state,mod as DAE.MOD(eqModOption = SOME(_)),pre,n,cl,attr,pf,dims,_,inst_dims,impl,comment,info,graph,csets)
      equation
        true = ClassInf.isFunction(ci_state);
        InstUtil.checkFunctionVar(n, attr, pf, info);

        //get the equation modification
        SOME(DAE.TYPED(e,_,p,_,_)) = Mod.modEquation(mod);
        //Instantiate type of the component, skip dae/not flattening (but extract functions)
        // adrpo: do not send in the modifications as it will fail if the modification is an ARRAY.
        //        anyhow the modifications are handled below.
        //        input Integer sequence[3](min = {1,1,1}, max = {3,3,3}) = {1,2,3}; // this will fail if we send in the mod.
        //        see testsuite/mofiles/Sequence.mo
        (cache,env_1,ih,store,_,csets,ty,_,_,graph) =
          Inst.instClass(cache, env, ih, store, /* mod */ DAE.NOMOD(), pre, cl, inst_dims, impl, InstTypes.INNER_CALL(), graph, csets);
        //Make it an array type since we are not flattening
        ty_1 = InstUtil.makeArrayType(dims, ty);
        InstUtil.checkFunctionVarType(ty_1, ci_state, n, info);

        (cache,dae_var_attr) = InstBinding.instDaeVariableAttributes(cache, env, mod, ty, {});
        // Check binding type matches variable type
        (e_1,_) = Types.matchProp(e,p,DAE.PROP(ty_1,DAE.C_VAR()),true);

        //Generate variable with default binding
        ty_2 = Types.simplifyType(ty_1);
        (cache,cr) = PrefixUtil.prefixCref(cache,env,ih,pre, ComponentReference.makeCrefIdent(n,ty_2,{}));

        // set the source of this element
        source = DAEUtil.createElementSource(info, FGraph.getScopePath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());


        SCode.PREFIXES(visibility = vis, finalPrefix = fin, innerOuter = io) = pf;
        dae = InstDAE.daeDeclare(cache, env, env_1, cr, ci_state, ty, attr, vis, SOME(e_1), {dims}, NONE(), dae_var_attr, SOME(comment), io, fin, source, true);
        store = UnitAbsynBuilder.instAddStore(store,ty,cr);
      then
        (cache,env_1,ih,store,dae,csets,ty_1,graph);


    // Function variables without binding
    case (cache,env,ih,store,ci_state,mod,pre,n,(cl as SCode.CLASS()),attr,pf,dims,_,inst_dims,impl,comment,info,graph,csets)
       equation
        true = ClassInf.isFunction(ci_state);
        InstUtil.checkFunctionVar(n, attr, pf, info);

         //Instantiate type of the component, skip dae/not flattening
        (cache,env_1,ih,store,_,csets,ty,_,_,_) =
          Inst.instClass(cache, env, ih, store, mod, pre, cl, inst_dims, impl, InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, csets);
        arrty = InstUtil.makeArrayType(dims, ty);
        InstUtil.checkFunctionVarType(arrty, ci_state, n, info);
        (cache,cr) = PrefixUtil.prefixCref(cache,env,ih,pre, ComponentReference.makeCrefIdent(n,arrty,{}));
        (cache,dae_var_attr) = InstBinding.instDaeVariableAttributes(cache,env, mod, ty, {});

        // set the source of this element
        source = DAEUtil.createElementSource(info, FGraph.getScopePath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());

        SCode.PREFIXES(visibility = vis, finalPrefix = fin, innerOuter = io) = pf;
        dae = InstDAE.daeDeclare(cache, env, env_1, cr, ci_state, ty, attr,vis,NONE(), {dims},NONE(), dae_var_attr, SOME(comment),io,fin,source,true);
        store = UnitAbsynBuilder.instAddStore(store,ty,cr);
      then
        (cache,env_1,ih,store,dae,csets,arrty,graph);

    // Scalar variables.
    case (_, _, _, _, _, _, _, _, _, _, _, {}, _, _, _, _, _, _, _)
      equation
        false = ClassInf.isFunction(inState);
        // print("InstVar.instVar2: Scalar variables case: inClass: " + SCodeDump.unparseElementStr(inClass) + "\n");
        (cache, env, ih, store, dae, csets, ty, graph) = instScalar(
            inCache, inEnv, inIH, inStore, inState, inMod, inPrefix,
            inName, inClass, inAttributes, inPrefixes, inSubscripts,
            inInstDims, inImpl, SOME(inComment), inInfo, inGraph, inSets);
      then
        (cache, env, ih, store, dae, csets, ty, graph);

    // Array variables with unknown dimensions, e.g. Real x[:] = [some expression that can be used to determine dimension].
    case (cache,env,ih,store,ci_state,(mod as DAE.MOD(eqModOption = SOME(DAE.TYPED(_,_,_,_,_)))),pre,n,cl,attr,pf,
        ((dim as DAE.DIM_UNKNOWN()) :: dims),idxs,inst_dims,impl,comment,info,graph, csets)
      equation
        true = Config.splitArrays();
        false = ClassInf.isFunction(ci_state);

        // Try to deduce the dimension from the modifier.
        dim2 = InstUtil.instWholeDimFromMod(dim, mod, n, info);
        inst_dims_1 = List.appendLastList(inst_dims, {dim2});

        (cache,compenv,ih,store,dae,csets,ty,graph) =
          instArray(cache,env,ih,store, ci_state, mod, pre, n, (cl,attr), pf, 1, dim2, dims, idxs, inst_dims_1, impl, comment,info,graph, csets);
        ty_1 = InstUtil.liftNonBasicTypes(ty,dim2); // Do not lift types extending basic type, they are already array types.
      then
        (cache,compenv,ih,store,dae,csets,ty_1,graph);

    // Array variables with unknown dimensions, non-expanding case
    case (cache,env,ih,store,ci_state,(mod as DAE.MOD(eqModOption = SOME(DAE.TYPED(_,_,_,_,_)))),pre,n,cl,attr,pf,
      ((dim as DAE.DIM_UNKNOWN()) :: dims),idxs,inst_dims,impl,comment,info,graph, csets)
      equation
        false = Config.splitArrays();
        false = ClassInf.isFunction(ci_state);
        // Try to deduce the dimension from the modifier.
        /*TODO : mahge: remove this*/
        /*
        dime = InstUtil.instWholeDimFromMod(dim, mod, n, info);
        dime2 = InstUtil.makeNonExpSubscript(dime);
        dim2 = Expression.subscriptDimension(dime);
        inst_dims_1 = List.appendLastList(inst_dims, {dime2});
        */
        dim2 = InstUtil.instWholeDimFromMod(dim, mod, n, info);
        inst_dims_1 = List.appendLastList(inst_dims, {dim2});
        dime2 = Expression.dimensionSubscript(dim2);

        (cache,compenv,ih,store,dae,csets,ty,graph) =
          instVar2(cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,dime2::idxs,inst_dims_1,impl,comment,info,graph,csets);
        ty_1 = InstUtil.liftNonBasicTypes(ty,dim2); // Do not lift types extending basic type, they are already array types.
      then
        (cache,compenv,ih,store,dae,csets,ty_1,graph);

    // Array variables , e.g. Real x[3]
    case (cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,(dim :: dims),idxs,inst_dims,impl,comment,info,graph,csets)
      equation
        true = Config.splitArrays();
        false = ClassInf.isFunction(ci_state);

        // dim = InstUtil.evalEnumAndBoolDim(dim);
        inst_dims_1 = List.appendLastList(inst_dims, {dim});

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
        /*TODO : mahge: remove this*/
        /*
        dime = InstUtil.instDimExpNonSplit(dim, impl);
        inst_dims_1 = List.appendLastList(inst_dims, {dime});
        */
        inst_dims_1 = List.appendLastList(inst_dims, {dim});
        dime = Expression.dimensionSubscript(dim);

        (cache,compenv,ih,store,dae,csets,ty,graph) =
          instVar2(cache,env,ih,store,ci_state,mod,pre,n,cl,attr,pf,dims,dime::idxs,inst_dims_1,impl,comment,info,graph,csets);
        // Type lifting is done in the "scalar" case
        //ty_1 = InstUtil.liftNonBasicTypes(ty,dim); // Do not lift types extending basic type, they are already array types.
      then
        (cache,compenv,ih,store,dae,csets,ty,graph);

    // Array variable with unknown dimensions, but no binding
    case (_,_,_,_,_,DAE.NOMOD(),_,n,_,_,_,
      ((DAE.DIM_UNKNOWN()) :: _),_,_,_,_,info,_,_)
      equation
        Error.addSourceMessage(Error.FAILURE_TO_DEDUCE_DIMS_NO_MOD,{n},info);
      then
        fail();

    // failtrace
    case (_,env,_,_,_,mod,pre,n,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- InstVar.instVar2 failed: " +
          PrefixUtil.printPrefixStr(pre) + "." +
          n + "(" + Mod.prettyPrintMod(mod, 0) + ")\n  Scope: " +
          FGraph.printGraphPathStr(env));
      then
        fail();
  end matchcontinue;
end instVar2;

public function instScalar
  "Instantiates a scalar variable."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
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
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean inImpl;
  input Option<SCode.Comment> inComment;
  input SourceInfo inInfo;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
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
      FCore.Cache cache;
      FCore.Graph env, env_1;
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
      list<DAE.Dimension> predims;

    case (cache, env, ih, store, _, mod, _, _,
        SCode.CLASS(name = cls_name, restriction = res), SCode.ATTR(variability = vt),
        SCode.PREFIXES(visibility = vis, finalPrefix = fin, innerOuter = io),
        idxs, _, _, _, _, _, _)
      equation
        // Instantiate the components class.
        idxs = listReverse(idxs);
        ci_state = ClassInf.start(res, Absyn.IDENT(cls_name));
        predims = List.lastListOrEmpty(inInstDims);
        pre = PrefixUtil.prefixAdd(inName, predims, idxs, inPrefix, vt, ci_state);
        (cache, env_1, ih, store, dae1, csets, ty,_, opt_attr, graph) =
          Inst.instClass(cache, env, ih, store, inMod, pre, inClass, inInstDims,
            inImpl, InstTypes.INNER_CALL(), inGraph, inSets);

        // Propagate and instantiate attributes.
        (cache, dae_var_attr) = InstBinding.instDaeVariableAttributes(cache, env_1, inMod, ty, {});
        attr = InstUtil.propagateAbSCDirection(vt, inAttributes, opt_attr, inInfo);
        attr = SCode.removeAttributeDimensions(attr);

        // Attempt to set the correct type for array variable if splitArrays is
        // false. Does not work correctly yet.
        /* TODO: mahge: this should be removed
        ty = Debug.bcallret2(not Config.splitArrays(), Types.liftArraySubscriptList,
          ty, List.flatten(inInstDims), ty);
          */

        // Make a component reference for the component.
        ident_ty = InstUtil.makeCrefBaseType(ty, inInstDims);
        cr = ComponentReference.makeCrefIdent(inName, ident_ty, idxs);
        (cache, cr) = PrefixUtil.prefixCref(cache, env, ih, inPrefix, cr);

        // adrpo: we cannot check this here as:
        //        we might have modifications on inner that we copy here
        //        Dymola doesn't report modifications on outer as error!
        //        instead we check here if the modification is not the same
        //        as the one on inner
        InstUtil.checkModificationOnOuter(cache, env_1, ih, inPrefix, inName, cr, inMod,
          vt, io, inImpl, inInfo);

        // Set the source of this element.
        source = DAEUtil.createElementSource(inInfo, FGraph.getScopePath(env_1),
          PrefixUtil.prefixToCrefOpt(inPrefix), NONE(), NONE());

        // Instantiate the components binding.
        mod = if not listEmpty(inSubscripts) and not SCode.isParameterOrConst(vt) and not ClassInf.isFunctionOrRecord(inState) and not Types.isComplexType(Types.arrayElementType(ty)) and not Types.isExternalObject(Types.arrayElementType(ty)) and not Config.scalarizeBindings()
                 then DAE.NOMOD()
                 else inMod;
        opt_binding = InstBinding.makeVariableBinding(ty, mod, NFInstUtil.toConst(vt), inPrefix, inName);
        start = InstBinding.instStartBindingExp(inMod /* Yup, let's keep the start-binding. It seems sane. */, ty, vt);

        // Propagate the final prefix from the modifier.
        //fin = InstUtil.propagateModFinal(mod, fin);

        attr = stripVarAttrDirection(cr, ih, inState, inPrefix, attr);

        // Propagate prefixes to any elements inside this components if it's a
        // structured component.
        dae1 = InstUtil.propagateAttributes(dae1, attr, inPrefixes, inInfo);

        // Add the component to the DAE.
        dae2 = InstDAE.daeDeclare(cache, env, env_1, cr, inState, ty, attr, vis, opt_binding, inInstDims,
          start, dae_var_attr, inComment, io, fin, source, false);
        dae2 = DAEUtil.addComponentTypeOpt(dae2, Types.getClassnameOpt(ty));
        store = UnitAbsynBuilder.instAddStore(store, ty, cr);

        // The remaining work is done in instScalar2.
        dae = instScalar2(cr, ty, vt, inMod, dae2, dae1, source, inImpl);
      then
        (cache, env_1, ih, store, dae, csets, ty, graph);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Inst.instScalar failed on " + inName + " in scope " + PrefixUtil.printPrefixStr(inPrefix) + " env: " + FGraph.printGraphPathStr(inEnv) + "\n");
      then
        fail();
  end matchcontinue;
end instScalar;

protected function stripVarAttrDirection
  "This function strips the input/output prefixes from components which are not
   top-level or inside a top-level connector or part of a state machine component."
  input DAE.ComponentRef inCref;
  input InstanceHierarchy ih;
  input ClassInf.State inState;
  input Prefix.Prefix inPrefix;
  input SCode.Attributes inAttributes;
  output SCode.Attributes outAttributes;
algorithm
  outAttributes := matchcontinue (inCref, inState, inAttributes)
    local
      DAE.ComponentRef cref;
      InnerOuter.TopInstance topInstance;
      HashSet.HashSet sm;
    // Component without input/output.
    case (_, _, SCode.ATTR(direction = Absyn.BIDIR())) then inAttributes;
    // Non-qualified identifier = top-level component.
    case (DAE.CREF_IDENT(), _, _) then inAttributes;
    // Outside connector
    case (_, ClassInf.CONNECTOR(), _)
      guard(ConnectUtil.faceEqual(ConnectUtil.componentFaceType(inCref), Connect.OUTSIDE()))
      then inAttributes;
    // Component with input/output that is part of a state machine
    case (_, _, _)
      equation
        cref = PrefixUtil.prefixToCref(inPrefix);
        topInstance = listHead(ih);
        InnerOuter.TOP_INSTANCE(sm=sm) = topInstance;
        true = BaseHashSet.has(cref, sm);
      then inAttributes;
    // Everything else, strip the input/output prefix.
    else SCode.setAttributesDirection(inAttributes, Absyn.BIDIR());
  end matchcontinue;
end stripVarAttrDirection;

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
      DAE.DAElist dae, cls_dae;

    // Constant with binding.
    case (_, _, SCode.CONST(), DAE.MOD(eqModOption = SOME(DAE.TYPED())),
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
    case (_, _, SCode.PARAM(), DAE.MOD(eqModOption = SOME(DAE.TYPED())),
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
        dae = if Types.isComplexType(inType) then InstBinding.instModEquation(inCref, inType, inMod, inSource, inImpl) else DAE.emptyDae;
        cls_dae = stripRecordDefaultBindingsFromDAE(inClassDae, inType, dae);
        dae = DAEUtil.joinDaes(dae, inDae);
        dae = DAEUtil.joinDaes(cls_dae, dae);
      then
        dae;
  end match;
end instScalar2;

protected function stripRecordDefaultBindingsFromDAE
  "This function removes bindings from record members for which a binding
   equation has already been generated. This is done because the record members
   otherwise get a binding from the default argument of the record too."
  input DAE.DAElist inClassDAE;
  input DAE.Type inType;
  input DAE.DAElist inEqDAE;
  output DAE.DAElist outClassDAE;
algorithm
  outClassDAE := match(inClassDAE, inType, inEqDAE)
    local
      list<DAE.Element> els, eqs;

    // Check if the component is of record type, and if any equations have been
    // generated for the component's binding.
    case (DAE.DAE(elementLst = els),
          DAE.T_COMPLEX(complexClassType = ClassInf.RECORD()),
          DAE.DAE(elementLst = eqs as _ :: _))
      equation
        // This assumes that the equations are ordered the same as the variables.
        (els, _) = List.mapFold(els, stripRecordDefaultBindingsFromElement, eqs);
      then
        DAE.DAE(els);

    else inClassDAE;
  end match;
end stripRecordDefaultBindingsFromDAE;

protected function stripRecordDefaultBindingsFromElement
  input DAE.Element inVar;
  input list<DAE.Element> inEqs;
  output DAE.Element outVar;
  output list<DAE.Element> outEqs;
algorithm
  (outVar, outEqs) := match(inVar, inEqs)
    local
      DAE.ComponentRef var_cr, eq_cr;
      list<DAE.Element> rest_eqs;

    case (DAE.VAR(componentRef = var_cr),
          DAE.EQUATION(exp = DAE.CREF(componentRef = eq_cr)) :: rest_eqs)
      equation
        true = ComponentReference.crefEqual(var_cr, eq_cr);
        // The first equation assigns the variable. Remove the variable's
        // binding and discard the equation.
      then
        (DAEUtil.setElementVarBinding(inVar, NONE()), rest_eqs);

    else (inVar, inEqs);
  end match;
end stripRecordDefaultBindingsFromElement;

protected function checkDimensionGreaterThanZero
  input DAE.Dimension inDim;
  input Prefix.Prefix inPrefix;
  input String inIdent;
  input SourceInfo info;
algorithm
  _ := match inDim
    local
      String dim_str, cr_str;
      DAE.ComponentRef cr;

    case DAE.DIM_INTEGER()
      algorithm
        if inDim.integer < 0 then
          dim_str := ExpressionDump.dimensionString(inDim);
          cr := DAE.CREF_IDENT(inIdent, DAE.T_REAL_DEFAULT, {});
          cr_str := ComponentReference.printComponentRefStr(
            PrefixUtil.prefixCrefNoContext(inPrefix, cr));
          Error.addSourceMessageAndFail(Error.NEGATIVE_DIMENSION_INDEX,
           {dim_str, cr_str}, info);
        end if;
      then
        ();

    else ();
  end match;
end checkDimensionGreaterThanZero;

protected function checkArrayModDimSize
  "This function checks that the dimension of a modifier is the same as the
   modified components dimension. Only the first dimension is checked, since
   this function is meant to be called in instArray which is called recursively
   for a component's dimensions."
  input DAE.Mod mod;
  input DAE.Dimension inDimension;
  input Prefix.Prefix inPrefix;
  input String inIdent;
  input SourceInfo inInfo;
algorithm
  _ := match mod
    // Only check modifiers which are not marked with 'each'.
    case DAE.MOD(eachPrefix = SCode.NOT_EACH())
      algorithm
        List.map4_0(mod.subModLst, checkArraySubModDimSize, inDimension, inPrefix, inIdent, inInfo);
      then ();
    else ();
  end match;
end checkArrayModDimSize;

protected function checkArraySubModDimSize
  input DAE.SubMod inSubMod;
  input DAE.Dimension inDimension;
  input Prefix.Prefix inPrefix;
  input String inIdent;
  input SourceInfo inInfo;
algorithm
  _ := match inSubMod
    local
      String name;
      Option<DAE.EqMod> eqmod;

    // Don't check quantity, because Dymola doesn't and as a result the MSL
    // contains some type errors.
    case DAE.NAMEMOD(ident = "quantity") then ();

    case DAE.NAMEMOD(ident = name, mod = DAE.MOD(eachPrefix = SCode.NOT_EACH(),
        eqModOption = eqmod))
      equation
        name = inIdent + "." + name;
        true = checkArrayModBindingDimSize(eqmod, inDimension, inPrefix, name, inInfo);
      then
        ();

    else ();
  end match;
end checkArraySubModDimSize;

protected function checkArrayModBindingDimSize
  input Option<DAE.EqMod> inBinding;
  input DAE.Dimension inDimension;
  input Prefix.Prefix inPrefix;
  input String inIdent;
  input SourceInfo inInfo;
  output Boolean outIsCorrect;
algorithm
  outIsCorrect := matchcontinue inBinding
    local
      DAE.Exp exp;
      DAE.Type ty;
      DAE.Dimension ty_dim;
      Integer dim_size1, dim_size2;
      String exp_str, exp_ty_str, dims_str;
      DAE.Dimensions ty_dims;

    case SOME(DAE.TYPED(modifierAsExp = exp, properties = DAE.PROP(type_ = ty)))
      equation
        ty_dim = Types.getDimensionNth(ty, 1);
        dim_size1 = Expression.dimensionSize(inDimension);
        dim_size2 = Expression.dimensionSize(ty_dim);
        true = dim_size1 <> dim_size2;
        // If the dimensions are not equal, print an error message.
        exp_str = ExpressionDump.printExpStr(exp);
        exp_ty_str = Types.unparseType(ty);
        // We don't know the complete expected type, so lets assume that the
        // rest of the expression's type is correct (will be caught later anyway).
        _ :: ty_dims = Types.getDimensions(ty);
        dims_str = ExpressionDump.dimensionsString(inDimension :: ty_dims);
        Error.addSourceMessage(Error.ARRAY_DIMENSION_MISMATCH,
          {exp_str, exp_ty_str, dims_str}, inInfo);
      then
        false;

    else true;
  end matchcontinue;
end checkArrayModBindingDimSize;

protected function instArray
"When an array is instantiated by instVar, this function is used
  to go through all the array elements and instantiate each array
  element separately."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input ClassInf.State inState;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input String inIdent;
  input tuple<SCode.Element, SCode.Attributes> inElement;
  input SCode.Prefixes inPrefixes;
  input Integer inInteger;
  input DAE.Dimension inDimension;
  input DAE.Dimensions inDimensionLst;
  input list<DAE.Subscript> inIntegerLst;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean inBoolean;
  input SCode.Comment inComment;
  input SourceInfo info;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output DAE.Type outType;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  checkDimensionGreaterThanZero(inDimension, inPrefix, inIdent, info);
  checkArrayModDimSize(inMod, inDimension, inPrefix, inIdent, info);

  (outCache,outEnv,outIH,outStore,outDae,outSets,outType,outGraph) :=
  matchcontinue (inCache,inEnv,inIH,inStore,inState,inMod,inPrefix,inIdent,inElement,inPrefixes,inInteger,inDimension,inDimensionLst,inIntegerLst,inInstDims,inBoolean,inComment,info,inGraph,inSets)
    local
      DAE.Exp e,lhs,rhs;
      DAE.Properties p;
      FCore.Cache cache;
      FCore.Graph env_1,env_2,env,compenv;
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
      Absyn.Path enum_lit;
      SCode.Prefixes pf;
      UnitAbsyn.InstStore store;

    // component environment If is a function var.
    case (cache,env,ih,store,(ClassInf.FUNCTION()),mod,pre,n,(cl,_),_,_,dim,_,_,inst_dims,_,_,_,graph, csets)
      equation
        true = Expression.dimensionUnknownOrExp(dim);
        SOME(DAE.TYPED(e,_,p,_,_)) = Mod.modEquation(mod);
        (cache,env_1,ih,store,_,_,ty,_,_,graph) =
          Inst.instClass(cache,env,ih,store, mod, pre, cl, inst_dims, true, InstTypes.INNER_CALL(), graph, csets) "Which has an expression binding";
        ty_1 = Types.simplifyType(ty);
        (cache,cr) = PrefixUtil.prefixCref(cache,env,ih,pre,ComponentReference.makeCrefIdent(n,ty_1,{})) "check their types";
        (rhs,_) = Types.matchProp(e,p,DAE.PROP(ty,DAE.C_VAR()),true);

        // set the source of this element
        source = DAEUtil.createElementSource(info, FGraph.getScopePath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());

        lhs = Expression.makeCrefExp(cr,ty_1);

        dae = InstSection.makeDaeEquation(lhs, rhs, source, SCode.NON_INITIAL());
        // dae = DAEUtil.joinDaes(dae,DAEUtil.extractFunctions(dae1));
      then
        (cache,env_1,ih,store,dae,inSets,ty,graph);

    case (cache,env,ih,store,ci_state,mod,pre,n,(cl,attr),pf,i,_,dims,idxs,inst_dims,impl,comment,_,graph,csets)
      equation
        false = Expression.dimensionKnown(inDimension);
        e = DAE.ICONST(i);
        s = DAE.INDEX(e);
        mod = Mod.lookupIdxModification(mod, e);
        (cache,compenv,ih,store,daeLst,csets,ty,graph) =
          instVar2(cache, env, ih, store, ci_state, mod, pre, n, cl, attr, pf, dims, (s :: idxs), inst_dims, impl, comment,info,graph, csets);
      then
        (cache,compenv,ih,store,daeLst,csets,ty,graph);

    // Special case when instantiating Real[0]. We need to know the type
    case (cache,env,ih,store,ci_state,_,pre,n,(cl,attr),pf,_,DAE.DIM_INTEGER(0),dims,idxs,inst_dims,impl,comment,_,graph, csets)
      equation
        ErrorExt.setCheckpoint("instArray Real[0]");
        s = DAE.INDEX(DAE.ICONST(0));
        (cache,compenv,ih,store,_,csets,ty,graph) =
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

    // Handle DIM_INTEGER, where the dimension is >0
    case (cache,env,ih,store,ci_state,_,_,_,(_,_),_,_,DAE.DIM_INTEGER(integer = stop),_,_,_,_,_,_,graph,csets)
      equation
        (cache,env,ih,store,dae,csets,ty,graph) = instArrayDimInteger(cache,env,ih,store,ci_state,inMod,inPrefix,inIdent,inElement,inPrefixes,stop,inDimensionLst,inIntegerLst,inInstDims,inBoolean,inComment,info,graph,csets,DAE.emptyDae);
      then
        (cache,env,ih,store,dae,csets,ty,graph);

    // Instantiate an array whose dimension is determined by an enumeration.
    case (cache, env, ih, store, ci_state, mod, pre, n, (cl, attr), pf, _,
        DAE.DIM_ENUM(), dims, idxs, inst_dims, impl, comment, _, graph, csets)
      then instArrayDimEnum(cache, env, ih, store, ci_state, mod, pre, n, cl,
          attr, pf, inDimension, dims, idxs, inst_dims, impl, comment, info,
          graph, csets);

    case (cache, env, ih, store, ci_state, mod, pre, n, (cl, attr), pf, i, DAE.DIM_BOOLEAN(), dims, idxs, inst_dims, impl, comment, _, graph, csets)
      equation
        mod_1 = Mod.lookupIdxModification(mod, DAE.BCONST(false));
        mod_2 = Mod.lookupIdxModification(mod, DAE.BCONST(true));
        (cache, env_1, ih, store, dae1, csets, ty, graph) =
          instVar2(cache, env, ih, store, ci_state, mod_1, pre, n, cl, attr, pf, dims, (DAE.INDEX(DAE.BCONST(false)) :: idxs), inst_dims, impl, comment, info, graph, csets);
        (cache, _, ih, store, dae2, csets, ty, graph) =
          instVar2(cache, env, ih, store, ci_state, mod_2, pre, n, cl, attr, pf, dims, (DAE.INDEX(DAE.BCONST(true))  :: idxs), inst_dims, impl, comment, info, graph, csets);
        daeLst = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache, env_1, ih, store, daeLst, csets, ty, graph);

    case (_,_,_,_,ci_state,mod,pre,n,(_,_),_,i,_,_,idxs,_,_,_,_,_,_)
      equation
        failure(_ = Mod.lookupIdxModification(mod, DAE.ICONST(i)));
        str1 = PrefixUtil.printPrefixStrIgnoreNoPre(PrefixUtil.prefixAdd(n, {}, {}, pre, SCode.VAR(), ci_state));
        str2 = "[" + stringDelimitList(List.map(idxs, ExpressionDump.printSubscriptStr), ", ") + "]";
        str3 = Mod.prettyPrintMod(mod, 1);
        str4 = PrefixUtil.printPrefixStrIgnoreNoPre(pre) + "(" + n + str2 + "=" + str3 + ")";
        str2 = str1 + str2;
        Error.addSourceMessage(Error.MODIFICATION_INDEX_NOT_FOUND, {str1,str4,str2,str3}, info);
      then
        fail();

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Inst.instArray failed: " + inIdent);
      then
        fail();
  end matchcontinue;
end instArray;

protected function instArrayDimInteger
"When an array is instantiated by instVar, this function is used to go through all the array elements and instantiate each array element separately.
Special case for DIM_INTEGER: tail-recursive implementation since the number of dimensions may grow arbitrarily large."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input ClassInf.State inState;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input String inIdent;
  input tuple<SCode.Element, SCode.Attributes> inElement;
  input SCode.Prefixes inPrefixes;
  input Integer thisDim;
  input DAE.Dimensions inDimensionLst;
  input list<DAE.Subscript> inIntegerLst;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean inBoolean;
  input SCode.Comment inComment;
  input SourceInfo info;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  input DAE.DAElist accDae;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output UnitAbsyn.InstStore outStore;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output DAE.Type outType;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outStore,outDae,outSets,outType,outGraph) :=
  match (inCache,inEnv,inIH,inStore,inState,inMod,inPrefix,inIdent,inElement,inPrefixes,thisDim,inDimensionLst,inIntegerLst,inInstDims,inBoolean,inComment,info,inGraph,inSets,accDae)
    local
      DAE.Exp e,lhs,rhs;
      DAE.Properties p;
      FCore.Cache cache;
      FCore.Graph env_1,env_2,env,compenv;
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

    // Stop=true
    case (cache,env,ih,store,_,_,_,_,(_,_),_,0,_,_,_,_,_,_,graph,csets,dae) then (cache,env,ih,store,dae,csets,DAE.T_UNKNOWN_DEFAULT,graph);

    // Stop=false

    // adrpo: if a class is derived WITH AN ARRAY DIMENSION we should instVar2 the derived from type not the actual type!!!
    case (cache,env,ih,store,ci_state,mod,pre,n,
          (cl as SCode.CLASS(classDef=SCode.DERIVED(typeSpec=Absyn.TPATH(path,SOME(_)),
                                                    modifications=scodeMod)),
                                                    attr),
          pf,i,dims,idxs,_,impl,comment,_,graph, _, _)
      equation
        true = i > 0;
        (_,clBase,_) = Lookup.lookupClass(cache, env, path, true);
        /* adrpo: TODO: merge also the attributes, i.e.:
           type A = input discrete flow Integer[3];
           A x; <-- input discrete flow IS NOT propagated even if it should. FIXME!
         */
        //SOME(attr3) = SCode.mergeAttributes(attr,SOME(absynAttr));

        scodeMod = InstUtil.chainRedeclares(mod, scodeMod);

        (_,mod2) = Mod.elabMod(cache, env, ih, pre, scodeMod, impl, Mod.DERIVED(path), info);
        mod3 = Mod.merge(mod, mod2, env, pre);
        e = DAE.ICONST(i);
        mod_1 = Mod.lookupIdxModification(mod3, e);
        s = DAE.INDEX(e);
        (cache,env_1,ih,store,dae1,csets,ty,graph) = instVar2(cache,env,ih, store,ci_state, mod_1, pre, n, clBase, attr, pf, dims, (s :: idxs), {} /* inst_dims */, impl, comment, info, graph, inSets);
        (cache,_,ih,store,daeLst,csets,_,graph) = instArrayDimInteger(cache, env, ih, store, ci_state, mod, pre, n, (cl,attr), pf, i - 1, dims, idxs, {} /* inst_dims */, impl, comment,info,graph, csets, DAEUtil.joinDaes(dae1, accDae));
      then
        (cache,env_1,ih,store,daeLst,csets,ty,graph);

    case (cache,env,ih,store,ci_state,mod,pre,n,(cl,attr),pf,i,dims,idxs,inst_dims,impl,comment,_,graph,csets,_)
      equation
        true = i > 0;
        e = DAE.ICONST(i);
        mod_1 = Mod.lookupIdxModification(mod, e);
        s = DAE.INDEX(e);
        (cache,env_1,ih,store,dae1,csets,ty,graph) = instVar2(cache,env,ih, store,ci_state, mod_1, pre, n, cl, attr, pf,dims, (s :: idxs), inst_dims, impl, comment,info,graph, csets);
        (cache,_,ih,store,daeLst,csets,_,graph) = instArrayDimInteger(cache,env,ih,store, ci_state, mod, pre, n, (cl,attr), pf, i - 1, dims, idxs, inst_dims, impl, comment,info,graph, csets, DAEUtil.joinDaes(dae1, accDae));
      then
        (cache,env_1,ih,store,daeLst,csets,ty,graph);

  end match;
end instArrayDimInteger;

protected function instArrayDimEnum
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input UnitAbsyn.InstStore inStore;
  input ClassInf.State inState;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input String inName;
  input SCode.Element inClass;
  input SCode.Attributes inAttributes;
  input SCode.Prefixes inPrefixes;
  input DAE.Dimension inDimension;
  input DAE.Dimensions inRestDimensions;
  input list<DAE.Subscript> inSubscripts;
  input list<list<DAE.Dimension>> inInstDims;
  input Boolean inImpl;
  input SCode.Comment inComment;
  input SourceInfo inInfo;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Connect.Sets inSets;
  output FCore.Cache outCache = inCache;
  output FCore.Graph outEnv = inEnv;
  output InnerOuter.InstHierarchy outIH = inIH;
  output UnitAbsyn.InstStore outStore = inStore;
  output DAE.DAElist outDae = DAE.emptyDae;
  output Connect.Sets outSets = inSets;
  output DAE.Type outType = DAE.T_UNKNOWN_DEFAULT;
  output ConnectionGraph.ConnectionGraph outGraph = inGraph;
protected
  Absyn.Path enum_path, enum_lit_path;
  list<String> literals;
  Integer i = 1;
  DAE.Exp e;
  DAE.Mod mod;
  DAE.DAElist dae;
algorithm
  DAE.DIM_ENUM(enumTypeName = enum_path, literals = literals) := inDimension;

  for lit in literals loop
    enum_lit_path := Absyn.joinPaths(enum_path, Absyn.IDENT(lit));
    e := DAE.ENUM_LITERAL(enum_lit_path, i);
    mod := Mod.lookupIdxModification(inMod, e);
    i := i + 1;

    (outCache, outEnv, outIH, outStore, dae, outSets, outType, outGraph) :=
      instVar2(outCache, inEnv, outIH, outStore, inState, mod, inPrefix,
        inName, inClass, inAttributes, inPrefixes, inRestDimensions,
        DAE.INDEX(e) :: inSubscripts, inInstDims, inImpl, inComment, inInfo,
        outGraph, outSets);

    outDae := DAEUtil.joinDaes(outDae, dae);
  end for;
end instArrayDimEnum;

annotation(__OpenModelica_Interface="frontend");
end InstVar;
