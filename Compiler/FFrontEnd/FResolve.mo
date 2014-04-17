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
import FGraph;
import FLookup;

protected
import SCode;
import FGraphBuild;

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

type Msg = Option<Absyn.Info>;

constant Option<Absyn.Info> dummyLookupOption = NONE(); // SOME(Absyn.dummyInfo);

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
        g = FNode.apply1(inRef, ext_helper, g);
      then
        g;

  end match;
end ext;

protected function ext_helper
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
      Absyn.Info i;
      Graph g;

    // found ref
    case (r, g)
      equation
        true = FNode.isRefExtends(r);
        FCore.EX(e) = FNode.data(FNode.fromRef(r));
        p = SCode.getBaseClassPath(e);
        _ = SCode.elementInfo(e);
        rr = FLookup.name(r, p, FLookup.ignoreNothing, dummyLookupOption);
        g = FGraphBuild.mkRefNode(FNode.refNodeName, rr, r, g);
      then
        g;

    // not found ref
    case (r, g)
      equation
        true = FNode.isRefExtends(r);
        FCore.EX(e) = FNode.data(FNode.fromRef(r));
        p = SCode.getBaseClassPath(e);
        _ = SCode.elementInfo(e);
        failure(_ = FLookup.name(r, p, FLookup.ignoreNothing, dummyLookupOption));
        print("FResolve.ext_helper: baseclass " +& Absyn.pathString(p) +&
              " not found in: " +& FNode.toPathStr(FNode.fromRef(r)) +&"!\n");
      then
        g;

    else ig;

  end matchcontinue;
end ext_helper;

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
        g = FNode.apply1(inRef, derived_helper, g);
      then
        g;

  end match;
end derived;

protected function derived_helper
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
      Absyn.Info i;
      Graph g;

    // found ref
    case (r, g)
      equation
        true = FNode.isRefDerived(r);
        FCore.DE(d) = FNode.data(FNode.fromRef(r));
        SCode.DERIVED(typeSpec = Absyn.TPATH(p, _)) = d;
        rr = FLookup.name(r, p, FLookup.ignoreNothing, dummyLookupOption);
        g = FGraphBuild.mkRefNode(FNode.refNodeName, rr, r, g);
      then
        g;

    // not found ref
    case (r, g)
      equation
        true = FNode.isRefDerived(r);
        FCore.DE(d) = FNode.data(FNode.fromRef(r));
        SCode.DERIVED(typeSpec = Absyn.TPATH(p, _)) = d;
        failure(_ = FLookup.name(r, p, FLookup.ignoreNothing, dummyLookupOption));
        print("FResolve.derived_helper: baseclass " +& Absyn.pathString(p) +&
              " not found in: " +& FNode.toPathStr(FNode.fromRef(r)) +&"!\n");
      then
        g;

    else ig;

  end matchcontinue;
end derived_helper;

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
        g = FNode.apply1(inRef, ty_helper, g);
      then
        g;

  end match;
end ty;

protected function ty_helper
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
      Absyn.Info i;
      Graph g;

    // found ref
    case (r, g)
      equation
        true = FNode.isRefComponent(r);
        FCore.CO(e = e) = FNode.data(FNode.fromRef(r));
        Absyn.TPATH(p, _) = SCode.getComponentTypeSpec(e);
        rr = FLookup.name(r, p, FLookup.ignoreNothing, dummyLookupOption);
        // print("Resolving ty: " +& Absyn.pathString(p) +& " -> " +& FNode.toStr(FNode.fromRef(rr)) +& "\n");
        g = FGraphBuild.mkRefNode(FNode.refNodeName, rr, r, g);
      then
        g;

    // not found ref
    case (r, g)
      equation
        true = FNode.isRefComponent(r);
        FCore.CO(e = e) = FNode.data(FNode.fromRef(r));
        Absyn.TPATH(p, _) = SCode.getComponentTypeSpec(e);
        failure(_ = FLookup.name(r, p, FLookup.ignoreNothing, dummyLookupOption));
        print("FResolve.ty_helper: type path " +& Absyn.pathString(p) +&
              " not found in: " +& FNode.toPathStr(FNode.fromRef(r)) +&"!\n");
      then
        g;

    else ig;

  end matchcontinue;
