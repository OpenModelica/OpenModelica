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
import Inst = NFInst;
import NFComponent.Component;
import NFInstance.ClassTree;
import NFInstance.Instance;
import NFInstanceTree.InstanceTree;
import NFInstanceTree.InstVector;
import NFInstNode.InstNode;
import NFMod.Modifier;
import NFPrefix.Prefix;

constant NFInst.InstNode REAL_TYPE = NFInstNode.INST_NODE("Real",
  SOME(NFBuiltin.BUILTIN_REAL), NFInstance.PARTIAL_BUILTIN(Modifier.NOMOD()), 0, 0);
constant NFInst.InstNode INT_TYPE = NFInstNode.INST_NODE("Integer",
  SOME(NFBuiltin.BUILTIN_INTEGER), NFInstance.PARTIAL_BUILTIN(Modifier.NOMOD()), 0, 0);
constant NFInst.InstNode BOOL_TYPE = NFInstNode.INST_NODE("Boolean",
  SOME(NFBuiltin.BUILTIN_BOOLEAN), NFInstance.PARTIAL_BUILTIN(Modifier.NOMOD()), 0, 0);
constant NFInst.InstNode STRING_TYPE = NFInstNode.INST_NODE("String",
  SOME(NFBuiltin.BUILTIN_STRING), NFInstance.PARTIAL_BUILTIN(Modifier.NOMOD()), 0, 0);

function lookupClassName
  input Absyn.Path name;
        output InstNode instance;
  input output InstanceTree tree;
  input SourceInfo info;
algorithm
  (instance, tree) := lookupNameWithError(name, tree, info, Error.LOOKUP_ERROR);
end lookupClassName;

function lookupBaseClassName
  input Absyn.Path name;
        output InstNode instance;
  input output InstanceTree tree;
  input SourceInfo info;
algorithm
  (instance, tree) := lookupNameWithError(name, tree, info, Error.LOOKUP_BASECLASS_ERROR);
end lookupBaseClassName;

function lookupVariableName
  input Absyn.Path name;
        output InstNode instance;
  input output InstanceTree tree;
  input SourceInfo info;
algorithm
  (instance, tree) := lookupNameWithError(name, tree, info, Error.LOOKUP_VARIABLE_ERROR);
end lookupVariableName;

function lookupFunctionName
  input Absyn.Path name;
        output InstNode instance;
  input output InstanceTree tree;
  input SourceInfo info;
algorithm
  (instance, tree) := lookupNameWithError(name, tree, info, Error.LOOKUP_FUNCTION_ERROR);
end lookupFunctionName;

function lookupCref
  input Absyn.ComponentRef cref;
        output Component component "The component the cref refers to.";
        output Instance instance "The instance the component was found in.";
        output Prefix prefix;
  input output InstanceTree tree;
protected
  Component current_inst;
  InstNode current_scope;
  Instance.ElementId element;
algorithm
  (component, instance, prefix) := matchcontinue cref
    case _
      algorithm
        current_inst := InstanceTree.currentInstance(tree);
        (element, instance, tree) := lookupCrefInComponent(cref, current_inst, tree);
        component := Instance.lookupComponentById(element, instance);
        prefix := InstanceTree.hierarchyPrefix(tree);
      then
        (component, instance, prefix);

    case _
      algorithm
        tree := InstanceTree.enterParentScope(tree);

        while true loop
          try
            // TODO: Stop if the first part of the cref is found in any scope,
            // regardless of if the rest of the name can be found or not.
            (element, instance, tree) := lookupCrefInNode(cref, InstanceTree.currentScope(tree), tree);
            component := Instance.lookupComponentById(element, instance);
            prefix := InstanceTree.scopePrefix(tree);
            return;
          else
            tree := InstanceTree.enterParentScope(tree);
          end try;
        end while;
      then
        (component, instance, Prefix.NO_PREFIX());

    else
      algorithm
        print("lookupCref: Couldn't find " + Dump.printComponentRefStr(cref) + "\n");
      then
        fail();

  end matchcontinue;
end lookupCref;

function lookupElementId
  input String name;
        output Instance.ElementId id;
        output InstNode scope;
  input output InstanceTree tree;
protected
  Integer scope_idx;
  InstVector.Vector iv;
algorithm
  InstanceTree.INST_TREE(currentScope = scope_idx, instances = iv) := tree;

  while scope_idx <> NFInstanceTree.NO_SCOPE loop
    scope := InstVector.get(iv, scope_idx);

    try
      id := Instance.lookupElementId(name, InstNode.instance(scope));
      tree := InstanceTree.setCurrentScope(tree, InstNode.index(scope));
      return;
    else
      scope_idx := InstNode.parent(scope);
    end try;
  end while;

  fail();
