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

encapsulated package FResolve
" file:        FResolve.mo
  package:     FResolve
  description: Resolving of types paths, component references, class extends

  RCS: $Id: FResolve 18987 2014-02-05 16:24:53Z adrpo $

"

// public imports
public
import Absyn;
import FCore;
import FNode;
import FLookup;

protected
import SCode;
import FGraphBuild;
import List;
import ClassInf;

public
type Name = FCore.Name;
type Id = FCore.Id;
type Seq = FCore.Seq;
type Next = FCore.Next;
type Node = FCore.Node;
type Data = FCore.Data;
type Kind = FCore.Kind;
type Ref = FCore.Ref;
type Refs = FCore.Refs;
type Children = FCore.Children;
type Parents = FCore.Parents;
type ImportTable = FCore.ImportTable;
type Extra = FCore.Extra;
type Visited = FCore.Visited;
type Import = FCore.Import;
type Graph = FCore.Graph;

type Msg = Option<SourceInfo>;

public function ext
"@author: adrpo
 for all extends nodes lookup the type and add $ref nodes to the result"
  input Ref inRef;
  input Graph ig;
  output Graph og;
algorithm
  og := match(inRef, ig)
    local
      Refs refs;
      Graph g;

    case (_, g)
      equation
        // apply on all extends nodes
        g = FNode.apply1(inRef, ext_one, g);
      then
        g;

  end match;
end ext;

public function ext_one
"@author: adrpo
 helper"
  input Ref inRef;
  input Graph ig;
  output Graph og;
algorithm
  og := matchcontinue(inRef, ig)
    local
      Ref r, rr, rn, rc;
      Absyn.Path p;
      SCode.Element e;
      Node n;
      SourceInfo i;
      Graph g;

    // found extends that has a ref node
    case (r, g)
      equation
        true = FNode.isRefExtends(r);
        false = FNode.isRefDerived(r);
        // it does have a reference child already!
        true = FNode.isRefRefResolved(r);
      then
        g;

    // found extends
    case (r, g)
      equation
        true = FNode.isRefExtends(r);
        false = FNode.isRefDerived(r);
        FCore.EX(e = e) = FNode.refData(r);
        p = SCode.getBaseClassPath(e);
        _ = SCode.elementInfo(e);
        (g, rr) = FLookup.name(g, r, p, FLookup.ignoreNothing, FLookup.dummyLookupOption);
        g = FGraphBuild.mkRefNode(FNode.refNodeName, {rr}, r, g);
      then
        g;

    // not found ref
    case (r, g)
      equation
        true = FNode.isRefExtends(r);
        false = FNode.isRefDerived(r);
        FCore.EX(e = e) = FNode.refData(r);
        p = SCode.getBaseClassPath(e);
        _ = SCode.elementInfo(e);
        failure((_, _) = FLookup.name(g, r, p, FLookup.ignoreNothing, FLookup.dummyLookupOption));
        print("FResolve.ext_one: baseclass: " + Absyn.pathString(p) +
              " not found in: " + FNode.toPathStr(FNode.fromRef(r)) +"!\n");
        // put it in the graph as unresolved ref
        g = FGraphBuild.mkRefNode(FNode.refNodeName, {}, r, g);
      then
        g;

    else ig;

  end matchcontinue;
end ext_one;

public function derived
"@author: adrpo
 for all derived nodes lookup the type and add $ref nodes to the result"
  input Ref inRef;
  input Graph ig;
  output Graph og;
algorithm
  og := match(inRef, ig)
    local
      Refs refs;
      Graph g;

    case (_, g)
      equation
        // apply on all derived nodes
        g = FNode.apply1(inRef, derived_one, g);
      then
        g;

  end match;
end derived;

public function derived_one
"@author: adrpo
 helper"
  input Ref inRef;
  input Graph ig;
  output Graph og;