end ty_helper;

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
        g = FNode.apply1(inRef, cc_helper, g);
      then
        g;

  end match;
end cc;

protected function cc_helper
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
      Absyn.Info i;
      Graph g;

    // found ref
    case (r, g)
      equation
        true = FNode.isRefConstrainClass(r);
        FCore.CC(SCode.CONSTRAINCLASS(constrainingClass = p)) = FNode.data(FNode.fromRef(r));
        rr = FLookup.name(r, p, FLookup.ignoreNothing, dummyLookupOption);
        g = FGraphBuild.mkRefNode(FNode.refNodeName, rr, r, g);
      then
        g;

    // not found ref
    case (r, g)
      equation
        true = FNode.isRefConstrainClass(r);
        FCore.CC(SCode.CONSTRAINCLASS(constrainingClass = p)) = FNode.data(FNode.fromRef(r));
        failure(_ = FLookup.name(r, p, FLookup.ignoreNothing, dummyLookupOption));
        print("FResolve.cc_helper: type path " +& Absyn.pathString(p) +&
              " not found in: " +& FNode.toPathStr(FNode.fromRef(r)) +&"!\n");
      then
        g;

    else ig;

  end matchcontinue;
end cc_helper;

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
        g = FNode.apply1(inRef, clsext_helper, g);
      then
        g;

  end match;
end clsext;

protected function clsext_helper
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
      Absyn.Info i;
      Name id;
      Graph g;

    // found ref
    case (r, g)
      equation
        true = FNode.isRefClassExtends(r);
        FCore.CL(e = SCode.CLASS(classDef = SCode.CLASS_EXTENDS(baseClassName = id))) = FNode.data(FNode.fromRef(r));
        // get the parent where the extends are!
        p::_ = FNode.parents(FNode.fromRef(r));
        // search ONLY in extends!
        rr = FLookup.ext(p, id, FLookup.ignoreParentsAndImports, dummyLookupOption);
        g = FGraphBuild.mkRefNode(FNode.refNodeName, rr, r, g);
      then
        g;

    // not found ref
    case (r, g)
      equation
        true = FNode.isRefClassExtends(r);
        FCore.CL(e = SCode.CLASS(classDef = SCode.CLASS_EXTENDS(baseClassName = id))) = FNode.data(FNode.fromRef(r));
        // get the parent where the extends are!
        p::_ = FNode.parents(FNode.fromRef(r));
        // search ONLY in extends!
        failure(_ = FLookup.ext(p, id, FLookup.ignoreParentsAndImports, dummyLookupOption));
        print("FResolve.clsext_helper: class extends " +& id +&
              " not found in extends of: " +& FNode.toPathStr(FNode.fromRef(r)) +&"!\n");
      then
        g;

    else ig;

  end matchcontinue;
end clsext_helper;

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
        // apply on all comopnent reference nodes
        g = FNode.apply1(inRef, cr_helper, g);
      then
        g;

  end match;
end cr;

protected function cr_helper
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
      Absyn.Info i;
      Graph g;

    // found ref
    case (r, g)
      equation
        true = FNode.isRefCref(r);
        FCore.CR(r = cr) = FNode.data(FNode.fromRef(r));
        rr = FLookup.cr(r, cr, FLookup.ignoreNothing, dummyLookupOption);
        g = FGraphBuild.mkRefNode(FNode.refNodeName, rr, r, g);
      then
        g;

    // not found ref
    case (r, g)
      equation
        true = FNode.isRefCref(r);
        FCore.CR(r = cr) = FNode.data(FNode.fromRef(r));
        failure(_ = FLookup.cr(r, cr, FLookup.ignoreNothing, dummyLookupOption));
        print("FResolve.cr_helper: component reference " +& Absyn.crefString(cr) +&
              " not found in: " +& FNode.toPathStr(FNode.fromRef(r)) +&"!\n");
      then
        g;

    else ig;

  end matchcontinue;
end cr_helper;

end FResolve;