end lookupElementId;

protected

function lookupSimpleName
  input String name;
        output InstNode instance;
  input output InstanceTree tree;
protected
  Integer id;
algorithm
  (Instance.ElementId.CLASS(id = id), instance, tree) := lookupElementId(name, tree);
  instance := InstanceTree.lookupNode(id, tree);
end lookupSimpleName;

function lookupNameWithError
  input Absyn.Path name;
        output InstNode instance;
  input output InstanceTree tree;
  input SourceInfo info;
  input Error.Message errorType;
algorithm
  try
    (instance, tree) := lookupName(name, tree);
  else
    Error.addSourceMessage(errorType, {Absyn.pathString(name), "<unknown>"}, info);
    fail();
  end try;
end lookupNameWithError;

function lookupName
  input Absyn.Path name;
        output InstNode instance;
  input output InstanceTree tree;
algorithm
  (instance, tree) := match name
    case Absyn.IDENT()
      algorithm
        try
          instance := lookupSimpleBuiltinName(name.name);
        else
          (instance, tree) := lookupSimpleName(name.name, tree);
        end try;
      then
        (instance, tree);

    case Absyn.IDENT()
      then lookupSimpleName(name.name, tree);

    // Qualified name, look up first part, expand it, and look up the rest of
    // the name in the expanded instance.
    case Absyn.QUALIFIED()
      algorithm
        (instance, tree) := lookupSimpleName(name.name, tree);
        (instance, tree) := Inst.expand(instance, tree);
      then
        lookupLocalName(name.path, tree);

    // Fully qualified path, start from top scope.
    case Absyn.FULLYQUALIFIED()
      algorithm
        tree := InstanceTree.setCurrentScope(tree, NFInstanceTree.TOP_SCOPE);
      then
        lookupName(name.path, tree);

  end match;
end lookupName;

function lookupLocalSimpleName
  input String name;
  input InstanceTree tree;
  output InstNode instance;
protected
  ClassTree.Tree scope_tree;
  InstVector.Vector iv;
  Integer idx;
algorithm
  // Look up the current scope.
  InstanceTree.INST_TREE(currentScope = idx, instances = iv) := tree;
  instance := InstVector.get(iv, idx);
  // Look up the name in that scope.
  idx := Instance.lookupClassId(name, InstNode.instance(instance));
  instance := InstVector.get(iv, idx);
end lookupLocalSimpleName;

function lookupLocalName
  input Absyn.Path name;
        output InstNode instance;
  input output InstanceTree tree;
algorithm
  (instance, tree) := match name
    local
      InstNode i;

    case Absyn.IDENT()
      then (lookupLocalSimpleName(name.name, tree), tree);

    case Absyn.QUALIFIED()
      algorithm
        i := lookupLocalSimpleName(name.name, tree);
        (i, tree) := Inst.expand(i, tree);
      then
        lookupLocalName(name.path, tree);

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

function lookupCrefInComponent
  input Absyn.ComponentRef cref;
  input Component component;
        output Instance.ElementId element;
        output Instance instance;
  input output InstanceTree tree;
algorithm
  (element, instance, tree) :=
    lookupCrefInNode(cref, Component.classInstance(component), tree);
end lookupCrefInComponent;

function lookupCrefInNode
  input Absyn.ComponentRef cref;
  input InstNode node;
        output Instance.ElementId element;
        output Instance instance;
  input output InstanceTree tree;
protected
  Component c;
  InstNode cls;
algorithm
  (cls, tree) := Inst.instantiate(node, Modifier.NOMOD(), tree);
  instance := InstNode.instance(cls);

  element := match cref
    case Absyn.ComponentRef.CREF_IDENT()
      then Instance.lookupElementId(cref.name, instance);

    case Absyn.ComponentRef.CREF_QUAL()
      algorithm
        element := Instance.lookupElementId(cref.name, instance);

        (element, instance, tree) := match element
          case Instance.ElementId.COMPONENT()
            algorithm
              c := Instance.lookupComponentById(element, instance);
            then
              lookupCrefInComponent(cref.componentRef, c, tree);

          case Instance.ElementId.CLASS()
            algorithm
              cls := InstanceTree.lookupNode(element.id, tree);
            then
              lookupCrefInNode(cref.componentRef, cls, tree);

        end match;
      then
        element;

  end match;
end lookupCrefInNode;

annotation(__OpenModelica_Interface="frontend");
end NFLookup;
