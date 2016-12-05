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
import Inst = NFInst;
import NFComponentNode.ComponentNode;
import NFComponent.Component;
import NFInstance.ClassTree;
import NFInstance.Instance;
import NFInstNode.InstNode;
import NFLookupState.LookupState;
import NFMod.Modifier;
import NFPrefix.Prefix;

constant NFInst.InstNode REAL_TYPE = NFInstNode.INST_NODE("Real",
  NFBuiltin.BUILTIN_REAL,
  listArray({NFInstance.PARTIAL_BUILTIN("Real", Modifier.NOMOD())}),
  NFInstNode.EMPTY_NODE(), NFInstNode.NORMAL_CLASS());
constant NFInst.InstNode INT_TYPE = NFInstNode.INST_NODE("Integer",
  NFBuiltin.BUILTIN_INTEGER,
  listArray({NFInstance.PARTIAL_BUILTIN("Integer", Modifier.NOMOD())}),
  NFInstNode.EMPTY_NODE(), NFInstNode.NORMAL_CLASS());
constant NFInst.InstNode BOOL_TYPE = NFInstNode.INST_NODE("Boolean",
  NFBuiltin.BUILTIN_BOOLEAN,
  listArray({NFInstance.PARTIAL_BUILTIN("Boolean", Modifier.NOMOD())}),
  NFInstNode.EMPTY_NODE(), NFInstNode.NORMAL_CLASS());
constant NFInst.InstNode STRING_TYPE = NFInstNode.INST_NODE("String",
  NFBuiltin.BUILTIN_STRING,
  listArray({NFInstance.PARTIAL_BUILTIN("String", Modifier.NOMOD())}),
  NFInstNode.EMPTY_NODE(), NFInstNode.NORMAL_CLASS());

constant NFComponentNode.ComponentNode BUILTIN_TIME =
  NFComponentNode.COMPONENT_NODE("time",
    NFBuiltin.BUILTIN_TIME,
    listArray({NFComponent.TYPED_COMPONENT(
        REAL_TYPE,
        DAE.T_REAL_DEFAULT,
        NFBinding.UNBOUND(),
        NFComponent.INPUT_ATTR)}),
    NFComponentNode.EMPTY_NODE());

uniontype LookupResult
  record CLASS
    InstNode node;
  end CLASS;

  record COMPONENT
    ComponentNode node;
  end COMPONENT;

  function getDefinition
    input LookupResult result;
    output SCode.Element def;
  algorithm
    def := match result
      case CLASS() then InstNode.definition(result.node);
      case COMPONENT() then ComponentNode.definition(result.node);
    end match;
  end getDefinition;

  function fromElement
    input Instance.Element element;
    input Instance instance;
    output LookupResult result;
  algorithm
    result := match element
      case Instance.Element.CLASS() then LookupResult.CLASS(element.node);
      case Instance.Element.COMPONENT()
        then LookupResult.COMPONENT(Instance.lookupComponentByIndex(element.index, instance));
     end match;
  end fromElement;

  function state
    input LookupResult result;
    output LookupState state;
  algorithm
    state := match result
      case CLASS() then LookupState.elementState(InstNode.definition(result.node));
      case COMPONENT() then LookupState.elementState(ComponentNode.definition(result.node));
    end match;
  end state;
end LookupResult;

function lookupClassName
  input Absyn.Path name;
  input InstNode scope;
  input SourceInfo info;
  output InstNode node;
protected
  LookupResult res;
  LookupState state;
algorithm
  (res, state) := lookupNameWithError(name, scope, info, Error.LOOKUP_ERROR);
  LookupState.assertClass(state, res, name, info);
  LookupResult.CLASS(node = node) := res;
end lookupClassName;

function lookupBaseClassName
  input Absyn.Path name;
  input InstNode scope;
  input SourceInfo info;
  output InstNode node;
protected
  LookupResult res;
  LookupState state;
algorithm
  (res, state) := lookupNameWithError(name, scope, info, Error.LOOKUP_BASECLASS_ERROR);
  LookupState.assertClass(state, res, name, info);
  LookupResult.CLASS(node = node) := res;
end lookupBaseClassName;

function lookupComponent
  input Absyn.ComponentRef cref;
  input Component.Scope scope;
  input ComponentNode component "The component to look in.";
  input SourceInfo info;
  output ComponentNode foundComponent "The component the cref resolves to.";
  output Prefix prefix;
protected
  LookupResult res;
  LookupState state;
algorithm
  (res, prefix, state) := lookupCref(cref, scope, component, info);
  LookupState.assertComponent(state, res, cref, info);
  LookupResult.COMPONENT(node = foundComponent) := res;
end lookupComponent;

