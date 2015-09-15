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

encapsulated package InstExtends
" file:        InstExtends.mo
  package:     InstExtends
  description: Model instantiation

  RCS: $Id$

  This module is responsible for instantiation of the extends and
  class extends constructs in Modelica models.

"

// public imports
public import Absyn;
public import ClassInf;
public import DAE;
public import FCore;
public import HashTableStringToPath;
public import InnerOuter;
public import SCode;
public import Prefix;

// protected imports
protected import BaseHashTable;
protected import ComponentReference;
protected import Debug;
protected import Dump;
protected import Error;
protected import Flags;
protected import FGraph;
protected import FNode;
protected import Inst;
protected import InstUtil;
protected import List;
protected import Lookup;
protected import Mod;
protected import Util;
protected import SCodeDump;
protected import ErrorExt;
protected import SCodeUtil;
protected import Global;
//protected import System;

protected type InstanceHierarchy = InnerOuter.InstHierarchy "an instance hierarchy";

protected function instExtendsList "
  author: PA
  This function flattens out the inheritance structure of a class.
  It takes an SCode.Element list and flattens out the extends nodes
  of that list. The result is a list of components and lists of equations
  and algorithms."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input list<SCode.Element> inLocalElements;
  input list<SCode.Element> inElementsFromExtendsScope;
  input ClassInf.State inState;
  input String inClassName; // the class name whose elements are getting instantiated.
  input Boolean inImplicit;
  input Boolean isPartialInst;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output DAE.Mod outMod;
  output list<tuple<SCode.Element, DAE.Mod, Boolean>> outElements;
  output list<SCode.Equation> outNormalEqs;
  output list<SCode.Equation> outInitialEqs;
  output list<SCode.AlgorithmSection> outNormalAlgs;
  output list<SCode.AlgorithmSection> outInitialAlgs;
algorithm
  (outCache,outEnv,outIH,outMod,outElements,outNormalEqs,outInitialEqs,outNormalAlgs,outInitialAlgs):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inLocalElements,inElementsFromExtendsScope,inState,inClassName,inImplicit,isPartialInst)
    local
      SCode.Element c;
      String cn,s,scope_str,className,extName;
      SCode.Encapsulated encf;
      Boolean impl,notConst,eq_name;
      SCode.Restriction r;
      FCore.Graph cenv,cenv1,cenv3,env2,env,env_1;
      DAE.Mod outermod,mods,mods_1,emod_1,mod;
      list<SCode.Element> importelts,els,els_1,rest,cdefelts,classextendselts, elsExtendsScope;
      list<SCode.Equation> eq1,ieq1,eq1_1,ieq1_1,eq2,ieq2,eq3,ieq3,eq,ieq,initeq2;
      list<SCode.AlgorithmSection> alg1,ialg1,alg1_1,ialg1_1,alg2,ialg2,alg3,ialg3,alg,ialg;
      Absyn.Path tp_1,tp;
      ClassInf.State new_ci_state,ci_state;
      list<tuple<SCode.Element, DAE.Mod, Boolean>> compelts1,compelts2,compelts,compelts3;
      SCode.Mod emod;
      SCode.Element elt;
      FCore.Cache cache;
      InstanceHierarchy ih;
      HashTableStringToPath.HashTable ht;
      SCode.Variability var;
      Prefix.Prefix pre;
      SCode.Mod scodeMod;
      SCode.Final finalPrefix;
      SourceInfo info;
      SCode.Comment cmt;
      SCode.Visibility vis;
      SCode.Element comp;
      DAE.Var dvar;

    // no further elements to instantiate
    case (cache,env,ih,mod,_,{},_,_,_,_,_) then (cache,env,ih,mod,{},{},{},{},{});

    // instantiate a basic type base class
    case (cache,env,ih,mod,pre,(SCode.EXTENDS( baseClassPath = tp)) :: rest,elsExtendsScope,ci_state,className,impl,_)
      equation
        Absyn.IDENT(cn) = Absyn.makeNotFullyQualified(tp);
        true = InstUtil.isBuiltInClass(cn);
        // adrpo: maybe we should check here if what comes down from the other extends has components!
        (cache,env2,ih,mods_1,compelts2,eq3,ieq3,alg3,ialg3) = instExtendsList(cache,env,ih,mod,pre,rest,elsExtendsScope,ci_state,className,impl,isPartialInst);
      then
        (cache,env2,ih,mods_1,compelts2,eq3,ieq3,alg3,ialg3);

    // instantiate a base class
    case (cache,env,ih,mod,pre,(SCode.EXTENDS(info = info, baseClassPath = tp, modifications = emod, visibility = vis)) :: rest,elsExtendsScope,ci_state,className,impl,_)
      equation
        emod = InstUtil.chainRedeclares(mod, emod);

        // function names might be the same but IT DOES NOT MEAN THEY ARE IN THE SAME SCOPE!
        eq_name = stringEq(className, Absyn.pathFirstIdent(tp)) and // make sure is the same freaking env!
                  Absyn.pathEqual(
                     ClassInf.getStateName(inState),
                     Absyn.joinPaths(FGraph.getGraphName(env), Absyn.makeIdentPathFromString(Absyn.pathFirstIdent(tp))));

        (cache, (c as SCode.CLASS(name = cn, encapsulatedPrefix = encf,
        restriction = r)), cenv) = lookupBaseClass(tp, eq_name, className, env, cache);

        //print("Found " + cn + "\n");
        // outermod = Mod.lookupModificationP(mod, Absyn.IDENT(cn));

        (cache,cenv1,ih,els,eq1,ieq1,alg1,ialg1,mod) = instDerivedClasses(cache,cenv,ih,mod,pre,c,impl,info);
        els = updateElementListVisibility(els, vis);

        // build a ht with the constant elements from the extends scope
        ht = HashTableStringToPath.emptyHashTableSized(BaseHashTable.lowBucketSize);
        ht = getLocalIdentList(InstUtil.constantAndParameterEls(elsExtendsScope),ht,getLocalIdentElement);
        ht = getLocalIdentList(InstUtil.constantAndParameterEls(els),ht,getLocalIdentElement);
        // fully qualify modifiers in extends in the extends environment!
        (cache, emod) = fixModifications(cache, env, emod, ht);

        //(cache,tp_1) = Inst.makeFullyQualified(cache,/* adrpo: cenv1?? FIXME */env, tp);

        eq1_1 = if isPartialInst then {} else eq1;
        ieq1_1 = if isPartialInst then {} else ieq1;
        alg1_1 = if isPartialInst then {} else alg1;
        ialg1_1 = if isPartialInst then {} else ialg1;

        // cenv1 = FGraph.createVersionScope(env, cenv1, cn, FNode.mkExtendsName(tp), pre, mod);
        cenv3 = FGraph.openScope(cenv1, encf, SOME(cn), FGraph.classInfToScopeType(ci_state));
        _ = ClassInf.start(r, FGraph.getGraphName(cenv3));
        /* Add classdefs and imports to env, so e.g. imports from baseclasses found, see Extends5.mo */
        (importelts,cdefelts,classextendselts,els_1) = InstUtil.splitEltsNoComponents(els);
        (cache,cenv3,ih) = InstUtil.addClassdefsToEnv(cache,cenv3,ih,pre,importelts,impl,NONE());
        (cache,cenv3,ih) = InstUtil.addClassdefsToEnv(cache,cenv3,ih,pre,cdefelts,impl,SOME(mod));

        els_1 = SCodeUtil.addRedeclareAsElementsToExtends(els_1, List.select(els_1, SCodeUtil.isRedeclareElement));

        emod_1 = Mod.elabUntypedMod(emod, env, Prefix.NOPRE(), Mod.EXTENDS(tp));
        mods_1 = Mod.merge(mod, emod_1, env, Prefix.NOPRE());

        (cache,_,ih,_,compelts1,eq2,ieq2,alg2,ialg2) = instExtendsAndClassExtendsList2(cache,cenv3,ih,mods_1,pre,els_1,classextendselts,els,ci_state,className,impl,isPartialInst)
        "recurse to fully flatten extends elements env";

        // print("Extended Elements Extends:\n" + InstUtil.printElementAndModList(List.map(compelts1, Util.tuple312)));

        ht = HashTableStringToPath.emptyHashTableSized(BaseHashTable.lowBucketSize);
        ht = getLocalIdentList(compelts1,ht,getLocalIdentElementTpl);
        ht = getLocalIdentList(cdefelts,ht,getLocalIdentElement);
        ht = getLocalIdentList(importelts,ht,getLocalIdentElement);

        //tmp = tick(); Debug.traceln("try fix local idents " + intString(tmp));
        (cache,compelts1) = fixLocalIdents(cache, cenv3, compelts1, ht);
        (cache,eq1_1) = fixList(cache, cenv3, eq1_1, ht,fixEquation);
        (cache,ieq1_1) = fixList(cache, cenv3, ieq1_1, ht,fixEquation);
        (cache,alg1_1) = fixList(cache, cenv3, alg1_1, ht,fixAlgorithm);
        (cache,ialg1_1) = fixList(cache, cenv3, ialg1_1, ht,fixAlgorithm);
        //Debug.traceln("fixed local idents " + intString(tmp));

        (cache,env2,ih,mods_1,compelts2,eq3,ieq3,alg3,ialg3) = instExtendsList(cache,env,ih,mods_1,pre,rest,elsExtendsScope,ci_state,className,impl,isPartialInst)
        "continue with next element in list";

        compelts = listAppend(compelts1, compelts2);

        (compelts3,mods_1) = updateComponentsAndClassdefs(compelts, mods_1, env2) "update components with new merged modifiers";
        eq = List.unionOnTrueList({eq1_1,eq2,eq3},valueEq);
        ieq = List.unionOnTrueList({ieq1_1,ieq2,ieq3},valueEq);
        alg = List.unionOnTrueList({alg1_1,alg2,alg3},valueEq);
        ialg = List.unionOnTrueList({ialg1_1,ialg2,ialg3},valueEq);
      then
        (cache,env2,ih,mods_1,compelts3,eq,ieq,alg,ialg);

    // base class was not found
    case (cache,env,_,_,_,(SCode.EXTENDS(info = info, baseClassPath = tp) :: _),_,_,_,_,_)
      equation
        failure((_,_,_) = Lookup.lookupClass(cache, env, tp, false));
        s = Absyn.pathString(tp);
        scope_str = FGraph.printGraphPathStr(env);
        Error.addSourceMessage(Error.LOOKUP_BASECLASS_ERROR, {s,scope_str}, info);
      then
        fail();

    // extending a component means copying it. It might fail above, try again
    case (cache,env,ih,mod,pre,
         (elt as SCode.COMPONENT(attributes =
          SCode.ATTR(variability = var),
          prefixes = SCode.PREFIXES())) :: rest,elsExtendsScope,
          ci_state,className,impl,_)
      equation
        (cache,env_1,ih,mods,compelts2,eq2,initeq2,alg2,ialg2) =
        instExtendsList(cache, env, ih, mod, pre, rest, elsExtendsScope, ci_state, className, impl, isPartialInst);
        // Filter out non-constants or parameters if partial inst
        notConst = not SCode.isConstant(var); // not (SCode.isConstant(var) or SCode.getEvaluateAnnotation(cmt));
        // we should always add it as the class that variable represents might contain constants!
        compelts2 = if notConst and isPartialInst then compelts2 else ((elt,DAE.NOMOD(),false)::compelts2);
      then
        (cache,env_1,ih,mods,compelts2,eq2,initeq2,alg2,ialg2);

    // Classdefs
    case (cache,env,ih,mod,pre,(elt as SCode.CLASS()) :: rest, elsExtendsScope,
          ci_state,className,impl,_)
      equation
        (cache,env_1,ih,mods,compelts2,eq2,initeq2,alg2,ialg2) =
        instExtendsList(cache, env, ih, mod, pre, rest, elsExtendsScope, ci_state, className, impl, isPartialInst);
      then
        (cache,env_1,ih,mods,((elt,DAE.NOMOD(),false) :: compelts2),eq2,initeq2,alg2,ialg2);

    // instantiate elements that are not extends
    case (cache,env,ih,mod,pre,(elt as SCode.IMPORT()) :: rest, elsExtendsScope, ci_state,className,impl,_)
      equation
        (cache,env_1,ih,mods,compelts2,eq2,initeq2,alg2,ialg2) =
        instExtendsList(cache,env,ih, mod, pre, rest, elsExtendsScope, ci_state, className, impl, isPartialInst);
      then
        (cache,env_1,ih,mods,((elt,DAE.NOMOD(),false) :: compelts2),eq2,initeq2,alg2,ialg2);

    /* instantiation failed */
    case (_,env,_,mod,_,rest, _, _,className,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Inst.instExtendsList failed on:\n\t" +
          "className: " +  className + "\n\t" +
          "env:       " +  FGraph.printGraphPathStr(env) + "\n\t" +
          "mods:      " +  Mod.printModStr(mod) + "\n\t" +
          "elems:     " +  stringDelimitList(List.map1(rest, SCodeDump.unparseElementStr, SCodeDump.defaultOptions), ", ")
          );
      then
        fail();
  end matchcontinue;
