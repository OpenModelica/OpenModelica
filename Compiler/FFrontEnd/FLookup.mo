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

  RCS: $Id: FLookup.mo 18328 2013-11-28 03:05:41Z vitalij $

"

public
import Absyn;
import FCore;
import FNode;
import FGraph;

protected
import List;

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
type Msg = Option<Absyn.Info>;

constant Option<Absyn.Info> dummyLookupOption = NONE(); // SOME(Absyn.dummyInfo);

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
  input Ref inRef;
  input Name inName;
  input Options inOptions;
  input Msg inMsg "Message flag, SOME() outputs lookup error messages";
  output Ref outRef;
algorithm
  outRef := matchcontinue(inRef, inName, inOptions, inMsg)
    local
      Ref r;
      Parents p;

    // implicit scope which has for iterators
    case (_, _, _, _)
      equation
        r = FNode.child(inRef, FNode.forNodeName);
        r = FNode.child(r, inName);
      then
        r;

    /*/ self?
    case (_, _, _, _)
      equation
        true = FNode.isRefImplicitScope(inRef);
        true = stringEq(FNode.name(FNode.fromRef(inRef)), inName);
        r = FNode.child(inRef, inName);
        false = FNode.isRefImplicitScope(r);
      then
        r;*/

    // implicit scope? move upwards
    case (_, _, _, _)
      equation
        true = FNode.isRefImplicitScope(inRef);
        p = FNode.parents(FNode.fromRef(inRef));
        // get the original parent
        r = FNode.original(p);
        r = id(r, inName, inOptions, inMsg);
      then
        r;

    // local?
    case (_, _, _, _)
      equation
        false = FNode.isRefImplicitScope(inRef);
        r = FNode.child(inRef, inName);
      then
        r;

    // lookup in imports
    case (_, _, OPTIONS(false, _, _), _)
      equation
        false = FNode.isRefImplicitScope(inRef);
        r = imp(inRef, inName, inOptions, inMsg);
      then
        r;

    // lookup in extends
    case (_, _, OPTIONS(_, false, _), _)
      equation
        false = FNode.isRefImplicitScope(inRef);
        r = ext(inRef, inName, inOptions, inMsg);
      then
        r;

    // encapsulated
    case (_, _, OPTIONS(_, _, false), _)
      equation
        false = FNode.isRefImplicitScope(inRef);
        true = FNode.isEncapsulated(FNode.fromRef(inRef));
        r = FNode.top(inRef);
        r = id(r, inName, inOptions, inMsg);
      then
        r;

    // search parent
    case (_, _, OPTIONS(_, _, false), _)
      equation
        false = FNode.isRefImplicitScope(inRef);
        false = FNode.isEncapsulated(FNode.fromRef(inRef));
        true = FNode.hasParents(FNode.fromRef(inRef));
        p = FNode.parents(FNode.fromRef(inRef));
        // get the original parent
        r = FNode.original(p);
        r = search({r}, inName, inOptions, inMsg);
      then
        r;

    // top node reached
    case (_, _, OPTIONS(_, _, false), _)
      equation
        false = FNode.hasParents(FNode.fromRef(inRef));
      then
        fail();

    // failure
    case (_, _, _, SOME(_))
      equation
        print("FLookup.id failed for: " +& inName +& " in: " +& FNode.toPathStr(FNode.fromRef(inRef)) +& "\n");
      then
        fail();

  end matchcontinue;
end id;

public function search
"@author: adrpo
 search for id in list"
  input Refs inRefs;
  input Name inName;
  input Options inOptions;
  input Msg inMsg "Message flag, SOME() outputs lookup error messages";
  output Ref outRef;
algorithm
  outRef := matchcontinue(inRefs, inName, inOptions, inMsg)
    local
      Ref r;
      Refs rest;

    // not found
    case ({}, _, _, _) then fail();

    // found
    case (r::_, _, _, _)
      equation
        r = id(r, inName, inOptions, inMsg);
      then
        r;

    // search rest
    case (_::rest, _, _, _)
      equation
        r = search(rest, inName, inOptions, inMsg);
      then
        r;

    // failure
    case (_, _, _, SOME(_))
      equation
        print("FLookup.search failed for: " +& inName +& " in: " +&
           FNode.toPathStr(FNode.fromRef(List.first(inRefs))) +& "\n");
      then
        fail();

  end matchcontinue;
