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

encapsulated package NFLookup
" file:        NFLookup.mo
  package:     NFLookup
  description: Lookup functions for NFInst
"

import Absyn;
import SCode;
import Dump;
import Error;
import Global;
import NFBuiltin;
import Inst = NFInst;
import NFClass.Class;
import NFInstNode.InstNode;
import NFLookupState.LookupState;
import Type = NFType;
import ComponentRef = NFComponentRef;

protected
import NFInstNode.NodeTree;
import NFInstNode.CachedData;
import NFComponent.Component;
import Subscript = NFSubscript;
import ComplexType = NFComplexType;
import Config;

public
type MatchType = enumeration(FOUND, NOT_FOUND, PARTIAL);

function lookupClassName
  input Absyn.Path name;
  input InstNode scope;
  input SourceInfo info;
  input Boolean checkAccessViolations = true;
  output InstNode node;
protected
  LookupState state;
algorithm
  (node, state) := lookupNameWithError(name, scope, info, Error.LOOKUP_ERROR, checkAccessViolations);
  LookupState.assertClass(state, node, name, info);
end lookupClassName;

function lookupBaseClassName
  input Absyn.Path name;
  input InstNode scope;
  input SourceInfo info;
  output list<InstNode> nodes;
protected
  LookupState state;
algorithm
  try
    (nodes, state) := lookupNames(name, scope);
  else
    Error.addSourceMessage(Error.LOOKUP_BASECLASS_ERROR,
      {Absyn.pathString(name), InstNode.scopeName(scope)}, info);
    fail();
  end try;

  LookupState.assertClass(state, listHead(nodes), name, info);
end lookupBaseClassName;

function lookupComponent
  input Absyn.ComponentRef cref;
  input InstNode scope "The scope to look in.";
  input SourceInfo info;
  output ComponentRef foundCref;
  output InstNode foundScope "The scope the cref was found in.";
protected
  LookupState state;
  InstNode node;
algorithm
  try
    (foundCref, foundScope, state) := lookupCref(cref, scope);
    node := ComponentRef.node(foundCref);
    false := InstNode.isName(node);
  else
    Error.addSourceMessageAndFail(Error.LOOKUP_VARIABLE_ERROR,
      {Dump.printComponentRefStr(cref), InstNode.scopeName(scope)}, info);
  end try;

  state := fixTypenameState(node, state);
  LookupState.assertComponent(state, node, cref, info);
end lookupComponent;

function lookupConnector
  input Absyn.ComponentRef cref;
  input InstNode scope "The scope to look in.";
  input SourceInfo info;
  output ComponentRef foundCref;
  output InstNode foundScope "The scope the cref was found in.";
protected
  LookupState state;
  InstNode node;
algorithm
  try
    (foundCref, foundScope, state) := lookupCref(cref, scope);
  else
    Error.addSourceMessageAndFail(Error.LOOKUP_VARIABLE_ERROR,
      {Dump.printComponentRefStr(cref), InstNode.scopeName(scope)}, info);
  end try;

  node := ComponentRef.node(foundCref);
  state := fixTypenameState(node, state);
  LookupState.assertComponent(state, node, cref, info);
end lookupConnector;

function fixTypenameState
  input InstNode component;
  input output LookupState state;
protected
  Type ty;
algorithm
  if InstNode.isClass(component) then
    ty := InstNode.getType(Inst.expand(component));

    state := match ty
      case Type.ENUMERATION() then LookupState.COMP();
      case Type.BOOLEAN() then LookupState.COMP();
      else state;
    end match;
  end if;
end fixTypenameState;

function lookupLocalComponent
  "Looks up a component in the local scope, without searching in any enclosing
   scopes. The found scope is returned since it can be different from the given
   scope in the case where the cref refers to an outer component."
  input Absyn.ComponentRef cref;
  input InstNode scope "The scope to look in.";
  input SourceInfo info;
  output ComponentRef foundCref;
  output InstNode foundScope "The scope the cref was found in.";
protected
  LookupState state;
  InstNode node;
