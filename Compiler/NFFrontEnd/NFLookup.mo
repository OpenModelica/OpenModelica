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
import NFInstNode.InstParent;
import NFMod.Modifier;
import NFPrefix.Prefix;

constant NFInst.InstNode REAL_TYPE = NFInstNode.INST_NODE("Real",
  SOME(NFBuiltin.BUILTIN_REAL), NFInstance.PARTIAL_BUILTIN(Modifier.NOMOD()),
  0, 0, InstParent.NO_PARENT());
constant NFInst.InstNode INT_TYPE = NFInstNode.INST_NODE("Integer",
  SOME(NFBuiltin.BUILTIN_INTEGER), NFInstance.PARTIAL_BUILTIN(Modifier.NOMOD()),
  0, 0, InstParent.NO_PARENT());
constant NFInst.InstNode BOOL_TYPE = NFInstNode.INST_NODE("Boolean",
  SOME(NFBuiltin.BUILTIN_BOOLEAN), NFInstance.PARTIAL_BUILTIN(Modifier.NOMOD()),
  0, 0, InstParent.NO_PARENT());
constant NFInst.InstNode STRING_TYPE = NFInstNode.INST_NODE("String",
  SOME(NFBuiltin.BUILTIN_STRING), NFInstance.PARTIAL_BUILTIN(Modifier.NOMOD()),
  0, 0, InstParent.NO_PARENT());

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
        output Prefix prefix;
  input output InstanceTree tree;
protected
  Component current_inst;
  InstNode current_scope, scope;
  Instance.ElementId element;
  InstParent parent = InstParent.NO_PARENT();
  Integer parent_idx;
algorithm
  (component, prefix) := matchcontinue cref
    case _
      algorithm
        current_inst := InstanceTree.currentInstance(tree);
        (element, scope, tree) := lookupCrefInComponent(cref, current_inst, tree);
        component := Instance.lookupComponentById(element, InstNode.instance(scope));
        prefix := InstanceTree.hierarchyPrefix(tree);
      then
        (component, prefix);

    case _
      algorithm
        tree := InstanceTree.enterParentScope(tree);
        current_scope := InstanceTree.currentScope(tree);

        while true loop
          try
            // TODO: Stop if the first part of the cref is found in any scope,
            // regardless of if the rest of the name can be found or not.
            parent_idx := InstNode.scopeParent(current_scope);
            parent := if parent_idx == NFInstanceTree.NO_SCOPE then
                InstParent.NO_PARENT()
              else
                InstParent.CLASS(InstanceTree.lookupNode(parent_idx, tree));

            (element, scope, tree) := lookupCrefInNode(cref, current_scope, parent, tree);
            component := Instance.lookupComponentById(element, InstNode.instance(scope));
            prefix := InstanceTree.prefix(current_scope);
            return;
          else
            InstParent.CLASS(node = current_scope) := parent;
            tree := InstanceTree.setCurrentScope(tree, current_scope);
          end try;
        end while;
      then
        (component, prefix);

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
  InstVector.Vector iv;
algorithm
  InstanceTree.INST_TREE(currentScope = scope, instances = iv) := tree;

  while true loop
    try
      id := Instance.lookupElementId(name, InstNode.instance(scope));
      tree := InstanceTree.setCurrentScope(tree, scope);
      return;
    else
      scope := InstVector.get(iv, InstNode.scopeParent(scope));
    end try;
  end while;
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
        (instance, tree) := Inst.expand(instance,
          InstParent.CLASS(InstanceTree.currentScope(tree)), tree);
      then
        lookupLocalName(name.path, InstParent.CLASS(instance), tree);

    // Fully qualified path, start from top scope.
    case Absyn.FULLYQUALIFIED()
      algorithm
        tree := InstanceTree.setCurrentScopeIndex(tree, NFInstanceTree.TOP_SCOPE);
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
  idx := Instance.lookupClassId(name, InstNode.instance(tree.currentScope));
  instance := InstVector.get(tree.instances, idx);
end lookupLocalSimpleName;

function lookupLocalName
  input Absyn.Path name;
  input InstParent parent;
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
        (i, tree) := Inst.expand(i, parent, tree);
      then
        lookupLocalName(name.path, InstParent.CLASS(i), tree);

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
        output InstNode scope;
  input output InstanceTree tree;
algorithm
  (element, scope, tree) :=
    lookupCrefInNode(cref, Component.classInstance(component), InstParent.COMPONENT(component), tree);
end lookupCrefInComponent;

function lookupCrefInNode
  input Absyn.ComponentRef cref;
  input InstNode node;
  input InstParent parent;
        output Instance.ElementId element;
        output InstNode scope;
  input output InstanceTree tree;
protected
  Component c;
  InstNode next_cls;
  Instance instance;
algorithm
  (scope, tree) := Inst.instantiate(node, Modifier.NOMOD(), parent, tree);
  instance := InstNode.instance(scope);

  element := match cref
    case Absyn.ComponentRef.CREF_IDENT()
      then Instance.lookupElementId(cref.name, instance);

    case Absyn.ComponentRef.CREF_QUAL()
      algorithm
        element := Instance.lookupElementId(cref.name, instance);

        (element, scope, tree) := match element
          case Instance.ElementId.COMPONENT()
            algorithm
              c := Instance.lookupComponentById(element, instance);
            then
              lookupCrefInComponent(cref.componentRef, c, tree);

          case Instance.ElementId.CLASS()
            algorithm
              next_cls := InstanceTree.lookupNode(element.id, tree);
            then
              lookupCrefInNode(cref.componentRef, next_cls, InstParent.CLASS(scope), tree);

        end match;
      then
        element;

  end match;
end lookupCrefInNode;

annotation(__OpenModelica_Interface="frontend");
end NFLookup;
