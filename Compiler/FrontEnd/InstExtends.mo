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
        HashTableStringToPath.HashTable ht;

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

          // Build a hashtable with the constant elements from the extends scope.
          ht := HashTableStringToPath.emptyHashTableSized(BaseHashTable.lowBucketSize);
          ht := getLocalIdentList(InstUtil.constantAndParameterEls(inElementsFromExtendsScope),
            ht, getLocalIdentElement);
          ht := getLocalIdentList(InstUtil.constantAndParameterEls(els1), ht, getLocalIdentElement);

          // Fully qualify modifiers in extends in the extends environment.
          (outCache, emod) := fixModifications(outCache, inEnv, emod, {ht});

          cenv := FGraph.openScope(cenv, encf, SOME(cn), FGraph.classInfToScopeType(inState));

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

          ht := HashTableStringToPath.emptyHashTableSized(BaseHashTable.lowBucketSize);
          ht := getLocalIdentList(els2, ht, getLocalIdentElementTpl);
          ht := getLocalIdentList(cdef_els, ht, getLocalIdentElement);
          ht := getLocalIdentList(import_els, ht, getLocalIdentElement);

          (outCache, els2) := fixLocalIdents(outCache, cenv, els2, {ht});
          // Update components with new merged modifiers.
          //(els2, outMod) := updateComponentsAndClassdefs(els2, outMod, inEnv);
          outElements := listAppend(els2, outElements);

          outNormalEqs := List.unionAppendListOnTrue(listReverse(eq2), outNormalEqs, valueEq);
          outInitialEqs := List.unionAppendListOnTrue(listReverse(ieq2), outInitialEqs, valueEq);
          outNormalAlgs := List.unionAppendListOnTrue(listReverse(alg2), outNormalAlgs, valueEq);
          outInitialAlgs := List.unionAppendListOnTrue(listReverse(ialg2), outInitialAlgs, valueEq);

          if not inPartialInst then
            (outCache,   eq1) := fixList(outCache, cenv,   eq1, {ht}, fixEquation);
            (outCache,  ieq1) := fixList(outCache, cenv,  ieq1, {ht}, fixEquation);
            (outCache,  alg1) := fixList(outCache, cenv,  alg1, {ht}, fixAlgorithm);
            (outCache, ialg1) := fixList(outCache, cenv, ialg1, {ht}, fixAlgorithm);
            outNormalEqs := List.unionAppendListOnTrue(listReverse(eq1), outNormalEqs, valueEq);
            outInitialEqs := List.unionAppendListOnTrue(listReverse(ieq1), outInitialEqs, valueEq);
            outNormalAlgs := List.unionAppendListOnTrue(listReverse(alg1), outNormalAlgs, valueEq);
            outInitialAlgs := List.unionAppendListOnTrue(listReverse(ialg1), outInitialAlgs, valueEq);
          end if;

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
        cmod = if valueEq(cmod, DAE.NOMOD()) then mod else cmod;
      then
        ((el, cmod, b), inMod);

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
  input HashTableStringToPath.HashTable inHt;
  input getIdentFn getIdent;
  output HashTableStringToPath.HashTable outHt = inHt;

  replaceable type Type_A subtypeof Any;
  partial function getIdentFn
    input Type_A inA;
    input HashTableStringToPath.HashTable inHt;
    output HashTableStringToPath.HashTable outHt;
  end getIdentFn;
algorithm
  for elt in ielts loop
    outHt := getIdent(elt, outHt);
  end for;
end getLocalIdentList;

protected function getLocalIdentElementTpl
" Analyzes the elements of a class and fetches a list of components and classdefs,
  as well as aliases from imports to paths.
"
  input tuple<SCode.Element,DAE.Mod,Boolean> eltTpl;
  input HashTableStringToPath.HashTable ht;
  output HashTableStringToPath.HashTable outHt;
protected
  SCode.Element elt;
algorithm
  (elt, _, _) := eltTpl;
  outHt := getLocalIdentElement(elt, ht);
end getLocalIdentElementTpl;

protected function getLocalIdentElement
" Analyzes an element of a class and fetches a list of components and classdefs,
  as well as aliases from imports to paths."
  input SCode.Element elt;
  input HashTableStringToPath.HashTable inHt;
  output HashTableStringToPath.HashTable outHt;
