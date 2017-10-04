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
import Dump;
import Error;
import Global;
import NFBuiltin;
import Inst = NFInst;
import NFClass.Class;
import NFInstNode.InstNode;
import NFLookupState.LookupState;
import Type = NFType;
import NFMod.Modifier;

protected
import NFInstNode.NodeTree;
import NFInstNode.CachedData;
import NFComponent.Component;

public
type MatchType = enumeration(FOUND, NOT_FOUND, PARTIAL);

function lookupClassName
  input Absyn.Path name;
  input InstNode scope;
  input SourceInfo info;
  output InstNode node;
protected
  LookupState state;
algorithm
  (node, state) := lookupNameWithError(name, scope, info, Error.LOOKUP_ERROR);
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
      {Absyn.pathString(name), InstNode.name(scope)}, info);
    fail();
  end try;

  LookupState.assertClass(state, listHead(nodes), name, info);
end lookupBaseClassName;

function lookupComponent
  input Absyn.ComponentRef cref;
  input InstNode scope "The scope to look in.";
  input SourceInfo info;
  output InstNode foundComponent "The component the cref resolves to.";
  output list<InstNode> restNodes "The rest of the found nodes.";
  output InstNode foundScope "The scope the first part of the cref was found in.";
protected
  LookupState state;
algorithm
  (foundComponent, restNodes, foundScope, state) := lookupCref(cref, scope, info);
  state := fixTypenameState(foundComponent, state);
  LookupState.assertComponent(state, foundComponent, cref, info);
end lookupComponent;

function fixTypenameState
  input InstNode component;
  input output LookupState state;
protected
  Type ty;
algorithm
  if InstNode.isClass(component) then
    ty := InstNode.getType(Inst.expand(component));

    state := match ty
      case Type.ENUMERATION() then LookupState.STATE_COMP();
      case Type.BOOLEAN() then LookupState.STATE_COMP();
      else state;
    end match;
  end if;
end fixTypenameState;

function lookupFunctionName
  input Absyn.ComponentRef cref;
  input InstNode scope "The scope to look in.";
  input SourceInfo info;
  output InstNode func;
  output list<InstNode> nodes;
  output InstNode foundScope;
protected
  LookupState state;
algorithm
  (func, nodes, foundScope, state) := lookupCref(cref, scope, info);
  LookupState.assertFunction(state, func, cref, info);
end lookupFunctionName;

function lookupImport
  input Absyn.Path name;
  input InstNode scope;
  input SourceInfo info;
  output InstNode element;
algorithm
  element := lookupNameWithError(name, InstNode.topScope(scope), info, Error.LOOKUP_IMPORT_ERROR);
end lookupImport;

function lookupCref
  "This function will look up a component reference in the given scope, and
   return a list of nodes that correspond to the parts of the cref in reverse
   order. I.e. when looking up the cref a.b.c, the list of nodes {c, b, a} will
   be returned. The scope where the first part of the cref was found will also
   be returned."
  input Absyn.ComponentRef cref;
  input InstNode scope "The scope to look in.";
  input SourceInfo info;
  output InstNode node "The node the cref refers to.";
  output list<InstNode> restNodes "The rest of the found nodes.";
  output InstNode foundScope "The scope where the first part of the cref was found.";
  output LookupState state;
protected
  MatchType match_ty;
  InstNode n;
algorithm
  // Check if the cref is one of the builtin types with reserved names.
  (node, restNodes, state, match_ty) := lookupBuiltinCref(cref, info);

  if match_ty == MatchType.NOT_FOUND then
    // The cref was not a reserved builtin name, continue with normal lookup.
    match_ty := MatchType.FOUND;

    (node, restNodes, foundScope, state) := matchcontinue cref
      local
        InstNode found_scope;

      case Absyn.ComponentRef.CREF_IDENT()
        algorithm
          (node, foundScope) := lookupSimpleCref(cref.name, scope);
          state := LookupState.nodeState(node);
        then
          (node, {node}, foundScope, state);

      case Absyn.ComponentRef.CREF_QUAL()
        algorithm
          (n, foundScope) := lookupSimpleCref(cref.name, scope);
          state := LookupState.nodeState(n);
          (node, restNodes, state) := lookupCrefInNode(cref.componentRef, n, state);
        then
          (node, n :: restNodes, foundScope, state);

      case Absyn.ComponentRef.CREF_FULLYQUALIFIED()
        then lookupCref(cref.componentRef, InstNode.topScope(scope), info);

      else
        algorithm
          match_ty := MatchType.NOT_FOUND;
        then
          (InstNode.EMPTY_NODE(), {}, scope, LookupState.STATE_BEGIN());
    end matchcontinue;
  else
    // The cref was one of the reserved builtin names defined in the top scope,
    // return the correct scope.
    foundScope := InstNode.topScope(scope);
  end if;

  if match_ty <> MatchType.FOUND then
    Error.addSourceMessage(Error.LOOKUP_VARIABLE_ERROR,
      {Dump.printComponentRefStr(cref), InstNode.name(scope)}, info);
    fail();
  end if;
