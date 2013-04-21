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
public import Env;
public import HashTableStringToPath;
public import InnerOuter;
public import SCode;
public import Prefix;

// protected imports
protected import BaseHashTable;
protected import Builtin;
protected import ComponentReference;
protected import Debug;
protected import Dump;
protected import Error;
protected import Flags;
protected import Inst;
protected import List;
protected import Lookup;
protected import Mod;
protected import Util;
protected import SCodeDump;
protected import ErrorExt;
protected import SCodeUtil;
//protected import System;

public type InstanceHierarchy = InnerOuter.InstHierarchy "an instance hierarchy";

protected function instExtendsList "
  author: PA
  This function flattens out the inheritance structure of a class.
  It takes an SCode.Element list and flattens out the extends nodes
  of that list. The result is a list of components and lists of equations
  and algorithms."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input list<SCode.Element> inSCodeElementLst;
  input ClassInf.State inState;
  input String inClassName; // the class name whose elements are getting instantiated.
  input Boolean inImplicit;
  input Boolean isPartialInst;
  output Env.Cache outCache;
  output Env.Env outEnv1;
  output InstanceHierarchy outIH;
  output DAE.Mod outMod2;
  output list<tuple<SCode.Element, DAE.Mod, Boolean>> outTplSCodeElementModLst3;
  output list<SCode.Equation> outSCodeEquationLst4;
  output list<SCode.Equation> outSCodeEquationLst5;
  output list<SCode.AlgorithmSection> outSCodeAlgorithmLst6;
  output list<SCode.AlgorithmSection> outSCodeAlgorithmLst7;
algorithm
  (outCache,outEnv1,outIH,outMod2,outTplSCodeElementModLst3,outSCodeEquationLst4,outSCodeEquationLst5,outSCodeAlgorithmLst6,outSCodeAlgorithmLst7):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSCodeElementLst,inState,inClassName,inImplicit,isPartialInst)
    local
      SCode.Element c;
      String cn,s,scope_str,className;
      SCode.Encapsulated encf;
      Boolean impl,notConst;
      SCode.Restriction r;
      list<Env.Frame> cenv,cenv1,cenv3,env2,env,env_1;
      DAE.Mod outermod,mods,mods_1,emod_1,mod;
      list<SCode.Element> importelts,els,els_1,rest,cdefelts,classextendselts;
      list<SCode.Equation> eq1,ieq1,eq1_1,ieq1_1,eq2,ieq2,eq3,ieq3,eq,ieq,initeq2;
      list<SCode.AlgorithmSection> alg1,ialg1,alg1_1,ialg1_1,alg2,ialg2,alg3,ialg3,alg,ialg;
      Absyn.Path tp_1,tp;
      ClassInf.State new_ci_state,ci_state;
      list<tuple<SCode.Element, DAE.Mod, Boolean>> compelts1,compelts2,compelts,compelts3;
      SCode.Mod emod;
      SCode.Element elt;
      Env.Cache cache;
      InstanceHierarchy ih;
      HashTableStringToPath.HashTable ht;
      SCode.Variability var;
      Prefix.Prefix pre;
      SCode.Mod scodeMod;
      SCode.Final finalPrefix;
      Absyn.Info info;
      Option<SCode.Comment> cmt;
      SCode.Visibility vis;

    /* no further elements to instantiate */
    case (cache,env,ih,mod,pre,{},ci_state,className,impl,_) then (cache,env,ih,mod,{},{},{},{},{});

    /* instantiate a base class */
    case (cache,env,ih,mod,pre,(elt as SCode.EXTENDS(info = info, baseClassPath = tp, modifications = emod, visibility = vis)) :: rest,ci_state,className,impl,_)
      equation
        // Debug.fprintln(Flags.INST_TRACE, "EXTENDS: " +& Env.printEnvPathStr(env) +& " el: " +& SCodeDump.unparseElementStr(elt) +& " mods: " +& Mod.printModStr(mod));
        //print("EXTENDS: " +& Env.printEnvPathStr(env) +& "/" +& Absyn.pathString(tp) +& "(" +& SCodeDump.printModStr(emod) +& ") outemod: " +& Mod.printModStr(mod) +& "\n");
        // adrpo - here we need to check if we don't have recursive extends of the form:
        // package Icons
        //   extends Icons.BaseLibrary;
        //        model BaseLibrary "Icon for base library"
        //        end BaseLibrary;
        // end Icons;
        // if we don't check that, then the compiler enters an infinite loop!
        // what we do is removing Icons from extends Icons.BaseLibrary;
        tp = Inst.removeSelfReference(className, tp);
        //print(className +& "\n");
        //print("Type: " +& Absyn.pathString(tp) +& "(" +& SCodeDump.printModStr(emod) +& ")\n");

        emod = Inst.chainRedeclares(mod, emod);

        // fully qualify modifiers in extends in this environment!
        (cache, emod) = fixModifications(cache, env, emod, HashTableStringToPath.emptyHashTable());

        // Debug.fprintln(Flags.INST_TRACE, "EXTENDS (FULLY QUAL): " +& Env.printEnvPathStr(env) +& " el: " +& SCodeDump.printModStr(emod));

        (cache,(c as SCode.CLASS(name=cn,encapsulatedPrefix=encf,restriction=r)),cenv) = Lookup.lookupClass(cache, env, tp, false);

        //print("Found " +& cn +& "\n");
        // outermod = Mod.lookupModificationP(mod, Absyn.IDENT(cn));
        outermod = mod;

        (cache,cenv1,ih,els,eq1,ieq1,alg1,ialg1) = instDerivedClasses(cache,cenv,ih,outermod,pre,c,impl,info);
        els = updateElementListVisibility(els, vis);

        (cache,tp_1) = Inst.makeFullyQualified(cache,/* adrpo: cenv1?? FIXME */env, tp);

        eq1_1 = Util.if_(isPartialInst, {}, eq1);
        ieq1_1 = Util.if_(isPartialInst, {}, ieq1);
        alg1_1 = Util.if_(isPartialInst, {}, alg1);
        ialg1_1 = Util.if_(isPartialInst, {}, ialg1);

        cenv3 = Env.openScope(cenv1, encf, SOME(cn), Env.classInfToScopeType(ci_state));
        new_ci_state = ClassInf.start(r, Env.getEnvName(cenv3));
        /* Add classdefs and imports to env, so e.g. imports from baseclasses found, see Extends5.mo */
        (importelts,cdefelts,classextendselts,els_1) = Inst.splitEltsNoComponents(els);
        (cenv3,ih) = Inst.addClassdefsToEnv(cenv3,ih,pre,importelts,impl,NONE());
        (cenv3,ih) = Inst.addClassdefsToEnv(cenv3,ih,pre,cdefelts,impl,SOME(mod));

        els_1 = SCodeUtil.addRedeclareAsElementsToExtends(els_1, SCodeUtil.getRedeclareAsElements(els_1));

        (cache,_,ih,mods,compelts1,eq2,ieq2,alg2,ialg2) = instExtendsAndClassExtendsList2(cache,cenv3,ih,outermod,pre,els_1,classextendselts,ci_state,className,impl,isPartialInst)
        "recurse to fully flatten extends elements env";

        ht = getLocalIdentList(compelts1,HashTableStringToPath.emptyHashTable(),getLocalIdentElementTpl);
        ht = getLocalIdentList(cdefelts,ht,getLocalIdentElement);
        ht = getLocalIdentList(importelts,ht,getLocalIdentElement);

        //tmp = tick(); Debug.traceln("try fix local idents " +& intString(tmp));
        (cache,compelts1) = fixLocalIdents(cache, cenv3, compelts1, ht);
        (cache,eq1_1) = fixList(cache, cenv3, eq1_1, ht,fixEquation);
        (cache,ieq1_1) = fixList(cache, cenv3, ieq1_1, ht,fixEquation);
        (cache,alg1_1) = fixList(cache, cenv3, alg1_1, ht,fixAlgorithm);
        (cache,ialg1_1) = fixList(cache, cenv3, ialg1_1, ht,fixAlgorithm);
        //Debug.traceln("fixed local idents " +& intString(tmp));

        (cache,env2,ih,mods_1,compelts2,eq3,ieq3,alg3,ialg3) = instExtendsList(cache,env,ih,mod,pre,rest,ci_state,className,impl,isPartialInst)
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

        (compelts3,mods_1) = updateComponentsAndClassdefs(compelts, mods_1, env2) "update components with new merged modifiers";
        eq = List.unionOnTrueList({eq1_1,eq2,eq3},Util.equal);
        ieq = List.unionOnTrueList({ieq1_1,ieq2,ieq3},Util.equal);
        alg = List.unionOnTrueList({alg1_1,alg2,alg3},Util.equal);
        ialg = List.unionOnTrueList({ialg1_1,ialg2,ialg3},Util.equal);
      then
        (cache,env2,ih,mods_1,compelts3,eq,ieq,alg,ialg);

    // base class was not found
    case (cache,env,ih,mod,pre,(SCode.EXTENDS(info = info, baseClassPath = tp,modifications = emod) :: rest),ci_state,className,impl,_)
      equation
        failure((_,c,cenv) = Lookup.lookupClass(cache, env, tp, false));
        s = Absyn.pathString(tp);
        scope_str = Env.printEnvPathStr(env);
        Error.addSourceMessage(Error.LOOKUP_BASECLASS_ERROR, {s,scope_str}, info);
      then
        fail();

    // Extending a component means copying it. It might fail above, try again
    case (cache,env,ih,mod,pre,
         (elt as SCode.COMPONENT(name = s, attributes =
          SCode.ATTR(variability = var),
          modifications = scodeMod,
          prefixes = SCode.PREFIXES(finalPrefix=finalPrefix),
          comment = cmt)) :: rest,
          ci_state,className,impl,_)
      equation
        (cache,env_1,ih,mods,compelts2,eq2,initeq2,alg2,ialg2) =
        instExtendsList(cache, env, ih, mod, pre, rest, ci_state, className, impl, isPartialInst);
        // Filter out non-constants or parameters if partial inst
        notConst = not SCode.isConstant(var); // not (SCode.isConstant(var) or SCode.getEvaluateAnnotation(cmt));
        // we should always add it as the class that variable represents might contain constants!
        compelts2 = Util.if_(notConst and isPartialInst,compelts2,(elt,DAE.NOMOD(),false)::compelts2);
      then
        (cache,env_1,ih,mods,compelts2,eq2,initeq2,alg2,ialg2);

    // Classdefs
    case (cache,env,ih,mod,pre,(elt as SCode.CLASS(name = cn)) :: rest,
          ci_state,className,impl,_)
      equation
        (cache,env_1,ih,mods,compelts2,eq2,initeq2,alg2,ialg2) =
        instExtendsList(cache, env, ih, mod, pre, rest, ci_state, className, impl, isPartialInst);
      then
        (cache,env_1,ih,mods,((elt,DAE.NOMOD(),false) :: compelts2),eq2,initeq2,alg2,ialg2);

    /* instantiate elements that are not extends */
    case (cache,env,ih,mod,pre,(elt as SCode.IMPORT(imp = _)) :: rest,ci_state,className,impl,_)
      equation
        (cache,env_1,ih,mods,compelts2,eq2,initeq2,alg2,ialg2) =
        instExtendsList(cache,env,ih, mod, pre, rest, ci_state, className, impl, isPartialInst);
      then
        (cache,env_1,ih,mods,((elt,DAE.NOMOD(),false) :: compelts2),eq2,initeq2,alg2,ialg2);

    /* instantiation failed */
    case (cache,env,ih,mod,pre,rest,ci_state,className,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Inst.instExtendsList failed on:\n\t" +&
          "className: " +&  className +& "\n\t" +&
          "env:       " +&  Env.printEnvPathStr(env) +& "\n\t" +&
          "mods:      " +&  Mod.printModStr(mod) +& "\n\t" +&
          "elems:     " +&  stringDelimitList(List.map(rest, SCodeDump.printElementStr), ", ")
          );
      then
        fail();
  end matchcontinue;