algorithm
  (outHt) := matchcontinue elt
    local
      String id;
      Absyn.Path p;

    case SCode.COMPONENT(name = id)
      then BaseHashTable.add((id,Absyn.IDENT(id)), inHt);

    case SCode.CLASS(name = id)
      then BaseHashTable.add((id,Absyn.IDENT(id)), inHt);

    case SCode.IMPORT(imp = Absyn.NAMED_IMPORT(name = id, path = p))
      then BaseHashTable.addUnique((id, p), inHt);

    case SCode.IMPORT(imp = Absyn.QUAL_IMPORT(path = p))
      then BaseHashTable.addUnique((Absyn.pathLastIdent(p), p), inHt);

    // adrpo: 2010-10-07 handle unqualified imports!!! TODO! FIXME! should we just ignore them??
    //                   this fixes bug: #1234 https://openmodelica.org:8443/cb/issue/1234
    case SCode.IMPORT(imp = Absyn.UNQUAL_IMPORT(path = p))
      then BaseHashTable.addUnique((Absyn.pathLastIdent(p), p), inHt);

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
  input list<HashTableStringToPath.HashTable> inHt;
  output FCore.Cache outCache = inCache;
  output list<tuple<SCode.Element,DAE.Mod,Boolean>> outElts = {};
protected
  SCode.Element elt;
  DAE.Mod mod;
  Boolean b;
algorithm
  if listEmpty(inElts) then
    return;
  end if;

  for e in inElts loop
    (elt, mod, b) := e;
    (outCache, elt) := fixElement(outCache, inEnv, elt, inHt);
    outElts := (elt, mod, true) :: outElts;
  end for;

  outElts := listReverse(outElts);
end fixLocalIdents;

protected function fixElement
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.Element inElt;
  input list<HashTableStringToPath.HashTable> inHt;
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
      Absyn.IsField isf;
      FCore.Cache cache;
      FCore.Graph env;
      list<HashTableStringToPath.HashTable> ht;
      SCode.Element elt;

    case (cache,env,SCode.COMPONENT(name, prefixes as SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(_)),
                                    SCode.ATTR(ad, ct, prl, var, dir, isf), typeSpec, modifications, comment, condition, info),ht)
      equation
        //fprintln(Flags.DEBUG,"fix comp " + SCodeDump.unparseElementStr(elt,SCodeDump.defaultOptions));
        // lookup as it might have been redeclared!!!
        (_, _, SCode.COMPONENT(name, prefixes, SCode.ATTR(ad, ct, prl, var, dir), typeSpec, modifications, comment, condition, info),
         _, _, _) = Lookup.lookupIdentLocal(cache, env, name);
        (cache,modifications) = fixModifications(cache,env,modifications,ht);
        (cache,typeSpec) = fixTypeSpec(cache,env,typeSpec,ht);
        (cache,SOME(ad)) = fixArrayDim(cache, env, SOME(ad), ht);
      then
        (cache,SCode.COMPONENT(name, prefixes, SCode.ATTR(ad, ct, prl, var, dir, isf), typeSpec, modifications, comment, condition, info));

    // we failed above
    case (cache,env,SCode.COMPONENT(name, prefixes, SCode.ATTR(ad, ct, prl, var, dir, isf), typeSpec, modifications, comment, condition, info),ht)
      equation
        //fprintln(Flags.DEBUG,"fix comp " + SCodeDump.unparseElementStr(elt,SCodeDump.defaultOptions));
        (cache,modifications) = fixModifications(cache,env,modifications,ht);
        (cache,typeSpec) = fixTypeSpec(cache,env,typeSpec,ht);
        (cache,SOME(ad)) = fixArrayDim(cache, env, SOME(ad), ht);
      then
        (cache,SCode.COMPONENT(name, prefixes, SCode.ATTR(ad, ct, prl, var, dir, isf), typeSpec, modifications, comment, condition, info));

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
  input list<HashTableStringToPath.HashTable> inHt;
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
      list<HashTableStringToPath.HashTable> ht;
      HashTableStringToPath.HashTable cls_ht;
      SCode.ClassDef cd;

    case (cache,env,SCode.PARTS(elts,ne,ie,na,ia,nc,clats,ed),ht)
      algorithm
        if not listEmpty(elts) then
          cls_ht := HashTableStringToPath.emptyHashTableSized(Util.nextPrime(listLength(elts)));
          cls_ht := getLocalIdentList(elts, cls_ht, getLocalIdentElement);
          ht := cls_ht :: ht;
        end if;

        (cache,elts) := fixList(cache,env,elts,ht,fixElement);
        (cache,ne) := fixList(cache,env,ne,ht,fixEquation);
        (cache,ie) := fixList(cache,env,ie,ht,fixEquation);
        (cache,na) := fixList(cache,env,na,ht,fixAlgorithm);
        (cache,ia) := fixList(cache,env,ia,ht,fixAlgorithm);
        (cache,nc) := fixList(cache,env,nc,ht,fixConstraint);
      then (cache,SCode.PARTS(elts,ne,ie,na,ia,nc,clats,ed));

    case (cache,env,SCode.CLASS_EXTENDS(name,mod,SCode.PARTS(elts,ne,ie,na,ia,nc,clats,ed)),ht)
      equation
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
  input list<HashTableStringToPath.HashTable> inHt;
  output FCore.Cache outCache;
  output SCode.Equation outEq;