algorithm
  (foundCref, foundScope, state) := lookupLocalCref(cref, scope, info);
  LookupState.assertComponent(state, ComponentRef.node(foundCref), cref, info);
end lookupLocalComponent;

function lookupFunctionName
  input Absyn.ComponentRef cref;
  input InstNode scope "The scope to look in.";
  input SourceInfo info;
  output ComponentRef foundCref;
  output InstNode foundScope;
protected
  LookupState state;
  InstNode node;
algorithm
  try
    (foundCref, foundScope, state) := lookupCref(cref, scope);
    node := ComponentRef.node(foundCref);
    false := InstNode.isName(node);
  else
    Error.addSourceMessageAndFail(Error.LOOKUP_FUNCTION_ERROR,
      {Dump.printComponentRefStr(cref), InstNode.scopeName(scope)}, info);
  end try;

  (foundCref, state) := fixExternalObjectCall(node, foundCref, state);
  LookupState.assertFunction(state, node, cref, info);
end lookupFunctionName;

function lookupFunctionNameSilent
  input Absyn.ComponentRef cref;
  input InstNode scope "The scope to look in.";
  output ComponentRef foundCref;
  output InstNode foundScope;
protected
  LookupState state;
  InstNode node;
algorithm
  (foundCref, foundScope, state) := lookupCref(cref, scope);
  node := ComponentRef.node(foundCref);
  (foundCref, state) := fixExternalObjectCall(node, foundCref, state);
  true := LookupState.isFunction(state, node);
end lookupFunctionNameSilent;

function fixExternalObjectCall
  "Changes calls to external objects so that the constructor is called instead,
   i.e. a call such as
     'ExtObj eo = ExtObj(...)'
   is changed to
     'ExtObj eo = ExtObj.constructor(...)'"
  input InstNode node;
  input output ComponentRef cref;
  input output LookupState state;
protected
  Class cls;
  InstNode constructor;
algorithm
  // If it's not a class it can't be an external object.
  if not LookupState.isClass(state) then
    return;
  end if;

  // External objects are identified by extending from ExternalObject, so the
  // node needs to be expanded before we know whether it's an external object or
  // not. Components are instantiated before their bindings, so in proper models
  // we shouldn't get any non-expanded external objects here. But to avoid
  // getting weird errors in erroneous models we make sure it's expanded anyway.
  Inst.expand(node);
  cls := InstNode.getClass(node);

  () := match cls
    case Class.PARTIAL_BUILTIN(ty = Type.COMPLEX(complexTy =
        ComplexType.EXTERNAL_OBJECT(constructor = constructor)))
      algorithm
        cref := ComponentRef.prefixCref(constructor, Type.UNKNOWN(), {}, cref);
        state := LookupState.FUNC();
      then
        ();

    else ();
  end match;
end fixExternalObjectCall;

function lookupImport
  input Absyn.Path name;
  input InstNode scope;
  input SourceInfo info;
  output InstNode element;
algorithm
  element := lookupNameWithError(name, InstNode.topScope(scope), info, Error.LOOKUP_IMPORT_ERROR);
end lookupImport;

function lookupCrefWithError
  input Absyn.ComponentRef cref;
  input InstNode scope;
  input SourceInfo info;
  input Error.Message errMsg;
  output ComponentRef foundCref;
  output InstNode foundScope;
  output LookupState state;
algorithm
  try
    (foundCref, foundScope, state) := lookupCref(cref, scope);
  else
    Error.addSourceMessage(errMsg,
      {Dump.printComponentRefStr(cref), InstNode.scopeName(scope)}, info);
    fail();
  end try;
end lookupCrefWithError;

function lookupCref
  "This function will look up an Absyn.ComponentRef in the given scope, and
   construct a ComponentRef from the found nodes. The scope where the first part
   of the cref was found will also be returned."
  input Absyn.ComponentRef cref;
  input InstNode scope "The scope to look in.";
  output ComponentRef foundCref;
  output InstNode foundScope "The scope where the first part of the cref was found.";
  output LookupState state;
protected
  InstNode node;
