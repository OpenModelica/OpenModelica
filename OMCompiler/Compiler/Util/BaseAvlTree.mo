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

  record LEAF
    Key key "The key of the node.";
    Value value;
  end LEAF;

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
    case LEAF() then "(" + keyStr(inNode.key) + ", " + valueStr(inNode.value) + ")";
  end match;
end printNodeStr;

partial function ConflictFunc
  input Value newValue "The value given by the caller.";
  input Value oldValue "The value already in the tree.";
  input Key key "The key associated with the values.";
  output Value value "The value that will replace the existing value.";
end ConflictFunc;

replaceable function addConflictDefault = addConflictFail
  "Default conflict resolving function for add.";

function addConflictFail
  "Conflict resolving function for add which fails on conflict."
  input Value newValue;
  input Value oldValue;
  input Key key;
  output Value value;
algorithm
  fail();
end addConflictFail;

function addConflictReplace
  "Conflict resolving function for add which replaces the old value with the new."
  input Value newValue;
  input Value oldValue;
  input Key key;
  output Value value = newValue;
end addConflictReplace;

function addConflictKeep
  "Conflict resolving function for add which keeps the old value."
  input Value newValue;
  input Value oldValue;
  input Key key;
  output Value value = oldValue;
end addConflictKeep;

redeclare function add
  "Inserts a new node in the tree."
  input Tree inTree;
  input Key inKey;
  input Value inValue;
  input ConflictFunc conflictFunc = addConflictDefault "Used to resolve conflicts.";
  output Tree tree=inTree;
algorithm
  tree := match tree
    local
      Key key;
      Value value;
      Integer key_comp;
      Tree outTree;

    // Empty tree.
    case EMPTY()
      then LEAF(inKey, inValue);

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
          value := conflictFunc(inValue, tree.value, key);
          if not referenceEq(tree.value, value) then
            tree.value := value;
          end if;
        end if;
      then
        if key_comp == 0 then tree else balance(tree);

    case LEAF(key = key)
      algorithm
        key_comp := keyCompare(inKey, key);

        if key_comp == -1 then
          // Replace left branch.
          outTree := NODE(tree.key, tree.value, 2, LEAF(inKey,inValue), EMPTY());
        elseif key_comp == 1 then
          // Replace right branch.
          outTree := NODE(tree.key, tree.value, 2, EMPTY(), LEAF(inKey,inValue));
        else
          // Use the given function to resolve the conflict.
          value := conflictFunc(inValue, tree.value, key);
          if not referenceEq(tree.value, value) then
            tree.value := value;
          end if;
          outTree := tree;
        end if;
      then
        if key_comp == 0 then outTree else balance(outTree);

  end match;
end add;

redeclare function addList
  "Adds a list of key-value pairs to the tree."
  input output Tree tree;
  input list<tuple<Key,Value>> inValues;
  input ConflictFunc conflictFunc = addConflictDefault "Used to resolve conflicts.";
protected
  Key key;
  Value value;
algorithm
  for t in inValues loop
    (key, value) := t;
    tree := add(tree, key, value, conflictFunc);
  end for;
end addList;

function update
  "Alias for add that replaces the node in case of conflict."
  input Tree tree;
  input Key key;
  input Value value;
  output Tree outTree = add(tree, key, value, addConflictReplace);
end update;

function get
  "Fetches a value from the tree given a key, or fails if no value is associated
   with the key."
  input Tree tree;
  input Key key;
  output Value value;
protected
  Key k;
algorithm
  k := match tree
    case NODE() then tree.key;
    case LEAF() then tree.key;
  end match;

  value := match (keyCompare(key, k), tree)
    case ( 0, LEAF()) then tree.value;
    case ( 0, NODE()) then tree.value;
    case ( 1, NODE()) then get(tree.right, key);
    case (-1, NODE()) then get(tree.left, key);
  end match;
end get;

