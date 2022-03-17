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

encapsulated package AvlSetInt

import Mutable;

  type Key = Integer;

  uniontype Tree
  "The binary tree data structure."

  record NODE
    Mutable<Key> key "The key of the node.";
    Mutable<Integer> height "Height of tree, used for balancing";
    Mutable<Tree> left "Left subtree.";
    Mutable<Tree> right "Right subtree.";
  end NODE;

  record LEAF
    Key key "The key of the node.";
  end LEAF;

  record EMPTY end EMPTY;
end Tree;

public constant Tree EMPTY_TREE = EMPTY();

replaceable type ValueNode = Key;

function keyStr
  "Prints a key to a string."
  input Key inKey;
  output String outString;
algorithm
  outString := String(inKey);
end keyStr;

replaceable function keyCompare
  "Compares two keys. It returns -1 if key1 is less than key2, 0 if they are
   equal, and 1 if key1 is larger than key2."
  input Key inKey1;
  input Key inKey2;
  output Integer outResult;
algorithm
  outResult := sign(inKey2-inKey1);
end keyCompare;

replaceable function printNodeStr
  input Tree inNode;
  output String outString;
algorithm
  outString := match inNode
    case NODE() then keyStr(Mutable.access(inNode.key));
    case LEAF() then keyStr(inNode.key);
  end match;
end printNodeStr;

function new
  "Return an empty tree"
  output Tree outTree = EMPTY_TREE;
  annotation(__OpenModelica_EarlyInline = true);
end new;

function newNODE
  "create a NODE"
  input Key key;
  input Integer height;
  input Tree left;
  input Tree right;
  output Tree outTree = NODE(Mutable.create(key), Mutable.create(height), Mutable.create(left), Mutable.create(right));
  annotation(__OpenModelica_EarlyInline = true);
end newNODE;

replaceable function add
  "Inserts a new node in the tree."
  input Tree inTree;
  input Key inKey;
  output Tree tree=inTree;
algorithm
  tree := match tree
    local
      Key key;
      Integer key_comp;
      Tree outTree;

    // Empty tree.
    case EMPTY()
      then LEAF(inKey);

    case NODE()
      algorithm
        key := Mutable.access(tree.key);
        key_comp := keyCompare(inKey, key);

        if key_comp == -1 then
          // Replace left branch.
          Mutable.update(tree.left, add(Mutable.access(tree.left), inKey));
        elseif key_comp == 1 then
          // Replace right branch.
          Mutable.update(tree.right, add(Mutable.access(tree.right), inKey));
        end if;
      then
        if key_comp == 0 then tree else balance(tree);

    case LEAF(key = key)
      algorithm
        key_comp := keyCompare(inKey, key);

        if key_comp == -1 then
          // Replace left branch.
          outTree := NODE(Mutable.create(tree.key), Mutable.create(2), Mutable.create(LEAF(inKey)), Mutable.create(EMPTY_TREE));
        elseif key_comp == 1 then
          // Replace right branch.
          outTree := NODE(Mutable.create(tree.key), Mutable.create(2), Mutable.create(EMPTY_TREE), Mutable.create(LEAF(inKey)));
        else
          outTree := tree;
        end if;
      then outTree; // No need to balance addition in a leaf

  end match;
end add;

replaceable function addList
  "Adds a list of key-value pairs to the tree."
  input output Tree tree;
  input list<Key> inValues;
algorithm
  for key in inValues loop
    tree := add(tree, key);
  end for;
end addList;

function hasKey
  "Gets a value from the tree given a key."
  input Tree inTree;
  input Key inKey;
  output Boolean comp=false;
protected
  Key key;
  Integer key_comp;
  Tree tree;
algorithm
  key := match inTree
    case NODE() then Mutable.access(inTree.key);
    case LEAF() then inTree.key;
    case EMPTY() algorithm return; then fail();
  end match;
  key_comp := keyCompare(inKey, key);

  comp := match (key_comp, inTree)
    case ( 0, _) then true;
    case ( 1, NODE()) then hasKey(Mutable.access(inTree.right), inKey);
    case (-1, NODE()) then hasKey(Mutable.access(inTree.left), inKey);
    else false;
  end match;
end hasKey;

function isEmpty
  input Tree tree;
  output Boolean isEmpty;
algorithm
  isEmpty := match tree
    case EMPTY() then true;
    else false;
  end match;
end isEmpty;

function listKeys
  "Converts the tree to a flat list of keys (in order)."
  input Tree inTree;
  input output list<Key> lst={};