algorithm
  (foundCref, foundScope, state) := match cref
    case Absyn.ComponentRef.CREF_IDENT()
      algorithm
        (_, foundCref, foundScope, state) := lookupSimpleCref(cref.name, cref.subscripts, scope);
      then
        (foundCref, foundScope, state);

    case Absyn.ComponentRef.CREF_QUAL()
      algorithm
        (node, foundCref, foundScope, state) := lookupSimpleCref(cref.name, cref.subscripts, scope);
        (foundCref, foundScope, state) := lookupCrefInNode(cref.componentRef, node, foundCref, foundScope, state);
      then
        (foundCref, foundScope, state);

    case Absyn.ComponentRef.CREF_FULLYQUALIFIED()
      then lookupCref(cref.componentRef, InstNode.topScope(scope));

    case Absyn.ComponentRef.WILD()
      then (ComponentRef.WILD(), scope, LookupState.PREDEF_COMP());

    case Absyn.ComponentRef.ALLWILD()
      then (ComponentRef.WILD(), scope, LookupState.PREDEF_COMP());
  end match;
end lookupCref;

function lookupLocalCref
  "Looks up a cref in the local scope without going into any enclosing scopes."
  input Absyn.ComponentRef cref;
  input InstNode scope "The scope to look in.";
  input SourceInfo info;
  output ComponentRef foundCref;
  output InstNode foundScope "The scope where the first part of the cref was found.";
  output LookupState state;
protected
  MatchType match_ty;
  InstNode node;
algorithm
  (foundCref, foundScope, state) := matchcontinue cref
    local
      InstNode found_scope;

    case Absyn.ComponentRef.CREF_IDENT()
      algorithm
        (node, foundScope) := lookupLocalSimpleCref(cref.name, scope);
        state := LookupState.nodeState(node);
      then
        (ComponentRef.fromAbsyn(node, cref.subscripts), foundScope, state);

    case Absyn.ComponentRef.CREF_QUAL()
      algorithm
        (node, foundScope) := lookupLocalSimpleCref(cref.name, scope);
        state := LookupState.nodeState(node);
        foundCref := ComponentRef.fromAbsyn(node, cref.subscripts);
        (foundCref, foundScope, state) :=
          lookupCrefInNode(cref.componentRef, node, foundCref, foundScope, state);
      then
        (foundCref, foundScope, state);

    else
      algorithm
        Error.addSourceMessage(Error.LOOKUP_VARIABLE_ERROR,
          {Dump.printComponentRefStr(cref), InstNode.scopeName(scope)}, info);
      then
        fail();
  end matchcontinue;
end lookupLocalCref;

function lookupInner
  "Looks up the corresponding inner node given an outer node."
  input InstNode outerNode;
  input InstNode scope;
  output InstNode innerNode;
protected
  String name = InstNode.name(outerNode);
  InstNode cur_scope = scope;
  InstNode prev_scope = scope;
algorithm
  while not InstNode.isEmpty(cur_scope) loop
    try
      // Check if we have an element with the same name as the outer node in this scope.
      innerNode := InstNode.resolveOuter(Class.lookupElement(name, InstNode.getClass(cur_scope)));
      true := InstNode.isInner(innerNode);
      return;
    else
      // Continue looking in the instance parent's scope.
      prev_scope := cur_scope;
      cur_scope := InstNode.derivedParent(cur_scope);
    end try;
  end while;

  // No inner found, try to generate one.
  innerNode := generateInner(outerNode, prev_scope);
end lookupInner;

function lookupLocalSimpleName
  "Looks up a name in the given scope, without continuing the search in any
   enclosing scopes if the name isn't found."
  input String name;
  input InstNode scope;
  output InstNode node;
algorithm
  node := InstNode.resolveInner(Class.lookupElement(name, InstNode.getClass(scope)));
end lookupLocalSimpleName;

function lookupSimpleName
  input String name;
  input InstNode scope;
  output InstNode node;
protected
  InstNode cur_scope = scope;