algorithm
  og := matchcontinue(inRef, ig)
    local
      Ref r, rr;
      Absyn.Path p;
      SCode.ClassDef d;
      Node n;
      SourceInfo i;
      Graph g;

    // found derived that has a ref node
    case (r, g)
      equation
        true = FNode.isRefDerived(r);
        // it does have a reference child already!
        true = FNode.isRefRefResolved(r);
      then
        g;

    // found derived
    case (r, g)
      equation
        true = FNode.isRefDerived(r);
        FCore.CL(e = SCode.CLASS(classDef = SCode.DERIVED(typeSpec = Absyn.TPATH(p, _)))) = FNode.refData(r);
        (g, rr) = FLookup.name(g, r, p, FLookup.ignoreNothing, FLookup.dummyLookupOption);
        g = FGraphBuild.mkRefNode(FNode.refNodeName, {rr}, r, g);
      then
        g;

    // not found ref
    case (r, g)
      equation
        true = FNode.isRefDerived(r);
        FCore.CL(e = SCode.CLASS(classDef = SCode.DERIVED(typeSpec = Absyn.TPATH(p, _)))) = FNode.refData(r);
        failure((_, _) = FLookup.name(g, r, p, FLookup.ignoreNothing, FLookup.dummyLookupOption));
        print("FResolve.derived_one: baseclass: " + Absyn.pathString(p) +
              " not found in: " + FNode.toPathStr(FNode.fromRef(r)) +"!\n");
        // put it in the graph as unresolved ref
        g = FGraphBuild.mkRefNode(FNode.refNodeName, {}, r, g);
      then
        g;

    else ig;

  end matchcontinue;
end derived_one;

public function ty
"@author: adrpo
 for all component nodes lookup the type and add $ref nodes to the result"
  input Ref inRef;
  input Graph ig;
  output Graph og;
algorithm
  og := match(inRef, ig)
    local
      Refs refs;
      Graph g;

    case (_, g)
      equation
        // apply to all component nodes
        g = FNode.apply1(inRef, ty_one, g);
      then
        g;

  end match;
end ty;

public function ty_one
"@author: adrpo
 helper"
  input Ref inRef;
  input Graph ig;
  output Graph og;
algorithm
  og := matchcontinue(inRef, ig)
    local
      Ref r, rr;
      Absyn.Path p;
      SCode.Element e;
      Node n;
      SourceInfo i;
      Graph g;

    // found component that has a ref node
    case (r, g)
      equation
        true = FNode.isRefComponent(r);
        // it does have a reference child already!
        true = FNode.isRefRefResolved(r);
      then
        g;

    // found component
    case (r, g)
      equation
        true = FNode.isRefComponent(r);
        FCore.CO(e = e) = FNode.refData(r);
        Absyn.TPATH(p, _) = SCode.getComponentTypeSpec(e);
        (g, rr) = FLookup.name(g, r, p, FLookup.ignoreNothing, FLookup.dummyLookupOption);
        // print("Resolving ty: " + Absyn.pathString(p) + " -> " + FNode.toStr(FNode.fromRef(rr)) + "\n");
        g = FGraphBuild.mkRefNode(FNode.refNodeName, {rr}, r, g);
      then
        g;

    // not found ref
    case (r, g)
      equation
        true = FNode.isRefComponent(r);
        FCore.CO(e = e) = FNode.refData(r);
        Absyn.TPATH(p, _) = SCode.getComponentTypeSpec(e);
        failure((_, _) = FLookup.name(g, r, p, FLookup.ignoreNothing, FLookup.dummyLookupOption));
        print("FResolve.ty_one: component type path: " + Absyn.pathString(p) +
              " not found in: " + FNode.toPathStr(FNode.fromRef(r)) +"!\n");
        // put it in the graph as unresolved ref
        g = FGraphBuild.mkRefNode(FNode.refNodeName, {}, r, g);
      then
        g;

    else ig;

  end matchcontinue;
end ty_one;

public function cc
"@author: adrpo
 for all constrained class nodes lookup the type and add $ref nodes to the result"
  input Ref inRef;
  input Graph ig;
  output Graph og;
algorithm
  og := match(inRef, ig)
    local
      Refs refs;
      Graph g;

    case (_, g)
      equation
        // apply on all constraintby nodes
        g = FNode.apply1(inRef, cc_one, g);
      then
        g;

  end match;
