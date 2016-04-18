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


  This module is responsible for instantiation of the extends and
  class extends constructs in Modelica models.

"

// public imports
public import Absyn;
public import ClassInf;
public import DAE;
public import FCore;
public import InnerOuter;
public import SCode;
public import Prefix;

// protected imports
protected import AvlSetString;
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

protected function instExtendsList
  "This function flattens out the inheritance structure of a class. It takes an
   SCode.Element list and flattens out the extends nodes of that list. The
   result is a list of components and lists of equations and algorithms."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input list<SCode.Element> inLocalElements;
  input list<SCode.Element> inElementsFromExtendsScope;
  input ClassInf.State inState;
  input String inClassName "The class whose elements are getting instantiated";
  input Boolean inImpl;
  input Boolean inPartialInst;
  output FCore.Cache outCache = inCache;
  output FCore.Graph outEnv = inEnv;
  output InnerOuter.InstHierarchy outIH = inIH;
  output DAE.Mod outMod = inMod;
  output list<tuple<SCode.Element, DAE.Mod, Boolean>> outElements = {};
  output list<SCode.Equation> outNormalEqs = {};
  output list<SCode.Equation> outInitialEqs = {};
  output list<SCode.AlgorithmSection> outNormalAlgs = {};
  output list<SCode.AlgorithmSection> outInitialAlgs = {};
algorithm
  for el in listReverse(inLocalElements) loop
    _ := matchcontinue el
      local
        String cn, bc_str, scope_str, base_first_id;
        SCode.Mod emod;
        Boolean eq_name;
        Option<SCode.Element> ocls;
        SCode.Element cls;
        FCore.Graph cenv;
        SCode.Encapsulated encf;
        SCode.Restriction r;
        list<SCode.Element> els1, rest_els, import_els, cdef_els, clsext_els;
        list<tuple<SCode.Element, DAE.Mod, Boolean>> els2;
        list<SCode.Equation> eq1, ieq1, eq2, ieq2;
        list<SCode.AlgorithmSection> alg1, ialg1, alg2, ialg2;
        DAE.Mod mod;
        AvlSetString.Tree tree;
        array<FCore.Cache> cacheArr;
        Boolean htHasEntries;

      // Instantiate a basic type base class.
      case SCode.EXTENDS()
        algorithm
          Absyn.IDENT(cn) := Absyn.makeNotFullyQualified(el.baseClassPath);
          true := InstUtil.isBuiltInClass(cn);
        then
          ();

      // Instantiate a base class.
      case SCode.EXTENDS()
        algorithm
          emod := InstUtil.chainRedeclares(outMod, el.modifications);

          // Check if the extends is referencing the class we're instantiating.
          base_first_id := Absyn.pathFirstIdent(el.baseClassPath);
          eq_name := stringEq(inClassName, base_first_id) and Absyn.pathEqual(
            ClassInf.getStateName(inState),
            Absyn.joinPaths(FGraph.getGraphName(outEnv),
                            Absyn.makeIdentPathFromString(base_first_id)));

          // Look up the base class.
          (outCache, ocls, cenv) :=
            lookupBaseClass(el.baseClassPath, eq_name, inClassName, outEnv, outCache);

          if isSome(ocls) then
            SOME(cls) := ocls;
            SCode.CLASS(name = cn, encapsulatedPrefix = encf, restriction = r) := cls;
          else
            // Base class could not be found, print an error unless --permissive
            // is used.
            if Flags.getConfigBool(Flags.PERMISSIVE) then
              bc_str := Absyn.pathString(el.baseClassPath);
              scope_str := FGraph.printGraphPathStr(inEnv);
              Error.addSourceMessage(Error.LOOKUP_BASECLASS_ERROR,
                {bc_str, scope_str}, el.info);
            end if;
            fail();
          end if;

          (outCache, cenv, outIH, els1, eq1, ieq1, alg1, ialg1, mod) :=
            instDerivedClasses(outCache, cenv, outIH, outMod, inPrefix, cls, inImpl, el.info);
          els1 := updateElementListVisibility(els1, el.visibility);

          // Build a set with the constant elements from the extends scope.
          tree := AvlSetString.new();
          tree := getLocalIdentList(InstUtil.constantAndParameterEls(inElementsFromExtendsScope),
            tree, getLocalIdentElement);
          tree := getLocalIdentList(InstUtil.constantAndParameterEls(els1), tree, getLocalIdentElement);

          // Fully qualify modifiers in extends in the extends environment.
          cacheArr := arrayCreate(1, outCache);
          emod := fixModifications(cacheArr, inEnv, emod, tree);

          cenv := FGraph.openScope(cenv, encf, cn, FGraph.classInfToScopeType(inState));

          // Add classdefs and imports to env, so e.g. imports from baseclasses can be found.
          (import_els, cdef_els, clsext_els, rest_els) :=
            InstUtil.splitEltsNoComponents(els1);
          (outCache, cenv, outIH) := InstUtil.addClassdefsToEnv(outCache, cenv,
            outIH, inPrefix, import_els, inImpl, NONE());
          (outCache, cenv, outIH) := InstUtil.addClassdefsToEnv(outCache, cenv,
            outIH, inPrefix, cdef_els, inImpl, SOME(mod));

          rest_els := SCodeUtil.addRedeclareAsElementsToExtends(rest_els,
            list(e for e guard(SCodeUtil.isRedeclareElement(e)) in rest_els));

          outMod := Mod.elabUntypedMod(emod, Mod.EXTENDS(el.baseClassPath));
          outMod := Mod.merge(mod, outMod, "", false);

          (outCache, _, outIH, _, els2, eq2, ieq2, alg2, ialg2) :=
            instExtendsAndClassExtendsList2(outCache, cenv, outIH, outMod, inPrefix,
              rest_els, clsext_els, els1, inState, inClassName, inImpl, inPartialInst);

          tree := AvlSetString.new();
          tree := getLocalIdentList(els2, tree, getLocalIdentElementTpl);
          tree := getLocalIdentList(cdef_els, tree, getLocalIdentElement);
          tree := getLocalIdentList(import_els, tree, getLocalIdentElement);
          htHasEntries := not AvlSetString.isEmpty(tree);

          arrayUpdate(cacheArr, 1, outCache);
          if htHasEntries then
            els2 := fixList(cacheArr, cenv, els2, tree, fixLocalIdent);
          end if;
          // Update components with new merged modifiers.
          //(els2, outMod) := updateComponentsAndClassdefs(els2, outMod, inEnv);
          outElements := listAppend(els2, outElements);

          outNormalEqs := List.unionAppendListOnTrue(listReverse(eq2), outNormalEqs, valueEq);
          outInitialEqs := List.unionAppendListOnTrue(listReverse(ieq2), outInitialEqs, valueEq);
          outNormalAlgs := List.unionAppendListOnTrue(listReverse(alg2), outNormalAlgs, valueEq);
          outInitialAlgs := List.unionAppendListOnTrue(listReverse(ialg2), outInitialAlgs, valueEq);

          if not inPartialInst then
            if htHasEntries then
              eq1 := fixList(cacheArr, cenv,   eq1, tree, fixEquation);
              ieq1 := fixList(cacheArr, cenv,  ieq1, tree, fixEquation);
              alg1 := fixList(cacheArr, cenv,  alg1, tree, fixAlgorithm);
              ialg1 := fixList(cacheArr, cenv, ialg1, tree, fixAlgorithm);
            end if;
            outNormalEqs := List.unionAppendListOnTrue(listReverse(eq1), outNormalEqs, valueEq);
            outInitialEqs := List.unionAppendListOnTrue(listReverse(ieq1), outInitialEqs, valueEq);
            outNormalAlgs := List.unionAppendListOnTrue(listReverse(alg1), outNormalAlgs, valueEq);
            outInitialAlgs := List.unionAppendListOnTrue(listReverse(ialg1), outInitialAlgs, valueEq);
          end if;
          outCache := arrayGet(cacheArr, 1);

        then
          ();

      // Skip any extends we couldn't handle if --permissive is given.
      case SCode.EXTENDS() guard(Flags.getConfigBool(Flags.PERMISSIVE))
        then ();

      case SCode.COMPONENT()
        algorithm
          // Keep only constants if partial inst, otherwise keep all components.
          if SCode.isConstant(SCode.attrVariability(el.attributes)) or not inPartialInst then
            outElements := (el, DAE.NOMOD(), false) :: outElements;
          end if;
        then
          ();

      case SCode.CLASS()
        algorithm
          outElements := (el, DAE.NOMOD(), false) :: outElements;
        then
          ();

      case SCode.IMPORT()
        algorithm
          outElements := (el, DAE.NOMOD(), false) :: outElements;
        then
          ();

      // Instantiation failed.
      else
        equation
          true = Flags.isSet(Flags.FAILTRACE);
          Debug.traceln("- Inst.instExtendsList failed on:\n\t" +
            "className: " +  inClassName + "\n\t" +
            "env:       " +  FGraph.printGraphPathStr(outEnv) + "\n\t" +
            "mods:      " +  Mod.printModStr(outMod) + "\n\t" +
            "elem:      " + SCodeDump.unparseElementStr(el)
            );
        then
          fail();

    end matchcontinue;
  end for;

  (outElements, outMod) := updateComponentsAndClassdefs(outElements, outMod, inEnv);
