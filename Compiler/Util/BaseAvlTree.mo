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

encapsulated partial package BaseAvlTree

import BaseAvlSet;
extends BaseAvlSet;

replaceable type Value = Integer; // TODO: We should have an Any type

redeclare uniontype Tree
  "The binary tree data structure."

  record NODE
    Key key "The key of the node.";
    Value value;
    Integer height "Height of tree, used for balancing";
    Tree left "Left subtree.";
    Tree right "Right subtree.";
  end NODE;

  record EMPTY end EMPTY;
end Tree;

replaceable partial function valueStr
  "Prints a Value to a string."
  input Value inValue;
  output String outString;
end valueStr;

redeclare function printNodeStr
  input Tree inNode;
  output String outString;
algorithm
  outString := match inNode
    case NODE() then "(" + keyStr(inNode.key) + ", " + valueStr(inNode.value) + ")";
  end match;
end printNodeStr;

replaceable function addConflictDefault = addConflictFail
  "Default conflict resolving function for add.";

function addConflictFail
  "Conflict resolving function for add which fails on conflict."
  input Value newValue;
  input Value oldValue;
  output Value value;
algorithm
  fail();
end addConflictFail;

function addConflictReplace
  "Conflict resolving function for add which replaces the old value with the new."
  input Value newValue;
  input Value oldValue;
  output Value value = newValue;
end addConflictReplace;

function addConflictKeep
  "Conflict resolving function for add which keeps the old value."
  input Value newValue;
  input Value oldValue;
  output Value value = oldValue;
end addConflictKeep;

redeclare function add
  "Inserts a new node in the tree."
  input Tree inTree;
  input Key inKey;
  input Value inValue;
  input ConflictFunc conflictFunc = addConflictDefault "Used to resolve conflicts.";
  output Tree tree=inTree;

  partial function ConflictFunc
    input Value newValue "The value given by the caller.";
    input Value oldValue "The value already in the tree.";
    output Value value "The value that will replace the existing value.";
  end ConflictFunc;
algorithm
  tree := match tree
    local
      Key key;
      Value value;
      Integer key_comp;

    // Empty tree.
    case EMPTY()
      then NODE(inKey, inValue, 1, EMPTY(), EMPTY());

    case NODE(key = key)
      algorithm
        key_comp := keyCompare(inKey, key);

        if key_comp == -1 then
          // Replace left branch.
          tree.left := add(tree.left, inKey, inValue, conflictFunc);
        elseif key_comp == 1 then
          // Replace right branch.
          tree.right := add(tree.right, inKey, inValue, conflictFunc);
        else
          // Use the given function to resolve the conflict.
          value := conflictFunc(inValue, tree.value);
          if not referenceEq(tree.value, value) then
            tree.value := value;
          end if;
        end if;
      then
        if key_comp == 0 then tree else balance(tree);

  end match;
end add;

redeclare function addList
  "Adds a list of key-value pairs to the tree."
  input output Tree tree;
  input list<tuple<Key,Value>> inValues;
  input ConflictFunc conflictFunc = addConflictDefault "Used to resolve conflicts.";

  partial function ConflictFunc
    input Value newValue "The value given by the caller.";
    input Value oldValue "The value already in the tree.";
    output Value value "The value that will replace the existing value.";
  end ConflictFunc;
protected
  Key key;
  Value value;
algorithm
  for t in inValues loop
    (key, value) := t;
    tree := add(tree, key, value, conflictFunc);
  end for;
end addList;

function get
  "Gets a value from the tree given a key."
  input Tree inTree;
  input Key inKey;
  output Value outValue;
protected
  Key key;
  Integer key_comp;
  Tree tree;
algorithm
  NODE(key = key) := inTree;
  key_comp := keyCompare(inKey, key);

  outValue := match (key_comp, inTree)
    case ( 0, NODE(value = outValue)) then outValue;
    case ( 1, NODE(right = tree)) then get(tree, inKey);
    case (-1, NODE(left = tree)) then get(tree, inKey);
  end match;
end get;

function toList
  "Converts the tree to a flat list of key-value tuples."
  input Tree inTree;
  input list<tuple<Key, Value>> inAccum = {};
  output list<tuple<Key, Value>> outList;
algorithm
  outList := match inTree
    local
      Key key;
      Value value;

    case NODE(key=key, value=value)
      algorithm
        outList := (key, value) :: inAccum;
        outList := toList(inTree.left, outList);
        outList := toList(inTree.right, outList);
      then
        outList;

    else inAccum;

  end match;