algorithm
  (outCache,outEq) := match inEq
    local
      SCode.EEquation eeq;

    case SCode.EQUATION(eeq)
      algorithm
        (outCache, eeq) := fixEEquation(inCache, inEnv, eeq, inHt);
      then
        (outCache, SCode.EQUATION(eeq));

    case SCode.EQUATION(eeq)
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
  input list<HashTableStringToPath.HashTable> inHt;
  output FCore.Cache outCache = inCache;
  output SCode.EEquation outEeq;
algorithm
  (outCache,outEeq) := match inEeq
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
        (outCache,expl) = fixList(outCache,inEnv,expl,inHt,fixExp);
        (outCache,eqll) = fixListList(outCache,inEnv,eqll,inHt,fixEEquation);
        (outCache,eql) = fixList(outCache,inEnv,eql,inHt,fixEEquation);
      then (outCache,SCode.EQ_IF(expl,eqll,eql,comment,info));
    case SCode.EQ_EQUALS(exp1,exp2,comment,info)
      equation
        (outCache,exp1) = fixExp(outCache,inEnv,exp1,inHt);
        (outCache,exp2) = fixExp(outCache,inEnv,exp2,inHt);
      then (outCache,SCode.EQ_EQUALS(exp1,exp2,comment,info));
    case SCode.EQ_PDE(exp1,exp2,cref,comment,info)
      equation
        (outCache,exp1) = fixExp(outCache,inEnv,exp1,inHt);
        (outCache,exp2) = fixExp(outCache,inEnv,exp2,inHt);
        (outCache,cref) = fixCref(outCache,inEnv,cref,inHt);
      then (outCache,SCode.EQ_PDE(exp1,exp2,cref,comment,info));
    case SCode.EQ_CONNECT(cref1,cref2,comment,info)
      equation
        (outCache,cref1) = fixCref(outCache,inEnv,cref1,inHt);
        (outCache,cref2) = fixCref(outCache,inEnv,cref2,inHt);
      then (outCache,SCode.EQ_CONNECT(cref1,cref2,comment,info));
    case SCode.EQ_FOR(id,optExp,eql,comment,info)
      equation
        (outCache,optExp) = fixOption(outCache,inEnv,optExp,inHt,fixExp);
        (outCache,eql) = fixList(outCache,inEnv,eql,inHt,fixEEquation);
      then (outCache,SCode.EQ_FOR(id,optExp,eql,comment,info));
    case SCode.EQ_WHEN(exp,eql,whenlst,comment,info)
      equation
        (outCache,exp) = fixExp(outCache,inEnv,exp,inHt);
        (outCache,eql) = fixList(outCache,inEnv,eql,inHt,fixEEquation);
        (outCache,whenlst) = fixListTuple2(outCache,inEnv,whenlst,inHt,fixExp,fixListEEquation);
      then (outCache,SCode.EQ_WHEN(exp,eql,whenlst,comment,info));
    case SCode.EQ_ASSERT(exp1,exp2,exp3,comment,info)
      equation
        (outCache,exp1) = fixExp(outCache,inEnv,exp1,inHt);
        (outCache,exp2) = fixExp(outCache,inEnv,exp2,inHt);
        (outCache,exp3) = fixExp(outCache,inEnv,exp3,inHt);
      then (outCache,SCode.EQ_ASSERT(exp1,exp2,exp3,comment,info));
    case SCode.EQ_TERMINATE(exp,comment,info)
      equation
        (outCache,exp) = fixExp(outCache,inEnv,exp,inHt);
      then (outCache,SCode.EQ_TERMINATE(exp,comment,info));
    case SCode.EQ_REINIT(cref,exp,comment,info)
      equation
        (outCache,cref) = fixCref(outCache,inEnv,cref,inHt);
        (outCache,exp) = fixExp(outCache,inEnv,exp,inHt);
      then (outCache,SCode.EQ_REINIT(cref,exp,comment,info));
    case SCode.EQ_NORETCALL(exp,comment,info)
      equation
        (outCache,exp) = fixExp(outCache,inEnv,exp,inHt);
      then (outCache,SCode.EQ_NORETCALL(exp,comment,info));
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
  input list<HashTableStringToPath.HashTable> ht;
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
  input list<HashTableStringToPath.HashTable> inHt;
  output FCore.Cache outCache;
  output SCode.AlgorithmSection outAlg;