function getOpt
  "Fetches a value from the tree given a key, or returns NONE if no value is
   associated with the key."
  input Tree tree;
  input Key key;
  output Option<Value> value;
protected
  Key k;
algorithm
  k := match tree
    case NODE() then tree.key;
    case LEAF() then tree.key;
    else key;
  end match;

  value := match (keyCompare(key, k), tree)
    case ( 0, LEAF()) then SOME(tree.value);
    case ( 0, NODE()) then SOME(tree.value);
    case ( 1, NODE()) then getOpt(tree.right, key);
    case (-1, NODE()) then getOpt(tree.left, key);
    else NONE();
  end match;
end getOpt;

function fromList
  "Creates a new tree from a list of key-value pairs."
  input list<tuple<Key,Value>> inValues;
  input ConflictFunc conflictFunc = addConflictDefault "Used to resolve conflicts.";
  output Tree tree = EMPTY();
protected
  Key key;
  Value value;
algorithm
  for t in inValues loop
    (key, value) := t;
    tree := add(tree, key, value, conflictFunc);
  end for;
end fromList;

function toList
  "Converts the tree to a flat list of key-value tuples."
  input Tree inTree;
  input output list<tuple<Key, Value>> lst = {};
algorithm
  lst := match inTree
    local
      Key key;
      Value value;

    case NODE(key=key, value=value)
      algorithm
        lst := toList(inTree.right, lst);
        lst := (key, value) :: lst;
        lst := toList(inTree.left, lst);
      then lst;

    case LEAF(key=key, value=value)
      then (key, value) :: lst;

    else lst;

  end match;
end toList;

function listValues
  "Constructs a list of all the values in the tree."
  input Tree tree;
  input output list<Value> lst = {};
algorithm
  lst := match tree
    local
      Value value;

    case NODE(value = value)
      algorithm
        lst := listValues(tree.right, lst);
        lst := value :: lst;
        lst := listValues(tree.left, lst);
      then lst;

    case LEAF(value = value) then value :: lst;

    else lst;

  end match;
end listValues;

redeclare function join
  "Joins two trees by adding the second one to the first."
  input output Tree tree;
  input Tree treeToJoin;
  input ConflictFunc conflictFunc = addConflictDefault "Used to resolve conflicts.";
algorithm
  tree := match treeToJoin
    case EMPTY() then tree;
    case NODE()
      algorithm
        tree := add(tree, treeToJoin.key, treeToJoin.value, conflictFunc);
        tree := join(tree, treeToJoin.left, conflictFunc);
        tree := join(tree, treeToJoin.right, conflictFunc);
      then tree;
    case LEAF() then add(tree, treeToJoin.key, treeToJoin.value, conflictFunc);
  end match;
end join;

function forEach
  "Traverses the tree in depth-first pre-order and applies the given function to
   each node, but without constructing a new tree like with map."
  input Tree tree;
  input EachFunc func;

  partial function EachFunc
    input Key key;
    input Value value;
  end EachFunc;
algorithm
  _ := match tree
    case NODE()
      algorithm
        forEach(tree.left, func);
        func(tree.key, tree.value);
        forEach(tree.right, func);
      then
        ();

    case LEAF()
      algorithm
        func(tree.key, tree.value);
      then
        ();

    case EMPTY() then ();
  end match;
end forEach;

redeclare function intersection
algorithm
  fail();
end intersection;

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
      Tree branch, new_left, new_right;

    case NODE(key=key, value=value)
      algorithm
        new_left := map(outTree.left, inFunc);
        new_value := inFunc(key, value);
        new_right := map(outTree.right, inFunc);
        if not referenceEq(new_left, outTree.left) or not referenceEq(value, new_value) or not referenceEq(new_right, outTree.right) then
          outTree := NODE(key, new_value, outTree.height, new_left, new_right);
        end if;
      then
        outTree;

    case LEAF(key=key, value=value)
      algorithm
        new_value := inFunc(key, value);
        if not referenceEq(value, new_value) then
          outTree.value := new_value;
        end if;
      then outTree;

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

    case NODE(key=key, value=value)
      algorithm
        outResult := fold(inTree.left, inFunc, outResult);
        outResult := inFunc(key, value, outResult);
        outResult := fold(inTree.right, inFunc, outResult);
      then
        outResult;

    case LEAF(key=key, value=value)
      algorithm
        outResult := inFunc(key, value, outResult);
      then outResult;

    else outResult;
  end match;