end search;

public function name
"@author: adrpo
 search for a name"
  input Ref inRef;
  input Absyn.Path inPath;
  input Options inOptions;
  input Msg inMsg "Message flag, SOME() outputs lookup error messages";
  output Ref outRef;
algorithm
  outRef := matchcontinue(inRef, inPath, inOptions, inMsg)
    local
      Ref r;
      Name i;
      Absyn.Path rest;

    // simple name
    case (_, Absyn.IDENT(i), _, _)
      equation
        r = id(inRef, i, inOptions, inMsg);
      then
        r;

    // qualified name
    case (_, Absyn.QUALIFIED(i, rest), _, _)
      equation
        r = id(inRef, i, inOptions, inMsg);
        r = name(r, rest, inOptions, inMsg);
      then
        r;

    // fully qual name
    case (_, Absyn.FULLYQUALIFIED(rest), _, _)
      equation
        r = FNode.top(inRef);
        r = name(r, rest, inOptions, inMsg);
      then
        r;

    case (_, _, _, SOME(_))
      equation
        print("FLookup.name failed for: " +& Absyn.pathString(inPath) +& " in: " +& FNode.toPathStr(FNode.fromRef(inRef)) +& "\n");
      then
        fail();

  end matchcontinue;
end name;

public function ext
"@author: adrpo
 search for id in extends"
  input Ref inRef;
  input Name inName;
  input Options inOptions;
  input Msg inMsg "Message flag, SOME() outputs lookup error messages";
  output Ref outRef;
algorithm
  outRef := matchcontinue(inRef, inName, inOptions, inMsg)
    local
      Ref r;
      Refs refs;
      Parents p;

    // for class extends we're searching inside the base class also!
    case (_, _, _, _)
      equation
        true = FNode.isClassExtends(FNode.fromRef(inRef));
        // get its ref node
        r = FNode.child(inRef, FNode.refNodeName);
        // get the target from ref
        r = FNode.target(FNode.fromRef(r));
        // print("Searching for: " +& inName +& " in class extends target:\n\t" +& FNode.toPathStr(FNode.fromRef(r)) +& "\n");
        // search in type target
        r = id(r, inName, ignoreParentsAndImports, inMsg);
        // print("Found it in: " +& FNode.toPathStr(FNode.fromRef(r)) +& "\n");
      then
        r;

    // get all extends of the node and search in them
    case (_, _, _, _)
      equation
        refs = FNode.extendsRefs(inRef);
        true = List.isNotEmpty(refs);
        refs = List.map(List.map(refs, FNode.fromRef), FNode.target);
        // print("Searching for: " +& inName +& " in extends targets:\n\t" +& stringDelimitList(List.map(List.map(refs, FNode.fromRef), FNode.toPathStr), "\n\t") +& "\n");
        r = search(refs, inName, ignoreParentsAndImports, inMsg);
      then
        r;

  end matchcontinue;
end ext;

public function imp
"@author: adrpo
 search for id in imports"
  input Ref inRef;
  input Name inName;
  input Options inOptions;
  input Msg inMsg "Message flag, SOME() outputs lookup error messages";
  output Ref outRef;
algorithm
  outRef := matchcontinue(inRef, inName, inOptions, inMsg)
    local
      Ref r;
      Parents p;
      list<Import> qi, uqi;

    // lookup in qual
    case (_, _, _, _)
      equation
        true = FNode.hasImports(FNode.fromRef(inRef));
        (qi,_) = FNode.imports(FNode.fromRef(inRef));
        r = imp_qual(inRef, inName, qi, inOptions, inMsg);
      then
        r;

    // lookup in un-qual
    case (_, _, _, _)
      equation
        true = FNode.hasImports(FNode.fromRef(inRef));
        (_, uqi) = FNode.imports(FNode.fromRef(inRef));
        r = imp_unqual(inRef, inName, uqi, inOptions, inMsg);
      then
        r;

  end matchcontinue;
end imp;

protected function imp_qual
"Looks up a name through the qualified imports in a scope."
  input Ref inRef;
  input Name inName;
  input list<Import> inImports;
  input Options inOptions;
  input Msg inMsg "Message flag, SOME() outputs lookup error messages";
  output Ref outRef;