protected
  list<SCode.Statement> stmts;
algorithm
  SCode.ALGORITHM(stmts) := inAlg;
  (outCache, stmts) := fixList(inCache, inEnv, stmts, inHt, fixStatement);
  outAlg := SCode.ALGORITHM(stmts);
end fixAlgorithm;

protected function fixConstraint
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.ConstraintSection inConstrs;
  input list<HashTableStringToPath.HashTable> inHt;
  output FCore.Cache outCache;
  output SCode.ConstraintSection outConstrs;
protected
  list<Absyn.Exp> exps;
algorithm
  SCode.CONSTRAINTS(exps) := inConstrs;
  (outCache, exps) := fixList(inCache, inEnv, exps, inHt, fixExp);
  outConstrs := SCode.CONSTRAINTS(exps);
end fixConstraint;

protected function fixListAlgorithmItem
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input FCore.Cache cache;
  input FCore.Graph env;
  input list<SCode.Statement> alg;
  input list<HashTableStringToPath.HashTable> ht;
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
  input list<HashTableStringToPath.HashTable> inHt;
  output FCore.Cache outCache = inCache;
  output SCode.Statement outStmt;
algorithm
  (outCache,outStmt) := matchcontinue inStmt
    local
      Absyn.Exp exp,exp1,exp2;
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
        (outCache,exp1) = fixExp(outCache,inEnv,exp1,inHt);
        (outCache,exp2) = fixExp(outCache,inEnv,exp2,inHt);
      then (outCache,SCode.ALG_ASSIGN(exp1,exp2,comment,info));

    case SCode.ALG_IF(exp,truebranch,elseifbranch,elsebranch,comment,info)
      equation
        (outCache,exp) = fixExp(outCache,inEnv,exp,inHt);
        (outCache,truebranch) = fixList(outCache,inEnv,truebranch,inHt,fixStatement);
        (outCache,elseifbranch) = fixListTuple2(outCache,inEnv,elseifbranch,inHt,fixExp,fixListAlgorithmItem);
        (outCache,elsebranch) = fixList(outCache,inEnv,elsebranch,inHt,fixStatement);
      then (outCache,SCode.ALG_IF(exp,truebranch,elseifbranch,elsebranch,comment,info));

    case SCode.ALG_FOR(iter,optExp,forbody,comment,info)
      equation
        (outCache,optExp) = fixOption(outCache,inEnv,optExp,inHt,fixExp);
        (outCache,forbody) = fixList(outCache,inEnv,forbody,inHt,fixStatement);
      then (outCache,SCode.ALG_FOR(iter,optExp,forbody,comment,info));

    case SCode.ALG_PARFOR(iter,optExp,forbody,comment,info)
      equation
        (outCache,optExp) = fixOption(outCache,inEnv,optExp,inHt,fixExp);
        (outCache,forbody) = fixList(outCache,inEnv,forbody,inHt,fixStatement);
      then (outCache,SCode.ALG_PARFOR(iter,optExp,forbody,comment,info));

    case SCode.ALG_WHILE(exp,whilebody,comment,info)
      equation
        (outCache,exp) = fixExp(outCache,inEnv,exp,inHt);
        (outCache,_) = fixList(outCache,inEnv,whilebody,inHt,fixStatement);
      then (outCache,SCode.ALG_WHILE(exp,whilebody,comment,info));

    case SCode.ALG_WHEN_A(whenlst,comment,info)
      equation
        (outCache,whenlst) = fixListTuple2(outCache,inEnv,whenlst,inHt,fixExp,fixListAlgorithmItem);
      then (outCache,SCode.ALG_WHEN_A(whenlst,comment,info));

    case SCode.ALG_ASSERT(exp, exp1, exp2, comment, info)
      algorithm
        (outCache, exp) := fixExp(outCache, inEnv, exp, inHt);
        (outCache, exp1) := fixExp(outCache, inEnv, exp1, inHt);
        (outCache, exp2) := fixExp(outCache, inEnv, exp2, inHt);
      then
        (outCache, SCode.ALG_ASSERT(exp, exp1, exp2, comment, info));

    case SCode.ALG_TERMINATE(exp, comment, info)
      algorithm
        (outCache, exp) := fixExp(outCache, inEnv, exp, inHt);
      then
        (outCache, SCode.ALG_TERMINATE(exp, comment, info));

    case SCode.ALG_REINIT(cr, exp, comment, info)
      algorithm
        (outCache, cr) := fixCref(outCache, inEnv, cr, inHt);
        (outCache, exp) := fixExp(outCache, inEnv, exp, inHt);
      then
        (outCache, SCode.ALG_REINIT(cr, exp, comment, info));

    case SCode.ALG_NORETCALL(exp,comment,info)
      equation
        (outCache,exp) = fixExp(outCache,inEnv,exp,inHt);
      then (outCache,SCode.ALG_NORETCALL(exp,comment,info));

    case SCode.ALG_RETURN(comment,info) then (outCache, inStmt);

    case SCode.ALG_BREAK(comment,info) then (outCache, inStmt);

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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Option<Absyn.ArrayDim> inAd;
  input list<HashTableStringToPath.HashTable> inHt;
  output FCore.Cache outCache;
  output Option<Absyn.ArrayDim> outAd;