end instExtendsList;

protected function lookupBaseClass
  "Looks up a base class used in an extends clause."
  input Absyn.Path inPath;
  input Boolean inSelfReference;
  input String inClassName;
  input FCore.Graph inEnv;
  input FCore.Cache inCache;
  output FCore.Cache outCache;
  output SCode.Element outElement;
  output FCore.Graph outEnv;
algorithm
  (outCache, outElement, outEnv) :=
  match(inPath, inSelfReference, inClassName, inEnv, inCache)
    local
      String name;
      SCode.Element elem;
      FCore.Graph env;
      FCore.Cache cache;
      Absyn.Path path;

    // We have a simple identifier with a self reference, i.e. a class which
    // extends a base class with the same name. The only legal situation in this
    // case is when extending a local class with the same name, e.g.:
    //
    //   class A
    //     extends A;
    //     class A end A;
    //   end A;
    case (Absyn.IDENT(name), true, _, _, _)
      equation
        // Only look the name up locally, otherwise we might get an infinite
        // loop if the class extends itself.
        (elem, env) = Lookup.lookupClassLocal(inEnv, name);
      then
        (inCache, elem, env);

    // Otherwise, remove the first identifier if it's the same as the class name
    // and look it up as normal.
    else
      equation
        path = Absyn.removePartialPrefix(Absyn.IDENT(inClassName), inPath);
        (cache, elem, env) = Lookup.lookupClass(inCache, inEnv, path, false);
      then
        (cache, elem, env);

  end match;
end lookupBaseClass;



protected function updateElementListVisibility
  input list<SCode.Element> inElements;
  input SCode.Visibility inVisibility;
  output list<SCode.Element> outElements;
algorithm
  outElements := match(inElements, inVisibility)
    case (_, SCode.PUBLIC()) then inElements;
    else List.map(inElements, SCode.makeElementProtected);
  end match;
end updateElementListVisibility;

public function instExtendsAndClassExtendsList "
  This function flattens out the inheritance structure of a class.
  It takes an SCode.Element list and flattens out the extends nodes and
  class extends nodes of that list. The result is a list of components and
  lists of equations and algorithms."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input list<SCode.Element> inExtendsElementLst;
  input list<SCode.Element> inClassExtendsElementLst;
  input list<SCode.Element> inElementsFromExtendsScope;
  input ClassInf.State inState;
  input String inClassName; // the class name whose elements are getting instantiated.
  input Boolean inImpl;
  input Boolean isPartialInst;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output DAE.Mod outMod;
  output list<tuple<SCode.Element, DAE.Mod>> outElements;
  output list<SCode.Equation> outNormalEqs;
  output list<SCode.Equation> outInitialEqs;
  output list<SCode.AlgorithmSection> outNormalAlgs;
  output list<SCode.AlgorithmSection> outInitialAlgs;
protected
  list<tuple<SCode.Element, DAE.Mod, Boolean>> elts;
  list<SCode.Element> cdefelts, tmpelts, extendselts;
algorithm
  extendselts := List.map(inExtendsElementLst, SCodeUtil.expandEnumerationClass);
  //fprintln(Flags.DEBUG,"instExtendsAndClassExtendsList: " + inClassName);
  (outCache,outEnv,outIH,outMod,elts,outNormalEqs,outInitialEqs,outNormalAlgs,outInitialAlgs):=
  instExtendsAndClassExtendsList2(inCache,inEnv,inIH,inMod,inPrefix,extendselts,inClassExtendsElementLst,inElementsFromExtendsScope,inState,inClassName,inImpl,isPartialInst);
  // Filter out the last boolean in the tuple
  outElements := List.map(elts, Util.tuple312);
  // Create a list of the class definitions, since these can't be properly added in the recursive call
  tmpelts := List.map(outElements,Util.tuple21);
  (_,cdefelts,_,_) := InstUtil.splitEltsNoComponents(tmpelts);
  // Add the class definitions to the environment
  (outCache,outEnv,outIH) := InstUtil.addClassdefsToEnv(outCache,outEnv,outIH,inPrefix,cdefelts,inImpl,SOME(outMod));
  //fprintln(Flags.DEBUG,"instExtendsAndClassExtendsList: " + inClassName + " done");
end instExtendsAndClassExtendsList;

protected function instExtendsAndClassExtendsList2 "
  This function flattens out the inheritance structure of a class.
  It takes an SCode.Element list and flattens out the extends nodes and
  class extends nodes of that list. The result is a list of components and
  lists of equations and algorithms."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input list<SCode.Element> inExtendsElementLst;
  input list<SCode.Element> inClassExtendsElementLst;
  input list<SCode.Element> inElementsFromExtendsScope;
  input ClassInf.State inState;
  input String inClassName; // the class name whose elements are getting instantiated.
  input Boolean inImpl;
  input Boolean isPartialInst;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output InnerOuter.InstHierarchy outIH;
  output DAE.Mod outMod;
  output list<tuple<SCode.Element, DAE.Mod, Boolean>> outElements;
  output list<SCode.Equation> outNormalEqs;
  output list<SCode.Equation> outInitialEqs;
  output list<SCode.AlgorithmSection> outNormalAlgs;
  output list<SCode.AlgorithmSection> outInitialAlgs;
algorithm
  (outCache,outEnv,outIH,outMod,outElements,outNormalEqs,outInitialEqs,outNormalAlgs,outInitialAlgs):=
  instExtendsList(inCache,inEnv,inIH,inMod,inPrefix,inExtendsElementLst,inElementsFromExtendsScope,inState,inClassName,inImpl,isPartialInst);
  (outMod,outElements):=instClassExtendsList(inEnv,outMod,inClassExtendsElementLst,outElements);
end instExtendsAndClassExtendsList2;

protected function instClassExtendsList
"Instantiate element nodes of type SCode.CLASS_EXTENDS. This is done by walking
the extended classes and performing the modifications in-place. The old class
will no longer be accessible."
  input FCore.Graph inEnv;
  input DAE.Mod inMod;
  input list<SCode.Element> inClassExtendsList;
  input list<tuple<SCode.Element, DAE.Mod, Boolean>> inElements;
  output DAE.Mod outMod;
  output list<tuple<SCode.Element, DAE.Mod, Boolean>> outElements;
algorithm
  (outMod,outElements) := matchcontinue (inEnv,inMod,inClassExtendsList,inElements)
    local
      SCode.Element first;
      list<SCode.Element> rest;
      String name;
      list<SCode.Element> els;
      list<tuple<SCode.Element, DAE.Mod, Boolean>> compelts;
      DAE.Mod emod;
      list<String> names;

    case (_,emod,{},compelts) then (emod,compelts);

    case (_,emod,(first as SCode.CLASS(name=name))::rest,compelts)
      equation
        (emod,compelts) = instClassExtendsList2(inEnv,emod,name,first,compelts);
        (emod,compelts) = instClassExtendsList(inEnv,emod,rest,compelts);
      then (emod,compelts);

    case (_,_,SCode.CLASS(name=name)::_,compelts)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Inst.instClassExtendsList failed " + name);
        Debug.traceln("  Candidate classes: ");
        els = List.map(compelts, Util.tuple31);
        names = List.map(els, SCode.elementName);
        Debug.traceln(stringDelimitList(names, ","));
      then fail();

  end matchcontinue;
end instClassExtendsList;

protected function buildClassExtendsName
  input String inEnvPath;
  input String inClassName;
  output String outClassName;
algorithm
  outClassName := match(inEnvPath, inClassName)
    local String ep, cn;
    /*
    case (ep, cn)
      equation
        // we already added this environment
        0 = System.stringFind(ep, cn);
        0 = System.stringFind(cn, "$parent");
        // keep the same class name!
      then
        cn;*/

    case (ep, cn)
      equation
        cn = "$parent" + "." + cn + ".$env." + ep;
      then
        cn;
  end match;
end buildClassExtendsName;

protected function instClassExtendsList2
  input FCore.Graph inEnv;
  input DAE.Mod inMod;
  input String inName;
  input SCode.Element inClassExtendsElt;
  input list<tuple<SCode.Element, DAE.Mod, Boolean>> inElements;
  output DAE.Mod outMod;
  output list<tuple<SCode.Element, DAE.Mod, Boolean>> outElements;