end fold;

function fold_2<FT1, FT2>
  "Like fold, but takes two fold arguments."
  input Tree tree;
  input FoldFunc foldFunc;
  input output FT1 foldArg1;
  input output FT2 foldArg2;

  partial function FoldFunc
    input Key key;
    input Value value;
    input output FT1 foldArg1;
    input output FT2 foldArg2;
  end FoldFunc;
algorithm
  () := match tree
    case NODE()
      algorithm
        (foldArg1, foldArg2) := fold_2(tree.left, foldFunc, foldArg1, foldArg2);
        (foldArg1, foldArg2) := foldFunc(tree.key, tree.value, foldArg1, foldArg2);
        (foldArg1, foldArg2) := fold_2(tree.right, foldFunc, foldArg1, foldArg2);
      then
        ();

    case LEAF()
      algorithm
        (foldArg1, foldArg2) := foldFunc(tree.key, tree.value, foldArg1, foldArg2);
      then
        ();

    else ();
  end match;
end fold_2;

function foldCond<FT>
  "Like fold, but if the fold function returns false it will not continue down
   into the tree (but will still continue with other branches)."
  input Tree tree;
  input FoldFunc foldFunc;
  input output FT value;

  partial function FoldFunc
    input Key key;
    input Value value;
    input output FT foldArg;
          output Boolean cont;
  end FoldFunc;
algorithm
  value := match tree
    local
      Boolean c;

    case NODE()
      algorithm
        (value, c) := foldFunc(tree.key, tree.value, value);

        if c then
          value := foldCond(tree.left, foldFunc, value);
          value := foldCond(tree.right, foldFunc, value);
        end if;
      then
        value;

    case LEAF()
      algorithm
        (value, c) := foldFunc(tree.key, tree.value, value);
      then
        value;

    else value;
  end match;
end foldCond;

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
      Tree branch, new_left, new_right;

    case NODE(key=key, value=value)
      algorithm
        (new_left, outResult) := mapFold(outTree.left, inFunc, outResult);
        (new_value, outResult) := inFunc(key, value, outResult);
        (new_right, outResult) := mapFold(outTree.right, inFunc, outResult);
        if not referenceEq(new_left, outTree.left) or not referenceEq(value, new_value) or not referenceEq(new_right, outTree.right) then
          outTree := NODE(key, new_value, outTree.height, new_left, new_right);
        end if;
      then outTree;

    case LEAF(key=key, value=value)
      algorithm
        (new_value, outResult) := inFunc(key, value, outResult);
        if not referenceEq(value, new_value) then
          outTree.value := new_value;
        end if;
      then outTree;

    else inTree;
  end match;
end mapFold;

redeclare function setTreeLeftRight
  input Tree orig, left=EMPTY(), right=EMPTY();
  output Tree res;
algorithm
  res := match (orig,left,right)
    case (NODE(),EMPTY(),EMPTY()) then LEAF(orig.key, orig.value);
    case (LEAF(),EMPTY(),EMPTY()) then orig;
    case (NODE(),_,_) then
      if referenceEqOrEmpty(orig.left, left) and referenceEqOrEmpty(orig.right, right)
      then orig
      else NODE(orig.key, orig.value, max(height(left),height(right))+1, left, right);
    case (LEAF(),_,_) then NODE(orig.key, orig.value, max(height(left),height(right))+1, left, right);
  end match;
end setTreeLeftRight;
annotation(__OpenModelica_Interface="util", __OpenModelica_isBaseClass=true);
end BaseAvlTree;
