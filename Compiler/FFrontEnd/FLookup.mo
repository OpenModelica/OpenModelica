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

encapsulated package FLookup
" file:        FLookup.mo
  package:     FLookup
  description: Scoping rules


"

public
import Absyn;
import FCore;
import FNode;

protected
import List;
import FGraph;
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
type Graph = FCore.Graph;
type Extra = FCore.Extra;
type Visited = FCore.Visited;
type Import = FCore.Import;
type Msg = Option<SourceInfo>;

constant Option<SourceInfo> dummyLookupOption = NONE(); // SOME(Absyn.dummyInfo);

public uniontype Options
  record OPTIONS
    Boolean ignoreImports;
    Boolean ignoreExtends;
    Boolean ignoreParents;
  end OPTIONS;
end Options;

public constant Options ignoreNothing = OPTIONS(false, false, false);
public constant Options ignoreParents = OPTIONS(false, false, true);
public constant Options ignoreParentsAndImports = OPTIONS(true, false, true);
public constant Options ignoreAll = OPTIONS(true, true, true);

public function id
"@author: adrpo
 search for id"
  input Graph inGraph;
  input Ref inRef;
  input Name inName;
  input Options inOptions;
  input Msg inMsg "Message flag, SOME() outputs lookup error messages";
  output Graph outGraph;
  output Ref outRef;
algorithm
  (outGraph, outRef) := matchcontinue(inGraph, inRef, inName, inOptions, inMsg)
    local
      Ref r;
      Parents p;
      Graph g;

    // implicit scope which has for iterators
    case (g, _, _, _, _)
      equation
        r = FNode.child(inRef, FNode.forNodeName);
        r = FNode.child(r, inName);
      then
        (g, r);

    /*/ self?
    case (g, _, _, _, _)
      equation
        true = FNode.isRefImplicitScope(inRef);
        true = stringEq(FNode.name(FNode.fromRef(inRef)), inName);
        r = FNode.child(inRef, inName);
        false = FNode.isRefImplicitScope(r);
      then
        (g, r);*/

    // implicit scope? move upwards if allowed
    case (g, _, _, OPTIONS(_, _, false), _)
      equation
        true = FNode.isRefImplicitScope(inRef);
        p = FNode.parents(FNode.fromRef(inRef));
        // get the original parent
        r = FNode.original(p);
        (g, r) = id(g, r, inName, inOptions, inMsg);
      then
        (g, r);

    // local?
    case (g, _, _, _, _)
      equation
        false = FNode.isRefImplicitScope(inRef);
        r = FNode.child(inRef, inName);
      then
        (g, r);

    // lookup in imports
    case (g, _, _, OPTIONS(false, _, _), _)
      equation
        false = FNode.isRefImplicitScope(inRef);
        (g, r) = imp(g, inRef, inName, inOptions, inMsg);
      then
        (g, r);

    // lookup in extends
    case (g, _, _, OPTIONS(_, false, _), _)
      equation
        false = FNode.isRefImplicitScope(inRef);
        (g, r) = ext(g, inRef, inName, inOptions, inMsg);
      then
        (g, r);

    // encapsulated
    case (g, _, _, OPTIONS(_, _, false), _)
      equation
        false = FNode.isRefImplicitScope(inRef);
        true = FNode.isEncapsulated(FNode.fromRef(inRef));
        r = FNode.top(inRef);
        (g, r) = id(g, r, inName, inOptions, inMsg);
      then
        (g, r);

    // search parent
    case (g, _, _, OPTIONS(_, _, false), _)
      equation
        false = FNode.isRefImplicitScope(inRef);
        false = FNode.isEncapsulated(FNode.fromRef(inRef));
        true = FNode.hasParents(FNode.fromRef(inRef));
        p = FNode.parents(FNode.fromRef(inRef));
        // get the original parent
        r = FNode.original(p);
        (g, r) = search(g, {r}, inName, inOptions, inMsg);
      then
        (g, r);

    // top node reached
    case (_, _, _, OPTIONS(_, _, false), _)
      equation
        false = FNode.hasParents(FNode.fromRef(inRef));
      then
        fail();

    // failure
    case (_, _, _, _, SOME(_))
      equation
        print("FLookup.id failed for: " + inName + " in: " + FNode.toPathStr(FNode.fromRef(inRef)) + "\n");
      then
        fail();

  end matchcontinue;