end toList;

function listValues
  "Constructs a list of all the values in the tree."
  input Tree tree;
  input list<Value> accum = {};
  output list<Value> values;
algorithm
  values := match tree
    local
      Value value;

    case NODE(value = value)
      algorithm
        values := value :: accum;
        values := listValues(tree.left, values);
        values := listValues(tree.right, values);
      then
        values;

    else accum;

  end match;
end listValues;

redeclare function join
  "Joins two trees by adding the second one to the first."
  input output Tree tree;
  input Tree treeToJoin;
  input ConflictFunc conflictFunc = addConflictDefault "Used to resolve conflicts.";

  partial function ConflictFunc
    input Value newValue "The value given by the caller.";
    input Value oldValue "The value already in the tree.";
    output Value value "The value that will replace the existing value.";
  end ConflictFunc;
algorithm
  tree := match treeToJoin
    case EMPTY() then tree;
    case NODE()
      algorithm
        tree := add(tree, treeToJoin.key, treeToJoin.value, conflictFunc=conflictFunc);
        tree := join(tree, treeToJoin.left, conflictFunc=conflictFunc);
        tree := join(tree, treeToJoin.right, conflictFunc=conflictFunc);
      then tree;
  end match;end join;

function map
  "Traverses the tree in depth-first pre-order and applies the given function to
   each node, constructing a new tree with the resulting nodes."
  input Tree inTree;
  input MapFunc inFunc;
  output Tree outTree = inTree;

  partial function MapFunc
    input Key inKey;
    input Value inValue;
    output Value outValue;
  end MapFunc;
algorithm
  outTree := match outTree
    local
      Key key;
      Value value, new_value;
      Tree branch, new_branch;

    case NODE(key=key, value=value)
      algorithm
        new_value := inFunc(key, value);
        if not referenceEq(value, new_value) then
          outTree.value := new_value;
        end if;

        new_branch := map(outTree.left, inFunc);
        if not referenceEq(new_branch, outTree.left) then
          outTree.left := new_branch;
        end if;

        new_branch := map(outTree.right, inFunc);
        if not referenceEq(new_branch, outTree.right) then
          outTree.right := new_branch;
        end if;
      then
        outTree;

    else inTree;
  end match;
end map;

function fold<FT>
  "Traverses the tree in depth-first pre-order and applies the given function to
   each node, in the process updating the given argument."
  input Tree inTree;
  input FoldFunc inFunc;
  input FT inStartValue;
  output FT outResult = inStartValue;

  partial function FoldFunc
    input Key inKey;
    input Value inValue;
    input FT inFoldArg;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  outResult := match inTree
    local
      Key key;
      Value value;
      Tree branch;

    case NODE(key=key, value=value)
      algorithm
        outResult := inFunc(key, value, outResult);
        outResult := fold(inTree.left, inFunc, outResult);
        outResult := fold(inTree.right, inFunc, outResult);
      then
        outResult;

    else outResult;
  end match;
end fold;

function mapFold<FT>
  "Traverses the tree in depth-first pre-order and applies the given function to
   each node, constructing a new tree with the resulting nodes. mapFold also
   takes an extra argument which is updated on each call to the given function."
  input Tree inTree;
  input MapFunc inFunc;
  input FT inStartValue;
  output Tree outTree = inTree;
  output FT outResult = inStartValue;

  partial function MapFunc
    input Key inKey;
    input Value inValue;
    input FT inFoldArg;
    output Value outValue;
    output FT outFoldArg;
  end MapFunc;
algorithm
  outTree := match outTree
    local
      Key key;
      Value value, new_value;
      Tree branch, new_branch;

    case NODE(key=key, value=value)
      algorithm
        (new_value, outResult) := inFunc(key, value, outResult);
        if not referenceEq(value, new_value) then
          outTree.value := new_value;
        end if;

        (new_branch, outResult) := mapFold(outTree.left, inFunc, outResult);
        if not referenceEq(new_branch, outTree.left) then
          outTree.left := new_branch;
        end if;

        (new_branch, outResult) := mapFold(outTree.right, inFunc, outResult);
        if not referenceEq(new_branch, outTree.right) then
          outTree.right := new_branch;
        end if;
      then
        outTree;

    else inTree;
  end match;
end mapFold;

annotation(__OpenModelica_Interface="util", __OpenModelica_isBaseClass=true);
end BaseAvlTree;