end instExtendsList;

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
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input list<SCode.Element> inExtendsElementLst;
  input list<SCode.Element> inClassExtendsElementLst;
  input ClassInf.State inState;
  input String inClassName; // the class name whose elements are getting instantiated.
  input Boolean inImpl;
  input Boolean isPartialInst;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.Mod outMod;
  output list<tuple<SCode.Element, DAE.Mod>> outTplSCodeElementModLst;
  output list<SCode.Equation> outSCodeNormalEquationLst;
  output list<SCode.Equation> outSCodeInitialEquationLst;
  output list<SCode.AlgorithmSection> outSCodeNormalAlgorithmLst;
  output list<SCode.AlgorithmSection> outSCodeInitialAlgorithmLst;
protected
  list<tuple<SCode.Element, DAE.Mod, Boolean>> outTplSCodeElementModLstTpl3;
  list<SCode.Element> cdefelts,tmpelts;
algorithm
  //Debug.fprintln(Flags.DEBUG,"instExtendsAndClassExtendsList: " +& inClassName);
  (outCache,outEnv,outIH,outMod,outTplSCodeElementModLstTpl3,outSCodeNormalEquationLst,outSCodeInitialEquationLst,outSCodeNormalAlgorithmLst,outSCodeInitialAlgorithmLst):=
  instExtendsAndClassExtendsList2(inCache,inEnv,inIH,inMod,inPrefix,inExtendsElementLst,inClassExtendsElementLst,inState,inClassName,inImpl,isPartialInst);
  // Filter out the last boolean in the tuple
  outTplSCodeElementModLst := List.map(outTplSCodeElementModLstTpl3, Util.tuple312);
  // Create a list of the class definitions, since these can't be properly added in the recursive call
  tmpelts := List.map(outTplSCodeElementModLst,Util.tuple21);
  (_,cdefelts,_,_) := Inst.splitEltsNoComponents(tmpelts);
  // Add the class definitions to the environment
  (outEnv,outIH) := Inst.addClassdefsToEnv(outEnv,outIH,inPrefix,cdefelts,inImpl,SOME(outMod));
  //Debug.fprintln(Flags.DEBUG,"instExtendsAndClassExtendsList: " +& inClassName +& " done");
end instExtendsAndClassExtendsList;

protected function instExtendsAndClassExtendsList2 "
  This function flattens out the inheritance structure of a class.
  It takes an SCode.Element list and flattens out the extends nodes and
  class extends nodes of that list. The result is a list of components and
  lists of equations and algorithms."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input list<SCode.Element> inExtendsElementLst;
  input list<SCode.Element> inClassExtendsElementLst;
  input ClassInf.State inState;
  input String inClassName; // the class name whose elements are getting instantiated.
  input Boolean inImpl;
  input Boolean isPartialInst;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.Mod outMod;
  output list<tuple<SCode.Element, DAE.Mod, Boolean>> outTplSCodeElementModLst;
  output list<SCode.Equation> outSCodeNormalEquationLst;
  output list<SCode.Equation> outSCodeInitialEquationLst;
  output list<SCode.AlgorithmSection> outSCodeNormalAlgorithmLst;
  output list<SCode.AlgorithmSection> outSCodeInitialAlgorithmLst;
algorithm
  (outCache,outEnv,outIH,outMod,outTplSCodeElementModLst,outSCodeNormalEquationLst,outSCodeInitialEquationLst,outSCodeNormalAlgorithmLst,outSCodeInitialAlgorithmLst):=
  instExtendsList(inCache,inEnv,inIH,inMod,inPrefix,inExtendsElementLst,inState,inClassName,inImpl,isPartialInst);
  (outMod,outTplSCodeElementModLst):=instClassExtendsList(inEnv,outMod,inClassExtendsElementLst,outTplSCodeElementModLst);
end instExtendsAndClassExtendsList2;

protected function instClassExtendsList
"Instantiate element nodes of type SCode.CLASS_EXTENDS. This is done by walking
the extended classes and performing the modifications in-place. The old class
will no longer be accessible."
  input Env.Env inEnv;
  input DAE.Mod inMod;
  input list<SCode.Element> inClassExtendsList;
  input list<tuple<SCode.Element, DAE.Mod, Boolean>> inTplSCodeElementModLst;
  output DAE.Mod outMod;
  output list<tuple<SCode.Element, DAE.Mod, Boolean>> outTplSCodeElementModLst;