end instExtendsList;

protected function lookupBaseClass
  "Looks up a base class used in an extends clause."
  input Absyn.Path inPath;
  input Boolean inSelfReference;
  input String inClassName;
  input FCore.Graph inEnv;
  input FCore.Cache inCache;
  output FCore.Cache outCache;
  output Option<SCode.Element> outElement;
  output FCore.Graph outEnv;
algorithm
  (outCache, outElement, outEnv) := match(inPath, inSelfReference)
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
    case (Absyn.IDENT(name), true)
      equation
        // Only look the name up locally, otherwise we might get an infinite
        // loop if the class extends itself.
        (elem, env) = Lookup.lookupClassLocal(inEnv, name);
      then
        (inCache, SOME(elem), env);

    // Otherwise, remove the first identifier if it's the same as the class name
    // and look it up as normal.
    case (_, _)
      equation
        path = Absyn.removePartialPrefix(Absyn.IDENT(inClassName), inPath);
        (cache, elem, env) = Lookup.lookupClass(inCache, inEnv, path);
      then
        (cache, SOME(elem), env);

    else (inCache, NONE(), inEnv);
  end match;
end lookupBaseClass;

protected function updateElementListVisibility
  input list<SCode.Element> inElements;
  input SCode.Visibility inVisibility;
  output list<SCode.Element> outElements;
algorithm
  outElements := match inVisibility
    case SCode.PUBLIC() then inElements;
    else list(SCode.makeElementProtected(e) for e in inElements);
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
  (outMod,outElements) := matchcontinue (inMod,inClassExtendsList,inElements)
    local
      SCode.Element first;
      list<SCode.Element> rest;
      String name;
      list<SCode.Element> els;
      list<tuple<SCode.Element, DAE.Mod, Boolean>> compelts;
      DAE.Mod emod;
      list<String> names;

    case (emod,{},compelts) then (emod,compelts);

    case (emod,(first as SCode.CLASS(name=name))::rest,compelts)
      equation
        (emod,compelts) = instClassExtendsList2(inEnv,emod,name,first,compelts);
        (emod,compelts) = instClassExtendsList(inEnv,emod,rest,compelts);
      then (emod,compelts);

    case (_,SCode.CLASS(name=name)::_,compelts)
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
  outClassName := "$parent." + inClassName + ".$env." + inEnvPath;
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
  (outMod,outElements) := matchcontinue (inMod,inName,inClassExtendsElt,inElements)
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
    case (emod,name1,classExtendsElt,(cl as SCode.CLASS(name = name2, classDef = SCode.PARTS()),mod1,b)::rest)
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
    case (emod,name1,classExtendsElt,(cl as SCode.CLASS(name = name2, classDef = SCode.DERIVED()),mod1,b)::rest)
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
    case (emod,name1,classExtendsElt,first::rest)
      equation
        (emod,rest) = instClassExtendsList2(inEnv,emod,name1,classExtendsElt,rest);
      then
        (emod,first::rest);

    // bah, we did not find it
    case (_,_,_,{})
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
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inClass,inBoolean,inInfo,overflow)
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
    case (cache,env,ih,_,_,SCode.CLASS(name = name),_,_,_)
      equation
        true = InstUtil.isBuiltInClass(name);
      then
        (cache,env,ih,{},{},{},{},{},inMod);

    case (cache,env,ih,_,_,SCode.CLASS(name = name, classDef =
          SCode.PARTS(elementLst = elt,
                      normalEquationLst = eq,initialEquationLst = ieq,
                      normalAlgorithmLst = alg,initialAlgorithmLst = ialg,
                      externalDecl = extdecl)),_,info,_)
      equation
        /* elt_1 = noImportElements(elt); */
        Error.assertionOrAddSourceMessage(Util.isNone(extdecl), Error.EXTENDS_EXTERNAL, {name}, info);
      then
        (cache,env,ih,elt,eq,ieq,alg,ialg,inMod);

    case (cache,env,ih,mod,pre,SCode.CLASS( info = info, classDef = SCode.DERIVED(typeSpec = Absyn.TPATH(tp, _),modifications = dmod)),impl, _, false)
      equation
        // fprintln(Flags.INST_TRACE, "DERIVED: " + FGraph.printGraphPathStr(env) + " el: " + SCodeDump.unparseElementStr(inClass) + " mods: " + Mod.printModStr(mod));
        (cache, c, cenv) = Lookup.lookupClass(cache, env, tp, SOME(info));
        dmod = InstUtil.chainRedeclares(mod, dmod);
        // false = Absyn.pathEqual(FGraph.getGraphName(env),FGraph.getGraphName(cenv)) and SCode.elementEqual(c,inClass);
        // modifiers should be evaluated in the current scope for derived!
        //daeDMOD = Mod.elabUntypedMod(dmod, Mod.DERIVED(tp));
        (cache,daeDMOD) = Mod.elabMod(cache, env, ih, pre, dmod, impl, Mod.DERIVED(tp), info);
        mod = Mod.merge(mod, daeDMOD);
        // print("DER: " + SCodeDump.unparseElementStr(inClass, SCodeDump.defaultOptions) + "\n");
        (cache,env,ih,elt,eq,ieq,alg,ialg,mod) = instDerivedClassesWork(cache, cenv, ih, mod, pre, c, impl, info, numIter >= Global.recursionDepthLimit, numIter+1)
        "Mod.lookup_modification_p(mod, c) => innermod & We have to merge and apply modifications as well!" ;
      then
        (cache,env,ih,elt,eq,ieq,alg,ialg,mod);

    case (cache,env,ih,mod,pre,SCode.CLASS(name=n, prefixes = prefixes, classDef = SCode.ENUMERATION(enumLst), cmt = cmt, info = info),impl,_,false)
      equation
        c = SCodeUtil.expandEnumeration(n, enumLst, prefixes, cmt, info);
        (cache,env,ih,elt,eq,ieq,alg,ialg,mod) = instDerivedClassesWork(cache, env, ih, mod, pre, c, impl,info, numIter >= Global.recursionDepthLimit, numIter+1);
      then
        (cache,env,ih,elt,eq,ieq,alg,ialg,mod);

    case (_,_,_,_,_,_,_,_,true)
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
  input list<SCode.Element> inElements;
  output list<SCode.Element> outElements;
