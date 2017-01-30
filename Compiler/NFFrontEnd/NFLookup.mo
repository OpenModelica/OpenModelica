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
import NFPrefix.Prefix;
import Type = NFType;

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
  output InstNode node;
protected
  LookupState state;
algorithm
  (node, state) := lookupNameWithError(name, scope, info, Error.LOOKUP_BASECLASS_ERROR);
  LookupState.assertClass(state, node, name, info);
end lookupBaseClassName;

function lookupComponent
  input Absyn.ComponentRef cref;
  input InstNode scope "The scope to look in.";
  input SourceInfo info;
  input Boolean allowTypename = false;
  output InstNode foundComponent "The component the cref resolves to.";
  output Prefix prefix;
protected
  LookupState state;
algorithm
  (foundComponent, prefix, state) := lookupCref(cref, scope, info);

  if allowTypename then
    state := fixTypenameState(foundComponent, state);
  end if;

  LookupState.assertComponent(state, foundComponent, cref, info);
end lookupComponent;

function fixTypenameState
  input InstNode component;
  input output LookupState state;
protected
  Type ty;
algorithm
  if InstNode.isClass(component) then
    ty := Class.getType(InstNode.getClass(component));

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
  output Prefix prefix;
protected
  LookupState state;
algorithm
  (func, prefix, state) := lookupCref(cref, scope, info);
  LookupState.assertFunction(state, func, cref, info);
end lookupFunctionName;

function lookupCref
  input Absyn.ComponentRef cref;
  input InstNode scope "The scope to look in.";
  input SourceInfo info;
  output InstNode node;
  output Prefix prefix;
  output LookupState state;
protected
  MatchType match_ty;
algorithm
  (node, prefix, state, match_ty) := lookupBuiltinCref(cref, info);

  if match_ty == MatchType.NOT_FOUND then
    match_ty := MatchType.FOUND;

    (node, prefix, state) := matchcontinue cref
      local
        Class.Element element;
        InstNode found_scope;

      case Absyn.ComponentRef.CREF_IDENT()
        algorithm
          (node, prefix) := lookupSimpleCref(cref.name, scope);
          state := LookupState.nodeState(node);
        then
          (node, prefix, state);

      case Absyn.ComponentRef.CREF_QUAL()
        algorithm
          (node, prefix) := lookupSimpleCref(cref.name, scope);
          state := LookupState.nodeState(node);
          (node, state) := lookupCrefInNode(cref.componentRef, node, state);
        then
          (node, prefix, state);

      case Absyn.ComponentRef.CREF_FULLYQUALIFIED()
        then lookupCref(cref.componentRef, InstNode.topComponent(scope), info);

      else
        algorithm
          match_ty := MatchType.NOT_FOUND;
        then
          (InstNode.EMPTY_NODE(), Prefix.NO_PREFIX(), LookupState.STATE_BEGIN());
    end matchcontinue;
  end if;

  if match_ty <> MatchType.FOUND then
    Error.addSourceMessage(Error.LOOKUP_VARIABLE_ERROR,
      {Dump.printComponentRefStr(cref), InstNode.name(scope)}, info);
    fail();
  end if;
end lookupCref;

protected

function lookupBuiltinCref
  input Absyn.ComponentRef cref;
  input SourceInfo info;
  output InstNode node;
  output Prefix prefix = Prefix.NO_PREFIX();
  output LookupState state = LookupState.STATE_PREDEF_COMP();
  output MatchType matchType = MatchType.FOUND;
protected
  Absyn.Ident id;
  Absyn.ComponentRef cr;
algorithm
  cr := Absyn.unqualifyCref(cref);

  node := match cr
    local

    case Absyn.ComponentRef.CREF_IDENT()
      then match cr.name
        case "time" then NFBuiltin.TIME;
        case "Boolean" then NFBuiltin.BOOLEAN_TYPE;
        case "StateSelect" then NFBuiltin.STATESELECT_TYPE;
        else algorithm matchType := MatchType.NOT_FOUND; then InstNode.EMPTY_NODE();
      end match;

    case Absyn.ComponentRef.CREF_QUAL()
      then match cr.name
        case "StateSelect"
          then match cr.componentRef
            case Absyn.CREF_IDENT(name = id)
              then match id
                case "never" then NFBuiltin.STATESELECT_NEVER;
                case "avoid" then NFBuiltin.STATESELECT_AVOID;
                case "default" then NFBuiltin.STATESELECT_DEFAULT;
                case "prefer" then NFBuiltin.STATESELECT_PREFER;
                case "always" then NFBuiltin.STATESELECT_ALWAYS;
                // Invalid StateSelect member.
                else algorithm matchType := MatchType.PARTIAL; then InstNode.EMPTY_NODE();
              end match;

            // Invalid StateSelect form.
            else algorithm matchType := MatchType.PARTIAL; then InstNode.EMPTY_NODE();
          end match;

        // Qualified name that's not a builtin name.
        else algorithm matchType := MatchType.NOT_FOUND; then InstNode.EMPTY_NODE();
      end match;

  end match;