algorithm
  (outMod,outElements) := matchcontinue (inEnv,inMod,inName,inClassExtendsElt,inElements)
    local
      SCode.Element elt,compelt,classExtendsElt;
      SCode.Element cl;
      SCode.ClassDef classDef,classExtendsCdef;
      SCode.Partial partialPrefix1,partialPrefix2;
      SCode.Encapsulated encapsulatedPrefix1,encapsulatedPrefix2;
      SCode.Restriction restriction1,restriction2;
      SCode.Prefixes prefixes1,prefixes2;
      SCode.Visibility vis2;
      String name1,name2,env_path;
      Option<SCode.ExternalDecl> externalDecl1,externalDecl2;
      list<SCode.Annotation> annotationLst1,annotationLst2;
      SCode.Comment comment1,comment2;
      Option<SCode.Annotation> ann1,ann2;
      list<SCode.Element> els1,els2;
      list<SCode.Equation> nEqn1,nEqn2,inEqn1,inEqn2;
      list<SCode.AlgorithmSection> nAlg1,nAlg2,inAlg1,inAlg2;
      list<SCode.ConstraintSection> inCons1, inCons2;
      list<Absyn.NamedArg> clats;
      list<tuple<SCode.Element, DAE.Mod, Boolean>> rest;
      tuple<SCode.Element, DAE.Mod, Boolean> first;
      SCode.Mod mods, derivedMod;
      DAE.Mod mod1,emod;
      SourceInfo info1, info2;
      Boolean b;
      SCode.Attributes attrs;
      Absyn.TypeSpec derivedTySpec;

    // found the base class with parts
    case (_,emod,name1,classExtendsElt,(cl as SCode.CLASS(name = name2, classDef = SCode.PARTS()),mod1,b)::rest)
      equation
        true = name1 == name2; // Compare the name before pattern-matching to speed this up

        env_path = Absyn.pathString(FGraph.getGraphName(inEnv));
        name2 = buildClassExtendsName(env_path,name2);
        SCode.CLASS(_,prefixes2,encapsulatedPrefix2,partialPrefix2,restriction2,SCode.PARTS(els2,nEqn2,inEqn2,nAlg2,inAlg2,inCons2,clats,externalDecl2),comment2,info2) = cl;

        SCode.CLASS(_, prefixes1, encapsulatedPrefix1, partialPrefix1, restriction1, classExtendsCdef, comment1, info1) = classExtendsElt;
        SCode.CLASS_EXTENDS(_,mods,SCode.PARTS(els1,nEqn1,inEqn1,nAlg1,inAlg1,inCons1,_,externalDecl1)) = classExtendsCdef;

        classDef = SCode.PARTS(els2,nEqn2,inEqn2,nAlg2,inAlg2,inCons2,clats,externalDecl2);
        compelt = SCode.CLASS(name2,prefixes2,encapsulatedPrefix2,partialPrefix2,restriction2,classDef,comment2,info2);
        vis2 = SCode.prefixesVisibility(prefixes2);
        elt = SCode.EXTENDS(Absyn.IDENT(name2),vis2,mods,NONE(),info1);
        classDef = SCode.PARTS(elt::els1,nEqn1,inEqn1,nAlg1,inAlg1,inCons1,clats,externalDecl1);
        elt = SCode.CLASS(name1, prefixes1, encapsulatedPrefix1, partialPrefix1, restriction1, classDef, comment1, info1);
        emod = Mod.renameTopLevelNamedSubMod(emod,name1,name2);
        //Debug.traceln("class extends: " + SCodeDump.unparseElementStr(compelt) + "  " + SCodeDump.unparseElementStr(elt));
      then
        (emod,(compelt,mod1,b)::(elt,DAE.NOMOD(),true)::rest);

    // found the base class which is derived
    case (_,emod,name1,classExtendsElt,(cl as SCode.CLASS(name = name2, classDef = SCode.DERIVED()),mod1,b)::rest)
      equation
        true = name1 == name2; // Compare the name before pattern-matching to speed this up

        env_path = Absyn.pathString(FGraph.getGraphName(inEnv));
        name2 = buildClassExtendsName(env_path,name2);
        SCode.CLASS(_,prefixes2,encapsulatedPrefix2,partialPrefix2,restriction2,SCode.DERIVED(derivedTySpec, derivedMod, attrs),comment2,info2) = cl;

        SCode.CLASS(_, prefixes1, encapsulatedPrefix1, partialPrefix1, restriction1, classExtendsCdef, comment1, info1) = classExtendsElt;
        SCode.CLASS_EXTENDS(_,mods,SCode.PARTS(els1,nEqn1,inEqn1,nAlg1,inAlg1,inCons1,_,externalDecl1)) = classExtendsCdef;

        classDef = SCode.DERIVED(derivedTySpec, derivedMod, attrs);
        compelt = SCode.CLASS(name2,prefixes2,encapsulatedPrefix2,partialPrefix2,restriction2,classDef,comment2,info2);
        vis2 = SCode.prefixesVisibility(prefixes2);
        elt = SCode.EXTENDS(Absyn.IDENT(name2),vis2,mods,NONE(),info1);
        classDef = SCode.PARTS(elt::els1,nEqn1,inEqn1,nAlg1,inAlg1,inCons1,{},externalDecl1);
        elt = SCode.CLASS(name1, prefixes1, encapsulatedPrefix1, partialPrefix1, restriction1, classDef, comment1, info1);
        emod = Mod.renameTopLevelNamedSubMod(emod,name1,name2);
        //Debug.traceln("class extends: " + SCodeDump.unparseElementStr(compelt) + "  " + SCodeDump.unparseElementStr(elt));
      then
        (emod,(compelt,mod1,b)::(elt,DAE.NOMOD(),true)::rest);

    // not this one, switch to next one
    case (_,emod,name1,classExtendsElt,first::rest)
      equation
        (emod,rest) = instClassExtendsList2(inEnv,emod,name1,classExtendsElt,rest);
      then
        (emod,first::rest);

    // bah, we did not find it
    case (_,_,_,_,{})
      equation

        Debug.traceln("TODO: Make a proper Error message here - Inst.instClassExtendsList2 couldn't find the class to extend");
      then
        fail();

  end matchcontinue;
end instClassExtendsList2;

public function instDerivedClasses
"author: PA
  This function takes a class definition and returns the
  elements and equations and algorithms of the class.
  If the class is derived, the class is looked up and the
  derived class parts are fetched."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input SCode.Element inClass;
  input Boolean inBoolean;
  input SourceInfo inInfo "File information of the extends element";
  output FCore.Cache outCache;
  output FCore.Graph outEnv1;
  output InnerOuter.InstHierarchy outIH;
  output list<SCode.Element> outSCodeElementLst2;
  output list<SCode.Equation> outSCodeEquationLst3;
  output list<SCode.Equation> outSCodeEquationLst4;
  output list<SCode.AlgorithmSection> outSCodeAlgorithmLst5;
  output list<SCode.AlgorithmSection> outSCodeAlgorithmLst6;
  output DAE.Mod outMod;
algorithm
  (outCache,outEnv1,outIH,outSCodeElementLst2,outSCodeEquationLst3,outSCodeEquationLst4,outSCodeAlgorithmLst5,outSCodeAlgorithmLst6,outMod) :=
  instDerivedClassesWork(inCache,inEnv,inIH,inMod,inPrefix,inClass,inBoolean,inInfo,false,0);
end instDerivedClasses;

protected function instDerivedClassesWork
"author: PA
  This function takes a class definition and returns the
  elements and equations and algorithms of the class.
  If the class is derived, the class is looked up and the
  derived class parts are fetched."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input SCode.Element inClass;
  input Boolean inBoolean;
  input SourceInfo inInfo "File information of the extends element";
  input Boolean overflow;
  input Integer numIter;
  output FCore.Cache outCache;
  output FCore.Graph outEnv1;
  output InnerOuter.InstHierarchy outIH;
  output list<SCode.Element> outSCodeElementLst2;
  output list<SCode.Equation> outSCodeEquationLst3;
  output list<SCode.Equation> outSCodeEquationLst4;
  output list<SCode.AlgorithmSection> outSCodeAlgorithmLst5;
  output list<SCode.AlgorithmSection> outSCodeAlgorithmLst6;
  output DAE.Mod outMod;
algorithm
  (outCache,outEnv1,outIH,outSCodeElementLst2,outSCodeEquationLst3,outSCodeEquationLst4,outSCodeAlgorithmLst5,outSCodeAlgorithmLst6,outMod):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inClass,inBoolean,inInfo,overflow,numIter)
    local
      list<SCode.Element> elt;
      FCore.Graph env,cenv;
      DAE.Mod mod,daeDMOD;
      list<SCode.Equation> eq,ieq;
      list<SCode.AlgorithmSection> alg,ialg;
      SCode.Element c;
      Absyn.Path tp;
      SCode.Mod dmod;
      Boolean impl;
      FCore.Cache cache;
      InstanceHierarchy ih;
      SCode.Comment cmt;
      list<SCode.Enum> enumLst;
      String n,name,str1,str2,strDepth,cn;
      Option<SCode.ExternalDecl> extdecl;
      Prefix.Prefix pre;
      SourceInfo info;
      SCode.Prefixes prefixes;

    // from basic types return nothing
    case (cache,env,ih,_,_,SCode.CLASS(name = name),_,_,_,_)
      equation
        true = InstUtil.isBuiltInClass(name);
      then
        (cache,env,ih,{},{},{},{},{},inMod);

    case (cache,env,ih,_,_,SCode.CLASS(name = name, classDef =
          SCode.PARTS(elementLst = elt,
                      normalEquationLst = eq,initialEquationLst = ieq,
                      normalAlgorithmLst = alg,initialAlgorithmLst = ialg,
                      externalDecl = extdecl)),_,info,_,_)
      equation
        /* elt_1 = noImportElements(elt); */
        Error.assertionOrAddSourceMessage(Util.isNone(extdecl), Error.EXTENDS_EXTERNAL, {name}, info);
      then
        (cache,env,ih,elt,eq,ieq,alg,ialg,inMod);

    case (cache,env,ih,mod,pre,SCode.CLASS( info = info, classDef = SCode.DERIVED(typeSpec = Absyn.TPATH(tp, _),modifications = dmod)),impl, _, false, _)
      equation
        // fprintln(Flags.INST_TRACE, "DERIVED: " + FGraph.printGraphPathStr(env) + " el: " + SCodeDump.unparseElementStr(inClass) + " mods: " + Mod.printModStr(mod));
        (cache, c, cenv) = Lookup.lookupClass(cache, env, tp, true);
        dmod = InstUtil.chainRedeclares(mod, dmod);
        // false = Absyn.pathEqual(FGraph.getGraphName(env),FGraph.getGraphName(cenv)) and SCode.elementEqual(c,inClass);
        // modifiers should be evaluated in the current scope for derived!
        //daeDMOD = Mod.elabUntypedMod(dmod, env, Prefix.NOPRE(), Mod.DERIVED(tp));
        (cache,daeDMOD) = Mod.elabMod(cache, env, ih, pre, dmod, impl, Mod.DERIVED(tp), info);
        mod = Mod.merge(mod, daeDMOD, env, pre);
        // print("DER: " + SCodeDump.unparseElementStr(inClass, SCodeDump.defaultOptions) + "\n");
        (cache,env,ih,elt,eq,ieq,alg,ialg,mod) = instDerivedClassesWork(cache, cenv, ih, mod, pre, c, impl, info, numIter >= Global.recursionDepthLimit, numIter+1)
        "Mod.lookup_modification_p(mod, c) => innermod & We have to merge and apply modifications as well!" ;
      then
        (cache,env,ih,elt,eq,ieq,alg,ialg,mod);

    case (cache,env,ih,mod,pre,SCode.CLASS(name=n, prefixes = prefixes, classDef = SCode.ENUMERATION(enumLst), cmt = cmt, info = info),impl,_,false,_)
      equation
        c = SCodeUtil.expandEnumeration(n, enumLst, prefixes, cmt, info);
        (cache,env,ih,elt,eq,ieq,alg,ialg,mod) = instDerivedClassesWork(cache, env, ih, mod, pre, c, impl,info, numIter >= Global.recursionDepthLimit, numIter+1);
      then
        (cache,env,ih,elt,eq,ieq,alg,ialg,mod);

    case (_,_,_,_,_,_,_,_,true,_)
      equation
        str1 = SCodeDump.unparseElementStr(inClass,SCodeDump.defaultOptions);
        str2 = FGraph.printGraphPathStr(inEnv);
        // print("instDerivedClassesWork recursion depth... " + str1 + " " + str2 + "\n");
        Error.addSourceMessage(Error.RECURSION_DEPTH_DERIVED,{str1,str2},inInfo);
      then fail();

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Inst.instDerivedClasses failed\n");
      then
        fail();
  end matchcontinue;
