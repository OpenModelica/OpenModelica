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
    Option<ValueNode> value "The value stored in the node.";
    Integer height "Height of tree, used for balancing";
    Option<Tree> left "Left subtree.";
    Option<Tree> right "Right subtree.";
  end NODE;
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
  output Tree outTree = NODE(NONE(), 0, NONE(), NONE());
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
    case NODE(value = NONE(), left = NONE(), right = NONE())
      then NODE(SOME(VALUE(inKey, inValue)), 1, NONE(), NONE());

    case NODE(value = SOME(VALUE(key = key)))
      algorithm
        key_comp := keyCompare(inKey, key);

        if key_comp == 0 then
          // Replace node if allowed, otherwise fail.
          if inReplaceExisting then
            outTree.value := SOME(VALUE(inKey, inValue));
          else
            fail();
          end if;
        elseif key_comp == 1 then
          // Replace right branch.
          outTree.right := SOME(add(inKey, inValue, branchOrEmpty(outTree.right), inReplaceExisting));
        elseif key_comp == -1 then
          // Replace left branch.
          outTree.left := SOME(add(inKey, inValue, branchOrEmpty(outTree.left), inReplaceExisting));
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
  NODE(value = SOME(VALUE(key = key))) := inTree;
  key_comp := keyCompare(inKey, key);

  outValue := match (key_comp, inTree)
    case ( 0, NODE(value = SOME(VALUE(value = outValue)))) then outValue;
    case ( 1, NODE(right = SOME(tree))) then get(tree, key);
    case (-1, NODE(left = SOME(tree))) then get(tree, key);
  end match;
end get;

function toList
  "Converts the tree to a flat list of key-value tuples."
  input Tree inTree;
  output list<tuple<Key, Value>> outList = toList2(SOME(inTree));
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

    case NODE()
      algorithm
        if isSome(outTree.value) then
          SOME(VALUE(key, value)) := outTree.value;
          new_value := inFunc(key, value);
          if not referenceEq(value, new_value) then
            outTree.value := SOME(VALUE(key, new_value));
          end if;
        end if;

        if isSome(outTree.left) then
          SOME(branch) := outTree.left;
          new_branch := map(branch, inFunc);
          if not referenceEq(branch, new_branch) then
            outTree.left := SOME(new_branch);
          end if;
        end if;

        if isSome(outTree.right) then
          SOME(branch) := outTree.right;
          new_branch := map(branch, inFunc);
          if not referenceEq(branch, new_branch) then
            outTree.right := SOME(new_branch);
          end if;
        end if;
      then
        outTree;
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

    case NODE()
      algorithm
        if isSome(inTree.value) then
          SOME(VALUE(key, value)) := inTree.value;
          outResult := inFunc(key, value, outResult);
        end if;

        if isSome(inTree.left) then
          SOME(branch) := inTree.left;
          outResult := fold(branch, inFunc, outResult);
        end if;

        if isSome(inTree.right) then
          SOME(branch) := inTree.right;
          outResult := fold(branch, inFunc, outResult);
        end if;
      then
        outResult;
  end match;
end fold;

function printTreeStr
  "Prints the tree to a string using UTF-8 box-drawing characters to construct a
   graphical view of the tree."
  input Tree inTree;
  output String outString;
protected
  Option<ValueNode> val_node;
  Option<Tree> left, right;
algorithm
  NODE(value = val_node, left = left, right = right) := inTree;
  outString := printTreeStr2(left, true, "") +
               printNodeStr(val_node) + "\n" +
               printTreeStr2(right, false, "");
end printTreeStr;

protected

function toList2
  "Helper function to toList."
  input Option<Tree> inTree;
  input list<tuple<Key, Value>> inAccum = {};
  output list<tuple<Key, Value>> outList = inAccum;
protected
  Option<ValueNode> ovalue;
  Option<Tree> left, right;
  Key key;
  Value value;
algorithm
  if isSome(inTree) then
    SOME(NODE(value = ovalue, left = left, right = right)) := inTree;

    if isSome(ovalue) then
      SOME(VALUE(key = key, value = value)) := ovalue;
      outList := (key, value) :: outList;
    end if;

    outList := toList2(left, outList);
    outList := toList2(right, outList);
  end if;