end lookupBuiltinCref;

function lookupLocalSimpleName
  "Looks up a name in the given scope, without continuing the search in any
   enclosing scopes if the name isn't found."
  input String name;
  input InstNode scope;
  output InstNode node;
algorithm
  node := Class.lookupElement(name, InstNode.getClass(scope));
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
      cur_scope := InstNode.parent(cur_scope);
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
    Error.addSourceMessage(errorType, {Absyn.pathString(name), "<unknown>"}, info);
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
        lookupLocalName(name.path, node, state);

    // Fully qualified path, start from top scope.
    case Absyn.Path.FULLYQUALIFIED()
      then lookupName(name.path, InstNode.topScope(scope));

  end match;
end lookupName;

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
algorithm
  // We're looking for a class, which is not legal to look up inside of a
  // component.
  () := match node
    case InstNode.CLASS_NODE() then ();
    else
      algorithm
        state := LookupState.STATE_COMP_CLASS();
        return;
      then
        ();
  end match;

  // Make sure the scope is expanded so that we can do lookup in it.
  node := Inst.expand(node);

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

function lookupSimpleBuiltinName
  input String name;
  output InstNode builtin;
algorithm
  builtin := match name
    case "Real" then NFBuiltin.REAL_TYPE;
    case "Integer" then NFBuiltin.INT_TYPE;
    case "Boolean" then NFBuiltin.BOOLEAN_TYPE;
    case "String" then NFBuiltin.STRING_TYPE;
  end match;
end lookupSimpleBuiltinName;

function lookupSimpleCref
  "This function look up a simple name as a cref in a given component."
  input String name;
  input InstNode scope;
  output InstNode node;
  output Prefix prefix;
protected
  InstNode foundScope = scope;
  Class cls;
  Class.Element e;
algorithm
  // Look for the name in the given scope, and if not found there continue
  // through the enclosing scopes of that scope until we either run out of
  // scopes or for some reason exceed the recursion depth limit.
  for i in 1:Global.recursionDepthLimit loop
    try
      // Check if the cref can be found in the current scope.
      cls := InstNode.getClass(foundScope);
      node := Class.lookupElement(name, cls);

      // We found it, build the prefix for the found cref.
      if i == 1 then
        prefix := InstNode.prefix(scope);
      else
        prefix := InstNode.prefix(foundScope);
      end if;

      // We're done here.
      return;
    else
      // Look in the next enclosing scope.
      foundScope := InstNode.parent(foundScope);
    end try;
  end for;

  Error.addMessage(Error.RECURSION_DEPTH_REACHED,
    {String(Global.recursionDepthLimit), InstNode.name(foundScope)});
  fail();
end lookupSimpleCref;

function lookupCrefInNode
  input Absyn.ComponentRef cref;
  input output InstNode node;
  input output LookupState state;
protected
  Class scope;
algorithm
  if LookupState.isError(state) then
    return;
  end if;

  scope := match node
    case InstNode.CLASS_NODE()
      then InstNode.getClass(Inst.expand(node));

    case InstNode.COMPONENT_NODE()
      then InstNode.getClass(node);
  end match;

  (node, state) := match cref
    case Absyn.ComponentRef.CREF_IDENT()
      algorithm
        node := Class.lookupElement(cref.name, scope);
        state := LookupState.next(node, state);
      then
        (node, state);

    case Absyn.ComponentRef.CREF_QUAL()
      algorithm
        node := Class.lookupElement(cref.name, scope);
        state := LookupState.next(node, state);
      then
        lookupCrefInNode(cref.componentRef, node, state);

  end match;
end lookupCrefInNode;

annotation(__OpenModelica_Interface="frontend");
end NFLookup;
