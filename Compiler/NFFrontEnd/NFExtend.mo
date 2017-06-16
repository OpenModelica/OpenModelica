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

encapsulated package NFExtend
" file:        NFExtend.mo
  package:     NFExtend
  description: Instantiation of class extends
"

import Absyn;
import SCode;

import Builtin = NFBuiltin;
import Binding = NFBinding;
import NFComponent.Component;
import Dimension = NFDimension;
import Expression = NFExpression;
import NFClass.ClassTree;
import NFClass.Class;
import NFInstNode.InstNode;
import NFInstNode.InstNodeType;
import NFMod.Modifier;
import NFMod.ModifierScope;
import NFEquation.Equation;
import NFStatement.Statement;
import Type = NFType;

protected
import Array;
import Error;
import Flatten = NFFlatten;
import Global;
import InstUtil = NFInstUtil;
import List;
import Lookup = NFLookup;
import MetaModelica.Dangerous;
import Typing = NFTyping;
import ExecStat.{execStat,execStatReset};
import SCodeDump;
import SCodeUtil;
import System;

//public function isRedeclareElement
//"get the redeclare-as-element elements"
//  input SCode.Element element;
//  output Boolean isElement;
//algorithm
//  isElement := match element
//    // redeclare-as-element component
//    case SCode.COMPONENT(prefixes = SCode.PREFIXES(redeclarePrefix = SCode.REDECLARE()))
//      then true;
//    // redeclare-as-element class
//    case SCode.CLASS(prefixes = SCode.PREFIXES(redeclarePrefix = SCode.REDECLARE()))
//      then true;
//    // class extends WITHOUT redeclare, see:
//    // https://trac.modelica.org/Modelica/ticket/709
//    // TODO! FIXME! add a warning that class extends is WITHOUT redeclare
//    // maybe we should automatically add it when going from Absyn to SCode!
//    case SCode.CLASS(classDef = SCode.CLASS_EXTENDS())
//      then true;
//    else false;
//  end match;
//end isRedeclareElement;
//
//public function adaptClassExtendsChain
//"@author: adrpo
// handle class extends
// 1. see if we already have a class with the same name
// 2. patch the existing class with a new name Model_$ce$number
// 3. patch the current class extends with an extends to the Model_$extends_number and change it to a normal class"
//  input String name;
//  input ClassTree.Entry ceEntry "the class extends";
//  input ClassTree.Tree inScope;
//  output ClassTree.Tree scope;
//protected
//  SCode.Element ceEl, baseEl;
//  InstNode ceNode, baseNode;
//  ClassTree.Entry baseEntry;
//  String baseNewName;
//  Integer ceTick = System.tmpTickIndex(Global.classExtends_index);
//algorithm
//  scope := match ceEntry
//    case ClassTree.Entry.CLASS()
//      algorithm
//        // get the class extends class
//        ceNode := ceEntry.node;
//        ceEl := InstNode.definition(ceEntry.node);
//        // get the existing base class
//        try
//          baseEntry := ClassTree.get(inScope, name);
//        else
//          // report that the target of class extends does not exist!
//          Error.addSourceMessageAndFail(Error.CLASS_EXTENDS_TARGET_NOT_FOUND, {name}, SCode.elementInfo(ceEl));
//        end try;
//
//        ClassTree.Entry.CLASS(baseNode) := baseEntry;
//        // get the existing class in the environment
//        baseEl := InstNode.definition(baseNode);
//        // TODO! FIXME! check if the base class (id) is replaceable and add an error if not
//        // Error.NON_REPLACEABLE_CLASS_EXTENDS
//        baseNewName := name + "$ce$" + String(ceTick);
//        // patch the base class and the class extends!
//        (baseEl, ceEl) := patchBaseClassAndClassExtends(baseNewName, name, baseEl, ceEl);
//        // update nodes!
//        baseNode := InstNode.rename(baseNode, baseNewName);
//        baseNode := InstNode.setDefinition(baseEl, baseNode);
//        ceNode := InstNode.setDefinition(ceEl, ceNode);
//
//        // do partial instantiation again TODO! FIXME! is this needed??!!
//        baseNode := NFInst.partialInstClass(baseNode);
//        ceNode := NFInst.partialInstClass(ceNode);
//
//        // replace the class extends with the new definition
//        scope := ClassTree.add(inScope, name, ClassTree.Entry.CLASS(ceNode), ClassTree.addConflictReplace);
//
//        // add the base class with the new name to the scope
//        scope := ClassTree.add(scope, baseNewName, ClassTree.Entry.CLASS(baseNode));
//      then
//        scope;
//
//    else inScope;
//  end match;
//end adaptClassExtendsChain;
//
//protected function patchBaseClassAndClassExtends
//  input String inBaseEltName;
//  input String inClassExtendsEltName;
//  input SCode.Element inBaseElt;
//  input SCode.Element inClassExtendsElt;
//  output SCode.Element outBaseElt;
//  output SCode.Element outClassExtendsElt;
//algorithm
//  (outBaseElt,outClassExtendsElt) := matchcontinue (inBaseElt,inClassExtendsElt)
//    local
//      SCode.Element elt,compelt,classExtendsElt;
//      SCode.Element cl;
//      SCode.ClassDef classDef,classExtendsCdef;
//      SCode.Partial partialPrefix1,partialPrefix2;
//      SCode.Encapsulated encapsulatedPrefix1,encapsulatedPrefix2;
//      SCode.Restriction restriction1,restriction2;
//      SCode.Prefixes prefixes1,prefixes2;
//      SCode.Visibility vis2;
//      String name1,name2,env_path;
//      Option<SCode.ExternalDecl> externalDecl1,externalDecl2;
//      list<SCode.Annotation> annotationLst1,annotationLst2;
//      SCode.Comment comment1,comment2;
//      Option<SCode.Annotation> ann1,ann2;
//      list<SCode.Element> els1,els2;
//      list<SCode.Equation> nEqn1,nEqn2,inEqn1,inEqn2;
//      list<SCode.AlgorithmSection> nAlg1,nAlg2,inAlg1,inAlg2;
//      list<SCode.ConstraintSection> inCons1, inCons2;
//      list<Absyn.NamedArg> clats;
//      list<tuple<SCode.Element, DAE.Mod, Boolean>> rest;
//      tuple<SCode.Element, DAE.Mod, Boolean> first;
//      SCode.Mod mods, derivedMod;
//      DAE.Mod mod1,emod;
//      SourceInfo info1, info2;
//      Boolean b;
//      SCode.Attributes attrs;
//      Absyn.TypeSpec derivedTySpec;
//
//    // found the base class with parts
//    case (cl as SCode.CLASS(name = name2, classDef = SCode.PARTS()), classExtendsElt)
//      equation
//        name1 = inClassExtendsEltName;
//        name2 = inBaseEltName;
//
//        SCode.CLASS(_,prefixes2,encapsulatedPrefix2,partialPrefix2,restriction2,SCode.PARTS(els2,nEqn2,inEqn2,nAlg2,inAlg2,inCons2,clats,externalDecl2),comment2,info2) = cl;
//
//        SCode.CLASS(_, prefixes1, encapsulatedPrefix1, partialPrefix1, restriction1, classExtendsCdef, comment1, info1) = classExtendsElt;
//        SCode.CLASS_EXTENDS(_,mods,SCode.PARTS(els1,nEqn1,inEqn1,nAlg1,inAlg1,inCons1,_,externalDecl1)) = classExtendsCdef;
//
//        classDef = SCode.PARTS(els2,nEqn2,inEqn2,nAlg2,inAlg2,inCons2,clats,externalDecl2);
//        compelt = SCode.CLASS(name2,prefixes2,encapsulatedPrefix2,partialPrefix2,restriction2,classDef,comment2,info2);
//        vis2 = SCode.prefixesVisibility(prefixes2);
//        elt = SCode.EXTENDS(Absyn.IDENT(name2),vis2,mods,NONE(),info1);
//        classDef = SCode.PARTS(elt::els1,nEqn1,inEqn1,nAlg1,inAlg1,inCons1,clats,externalDecl1);
//        elt = SCode.CLASS(name1, prefixes1, encapsulatedPrefix1, partialPrefix1, restriction1, classDef, comment1, info1);
//      then
//        (compelt, elt);
//
//    // found the base class which is derived
//    case (cl as SCode.CLASS(name = name2, classDef = SCode.DERIVED()), classExtendsElt)
//      equation
//        name1 = inClassExtendsEltName;
//        name2 = inBaseEltName;
//
//        SCode.CLASS(_,prefixes2,encapsulatedPrefix2,partialPrefix2,restriction2,SCode.DERIVED(derivedTySpec, derivedMod, attrs),comment2,info2) = cl;
//
//        SCode.CLASS(_, prefixes1, encapsulatedPrefix1, partialPrefix1, restriction1, classExtendsCdef, comment1, info1) = classExtendsElt;
//        SCode.CLASS_EXTENDS(_,mods,SCode.PARTS(els1,nEqn1,inEqn1,nAlg1,inAlg1,inCons1,_,externalDecl1)) = classExtendsCdef;
//
//        classDef = SCode.DERIVED(derivedTySpec, derivedMod, attrs);
//        compelt = SCode.CLASS(name2,prefixes2,encapsulatedPrefix2,partialPrefix2,restriction2,classDef,comment2,info2);
//        vis2 = SCode.prefixesVisibility(prefixes2);
//        elt = SCode.EXTENDS(Absyn.IDENT(name2),vis2,mods,NONE(),info1);
//        classDef = SCode.PARTS(elt::els1,nEqn1,inEqn1,nAlg1,inAlg1,inCons1,{},externalDecl1);
//        elt = SCode.CLASS(name1, prefixes1, encapsulatedPrefix1, partialPrefix1, restriction1, classDef, comment1, info1);
//      then
//        (compelt, elt);
//
//    // something went wrong!
//    else
//      equation
//        assert(false, getInstanceName() + " could not rename class extends base class to: " + inBaseEltName);
//      then
//        fail();
//
//  end matchcontinue;
//end patchBaseClassAndClassExtends;
//
//public function addRedeclareAsElementsToExtends
//"add the redeclare-as-element elements to extends"
//  input list<SCode.Element> inElements;
//  input list<SCode.Element> redeclareElements;
//  output list<SCode.Element> outExtendsElements;
//algorithm
//  outExtendsElements := matchcontinue (inElements, redeclareElements)
//    local
//      SCode.Element el;
//      list<SCode.Element> redecls, rest, out;
//      Absyn.Path baseClassPath;
//      SCode.Visibility visibility;
//      SCode.Mod mod;
//      Option<SCode.Annotation> ann "the extends annotation";
//      SourceInfo info;
//      SCode.Mod redeclareMod;
//      list<SCode.SubMod> submods;
//
//    // empty, return the same
//    case (_, {}) then inElements;
//
//    // empty elements
//    case ({}, _) then {};
//
//    // we got some
//    case (SCode.EXTENDS(baseClassPath, visibility, mod, ann, info)::rest, redecls)
//      equation
//        submods = makeElementsIntoSubMods(SCode.NOT_FINAL(), SCode.NOT_EACH(), redecls);
//        redeclareMod = SCode.MOD(SCode.NOT_FINAL(), SCode.NOT_EACH(), submods, NONE(), info);
//        mod = mergeSCodeMods(redeclareMod, mod);
//        out = addRedeclareAsElementsToExtends(rest, redecls);
//      then
//        SCode.EXTENDS(baseClassPath, visibility, mod, ann, info)::out;
//
//    // failure
//    case ((el as SCode.EXTENDS())::_, redecls)
//      equation
//        print("- SCodeUtil.addRedeclareAsElementsToExtends failed on:\nextends:\n\t" + SCodeDump.shortElementStr(el) +
//                 "\nredeclares:\n" + stringDelimitList(List.map1(redecls, SCodeDump.unparseElementStr, SCodeDump.defaultOptions), "\n") + "\n");
//      then
//        fail();
//
//    // ignore non-extends
//    case (el::rest, redecls)
//      equation
//        out = addRedeclareAsElementsToExtends(rest, redecls);
//      then
//        el::out;
//
//  end matchcontinue;
//end addRedeclareAsElementsToExtends;
//
//protected function mergeSCodeMods
//  input SCode.Mod inModOuter;
//  input SCode.Mod inModInner;
//  output SCode.Mod outMod;
//algorithm
//  outMod := matchcontinue(inModOuter, inModInner)
//    local
//      SCode.Final f1, f2;
//      SCode.Each e1, e2;
//      list<SCode.SubMod> subMods1, subMods2;
//      Option<Absyn.Exp> b1, b2;
//      SourceInfo info;
//
//    // inner is NOMOD
//    case (_, SCode.NOMOD()) then inModOuter;
//
//    // both are redeclarations
//    //case (SCode.REDECL(f1, e1, redecls), SCode.REDECL(f2, e2, els))
//    //  equation
//    //    els = listAppend(redecls, els);
//    //  then
//    //    SCode.REDECL(f2, e2, els);
//
//    // inner is mod
//    //case (SCode.REDECL(f1, e1, redecls), SCode.MOD(f2, e2, subMods, b, info))
//    //  equation
//    //    // we need to make each redcls element into a submod!
//    //    newSubMods = makeElementsIntoSubMods(f1, e1, redecls);
//    //    newSubMods = listAppend(newSubMods, subMods);
//    //  then
//    //    SCode.MOD(f2, e2, newSubMods, b, info);
//
//    case (SCode.MOD(f1, e1, subMods1, b1, info),
//          SCode.MOD(_, _, subMods2, b2, _))
//      equation
//        subMods2 = listAppend(subMods1, subMods2);
//        b1 = if isSome(b1) then b1 else b2;
//      then
//        SCode.MOD(f1, e1, subMods2, b1, info);
//
//    // failure
//    else
//      equation
//        print("SCodeUtil.mergeSCodeMods failed on:\nouterMod: " + SCodeDump.printModStr(inModOuter,SCodeDump.defaultOptions) +
//               "\ninnerMod: " + SCodeDump.printModStr(inModInner,SCodeDump.defaultOptions) + "\n");
//      then
//        fail();
//
//  end matchcontinue;
//end mergeSCodeMods;
//
//protected function makeElementsIntoSubMods
//"transform elements into submods with named mods"
//  input SCode.Final inFinal;
//  input SCode.Each inEach;
//  input list<SCode.Element> inElements;
//  output list<SCode.SubMod> outSubMods;
//algorithm
//  outSubMods := matchcontinue (inFinal, inEach, inElements)
//    local
//      SCode.Element el;
//      list<SCode.Element> rest;
//      SCode.Final f;
//      SCode.Each e;
//      SCode.Ident n;
//      list<SCode.SubMod> newSubMods;
//
//    // empty
//    case (_, _, {}) then {};
//
//    // component
//    case (f, e, (el as SCode.COMPONENT(name = n))::rest)
//      equation
//        // recurse
//        newSubMods = makeElementsIntoSubMods(f, e, rest);
//      then
//        SCode.NAMEMOD(n,SCode.REDECL(f,e,el))::newSubMods;
//
//    // class
//    case (f, e, (el as SCode.CLASS(name = n))::rest)
//      equation
//        // recurse
//        newSubMods = makeElementsIntoSubMods(f, e, rest);
//      then
//        SCode.NAMEMOD(n,SCode.REDECL(f,e,el))::newSubMods;
//
//    // rest
//    case (f, e, el::rest)
//      equation
//        // print an error here
//        print("- SCodeUtil.makeElementsIntoSubMods ignoring redeclare-as-element redeclaration: " + SCodeDump.unparseElementStr(el,SCodeDump.defaultOptions) + "\n");
//        // recurse
//        newSubMods = makeElementsIntoSubMods(f, e, rest);
//      then
//        newSubMods;
//  end matchcontinue;
//end makeElementsIntoSubMods;


annotation(__OpenModelica_Interface="frontend");
end NFExtend;