algorithm
  (outCache,outAd) := match inAd
    local
      list<Absyn.Subscript> ads;

    case NONE() then (inCache,NONE());
    case SOME(ads)
      algorithm
        (outCache, ads) := fixList(inCache, inEnv, ads, inHt, fixSubscript);
      then (outCache,SOME(ads));
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
  input list<HashTableStringToPath.HashTable> inHt;
  output FCore.Cache outCache;
  output Absyn.Subscript outSub;
algorithm
  (outCache,outSub) := match inSub
    local
      Absyn.Exp exp;

    case Absyn.NOSUB() then (inCache,Absyn.NOSUB());
    case Absyn.SUBSCRIPT(exp)
      algorithm
        (outCache, exp) := fixExp(inCache, inEnv, exp, inHt);
      then (outCache, Absyn.SUBSCRIPT(exp));
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
  input list<HashTableStringToPath.HashTable> inHt;
  output FCore.Cache outCache = inCache;
  output Absyn.TypeSpec outTs;
algorithm
  (outCache,outTs) := match inTs
    local
      Absyn.Path path;
      Option<Absyn.ArrayDim> arrayDim;
      list<Absyn.TypeSpec> typeSpecs;

    case Absyn.TPATH(path,arrayDim)
      equation
        (outCache,arrayDim) = fixArrayDim(outCache,inEnv,arrayDim,inHt);
        (outCache,path) = fixPath(outCache,inEnv,path,inHt);
      then (outCache,Absyn.TPATH(path,arrayDim));
    case Absyn.TCOMPLEX(path,typeSpecs,arrayDim)
      equation
        (outCache,arrayDim) = fixArrayDim(outCache,inEnv,arrayDim,inHt);
        (outCache,path) = fixPath(outCache,inEnv,path,inHt);
        (outCache,typeSpecs) = fixList(outCache,inEnv,typeSpecs,inHt,fixTypeSpec);
      then (outCache,Absyn.TCOMPLEX(path,typeSpecs,arrayDim));
  end match;
end fixTypeSpec;

protected function fixPath
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  input list<HashTableStringToPath.HashTable> inHt;
  output FCore.Cache outCache;
  output Absyn.Path outPath;