algorithm
  (outMod,outTplSCodeElementModLst) := matchcontinue (inEnv,inMod,inClassExtendsList,inTplSCodeElementModLst)
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

    case (_,_,SCode.CLASS(name=name)::rest,compelts)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Inst.instClassExtendsList failed " +& name);
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
        cn = "$parent" +& "." +& cn +& ".$env." +& ep;
      then
        cn;
  end match;
end buildClassExtendsName;

protected function instClassExtendsList2
  input Env.Env inEnv;
  input DAE.Mod inMod;
  input String inName;
  input SCode.Element inClassExtendsElt;
  input list<tuple<SCode.Element, DAE.Mod, Boolean>> inTplSCodeElementModLst;
  output DAE.Mod outMod;
  output list<tuple<SCode.Element, DAE.Mod, Boolean>> outTplSCodeElementModLst;
algorithm
  (outMod,outTplSCodeElementModLst) := matchcontinue (inEnv,inMod,inName,inClassExtendsElt,inTplSCodeElementModLst)
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
      Option<SCode.Comment> comment1,comment2;
      list<SCode.Element> els1,els2;
      list<SCode.Equation> nEqn1,nEqn2,inEqn1,inEqn2;
      list<SCode.AlgorithmSection> nAlg1,nAlg2,inAlg1,inAlg2;
      list<SCode.ConstraintSection> inCons1, inCons2;
      list<Absyn.NamedArg> clats;
      list<tuple<SCode.Element, DAE.Mod, Boolean>> rest;
      tuple<SCode.Element, DAE.Mod, Boolean> first;
      SCode.Mod mods;
      DAE.Mod mod1,emod;
      Absyn.Info info1, info2;
      Boolean b;

    case (_,emod,name1,classExtendsElt,(cl as SCode.CLASS(name = name2),mod1,b)::rest)
      equation
        true = name1 ==& name2; // Compare the name before pattern-matching to speed this up

        env_path = Absyn.pathString(Env.getEnvName(inEnv));
        name2 = buildClassExtendsName(env_path,name2);
        SCode.CLASS(_,prefixes2,encapsulatedPrefix2,partialPrefix2,restriction2,SCode.PARTS(els2,nEqn2,inEqn2,nAlg2,inAlg2,inCons2,clats,externalDecl2,annotationLst2,comment2),info2) = cl;

        SCode.CLASS(_, prefixes1, encapsulatedPrefix1, partialPrefix1, restriction1, classExtendsCdef, info1) = classExtendsElt;
        SCode.CLASS_EXTENDS(_,mods,SCode.PARTS(els1,nEqn1,inEqn1,nAlg1,inAlg1,inCons1,_,externalDecl1,annotationLst1,comment1)) = classExtendsCdef;

        classDef = SCode.PARTS(els2,nEqn2,inEqn2,nAlg2,inAlg2,inCons2,clats,externalDecl2,annotationLst2,comment2);
        compelt = SCode.CLASS(name2,prefixes2,encapsulatedPrefix2,partialPrefix2,restriction2,classDef,info2);
        vis2 = SCode.prefixesVisibility(prefixes2);
        elt = SCode.EXTENDS(Absyn.IDENT(name2),vis2,mods,NONE(),info1);
        classDef = SCode.PARTS(elt::els1,nEqn1,inEqn1,nAlg1,inAlg1,inCons1,clats,externalDecl1,annotationLst1,comment1);
        elt = SCode.CLASS(name1, prefixes1, encapsulatedPrefix1, partialPrefix1, restriction1, classDef, info1);
        emod = Mod.renameTopLevelNamedSubMod(emod,name1,name2);
        //Debug.traceln("class extends: " +& SCodeDump.unparseElementStr(compelt) +& "  " +& SCodeDump.unparseElementStr(elt));
      then
        (emod,(compelt,mod1,b)::(elt,DAE.NOMOD(),true)::rest);

    case (_,emod,name1,classExtendsElt,first::rest)
      equation
        (emod,rest) = instClassExtendsList2(inEnv,emod,name1,classExtendsElt,rest);
      then
        (emod,first::rest);

    case (_,_,_,_,{})
      equation
        Debug.traceln("TODO: Make a proper Error message here - Inst.instClassExtendsList2 couldn't find the class to extend");
      then
        fail();

  end matchcontinue;
end instClassExtendsList2;

public function instDerivedClasses
"function: instDerivedClasses
  author: PA
  This function takes a class definition and returns the
  elements and equations and algorithms of the class.
  If the class is derived, the class is looked up and the
  derived class parts are fetched."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input SCode.Element inClass;
  input Boolean inBoolean;
  input Absyn.Info inInfo "File information of the extends element";
  output Env.Cache outCache;
  output Env.Env outEnv1;
  output InstanceHierarchy outIH;
  output list<SCode.Element> outSCodeElementLst2;
  output list<SCode.Equation> outSCodeEquationLst3;
  output list<SCode.Equation> outSCodeEquationLst4;
  output list<SCode.AlgorithmSection> outSCodeAlgorithmLst5;
  output list<SCode.AlgorithmSection> outSCodeAlgorithmLst6;
algorithm
  (outCache,outEnv1,outIH,outSCodeElementLst2,outSCodeEquationLst3,outSCodeEquationLst4,outSCodeAlgorithmLst5,outSCodeAlgorithmLst6) :=
  instDerivedClassesWork(inCache,inEnv,inIH,inMod,inPrefix,inClass,inBoolean,inInfo,false,0);
end instDerivedClasses;

protected function instDerivedClassesWork
"function: instDerivedClasses
  author: PA
  This function takes a class definition and returns the
  elements and equations and algorithms of the class.
  If the class is derived, the class is looked up and the
  derived class parts are fetched."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input SCode.Element inClass;
  input Boolean inBoolean;
  input Absyn.Info inInfo "File information of the extends element";
  input Boolean overflow;
  input Integer numIter;
  output Env.Cache outCache;
  output Env.Env outEnv1;
  output InstanceHierarchy outIH;
  output list<SCode.Element> outSCodeElementLst2;
  output list<SCode.Equation> outSCodeEquationLst3;
  output list<SCode.Equation> outSCodeEquationLst4;
  output list<SCode.AlgorithmSection> outSCodeAlgorithmLst5;
  output list<SCode.AlgorithmSection> outSCodeAlgorithmLst6;