algorithm
  outElements := list(e for e guard(not SCode.elementIsImport(e)) in inElements);
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
protected
  SCode.Element el;
  DAE.Mod mod;
  Boolean b;
algorithm
  (el, mod, b) := inComponent;

  (outComponent, outRestMod) := matchcontinue el
    local
      SCode.Element comp;
      DAE.Mod cmod, mod_rest;

    case SCode.COMPONENT()
      equation
        // Debug.traceln(" comp: " + id + " " + Mod.printModStr(mod));
        // take ONLY the modification from the equation if is typed
        // cmod2 = Mod.getModifs(inMod, id, m);
        cmod = Mod.lookupCompModificationFromEqu(inMod, el.name);
        // Debug.traceln("\tSpecific mods on comp: " +  Mod.printModStr(cmod2));
        cmod = Mod.merge(cmod, mod, el.name, false);
        mod_rest = inMod; //mod_rest = Mod.removeMod(inMod, id);
      then
        ((el, cmod, b), mod_rest);

    case SCode.EXTENDS()
      then (inComponent, inMod);

    case SCode.IMPORT()
      then ((el, DAE.NOMOD(), b), inMod);

    case SCode.CLASS(prefixes = SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(_)))
      equation
        DAE.REDECL(element = comp, mod = cmod) = Mod.lookupCompModification(inMod, el.name);
        mod_rest = inMod; //mod_rest = Mod.removeMod(inMod, id);
        cmod = Mod.merge(cmod, mod, el.name, false);
        comp = SCode.mergeWithOriginal(comp, el);
        // comp2 = SCode.renameElement(comp2, id);
      then
        ((comp, cmod, b), mod_rest);

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
    case SCode.CLASS()
      equation
        cmod = Mod.lookupCompModification(inMod, el.name);
        outComponent = if valueEq(cmod, DAE.NOMOD()) then inComponent else (el,cmod,b);
      then
        (outComponent, inMod);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln(
          "- InstExtends.updateComponentsAndClassdefs2 failed on:\n" +
          "env = " + FGraph.printGraphPathStr(inEnv) +
          "\nmod = " + Mod.printModStr(inMod) +
          "\ncmod = " + Mod.printModStr(mod) +
          "\nbool = " + boolString(b) + "\n" +
          SCodeDump.unparseElementStr(el)
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
  input output AvlSetString.Tree tree;
  input getIdentFn getIdent;

  replaceable type Type_A subtypeof Any;
  partial function getIdentFn
    input Type_A inA;
    input output AvlSetString.Tree tree;
  end getIdentFn;
algorithm
  for elt in ielts loop
    tree := getIdent(elt, tree);
  end for;
end getLocalIdentList;

protected function getLocalIdentElementTpl
" Analyzes the elements of a class and fetches a list of components and classdefs,
  as well as aliases from imports to paths.
"
  input tuple<SCode.Element,DAE.Mod,Boolean> eltTpl;
  input output AvlSetString.Tree tree;
protected
  SCode.Element elt;
algorithm
  (elt, _, _) := eltTpl;
  tree := getLocalIdentElement(elt, tree);
end getLocalIdentElementTpl;

protected function getLocalIdentElement
" Analyzes an element of a class and fetches a list of components and classdefs,
  as well as aliases from imports to paths."
  input SCode.Element elt;
  input output AvlSetString.Tree tree;
algorithm
  tree := match elt
    local
      String id;

    case SCode.COMPONENT(name = id)
      then AvlSetString.add(tree, id);

    case SCode.CLASS(name = id)
      then AvlSetString.add(tree, id);

    else tree;
  end match;
end getLocalIdentElement;

protected function fixLocalIdent
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment."
  input array<FCore.Cache> inCache;
  input FCore.Graph inEnv;
  input output tuple<SCode.Element,DAE.Mod,Boolean> elt;
  input AvlSetString.Tree tree;
protected
  SCode.Element elt1,elt2;
  DAE.Mod mod;
  Boolean b;
algorithm
  (elt1, mod, b) := elt;
  elt2 := fixElement(inCache, inEnv, elt1, tree);
  if (not referenceEq(elt1, elt2)) or not b then
    elt := (elt2, mod, true);
  end if;
end fixLocalIdent;

protected function fixElement
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input array<FCore.Cache> inCache;
  input FCore.Graph inEnv;
  input SCode.Element inElt;
  input AvlSetString.Tree tree;
  output SCode.Element outElts;
algorithm
  outElts := matchcontinue (inEnv,inElt)
    local
      String name;
      SCode.Prefixes prefixes;
      SCode.Partial partialPrefix;
      Absyn.TypeSpec typeSpec1, typeSpec2;
      SCode.Mod modifications1, modifications2;
      SCode.Comment comment;
      Option<Absyn.Exp> condition;
      SourceInfo info;
      SCode.ClassDef classDef1,classDef2;
      SCode.Restriction restriction;
      Option<SCode.Annotation> optAnnotation;
      Absyn.Path extendsPath1, extendsPath2;
      SCode.Visibility vis;
      Absyn.ArrayDim ad;
      SCode.ConnectorType ct;
      SCode.Variability var;
      SCode.Parallelism prl;
      Absyn.Direction dir;
      Absyn.IsField isf;
      FCore.Cache cache;
      FCore.Graph env;
      SCode.Element elt, elt2;
      SCode.Attributes attr;

    case (env,elt as SCode.COMPONENT(prefixes=SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(_))))
      algorithm
        //fprintln(Flags.DEBUG,"fix comp " + SCodeDump.unparseElementStr(elt,SCodeDump.defaultOptions));
        // lookup as it might have been redeclared!!!
        (_,_,elt2 as SCode.COMPONENT(name, prefixes, attr as SCode.ATTR(), typeSpec1, modifications1, comment, condition, info),_,_,env)
         := Lookup.lookupIdentLocal(arrayGet(inCache, 1), env, elt.name);
        modifications2 := fixModifications(inCache,env,modifications1,tree);
        typeSpec2 := fixTypeSpec(inCache,env,typeSpec1,tree);
        ad := fixArrayDim(inCache, env, attr.arrayDims, tree);
        if not referenceEq(ad, attr.arrayDims) then
          attr.arrayDims := ad;
        end if;
        if not (referenceEq(ad, attr.arrayDims) and referenceEq(typeSpec1, typeSpec2) and referenceEq(modifications1, modifications2)) then
          elt2 := SCode.COMPONENT(name, prefixes, attr, typeSpec2, modifications2, comment, condition, info);
        end if;
        //print("fixElement -1\n");
      then elt2;

    case (env,elt as SCode.COMPONENT(attributes=attr))
      algorithm
        modifications2 := fixModifications(inCache,env,elt.modifications,tree);
        typeSpec2 := fixTypeSpec(inCache,env,elt.typeSpec,tree);
        ad := fixArrayDim(inCache, env, attr.arrayDims, tree);
        if not referenceEq(ad, attr.arrayDims) then
          attr.arrayDims := ad;
        end if;
        if not (referenceEq(ad, attr.arrayDims) and referenceEq(elt.typeSpec, typeSpec2) and referenceEq(elt.modifications, modifications2)) then
          elt := SCode.COMPONENT(elt.name, elt.prefixes, attr, typeSpec2, modifications2, elt.comment, elt.condition, elt.info);
        end if;
        //print("fixElement 0\n");
      then elt;

    case (env,SCode.CLASS(name, prefixes as SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(_)),
                                SCode.ENCAPSULATED(), partialPrefix, restriction, _, comment, info))
      equation
        //fprintln(Flags.DEBUG,"fixClassdef " + name);
        // lookup as it might have been redeclared!!!
        (SCode.CLASS(prefixes = prefixes, partialPrefix = partialPrefix, restriction = restriction,
                     cmt = comment, info = info,classDef=classDef1),env) = Lookup.lookupClassLocal(env, name);
        env = FGraph.openScope(env, SCode.ENCAPSULATED(), name, FGraph.restrictionToScopeType(restriction));
        classDef2 = fixClassdef(inCache, env,classDef1,tree);
        //print("fixElement 1\n");
      then
        (if referenceEq(classDef1,classDef2) then inElt else SCode.CLASS(name, prefixes, SCode.ENCAPSULATED(), partialPrefix, restriction, classDef2, comment, info));

    // failed above
    case (env,SCode.CLASS(name, prefixes, SCode.ENCAPSULATED(), partialPrefix, restriction, classDef1, comment, info))
      equation
        //fprintln(Flags.DEBUG,"fixClassdef " + name);
        env = FGraph.openScope(env, SCode.ENCAPSULATED(), name, FGraph.restrictionToScopeType(restriction));
        classDef2 = fixClassdef(inCache, env,classDef1,tree);
        //print("fixElement 2\n");
      then
        (if referenceEq(classDef1,classDef2) then inElt else SCode.CLASS(name, prefixes, SCode.ENCAPSULATED(), partialPrefix, restriction, classDef2, comment, info));

    case (env,SCode.CLASS(name, prefixes as SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(_)),
                                SCode.NOT_ENCAPSULATED(), partialPrefix, restriction, _, comment, info))
      equation
        //fprintln(Flags.DEBUG,"fixClassdef " + name + str);
        // lookup as it might have been redeclared!!!
        (SCode.CLASS(prefixes = prefixes, partialPrefix = partialPrefix, restriction = restriction,
                     cmt = comment, info = info,classDef=classDef1),env) = Lookup.lookupClassLocal(env, name);

        env = FGraph.openScope(env, SCode.NOT_ENCAPSULATED(), name, FGraph.restrictionToScopeType(restriction));
        classDef2 = fixClassdef(inCache,env,classDef1,tree);
        //print("fixElement 3\n");
      then
        (if referenceEq(classDef1,classDef2) then inElt else SCode.CLASS(name, prefixes, SCode.NOT_ENCAPSULATED(), partialPrefix, restriction, classDef2, comment, info));

    // failed above
    case (env,SCode.CLASS(name, prefixes, SCode.NOT_ENCAPSULATED(), partialPrefix, restriction, classDef1, comment, info))
      equation
        //fprintln(Flags.DEBUG,"fixClassdef " + name + str);
        env = FGraph.openScope(env, SCode.NOT_ENCAPSULATED(), name, FGraph.restrictionToScopeType(restriction));
        classDef2 = fixClassdef(inCache,env,classDef1,tree);
        //print("fixElement 4\n");
      then
        (if referenceEq(classDef1,classDef2) then inElt else SCode.CLASS(name, prefixes, SCode.NOT_ENCAPSULATED(), partialPrefix, restriction, classDef2, comment, info));

    case (env,SCode.EXTENDS(extendsPath1,vis,modifications1,optAnnotation,info))
      equation
        //fprintln(Flags.DEBUG,"fix extends " + SCodeDump.unparseElementStr(elt,SCodeDump.defaultOptions));
        extendsPath2 = fixPath(inCache,env,extendsPath1,tree);
        modifications2 = fixModifications(inCache,env,modifications1,tree);
        //print("fixElement 5\n");
      then
        (if referenceEq(extendsPath1,extendsPath2) and referenceEq(modifications1,modifications2) then inElt else SCode.EXTENDS(extendsPath2,vis,modifications2,optAnnotation,info));

    case (_,SCode.IMPORT()) then inElt;

    case (_,elt)
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
  input array<FCore.Cache> cache;
  input FCore.Graph inEnv;
  input SCode.ClassDef inCd;
  input AvlSetString.Tree inTree;
  output SCode.ClassDef outCd;