algorithm
  lst := match inTree
    case LEAF() then inTree.key::lst;
    case NODE()
      algorithm
        lst := listKeys(Mutable.access(inTree.right), lst);
        lst := Mutable.access(inTree.key)::lst;
        lst := listKeys(Mutable.access(inTree.left), lst);
      then
        lst;

    else lst;
  end match;
end listKeys;

function listKeysReverse
  "Converts the tree to a flat list of keys (in order)."
  input Tree inTree;
  input output list<Key> lst={};
algorithm
  lst := match inTree
    case LEAF() then inTree.key::lst;
    case NODE()
      algorithm
        lst := listKeysReverse(Mutable.access(inTree.left), lst);
        lst := Mutable.access(inTree.key)::lst;
        lst := listKeysReverse(Mutable.access(inTree.right), lst);
      then
        lst;

    else lst;
  end match;
end listKeysReverse;

replaceable function join
  "Joins two trees by adding the second one to the first."
  input output Tree tree;
  input Tree treeToJoin;
algorithm
  tree := match treeToJoin
    case EMPTY() then tree;
    case NODE()
      algorithm
        tree := add(tree, Mutable.access(treeToJoin.key));
        tree := join(tree, Mutable.access(treeToJoin.left));
        tree := join(tree, Mutable.access(treeToJoin.right));
      then tree;
    case LEAF() then add(tree, treeToJoin.key);
  end match;
end join;

function printTreeStr
  "Prints the tree to a string using UTF-8 box-drawing characters to construct a
   graphical view of the tree."
  input Tree inTree;
  output String outString;
algorithm
  outString := match inTree
    case EMPTY() then "EMPTY()";
    case LEAF() then printNodeStr(inTree);
    case NODE() then printTreeStr2(Mutable.access(inTree.left), true, "") +
               printNodeStr(inTree) + "\n" +
               printTreeStr2(Mutable.access(inTree.right), false, "");
  end match;
end printTreeStr;

replaceable function setTreeLeftRight
  input Tree orig, left=EMPTY_TREE, right=EMPTY_TREE;
  output Tree res;
algorithm
  res := match (orig,left,right)
    case (NODE(),EMPTY(),EMPTY()) then LEAF(Mutable.access(orig.key));
    case (LEAF(),EMPTY(),EMPTY()) then orig;
//    case (NODE(),_,_) then
//      if referenceEqOrEmpty(orig.left, left) and referenceEqOrEmpty(orig.right, right)
//      then orig
//      else NODE(orig.key, max(height(left),height(right))+1, left, right);

    case (res as NODE(),_,_) algorithm
        Mutable.update(res.height, max(height(left),height(right))+1);
        Mutable.update(res.left, left);
        Mutable.update(res.right, right);
      then res;
    case (LEAF(),_,_) then NODE(Mutable.create(orig.key), Mutable.create(max(height(left),height(right))+1), Mutable.create(left), Mutable.create(right));
  end match;
end setTreeLeftRight;

function intersection
  "Takes two sets and returns the intersection as well as the remainder
  of both sets after removing the duplicates in both sets."
  input Tree tree1, tree2;
  output Tree intersect=EMPTY_TREE, rest1=EMPTY_TREE, rest2=EMPTY_TREE;
protected
  list<Key> keylist1, keylist2;
  Key k1, k2;
  Integer key_comp;
algorithm
  if isEmpty(tree1) then
    rest2 := tree2;
    return;
  end if;
  if isEmpty(tree2) then
    rest1 := tree1;
    return;
  end if;

  // we operate on sorted lists from the trees!
  k1::keylist1 := listKeys(tree1);
  k2::keylist2 := listKeys(tree2);
  while true loop
    key_comp := keyCompare(k1, k2);
    if key_comp > 0 then
      if isPresent(rest2) then rest2 := add(rest2, k2); end if;
      if listEmpty(keylist2) then break; end if;
      k2::keylist2 := keylist2;
    elseif key_comp < 0 then
      if isPresent(rest1) then rest1 := add(rest1, k1); end if;
      if listEmpty(keylist1) then break; end if;
      k1::keylist1 := keylist1;
    else // equal keys: advance both lists
      intersect := add(intersect, k1);
      if listEmpty(keylist1) or listEmpty(keylist2) then break; end if;
      k1::keylist1 := keylist1;
      k2::keylist2 := keylist2;
    end if;
  end while;
  if isPresent(rest1) and not listEmpty(keylist1) then
    rest1 := addList(rest1, keylist1);
  end if;
  if isPresent(rest2) and not listEmpty(keylist2) then
    rest2 := addList(rest2, keylist2);
  end if;