algorithm
  (outCache,outPath) := matchcontinue inPath
    local
      String id;
      Absyn.Path path2,path;

    case Absyn.FULLYQUALIFIED()
      then (inCache, inPath);

    case _
      equation
        id = Absyn.pathFirstIdent(inPath);
        path2 = lookupName(id, inHt);
        path2 = Absyn.pathReplaceFirstIdent(inPath, path2);
        path2 = FGraph.pathStripGraphScopePrefix(path2, inEnv, false);
        //fprintln(Flags.DEBUG, "Replacing: " + Absyn.pathString(inPath) + " with " + Absyn.pathString(path2) + " s:" + FGraph.printGraphPathStr(inEnv));
      then (inCache, path2);

    // first indent is local in the inEnv, DO NOT QUALIFY!
    case _
      equation
        //fprintln(Flags.DEBUG,"Try makeFullyQualified " + Absyn.pathString(path));
        (_, _) = Lookup.lookupClassLocal(inEnv, Absyn.pathFirstIdent(inPath));
        path = FGraph.pathStripGraphScopePrefix(inPath, inEnv, false);
        //fprintln(Flags.DEBUG,"FullyQual: " + Absyn.pathString(path));
      then (inCache, path);

    case _
      equation
        // isOutside = isPathOutsideScope(cache, inEnv, path);
        //print("Try makeFullyQualified " + Absyn.pathString(path) + "\n");
        (outCache, path) = Inst.makeFullyQualified(inCache, inEnv, inPath);
        // path = if_(isOutside, path, FGraph.pathStripGraphScopePrefix(path, inEnv, false));
        path = FGraph.pathStripGraphScopePrefix(path, inEnv, false);
        //print("FullyQual: " + Absyn.pathString(path) + "\n");
      then (outCache, path);

    else
      equation
        path = FGraph.pathStripGraphScopePrefix(inPath, inEnv, false);
        //fprintln(Flags.DEBUG, "Path not fixed: " + Absyn.pathString(path) + "\n");
      then
        (inCache, path);

  end matchcontinue;
end fixPath;

protected function lookupName
  input String inName;
  input list<HashTableStringToPath.HashTable> inHT;
  output Absyn.Path outPath;
algorithm
  for ht in inHT loop
    try
      outPath := BaseHashTable.get(inName, ht);
      return;
    else
    end try;
  end for;
  fail();
end lookupName;

public function isPathOutsideScope
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  output Boolean yes;
protected
  FCore.Graph env;
algorithm
  try
    // see where the first ident from the path leads, if is outside the current env DO NOT strip!
    (_, _, env) := Lookup.lookupClass(inCache, inEnv, Absyn.makeIdentPathFromString(Absyn.pathFirstIdent(inPath)));
    // if envClass is prefix of env then is outside scope
    yes := FGraph.graphPrefixOf(env, inEnv);
  else
    yes := false;
  end try;
end isPathOutsideScope;

protected function lookupVarNoErrorMessage
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.ComponentRef inComponentRef;
  output FCore.Graph outEnv;
  output String id;
algorithm
  try
    ErrorExt.setCheckpoint("InstExtends.lookupVarNoErrorMessage");
    (_,_,_,_,_,_,outEnv,_,id) := Lookup.lookupVar(inCache, inEnv, inComponentRef);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inCref;
  input list<HashTableStringToPath.HashTable> inHt;
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
      list<HashTableStringToPath.HashTable> ht;
      Absyn.ComponentRef cref;
      SCode.Element c;
      Boolean isOutside;

    case (cache,env,cref,ht)
      equation
        id = Absyn.crefFirstIdent(cref);
        //fprintln(Flags.DEBUG,"Try ht lookup " + id);
        path = lookupName(id, ht);
        //fprintln(Flags.DEBUG,"Got path " + Absyn.pathString(path));
        cref = Absyn.crefReplaceFirstIdent(cref,path);
        cref = FGraph.crefStripGraphScopePrefix(cref, env, false);
        //fprintln(Flags.DEBUG, "Cref HT fixed: " + Absyn.printComponentRefStr(cref));
        cref = if Absyn.crefEqual(cref, inCref) then inCref else cref;
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
        cref = if Absyn.crefEqual(cref, inCref) then inCref else cref;
      then (cache,cref);

    case (cache,env,cref,_)
      equation
        id = Absyn.crefFirstIdent(cref);
        //print("Try lookupC " + id + "\n");
        (_,c,denv) = Lookup.lookupClass(cache,env,Absyn.IDENT(id));
        // isOutside = FGraph.graphPrefixOf(denv, env);
        // id might come from named import, make sure you use the actual class name!
        id = SCode.getElementName(c);
        //fprintln(Flags.DEBUG,"Got env " + intString(listLength(env)));
        denv = FGraph.openScope(denv,SCode.ENCAPSULATED(),SOME(id),NONE());
        cref = Absyn.crefReplaceFirstIdent(cref,FGraph.getGraphName(denv));
        // cref = if_(isOutside, cref, FGraph.crefStripGraphScopePrefix(cref, env, false));
        cref = FGraph.crefStripGraphScopePrefix(cref, env, false);
        //print("Cref CLASS fixed: " + Absyn.printComponentRefStr(cref) + "\n");
        cref = if Absyn.crefEqual(cref, inCref) then inCref else cref;
      then (cache,cref);

    else (inCache, inCref);

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
  input list<HashTableStringToPath.HashTable> inHT;
  output FCore.Cache outCache;
  output SCode.Mod outMod = inMod;