protected
  AvlSetString.Tree tree=inTree;
algorithm
  outCd := matchcontinue (inEnv,inCd)
    local
      list<SCode.Element> elts,elts_1;
      list<SCode.Equation> ne,ne_1,ie,ie_1;
      list<SCode.AlgorithmSection> na,na_1,ia,ia_1;
      list<SCode.ConstraintSection> nc,nc_1;
      list<Absyn.NamedArg> clats;
      Option<SCode.ExternalDecl> ed;
      list<SCode.Annotation> ann;
      Option<SCode.Comment> c;
      Absyn.TypeSpec ts,ts_1;
      SCode.Attributes attr;
      String name;
      SCode.Mod mod,mod_1;
      FCore.Graph env;
      SCode.ClassDef cd,cd_1;

    case (env,SCode.PARTS(elts,ne,ie,na,ia,nc,clats,ed))
      algorithm
        tree := getLocalIdentList(elts, tree, getLocalIdentElement);
        elts_1 := fixList(cache,env,elts,tree,fixElement);
        ne_1 := fixList(cache,env,ne,tree,fixEquation);
        ie_1 := fixList(cache,env,ie,tree,fixEquation);
        na_1 := fixList(cache,env,na,tree,fixAlgorithm);
        ia_1 := fixList(cache,env,ia,tree,fixAlgorithm);
        nc_1 := fixList(cache,env,nc,tree,fixConstraint);
      then if referenceEq(elts,elts_1) and referenceEq(ne,ne_1) and referenceEq(ie,ie_1) and referenceEq(na,na_1) and referenceEq(ia,ia_1) and referenceEq(nc,nc_1)
           then inCd else SCode.PARTS(elts_1,ne_1,ie_1,na_1,ia_1,nc_1,clats,ed);

    case (env,SCode.CLASS_EXTENDS(name,mod,cd as SCode.PARTS(elts,ne,ie,na,ia,nc,clats,ed)))
      equation
        mod_1 = fixModifications(cache,env,mod,inTree);
        elts_1 = fixList(cache,env,elts,tree,fixElement);
        ne_1 = fixList(cache,env,ne,tree,fixEquation);
        ie_1 = fixList(cache,env,ie,tree,fixEquation);
        na_1 = fixList(cache,env,na,tree,fixAlgorithm);
        ia_1 = fixList(cache,env,ia,tree,fixAlgorithm);
        nc_1 = fixList(cache,env,nc,tree,fixConstraint);
        cd_1 = if referenceEq(elts,elts_1) and referenceEq(ne,ne_1) and referenceEq(ie,ie_1) and referenceEq(na,na_1) and referenceEq(ia,ia_1) and referenceEq(nc,nc_1)
             then cd else SCode.PARTS(elts_1,ne_1,ie_1,na_1,ia_1,nc_1,clats,ed);
      then if referenceEq(cd,cd_1) and referenceEq(mod,mod_1)
           then inCd else SCode.CLASS_EXTENDS(name,mod_1,cd_1);

    case (env,SCode.DERIVED(ts,mod,attr))
      equation
        ts_1 = fixTypeSpec(cache,env,ts,tree);
        mod_1 = fixModifications(cache,env,mod,tree);
      then if referenceEq(ts,ts_1) and referenceEq(mod,mod_1) then inCd else SCode.DERIVED(ts_1,mod_1,attr);

    case (_,cd as SCode.ENUMERATION()) then cd;
    case (_,cd as SCode.OVERLOAD()) then cd;
    case (_,cd as SCode.PDER()) then cd;

    case (_,cd)
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
  input array<FCore.Cache> inCache;
  input FCore.Graph inEnv;
  input SCode.Equation inEq;
  input AvlSetString.Tree tree;
  output SCode.Equation outEq;
