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
import Inst = NFInst;
import NFInstance.ClassTree;
import NFInstance.Instance;
import NFInstanceTree.InstanceTree;
import NFInstanceTree.InstVector;
import NFInstNode.InstNode;

constant NFInst.InstNode REAL_TYPE = NFInstNode.INST_NODE("Real",
  SOME(NFBuiltin.BUILTIN_REAL), NFInstance.PARTIAL_BUILTIN(), 0, 0);
constant NFInst.InstNode INT_TYPE = NFInstNode.INST_NODE("Integer",
  SOME(NFBuiltin.BUILTIN_INTEGER), NFInstance.PARTIAL_BUILTIN(), 0, 0);
constant NFInst.InstNode BOOL_TYPE = NFInstNode.INST_NODE("Boolean",
  SOME(NFBuiltin.BUILTIN_BOOLEAN), NFInstance.PARTIAL_BUILTIN(), 0, 0);
constant NFInst.InstNode STRING_TYPE = NFInstNode.INST_NODE("String",
  SOME(NFBuiltin.BUILTIN_STRING), NFInstance.PARTIAL_BUILTIN(), 0, 0);

function lookupSimpleName
  input String inName;
  input InstanceTree inTree;
  output InstNode outInstance;
protected
  InstNode scope;
  InstVector.Vector iv;
  ClassTree.Tree scope_tree;
  Integer scope_idx, idx;
algorithm
  InstanceTree.INST_TREE(currentScope = scope_idx, instances = iv) := inTree;

  while scope_idx <> NFInstanceTree.NO_SCOPE loop
    scope := InstVector.get(iv, scope_idx);

    try
      idx := Instance.lookupClassId(inName, InstNode.instance(scope));
      outInstance := InstVector.get(iv, idx);
      return;
    else
      scope_idx := InstNode.parent(scope);
    end try;
  end while;

  fail();
end lookupSimpleName;

function lookupName
  input Absyn.Path inName;
  input InstanceTree inTree;
  output InstNode outInstance;
  output InstanceTree outTree;
algorithm
  (outInstance, outTree) := matchcontinue inName
    local
      InstanceTree tree;
      InstNode i;

    case Absyn.IDENT()
      then (lookupSimpleBuiltinName(inName.name), inTree);

    case Absyn.IDENT()
      then (lookupSimpleName(inName.name, inTree), inTree);

    // Qualified name, look up first part, expand it, and look up the rest of
    // the name in the expanded instance.
    case Absyn.QUALIFIED()
      algorithm
        i := lookupSimpleName(inName.name, inTree);
        (i, tree) := Inst.expand(i, inTree);
      then
        lookupLocalName(inName.path, tree);

    // Fully qualified path, start from top scope.
    case Absyn.FULLYQUALIFIED()
      algorithm
        tree := InstanceTree.setCurrentScope(inTree, NFInstanceTree.TOP_SCOPE);
      then
        lookupName(inName.path, tree);

    else
      algorithm
        print(Absyn.pathString(inName) + " could not be found.\n");
      then
        fail();
  end matchcontinue;
end lookupName;

function lookupLocalSimpleName
  input String inName;
  input InstanceTree inTree;
  output InstNode outInstance;
protected
  ClassTree.Tree scope_tree;
  InstVector.Vector iv;
  Integer idx;
algorithm
  // Look up the current scope.
  InstanceTree.INST_TREE(currentScope = idx, instances = iv) := inTree;
  outInstance := InstVector.get(iv, idx);
  // Look up the name in that scope.
  idx := Instance.lookupClassId(inName, InstNode.instance(outInstance));
  outInstance := InstVector.get(iv, idx);
end lookupLocalSimpleName;

function lookupLocalName
  input Absyn.Path inName;
  input InstanceTree inTree;
  output InstNode outInstance;
  output InstanceTree outTree;
algorithm
  (outInstance, outTree) := match inName
    local
      InstNode i;
      InstanceTree tree;

    case Absyn.IDENT()
      then (lookupLocalSimpleName(inName.name, inTree), inTree);

    case Absyn.QUALIFIED()
      algorithm
        i := lookupLocalSimpleName(inName.name, inTree);
        (i, tree) := Inst.expand(i, inTree);
      then
        lookupLocalName(inName.path, tree);

  end match;
end lookupLocalName;

function lookupSimpleBuiltinName
  input String inName;
  output InstNode outBuiltin;
algorithm
  outBuiltin := match inName
    case "Real" then REAL_TYPE;
    case "Integer" then INT_TYPE;
    case "Boolean" then BOOL_TYPE;
    case "String" then STRING_TYPE;
  end match;
end lookupSimpleBuiltinName;

annotation(__OpenModelica_Interface="frontend");
end NFLookup;
