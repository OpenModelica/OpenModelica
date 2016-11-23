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

function lookupClassName
  input Absyn.Path name;
  input InstNode scope;
  input SourceInfo info;
  output InstNode instance;
algorithm
  instance := lookupNameWithError(name, scope, info, Error.LOOKUP_ERROR);
end lookupClassName;

function lookupBaseClassName
  input Absyn.Path name;
  input InstNode scope;
  input SourceInfo info;
  output InstNode instance;
algorithm
  instance := lookupNameWithError(name, scope, info, Error.LOOKUP_BASECLASS_ERROR);
end lookupBaseClassName;

function lookupVariableName
  input Absyn.Path name;
  input InstNode scope;
  input SourceInfo info;
  output InstNode instance;
algorithm
  instance := lookupNameWithError(name, scope, info, Error.LOOKUP_VARIABLE_ERROR);
end lookupVariableName;

function lookupFunctionName
  input Absyn.Path name;
  input InstNode scope;
  input SourceInfo info;
  output InstNode instance;
algorithm
  instance := lookupNameWithError(name, scope, info, Error.LOOKUP_FUNCTION_ERROR);
end lookupFunctionName;

function lookupCref
  input Absyn.ComponentRef cref;
  input Component.Scope scope;
  input ComponentNode component "The component to look in.";
  input SourceInfo info;
  output ComponentNode foundComponent "The component the cref resolves to.";
  output Prefix prefix;
algorithm
  (foundComponent, prefix) := matchcontinue cref
    local
      Instance.Element element;
      InstNode found_scope;

    case Absyn.ComponentRef.CREF_IDENT(name = "time")
      then (BUILTIN_TIME, Prefix.NO_PREFIX());

    case Absyn.ComponentRef.CREF_IDENT()
      algorithm
        (element, found_scope, prefix) := lookupSimpleCref(cref.name, scope, component);
        // TODO: Give an error if the found element is not a component (or function?).
        foundComponent := Instance.lookupComponentByElement(element, InstNode.instance(found_scope));
      then
        (foundComponent, prefix);

    case Absyn.ComponentRef.CREF_QUAL()
      algorithm
        (element, found_scope, prefix) := lookupSimpleCref(cref.name, scope, component);
        (element, found_scope) := lookupCrefInElement(cref.componentRef, element, found_scope);
        // TODO: Give an error if the found element is not a component (or function?).
        foundComponent := Instance.lookupComponentByElement(element, InstNode.instance(found_scope));
      then
        (foundComponent, prefix);

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

function lookupElement
  input String name;
  input InstNode scope;
  output Instance.Element element;
protected
  InstNode cur_scope = scope;
algorithm
  // Look for the name in each enclosing scope, until it's either found or we
  // run out of scopes.
  while true loop
    try
      element := Instance.lookupElement(name, InstNode.instance(cur_scope));
      return;
    else
      cur_scope := InstNode.parentScope(cur_scope);
    end try;
  end while;
end lookupElement;

protected

function lookupSimpleName
  input String name;
  input InstNode scope;
  output InstNode instance;
algorithm
  Instance.Element.CLASS(node = instance) := lookupElement(name, scope);
end lookupSimpleName;

function lookupNameWithError
  input Absyn.Path name;
  input InstNode scope;
  input SourceInfo info;
  input Error.Message errorType;
  output InstNode instance;
algorithm
  try
    instance := lookupName(name, scope);
  else
    Error.addSourceMessage(errorType, {Absyn.pathString(name), "<unknown>"}, info);
    fail();
  end try;
end lookupNameWithError;

function lookupName
  input Absyn.Path name;
  input InstNode scope;
  output InstNode instance;
algorithm
  instance := match name
    case Absyn.Path.IDENT()
      algorithm
        try
          instance := lookupSimpleBuiltinName(name.name);
        else
          instance := lookupSimpleName(name.name, scope);
        end try;
      then
        instance;

    // Qualified name, look up first part, expand it, and look up the rest of
    // the name in the expanded instance.
    case Absyn.Path.QUALIFIED()
      algorithm
        instance := lookupSimpleName(name.name, scope);
        instance := Inst.expand(instance);
      then
        lookupLocalName(name.path, instance);

    // Fully qualified path, start from top scope.
    case Absyn.Path.FULLYQUALIFIED()
      then lookupName(name.path, InstNode.topScope(scope));

  end match;
end lookupName;

function lookupLocalSimpleName
  input String name;
  input InstNode scope;
  output InstNode instance;
algorithm
  instance := Instance.lookupClass(name, InstNode.instance(scope));
end lookupLocalSimpleName;

function lookupLocalName
  input Absyn.Path name;
  input InstNode scope;
  output InstNode instance;
algorithm
  instance := match name
    case Absyn.Path.IDENT() then lookupLocalSimpleName(name.name, scope);

    case Absyn.Path.QUALIFIED()
      algorithm
        instance := lookupLocalSimpleName(name.name, scope);
        instance := Inst.expand(instance);
      then
        lookupLocalName(name.path, instance);

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
  output Instance.Element element;
  output InstNode foundScope;
  output Prefix prefix;
protected
  ComponentNode parent = component;
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
      element := Instance.lookupElement(name, InstNode.instance(foundScope));

      // We found it, build the prefix for the found cref.
      if i == 1 then
        prefix := ComponentNode.instPrefix(parent);
      else
        prefix := InstNode.scopePrefix(foundScope);
      end if;

      // We're done here.
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
  input output Instance.Element element;
  input output InstNode scope;
algorithm
  (element, scope) := match element
    local
      ComponentNode c;

    case Instance.Element.COMPONENT()
      algorithm
        c := Instance.lookupComponentByIndex(element.index, InstNode.instance(scope));
      then
        lookupCrefInComponent(cref, c);

    case Instance.Element.CLASS()
      then lookupCrefInClass(cref, element.node);
  end match;
end lookupCrefInElement;

function lookupCrefInComponent
  input Absyn.ComponentRef cref;
  input ComponentNode component;
  output Instance.Element element;
  output InstNode scope;
algorithm
  (element, scope) := lookupCrefInClass(cref,
    Component.classInstance(ComponentNode.component(component)));
end lookupCrefInComponent;

function lookupCrefInClass
  input Absyn.ComponentRef cref;
  input InstNode node;
  output Instance.Element element;
  output InstNode scope;
protected
  Instance i;
algorithm
  scope := Inst.expand(node);
  i := InstNode.instance(node);

  (element, scope) := match cref
    case Absyn.ComponentRef.CREF_IDENT()
      then (Instance.lookupElement(cref.name, i), scope);

    case Absyn.ComponentRef.CREF_QUAL()
      algorithm
        element := Instance.lookupElement(cref.name, i);
      then
        lookupCrefInElement(cref.componentRef, element, scope);
  end match;
end lookupCrefInClass;

annotation(__OpenModelica_Interface="frontend");
end NFLookup;