end id;

public function search
"@author: adrpo
 search for id in list"
  input Graph inGraph;
  input Refs inRefs;
  input Name inName;
  input Options inOptions;
  input Msg inMsg "Message flag, SOME() outputs lookup error messages";
  output Graph outGraph;
  output Ref outRef;
algorithm
  (outGraph, outRef) := matchcontinue(inGraph, inRefs, inName, inOptions, inMsg)
    local
      Ref r;
      Refs rest;
      Graph g;

    // not found
    case (_, {}, _, _, _) then fail();

    // found
    case (g, r::_, _, _, _)
      equation
        (g, r) = id(g, r, inName, inOptions, inMsg);
      then
        (g, r);

    // search rest
    case (g, _::rest, _, _, _)
      equation
        (g, r) = search(g, rest, inName, inOptions, inMsg);
      then
        (g, r);

    // failure
    case (_, _, _, _, SOME(_))
      equation
        print("FLookup.search failed for: " + inName + " in: " +
           FNode.toPathStr(FNode.fromRef(listHead(inRefs))) + "\n");
      then
        fail();

  end matchcontinue;
end search;

public function name
"@author: adrpo
 search for a name"
  input Graph inGraph;
  input Ref inRef;
  input Absyn.Path inPath;
  input Options inOptions;
  input Msg inMsg "Message flag, SOME() outputs lookup error messages";
  output Graph outGraph;
  output Ref outRef;
algorithm
  (outGraph, outRef) := matchcontinue(inGraph, inRef, inPath, inOptions, inMsg)
    local
      Ref r;
      Name i;
      Absyn.Path rest;
      String s;
      Graph g;

    // simple name
    case (g, _, Absyn.IDENT(i), _, _)
      equation
        (g, r) = id(g, inRef, i, inOptions, inMsg);
      then
        (g, r);

    // qualified name, could find the rest
    case (g, _, Absyn.QUALIFIED(i, rest), _, _)
      equation
        (g, r) = id(g, inRef, i, inOptions, inMsg);
        (g, r) = name(g, r, rest, inOptions, inMsg);
      then
        (g, r);

    // qualified name, could not find the rest, stop!
    case (g, _, Absyn.QUALIFIED(i, rest), _, _)
      equation
        (g, r) = id(g, inRef, i, inOptions, inMsg);
        failure((_, _) = name(g, r, rest, inOptions, inMsg));
        // add an assersion node that it should
        // be a name in here and return that
        s = "missing: " + Absyn.pathString(rest) + " in scope: " + FNode.toPathStr(FNode.fromRef(r));
        // make the assert node have the name of the missing path part
        (g, r) = FGraphBuild.mkAssertNode(Absyn.pathFirstIdent(rest), s, r, g);
      then
        (g, r);

    // fully qual name
    case (g, _, Absyn.FULLYQUALIFIED(rest), _, _)
      equation
        r = FNode.top(inRef);
        (g, r) = name(g, r, rest, inOptions, inMsg);
      then
        (g, r);

    case (_, _, _, _, SOME(_))
      equation
        print("FLookup.name failed for: " + Absyn.pathString(inPath) + " in: " + FNode.toPathStr(FNode.fromRef(inRef)) + "\n");
      then
        fail();

  end matchcontinue;
end name;

public function ext
"@author: adrpo
 search for id in extends"
  input Graph inGraph;
  input Ref inRef;
  input Name inName;
  input Options inOptions;
  input Msg inMsg "Message flag, SOME() outputs lookup error messages";
  output Graph outGraph;
  output Ref outRef;