function lookupFunctionName
  input Absyn.ComponentRef cref;
  input Component.Scope scope;
  input ComponentNode component "The component to look in.";
  input SourceInfo info;
  output InstNode func;
  output Prefix prefix;
protected
  LookupResult res;
  LookupState state;
algorithm
  (res, prefix, state) := lookupCref(cref, scope, component, info);
  LookupState.assertFunction(state, res, cref, info);
  LookupResult.CLASS(node = func) := res;
end lookupFunctionName;

function lookupCref
  input Absyn.ComponentRef cref;
  input Component.Scope scope;
  input ComponentNode component "The component to look in.";
  input SourceInfo info;
  output LookupResult result;
  output Prefix prefix;
  output LookupState state;
algorithm
  (result, prefix, state) := matchcontinue cref
    local
      Instance.Element element;
      InstNode found_scope;

    case Absyn.ComponentRef.CREF_IDENT(name = "time")
      then (LookupResult.COMPONENT(BUILTIN_TIME), Prefix.NO_PREFIX(),
            LookupState.STATE_PREDEF_COMP());

    case Absyn.ComponentRef.CREF_IDENT()
      algorithm
        (result, found_scope, prefix) := lookupSimpleCref(cref.name, scope, component);
        state := LookupResult.state(result);
      then
        (result, prefix, state);

    case Absyn.ComponentRef.CREF_QUAL()
      algorithm
        (result, found_scope, prefix) := lookupSimpleCref(cref.name, scope, component);
        state := LookupResult.state(result);
        (result, found_scope, state) :=
          lookupCrefInElement(cref.componentRef, result, found_scope, state);
      then
        (result, prefix, state);

    case Absyn.ComponentRef.CREF_FULLYQUALIFIED()
      then lookupCref(cref.componentRef, Component.Scope.RELATIVE_COMP(0),
        ComponentNode.topComponent(component), info);

    else
      algorithm
        Error.addSourceMessage(Error.LOOKUP_VARIABLE_ERROR,
          {Dump.printComponentRefStr(cref), ComponentNode.name(component)}, info);
      then
        fail();

  end matchcontinue;
end lookupCref;

protected

function lookupLocalSimpleName
  "Looks up a name in the given scope, without continuing the search in any
   enclosing scopes if the name isn't found."
  input String name;
  input InstNode scope;
  output LookupResult result;
protected
  Instance i;
  Instance.Element e;
algorithm
  i := InstNode.instance(scope);
  e := Instance.lookupElement(name, i);
  result := LookupResult.fromElement(e, i);
end lookupLocalSimpleName;

function lookupSimpleName
  input String name;
  input InstNode scope;
  output LookupResult result;
protected
  InstNode cur_scope = scope;
  Instance i;
  Instance.Element e;
algorithm
  // Look for the name in each enclosing scope, until it's either found or we
  // run out of scopes.
  for i in 1:Global.recursionDepthLimit loop
    try
      result := lookupLocalSimpleName(name, cur_scope);
      return;
    else
      // TODO: Handle encapsulated scopes.
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
  output LookupResult result;
  output LookupState state;
algorithm
  try
    (result, state) := lookupName(name, scope);
  else
    Error.addSourceMessage(errorType, {Absyn.pathString(name), "<unknown>"}, info);
    fail();
  end try;
end lookupNameWithError;

function lookupName
  input Absyn.Path name;
  input InstNode scope;
  output LookupResult result;
  output LookupState state;
algorithm
  (result, state) := match name
    local
      InstNode node;

    // Simple name, look it up in the given scope.
    case Absyn.Path.IDENT()
      then lookupFirstIdent(name.name, scope);

    // Qualified name, look up first part in the given scope and look up the
    // rest of the name in the found element.
    case Absyn.Path.QUALIFIED()
      algorithm
        (result, state) := lookupFirstIdent(name.name, scope);
      then
        lookupLocalName(name.path, result, state);

    // Fully qualified path, start from top scope.
    case Absyn.Path.FULLYQUALIFIED()
      then lookupName(name.path, InstNode.topScope(scope));

  end match;
end lookupName;

function lookupFirstIdent
  "Looks up the first part of a name."
  input String name;
  input InstNode scope;
  output LookupResult result;
  output LookupState state;
protected
  InstNode node;
algorithm
  try
    // Check if the name refers to a reserved builtin name.
    node := lookupSimpleBuiltinName(name);
    result := LookupResult.CLASS(node);
    state := LookupState.STATE_PREDEF_CLASS();
  else
    // Otherwise, check each scope until the name is found.
    result := lookupSimpleName(name, scope);
    state := LookupState.elementState(LookupResult.getDefinition(result));
  end try;
end lookupFirstIdent;

function lookupLocalName
  "Looks up a path in the given scope, without continuing the search in any
   enclosing scopes if the path isn't found."
  input Absyn.Path name;
  input output LookupResult result;
  input output LookupState state;