end cc;

public function cc_one
"@author: adrpo
 helper"
  input Ref inRef;
  input Graph ig;
  output Graph og;
algorithm
  og := matchcontinue(inRef, ig)
    local
      Ref r, rr;
      Absyn.Path p;
      SCode.Element e;
      Node n;
      SourceInfo i;
      Graph g;

    // found constraint class that has a ref node
    case (r, g)
      equation
        true = FNode.isRefConstrainClass(r);
        // it does have a reference child already!
        true = FNode.isRefRefResolved(r);
      then
        g;

    // found constraint class
    case (r, g)
      equation
        true = FNode.isRefConstrainClass(r);
        FCore.CC(SCode.CONSTRAINCLASS(constrainingClass = p)) = FNode.refData(r);
        (g, rr) = FLookup.name(g, r, p, FLookup.ignoreNothing, FLookup.dummyLookupOption);
        g = FGraphBuild.mkRefNode(FNode.refNodeName, {rr}, r, g);
      then
        g;

    // not found ref
    case (r, g)
      equation
        true = FNode.isRefConstrainClass(r);
        FCore.CC(SCode.CONSTRAINCLASS(constrainingClass = p)) = FNode.refData(r);
        failure((_, _) = FLookup.name(g, r, p, FLookup.ignoreNothing, FLookup.dummyLookupOption));
        print("FResolve.cc_one: constrained class: " + Absyn.pathString(p) +
              " not found in: " + FNode.toPathStr(FNode.fromRef(r)) +"!\n");
        // put it in the graph as unresolved ref
        g = FGraphBuild.mkRefNode(FNode.refNodeName, {}, r, g);
      then
        g;

    else ig;

  end matchcontinue;
end cc_one;

public function clsext
"@author: adrpo
 for all class extends nodes lookup the base class and add $ref nodes to the result"
  input Ref inRef;
  input Graph ig;
  output Graph og;
algorithm
  og := match(inRef, ig)
    local
      Refs refs;
      Graph g;

    case (_, g)
      equation
        // apply on all class extends nodes
        g = FNode.apply1(inRef, clsext_one, g);
      then
        g;

  end match;
end clsext;

public function clsext_one
"@author: adrpo
 helper"
  input Ref inRef;
  input Graph ig;
  output Graph og;
algorithm
  og := matchcontinue(inRef, ig)
    local
      Ref r, rr, p;
      SCode.Element e;
      Node n;
      SourceInfo i;
      Name id;
      Graph g;

    // found class extends that has a ref node
    case (r, g)
      equation
        true = FNode.isRefClassExtends(r);
        // it does have a reference child already!
        true = FNode.isRefRefResolved(r);
      then
        g;

    // found class extends
    case (r, g)
      equation
        true = FNode.isRefClassExtends(r);
        FCore.CL(e = SCode.CLASS(classDef = SCode.CLASS_EXTENDS(baseClassName = id))) = FNode.refData(r);
        // get the parent where the extends are!
        p::_ = FNode.parents(FNode.fromRef(r));
        // search ONLY in extends!
        (g, rr) = FLookup.ext(g, p, id, FLookup.ignoreParentsAndImports, FLookup.dummyLookupOption);
        g = FGraphBuild.mkRefNode(FNode.refNodeName, {rr}, r, g);
      then
        g;

    // not found ref
    case (r, g)
      equation
        true = FNode.isRefClassExtends(r);
        FCore.CL(e = SCode.CLASS(classDef = SCode.CLASS_EXTENDS(baseClassName = id))) = FNode.refData(r);
        // get the parent where the extends are!
        p::_ = FNode.parents(FNode.fromRef(r));
        // search ONLY in extends!
        failure((_, _) = FLookup.ext(g, p, id, FLookup.ignoreParentsAndImports, FLookup.dummyLookupOption));
        print("FResolve.clsext_one: class extends: " + id + " scope: " + FNode.toPathStr(FNode.fromRef(r)) +
              " not found in extends of: " + FNode.toPathStr(FNode.fromRef(p)) + ":\n");
        print("\t" + stringDelimitList(List.map(List.map(FNode.extendsRefs(p), FNode.fromRef), FNode.toPathStr), "\n\t") + "\n");
        // put it in the graph as unresolved ref
        g = FGraphBuild.mkRefNode(FNode.refNodeName, {}, r, g);
      then
        g;

    else ig;

  end matchcontinue;
