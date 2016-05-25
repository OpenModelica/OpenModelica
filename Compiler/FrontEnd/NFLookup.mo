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
import Error;
import Inst = NFInst;
import NFInstance.ClassTree;
import NFInstance.Instance;
import NFInstanceTree.InstanceTree;
import NFInstanceTree.InstVector;
import NFInstNode.InstNode;
import NFMod.Modifier;

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
  (instance, tree) := lookupName(name, tree, info, Error.LOOKUP_ERROR);
end lookupClassName;

function lookupBaseClassName
  input Absyn.Path name;
        output InstNode instance;
  input output InstanceTree tree;
  input SourceInfo info;
algorithm
  (instance, tree) := lookupName(name, tree, info, Error.LOOKUP_BASECLASS_ERROR);
end lookupBaseClassName;

function lookupVariableName
  input Absyn.Path name;
        output InstNode instance;
  input output InstanceTree tree;
  input SourceInfo info;
algorithm
  (instance, tree) := lookupName(name, tree, info, Error.LOOKUP_VARIABLE_ERROR);
end lookupVariableName;

function lookupFunctionName
  input Absyn.Path name;
        output InstNode instance;
  input output InstanceTree tree;
  input SourceInfo info;
algorithm
  (instance, tree) := lookupName(name, tree, info, Error.LOOKUP_FUNCTION_ERROR);
end lookupFunctionName;

protected

function lookupSimpleName
  input String name;
  input InstanceTree tree;
  output InstNode instance;
protected
  InstNode scope;
  InstVector.Vector iv;
  ClassTree.Tree scope_tree;
  Integer scope_idx, idx;
algorithm
  InstanceTree.INST_TREE(currentScope = scope_idx, instances = iv) := tree;

  while scope_idx <> NFInstanceTree.NO_SCOPE loop
    scope := InstVector.get(iv, scope_idx);

    try
      idx := Instance.lookupClassId(name, InstNode.instance(scope));
      instance := InstVector.get(iv, idx);
      return;
    else
      scope_idx := InstNode.parent(scope);
    end try;
  end while;

  fail();
end lookupSimpleName;

function lookupName
  input Absyn.Path name;
        output InstNode instance;
  input output InstanceTree tree;
  input SourceInfo info;
  input Error.Message errorType;
algorithm
  (instance, tree) := matchcontinue name
    local
      InstNode i;

    case Absyn.IDENT()
      then (lookupSimpleBuiltinName(name.name), tree);

    case Absyn.IDENT()
      then (lookupSimpleName(name.name, tree), tree);

    // Qualified name, look up first part, expand it, and look up the rest of
    // the name in the expanded instance.
    case Absyn.QUALIFIED()
      algorithm
        i := lookupSimpleName(name.name, tree);
        (i, tree) := Inst.expand(i, tree);
      then
        lookupLocalName(name.path, tree);

    // Fully qualified path, start from top scope.
    case Absyn.FULLYQUALIFIED()
      algorithm
        tree := InstanceTree.setCurrentScope(tree, NFInstanceTree.TOP_SCOPE);
      then
        lookupName(name.path, tree, info, errorType);

    else
      algorithm
        Error.addSourceMessage(errorType, {Absyn.pathString(name), "<unknown>"}, info);
      then
        fail();

  end matchcontinue;
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

annotation(__OpenModelica_Interface="frontend");
end NFLookup;