algorithm
  (outCache, outMod) := matchcontinue outMod
    local
      list<SCode.SubMod> subModLst;
      Absyn.Exp exp;
      SCode.Element e;
      SCode.ClassDef cdef;

    case SCode.NOMOD() then (inCache, inMod);

    case SCode.MOD()
      algorithm
        (outCache, subModLst) := fixSubModList(inCache, inEnv, outMod.subModLst, inHT);
        outMod.subModLst := subModLst;

        if isSome(outMod.binding) then
          SOME(exp) := outMod.binding;
          (outCache, exp) := fixExp(outCache, inEnv, exp, inHT);
          outMod.binding := SOME(exp);
        end if;
      then
        (outCache, outMod);

    case SCode.REDECL(element = SCode.COMPONENT())
      algorithm
        (outCache, e) := fixElement(inCache, inEnv, outMod.element, inHT);
        outMod.element := e;
      then
        (outCache, outMod);

    case SCode.REDECL(element = e as SCode.CLASS(classDef = cdef))
      algorithm
        (outCache, cdef) := fixClassdef(inCache, inEnv, cdef, inHT);
        e.classDef := cdef;
        outMod.element := e;
      then
        (outCache, outMod);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("InstExtends.fixModifications failed: " + SCodeDump.printModStr(inMod));
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
  input list<HashTableStringToPath.HashTable> inHt;
  output FCore.Cache outCache = inCache;
  output list<SCode.SubMod> outSubMods = {};
protected
  Absyn.Ident ident;
  SCode.Mod mod;
algorithm
  for sm in inSubMods loop
    SCode.NAMEMOD(ident, mod) := sm;
    (outCache, mod) := fixModifications(outCache, inEnv, mod, inHt);
    outSubMods := SCode.NAMEMOD(ident, mod) :: outSubMods;
  end for;

  outSubMods := listReverse(outSubMods);
end fixSubModList;

protected function fixExp
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input list<HashTableStringToPath.HashTable> inHt;
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
  input tuple<FCore.Cache,FCore.Graph,list<HashTableStringToPath.HashTable>> inTpl;
  output Absyn.Exp outExp;
  output tuple<FCore.Cache,FCore.Graph,list<HashTableStringToPath.HashTable>> outTpl;
algorithm
  (outExp,outTpl) := match (inExp,inTpl)
    local
      Absyn.FunctionArgs fargs;
      Absyn.ComponentRef cref, cref1;
      Absyn.Path path;
      FCore.Cache cache;
      FCore.Graph env;
      list<HashTableStringToPath.HashTable> ht;

    case (Absyn.CREF(cref),(cache,env,ht))
      equation
        (cache,cref1) = fixCref(cache,env,cref,ht);
      then (if referenceEq(cref, cref1) then inExp else Absyn.CREF(cref1),(cache,env,ht));

    case (Absyn.CALL(cref,fargs),(cache,env,ht))
      equation
        // print("cref actual: " + Absyn.crefString(cref) + " scope: " + FGraph.printGraphPathStr(env) + "\n");
        (cache,cref1) = fixCref(cache,env,cref,ht);
        // print("cref fixed : " + Absyn.crefString(cref) + "\n");
      then (if referenceEq(cref, cref1) then inExp else Absyn.CALL(cref1,fargs),(cache,env,ht));

    case (Absyn.PARTEVALFUNCTION(cref,fargs),(cache,env,ht))
      equation
        (cache,cref1) = fixCref(cache,env,cref,ht);
      then (if referenceEq(cref, cref1) then inExp else Absyn.PARTEVALFUNCTION(cref1,fargs),(cache,env,ht));

    else (inExp,inTpl);
  end match;