end clsext_one;

public function cr
"@author: adrpo
 for all crefs lookup the cref node and add $ref nodes to the result"
  input Ref inRef;
  input Graph ig;
  output Graph og;
algorithm
  og := match(inRef, ig)
    local
      Refs refs;
      Graph g;

    case (_, g)
      equation
        // apply on all component reference nodes
        g = FNode.apply1(inRef, cr_one, g);
      then
        g;

  end match;
end cr;

public function cr_one
"@author: adrpo
 helper"
  input Ref inRef;
  input Graph ig;
  output Graph og;
algorithm
  og := matchcontinue(inRef, ig)
    local
      Ref r, rr;
      Absyn.ComponentRef cr;
      Node n;
      SourceInfo i;
      Graph g;


    // found cref that has a ref node
    case (r, g)
      equation
        true = FNode.isRefCref(r);
        // it does have a reference child already!
        true = FNode.isRefRefResolved(r);
      then
        g;

    // found cref
    case (r, g)
      equation
        true = FNode.isRefCref(r);
        FCore.CR(r = cr) = FNode.refData(r);
        (g, rr) = FLookup.cr(g, r, cr, FLookup.ignoreNothing, FLookup.dummyLookupOption); // SOME(Absyn.dummyInfo));
        g = FGraphBuild.mkRefNode(FNode.refNodeName, {rr}, r, g);
      then
        g;

    // not found ref
    case (r, g)
      equation
        true = FNode.isRefCref(r);
        FCore.CR(r = cr) = FNode.refData(r);
        failure((_, _) = FLookup.cr(g, r, cr, FLookup.ignoreNothing, FLookup.dummyLookupOption));
        print("FResolve.cr_one: component reference: " + Absyn.crefString(cr) +
              " not found in: " + FNode.toPathStr(FNode.fromRef(r)) +"!\n");
        // put it in the graph as unresolved ref
        g = FGraphBuild.mkRefNode(FNode.refNodeName, {}, r, g);
      then
        g;

    else ig;

  end matchcontinue;
end cr_one;

public function mod
"@author: adrpo
 for all mods lookup the modifier node and add $ref nodes to the result"
  input Ref inRef;
  input Graph ig;
  output Graph og;
algorithm
  og := match(inRef, ig)
    local
      Refs refs;
      Graph g;

    case (_, g)
      equation
        // apply on all modifier nodes
        g = FNode.apply1(inRef, mod_one, g);
      then
        g;

  end match;
end mod;

public function mod_one
"@author: adrpo
 helper"
  input Ref inRef;
  input Graph ig;
  output Graph og;
algorithm
  og := matchcontinue(inRef, ig)
    local
      Ref r, rr;
      Absyn.ComponentRef cr;
      Node n;
      SourceInfo i;
      Graph g;

    // found mod that has a ref node
    case (r, g)
      equation
        true = FNode.isRefMod(r) and
               (not FNode.isRefModHolder(r)) and
               (not ClassInf.isBasicTypeComponentName(FNode.refName(r)));
        // it does have a reference child already!
        true = FNode.isRefRefResolved(r);
      then
        g;

    // found mod
    case (r, g)
      equation
        true = FNode.isRefMod(r) and
               (not FNode.isRefModHolder(r)) and
               (not ClassInf.isBasicTypeComponentName(FNode.refName(r)));
        cr = Absyn.pathToCref(Absyn.stringListPath(FNode.namesUpToParentName(r, FNode.modNodeName)));
        (g, rr) = FLookup.cr(g, FNode.getModifierTarget(r), cr, FLookup.ignoreNothing, FLookup.dummyLookupOption); // SOME(Absyn.dummyInfo));
        g = FGraphBuild.mkRefNode(FNode.refNodeName, {rr}, r, g);
      then
        g;

    // not found mod
    case (r, g)
      equation
        true = FNode.isRefMod(r) and
               (not FNode.isRefModHolder(r)) and
               (not ClassInf.isBasicTypeComponentName(FNode.refName(r)));
        cr = Absyn.pathToCref(Absyn.stringListPath(FNode.namesUpToParentName(r, FNode.modNodeName)));
        failure((_, _) = FLookup.cr(g, FNode.getModifierTarget(r), cr, FLookup.ignoreNothing, FLookup.dummyLookupOption));
        print("FResolve.mod_one: modifier: " + Absyn.crefString(cr) +
              " not found in: " + FNode.toPathStr(FNode.fromRef(r)) +"!\n");
        // put it in the graph as unresolved ref
        g = FGraphBuild.mkRefNode(FNode.refNodeName, {}, r, g);
      then
        g;

    else ig;

  end matchcontinue;