algorithm
  // Look for the name in each enclosing scope, until it's either found or we
  // run out of scopes.
  for i in 1:Global.recursionDepthLimit loop
    try
      node := lookupLocalSimpleName(name, cur_scope);
      return;
    else
      // TODO: Handle encapsulated scopes.
      // If the scope has the same name as we're looking for we can just return it.
      if name == InstNode.name(cur_scope) and InstNode.isClass(cur_scope) then
        node := cur_scope;
        return;
      end if;

      // Otherwise, continue in the enclosing scope.
      cur_scope := InstNode.parentScope(cur_scope);
    end try;
  end for;

  Error.addMessage(Error.RECURSION_DEPTH_REACHED,
    {String(Global.recursionDepthLimit), InstNode.name(scope)});
  fail();
end lookupSimpleName;

function lookupNameWithError
  input Absyn.Path name;
  input InstNode scope;
  input SourceInfo info;
  input Error.Message errorType;
  input Boolean checkAccessViolations = true;
  output InstNode node;
  output LookupState state;
algorithm
  try
    (node, state) := lookupName(name, scope, checkAccessViolations);
  else
    Error.addSourceMessage(errorType, {Absyn.pathString(name), InstNode.scopeName(scope)}, info);
    fail();
  end try;
end lookupNameWithError;

function lookupName
  input Absyn.Path name;
  input InstNode scope;
  input Boolean checkAccessViolations;
  output InstNode node;
  output LookupState state;
algorithm
  (node, state) := match name
    // Simple name, look it up in the given scope.
    case Absyn.Path.IDENT()
      then lookupFirstIdent(name.name, scope);

    // Qualified name, look up first part in the given scope and look up the
    // rest of the name in the found element.
    case Absyn.Path.QUALIFIED()
      algorithm
        (node, state) := lookupFirstIdent(name.name, scope);
      then
        lookupLocalName(name.path, node, state, checkAccessViolations, InstNode.refEqual(node, scope));

    // Fully qualified path, start from top scope.
    case Absyn.Path.FULLYQUALIFIED()
      then lookupName(name.path, InstNode.topScope(scope), checkAccessViolations);

  end match;
end lookupName;

function lookupNames
  input Absyn.Path name;
  input InstNode scope;
  output list<InstNode> nodes;
  output LookupState state;
algorithm
  (nodes, state) := match name
    local
       InstNode node;

    // Simple name, look it up in the given scope.
    case Absyn.Path.IDENT()
      algorithm
        (node, state) := lookupFirstIdent(name.name, scope);
      then
        ({node}, state);

    // Qualified name, look up first part in the given scope and look up the
    // rest of the name in the found element.
    case Absyn.Path.QUALIFIED()
      algorithm
        (node, state) := lookupFirstIdent(name.name, scope);
      then
        lookupLocalNames(name.path, node, {node}, state, InstNode.refEqual(node, scope));

    // Fully qualified path, start from top scope.
    case Absyn.Path.FULLYQUALIFIED()
      then lookupNames(name.path, InstNode.topScope(scope));

  end match;
end lookupNames;

function lookupFirstIdent
  "Looks up the first part of a name."
  input String name;
  input InstNode scope;
  output InstNode node;
  output LookupState state;
algorithm
  try
    // Check if the name refers to a reserved builtin name.
    node := lookupSimpleBuiltinName(name);
    state := LookupState.PREDEF_CLASS();
  else
    // Otherwise, check each scope until the name is found.
    node := lookupSimpleName(name, scope);
    state := LookupState.nodeState(node);
  end try;
end lookupFirstIdent;

function lookupLocalName
  "Looks up a path in the given scope, without continuing the search in any
   enclosing scopes if the path isn't found."
  input Absyn.Path name;
  input output InstNode node;
  input output LookupState state;
  input Boolean checkAccessViolations = true;
  input Boolean selfReference = false;