algorithm
  outEq := match inEq
    local
      SCode.EEquation eeq1,eeq2;

    case SCode.EQUATION(eeq1)
      algorithm
        eeq2 := fixEEquation(inCache, inEnv, eeq1, tree);
      then if referenceEq(eeq1,eeq2) then inEq else SCode.EQUATION(eeq2);

    case SCode.EQUATION(eeq1)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Inst.fixEquation failed: " + SCodeDump.equationStr(eeq1));
      then fail();
  end match;
end fixEquation;

protected function fixEEquation
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input array<FCore.Cache> cache;
  input FCore.Graph inEnv;
  input SCode.EEquation inEeq;
  input AvlSetString.Tree tree;
  output SCode.EEquation outEeq;
algorithm
  outEeq := match inEeq
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

    case SCode.EQ_IF(expl,eqll,eql,comment,info)
      equation
        expl = fixList(cache,inEnv,expl,tree,fixExp);
        eqll = fixListList(cache,inEnv,eqll,tree,fixEEquation);
        eql = fixList(cache,inEnv,eql,tree,fixEEquation);
      then (SCode.EQ_IF(expl,eqll,eql,comment,info));
    case SCode.EQ_EQUALS(exp1,exp2,comment,info)
      equation
        exp1 = fixExp(cache,inEnv,exp1,tree);
        exp2 = fixExp(cache,inEnv,exp2,tree);
      then (SCode.EQ_EQUALS(exp1,exp2,comment,info));
    case SCode.EQ_PDE(exp1,exp2,cref,comment,info)
      equation
        exp1 = fixExp(cache,inEnv,exp1,tree);
        exp2 = fixExp(cache,inEnv,exp2,tree);
        cref = fixCref(cache,inEnv,cref,tree);
      then (SCode.EQ_PDE(exp1,exp2,cref,comment,info));
    case SCode.EQ_CONNECT(cref1,cref2,comment,info)
      equation
        cref1 = fixCref(cache,inEnv,cref1,tree);
        cref2 = fixCref(cache,inEnv,cref2,tree);
      then (SCode.EQ_CONNECT(cref1,cref2,comment,info));
    case SCode.EQ_FOR(id,optExp,eql,comment,info)
      equation
        optExp = fixOption(cache,inEnv,optExp,tree,fixExp);
        eql = fixList(cache,inEnv,eql,tree,fixEEquation);
      then (SCode.EQ_FOR(id,optExp,eql,comment,info));
    case SCode.EQ_WHEN(exp,eql,whenlst,comment,info)
      equation
        exp = fixExp(cache,inEnv,exp,tree);
        eql = fixList(cache,inEnv,eql,tree,fixEEquation);
        whenlst = fixListTuple2(cache,inEnv,whenlst,tree,fixExp,fixListEEquation);
      then (SCode.EQ_WHEN(exp,eql,whenlst,comment,info));
    case SCode.EQ_ASSERT(exp1,exp2,exp3,comment,info)
      equation
        exp1 = fixExp(cache,inEnv,exp1,tree);
        exp2 = fixExp(cache,inEnv,exp2,tree);
        exp3 = fixExp(cache,inEnv,exp3,tree);
      then (SCode.EQ_ASSERT(exp1,exp2,exp3,comment,info));
    case SCode.EQ_TERMINATE(exp,comment,info)
      equation
        exp = fixExp(cache,inEnv,exp,tree);
      then (SCode.EQ_TERMINATE(exp,comment,info));
    case SCode.EQ_REINIT(cref,exp,comment,info)
      equation
        cref = fixCref(cache,inEnv,cref,tree);
        exp = fixExp(cache,inEnv,exp,tree);
      then (SCode.EQ_REINIT(cref,exp,comment,info));
    case SCode.EQ_NORETCALL(exp,comment,info)
      equation
        exp = fixExp(cache,inEnv,exp,tree);
      then (SCode.EQ_NORETCALL(exp,comment,info));
  end match;
end fixEEquation;

protected function fixListEEquation
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input array<FCore.Cache> cache;
  input FCore.Graph env;
  input list<SCode.EEquation> eeq;
  input AvlSetString.Tree tree;
  output list<SCode.EEquation> outEeq;
algorithm
  outEeq := fixList(cache,env,eeq,tree,fixEEquation);
end fixListEEquation;

protected function fixAlgorithm
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input array<FCore.Cache> inCache;
  input FCore.Graph inEnv;
  input SCode.AlgorithmSection inAlg;
  input AvlSetString.Tree tree;
  output SCode.AlgorithmSection outAlg;
protected
  list<SCode.Statement> stmts1,stmts2;
algorithm
  SCode.ALGORITHM(stmts1) := inAlg;
  stmts2 := fixList(inCache, inEnv, stmts1, tree, fixStatement);
  outAlg := if referenceEq(stmts1,stmts2) then inAlg else SCode.ALGORITHM(stmts2);
end fixAlgorithm;