algorithm
  outRef := matchcontinue(inRef, inName, inImports, inOptions, inMsg)
    local
      Name name;
      Absyn.Path path;
      list<Import> rest_imps;
      Ref r;

    // No match, search the rest of the list of imports.
    case (_, _, Absyn.NAMED_IMPORT(name = name) :: rest_imps, _, _)
      equation
        false = stringEqual(inName, name);
        r = imp_qual(inRef, inName, rest_imps, inOptions, inMsg);
      then
        r;

    // Match, look up the fully qualified import path.
    case (_, _, Absyn.NAMED_IMPORT(name = name, path = path) :: _, _, _)
      equation
        true = stringEqual(inName, name);
        r = fq(inRef, path, inOptions, inMsg);
      then
        r;

    // Partial match, return failure
    case (_, _, Absyn.NAMED_IMPORT(name = name) :: _, _, _)
      equation
        true = stringEqual(inName, name);
      then
        fail();

  end matchcontinue;
end imp_qual;

public function imp_unqual
  "Looks up a name through the qualified imports in a scope. If it finds the
  name it returns the item, path, and environment for the name, otherwise it
  fails."
  input Ref inRef;
  input Name inName;
  input list<Import> inImports;
  input Options inOptions;
  input Msg inMsg "Message flag, SOME() outputs lookup error messages";
  output Ref outRef;
algorithm
  outRef := matchcontinue(inRef, inName, inImports, inOptions, inMsg)
    local
      Absyn.Path path, path2;
      list<Import> rest_imps;
      Ref r;

    // For each unqualified import we have to look up the package the import
    // points to, and then look among the public member of the package for the
    // name we are looking for.
    case (_, _, Absyn.UNQUAL_IMPORT(path = path) :: _, _, _)
      equation
        // Look up the import path.
        r = fq(inRef, path, inOptions, inMsg);
        // Look up the name among the public member of the found package.
        r = id(r, inName, ignoreParents, inMsg);
      then
        r;

    // No match, continue with the rest of the imports.
    case (_, _, _ :: rest_imps, _, _)
      equation
        r = imp_unqual(inRef, inName, rest_imps, inOptions, inMsg);
      then
        r;
  end matchcontinue;
end imp_unqual;

public function fq
"Looks up a fully qualified path in ref"
  input Ref inRef;
  input Absyn.Path inName;
  input Options inOptions;
  input Msg inMsg "Message flag, SOME() outputs lookup error messages";
  output Ref outRef;
algorithm
  outRef := name(FNode.top(inRef), inName, inOptions, inMsg);
end fq;

public function cr
"@author: adrpo
 search for a component reference"
  input Ref inRef;
  input Absyn.ComponentRef inCref;
  input Options inOptions;
  input Msg inMsg "Message flag, SOME() outputs lookup error messages";
  output Ref outRef;
algorithm
  outRef := matchcontinue(inRef, inCref, inOptions, inMsg)
    local
      Ref r;
      Name i;
      Absyn.ComponentRef rest;
      list<Absyn.Subscript> ss;

    // simple name
    case (_, Absyn.CREF_IDENT(i, _), _, _)
      equation
        r = id(inRef, i, inOptions, inMsg);
      then
        r;

    // qualified name, first is component
    case (_, Absyn.CREF_QUAL(i, _, rest), _, _)
      equation
        r = id(inRef, i, inOptions, inMsg);
        // inRef is a component, lookup in type
        true = FNode.isRefComponent(r);
        // get the ref
        r = FNode.child(r, FNode.refNodeName);
        // get the target from ref
        r = FNode.target(FNode.fromRef(r));
        // search in type target
        r = cr(r, rest, inOptions, inMsg);
      then
        r;

    // qualified name
    case (_, Absyn.CREF_QUAL(i, _, rest), _, _)
      equation
        // inRef is a class
        r = id(inRef, i, inOptions, inMsg);
        true = FNode.isRefClass(r);
        r = cr(r, rest, inOptions, inMsg);
      then
        r;

    // fully qual name
    case (_, Absyn.CREF_FULLYQUALIFIED(rest), _, _)
      equation
        r = FNode.top(inRef);
        r = cr(r, rest, inOptions, inMsg);
      then
        r;

    case (_, _, _, SOME(_))
      equation
        print("FLookup.cr failed for: " +& Absyn.crefString(inCref) +& " in: " +& FNode.toPathStr(FNode.fromRef(inRef)) +& "\n");
      then
        fail();

  end matchcontinue;
end cr;

end FLookup;