algorithm
  (outCache,outEnv1,outIH,outSCodeElementLst2,outSCodeEquationLst3,outSCodeEquationLst4,outSCodeAlgorithmLst5,outSCodeAlgorithmLst6):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inClass,inBoolean,inInfo,overflow,numIter)
    local
      list<SCode.Element> elt;
      list<Env.Frame> env,cenv;
      DAE.Mod mod;
      list<SCode.Equation> eq,ieq;
      list<SCode.AlgorithmSection> alg,ialg;
      SCode.Element c;
      Absyn.Path tp;
      SCode.Mod dmod;
      Boolean impl;
      Env.Cache cache;
      InstanceHierarchy ih;
      Option<SCode.Comment> cmt;
      list<SCode.Enum> enumLst;
      String n,name,str1,str2;
      Option<SCode.ExternalDecl> extdecl;
      Prefix.Prefix pre;
      Absyn.Info info;

    case (cache,env,ih,mod,pre,SCode.CLASS(name = name, classDef =
          SCode.PARTS(elementLst = elt,
                      normalEquationLst = eq,initialEquationLst = ieq,
                      normalAlgorithmLst = alg,initialAlgorithmLst = ialg,
                      externalDecl = extdecl)),_,info,_,_)
      equation
        /* elt_1 = noImportElements(elt); */
        Error.assertionOrAddSourceMessage(Util.isNone(extdecl), Error.EXTENDS_EXTERNAL, {name}, info);
      then
        (cache,env,ih,elt,eq,ieq,alg,ialg);

    case (cache,env,ih,mod,pre,SCode.CLASS(info = info, classDef = SCode.DERIVED(typeSpec = Absyn.TPATH(tp, _),modifications = dmod)),impl, _, false, _)
      equation
        // Debug.fprintln(Flags.INST_TRACE, "DERIVED: " +& Env.printEnvPathStr(env) +& " el: " +& SCodeDump.unparseElementStr(inClass) +& " mods: " +& Mod.printModStr(mod));
        (cache, c, cenv) = Lookup.lookupClass(cache, env, tp, true);
        // false = Absyn.pathEqual(Env.getEnvName(env),Env.getEnvName(cenv)) and SCode.elementEqual(c,inClass);
        // modifiers should be evaluated in the current scope for derived!
        //(cache,daeDMOD) = Mod.elabMod(cache, env, ih, pre, dmod, impl, info);
        // merge in the class env
        //mod = Mod.merge(mod, daeDMOD, cenv, pre);
        (cache,env,ih,elt,eq,ieq,alg,ialg) = instDerivedClassesWork(cache, cenv, ih, mod, pre, c, impl, info, numIter >= 40, numIter+1)
        "Mod.lookup_modification_p(mod, c) => innermod & We have to merge and apply modifications as well!" ;
      then
        (cache,env,ih,elt,eq,ieq,alg,ialg);

    case (cache,env,ih,mod,pre,SCode.CLASS(name=n, classDef = SCode.ENUMERATION(enumLst,cmt), info = info),impl,_,false,_)
      equation
        c = Inst.instEnumeration(n, enumLst, cmt, info);
        (cache,env,ih,elt,eq,ieq,alg,ialg) = instDerivedClassesWork(cache, env, ih, mod, pre, c, impl,info, numIter >= 40, numIter+1);
      then
        (cache,env,ih,elt,eq,ieq,alg,ialg);

    case (_,_,_,_,_,_,_,_,true,_)
      equation
        str1 = SCodeDump.printElementStr(inClass);
        str2 = Env.printEnvPathStr(inEnv);
        // print("instDerivedClassesWork recursion depth... " +& str1 +& " " +& str2 +& "\n");
        Error.addSourceMessage(Error.RECURSION_DEPTH_DERIVED,{str1,str2},inInfo);
      then fail();

    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Inst.instDerivedClasses failed\n");
      then
        fail();
  end matchcontinue;
end instDerivedClassesWork;

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
  input Env.Env inEnv;
  output list<tuple<SCode.Element, DAE.Mod, Boolean>> outComponents;
  output DAE.Mod outRestMod;
algorithm
  (outComponents, outRestMod) := List.map1Fold(inComponents,
    updateComponentsAndClassdefs2, inEnv, inMod);
end updateComponentsAndClassdefs;

protected function updateComponentsAndClassdefs2
  input tuple<SCode.Element, DAE.Mod, Boolean> inComponent;
  input Env.Env inEnv;
  input DAE.Mod inMod;
  output tuple<SCode.Element, DAE.Mod, Boolean> outComponent;
  output DAE.Mod outRestMod;