end mod_one;

public function elred
"@author: adrpo
 for all redeclare as element lookup the base class and add $ref nodes to the result"
  input Ref inRef;
  input Graph ig;
  output Graph og;
algorithm
  og := match(inRef, ig)
    local
      Refs refs;
      Graph g;

    case (_, g)
      equation
        // apply on all class extends nodes
        g = FNode.apply1(inRef, elred_one, g);
      then
        g;

  end match;
end elred;

public function elred_one
"@author: adrpo
 helper"
  input Ref inRef;
  input Graph ig;
  output Graph og;
algorithm
  og := matchcontinue(inRef, ig)
    local
      Ref r, rr, p;
      SCode.Element e;
      Node n;
      SourceInfo i;
      Name id;
      Graph g;

    // found redeclare as element that has a ref node
    case (r, g)
      equation
        true = FNode.isRefRedeclare(r);
        true = (FNode.isRefClass(r) and (not FNode.isRefClassExtends(r))) or FNode.isRefComponent(r);
        // it does have a reference child already!
        true = FNode.isRefRefResolved(r);
      then
        g;

    // found redeclare as element
    case (r, g)
      equation
        true = FNode.isRefRedeclare(r);
        true = (FNode.isRefClass(r) and (not FNode.isRefClassExtends(r))) or FNode.isRefComponent(r);
        id = SCode.elementName(FNode.getElement(FNode.fromRef(r)));
        // get the parent where the extends are!
        p::_ = FNode.parents(FNode.fromRef(r));
        // search ONLY in extends!
        (g, rr) = FLookup.ext(g, p, id, FLookup.ignoreParentsAndImports, FLookup.dummyLookupOption);
        g = FGraphBuild.mkRefNode(FNode.refNodeName, {rr}, r, g);
      then
        g;

    // not found ref
    case (r, g)
      equation
        true = FNode.isRefRedeclare(r);
        true = (FNode.isRefClass(r) and (not FNode.isRefClassExtends(r))) or FNode.isRefComponent(r);
        id = SCode.elementName(FNode.getElement(FNode.fromRef(r)));
        // get the parent where the extends are!
        p::_ = FNode.parents(FNode.fromRef(r));
        // search ONLY in extends!
        failure((_, _) = FLookup.ext(g, p, id, FLookup.ignoreParentsAndImports, FLookup.dummyLookupOption));
        print("FResolve.elred_one: redeclare as element: " + id + " scope: " + FNode.toPathStr(FNode.fromRef(r)) +
              " not found in extends of: " + FNode.toPathStr(FNode.fromRef(p)) + ":\n");
        print("\t" + stringDelimitList(List.map(List.map(FNode.extendsRefs(p), FNode.fromRef), FNode.toPathStr), "\n\t") + "\n");
        // put it in the graph as unresolved ref
        g = FGraphBuild.mkRefNode(FNode.refNodeName, {}, r, g);
      then
        g;

    else ig;

  end matchcontinue;
end elred_one;

annotation(__OpenModelica_Interface="frontend");
end FResolve;