end intersection;

protected

function referenceEqOrEmpty
  input Tree t1,t2;
  output Boolean b;
algorithm
  b := match (t1,t2)
    case (EMPTY(),EMPTY()) then true;
    else referenceEq(t1,t2);
  end match;
end referenceEqOrEmpty;

function balance
  "Balances a Tree"
  input Tree inTree;
  output Tree outTree = inTree;
algorithm
  outTree := match inTree
    local
      Integer lh, rh, diff;
      Tree left, right, child, balanced_tree;

    case LEAF() then inTree;

    case child as NODE()
      algorithm
        left := Mutable.access(child.left);
        right := Mutable.access(child.right);
        lh := height(left);
        rh := height(right);
        diff := lh - rh;

        if diff < -1 then
          balanced_tree := if calculateBalance(right) > 0
            then rotateLeft(setTreeLeftRight(inTree, left=left, right=rotateRight(right)))
            else rotateLeft(inTree);
        elseif diff > 1 then
          balanced_tree := if calculateBalance(left) < 0
            then rotateRight(setTreeLeftRight(inTree, left=rotateLeft(left), right=right))
            else rotateRight(inTree);
        elseif Mutable.access(inTree.height) <> max(lh, rh) + 1 then
          Mutable.update(inTree.height, max(lh, rh) + 1);
          balanced_tree := inTree;
        else
          balanced_tree := inTree;
        end if;
      then
        balanced_tree;

  end match;
end balance;

function height
  input Tree inNode;
  output Integer outHeight;
algorithm
  outHeight := match inNode
    case NODE() then Mutable.access(inNode.height);
    case LEAF() then 1;
    else 0;
  end match;
end height;

function calculateBalance
  input Tree inNode;
  output Integer outBalance;
algorithm
  outBalance := match inNode
    case NODE()
      then height(Mutable.access(inNode.left)) - height(Mutable.access(inNode.right));
    case LEAF() then 0;
    else 0;
  end match;
end calculateBalance;

function rotateLeft
  "Performs an AVL left rotation on the given tree."
  input Tree inNode;
  output Tree outNode = inNode;
algorithm
  outNode := match inNode
    local
      Tree node, child;

    case NODE()
      algorithm
        child := Mutable.access(inNode.right);
        outNode := match child
          case NODE()
            algorithm
              node := setTreeLeftRight(inNode, left=Mutable.access(inNode.left), right=Mutable.access(child.left));
            then setTreeLeftRight(child, left=node, right=Mutable.access(child.right));

          case LEAF()
            algorithm
              node := setTreeLeftRight(inNode, left=Mutable.access(inNode.left), right=EMPTY_TREE);
            then setTreeLeftRight(child, left=node, right=EMPTY_TREE);

          else
            inNode;
          end match;
        then outNode;
    else inNode;
  end match;
end rotateLeft;

function rotateRight
  "Performs an AVL right rotation on the given tree."
  input Tree inNode;
  output Tree outNode = inNode;
algorithm
  outNode := match inNode
    local
      Tree node, child;

    case NODE()
      algorithm
        child := Mutable.access(inNode.left);
        outNode := match child
          case NODE()
            algorithm
              node := setTreeLeftRight(inNode, left=Mutable.access(child.right), right=Mutable.access(inNode.right));
            then setTreeLeftRight(child, right=node, left=Mutable.access(child.left));

          case LEAF()
            algorithm
              node := setTreeLeftRight(inNode, left=EMPTY_TREE, right=Mutable.access(inNode.right));
            then setTreeLeftRight(child, right=node, left=EMPTY_TREE);

          else
            inNode;
        end match;
        then outNode;

    else inNode;
  end match;
end rotateRight;

function printTreeStr2
  "Helper function to printTreeStr."
  input Tree inTree;
  input Boolean isLeft;
  input String inIndent;
  output String outString;
protected
  Option<ValueNode> val_node;
  Option<Tree> left, right;
  String left_str, right_str;
algorithm
  outString := match inTree
    case NODE()
      then printTreeStr2(Mutable.access(inTree.left), true, inIndent + (if isLeft then "     " else " │   ")) +
           inIndent + (if isLeft then " ┌" else " └") + "────" +
           printNodeStr(inTree) + "\n" +
           printTreeStr2(Mutable.access(inTree.right), false, inIndent + (if isLeft then " │   " else "     "));

    else "";
  end match;
end printTreeStr2;
annotation(__OpenModelica_Interface="backend");
end AvlSetInt;