end fixExpTraverse;

protected function fixOption<Type_A>
" Generic function to fix an optional element."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Option<Type_A> inA;
  input list<HashTableStringToPath.HashTable> inHt;
  input FixAFn fixA;
  output FCore.Cache outCache;
  output Option<Type_A> outA;

  partial function FixAFn
    input FCore.Cache inCache;
    input FCore.Graph inEnv;
    input Type_A inA;
    input list<HashTableStringToPath.HashTable> inHt;
    output FCore.Cache outCache;
    output Type_A outTypeA;
  end FixAFn;
algorithm
  (outCache,outA) := match inA
    local
      Type_A A;

    case NONE() then (inCache, NONE());
    case SOME(A)
      equation
        (outCache, A) = fixA(inCache, inEnv, A, inHt);
      then (outCache, SOME(A));
  end match;
end fixOption;

protected function fixList<Type_A>
" Generic function to fix a list of elements."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Type_A> inA;
  input list<HashTableStringToPath.HashTable> inHt;
  input FixAFn fixA;
  output FCore.Cache outCache = inCache;
  output list<Type_A> outA = {};

  partial function FixAFn
    input FCore.Cache inCache;
    input FCore.Graph inEnv;
    input Type_A inA;
    input list<HashTableStringToPath.HashTable> inHt;
    output FCore.Cache outCache;
    output Type_A outTypeA;
  end FixAFn;
algorithm
  for a in inA loop
    (outCache, a) := fixA(outCache, inEnv, a, inHt);
    outA := a :: outA;
  end for;

  outA := listReverse(outA);
end fixList;

protected function fixListList<Type_A>
" Generic function to fix a list of elements."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<list<Type_A>> inA;
  input list<HashTableStringToPath.HashTable> inHt;
  input FixAFn fixA;
  output FCore.Cache outCache = inCache;
  output list<list<Type_A>> outA = {};

  partial function FixAFn
    input FCore.Cache inCache;
    input FCore.Graph inEnv;
    input Type_A inA;
    input list<HashTableStringToPath.HashTable> inHt;
    output FCore.Cache outCache;
    output Type_A outTypeA;
  end FixAFn;
algorithm
  for a in inA loop
    (outCache, a) := fixList(outCache, inEnv, a, inHt, fixA);
    outA := a :: outA;
  end for;

  outA := listReverse(outA);
end fixListList;

protected function fixListTuple2<Type_A, Type_B>
" Generic function to fix a list of elements."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<tuple<Type_A,Type_B>> inRest;
  input list<HashTableStringToPath.HashTable> inHt;
  input FixAFn fixA;
  input FixBFn fixB;
  output FCore.Cache outCache = inCache;
  output list<tuple<Type_A,Type_B>> outA = {};

  partial function FixAFn
    input FCore.Cache inCache;
    input FCore.Graph inEnv;
    input Type_A inA;
    input list<HashTableStringToPath.HashTable> inHt;
    output FCore.Cache outCache;
    output Type_A outLst;
  end FixAFn;
  partial function FixBFn
    input FCore.Cache inCache;
    input FCore.Graph inEnv;
    input Type_B inA;
    input list<HashTableStringToPath.HashTable> inHt;
    output FCore.Cache outCache;
    output Type_B outTypeA;
  end FixBFn;
protected
  Type_A a;
  Type_B b;
algorithm
  for t in inRest loop
    (a, b) := t;
    (outCache, a) := fixA(outCache, inEnv, a, inHt);
    (outCache, b) := fixB(outCache, inEnv, b, inHt);
    outA := (a, b) :: outA;
  end for;

  outA := listReverse(outA);
end fixListTuple2;

annotation(__OpenModelica_Interface="frontend");
end InstExtends;