end instDerivedClassesWork;

protected function noImportElements
"Returns all elements except imports, i.e. filter out import elements."
  input list<SCode.Element> inSCodeElementLst;
  output list<SCode.Element> outSCodeElementLst;
algorithm
  outSCodeElementLst := matchcontinue (inSCodeElementLst)
    local
      list<SCode.Element> elt,rest;
      SCode.Element e;
    case {} then {};
    case (SCode.IMPORT() :: rest)
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

protected function updateComponentsAndClassdefs
  "This function takes a list of components and a Mod and returns a list of
  components  with the modifiers updated.  The function is used when flattening
  the inheritance structure, resulting in a list of components to insert into
  the class definition. For instance
  model A
    extends B(modifiers)
  end A;
  will result in a list of components
  from B for which modifiers should be applied to."
  input list<tuple<SCode.Element, DAE.Mod, Boolean>> inComponents;
  input DAE.Mod inMod;
  input FCore.Graph inEnv;
  output list<tuple<SCode.Element, DAE.Mod, Boolean>> outComponents;
  output DAE.Mod outRestMod;
algorithm
  (outComponents, outRestMod) := List.map1Fold(inComponents,
    updateComponentsAndClassdefs2, inEnv, inMod);
end updateComponentsAndClassdefs;

protected function updateComponentsAndClassdefs2
  input tuple<SCode.Element, DAE.Mod, Boolean> inComponent;
  input FCore.Graph inEnv;
  input DAE.Mod inMod;
  output tuple<SCode.Element, DAE.Mod, Boolean> outComponent;
  output DAE.Mod outRestMod;