end toList2;

function branchOrEmpty
  "Returns the given branch, or an empty node if the node is NONE."
  input Option<Tree> inBranch;
  output Tree outBranch;
algorithm
  outBranch := match inBranch
    case SOME(outBranch) then outBranch;
    else NODE(NONE(), 0, NONE(), NONE());
  end match;
end branchOrEmpty;

function printTreeStr2
  "Helper function to printTreeStr."
  input Option<Tree> inTree;
  input Boolean isLeft;
  input String inIndent;
  output String outString;
protected
  Option<ValueNode> val_node;
  Option<Tree> left, right;
  String left_str, right_str;
algorithm
  if isNone(inTree) then
    outString := "";
  else
    SOME(NODE(value = val_node, left = left, right = right)) := inTree;
    outString := printTreeStr2(left, true, inIndent + (if isLeft then "     " else " │   ")) +
                 inIndent + (if isLeft then " ┌" else " └") + "────" +
                 printNodeStr(val_node) + "\n" +
                 printTreeStr2(right, false, inIndent + (if isLeft then " │   " else "     "));
  end if;
end printTreeStr2;

function printNodeStr
  "Helper function to printTreeStr."
  input Option<ValueNode> inNode;
  output String outString;
algorithm
  outString := match inNode
    local
      Key key;
      Value value;

    case SOME(VALUE(key = key, value = value))
      then "(" + keyStr(key) + ", " + valueStr(value) + ")";
    else "()";
  end match;
end printNodeStr;

function balance
  "Balances a Tree"
  input Tree inTree;
  output Tree outTree = inTree;
algorithm
  outTree := match outTree
    local
      Integer lh, rh, diff;
      Tree child;

    case NODE()
      algorithm
        lh := getHeight(outTree.left);
        rh := getHeight(outTree.right);
        diff := lh - rh;

        if diff < -1 then
          if isSome(outTree.right) and differenceInHeight(outTree.right) > 0 then
            SOME(child) := outTree.right;
            outTree.right := SOME(rotateRight(child));
          end if;
          outTree := rotateLeft(outTree);
        elseif diff > 1 then
          if isSome(outTree.left) and differenceInHeight(outTree.left) < 0 then
            SOME(child) := outTree.left;
            outTree.left := SOME(rotateLeft(child));
          end if;
          outTree := rotateRight(outTree);
        else
          outTree.height := max(lh, rh) + 1;
        end if;
      then
        outTree;

  end match;
end balance;

function differenceInHeight
  "Returns the difference in height for the given tree."
  input Option<Tree> inNode;
  output Integer outDiff;
algorithm
  outDiff := match inNode
    local
      Tree node;

    case SOME(node as NODE()) then getHeight(node.left) - getHeight(node.right);
    else 0;
  end match;
end differenceInHeight;

function rotateRight
  "Performs an AVL right rotation on the given tree."
  input Tree inNode;
  output Tree outNode = inNode;
algorithm
  outNode := match outNode
    local
      Tree child;

    case NODE(right = SOME(child as NODE()))
      algorithm
        outNode.left := child.right;
        outNode := balance(outNode);
        child.right := SOME(outNode);
      then
        balance(child);

  end match;
end rotateRight;

function rotateLeft
  "Performs an AVL left rotation on the given tree."
  input Tree inNode;
  output Tree outNode = inNode;
algorithm
  outNode := match outNode
    local
      Tree child;

    case NODE(right = SOME(child as NODE()))
      algorithm
        outNode.right := child.left;
        outNode := balance(outNode);
        child.left := SOME(outNode);
      then
        balance(child);

  end match;
end rotateLeft;

function getHeight
  "Retrieves the height of a node."
  input Option<Tree> inNode;
  output Integer outHeight;
algorithm
  outHeight := match inNode
    case NONE() then 0;
    case SOME(NODE(height = outHeight)) then outHeight;
  end match;
end getHeight;

annotation(__OpenModelica_Interface="util", __OpenModelica_isBaseClass=true);
end BaseAvlTree;