algorithm
  (outGraph, outRef) := matchcontinue(inGraph, inRef, inName, inOptions, inMsg)
    local
      Ref r;
      Refs refs;
      Parents p;
      Graph g;

    // for class extends search inside the base class first
    case (g, _, _, _, _)
      equation
        true = FNode.isClassExtends(FNode.fromRef(inRef));
        // get its ref node
        r = FNode.child(inRef, FNode.refNodeName);
        // get the target from ref
        r = FNode.target(FNode.fromRef(r));
        // print("Searching for: " + inName + " in class extends target:\n\t" + FNode.toPathStr(FNode.fromRef(r)) + "\n");
        // search in type target
        (g, r) = id(g, r, inName, ignoreParents, inMsg);
        // print("Found it in: " + FNode.toPathStr(FNode.fromRef(r)) + "\n");
      then
        (g, r);

    // for class extends: if not found in base class search in the parents of this node
    case (g, _, _, _, _)
      equation
        true = FNode.isClassExtends(FNode.fromRef(inRef));
        // get the original parent
        r = FNode.original(FNode.parents(FNode.fromRef(inRef)));
        (g, r) = id(g, r, inName, ignoreNothing, inMsg);
        // print("Found it in: " + FNode.toPathStr(FNode.fromRef(r)) + "\n");
      then
        (g, r);

    // get all extends of the node and search in them
    case (g, _, _, _, _)
      equation
        refs = FNode.extendsRefs(inRef);
        false = listEmpty(refs);
        refs = List.map(List.map(refs, FNode.fromRef), FNode.target);
        // print("Searching for: " + inName + " in extends targets:\n\t" + stringDelimitList(List.map(List.map(refs, FNode.fromRef), FNode.toPathStr), "\n\t") + "\n");
        (g, r) = search(g, refs, inName, ignoreParentsAndImports, inMsg);
      then
        (g, r);

  end matchcontinue;
end ext;

public function imp
"@author: adrpo
 search for id in imports"
  input Graph inGraph;
  input Ref inRef;
  input Name inName;
  input Options inOptions;
  input Msg inMsg "Message flag, SOME() outputs lookup error messages";
  output Graph outGraph;
  output Ref outRef;
algorithm
  (outGraph, outRef) := matchcontinue(inGraph, inRef, inName, inOptions, inMsg)
    local
      Ref r;
      Parents p;
      list<Import> qi, uqi;
      Graph g;

    // lookup in qual
    case (g, _, _, _, _)
      equation
        true = FNode.hasImports(FNode.fromRef(inRef));
        (qi,_) = FNode.imports(FNode.fromRef(inRef));
        (g, r) = imp_qual(g, inRef, inName, qi, inOptions, inMsg);
      then
        (g, r);

    // lookup in un-qual
    case (g, _, _, _, _)
      equation
        true = FNode.hasImports(FNode.fromRef(inRef));
        (_, uqi) = FNode.imports(FNode.fromRef(inRef));
        (g, r) = imp_unqual(g, inRef, inName, uqi, inOptions, inMsg);
      then
        (g, r);

  end matchcontinue;
end imp;

protected function imp_qual
"Looks up a name through the qualified imports in a scope."
  input Graph inGraph;
  input Ref inRef;
  input Name inName;
  input list<Import> inImports;
  input Options inOptions;
  input Msg inMsg "Message flag, SOME() outputs lookup error messages";
  output Graph outGraph;
  output Ref outRef;
algorithm
  (outGraph, outRef) := matchcontinue(inGraph, inRef, inName, inImports, inOptions, inMsg)
    local
      Name name;
      Absyn.Path path;
      list<Import> rest_imps;
      Ref r;
      Graph g;

    // No match, search the rest of the list of imports.
    case (g, _, _, Absyn.NAMED_IMPORT(name = name) :: rest_imps, _, _)
      equation
        false = stringEqual(inName, name);
        (g, r) = imp_qual(g, inRef, inName, rest_imps, inOptions, inMsg);
      then
        (g, r);

    // Match, look up the fully qualified import path.
    case (g, _, _, Absyn.NAMED_IMPORT(name = name, path = path) :: _, _, _)
      equation
        true = stringEqual(inName, name);
        (g, r) = fq(g, path, inOptions, inMsg);
      then
        (g, r);

    // Partial match, return failure
    case (_, _, _, Absyn.NAMED_IMPORT(name = name) :: _, _, _)
      equation
        true = stringEqual(inName, name);
      then
        fail(); // TODO! maybe add an assertion node!

  end matchcontinue;
end imp_qual;

public function imp_unqual
  "Looks up a name through the qualified imports in a scope. If it finds the
  name it returns the item, path, and environment for the name, otherwise it
  fails."
  input Graph inGraph;
  input Ref inRef;
  input Name inName;
  input list<Import> inImports;
  input Options inOptions;
  input Msg inMsg "Message flag, SOME() outputs lookup error messages";
  output Graph outGraph;
  output Ref outRef;