algorithm
  (outComponent, outRestMod) := matchcontinue(inComponent, inEnv, inMod)
    local
      SCode.Element comp, comp1, comp2;
      DAE.Mod cmod, cmod1, cmod2, mod_rest;
      String id;
      Boolean b;
      SCode.Mod m;

    case ((comp as SCode.COMPONENT(name = id), cmod, b), _, _)
      equation
        // Debug.traceln(" comp: " + id + " " + Mod.printModStr(mod));
        // take ONLY the modification from the equation if is typed
        // cmod2 = Mod.getModifs(inMod, id, m);
        cmod2 = Mod.lookupCompModificationFromEqu(inMod, id);
        // Debug.traceln("\tSpecific mods on comp: " +  Mod.printModStr(cmod2));
        cmod = Mod.merge(cmod2, cmod, inEnv, Prefix.NOPRE());
        mod_rest = inMod; //mod_rest = Mod.removeMod(inMod, id);
      then
        ((comp, cmod, b), mod_rest);

    case ((SCode.EXTENDS(), _, _), _, _)
      then (inComponent, inMod);

    case ((comp as SCode.IMPORT(), _, b), _ , _)
      then ((comp, DAE.NOMOD(), b), inMod);

    case ((comp1 as SCode.CLASS(name = id, prefixes = SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(_))), cmod1, b), _, _)
      equation
        DAE.REDECL(_, _, (comp2, cmod2)::_) = Mod.lookupCompModification(inMod, id);
        mod_rest = inMod; //mod_rest = Mod.removeMod(inMod, id);
        cmod2 = Mod.merge(cmod2, cmod1, inEnv, Prefix.NOPRE());
        comp2 = SCode.mergeWithOriginal(comp2, comp1);
        // comp2 = SCode.renameElement(comp2, id);
      then
        ((comp2, cmod2, b), mod_rest);

    // adrpo:
    //  2011-01-19 we can have a modifier in the mods here,
    //  example in Modelica.Media:
    //   partial package SingleGasNasa
    //     extends Interfaces.PartialPureSubstance(
    //       ThermoStates = Choices.IndependentVariables.pT,
    //       mediumName=data.name,
    //       substanceNames={data.name},
    //       singleState=false,
    //       Temperature(min=200, max=6000, start=500, nominal=500),
    //       SpecificEnthalpy(start=if referenceChoice==ReferenceEnthalpy.ZeroAt0K then data.H0 else
    //         if referenceChoice==ReferenceEnthalpy.UserDefined then h_offset else 0, nominal=1.0e5),
    //       Density(start=10, nominal=10),
    //       AbsolutePressure(start=10e5, nominal=10e5)); <--- AbsolutePressure is a type and can have modifications!
    case ((comp as SCode.CLASS(name = id), cmod, b), _, _)
      equation
        cmod1 = Mod.lookupCompModification(inMod, id);
        if not valueEq(cmod1, DAE.NOMOD())
        then
          cmod = cmod1;
        end if;
      then
        ((comp, cmod, b), inMod);

    case ((comp,cmod,b),_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln(
          "- InstExtends.updateComponentsAndClassdefs2 failed on:\n" +
          "env = " + FGraph.printGraphPathStr(inEnv) +
          "\nmod = " + Mod.printModStr(inMod) +
          "\ncmod = " + Mod.printModStr(cmod) +
          "\nbool = " + boolString(b) + "\n" +
          SCodeDump.unparseElementStr(comp)
          );
      then
        fail();
  end matchcontinue;
end updateComponentsAndClassdefs2;

protected function getLocalIdentList
" Analyzes the elements of a class and fetches a list of components and classdefs,
  as well as aliases from imports to paths.
"
  input list<Type_A> ielts;
  input HashTableStringToPath.HashTable inHt;
  input getIdentFn getIdent;
  output HashTableStringToPath.HashTable outHt;

  replaceable type Type_A subtypeof Any;
  partial function getIdentFn
    input Type_A inA;
    input HashTableStringToPath.HashTable inHt;
    output HashTableStringToPath.HashTable outHt;
  end getIdentFn;
algorithm
  (outHt) := match (ielts,inHt,getIdent)
    local
      Type_A elt;
      HashTableStringToPath.HashTable ht;
      list<Type_A> elts;

    case ({},ht,_) then ht;
    case (elt::elts,ht,_)
      equation
        ht = getIdent(elt,ht);
        ht = getLocalIdentList(elts,ht,getIdent);
      then ht;
  end match;
end getLocalIdentList;

protected function getLocalIdentElementTpl
" Analyzes the elements of a class and fetches a list of components and classdefs,
  as well as aliases from imports to paths.
"
  input tuple<SCode.Element,DAE.Mod,Boolean> eltTpl;
  input HashTableStringToPath.HashTable ht;
  output HashTableStringToPath.HashTable outHt;
algorithm
  (outHt) := match (eltTpl,ht)
    local
      SCode.Element elt;
    case ((elt,_,_),_) then getLocalIdentElement(elt,ht);
  end match;
end getLocalIdentElementTpl;

protected function getLocalIdentElement
" Analyzes an element of a class and fetches a list of components and classdefs,
  as well as aliases from imports to paths."
  input SCode.Element elt;
  input HashTableStringToPath.HashTable inHt;
  output HashTableStringToPath.HashTable outHt;
algorithm
  (outHt) := matchcontinue (elt,inHt)
    local
      String id;
      Absyn.Path p;
      HashTableStringToPath.HashTable ht;

    case (SCode.COMPONENT(name = id),ht)
      equation
        ht = BaseHashTable.add((id,Absyn.IDENT(id)), ht);
      then ht;

    case (SCode.CLASS(name = id),ht)
      equation
        ht = BaseHashTable.add((id,Absyn.IDENT(id)), ht);
      then ht;

    case (SCode.IMPORT(imp = Absyn.NAMED_IMPORT(name = id, path = p)),ht)
      equation
        failure(_ = BaseHashTable.get(id, ht));
        ht = BaseHashTable.add((id,p), ht);
      then ht;

    case (SCode.IMPORT(imp = Absyn.QUAL_IMPORT(path = p)),ht)
      equation
        id = Absyn.pathLastIdent(p);
        failure(_ = BaseHashTable.get(id, ht));
        ht = BaseHashTable.add((id,p), ht);
      then ht;

    // adrpo: 2010-10-07 handle unqualified imports!!! TODO! FIXME! should we just ignore them??
    //                   this fixes bug: #1234 https://openmodelica.org:8443/cb/issue/1234
    case (SCode.IMPORT(imp = Absyn.UNQUAL_IMPORT(path = p)),ht)
      equation
        id = Absyn.pathLastIdent(p);
        failure(_ = BaseHashTable.get(id, ht));
        ht = BaseHashTable.add((id,p), ht);
      then ht;

    else inHt;
  end matchcontinue;
end getLocalIdentElement;

protected function fixLocalIdents
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<tuple<SCode.Element,DAE.Mod,Boolean>> inElts;
  input HashTableStringToPath.HashTable inHt;
  output FCore.Cache outCache;
  output list<tuple<SCode.Element,DAE.Mod,Boolean>> outElts;
algorithm
  (outCache,outElts) := matchcontinue (inCache,inEnv,inElts,inHt)
    local
      SCode.Element elt;
      DAE.Mod mod;
      Boolean b;
      FCore.Cache cache;
      FCore.Graph env;
      HashTableStringToPath.HashTable ht;
      list<tuple<SCode.Element,DAE.Mod,Boolean>> elts;

    case (cache,_,{},_) then (cache,{});
    case (cache,env,(elt,mod,false)::elts,ht)
      equation
        (cache,elt) = fixElement(cache,env,elt,ht);
        (cache,elts) = fixLocalIdents(cache,env,elts,ht);
      then (cache,(elt,mod,true)::elts);
    case (cache,env,(elt,mod,true)::elts,ht)
      equation
        (cache,elt) = fixElement(cache,env,elt,ht);
        (cache,elts) = fixLocalIdents(cache,env,elts,ht);
      then (cache,(elt,mod,true)::elts);
    case (_,env,(elt,mod,b)::_,_)
      equation
        Debug.traceln("- InstExtends.fixLocalIdents failed for element:" +
        SCodeDump.unparseElementStr(elt,SCodeDump.defaultOptions) + " mods: " +
        Mod.printModStr(mod) + " class extends:" +
        boolString(b) + " in env: " + FGraph.printGraphPathStr(env)
        );
      then
        fail();

  end matchcontinue;
end fixLocalIdents;

protected function fixElement
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.Element inElt;
  input HashTableStringToPath.HashTable inHt;
  output FCore.Cache outCache;
  output SCode.Element outElts;
algorithm
  (outCache,outElts) := matchcontinue (inCache,inEnv,inElt,inHt)
    local
      String name;
      SCode.Prefixes prefixes;
      SCode.Partial partialPrefix;
      Absyn.TypeSpec typeSpec;
      SCode.Mod modifications;
      SCode.Comment comment;
      Option<Absyn.Exp> condition;
      SourceInfo info;
      SCode.ClassDef classDef;
      SCode.Restriction restriction;
      Option<SCode.Annotation> optAnnotation;
      Absyn.Path extendsPath;
      SCode.Visibility vis;
      Absyn.ArrayDim ad;
      SCode.ConnectorType ct;
      SCode.Variability var;
      SCode.Parallelism prl;
      Absyn.Direction dir;
      FCore.Cache cache;
      FCore.Graph env;
      HashTableStringToPath.HashTable ht;
      SCode.Element elt;

    case (cache,env,SCode.COMPONENT(name, prefixes as SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(_)),
                                    SCode.ATTR(ad, ct, prl, var, dir), typeSpec, modifications, comment, condition, info),ht)
      equation
        //fprintln(Flags.DEBUG,"fix comp " + SCodeDump.unparseElementStr(elt,SCodeDump.defaultOptions));
        // lookup as it might have been redeclared!!!
        (_, _, SCode.COMPONENT(name, prefixes, SCode.ATTR(ad, ct, prl, var, dir), typeSpec, modifications, comment, condition, info),
         _, _, _) = Lookup.lookupIdentLocal(cache, env, name);
        (cache,modifications) = fixModifications(cache,env,modifications,ht);
        (cache,typeSpec) = fixTypeSpec(cache,env,typeSpec,ht);
        (cache,SOME(ad)) = fixArrayDim(cache, env, SOME(ad), ht);
      then
        (cache,SCode.COMPONENT(name, prefixes, SCode.ATTR(ad, ct, prl, var, dir), typeSpec, modifications, comment, condition, info));

    // we failed above
    case (cache,env,SCode.COMPONENT(name, prefixes, SCode.ATTR(ad, ct, prl, var, dir), typeSpec, modifications, comment, condition, info),ht)
      equation
        //fprintln(Flags.DEBUG,"fix comp " + SCodeDump.unparseElementStr(elt,SCodeDump.defaultOptions));
        (cache,modifications) = fixModifications(cache,env,modifications,ht);
        (cache,typeSpec) = fixTypeSpec(cache,env,typeSpec,ht);
        (cache,SOME(ad)) = fixArrayDim(cache, env, SOME(ad), ht);
      then
        (cache,SCode.COMPONENT(name, prefixes, SCode.ATTR(ad, ct, prl, var, dir), typeSpec, modifications, comment, condition, info));

    case (cache,env,SCode.CLASS(name, prefixes as SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(_)),
                                SCode.ENCAPSULATED(), partialPrefix, restriction, classDef, comment, info),ht)
      equation
        //fprintln(Flags.DEBUG,"fixClassdef " + name);
        // lookup as it might have been redeclared!!!
        (SCode.CLASS(prefixes = prefixes, partialPrefix = partialPrefix, restriction = restriction,
                     cmt = comment, info = info,classDef=classDef),_) = Lookup.lookupClassLocal(env, name);
        env = FGraph.openScope(env, SCode.ENCAPSULATED(), SOME(name), FGraph.restrictionToScopeType(restriction));
        (cache,classDef) = fixClassdef(cache,env,classDef,ht);
      then
        (cache,SCode.CLASS(name, prefixes, SCode.ENCAPSULATED(), partialPrefix, restriction, classDef, comment, info));

    // failed above
    case (cache,env,SCode.CLASS(name, prefixes, SCode.ENCAPSULATED(), partialPrefix, restriction, classDef, comment, info),ht)
      equation
        //fprintln(Flags.DEBUG,"fixClassdef " + name);
        env = FGraph.openScope(env, SCode.ENCAPSULATED(), SOME(name), FGraph.restrictionToScopeType(restriction));
        (cache,classDef) = fixClassdef(cache,env,classDef,ht);
      then
        (cache,SCode.CLASS(name, prefixes, SCode.ENCAPSULATED(), partialPrefix, restriction, classDef, comment, info));

    case (cache,env,SCode.CLASS(name, prefixes as SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(_)),
                                SCode.NOT_ENCAPSULATED(), partialPrefix, restriction, classDef, comment, info),ht)
      equation
        //fprintln(Flags.DEBUG,"fixClassdef " + name + str);
        // lookup as it might have been redeclared!!!
        (SCode.CLASS(prefixes = prefixes, partialPrefix = partialPrefix, restriction = restriction,
                     cmt = comment, info = info,classDef=classDef),_) = Lookup.lookupClassLocal(env, name);

        env = FGraph.openScope(env, SCode.NOT_ENCAPSULATED(), SOME(name), FGraph.restrictionToScopeType(restriction));
        (cache,classDef) = fixClassdef(cache,env,classDef,ht);
      then
        (cache,SCode.CLASS(name, prefixes, SCode.NOT_ENCAPSULATED(), partialPrefix, restriction, classDef, comment, info));

    // failed above
    case (cache,env,SCode.CLASS(name, prefixes, SCode.NOT_ENCAPSULATED(), partialPrefix, restriction, classDef, comment, info),ht)
      equation
        //fprintln(Flags.DEBUG,"fixClassdef " + name + str);
        env = FGraph.openScope(env, SCode.NOT_ENCAPSULATED(), SOME(name), FGraph.restrictionToScopeType(restriction));
        (cache,classDef) = fixClassdef(cache,env,classDef,ht);
      then
        (cache,SCode.CLASS(name, prefixes, SCode.NOT_ENCAPSULATED(), partialPrefix, restriction, classDef, comment, info));

    case (cache,env,SCode.EXTENDS(extendsPath,vis,modifications,optAnnotation,info),ht)
      equation
        //fprintln(Flags.DEBUG,"fix extends " + SCodeDump.unparseElementStr(elt,SCodeDump.defaultOptions));
        (cache,extendsPath) = fixPath(cache,env,extendsPath,ht);
        (cache,modifications) = fixModifications(cache,env,modifications,ht);
      then
        (cache,SCode.EXTENDS(extendsPath,vis,modifications,optAnnotation,info));

    case (cache,_,SCode.IMPORT(),_) then (cache,inElt);

    case (_,_,elt,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("InstExtends.fixElement failed: " + SCodeDump.unparseElementStr(elt));
      then fail();

  end matchcontinue;
end fixElement;

protected function fixClassdef
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.ClassDef inCd;
  input HashTableStringToPath.HashTable inHt;
  output FCore.Cache outCache;
  output SCode.ClassDef outCd;
algorithm
  (outCache,outCd) := matchcontinue (inCache,inEnv,inCd,inHt)
    local
      list<SCode.Element> elts;
      list<SCode.Equation> ne,ie;
      list<SCode.AlgorithmSection> na,ia;
      list<SCode.ConstraintSection> nc;
      list<Absyn.NamedArg> clats;
      Option<SCode.ExternalDecl> ed;
      list<SCode.Annotation> ann;
      Option<SCode.Comment> c;
      Absyn.TypeSpec ts;
      SCode.Attributes attr;
      String name;
      SCode.Mod mod;
      FCore.Cache cache;
      FCore.Graph env;
      HashTableStringToPath.HashTable ht, htParent;
      SCode.ClassDef cd;

    case (cache,env,SCode.PARTS(elts,ne,ie,na,ia,nc,clats,ed),htParent)
      equation
        ht = BaseHashTable.copy(htParent);
        ht = getLocalIdentList(elts,ht,getLocalIdentElement);
        (cache,elts) = fixList(cache,env,elts,ht,fixElement);
        (cache,ne) = fixList(cache,env,ne,ht,fixEquation);
        (cache,ie) = fixList(cache,env,ie,ht,fixEquation);
        (cache,na) = fixList(cache,env,na,ht,fixAlgorithm);
        (cache,ia) = fixList(cache,env,ia,ht,fixAlgorithm);
        (cache,nc) = fixList(cache,env,nc,ht,fixConstraint);
      then (cache,SCode.PARTS(elts,ne,ie,na,ia,nc,clats,ed));

    case (cache,env,SCode.CLASS_EXTENDS(name,mod,SCode.PARTS(elts,ne,ie,na,ia,nc,clats,ed)),htParent)
      equation
        ht = BaseHashTable.copy(htParent);
        (cache,mod) = fixModifications(cache,env,mod,ht);
        (cache,elts) = fixList(cache,env,elts,ht,fixElement);
        (cache,ne) = fixList(cache,env,ne,ht,fixEquation);
        (cache,ie) = fixList(cache,env,ie,ht,fixEquation);
        (cache,na) = fixList(cache,env,na,ht,fixAlgorithm);
        (cache,ia) = fixList(cache,env,ia,ht,fixAlgorithm);
        (cache,nc) = fixList(cache,env,nc,ht,fixConstraint);
      then (cache,SCode.CLASS_EXTENDS(name,mod,SCode.PARTS(elts,ne,ie,na,ia,nc,clats,ed)));

    case (cache,env,SCode.DERIVED(ts,mod,attr),ht)
      equation
        (cache,ts) = fixTypeSpec(cache,env,ts,ht);
        (cache,mod) = fixModifications(cache,env,mod,ht);
      then (cache,SCode.DERIVED(ts,mod,attr));

    case (cache,_,cd as SCode.ENUMERATION(),_) then (cache,cd);
    case (cache,_,cd as SCode.OVERLOAD(),_) then (cache,cd);
    case (cache,_,cd as SCode.PDER(),_) then (cache,cd);

    case (_,_,cd,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("InstExtends.fixClassDef failed: " + SCodeDump.classDefStr(cd));
      then
        fail();

  end matchcontinue;
end fixClassdef;

protected function fixEquation
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.Equation inEq;
  input HashTableStringToPath.HashTable inHt;
  output FCore.Cache outCache;
  output SCode.Equation outEq;
algorithm
  (outCache,outEq) := match (inCache,inEnv,inEq,inHt)
    local
      SCode.EEquation eeq;
      FCore.Cache cache;
      FCore.Graph env;
      HashTableStringToPath.HashTable ht;

    case (cache,env,SCode.EQUATION(eeq),ht)
      equation
        (cache,eeq) = fixEEquation(cache,env,eeq,ht);
      then
        (cache,SCode.EQUATION(eeq));
    case (_,_,SCode.EQUATION(eeq),_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Inst.fixEquation failed: " + SCodeDump.equationStr(eeq));
      then
        fail();
  end match;
end fixEquation;

protected function fixEEquation
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.EEquation inEeq;
  input HashTableStringToPath.HashTable inHt;
  output FCore.Cache outCache;
  output SCode.EEquation outEeq;
algorithm
  (outCache,outEeq) := match (inCache,inEnv,inEeq,inHt)
    local
      String id;
      Absyn.ComponentRef cref,cref1,cref2;
      Absyn.Exp exp,exp1,exp2,exp3;
      list<Absyn.Exp> expl;
      list<SCode.EEquation> eql;
      list<list<SCode.EEquation>> eqll;
      list<tuple<Absyn.Exp, list<SCode.EEquation>>> whenlst;
      SCode.Comment comment;
      Option<Absyn.Exp> optExp;
      SourceInfo info;
      FCore.Cache cache;
      FCore.Graph env;
      HashTableStringToPath.HashTable ht;

    case (cache,env,SCode.EQ_IF(expl,eqll,eql,comment,info),ht)
      equation
        (cache,expl) = fixList(cache,env,expl,ht,fixExp);
        (cache,eqll) = fixListList(cache,env,eqll,ht,fixEEquation);
        (cache,eql) = fixList(cache,env,eql,ht,fixEEquation);
      then (cache,SCode.EQ_IF(expl,eqll,eql,comment,info));
    case (cache,env,SCode.EQ_EQUALS(exp1,exp2,comment,info),ht)
      equation
        (cache,exp1) = fixExp(cache,env,exp1,ht);
        (cache,exp2) = fixExp(cache,env,exp2,ht);
      then (cache,SCode.EQ_EQUALS(exp1,exp2,comment,info));
    case (cache,env,SCode.EQ_CONNECT(cref1,cref2,comment,info),ht)
      equation
        (cache,cref1) = fixCref(cache,env,cref1,ht);
        (cache,cref2) = fixCref(cache,env,cref2,ht);
      then (cache,SCode.EQ_CONNECT(cref1,cref2,comment,info));
    case (cache,env,SCode.EQ_FOR(id,optExp,eql,comment,info),ht)
      equation
        (cache,optExp) = fixOption(cache,env,optExp,ht,fixExp);
        (cache,eql) = fixList(cache,env,eql,ht,fixEEquation);
      then (cache,SCode.EQ_FOR(id,optExp,eql,comment,info));
    case (cache,env,SCode.EQ_WHEN(exp,eql,whenlst,comment,info),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
        (cache,eql) = fixList(cache,env,eql,ht,fixEEquation);
        (cache,whenlst) = fixListTuple2(cache,env,whenlst,ht,fixExp,fixListEEquation);
      then (cache,SCode.EQ_WHEN(exp,eql,whenlst,comment,info));
    case (cache,env,SCode.EQ_ASSERT(exp1,exp2,exp3,comment,info),ht)
      equation
        (cache,exp1) = fixExp(cache,env,exp1,ht);
        (cache,exp2) = fixExp(cache,env,exp2,ht);
        (cache,exp3) = fixExp(cache,env,exp3,ht);
      then (cache,SCode.EQ_ASSERT(exp1,exp2,exp3,comment,info));
    case (cache,env,SCode.EQ_TERMINATE(exp,comment,info),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
      then (cache,SCode.EQ_TERMINATE(exp,comment,info));
    case (cache,env,SCode.EQ_REINIT(cref,exp,comment,info),ht)
      equation
        (cache,cref) = fixCref(cache,env,cref,ht);
        (cache,exp) = fixExp(cache,env,exp,ht);
      then (cache,SCode.EQ_REINIT(cref,exp,comment,info));
    case (cache,env,SCode.EQ_NORETCALL(exp,comment,info),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
      then (cache,SCode.EQ_NORETCALL(exp,comment,info));
  end match;
end fixEEquation;

protected function fixListEEquation
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input FCore.Cache cache;
  input FCore.Graph env;
  input list<SCode.EEquation> eeq;
  input HashTableStringToPath.HashTable ht;
  output FCore.Cache outCache;
  output list<SCode.EEquation> outEeq;
algorithm
  (outCache,outEeq) := fixList(cache,env,eeq,ht,fixEEquation);
end fixListEEquation;

protected function fixAlgorithm
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.AlgorithmSection inAlg;
  input HashTableStringToPath.HashTable inHt;
  output FCore.Cache outCache;
  output SCode.AlgorithmSection outAlg;
algorithm
  (outCache,outAlg) := match (inCache,inEnv,inAlg,inHt)
    local
      list<SCode.Statement> stmts;
      FCore.Cache cache;
      FCore.Graph env;
      HashTableStringToPath.HashTable ht;

    case (cache,env,SCode.ALGORITHM(stmts),ht)
      equation
        (cache,stmts) = fixList(cache,env,stmts,ht,fixStatement);
      then (cache,SCode.ALGORITHM(stmts));
  end match;
end fixAlgorithm;

protected function fixConstraint
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.ConstraintSection inConstrs;
  input HashTableStringToPath.HashTable inHt;
  output FCore.Cache outCache;
  output SCode.ConstraintSection outConstrs;
algorithm
  (outCache,outConstrs) := match (inCache,inEnv,inConstrs,inHt)
    local
      list<Absyn.Exp> exps;
      FCore.Cache cache;
      FCore.Graph env;
      HashTableStringToPath.HashTable ht;

    case (cache,env,SCode.CONSTRAINTS(exps),ht)
      equation
        (cache,exps) = fixList(cache,env,exps,ht,fixExp);
      then (cache,SCode.CONSTRAINTS(exps));
  end match;
end fixConstraint;

protected function fixListAlgorithmItem
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input FCore.Cache cache;
  input FCore.Graph env;
  input list<SCode.Statement> alg;
  input HashTableStringToPath.HashTable ht;
  output FCore.Cache outCache;
  output list<SCode.Statement> outAlg;
algorithm
  (outCache,outAlg) := fixList(cache,env,alg,ht,fixStatement);
end fixListAlgorithmItem;

protected function fixStatement
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.Statement inStmt;
  input HashTableStringToPath.HashTable inHt;
  output FCore.Cache outCache;
  output SCode.Statement outStmt;
algorithm
  (outCache,outStmt) := matchcontinue (inCache,inEnv,inStmt,inHt)
    local
      Absyn.Exp exp,exp1,exp2;
      Option<Absyn.Exp> optExp;
      String iter;
      list<tuple<Absyn.Exp, list<SCode.Statement>>> elseifbranch,whenlst;
      list<SCode.Statement> truebranch,elsebranch,forbody,whilebody;
      SCode.Comment comment;
      SourceInfo info;
      FCore.Cache cache;
      FCore.Graph env;
      HashTableStringToPath.HashTable ht;
      SCode.Statement stmt;
      Absyn.ComponentRef cr;

    case (cache,env,SCode.ALG_ASSIGN(exp1,exp2,comment,info),ht)
      equation
        (cache,exp1) = fixExp(cache,env,exp1,ht);
        (cache,exp2) = fixExp(cache,env,exp2,ht);
      then (cache,SCode.ALG_ASSIGN(exp1,exp2,comment,info));

    case (cache,env,SCode.ALG_IF(exp,truebranch,elseifbranch,elsebranch,comment,info),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
        (cache,truebranch) = fixList(cache,env,truebranch,ht,fixStatement);
        (cache,elseifbranch) = fixListTuple2(cache,env,elseifbranch,ht,fixExp,fixListAlgorithmItem);
        (cache,elsebranch) = fixList(cache,env,elsebranch,ht,fixStatement);
      then (cache,SCode.ALG_IF(exp,truebranch,elseifbranch,elsebranch,comment,info));

    case (cache,env,SCode.ALG_FOR(iter,optExp,forbody,comment,info),ht)
      equation
        (cache,optExp) = fixOption(cache,env,optExp,ht,fixExp);
        (cache,forbody) = fixList(cache,env,forbody,ht,fixStatement);
      then (cache,SCode.ALG_FOR(iter,optExp,forbody,comment,info));

    case (cache,env,SCode.ALG_PARFOR(iter,optExp,forbody,comment,info),ht)
      equation
        (cache,optExp) = fixOption(cache,env,optExp,ht,fixExp);
        (cache,forbody) = fixList(cache,env,forbody,ht,fixStatement);
      then (cache,SCode.ALG_PARFOR(iter,optExp,forbody,comment,info));

    case (cache,env,SCode.ALG_WHILE(exp,whilebody,comment,info),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
        (cache,_) = fixList(cache,env,whilebody,ht,fixStatement);
      then (cache,SCode.ALG_WHILE(exp,whilebody,comment,info));

    case (cache,env,SCode.ALG_WHEN_A(whenlst,comment,info),ht)
      equation
        (cache,whenlst) = fixListTuple2(cache,env,whenlst,ht,fixExp,fixListAlgorithmItem);
      then (cache,SCode.ALG_WHEN_A(whenlst,comment,info));

    case (cache, env, SCode.ALG_ASSERT(exp, exp1, exp2, comment, info), ht)
      algorithm
        (cache, exp) := fixExp(cache, env, exp, ht);
        (cache, exp1) := fixExp(cache, env, exp1, ht);
        (cache, exp2) := fixExp(cache, env, exp2, ht);
      then
        (cache, SCode.ALG_ASSERT(exp, exp1, exp2, comment, info));

    case (cache, env, SCode.ALG_TERMINATE(exp, comment, info), ht)
      algorithm
        (cache, exp) := fixExp(cache, env, exp, ht);
      then
        (cache, SCode.ALG_TERMINATE(exp, comment, info));

    case (cache, env, SCode.ALG_REINIT(cr, exp, comment, info), ht)
      algorithm
        (cache, cr) := fixCref(cache, env, cr, ht);
        (cache, exp) := fixExp(cache, env, exp, ht);
      then
        (cache, SCode.ALG_REINIT(cr, exp, comment, info));

    case (cache,env,SCode.ALG_NORETCALL(exp,comment,info),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
      then (cache,SCode.ALG_NORETCALL(exp,comment,info));

    case (cache,_,SCode.ALG_RETURN(comment,info),_) then (cache,SCode.ALG_RETURN(comment,info));

    case (cache,_,SCode.ALG_BREAK(comment,info),_) then (cache,SCode.ALG_BREAK(comment,info));

    case (_,_,stmt,_)
      equation
        Error.addInternalError(getInstanceName() + " failed: " + Dump.unparseAlgorithmStr(SCode.statementToAlgorithmItem(stmt)), sourceInfo());
      then fail();
  end matchcontinue;
end fixStatement;

protected function fixArrayDim
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Option<Absyn.ArrayDim> inAd;
  input HashTableStringToPath.HashTable inHt;
  output FCore.Cache outCache;
  output Option<Absyn.ArrayDim> outAd;
algorithm
  (outCache,outAd) := match (inCache,inEnv,inAd,inHt)
    local
      list<Absyn.Subscript> ads;
      FCore.Cache cache;
      FCore.Graph env;
      HashTableStringToPath.HashTable ht;

    case (cache,_,NONE(),_) then (cache,NONE());
    case (cache,env,SOME(ads),ht)
      equation
        (cache,ads) = fixList(cache,env,ads,ht,fixSubscript);
      then (cache,SOME(ads));
  end match;
end fixArrayDim;

protected function fixSubscript
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Subscript inSub;
  input HashTableStringToPath.HashTable inHt;
  output FCore.Cache outCache;
  output Absyn.Subscript outSub;
algorithm
  (outCache,outSub) := match (inCache,inEnv,inSub,inHt)
    local
      Absyn.Exp exp;
      FCore.Cache cache;
      FCore.Graph env;
      HashTableStringToPath.HashTable ht;

    case (cache,_,Absyn.NOSUB(),_) then (cache,Absyn.NOSUB());
    case (cache,env,Absyn.SUBSCRIPT(exp),ht)
      equation
        (cache,exp) = fixExp(cache, env, exp, ht);
      then (cache,Absyn.SUBSCRIPT(exp));
  end match;
end fixSubscript;

protected function fixTypeSpec
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.TypeSpec inTs;
  input HashTableStringToPath.HashTable inHt;
  output FCore.Cache outCache;
  output Absyn.TypeSpec outTs;
algorithm
  (outCache,outTs) := match (inCache,inEnv,inTs,inHt)
    local
      Absyn.Path path;
      Option<Absyn.ArrayDim> arrayDim;
      list<Absyn.TypeSpec> typeSpecs;
      FCore.Cache cache;
      FCore.Graph env;
      HashTableStringToPath.HashTable ht;

    case (cache,env,Absyn.TPATH(path,arrayDim),ht)
      equation
        (cache,arrayDim) = fixArrayDim(cache,env,arrayDim,ht);
        (cache,path) = fixPath(cache,env,path,ht);
      then (cache,Absyn.TPATH(path,arrayDim));
    case (cache,env,Absyn.TCOMPLEX(path,typeSpecs,arrayDim),ht)
      equation
        (cache,arrayDim) = fixArrayDim(cache,env,arrayDim,ht);
        (cache,path) = fixPath(cache,env,path,ht);
        (cache,typeSpecs) = fixList(cache,env,typeSpecs,ht,fixTypeSpec);
      then (cache,Absyn.TCOMPLEX(path,typeSpecs,arrayDim));
  end match;
end fixTypeSpec;

protected function fixPath
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  input HashTableStringToPath.HashTable inHt;
  output FCore.Cache outCache;
  output Absyn.Path outPath;
algorithm
  (outCache,outPath) := matchcontinue (inCache,inEnv,inPath,inHt)
    local
      String id;
      Absyn.Path path1,path2,path;
      FCore.Cache cache;
      FCore.Graph env;
      HashTableStringToPath.HashTable ht;
      Boolean isOutside;

    case (cache,_,path1 as Absyn.FULLYQUALIFIED(_),_)
      equation
        // path1 = FGraph.pathStripGraphScopePrefix(path1, env, false);
        //fprintln(Flags.DEBUG, "Path FULLYQUAL: " + Absyn.pathString(path));
      then
        (cache,path1);

    case (cache,env,path1,ht)
      equation
        id = Absyn.pathFirstIdent(path1);
        path2 = BaseHashTable.get(id,ht);
        path2 = Absyn.pathReplaceFirstIdent(path1,path2);
        path2 = FGraph.pathStripGraphScopePrefix(path2, env, false);
        //fprintln(Flags.DEBUG, "Replacing: " + Absyn.pathString(path1) + " with " + Absyn.pathString(path2) + " s:" + FGraph.printGraphPathStr(env));
      then (cache,path2);

    // first indent is local in the env, DO NOT QUALIFY!
    case (cache,env,path,_)
      equation
        //fprintln(Flags.DEBUG,"Try makeFullyQualified " + Absyn.pathString(path));
        (_, _) = Lookup.lookupClassLocal(env, Absyn.pathFirstIdent(path));
        path = FGraph.pathStripGraphScopePrefix(path, env, false);
        //fprintln(Flags.DEBUG,"FullyQual: " + Absyn.pathString(path));
      then (cache,path);

    case (cache,env,path,_)
      equation
        // isOutside = isPathOutsideScope(cache, env, path);
        //print("Try makeFullyQualified " + Absyn.pathString(path) + "\n");
        (cache,path) = Inst.makeFullyQualified(cache,env,path);
        // path = if_(isOutside, path, FGraph.pathStripGraphScopePrefix(path, env, false));
        path = FGraph.pathStripGraphScopePrefix(path, env, false);
        //print("FullyQual: " + Absyn.pathString(path) + "\n");
      then (cache,path);

    case (cache,env,path,_)
      equation
        path = FGraph.pathStripGraphScopePrefix(path, env, false);
        //fprintln(Flags.DEBUG, "Path not fixed: " + Absyn.pathString(path) + "\n");
      then
        (cache,path);
  end matchcontinue;
end fixPath;

public function isPathOutsideScope
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  output Boolean yes;
algorithm
  yes := matchcontinue(inCache, inEnv, inPath)
    local
      FCore.Graph env;

    case (_, _, _)
      equation
        // see where the first ident from the path leads, if is outside the current env DO NOT strip!
        (_, _, env) = Lookup.lookupClass(inCache, inEnv, Absyn.makeIdentPathFromString(Absyn.pathFirstIdent(inPath)), false);
        // if envClass is prefix of env then is outside scope
        yes = FGraph.graphPrefixOf(env, inEnv);
      then
        yes;

     else false;
  end matchcontinue;
end isPathOutsideScope;

protected function lookupVarNoErrorMessage
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.ComponentRef inComponentRef;
  output FCore.Graph outEnv;
  output String id;
algorithm
  (outEnv, id) := matchcontinue(inCache, inEnv, inComponentRef)
    case (_, _, _)
      equation
        ErrorExt.setCheckpoint("InstExtends.lookupVarNoErrorMessage");
        (_,_,_,_,_,_,outEnv,_,id) = Lookup.lookupVar(inCache, inEnv, inComponentRef);
        ErrorExt.rollBack("InstExtends.lookupVarNoErrorMessage");
      then
        (outEnv, id);
    else
      equation
        ErrorExt.rollBack("InstExtends.lookupVarNoErrorMessage");
      then
        fail();
  end matchcontinue;
end lookupVarNoErrorMessage;

protected function fixCref
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inCref;
  input HashTableStringToPath.HashTable inHt;
  output FCore.Cache outCache;
  output Absyn.ComponentRef outCref;
algorithm
  (outCache,outCref) := matchcontinue (inCache,inEnv,inCref,inHt)
    local
      String id;
      Absyn.Path path;
      DAE.ComponentRef cref_;
      FCore.Cache cache;
      FCore.Graph env, denv;
      HashTableStringToPath.HashTable ht;
      Absyn.ComponentRef cref;
      SCode.Element c;
      Boolean isOutside;

    case (cache,env,cref,ht)
      equation
        id = Absyn.crefFirstIdent(cref);
        //fprintln(Flags.DEBUG,"Try ht lookup " + id);
        path = BaseHashTable.get(id,ht);
        //fprintln(Flags.DEBUG,"Got path " + Absyn.pathString(path));
        cref = Absyn.crefReplaceFirstIdent(cref,path);
        cref = FGraph.crefStripGraphScopePrefix(cref, env, false);
        //fprintln(Flags.DEBUG, "Cref HT fixed: " + Absyn.printComponentRefStr(cref));
      then (cache,cref);

    // try lookup var (constant in a package?)
    case (cache,env,cref,_)
      equation
        id = Absyn.crefFirstIdent(cref);
        cref_ = ComponentReference.makeCrefIdent(id,DAE.T_UNKNOWN_DEFAULT,{});
        //fprintln(Flags.DEBUG,"Try lookupV " + id);
        (denv,id) = lookupVarNoErrorMessage(cache,env,cref_);
        //fprintln(Flags.DEBUG,"Got env " + intString(listLength(env)));
        // isOutside = FGraph.graphPrefixOf(denv, env);
        denv = FGraph.openScope(denv,SCode.ENCAPSULATED(),SOME(id),NONE());
        cref = Absyn.crefReplaceFirstIdent(cref,FGraph.getGraphName(denv));
        // cref = if_(isOutside, cref, FGraph.crefStripGraphScopePrefix(cref, env, false));
        cref = FGraph.crefStripGraphScopePrefix(cref, env, false);
        //fprintln(Flags.DEBUG, "Cref VAR fixed: " + Absyn.printComponentRefStr(cref));
      then (cache,cref);

    case (cache,env,cref,_)
      equation
        id = Absyn.crefFirstIdent(cref);
        //print("Try lookupC " + id + "\n");
        (_,c,denv) = Lookup.lookupClass(cache,env,Absyn.IDENT(id),false);
        // isOutside = FGraph.graphPrefixOf(denv, env);
        // id might come from named import, make sure you use the actual class name!
        id = SCode.getElementName(c);
        //fprintln(Flags.DEBUG,"Got env " + intString(listLength(env)));
        denv = FGraph.openScope(denv,SCode.ENCAPSULATED(),SOME(id),NONE());
        cref = Absyn.crefReplaceFirstIdent(cref,FGraph.getGraphName(denv));
        // cref = if_(isOutside, cref, FGraph.crefStripGraphScopePrefix(cref, env, false));
        cref = FGraph.crefStripGraphScopePrefix(cref, env, false);
        //print("Cref CLASS fixed: " + Absyn.printComponentRefStr(cref) + "\n");
      then (cache,cref);

    case (cache,_,cref,_)
      equation
        //fprintln(Flags.DEBUG, "Cref not fixed: " + Absyn.printComponentRefStr(cref));
      then
        (cache,cref);

  end matchcontinue;
end fixCref;

protected function fixModifications
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.Mod inMod;
  input HashTableStringToPath.HashTable inHt;
  output FCore.Cache outCache;
  output SCode.Mod outMod;
algorithm
  (outCache,outMod) := matchcontinue (inCache,inEnv,inMod,inHt)
    local
      SCode.Final finalPrefix "final prefix";
      SCode.Each eachPrefix;
      list<SCode.SubMod> subModLst;
      Absyn.Exp exp;
      SCode.Element elt;
      FCore.Cache cache;
      FCore.Graph env;
      HashTableStringToPath.HashTable ht;
      SCode.Mod mod;
      SourceInfo info;

    case (cache,_,SCode.NOMOD(),_) then (cache,SCode.NOMOD());

    case (cache,env,SCode.MOD(finalPrefix,eachPrefix,subModLst,SOME(exp),info),ht)
      equation
        (cache, subModLst) = fixSubModList(cache, env, subModLst, ht);
        (cache,exp) = fixExp(cache,env,exp,ht);
      then
        (cache,SCode.MOD(finalPrefix,eachPrefix,subModLst,SOME(exp),info));

    case (cache,env,SCode.MOD(finalPrefix,eachPrefix,subModLst,NONE(),info),ht)
      equation
        (cache, subModLst) = fixSubModList(cache, env, subModLst, ht);
      then
        (cache,SCode.MOD(finalPrefix,eachPrefix,subModLst,NONE(),info));

    case (cache,env,SCode.REDECL(finalPrefix, eachPrefix, elt),ht)
      equation
        (cache, elt) = fixElement(cache, env, elt, ht);
      then
        (cache,SCode.REDECL(finalPrefix, eachPrefix, elt));

    case (_,_,mod,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("InstExtends.fixModifications failed: " + SCodeDump.printModStr(mod));
      then
        fail();

  end matchcontinue;
end fixModifications;

protected function fixSubModList
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<SCode.SubMod> inSubMods;
  input HashTableStringToPath.HashTable inHt;
  output FCore.Cache outCache;
  output list<SCode.SubMod> outSubMods;
algorithm
  (outCache, outSubMods) := match (inCache, inEnv, inSubMods, inHt)
    local
      SCode.Mod mod;
      list<SCode.SubMod> rest_mods;
      Absyn.Ident ident;
      list<SCode.Subscript> subs;
      FCore.Cache cache;

    case (_, _, {}, _) then (inCache, {});

    case (_, _, SCode.NAMEMOD(ident, mod) :: rest_mods, _)
      equation
        (cache, mod) = fixModifications(inCache, inEnv, mod, inHt);
        (cache, rest_mods) = fixSubModList(cache, inEnv, rest_mods, inHt);
      then
        (cache, SCode.NAMEMOD(ident, mod) :: rest_mods);

  end match;
end fixSubModList;

protected function fixExp
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input HashTableStringToPath.HashTable inHt;
  output FCore.Cache outCache;
  output Absyn.Exp outExp;
algorithm
  (outExp,(outCache,_,_)) := Absyn.traverseExp(inExp,fixExpTraverse,(inCache,inEnv,inHt));
end fixExp;

protected function fixExpTraverse
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Absyn.Exp inExp;
  input tuple<FCore.Cache,FCore.Graph,HashTableStringToPath.HashTable> inTpl;
  output Absyn.Exp outExp;
  output tuple<FCore.Cache,FCore.Graph,HashTableStringToPath.HashTable> outTpl;
algorithm
  (outExp,outTpl) := match (inExp,inTpl)
    local
      Absyn.FunctionArgs fargs;
      Absyn.ComponentRef cref;
      Absyn.Path path;
      FCore.Cache cache;
      FCore.Graph env;
      HashTableStringToPath.HashTable ht;

    case (Absyn.CREF(cref),(cache,env,ht))
      equation
        (cache,cref) = fixCref(cache,env,cref,ht);
      then (Absyn.CREF(cref),(cache,env,ht));

    case (Absyn.CALL(cref,fargs),(cache,env,ht))
      equation
        // print("cref actual: " + Absyn.crefString(cref) + " scope: " + FGraph.printGraphPathStr(env) + "\n");
        (cache,cref) = fixCref(cache,env,cref,ht);
        // print("cref fixed : " + Absyn.crefString(cref) + "\n");
      then (Absyn.CALL(cref,fargs),(cache,env,ht));

    case (Absyn.PARTEVALFUNCTION(cref,fargs),(cache,env,ht))
      equation
        (cache,cref) = fixCref(cache,env,cref,ht);
      then (Absyn.PARTEVALFUNCTION(cref,fargs),(cache,env,ht));

    else (inExp,inTpl);
  end match;
end fixExpTraverse;

protected function fixOption
" Generic function to fix an optional element."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Option<Type_A> inA;
  input HashTableStringToPath.HashTable inHt;
  input FixAFn fixA;
  output FCore.Cache outCache;
  output Option<Type_A> outA;

  replaceable type Type_A subtypeof Any;
  partial function FixAFn
    input FCore.Cache inCache;
    input FCore.Graph inEnv;
    input Type_A inA;
    input HashTableStringToPath.HashTable inHt;
    output FCore.Cache outCache;
    output Type_A outTypeA;
  end FixAFn;
algorithm
  (outCache,outA) := match (inCache,inEnv,inA,inHt,fixA)
    local
      Type_A A;
      FCore.Cache cache;
      FCore.Graph env;
      HashTableStringToPath.HashTable ht;

    case (cache,_,NONE(),_,_) then (cache,NONE());
    case (cache,env,SOME(A),ht,_)
      equation
        (cache,A) = fixA(cache,env,A,ht);
      then (cache,SOME(A));
  end match;
end fixOption;

protected function fixList
" Generic function to fix a list of elements."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Type_A> inA;
  input HashTableStringToPath.HashTable inHt;
  input FixAFn fixA;
  output FCore.Cache outCache;
  output list<Type_A> outA;

  replaceable type Type_A subtypeof Any;
  partial function FixAFn
    input FCore.Cache inCache;
    input FCore.Graph inEnv;
    input Type_A inA;
    input HashTableStringToPath.HashTable inHt;
    output FCore.Cache outCache;
    output Type_A outTypeA;
  end FixAFn;
algorithm
  (outCache,outA) := match (inCache,inEnv,inA,inHt,fixA)
    local
      Type_A A;
      list<Type_A> lstA;
      FCore.Cache cache;
      FCore.Graph env;
      HashTableStringToPath.HashTable ht;

    case (cache,_,{},_,_) then (cache,{});
    case (cache,env,A::lstA,ht,_)
      equation
        (cache,A) = fixA(cache,env,A,ht);
        (cache,lstA) = fixList(cache,env,lstA,ht,fixA);
      then (cache,A::lstA);
  end match;
end fixList;

protected function fixListList
" Generic function to fix a list of elements."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<list<Type_A>> inA;
  input HashTableStringToPath.HashTable inHt;
  input FixAFn fixA;
  output FCore.Cache outCache;
  output list<list<Type_A>> outA;

  replaceable type Type_A subtypeof Any;
  partial function FixAFn
    input FCore.Cache inCache;
    input FCore.Graph inEnv;
    input Type_A inA;
    input HashTableStringToPath.HashTable inHt;
    output FCore.Cache outCache;
    output Type_A outTypeA;
  end FixAFn;
algorithm
  (outCache,outA) := match (inCache,inEnv,inA,inHt,fixA)
    local
      list<Type_A> A;
      list<list<Type_A>> lstA;
      FCore.Cache cache;
      FCore.Graph env;
      HashTableStringToPath.HashTable ht;

    case (cache,_,{},_,_) then (cache,{});
    case (cache,env,A::lstA,ht,_)
      equation
        (cache,A) = fixList(cache,env,A,ht,fixA);
        (cache,lstA) = fixListList(cache,env,lstA,ht,fixA);
      then (cache,A::lstA);
  end match;
end fixListList;

protected function fixListTuple2
" Generic function to fix a list of elements."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<tuple<Type_A,Type_B>> inRest;
  input HashTableStringToPath.HashTable inHt;
  input FixAFn fixA;
  input FixBFn fixB;
  output FCore.Cache outCache;
  output list<tuple<Type_A,Type_B>> outA;

  replaceable type Type_A subtypeof Any;
  replaceable type Type_B subtypeof Any;
  partial function FixAFn
    input FCore.Cache inCache;
    input FCore.Graph inEnv;
    input Type_A inA;
    input HashTableStringToPath.HashTable inHt;
    output FCore.Cache outCache;
    output Type_A outLst;
  end FixAFn;
  partial function FixBFn
    input FCore.Cache inCache;
    input FCore.Graph inEnv;
    input Type_B inA;
    input HashTableStringToPath.HashTable inHt;
    output FCore.Cache outCache;
    output Type_B outTypeA;
  end FixBFn;
algorithm
  (outCache,outA) := match (inCache,inEnv,inRest,inHt,fixA,fixB)
    local
      Type_A a;
      Type_B b;
      list<tuple<Type_A,Type_B>> rest;
      FCore.Cache cache;
      FCore.Graph env;
      HashTableStringToPath.HashTable ht;

    case (cache,_,{},_,_,_) then (cache,{});
    case (cache,env,(a,b)::rest,ht,_,_)
      equation
        (cache,a) = fixA(cache,env,a,ht);
        (cache,b) = fixB(cache,env,b,ht);
        (cache,rest) = fixListTuple2(cache,env,rest,ht,fixA,fixB);
      then (cache,(a,b)::rest);
  end match;
end fixListTuple2;

annotation(__OpenModelica_Interface="frontend");
end InstExtends;