protected function fixConstraint
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input array<FCore.Cache> inCache;
  input FCore.Graph inEnv;
  input SCode.ConstraintSection inConstrs;
  input AvlSetString.Tree tree;
  output SCode.ConstraintSection outConstrs;
protected
  list<Absyn.Exp> exps;
algorithm
  SCode.CONSTRAINTS(exps) := inConstrs;
  exps := fixList(inCache, inEnv, exps, tree, fixExp);
  outConstrs := SCode.CONSTRAINTS(exps);
end fixConstraint;

protected function fixListAlgorithmItem
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input array<FCore.Cache> cache;
  input FCore.Graph env;
  input list<SCode.Statement> alg;
  input AvlSetString.Tree tree;
  output list<SCode.Statement> outAlg;
algorithm
  outAlg := fixList(cache,env,alg,tree,fixStatement);
end fixListAlgorithmItem;

protected function fixStatement
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input array<FCore.Cache> cache;
  input FCore.Graph inEnv;
  input SCode.Statement inStmt;
  input AvlSetString.Tree tree;
  output SCode.Statement outStmt;
algorithm
  outStmt := matchcontinue inStmt
    local
      Absyn.Exp exp,exp1,exp2,exp1_1,exp2_1;
      Option<Absyn.Exp> optExp;
      String iter;
      list<tuple<Absyn.Exp, list<SCode.Statement>>> elseifbranch,whenlst;
      list<SCode.Statement> truebranch,elsebranch,forbody,whilebody;
      SCode.Comment comment;
      SourceInfo info;
      SCode.Statement stmt;
      Absyn.ComponentRef cr;

    case SCode.ALG_ASSIGN(exp1,exp2,comment,info)
      equation
        exp1_1 = fixExp(cache,inEnv,exp1,tree);
        exp2_1 = fixExp(cache,inEnv,exp2,tree);
      then if referenceEq(exp1,exp1_1) and referenceEq(exp2,exp2_1) then inStmt else SCode.ALG_ASSIGN(exp1_1,exp2_1,comment,info);

    case SCode.ALG_IF(exp,truebranch,elseifbranch,elsebranch,comment,info)
      equation
        exp = fixExp(cache,inEnv,exp,tree);
        truebranch = fixList(cache,inEnv,truebranch,tree,fixStatement);
        elseifbranch = fixListTuple2(cache,inEnv,elseifbranch,tree,fixExp,fixListAlgorithmItem);
        elsebranch = fixList(cache,inEnv,elsebranch,tree,fixStatement);
      then SCode.ALG_IF(exp,truebranch,elseifbranch,elsebranch,comment,info);

    case SCode.ALG_FOR(iter,optExp,forbody,comment,info)
      equation
        optExp = fixOption(cache,inEnv,optExp,tree,fixExp);
        forbody = fixList(cache,inEnv,forbody,tree,fixStatement);
      then SCode.ALG_FOR(iter,optExp,forbody,comment,info);

    case SCode.ALG_PARFOR(iter,optExp,forbody,comment,info)
      equation
        optExp = fixOption(cache,inEnv,optExp,tree,fixExp);
        forbody = fixList(cache,inEnv,forbody,tree,fixStatement);
      then SCode.ALG_PARFOR(iter,optExp,forbody,comment,info);

    case SCode.ALG_WHILE(exp,whilebody,comment,info)
      equation
        exp = fixExp(cache,inEnv,exp,tree);
        whilebody = fixList(cache,inEnv,whilebody,tree,fixStatement);
      then SCode.ALG_WHILE(exp,whilebody,comment,info);

    case SCode.ALG_WHEN_A(whenlst,comment,info)
      equation
        whenlst = fixListTuple2(cache,inEnv,whenlst,tree,fixExp,fixListAlgorithmItem);
      then SCode.ALG_WHEN_A(whenlst,comment,info);

    case SCode.ALG_ASSERT(exp, exp1, exp2, comment, info)
      algorithm
        exp := fixExp(cache, inEnv, exp, tree);
        exp1 := fixExp(cache, inEnv, exp1, tree);
        exp2 := fixExp(cache, inEnv, exp2, tree);
      then SCode.ALG_ASSERT(exp, exp1, exp2, comment, info);

    case SCode.ALG_TERMINATE(exp, comment, info)
      algorithm
        exp := fixExp(cache, inEnv, exp, tree);
      then SCode.ALG_TERMINATE(exp, comment, info);

    case SCode.ALG_REINIT(cr, exp, comment, info)
      algorithm
        cr := fixCref(cache, inEnv, cr, tree);
        exp := fixExp(cache, inEnv, exp, tree);
      then SCode.ALG_REINIT(cr, exp, comment, info);

    case SCode.ALG_NORETCALL(exp,comment,info)
      equation
        exp = fixExp(cache,inEnv,exp,tree);
      then SCode.ALG_NORETCALL(exp,comment,info);

    case SCode.ALG_RETURN(comment,info) then inStmt;

    case SCode.ALG_BREAK(comment,info) then inStmt;

    else
      equation
        Error.addInternalError(getInstanceName() + " failed: " +
          Dump.unparseAlgorithmStr(SCode.statementToAlgorithmItem(inStmt)), sourceInfo());
      then fail();
  end matchcontinue;
end fixStatement;

protected function fixArrayDim
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input array<FCore.Cache> inCache;
  input FCore.Graph inEnv;
  input output Absyn.ArrayDim ads;
  input AvlSetString.Tree tree;
algorithm
  ads := fixList(inCache, inEnv, ads, tree, fixSubscript);
end fixArrayDim;

protected function fixSubscript
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input array<FCore.Cache> cache;
  input FCore.Graph inEnv;
  input Absyn.Subscript inSub;
  input AvlSetString.Tree tree;
  output Absyn.Subscript outSub;
algorithm
  outSub := match inSub
    local
      Absyn.Exp exp1, exp2;

    case Absyn.NOSUB() then inSub;
    case Absyn.SUBSCRIPT(exp1)
      algorithm
        exp2 := fixExp(cache, inEnv, exp1, tree);
      then if referenceEq(exp1,exp2) then inSub else Absyn.SUBSCRIPT(exp2);
  end match;
end fixSubscript;

protected function fixTypeSpec
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input array<FCore.Cache> cache;
  input FCore.Graph inEnv;
  input Absyn.TypeSpec inTs;
  input AvlSetString.Tree tree;
  output Absyn.TypeSpec outTs;
algorithm
  outTs := match inTs
    local
      Absyn.Path path1, path2;
      Option<Absyn.ArrayDim> arrayDim1,arrayDim2;
      list<Absyn.TypeSpec> typeSpecs1, typeSpecs2;

    case Absyn.TPATH(path1,arrayDim1)
      equation
        arrayDim2 = fixOption(cache,inEnv,arrayDim1,tree,fixArrayDim);
        path2 = fixPath(cache,inEnv,path1,tree);
      then if referenceEq(arrayDim2,arrayDim1) and referenceEq(path1,path2) then inTs else Absyn.TPATH(path2,arrayDim2);
    case Absyn.TCOMPLEX(path1,typeSpecs1,arrayDim1)
      equation
        arrayDim2 = fixOption(cache,inEnv,arrayDim1,tree,fixArrayDim);
        path2 = fixPath(cache,inEnv,path1,tree);
        typeSpecs2 = fixList(cache,inEnv,typeSpecs1,tree,fixTypeSpec);
      then if referenceEq(arrayDim2,arrayDim1) and referenceEq(path1,path2) and referenceEq(typeSpecs1,typeSpecs2) then inTs else Absyn.TCOMPLEX(path2,typeSpecs2,arrayDim2);
  end match;