algorithm
  // Looking something up in a component is only legal when the name begins with
  // a component reference, and for that we use lookupCref. So if the given node
  // is a component we can immediately quit and give an error.
  if not InstNode.isClass(node) then
    state := LookupState.COMP_CLASS();
    return;
  end if;

  if not selfReference then
    node := Inst.instPackage(node);
  end if;

  // Look up the path in the scope.
  () := match name
    case Absyn.Path.IDENT()
      algorithm
        node := lookupLocalSimpleName(name.name, node);
        state := LookupState.next(node, state, checkAccessViolations);
      then
        ();

    case Absyn.Path.QUALIFIED()
      algorithm
        node := lookupLocalSimpleName(name.name, node);
        state := LookupState.next(node, state, checkAccessViolations);
        (node, state) := lookupLocalName(name.path, node, state, checkAccessViolations);
      then
        ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " was called with an invalid path.", sourceInfo());
      then
        fail();
  end match;
end lookupLocalName;

function lookupLocalNames
  "Looks up a path in the given scope, without continuing the search in any
   enclosing scopes if the path isn't found."
  input Absyn.Path name;
  input InstNode scope;
  input output list<InstNode> nodes;
  input output LookupState state;
  input Boolean selfReference = false;
protected
  InstNode node = scope;
algorithm
  // Looking something up in a component is only legal when the name begins with
  // a component reference, and for that we use lookupCref. So if the given node
  // is a component we can immediately quit and give an error.
  if not InstNode.isClass(scope) then
    state := LookupState.COMP_CLASS();
    return;
  end if;

  // If the given node extends from itself, like 'extends Modelica.Icons.***' in
  // the MSL, then it's already being instantiated here.
  if not selfReference then
    node := Inst.instPackage(node);
  end if;

  // Look up the path in the scope.
  (nodes, state) := match name
    case Absyn.Path.IDENT()
      algorithm
        node := lookupLocalSimpleName(name.name, node);
        state := LookupState.next(node, state);
      then
        (node :: nodes, state);

    case Absyn.Path.QUALIFIED()
      algorithm
        node := lookupLocalSimpleName(name.name, node);
        state := LookupState.next(node, state);
      then
        lookupLocalNames(name.path, node, node :: nodes, state);

    else
      algorithm
        Error.assertion(false, getInstanceName() + " was called with an invalid path.", sourceInfo());
      then
        fail();
  end match;
end lookupLocalNames;

function lookupSimpleBuiltinName
  input String name;
  output InstNode builtin;
algorithm
  builtin := match name
    case "Real" then NFBuiltin.REAL_NODE;
    case "Integer" then NFBuiltin.INTEGER_NODE;
    case "Boolean" then NFBuiltin.BOOLEAN_NODE;
    case "String" then NFBuiltin.STRING_NODE;
    case "Clock" then NFBuiltin.CLOCK_NODE;
    case "polymorphic" then NFBuiltin.POLYMORPHIC_NODE;
  end match;
end lookupSimpleBuiltinName;

function lookupSimpleBuiltinCref
  input String name;
  input list<Absyn.Subscript> subs;
  output InstNode node;
  output ComponentRef cref;
  output LookupState state;
algorithm

  (node, cref, state) := match name
    case "time"
      then (NFBuiltin.TIME, NFBuiltin.TIME_CREF, LookupState.PREDEF_COMP());
    case "Boolean"
      then (NFBuiltin.BOOLEAN_NODE, NFBuiltin.BOOLEAN_CREF, LookupState.PREDEF_CLASS());
    case "Integer"
      then (NFBuiltinFuncs.INTEGER_NODE, NFBuiltinFuncs.INTEGER_CREF, LookupState.FUNC());
    case "String"
      then (NFBuiltinFuncs.STRING_NODE, NFBuiltinFuncs.STRING_CREF, LookupState.FUNC());
    case "Clock" guard Config.synchronousFeaturesAllowed()
      then (NFBuiltinFuncs.CLOCK_NODE, NFBuiltinFuncs.CLOCK_CREF, LookupState.FUNC());
  end match;

  if not listEmpty(subs) then
    cref := ComponentRef.setSubscripts(list(Subscript.RAW_SUBSCRIPT(s) for s in subs), cref);
  end if;
end lookupSimpleBuiltinCref;

function lookupSimpleCref
  "This function look up a simple name as a cref in a given component."
  input String name;
  input list<Absyn.Subscript> subs;
  input InstNode scope;
  output InstNode node;
  output ComponentRef cref;
  output InstNode foundScope = scope;
  output LookupState state;