algorithm
  (outGraph, outRef) := matchcontinue(inGraph, inRef, inName, inImports, inOptions, inMsg)
    local
      Absyn.Path path, path2;
      list<Import> rest_imps;
      Ref r;
      Graph g;

    // For each unqualified import we have to look up the package the import
    // points to, and then look among the public member of the package for the
    // name we are looking for.
    case (g, _, _, Absyn.UNQUAL_IMPORT(path = path) :: _, _, _)
      equation
        // Look up the import path.
        (g, r) = fq(g, path, inOptions, inMsg);
        // Look up the name among the public member of the found package.
        (g, r) = id(g, r, inName, ignoreParents, inMsg);
      then
        (g, r);

    // No match, continue with the rest of the imports.
    case (g, _, _, _ :: rest_imps, _, _)
      equation
        (g, r) = imp_unqual(g, inRef, inName, rest_imps, inOptions, inMsg);
      then
        (g, r);
  end matchcontinue;
end imp_unqual;

public function fq
"Looks up a fully qualified path in ref"
  input Graph inGraph;
  input Absyn.Path inName;
  input Options inOptions;
  input Msg inMsg "Message flag, SOME() outputs lookup error messages";
  output Graph outGraph;
  output Ref outRef;
algorithm
  (outGraph, outRef) := name(inGraph, FGraph.top(inGraph), inName, inOptions, inMsg);
end fq;

public function cr
"@author: adrpo
 search for a component reference"
  input Graph inGraph;
  input Ref inRef;
  input Absyn.ComponentRef inCref;
  input Options inOptions;
  input Msg inMsg "Message flag, SOME() outputs lookup error messages";
  output Graph outGraph;
  output Ref outRef;
algorithm
  (outGraph, outRef) := matchcontinue(inGraph, inRef, inCref, inOptions, inMsg)
    local
      Ref r;
      Name i;
      Absyn.ComponentRef rest;
      list<Absyn.Subscript> ss;
      Graph g;
      String s;

    // simple name
    case (g, _, Absyn.CREF_IDENT(i, _), _, _)
      equation
        (g, r) = id(g, inRef, i, inOptions, inMsg);
      then
        (g, r);

    // qualified name, first is component
    case (g, _, Absyn.CREF_QUAL(i, _, rest), _, _)
      equation
        (g, r) = id(g, inRef, i, inOptions, inMsg);
        // inRef is a component, lookup in type
        true = FNode.isRefComponent(r);
        // get the ref
        r = FNode.child(r, FNode.refNodeName);
        // get the target from ref
        r = FNode.target(FNode.fromRef(r));
        // search in type target
        (g, r) = cr(g, r, rest, ignoreParents, inMsg);
      then
        (g, r);

    // qualified name
    case (g, _, Absyn.CREF_QUAL(i, _, rest), _, _)
      equation
        // inRef is a class
        (g, r) = id(g, inRef, i, inOptions, inMsg);
        true = FNode.isRefClass(r);
        (g, r) = cr(g, r, rest, ignoreParents, inMsg);
      then
        (g, r);

    // qualified name
    case (g, _, Absyn.CREF_QUAL(i, _, rest), _, _)
      equation
        // inRef is a class
        (g, r) = id(g, inRef, i, inOptions, inMsg);
        true = FNode.isRefClass(r) or FNode.isRefComponent(r);
        // add an assersion node that it should
        // be a name in here and return that
        s = "missing: " + Absyn.crefString(rest) + " in scope: " + FNode.toPathStr(FNode.fromRef(r));
        // make the assert node have the name of the missing cref part
        (g, r) = FGraphBuild.mkAssertNode(Absyn.crefFirstIdent(rest), s, r, g);
      then
        (g, r);


    // fully qual name
    case (g, _, Absyn.CREF_FULLYQUALIFIED(rest), _, _)
      equation
        r = FGraph.top(g);
        (g, r) = cr(g, r, rest, inOptions, inMsg);
      then
        (g, r);

    case (_, _, _, _, SOME(_))
      equation
        print("FLookup.cr failed for: " + Absyn.crefString(inCref) + " in: " + FNode.toPathStr(FNode.fromRef(inRef)) + "\n");
      then
        fail();

  end matchcontinue;
end cr;

annotation(__OpenModelica_Interface="frontend");
end FLookup;