end fixTypeSpec;

protected function fixPath
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment."
  input array<FCore.Cache> inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  input AvlSetString.Tree tree;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue inPath
    local
      String id;
      Absyn.Path path2,path;
      FCore.Cache cache;

    case Absyn.FULLYQUALIFIED()
      then inPath;

    case _
      equation
        id = Absyn.pathFirstIdent(inPath);
        true = AvlSetString.hasKey(tree, id);
        path2 = FGraph.pathStripGraphScopePrefix(inPath, inEnv, false);
      then path2;

    // first indent is local in the inEnv, DO NOT QUALIFY!
    case _
      equation
        //fprintln(Flags.DEBUG,"Try makeFullyQualified " + Absyn.pathString(path));
        (_, _) = Lookup.lookupClassLocal(inEnv, Absyn.pathFirstIdent(inPath));
        path = FGraph.pathStripGraphScopePrefix(inPath, inEnv, false);
        //fprintln(Flags.DEBUG,"FullyQual: " + Absyn.pathString(path));
      then path;

    case _
      equation
        // isOutside = isPathOutsideScope(cache, inEnv, path);
        //print("Try makeFullyQualified " + Absyn.pathString(path) + "\n");
        (cache, path) = Inst.makeFullyQualified(arrayGet(inCache,1), inEnv, inPath);
        // path = if_(isOutside, path, FGraph.pathStripGraphScopePrefix(path, inEnv, false));
        path = FGraph.pathStripGraphScopePrefix(path, inEnv, false);
        //print("FullyQual: " + Absyn.pathString(path) + "\n");
        arrayUpdate(inCache, 1, cache);
      then path;

    else
      equation
        path = FGraph.pathStripGraphScopePrefix(inPath, inEnv, false);
        //fprintln(Flags.DEBUG, "Path not fixed: " + Absyn.pathString(path) + "\n");
      then path;

  end matchcontinue;
end fixPath;

protected function lookupVarNoErrorMessage
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input String ident;
  output FCore.Graph outEnv;
  output String id;
algorithm
  try
    ErrorExt.setCheckpoint("InstExtends.lookupVarNoErrorMessage");
    (_,_,_,_,_,_,outEnv,_,id) := Lookup.lookupVarIdent(inCache, inEnv, ident);
    ErrorExt.rollBack("InstExtends.lookupVarNoErrorMessage");
  else
    ErrorExt.rollBack("InstExtends.lookupVarNoErrorMessage");
    fail();
  end try;
end lookupVarNoErrorMessage;

protected function fixCref
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment."
  input array<FCore.Cache> cache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inCref;
  input AvlSetString.Tree tree;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := matchcontinue (inEnv,inCref)
    local
      String id;
      Absyn.Path path;
      DAE.ComponentRef cref_;
      FCore.Graph env, denv;
      Absyn.ComponentRef cref;
      SCode.Element c;
      Boolean isOutside;

    case (env,cref)
      algorithm
        id := Absyn.crefFirstIdent(cref);
        true := AvlSetString.hasKey(tree, id);
        cref := FGraph.crefStripGraphScopePrefix(cref, env, false);
        cref := if Absyn.crefEqual(cref, inCref) then inCref else cref;
      then cref;

    // try lookup var (constant in a package?)
    case (env,cref)
      equation
        id = Absyn.crefFirstIdent(cref);
        //fprintln(Flags.DEBUG,"Try lookupV " + id);
        (denv,id) = lookupVarNoErrorMessage(arrayGet(cache,1),env,id);
        //fprintln(Flags.DEBUG,"Got env " + intString(listLength(env)));
        // isOutside = FGraph.graphPrefixOf(denv, env);
        denv = FGraph.openScope(denv,SCode.ENCAPSULATED(),id,NONE());
        cref = Absyn.crefReplaceFirstIdent(cref,FGraph.getGraphName(denv));
        // cref = if_(isOutside, cref, FGraph.crefStripGraphScopePrefix(cref, env, false));
        cref = FGraph.crefStripGraphScopePrefix(cref, env, false);
        //fprintln(Flags.DEBUG, "Cref VAR fixed: " + Absyn.printComponentRefStr(cref));
        cref = if Absyn.crefEqual(cref, inCref) then inCref else cref;
      then cref;

    case (env,cref)
      equation
        id = Absyn.crefFirstIdent(cref);
        //print("Try lookupC " + id + "\n");
        (_,c,denv) = Lookup.lookupClassIdent(arrayGet(cache,1),env,id);
        // isOutside = FGraph.graphPrefixOf(denv, env);
        // id might come from named import, make sure you use the actual class name!
        id = SCode.getElementName(c);
        //fprintln(Flags.DEBUG,"Got env " + intString(listLength(env)));
        denv = FGraph.openScope(denv,SCode.ENCAPSULATED(),id,NONE());
        cref = Absyn.crefReplaceFirstIdent(cref,FGraph.getGraphName(denv));
        // cref = if_(isOutside, cref, FGraph.crefStripGraphScopePrefix(cref, env, false));
        cref = FGraph.crefStripGraphScopePrefix(cref, env, false);
        //print("Cref CLASS fixed: " + Absyn.printComponentRefStr(cref) + "\n");
        cref = if Absyn.crefEqual(cref, inCref) then inCref else cref;
      then cref;

    else inCref;

  end matchcontinue;
end fixCref;

protected function fixModifications
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input array<FCore.Cache> inCache;
  input FCore.Graph inEnv;
  input SCode.Mod inMod;
  input AvlSetString.Tree tree;
  output SCode.Mod outMod = inMod;
algorithm
  outMod := matchcontinue outMod
    local
      list<SCode.SubMod> subModLst;
      Option<Absyn.Exp> exp;
      SCode.Element e;
      SCode.ClassDef cdef;

    case SCode.NOMOD() then inMod;

    case SCode.MOD()
      algorithm
        subModLst := fixList(inCache, inEnv, outMod.subModLst, tree, fixSubMod);
        if not referenceEq(outMod.subModLst, subModLst) then
          outMod.subModLst := subModLst;
        end if;

        exp := fixOption(inCache, inEnv, outMod.binding, tree, fixExp);
        if not referenceEq(exp, outMod.binding) then
          outMod.binding := exp;
        end if;
      then outMod;

    case SCode.REDECL(element = SCode.COMPONENT())
      algorithm
        e := fixElement(inCache, inEnv, outMod.element, tree);
        if not referenceEq(e, outMod.element) then
          outMod.element := e;
        end if;
      then outMod;

    case SCode.REDECL(element = e as SCode.CLASS(classDef = cdef))
      algorithm
        cdef := fixClassdef(inCache, inEnv, cdef, tree);
        if not referenceEq(cdef, e.classDef) then
          e.classDef := cdef;
          outMod.element := e;
        end if;
      then outMod;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("InstExtends.fixModifications failed: " + SCodeDump.printModStr(inMod));
      then
        fail();

  end matchcontinue;