protected
  Boolean is_import;
algorithm
  try
    (node, cref, state) := lookupSimpleBuiltinCref(name, subs);
    foundScope := InstNode.topScope(foundScope);
  else
    // Look for the name in the given scope, and if not found there continue
    // through the enclosing scopes of that scope until we either run out of
    // scopes or for some reason exceed the recursion depth limit.
    for i in 1:Global.recursionDepthLimit loop
      try
        (node, is_import) := match foundScope
          case InstNode.IMPLICIT_SCOPE()
            then (lookupIterator(name, foundScope.locals), false);
          case InstNode.CLASS_NODE()
            then Class.lookupElement(name, InstNode.getClass(foundScope));
          case InstNode.COMPONENT_NODE()
            then Class.lookupElement(name, InstNode.getClass(foundScope));
          case InstNode.INNER_OUTER_NODE()
            then Class.lookupElement(name, InstNode.getClass(foundScope.innerNode));
        end match;

        if is_import then
          foundScope := InstNode.parent(node);
        elseif InstNode.isInnerOuterNode(node) then
          // If the node is an outer node, return the inner instead.
          node := InstNode.resolveInner(node);
          foundScope := InstNode.parent(node);
        end if;

        // We found a node, return it.
        state := LookupState.nodeState(node);
        cref := ComponentRef.fromAbsyn(node, subs);
        return;
      else
        // Look in the next enclosing scope.
        foundScope := InstNode.parentScope(foundScope);
      end try;
    end for;

    Error.addMessage(Error.RECURSION_DEPTH_REACHED,
      {String(Global.recursionDepthLimit), InstNode.scopeName(foundScope)});
    fail();
  end try;
end lookupSimpleCref;

function lookupLocalSimpleCref
  "This function look up a simple name as a cref in a given component, without
   searching in any enclosing scope."
  input String name;
  input InstNode scope;
  output InstNode node;
  output InstNode foundScope = scope;
protected
  Boolean is_import;
algorithm
  (node, is_import) := match foundScope
    case InstNode.IMPLICIT_SCOPE()
      then (lookupIterator(name, foundScope.locals), false);
    case InstNode.CLASS_NODE()
      then Class.lookupElement(name, InstNode.getClass(foundScope));
    case InstNode.COMPONENT_NODE()
      then Class.lookupElement(name, InstNode.getClass(foundScope));
    case InstNode.INNER_OUTER_NODE()
      then Class.lookupElement(name, InstNode.getClass(foundScope.innerNode));
  end match;

  if is_import then
    foundScope := InstNode.parent(node);
  elseif InstNode.isInnerOuterNode(node) then
    // If the node is an outer node, return the inner instead.
    node := InstNode.resolveInner(node);
    foundScope := InstNode.parent(node);
  end if;
end lookupLocalSimpleCref;

function lookupIterator
  input String name;
  input list<InstNode> iterators;
  output InstNode iterator;
algorithm
  for i in iterators loop
    if name == InstNode.name(i) then
      iterator := i;
      return;
    end if;
  end for;

  fail();
end lookupIterator;

function lookupCrefInNode
  input Absyn.ComponentRef cref;
  input InstNode node;
  input output ComponentRef foundCref;
  input output InstNode foundScope;
  input output LookupState state;
protected
  InstNode scope;
  InstNode n;
  String name;
  Class cls;
algorithm
  if LookupState.isError(state) then
    return;
  end if;

  scope := match node
    case InstNode.CLASS_NODE() then Inst.instPackage(node);
    else node;
  end match;

  name := Absyn.crefFirstIdent(cref);
  cls := InstNode.getClass(scope);

  try
    n := Class.lookupElement(name, cls);
  else
    n := InstNode.NAME_NODE(name);
  end try;

  (n, foundCref, foundScope) := resolveInnerCref(n, foundCref, foundScope);
  state := LookupState.next(n, state);

  (foundCref, foundScope, state) := match cref
    case Absyn.ComponentRef.CREF_IDENT()
      then (ComponentRef.fromAbsyn(n, cref.subscripts, foundCref), foundScope, state);

    case Absyn.ComponentRef.CREF_QUAL()
      algorithm
        foundCref := ComponentRef.fromAbsyn(n, cref.subscripts, foundCref);
      then
        lookupCrefInNode(cref.componentRef, n, foundCref, foundScope, state);
  end match;
