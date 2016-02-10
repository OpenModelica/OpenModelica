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

replaceable type Key = Integer; // TODO: We should have an Any type
replaceable type Value = Integer; // TODO: We should have an Any type

uniontype Tree
  "The binary tree data structure."

  record NODE
    ValueNode value "The value stored in the node.";
    Integer height "Height of tree, used for balancing";
    Tree left "Left subtree.";
    Tree right "Right subtree.";
  end NODE;

  record EMPTY end EMPTY;
end Tree;

uniontype ValueNode
  "Each node in the binary tree can have a value associated with it."

  record VALUE
    Key key "Key" ;
    Value value "Value" ;
  end VALUE;
end ValueNode;

replaceable partial function keyStr
  "Prints a key to a string."
  input Key inKey;
  output String outString;
end keyStr;

replaceable partial function valueStr
  "Prints a Value to a string."
  input Value inValue;
  output String outString;
end valueStr;

replaceable partial function keyCompare
  "Compares two keys. It returns -1 if key1 is less than key2, 0 if they are
   equal, and 1 if key1 is larger than key2."
  input Key inKey1;
  input Key inKey2;
  output Integer outResult;
end keyCompare;

function new
  "Return an empty tree"
  output Tree outTree = EMPTY();
  annotation(__OpenModelica_EarlyInline = true);
end new;

function add
  "Inserts a new node in the tree."
  input Key inKey;
  input Value inValue;
  input Tree inTree;
  input Boolean inReplaceExisting = true;
  output Tree outTree = inTree;
algorithm
  outTree := match outTree
    local
      Key key;
      Integer key_comp;

    // Empty tree.
    case EMPTY()
      then NODE(VALUE(inKey, inValue), 1, EMPTY(), EMPTY());

    case NODE(value = VALUE(key = key))
      algorithm
        key_comp := keyCompare(inKey, key);

        if key_comp == -1 then
          // Replace left branch.
          outTree.left := add(inKey, inValue, outTree.left, inReplaceExisting);
        elseif key_comp == 1 then
          // Replace right branch.
          outTree.right := add(inKey, inValue, outTree.right, inReplaceExisting);
        elseif inReplaceExisting then
          // Replace node if allowed.
          outTree.value := VALUE(inKey, inValue);
        else
          // Fail if not allowed to replace existing node.
          fail();
        end if;
      then
        if key_comp == 0 then outTree else balance(outTree);

  end match;
end add;

function addList
  "Adds a list of key-value pairs to the tree."
  input list<tuple<Key,Value>> inValues;
  input Tree inTree;
  input Boolean inReplaceExisting = true;
  output Tree outTree = inTree;
protected
  Key key;
  Value value;
algorithm
  for t in inValues loop
    (key, value) := t;
    outTree := add(key, value, outTree, inReplaceExisting);
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
  NODE(value = VALUE(key = key)) := inTree;
  key_comp := keyCompare(inKey, key);

  outValue := match (key_comp, inTree)
    case ( 0, NODE(value = VALUE(value = outValue))) then outValue;
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

    case NODE(value = VALUE(key, value))
      algorithm
        outList := (key, value) :: inAccum;
        outList := toList(inTree.left, outList);
        outList := toList(inTree.right, outList);
      then
        outList;

    else inAccum;

  end match;
end toList;

function join
  "Joins two trees by adding the second one to the first."
  input Tree inTree1;
  input Tree inTree2;
  output Tree outTree;
algorithm
  outTree := addList(toList(inTree2), inTree1);
end join;

function map
  "Traverses the tree in depth-first pre-order and applies the given function to
   each node, changing their values to the result of the call."
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

    case NODE(value = VALUE(key, value))
      algorithm
        new_value := inFunc(key, value);
        if not referenceEq(value, new_value) then
          outTree.value := VALUE(key, new_value);
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

    case NODE(value = VALUE(key, value))
      algorithm
        outResult := inFunc(key, value, outResult);
        outResult := fold(inTree.left, inFunc, outResult);
        outResult := fold(inTree.right, inFunc, outResult);
      then
        outResult;

    else outResult;
  end match;
end fold;

function printTreeStr
  "Prints the tree to a string using UTF-8 box-drawing characters to construct a
   graphical view of the tree."
  input Tree inTree;
  output String outString;
protected
  ValueNode val_node;
  Tree left, right;
algorithm
  NODE(value = val_node, left = left, right = right) := inTree;
  outString := printTreeStr2(left, true, "") +
               printNodeStr(val_node) + "\n" +
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
           printNodeStr(inTree.value) + "\n" +
           printTreeStr2(inTree.right, false, inIndent + (if isLeft then " │   " else "     "));

    else "";
  end match;
end printTreeStr2;

function printNodeStr
  input ValueNode inNode;
  output String outString;
protected
  Key key;
  Value value;
algorithm
  VALUE(key = key, value = value) := inNode;
  outString := "(" + keyStr(key) + ", " + valueStr(value) + ")";
end printNodeStr;

annotation(__OpenModelica_Interface="util", __OpenModelica_isBaseClass=true);
end BaseAvlTree;