algorithm
  (outComponent, outRestMod) := matchcontinue(inComponent, inEnv, inMod)
    local
      SCode.Element comp;
      DAE.Mod cmod, cmod2, mod_rest;
      String id;
      Boolean b;
      SCode.Mod m;

    case ((comp as SCode.COMPONENT(name = id, modifications = m), cmod, b), _, _)
      equation
        // Debug.traceln(" comp: " +& id +& " " +& Mod.printModStr(mod));
        // take ONLY the modification from the equation if is typed
        // cmod2 = Mod.getModifs(inMod, id, m);
        cmod2 = Mod.lookupCompModificationFromEqu(inMod, id);
        // Debug.traceln("\tSpecific mods on comp: " +&  Mod.printModStr(cmod2));
        cmod = Mod.merge(cmod2, cmod, inEnv, Prefix.NOPRE());
        mod_rest = inMod; //mod_rest = Mod.removeMod(inMod, id);
      then
        ((comp, cmod, b), mod_rest);

    case ((SCode.EXTENDS(baseClassPath = _), _, _), _, _)
      then (inComponent, inMod);

    case ((comp as SCode.IMPORT(imp = _), _, b), _ , _)
      then ((comp, DAE.NOMOD(), b), inMod);

    case ((comp as SCode.CLASS(name = id, prefixes = SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(_))), _, b), _, _)
      equation
        DAE.REDECL(_, _, (comp, cmod)::_) = Mod.lookupCompModification(inMod, id);
        mod_rest = inMod; //mod_rest = Mod.removeMod(inMod, id);
        comp = SCode.renameElement(comp, id);
      then
        ((comp, cmod, b), mod_rest);

    case ((comp as SCode.CLASS(name = id), cmod, b), _, _)
      equation
        DAE.NOMOD() = Mod.lookupCompModification(inMod, id);
      then
        ((comp, cmod, b), inMod);

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
    case ((comp as SCode.CLASS(name = id), _, b), _, _)
      equation
        cmod = Mod.lookupCompModification(inMod, id);
      then
        ((comp, cmod, b), inMod);

    case ((comp,cmod,b),_,_)
      equation
        Debug.fprintln(
          Flags.FAILTRACE,
          "- InstExtends.updateComponentsAndClassdefs2 failed on:\n" +&
          "env = " +& Env.printEnvPathStr(inEnv) +&
          "\nmod = " +& Mod.printModStr(inMod) +&
          "\ncmod = " +& Mod.printModStr(cmod) +&
          "\nbool = " +& Util.if_(b, "true", "false") +& "\n" +&
          SCodeDump.printElementStr(comp)
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
  as well as aliases from imports to paths.
"
  input SCode.Element elt;
  input HashTableStringToPath.HashTable inHt;
  output HashTableStringToPath.HashTable outHt;
algorithm
  (outHt) := match (elt,inHt)
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

  end match;
end getLocalIdentElement;

protected function fixLocalIdents
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<tuple<SCode.Element,DAE.Mod,Boolean>> inElts;
  input HashTableStringToPath.HashTable inHt;
  output Env.Cache outCache;
  output list<tuple<SCode.Element,DAE.Mod,Boolean>> outElts;
algorithm
  (outCache,outElts) := matchcontinue (inCache,inEnv,inElts,inHt)
    local
      SCode.Element elt;
      DAE.Mod mod;
      Boolean b;
      Env.Cache cache;
      Env.Env env;
      HashTableStringToPath.HashTable ht;
      list<tuple<SCode.Element,DAE.Mod,Boolean>> elts;

    case (cache,env,{},ht) then (cache,{});
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
    case (_,env,(elt,mod,b)::elts,_)
      equation
        Debug.traceln("- InstExtends.fixLocalIdents failed for element:" +&
        SCodeDump.unparseElementStr(elt) +& " mods: " +&
        Mod.printModStr(mod) +& " class extends:" +&
        Util.if_(b, "true", "false") +& " in env: " +& Env.printEnvPathStr(env)
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
  input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.Element inElt;
  input HashTableStringToPath.HashTable inHt;
  output Env.Cache outCache;
  output SCode.Element outElts;
algorithm
  (outCache,outElts) := matchcontinue (inCache,inEnv,inElt,inHt)
    local
      String name;
      SCode.Prefixes prefixes;
      SCode.Partial partialPrefix;
      Absyn.TypeSpec typeSpec;
      SCode.Mod modifications;
      Option<SCode.Comment> comment;
      Option<Absyn.Exp> condition;
      Absyn.Info info;
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
      Env.Cache cache;
      Env.Env env;
      HashTableStringToPath.HashTable ht;
      SCode.Element elt;

    case (cache,env,SCode.COMPONENT(name, prefixes, SCode.ATTR(ad, ct, prl, var, dir), typeSpec, modifications, comment, condition, info),ht)
      equation
        //Debug.fprintln(Flags.DEBUG,"fix comp " +& SCodeDump.printElementStr(elt));
        (cache,modifications) = fixModifications(cache,env,modifications,ht);
        (cache,typeSpec) = fixTypeSpec(cache,env,typeSpec,ht);
        (cache,SOME(ad)) = fixArrayDim(cache, env, SOME(ad), ht);
      then
        (cache,SCode.COMPONENT(name, prefixes, SCode.ATTR(ad, ct, prl, var, dir), typeSpec, modifications, comment, condition, info));

    case (cache,env,SCode.CLASS(name, prefixes, SCode.ENCAPSULATED(), partialPrefix, restriction, classDef, info),ht)
      equation
        //Debug.fprintln(Flags.DEBUG,"fixClassdef " +& name);
        (cache,env) = Builtin.initialEnv(cache);
        (cache,classDef) = fixClassdef(cache,env,classDef,ht);
      then
        (cache,SCode.CLASS(name, prefixes, SCode.ENCAPSULATED(), partialPrefix, restriction, classDef, info));

    case (cache,env,SCode.CLASS(name, prefixes, SCode.NOT_ENCAPSULATED(), partialPrefix, restriction, classDef, info),ht)
      equation
        //Debug.fprintln(Flags.DEBUG,"fixClassdef " +& name +& str);
        (cache,classDef) = fixClassdef(cache,env,classDef,ht);
      then
        (cache,SCode.CLASS(name, prefixes, SCode.NOT_ENCAPSULATED(), partialPrefix, restriction, classDef, info));

    case (cache,env,SCode.EXTENDS(extendsPath,vis,modifications,optAnnotation,info),ht)
      equation
        //Debug.fprintln(Flags.DEBUG,"fix extends " +& SCodeDump.printElementStr(elt));
        (cache,extendsPath) = fixPath(cache,env,extendsPath,ht);
        (cache,modifications) = fixModifications(cache,env,modifications,ht);
      then
        (cache,SCode.EXTENDS(extendsPath,vis,modifications,optAnnotation,info));

    case (cache,env,SCode.IMPORT(imp = _),ht) then (cache,inElt);

    case (cache,env,elt,ht)
      equation
        Debug.fprintln(Flags.FAILTRACE, "InstExtends.fixElement failed: " +& SCodeDump.printElementStr(elt));
      then fail();

  end matchcontinue;
end fixElement;

protected function fixClassdef
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.ClassDef inCd;
  input HashTableStringToPath.HashTable inHt;
  output Env.Cache outCache;
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
      Env.Cache cache;
      Env.Env env;
      HashTableStringToPath.HashTable ht;
      SCode.ClassDef cd;

    case (cache,env,SCode.PARTS(elts,ne,ie,na,ia,nc,clats,ed,ann,c),ht)
      equation
        (cache,elts) = fixList(cache,env,elts,ht,fixElement);
        (cache,ne) = fixList(cache,env,ne,ht,fixEquation);
        (cache,ie) = fixList(cache,env,ie,ht,fixEquation);
        (cache,na) = fixList(cache,env,na,ht,fixAlgorithm);
        (cache,ia) = fixList(cache,env,ia,ht,fixAlgorithm);
        (cache,nc) = fixList(cache,env,nc,ht,fixConstraint);
      then (cache,SCode.PARTS(elts,ne,ie,na,ia,nc,clats,ed,ann,c));

    case (cache,env,SCode.CLASS_EXTENDS(name,mod,SCode.PARTS(elts,ne,ie,na,ia,nc,clats,ed,ann,c)),ht)
      equation
        (cache,mod) = fixModifications(cache,env,mod,ht);
        (cache,elts) = fixList(cache,env,elts,ht,fixElement);
        (cache,ne) = fixList(cache,env,ne,ht,fixEquation);
        (cache,ie) = fixList(cache,env,ie,ht,fixEquation);
        (cache,na) = fixList(cache,env,na,ht,fixAlgorithm);
        (cache,ia) = fixList(cache,env,ia,ht,fixAlgorithm);
        (cache,nc) = fixList(cache,env,nc,ht,fixConstraint);
      then (cache,SCode.CLASS_EXTENDS(name,mod,SCode.PARTS(elts,ne,ie,na,ia,nc,clats,ed,ann,c)));

    case (cache,env,SCode.DERIVED(ts,mod,attr,c),ht)
      equation
        (cache,ts) = fixTypeSpec(cache,env,ts,ht);
        (cache,mod) = fixModifications(cache,env,mod,ht);
      then (cache,SCode.DERIVED(ts,mod,attr,c));

    case (cache,env,cd as SCode.ENUMERATION(comment = _),ht) then (cache,cd);
    case (cache,env,cd as SCode.OVERLOAD(comment = _),ht) then (cache,cd);
    case (cache,env,cd as SCode.PDER(comment = _),ht) then (cache,cd);

    case (cache,env,cd,ht)
      equation
        Debug.fprintln(Flags.FAILTRACE, "InstExtends.fixClassDef failed: " +& SCodeDump.printClassdefStr(cd));
      then
        fail();

  end matchcontinue;
end fixClassdef;

protected function fixEquation
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.Equation inEq;
  input HashTableStringToPath.HashTable inHt;
  output Env.Cache outCache;
  output SCode.Equation outEq;
algorithm
  (outCache,outEq) := match (inCache,inEnv,inEq,inHt)
    local
      SCode.EEquation eeq;
      Env.Cache cache;
      Env.Env env;
      HashTableStringToPath.HashTable ht;

    case (cache,env,SCode.EQUATION(eeq),ht)
      equation
        (cache,eeq) = fixEEquation(cache,env,eeq,ht);
      then
        (cache,SCode.EQUATION(eeq));
    case (cache,env,SCode.EQUATION(eeq),ht)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- Inst.fixEquation failed: " +& SCodeDump.equationStr(eeq));
      then
        fail();
  end match;
end fixEquation;

protected function fixEEquation
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.EEquation inEeq;
  input HashTableStringToPath.HashTable inHt;
  output Env.Cache outCache;
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
      Option<SCode.Comment> comment;
      Option<Absyn.Exp> optExp;
      Absyn.Info info;
      Env.Cache cache;
      Env.Env env;
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
  input Env.Cache cache;
  input Env.Env env;
  input list<SCode.EEquation> eeq;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output list<SCode.EEquation> outEeq;
algorithm
  (outCache,outEeq) := fixList(cache,env,eeq,ht,fixEEquation);
end fixListEEquation;

protected function fixAlgorithm
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.AlgorithmSection inAlg;
  input HashTableStringToPath.HashTable inHt;
  output Env.Cache outCache;
  output SCode.AlgorithmSection outAlg;
algorithm
  (outCache,outAlg) := match (inCache,inEnv,inAlg,inHt)
    local
      list<SCode.Statement> stmts;
      Env.Cache cache;
      Env.Env env;
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
  input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.ConstraintSection inConstrs;
  input HashTableStringToPath.HashTable inHt;
  output Env.Cache outCache;
  output SCode.ConstraintSection outConstrs;
algorithm
  (outCache,outConstrs) := match (inCache,inEnv,inConstrs,inHt)
    local
      list<Absyn.Exp> exps;
      Env.Cache cache;
      Env.Env env;
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
  input Env.Cache cache;
  input Env.Env env;
  input list<SCode.Statement> alg;
  input HashTableStringToPath.HashTable ht;
  output Env.Cache outCache;
  output list<SCode.Statement> outAlg;
algorithm
  (outCache,outAlg) := fixList(cache,env,alg,ht,fixStatement);
end fixListAlgorithmItem;

protected function fixStatement
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.Statement inStmt;
  input HashTableStringToPath.HashTable inHt;
  output Env.Cache outCache;
  output SCode.Statement outStmt;
algorithm
  (outCache,outStmt) := matchcontinue (inCache,inEnv,inStmt,inHt)
    local
      Absyn.Exp exp,exp1,exp2;
      Option<Absyn.Exp> optExp;
      String iter;
      list<tuple<Absyn.Exp, list<SCode.Statement>>> elseifbranch,whenlst;
      list<SCode.Statement> truebranch,elsebranch,forbody,whilebody;
      Option<SCode.Comment> comment;
      Absyn.Info info;
      Env.Cache cache;
      Env.Env env;
      HashTableStringToPath.HashTable ht;
      SCode.Statement stmt;

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
        (cache,forbody) = fixList(cache,env,whilebody,ht,fixStatement);
      then (cache,SCode.ALG_WHILE(exp,whilebody,comment,info));

    case (cache,env,SCode.ALG_WHEN_A(whenlst,comment,info),ht)
      equation
        (cache,whenlst) = fixListTuple2(cache,env,whenlst,ht,fixExp,fixListAlgorithmItem);
      then (cache,SCode.ALG_WHEN_A(whenlst,comment,info));

    case (cache,env,SCode.ALG_NORETCALL(exp,comment,info),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
      then (cache,SCode.ALG_NORETCALL(exp,comment,info));

    case (cache,env,SCode.ALG_RETURN(comment,info),ht) then (cache,SCode.ALG_RETURN(comment,info));

    case (cache,env,SCode.ALG_BREAK(comment,info),ht) then (cache,SCode.ALG_BREAK(comment,info));

    case (cache,env,stmt,ht)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- Inst.fixStatement failed: " +& Dump.unparseAlgorithmStr(4,SCode.statementToAlgorithmItem(stmt)));
      then fail();
  end matchcontinue;
end fixStatement;

protected function fixArrayDim
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Option<Absyn.ArrayDim> inAd;
  input HashTableStringToPath.HashTable inHt;
  output Env.Cache outCache;
  output Option<Absyn.ArrayDim> outAd;
algorithm
  (outCache,outAd) := match (inCache,inEnv,inAd,inHt)
    local
      list<Absyn.Subscript> ads;
      Env.Cache cache;
      Env.Env env;
      HashTableStringToPath.HashTable ht;

    case (cache,env,NONE(),ht) then (cache,NONE());
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
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Subscript inSub;
  input HashTableStringToPath.HashTable inHt;
  output Env.Cache outCache;
  output Absyn.Subscript outSub;
algorithm
  (outCache,outSub) := match (inCache,inEnv,inSub,inHt)
    local
      Absyn.Exp exp;
      Env.Cache cache;
      Env.Env env;
      HashTableStringToPath.HashTable ht;

    case (cache,env,Absyn.NOSUB(),ht) then (cache,Absyn.NOSUB());
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
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.TypeSpec inTs;
  input HashTableStringToPath.HashTable inHt;
  output Env.Cache outCache;
  output Absyn.TypeSpec outTs;
algorithm
  (outCache,outTs) := match (inCache,inEnv,inTs,inHt)
    local
      Absyn.Path path;
      Option<Absyn.ArrayDim> arrayDim;
      list<Absyn.TypeSpec> typeSpecs;
      Env.Cache cache;
      Env.Env env;
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
  local lookup or fully qualified in the environment.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input HashTableStringToPath.HashTable inHt;
  output Env.Cache outCache;
  output Absyn.Path outPath;
algorithm
  (outCache,outPath) := matchcontinue (inCache,inEnv,inPath,inHt)
    local
      String id;
      Absyn.Path path1,path2,path;
      Env.Cache cache;
      Env.Env env;
      HashTableStringToPath.HashTable ht;

    case (cache,env,path1 as Absyn.FULLYQUALIFIED(_),ht)
      equation
        //Debug.fprintln(Flags.DEBUG, "Path FULLYQUAL: " +& Absyn.pathString(path));
      then
        (cache,path1);

    case (cache,env,path1,ht)
      equation
        id = Absyn.pathFirstIdent(path1);
        path2 = BaseHashTable.get(id,ht);
        path2 = Absyn.pathReplaceFirstIdent(path1,path2);
        //Debug.fprintln(Flags.DEBUG, "Replacing: " +& Absyn.pathString(path1) +& " with " +& Absyn.pathString(path2) +& " s:" +& Env.printEnvPathStr(env));
      then (cache,path2);
    /*
    // when a class is partial, do not fully qualify as it SHOULD POINT TO THE ONE IN THE DERIVED CLASS!
    case (cache,env,path,ht)
      equation
        Debug.fprintln(Flags.DEBUG,"Try lookupC " +& Absyn.pathString(path));
        (_,SCode.CLASS(partialPrefix = SCode.PARTIAL()),env) = Lookup.lookupClass(cache,env,path,false);
        Debug.fprintln(Flags.DEBUG, "Path PARTIAL not fixed: " +& Absyn.pathString(path));
      then (cache,path);

    // when a class is replaceable, do not fully qualify it as it SHOULD POINT TO THE ONE IN THE DERIVED CLASS!
    case (cache,env,path,ht)
      equation
        Debug.fprintln(Flags.DEBUG,"Try lookupC " +& Absyn.pathString(path));
        (_,SCode.CLASS(prefixes = SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(_))),env) = Lookup.lookupClass(cache,env,path,false);
        Debug.fprintln(Flags.DEBUG, "Path REPLACEABLE not fixed: " +& Absyn.pathString(path));
      then (cache,path);*/

    case (cache,env,path,ht)
      equation
        //Debug.fprintln(Flags.DEBUG,"Try makeFullyQualified " +& Absyn.pathString(path));
        (cache,path) = Inst.makeFullyQualified(cache,env,path);
        //Debug.fprintln(Flags.DEBUG,"FullyQual: " +& Absyn.pathString(path));
      then (cache,path);

    case (cache,env,path,_)
      equation
        //Debug.fprintln(Flags.DEBUG, "Path not fixed: " +& Absyn.pathString(path) +& "\n");
      then
        (cache,path);
  end matchcontinue;
end fixPath;

protected function lookupVarNoErrorMessage
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
  output Env.Env outEnv;
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
    case (_, _, _)
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
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inCref;
  input HashTableStringToPath.HashTable inHt;
  output Env.Cache outCache;
  output Absyn.ComponentRef outCref;
algorithm
  (outCache,outCref) := matchcontinue (inCache,inEnv,inCref,inHt)
    local
      String id;
      Absyn.Path path;
      DAE.ComponentRef cref_;
      Env.Cache cache;
      Env.Env env;
      HashTableStringToPath.HashTable ht;
      Absyn.ComponentRef cref;

    case (cache,env,cref,ht)
      equation
        id = Absyn.crefFirstIdent(cref);
        //Debug.fprintln(Flags.DEBUG,"Try ht lookup " +& id);
        path = BaseHashTable.get(id,ht);
        //Debug.fprintln(Flags.DEBUG,"Got path " +& Absyn.pathString(path));
        cref = Absyn.crefReplaceFirstIdent(cref,path);
        //Debug.fprintln(Flags.DEBUG, "Cref HT fixed: " +& Absyn.printComponentRefStr(cref));
      then (cache,cref);

    // try lookup var (constant in a package?)
    case (cache,env,cref,ht)
      equation
        id = Absyn.crefFirstIdent(cref);
        cref_ = ComponentReference.makeCrefIdent(id,DAE.T_UNKNOWN_DEFAULT,{});
        //Debug.fprintln(Flags.DEBUG,"Try lookupV " +& id);
        (env,id) = lookupVarNoErrorMessage(cache,env,cref_);
        //Debug.fprintln(Flags.DEBUG,"Got env " +& intString(listLength(env)));
        env = Env.openScope(env,SCode.ENCAPSULATED(),SOME(id),NONE());
        cref = Absyn.crefReplaceFirstIdent(cref,Env.getEnvName(env));
        //Debug.fprintln(Flags.DEBUG, "Cref VAR fixed: " +& Absyn.printComponentRefStr(cref));
      then (cache,cref);

    /*// when a class is partial, do not fully qualify as it SHOULD POINT TO THE ONE IN THE DERIVED CLASS!
    case (cache,env,cref,ht)
      equation
        id = Absyn.crefFirstIdent(cref);
        Debug.fprintln(Flags.DEBUG,"Try lookupC " +& id);
        (_,SCode.CLASS(partialPrefix = SCode.PARTIAL()),env) = Lookup.lookupClass(cache,env,Absyn.IDENT(id),false);
        Debug.fprintln(Flags.DEBUG, "Cref PARTIAL CLASS fixed: " +& Absyn.printComponentRefStr(cref));
      then (cache,cref);

    // when a class is replaceable, do not fully qualify it as it SHOULD POINT TO THE ONE IN THE DERIVED CLASS!
    case (cache,env,cref,ht)
      equation
        id = Absyn.crefFirstIdent(cref);
        Debug.fprintln(Flags.DEBUG,"Try lookupC " +& id);
        (_,SCode.CLASS(prefixes = SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(_))),env) = Lookup.lookupClass(cache,env,Absyn.IDENT(id),false);
        Debug.fprintln(Flags.DEBUG, "Cref REPLACEABLE CLASS fixed: " +& Absyn.printComponentRefStr(cref));
      then (cache,cref);*/

    case (cache,env,cref,ht)
      equation
        id = Absyn.crefFirstIdent(cref);
        //Debug.fprintln(Flags.DEBUG,"Try lookupC " +& id);
        (_,_,env) = Lookup.lookupClass(cache,env,Absyn.IDENT(id),false);
        //Debug.fprintln(Flags.DEBUG,"Got env " +& intString(listLength(env)));
        env = Env.openScope(env,SCode.ENCAPSULATED(),SOME(id),NONE());
        cref = Absyn.crefReplaceFirstIdent(cref,Env.getEnvName(env));
        //Debug.fprintln(Flags.DEBUG, "Cref CLASS fixed: " +& Absyn.printComponentRefStr(cref));
      then (cache,cref);

    case (cache,env,cref,_)
      equation
        //Debug.fprintln(Flags.DEBUG, "Cref not fixed: " +& Absyn.printComponentRefStr(cref));
      then
        (cache,cref);

  end matchcontinue;
end fixCref;

protected function fixModifications
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.Mod inMod;
  input HashTableStringToPath.HashTable inHt;
  output Env.Cache outCache;
  output SCode.Mod outMod;
algorithm
  (outCache,outMod) := matchcontinue (inCache,inEnv,inMod,inHt)
    local
      SCode.Final finalPrefix "final prefix";
      SCode.Each eachPrefix;
      list<SCode.SubMod> subModLst;
      Absyn.Exp exp;
      Boolean b;
      SCode.Element elt;
      Env.Cache cache;
      Env.Env env;
      HashTableStringToPath.HashTable ht;
      SCode.Mod mod;
      Absyn.Info info;

    case (cache,env,SCode.NOMOD(),ht) then (cache,SCode.NOMOD());

    case (cache,env,SCode.MOD(finalPrefix,eachPrefix,subModLst,SOME((exp,b)),info),ht)
      equation
        (cache, subModLst) = fixSubModList(cache, env, subModLst, ht);
        (cache,exp) = fixExp(cache,env,exp,ht);
      then
        (cache,SCode.MOD(finalPrefix,eachPrefix,subModLst,SOME((exp,b)),info));

    case (cache,env,SCode.MOD(finalPrefix,eachPrefix,subModLst,NONE(),info),ht)
      equation
        (cache, subModLst) = fixSubModList(cache, env, subModLst, ht);
      then
        (cache,SCode.MOD(finalPrefix,eachPrefix,subModLst,NONE(),info));

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

    case (cache,env,mod,ht)
      equation
        Debug.fprintln(Flags.FAILTRACE,"InstExtends.fixModifications failed: " +& SCodeDump.printModStr(mod));
      then
        fail();

  end matchcontinue;
end fixModifications;

protected function fixSubModList
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<SCode.SubMod> inSubMods;
  input HashTableStringToPath.HashTable inHt;
  output Env.Cache outCache;
  output list<SCode.SubMod> outSubMods;
algorithm
  (outCache, outSubMods) := match (inCache, inEnv, inSubMods, inHt)
    local
      SCode.Mod mod;
      list<SCode.SubMod> rest_mods;
      Absyn.Ident ident;
      list<SCode.Subscript> subs;
      Env.Cache cache;

    case (_, _, {}, _) then (inCache, {});

    case (_, _, SCode.NAMEMOD(ident = ident, A = mod) :: rest_mods, _)
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
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Exp inExp;
  input HashTableStringToPath.HashTable inHt;
  output Env.Cache outCache;
  output Absyn.Exp outExp;
algorithm
  (outCache,outExp) := matchcontinue (inCache,inEnv,inExp,inHt)
    local
      Absyn.ComponentRef cref;
      Absyn.FunctionArgs fargs;
      Absyn.Exp exp1,exp2,ifexp,truebranch,elsebranch,exp;
      list<Absyn.Exp> expl;
      Option<Absyn.Exp> optExp;
      list<list<Absyn.Exp>> expll;
      list<tuple<Absyn.Exp,Absyn.Exp>> elseifbranches;
      Absyn.Operator op;
      Env.Cache cache;
      Env.Env env;
      HashTableStringToPath.HashTable ht;

    case (cache,env,Absyn.CREF(cref),ht)
      equation
        (cache,cref) = fixCref(cache,env,cref,ht);
      then (cache,Absyn.CREF(cref));
    case (cache,env,Absyn.CALL(cref,fargs),ht)
      equation
        (cache,fargs) = fixFarg(cache,env,fargs,ht);
        (cache,cref) = fixCref(cache,env,cref,ht);
      then (cache,Absyn.CALL(cref,fargs));
    case (cache,env,Absyn.BINARY(exp1,op,exp2),ht)
      equation
        (cache,exp1) = fixExp(cache,env,exp1,ht);
        (cache,exp2) = fixExp(cache,env,exp2,ht);
      then (cache,Absyn.BINARY(exp1,op,exp2));
    case (cache,env,Absyn.UNARY(op,exp),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
      then (cache,Absyn.UNARY(op,exp));
    case (cache,env,Absyn.LBINARY(exp1,op,exp2),ht)
      equation
        (cache,exp1) = fixExp(cache,env,exp1,ht);
        (cache,exp2) = fixExp(cache,env,exp2,ht);
      then (cache,Absyn.LBINARY(exp1,op,exp2));
    case (cache,env,Absyn.LUNARY(op,exp),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
      then (cache,Absyn.LUNARY(op,exp));
    case (cache,env,Absyn.RELATION(exp1,op,exp2),ht)
      equation
        (cache,exp1) = fixExp(cache,env,exp1,ht);
        (cache,exp2) = fixExp(cache,env,exp2,ht);
      then (cache,Absyn.RELATION(exp1,op,exp2));
    case (cache,env,Absyn.IFEXP(ifexp,truebranch,elsebranch,elseifbranches),ht)
      equation
        (cache,ifexp) = fixExp(cache,env,ifexp,ht);
        (cache,truebranch) = fixExp(cache,env,truebranch,ht);
        (cache,elsebranch) = fixExp(cache,env,elsebranch,ht);
        (cache,elseifbranches) = fixListTuple2(cache,env,elseifbranches,ht,fixExp,fixExp);
      then (cache,Absyn.IFEXP(ifexp,truebranch,elsebranch,elseifbranches));
    case (cache,env,Absyn.ARRAY(expl),ht)
      equation
        (cache,expl) = fixList(cache,env,expl,ht,fixExp);
      then (cache,Absyn.ARRAY(expl));
    case (cache,env,Absyn.MATRIX(expll),ht)
      equation
        (cache,expll) = fixListList(cache,env,expll,ht,fixExp);
      then (cache,Absyn.MATRIX(expll));
    case (cache,env,Absyn.RANGE(exp1,optExp,exp2),ht)
      equation
        (cache,exp1) = fixExp(cache,env,exp1,ht);
        (cache,exp2) = fixExp(cache,env,exp2,ht);
        (cache,optExp) = fixOption(cache,env,optExp,ht,fixExp);
      then (cache,Absyn.RANGE(exp1,optExp,exp2));
    case (cache,env,Absyn.TUPLE(expl),ht)
      equation
        (cache,expl) = fixList(cache,env,expl,ht,fixExp);
      then (cache,Absyn.TUPLE(expl));
    case (cache,env,exp as Absyn.INTEGER(_),ht) then (cache,exp);
    case (cache,env,exp as Absyn.REAL(_),ht) then (cache,exp);
    case (cache,env,exp as Absyn.STRING(_),ht) then (cache,exp);
    case (cache,env,exp as Absyn.BOOL(_),ht) then (cache,exp);
    case (cache,env,exp,ht)
      equation
        Debug.fprintln(Flags.FAILTRACE,"InstExtends.fixExp failed: " +& Dump.printExpStr(exp));
      then fail();
  end matchcontinue;
end fixExp;

protected function fixFarg
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.FunctionArgs inFargs;
  input HashTableStringToPath.HashTable inHt;
  output Env.Cache outCache;
  output Absyn.FunctionArgs outFarg;
algorithm
  (outCache,outFarg) := match (inCache,inEnv,inFargs,inHt)
    local
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> argNames;
      Absyn.ForIterators iterators;
      Absyn.Exp exp;
      Env.Cache cache;
      Env.Env env;
      HashTableStringToPath.HashTable ht;

    case (cache,env,Absyn.FUNCTIONARGS(args,argNames),ht)
      equation
        (cache,args) = fixList(cache,env,args,ht,fixExp);
        (cache,argNames) = fixList(cache,env,argNames,ht,fixNamedArg);
      then (cache,Absyn.FUNCTIONARGS(args,argNames));
    case (cache,env,Absyn.FOR_ITER_FARG(exp,iterators),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
        (cache,iterators) = fixList(cache,env,iterators,ht,fixForIterator);
      then (cache,Absyn.FOR_ITER_FARG(exp,iterators));
  end match;
end fixFarg;

protected function fixForIterator
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ForIterator inIter;
  input HashTableStringToPath.HashTable inHt;
  output Env.Cache outCache;
  output Absyn.ForIterator outIter;
algorithm
  (outCache,outIter) := match (inCache,inEnv,inIter,inHt)
    local
      String id;
      Absyn.Exp exp;
      Option<Absyn.Exp> guardExp;
      Absyn.ForIterator iter;
      Env.Cache cache;
      Env.Env env;
      HashTableStringToPath.HashTable ht;

    case (cache,env,Absyn.ITERATOR(id,guardExp,SOME(exp)),ht)
      equation
        (cache,exp) = fixExp(cache,env,exp,ht);
        (cache,guardExp) = fixOption(cache,env,guardExp,ht,fixExp);
      then (cache,Absyn.ITERATOR(id,guardExp,SOME(exp)));
    case (cache,env,iter,ht) then (cache,iter);
  end match;
end fixForIterator;

protected function fixNamedArg
" All of the fix functions do the following:
  Analyzes the SCode datastructure and replace paths with a new path (from
  local lookup or fully qualified in the environment.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.NamedArg inNarg;
  input HashTableStringToPath.HashTable inHt;
  output Env.Cache outCache;
  output Absyn.NamedArg outNarg;
algorithm
  (outCache,outNarg) := match (inCache,inEnv,inNarg,inHt)
    local
      String id;
      Absyn.Exp exp;
      Env.Cache cache;
      Env.Env env;
      HashTableStringToPath.HashTable ht;

    case (cache,env,Absyn.NAMEDARG(id,exp),ht)
      equation
        //print("Fixing named: id:" +& id +& " exp:" +& Dump.printExpStr(exp));
        (cache,exp) = fixExp(cache,env,exp,ht);
        //print("FIXED named: id:" +& id +& " exp:" +& Dump.printExpStr(exp));
      then (cache,Absyn.NAMEDARG(id,exp));
  end match;
end fixNamedArg;

protected function fixOption
" Generic function to fix an optional element."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Option<Type_A> inA;
  input HashTableStringToPath.HashTable inHt;
  input FixAFn fixA;
  output Env.Cache outCache;
  output Option<Type_A> outA;

  replaceable type Type_A subtypeof Any;
  partial function FixAFn
    input Env.Cache inCache;
    input Env.Env inEnv;
    input Type_A inA;
    input HashTableStringToPath.HashTable inHt;
    output Env.Cache outCache;
    output Type_A outTypeA;
  end FixAFn;
algorithm
  (outCache,outA) := match (inCache,inEnv,inA,inHt,fixA)
    local
      Type_A A;
      Env.Cache cache;
      Env.Env env;
      HashTableStringToPath.HashTable ht;

    case (cache,env,NONE(),ht,_) then (cache,NONE());
    case (cache,env,SOME(A),ht,_)
      equation
        (cache,A) = fixA(cache,env,A,ht);
      then (cache,SOME(A));
  end match;
end fixOption;

protected function fixList
" Generic function to fix a list of elements."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Type_A> inA;
  input HashTableStringToPath.HashTable inHt;
  input FixAFn fixA;
  output Env.Cache outCache;
  output list<Type_A> outA;

  replaceable type Type_A subtypeof Any;
  partial function FixAFn
    input Env.Cache inCache;
    input Env.Env inEnv;
    input Type_A inA;
    input HashTableStringToPath.HashTable inHt;
    output Env.Cache outCache;
    output Type_A outTypeA;
  end FixAFn;
algorithm
  (outCache,outA) := match (inCache,inEnv,inA,inHt,fixA)
    local
      Type_A A;
      list<Type_A> lstA;
      Env.Cache cache;
      Env.Env env;
      HashTableStringToPath.HashTable ht;

    case (cache,env,{},ht,_) then (cache,{});
    case (cache,env,A::lstA,ht,_)
      equation
        (cache,A) = fixA(cache,env,A,ht);
        (cache,lstA) = fixList(cache,env,lstA,ht,fixA);
      then (cache,A::lstA);
  end match;
end fixList;

protected function fixListList
" Generic function to fix a list of elements."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<list<Type_A>> inA;
  input HashTableStringToPath.HashTable inHt;
  input FixAFn fixA;
  output Env.Cache outCache;
  output list<list<Type_A>> outA;

  replaceable type Type_A subtypeof Any;
  partial function FixAFn
    input Env.Cache inCache;
    input Env.Env inEnv;
    input Type_A inA;
    input HashTableStringToPath.HashTable inHt;
    output Env.Cache outCache;
    output Type_A outTypeA;
  end FixAFn;
algorithm
  (outCache,outA) := match (inCache,inEnv,inA,inHt,fixA)
    local
      list<Type_A> A;
      list<list<Type_A>> lstA;
      Env.Cache cache;
      Env.Env env;
      HashTableStringToPath.HashTable ht;

    case (cache,env,{},ht,_) then (cache,{});
    case (cache,env,A::lstA,ht,_)
      equation
        (cache,A) = fixList(cache,env,A,ht,fixA);
        (cache,lstA) = fixListList(cache,env,lstA,ht,fixA);
      then (cache,A::lstA);
  end match;
end fixListList;

protected function fixListTuple2
" Generic function to fix a list of elements."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<tuple<Type_A,Type_B>> inRest;
  input HashTableStringToPath.HashTable inHt;
  input FixAFn fixA;
  input FixBFn fixB;
  output Env.Cache outCache;
  output list<tuple<Type_A,Type_B>> outA;

  replaceable type Type_A subtypeof Any;
  replaceable type Type_B subtypeof Any;
  partial function FixAFn
    input Env.Cache inCache;
    input Env.Env inEnv;
    input Type_A inA;
    input HashTableStringToPath.HashTable inHt;
    output Env.Cache outCache;
    output Type_A outLst;
  end FixAFn;
  partial function FixBFn
    input Env.Cache inCache;
    input Env.Env inEnv;
    input Type_B inA;
    input HashTableStringToPath.HashTable inHt;
    output Env.Cache outCache;
    output Type_B outTypeA;
  end FixBFn;
algorithm
  (outCache,outA) := match (inCache,inEnv,inRest,inHt,fixA,fixB)
    local
      Type_A a;
      Type_B b;
      list<tuple<Type_A,Type_B>> rest;
      Env.Cache cache;
      Env.Env env;
      HashTableStringToPath.HashTable ht;

    case (cache,env,{},ht,_,_) then (cache,{});
    case (cache,env,(a,b)::rest,ht,_,_)
      equation
        (cache,a) = fixA(cache,env,a,ht);
        (cache,b) = fixB(cache,env,b,ht);
        (cache,rest) = fixListTuple2(cache,env,rest,ht,fixA,fixB);
      then (cache,(a,b)::rest);
  end match;
end fixListTuple2;

end InstExtends;