end fixModifications;

protected function fixSubMod
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment."
  input array<FCore.Cache> inCache;
  input FCore.Graph inEnv;
  input output SCode.SubMod subMod;
  input AvlSetString.Tree tree;
protected
  Absyn.Ident ident;
  SCode.Mod mod1, mod2;
algorithm
  SCode.NAMEMOD(ident, mod1) := subMod;
  mod2 := fixModifications(inCache, inEnv, mod1, tree);
  if not referenceEq(mod1, mod2) then
    subMod := SCode.NAMEMOD(ident, mod2);
  end if;
end fixSubMod;

protected function fixExp
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input array<FCore.Cache> cache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input AvlSetString.Tree tree;
  output Absyn.Exp outExp;
algorithm
  (outExp,_) := Absyn.traverseExp(inExp,fixExpTraverse,(cache,inEnv,tree));
end fixExp;

protected function fixExpTraverse
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input output Absyn.Exp exp;
  input output tuple<array<FCore.Cache>,FCore.Graph,AvlSetString.Tree> tpl;
protected
  Absyn.Exp inExp=exp;
algorithm
  exp := match (exp,tpl)
    local
      Absyn.FunctionArgs fargs;
      Absyn.ComponentRef cref, cref1;
      Absyn.Path path;
      array<FCore.Cache> cache;
      FCore.Graph env;
      AvlSetString.Tree tree;

    case (Absyn.CREF(cref),(cache,env,tree))
      equation
        cref1 = fixCref(cache,env,cref,tree);
      then (if referenceEq(cref, cref1) then exp else Absyn.CREF(cref1));

    case (Absyn.CALL(cref,fargs),(cache,env,tree))
      equation
        // print("cref actual: " + Absyn.crefString(cref) + " scope: " + FGraph.printGraphPathStr(env) + "\n");
        cref1 = fixCref(cache,env,cref,tree);
        // print("cref fixed : " + Absyn.crefString(cref) + "\n");
      then (if referenceEq(cref, cref1) then exp else Absyn.CALL(cref1,fargs));

    case (Absyn.PARTEVALFUNCTION(cref,fargs),(cache,env,tree))
      equation
        cref1 = fixCref(cache,env,cref,tree);
      then (if referenceEq(cref, cref1) then exp else Absyn.PARTEVALFUNCTION(cref1,fargs));

    else exp;
  end match;
end fixExpTraverse;

protected function fixOption<Type_A>
" Generic function to fix an optional element."
  input array<FCore.Cache> inCache;
  input FCore.Graph inEnv;
  input Option<Type_A> inA;
  input AvlSetString.Tree tree;
  input FixAFn fixA;
  output Option<Type_A> outA;

  partial function FixAFn
    input array<FCore.Cache> inCache;
    input FCore.Graph inEnv;
    input Type_A inA;
    input AvlSetString.Tree tree;
    output Type_A outTypeA;
  end FixAFn;
algorithm
  outA := match inA
    local
      Type_A A1,A2;

    case NONE() then inA;
    case SOME(A1)
      equation
        A2 = fixA(inCache, inEnv, A1, tree);
      then if referenceEq(A1,A2) then inA else SOME(A2);
  end match;
end fixOption;

protected function fixList<Type_A>
" Generic function to fix a list of elements."
  input array<FCore.Cache> inCache;
  input FCore.Graph inEnv;
  input list<Type_A> inA;
  input AvlSetString.Tree tree;
  input FixAFn fixA;
  output list<Type_A> outA;

  partial function FixAFn
    input array<FCore.Cache> inCache;
    input FCore.Graph inEnv;
    input Type_A inA;
    input AvlSetString.Tree tree;
    output Type_A outTypeA;
  end FixAFn;
algorithm
  if listEmpty(inA) then
    outA := inA;
    return;
  end if;
  outA := List.mapCheckReferenceEq(inA, function fixA(inCache=inCache, inEnv=inEnv, tree=tree));
end fixList;

protected function fixListList<Type_A>
" Generic function to fix a list of elements."
  input array<FCore.Cache> inCache;
  input FCore.Graph inEnv;
  input list<list<Type_A>> inA;
  input AvlSetString.Tree tree;
  input FixAFn fixA;
  output list<list<Type_A>> outA = {};

  partial function FixAFn
    input array<FCore.Cache> inCache;
    input FCore.Graph inEnv;
    input Type_A inA;
    input AvlSetString.Tree tree;
    output Type_A outTypeA;
  end FixAFn;
algorithm
  if listEmpty(inA) then
    outA := {};
    return;
  end if;

  outA := List.mapCheckReferenceEq(inA, function fixList(inCache=inCache, inEnv=inEnv, tree=tree, fixA=fixA));
end fixListList;

protected function fixListTuple2<Type_A, Type_B>
" Generic function to fix a list of elements."
  input array<FCore.Cache> inCache;
  input FCore.Graph inEnv;
  input list<tuple<Type_A,Type_B>> inRest;
  input AvlSetString.Tree tree;
  input FixAFn fixA;
  input FixBFn fixB;
  output list<tuple<Type_A,Type_B>> outA;

  partial function FixAFn
    input array<FCore.Cache> inCache;
    input FCore.Graph inEnv;
    input Type_A inA;
    input AvlSetString.Tree tree;
    output Type_A outLst;
  end FixAFn;
  partial function FixBFn
    input array<FCore.Cache> inCache;
    input FCore.Graph inEnv;
    input Type_B inA;
    input AvlSetString.Tree tree;
    output Type_B outTypeA;
  end FixBFn;
protected
  Type_A a1,a2;
  Type_B b1,b2;
algorithm
  outA := fixList(inCache, inEnv, inRest, tree, function fixTuple2(fixA=fixA, fixB=fixB));
end fixListTuple2;

protected function fixTuple2<Type_A, Type_B>
" Generic function to fix a list of elements."
  input array<FCore.Cache> inCache;
  input FCore.Graph inEnv;
  input output tuple<Type_A,Type_B> tpl;
  input AvlSetString.Tree tree;
  input FixAFn fixA;
  input FixBFn fixB;

  partial function FixAFn
    input array<FCore.Cache> inCache;
    input FCore.Graph inEnv;
    input Type_A inA;
    input AvlSetString.Tree tree;
    output Type_A outLst;
  end FixAFn;
  partial function FixBFn
    input array<FCore.Cache> inCache;
    input FCore.Graph inEnv;
    input Type_B inA;
    input AvlSetString.Tree tree;
    output Type_B outTypeA;
  end FixBFn;
protected
  Type_A a1,a2;
  Type_B b1,b2;
algorithm
  (a1, b1) := tpl;
  a2 := fixA(inCache, inEnv, a1, tree);
  b2 := fixB(inCache, inEnv, b1, tree);
  if not (referenceEq(a1,a2) and referenceEq(b1,b2)) then
    tpl := (a2, b2);
  end if;
end fixTuple2;

annotation(__OpenModelica_Interface="frontend");
end InstExtends;