protected
  InstNode scope;
algorithm
  // We're looking for a class, which is not legal to look up inside of a
  // component.
  () := match result
    case LookupResult.CLASS()
      algorithm
        scope := result.node;
      then
        ();

    else
      algorithm
        state := LookupState.STATE_COMP_CLASS();
        return;
      then
        ();
  end match;

  // Make sure the scope is expanded so that we can do lookup in it.
  scope := Inst.expand(scope);

  // Look up the path in the scope.
  () := match name
    case Absyn.Path.IDENT()
      algorithm
        result := lookupLocalSimpleName(name.name, scope);
        state := LookupState.next(result, state);
      then
        ();

    case Absyn.Path.QUALIFIED()
      algorithm
        result := lookupLocalSimpleName(name.name, scope);
        state := LookupState.next(result, state);
        (result, state) := lookupLocalName(name.path, result, state);
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
    case "Real" then REAL_TYPE;
    case "Integer" then INT_TYPE;
    case "Boolean" then BOOL_TYPE;
    case "String" then STRING_TYPE;
  end match;
end lookupSimpleBuiltinName;

function lookupSimpleCref
  "This function look up a simple name as a cref in a given component."
  input String name;
  input Component.Scope scope;
  input ComponentNode component;
  output LookupResult result;
  output InstNode foundScope;
  output Prefix prefix;
protected
  ComponentNode parent = component;
  Instance inst;
  Instance.Element e;
algorithm
  // Figure out which scope to start looking for the cref in.
  foundScope := match scope
    // Use the given component as the scope.
    case Component.Scope.RELATIVE_COMP(level = 0)
      then Component.classInstance(ComponentNode.component(component));

    // Use the given component's n:th parent as the scope.
    case Component.Scope.RELATIVE_COMP()
      algorithm
        for i in 1:scope.level loop
          parent := ComponentNode.parent(parent);
        end for;
      then
        Component.classInstance(ComponentNode.component(parent));
  end match;

  // Look for the name in the given scope, and if not found there continue
  // through the enclosing scopes of that scope until we either run out of
  // scopes or for some reason exceed the recursion depth limit.
  for i in 1:Global.recursionDepthLimit loop
    try
      // Check if the cref can be found in the current scope.
      inst := InstNode.instance(foundScope);
      e := Instance.lookupElement(name, inst);

      // We found it, build the prefix for the found cref.
      if i == 1 then
        prefix := ComponentNode.instPrefix(parent);
      else
        prefix := InstNode.scopePrefix(foundScope);
      end if;

      // We're done here.
      result := LookupResult.fromElement(e, inst);
      return;
    else
      // Look in the next enclosing scope.
      foundScope := InstNode.parentScope(foundScope);
    end try;
  end for;

  Error.addMessage(Error.RECURSION_DEPTH_REACHED,
    {String(Global.recursionDepthLimit), InstNode.name(foundScope)});
  fail();
end lookupSimpleCref;

function lookupCrefInElement
  input Absyn.ComponentRef cref;
  input output LookupResult result;
  input output InstNode scope;
  input output LookupState state;
algorithm
  if LookupState.isError(state) then
    return;
  end if;

  (result, scope, state) := match result
    case LookupResult.COMPONENT() then lookupCrefInComponent(cref, result.node, state);
    case LookupResult.CLASS() then lookupCrefInClass(cref, result.node, state);
  end match;
end lookupCrefInElement;

function lookupCrefInComponent
  input Absyn.ComponentRef cref;
  input ComponentNode component;
        output LookupResult result;
        output InstNode scope;
  input output LookupState state;
algorithm
  (result, scope, state) := lookupCrefInClass(cref,
    Component.classInstance(ComponentNode.component(component)), state);
end lookupCrefInComponent;

function lookupCrefInClass
  input Absyn.ComponentRef cref;
  input InstNode node;
        output LookupResult result;
        output InstNode scope;
  input output LookupState state;
protected
  Instance i;
  Instance.Element e;
algorithm
  scope := Inst.expand(node);
  i := InstNode.instance(node);

  (result, scope, state) := match cref
    case Absyn.ComponentRef.CREF_IDENT()
      algorithm
        e := Instance.lookupElement(cref.name, i);
        result := LookupResult.fromElement(e, i);
        state := LookupState.next(result, state);
      then
        (result, scope, state);

    case Absyn.ComponentRef.CREF_QUAL()
      algorithm
        e := Instance.lookupElement(cref.name, i);
        result := LookupResult.fromElement(e, i);
        state := LookupState.next(result, state);
      then
        lookupCrefInElement(cref.componentRef, result, scope, state);
  end match;
end lookupCrefInClass;

annotation(__OpenModelica_Interface="frontend");
end NFLookup;