end lookupCrefInNode;

function resolveInnerCref
  "If given an outer node, resolves it to the corresponding inner node and
   collapses the given cref so that it refers to the correct node. The scope a
   cref is found in may also change if the inner is outside the scope found by
   lookupCref."
  input output InstNode node;
  input output ComponentRef cref;
  input output InstNode foundScope;
protected
  InstNode prev_node, scope;
algorithm
  if InstNode.isInnerOuterNode(node) then
    // Resolve the outer node to its inner.
    node := InstNode.resolveInner(node);
    scope := InstNode.parent(node);

    // Removes parts of the cref until it's either empty or we find the parent of
    // the inner node. I.e. if we have a.b.c.d.e where e is outer and the inner e
    // is declared in b, then we remove d and c and stop at b to get a.b.e.
    while not ComponentRef.isEmpty(cref) loop
      if referenceEq(ComponentRef.node(cref), scope) then
        break;
      else
        cref := ComponentRef.rest(cref);
      end if;
    end while;

    // If the cref is now empty it means the inner was declared outside the
    // scope we found the first part of the cref in, so the found scope is
    // replaced with the scope of the inner.
    if ComponentRef.isEmpty(cref) then
      foundScope := scope;
    end if;
  end if;
end resolveInnerCref;

function generateInner
  "Generates an inner element given an outer one, or returns the already
   generated inner element if one has already been generated."
  input InstNode outerNode;
  input InstNode topScope;
  output InstNode innerNode;
protected
  CachedData cache;
  String name;
  Option<InstNode> inner_node_opt;
  InstNode inner_node;
algorithm
  cache := InstNode.getInnerOuterCache(topScope);

  () := match cache
    case CachedData.TOP_SCOPE()
      algorithm
        name := InstNode.name(outerNode);
        inner_node_opt := NodeTree.getOpt(cache.addedInner, name);

        if isSome(inner_node_opt) then
          // Found an already generated node, return it.
          SOME(innerNode) := inner_node_opt;
        else
          // Otherwise, generate a new inner node and add it to the cache.
          innerNode := makeInnerNode(outerNode);
          innerNode := InstNode.setParent(cache.rootClass, innerNode);
          cache.addedInner := NodeTree.add(cache.addedInner, name, innerNode);
          InstNode.setInnerOuterCache(topScope, cache);
        end if;
      then
        ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got top node with missing cache", sourceInfo());
      then
        fail();

  end match;
end generateInner;

function makeInnerNode
  "Returns a copy of the given node where the element definition has been
   changed to have the inner prefix."
  input output InstNode node;
algorithm
  node := match node
    local
      SCode.Element def;
      SCode.Prefixes prefs;
      Component comp;

      case InstNode.CLASS_NODE(definition = def as SCode.CLASS(prefixes = prefs))
        algorithm
          prefs.innerOuter := Absyn.INNER();
          def.prefixes := prefs;
          node.definition := def;
        then
          node;

      case InstNode.COMPONENT_NODE()
        algorithm
          comp := InstNode.component(node);

          comp := match comp
            case Component.COMPONENT_DEF(definition = def as SCode.COMPONENT(prefixes = prefs))
              algorithm
                prefs.innerOuter := Absyn.INNER();
                def.prefixes := prefs;
                comp.definition := def;
              then
                comp;

            else
              algorithm
                Error.assertion(false, getInstanceName() + " got unknown component", sourceInfo());
              then
                fail();
          end match;
        then
          InstNode.replaceComponent(comp, node);

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown node", sourceInfo());
        then
          fail();
  end match;
end makeInnerNode;

annotation(__OpenModelica_Interface="frontend");
end NFLookup;
