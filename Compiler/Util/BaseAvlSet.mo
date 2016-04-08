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

encapsulated partial package BaseAvlSet

replaceable type Key = Integer;

replaceable uniontype Tree
  "The binary tree data structure."

  record NODE
    Key key "The key of the node.";
    Integer height "Height of tree, used for balancing";
    Tree left "Left subtree.";
    Tree right "Right subtree.";
  end NODE;

  record EMPTY end EMPTY;
end Tree;

replaceable type ValueNode = Key;

replaceable partial function keyStr
  "Prints a key to a string."
  input Key inKey;
  output String outString;
end keyStr;

replaceable partial function keyCompare
  "Compares two keys. It returns -1 if key1 is less than key2, 0 if they are
   equal, and 1 if key1 is larger than key2."
  input Key inKey1;
  input Key inKey2;
  output Integer outResult;
end keyCompare;

replaceable function printNodeStr
  input Tree inNode;
  output String outString;
algorithm
  outString := match inNode
    case NODE() then keyStr(inNode.key);
  end match;
end printNodeStr;

function new
  "Return an empty tree"
  output Tree outTree = EMPTY();
  annotation(__OpenModelica_EarlyInline = true);
end new;

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

    // Empty tree.
    case EMPTY()
      then NODE(inKey, 1, EMPTY(), EMPTY());

    case NODE(key = key)
      algorithm
        key_comp := keyCompare(inKey, key);

        if key_comp == -1 then
          // Replace left branch.
          tree.left := add(tree.left, inKey);
        elseif key_comp == 1 then
          // Replace right branch.
          tree.right := add(tree.right, inKey);
        else
          tree.key := inKey;
        end if;
      then
        if key_comp == 0 then tree else balance(tree);

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
    case EMPTY() algorithm return; then fail();
    case NODE() then inTree.key;
  end match;
  key_comp := keyCompare(inKey, key);

  comp := match (key_comp, inTree)
    case ( 0, _) then true;
    case ( 1, NODE(right = tree)) then hasKey(tree, inKey);
    case (-1, NODE(left = tree)) then hasKey(tree, inKey);
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
    case NODE()
      algorithm
        lst := listKeys(inTree.right, lst);
        lst := inTree.key::lst;
        lst := listKeys(inTree.left, lst);
      then
        lst;

    else lst;
  end match;
end listKeys;

replaceable function join
  "Joins two trees by adding the second one to the first."
  input output Tree tree;
  input Tree treeToJoin;
algorithm
  tree := match treeToJoin
    case EMPTY() then tree;
    case NODE()
      algorithm
        tree := add(tree, treeToJoin.key);
        tree := join(tree, treeToJoin.left);
        tree := join(tree, treeToJoin.right);
      then tree;
  end match;
end join;

function printTreeStr
  "Prints the tree to a string using UTF-8 box-drawing characters to construct a
   graphical view of the tree."
  input Tree inTree;
  output String outString;
protected
  Tree left, right;
algorithm
  NODE(left = left, right = right) := inTree;
  outString := printTreeStr2(left, true, "") +
               printNodeStr(inTree) + "\n" +
               printTreeStr2(right, false, "");
end printTreeStr;

protected

function balance
  "Balances a Tree"
  input Tree inTree;
  output Tree outTree = inTree;
algorithm
  outTree := match outTree
    local
      Integer lh, rh, diff;
      Tree child, balanced_tree;

    case NODE()
      algorithm
        lh := height(outTree.left);
        rh := height(outTree.right);
        diff := lh - rh;

        if diff < -1 then
          if calculateBalance(outTree.right) > 0 then
            outTree.right := rotateRight(outTree.right);
          end if;
          balanced_tree := rotateLeft(outTree);
        elseif diff > 1 then
          if calculateBalance(outTree.left) < 0 then
            outTree.left := rotateLeft(outTree.left);
          end if;
          balanced_tree := rotateRight(outTree);
        else
          outTree.height := max(lh, rh) + 1;
          balanced_tree := outTree;
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
    case NODE() then inNode.height;
    else 0;
  end match;
end height;

function calculateBalance
  input Tree inNode;
  output Integer outBalance;
algorithm
  outBalance := match inNode
    case NODE()
      then height(inNode.left) - height(inNode.right);

    else 0;
  end match;
end calculateBalance;

function rotateLeft
  "Performs an AVL left rotation on the given tree."
  input Tree inNode;
  output Tree outNode = inNode;
algorithm
  outNode := match outNode
    local
      Tree child;

    case NODE(right = child as NODE())
      algorithm
        outNode.right := child.left;
        outNode.height := max(height(outNode.left), height(outNode.right)) + 1;
        child.left := outNode;
        child.height := max(height(outNode), height(child.right)) + 1;
      then
        child;

    else inNode;

  end match;
end rotateLeft;

function rotateRight
  "Performs an AVL right rotation on the given tree."
  input Tree inNode;
  output Tree outNode = inNode;
algorithm
  outNode := match outNode
    local
      Tree child;

    case NODE(left = child as NODE())
      algorithm
        outNode.left := child.right;
        outNode.height := max(height(outNode.left), height(outNode.right)) + 1;
        child.right := outNode;
        child.height := max(height(child.left), height(outNode)) + 1;
      then
        child;

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
      then printTreeStr2(inTree.left, true, inIndent + (if isLeft then "     " else " │   ")) +
           inIndent + (if isLeft then " ┌" else " └") + "────" +
           printNodeStr(inTree) + "\n" +
           printTreeStr2(inTree.right, false, inIndent + (if isLeft then " │   " else "     "));

    else "";
  end match;
end printTreeStr2;

annotation(__OpenModelica_Interface="util", __OpenModelica_isBaseClass=true);
end BaseAvlSet;