end lookupCref;

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

      if InstNode.isInner(innerNode) then
        // Found an inner node, return it.
        return;
      else
        // Found a node that's not inner, give a warning and continue looking.
        Error.addMultiSourceMessage(Error.FOUND_NON_INNER,
          {name}, {InstNode.info(outerNode), InstNode.info(innerNode)});
        fail();
      end if;
    else
      // Continue looking in the instance parent's scope.
      prev_scope := cur_scope;
      cur_scope := InstNode.parent(cur_scope);
    end try;
  end while;

  // No inner found, try to generate one.
  innerNode := generateInner(outerNode, prev_scope);
end lookupInner;

function lookupBuiltinCref
  input Absyn.ComponentRef cref;
  input SourceInfo info;
  output InstNode node;
  output list<InstNode> restNodes;
  output LookupState state = LookupState.STATE_PREDEF_COMP();
  output MatchType matchType = MatchType.FOUND;
protected
  Absyn.Ident id;
  Absyn.ComponentRef cr;
algorithm
  cr := Absyn.unqualifyCref(cref);

  (node, restNodes) := match cr
    case Absyn.ComponentRef.CREF_IDENT()
      algorithm
        (node, state) := match cr.name
          case "time" then (NFBuiltin.TIME, LookupState.STATE_PREDEF_COMP());
          case "Boolean" then (NFBuiltin.BOOLEAN_TYPE_NODE, LookupState.STATE_PREDEF_CLASS());
          case "Integer" then (NFBuiltin.INT_TYPE_NODE, LookupState.STATE_FUNC());
          case "String" then (NFBuiltin.STRING_TYPE_NODE, LookupState.STATE_FUNC());
          case "StateSelect" then (NFBuiltin.STATESELECT_TYPE_NODE, LookupState.STATE_PREDEF_CLASS());
          else
            algorithm
              matchType := MatchType.NOT_FOUND;
            then
              (InstNode.EMPTY_NODE(), state);
        end match;
      then
        (node, {node});

    case Absyn.ComponentRef.CREF_QUAL()
      algorithm
        node := match cr.name
          case "StateSelect"
            algorithm
              node := match cr.componentRef
                case Absyn.CREF_IDENT(name = id)
                  then match id
                    case "never" then NFBuiltin.STATESELECT_NEVER;
                    case "avoid" then NFBuiltin.STATESELECT_AVOID;
                    case "default" then NFBuiltin.STATESELECT_DEFAULT;
                    case "prefer" then NFBuiltin.STATESELECT_PREFER;
                    case "always" then NFBuiltin.STATESELECT_ALWAYS;
                    else // Invalid StateSelect member.
                      algorithm
                        matchType := MatchType.PARTIAL;
                      then
                        InstNode.EMPTY_NODE();
                   end match;

                else // Invalid StateSelect form.
                  algorithm
                    matchType := MatchType.PARTIAL;
                  then
                    InstNode.EMPTY_NODE();
              end match;

              restNodes := {NFBuiltin.STATESELECT_TYPE_NODE, node};
            then
              node;

          else // Qualified name that's not a builtin name.
            algorithm
              matchType := MatchType.NOT_FOUND;
              restNodes := {};
            then
              InstNode.EMPTY_NODE();
        end match;
      then
        (node, restNodes);

  end match;
end lookupBuiltinCref;

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
      if name == InstNode.name(cur_scope) then
        node := cur_scope;
        return;
      else
        // Otherwise, continue in the enclosing scope.
        cur_scope := InstNode.parent(cur_scope);
      end if;
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
  output InstNode node;
  output LookupState state;
algorithm
  try
    (node, state) := lookupName(name, scope);
  else
    Error.addSourceMessage(errorType, {Absyn.pathString(name), InstNode.name(scope)}, info);
    fail();
  end try;
end lookupNameWithError;

function lookupName
  input Absyn.Path name;
  input InstNode scope;
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
        lookupLocalName(name.path, node, state, InstNode.refEqual(node, scope));

    // Fully qualified path, start from top scope.
    case Absyn.Path.FULLYQUALIFIED()
      then lookupName(name.path, InstNode.topScope(scope));

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
    state := LookupState.STATE_PREDEF_CLASS();
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
  input Boolean selfReference = false;
algorithm
  // Looking something up in a component is only legal when the name begins with
  // a component reference, and for that we use lookupCref. So if the given node
  // is a component we can immediately quit and give an error.
  if not InstNode.isClass(node) then
    state := LookupState.STATE_COMP_CLASS();
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
        state := LookupState.next(node, state);
      then
        ();

    case Absyn.Path.QUALIFIED()
      algorithm
        node := lookupLocalSimpleName(name.name, node);
        state := LookupState.next(node, state);
        (node, state) := lookupLocalName(name.path, node, state);
      then
        ();

    else
      algorithm
        assert(false, getInstanceName() + " was called with an invalid path.");
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
    state := LookupState.STATE_COMP_CLASS();
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
        assert(false, getInstanceName() + " was called with an invalid path.");
      then
        fail();
  end match;
end lookupLocalNames;

function lookupSimpleBuiltinName
  input String name;
  output InstNode builtin;
algorithm
  builtin := match name
    case "Real" then NFBuiltin.REAL_TYPE_NODE;
    case "Integer" then NFBuiltin.INT_TYPE_NODE;
    case "Boolean" then NFBuiltin.BOOLEAN_TYPE_NODE;
    case "String" then NFBuiltin.STRING_TYPE_NODE;
  end match;
end lookupSimpleBuiltinName;

function lookupSimpleCref
  "This function look up a simple name as a cref in a given component."
  input String name;
  input InstNode scope;
  output InstNode node;
  output InstNode foundScope = scope;
protected
  Class cls;
algorithm
  // Look for the name in the given scope, and if not found there continue
  // through the enclosing scopes of that scope until we either run out of
  // scopes or for some reason exceed the recursion depth limit.
  for i in 1:Global.recursionDepthLimit loop
    try
      node := match foundScope
        case InstNode.IMPLICIT_SCOPE()
          then lookupIterator(name, foundScope.locals);
        case InstNode.CLASS_NODE()
          then Class.lookupElement(name, InstNode.getClass(foundScope));
        case InstNode.COMPONENT_NODE()
          then Class.lookupElement(name, InstNode.getClass(foundScope));
        case InstNode.INNER_OUTER_NODE()
          then Class.lookupElement(name, InstNode.getClass(foundScope.innerNode));
      end match;

      // If the node is an outer node, return the inner instead.
      if InstNode.isInnerOuterNode(node) then
        node := InstNode.resolveInner(node);
        foundScope := InstNode.parent(node);
      end if;

      // We found a node, return it.
      return;
    else
      // Look in the next enclosing scope.
      // TODO: The enclosing scope here will be a package, so the lookup should
      //       be restricted to constants only.
      //foundScope := Inst.instPackage(InstNode.parentScope(foundScope));
      foundScope := InstNode.parentScope(foundScope);
    end try;
  end for;

  Error.addMessage(Error.RECURSION_DEPTH_REACHED,
    {String(Global.recursionDepthLimit), InstNode.name(foundScope)});
  fail();
end lookupSimpleCref;

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
  input output InstNode node;
        output list<InstNode> nodes;
  input output LookupState state;
protected
  Class scope;
  InstNode n;
algorithm
  if LookupState.isError(state) then
    return;
  end if;

  // TODO: If the node is a package and the cref is qualified, then we should
  // fully instantiate the node and not just expand it. Otherwise we can't look
  // up something like P.a.b where P is a package and a is a package constant,
  // since a will not be instantiated and thus we will fail when looking for b.
  scope := match node
    case InstNode.CLASS_NODE() then InstNode.getClass(Inst.instPackage(node));
    case InstNode.COMPONENT_NODE() then InstNode.getClass(node);
    case InstNode.INNER_OUTER_NODE() then InstNode.getClass(node.innerNode);
  end match;

  (node, nodes, state) := match cref
    case Absyn.ComponentRef.CREF_IDENT()
      algorithm
        node := Class.lookupElement(cref.name, scope);
        state := LookupState.next(node, state);
      then
        (node, {node}, state);

    case Absyn.ComponentRef.CREF_QUAL()
      algorithm
        n := Class.lookupElement(cref.name, scope);
        state := LookupState.next(n, state);
        (node, nodes, state) := lookupCrefInNode(cref.componentRef, n, state);
      then
        (node, n :: nodes, state);

  end match;
end lookupCrefInNode;

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
  cache := InstNode.cachedData(topScope);

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
          InstNode.setCachedData(cache, topScope);
        end if;
      then
        ();

    else
      algorithm
        assert(false, getInstanceName() + " got top node with missing cache");
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
                assert(false, getInstanceName() + " got unknown component");
              then
                fail();
          end match;
        then
          InstNode.replaceComponent(comp, node);

      else
        algorithm
          assert(false, getInstanceName() + " got unknown node");
        then
          fail();
  end match;
end makeInnerNode;

annotation(__OpenModelica_Interface="frontend");
end NFLookup;
