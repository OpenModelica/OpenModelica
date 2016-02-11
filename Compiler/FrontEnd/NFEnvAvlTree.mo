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

encapsulated package NFEnvAvlTree
" file:        NFEnvAvlTree.mo
  package:     NFEnvAvlTree
  description: AvlTree implementation for NFEnv


  This package implements an AvlTree that's used by NFEnv.
"

public import NFInstTypes;

protected import Error;
protected import Util;

public type AvlTree = NFInstTypes.AvlTree;
public type AvlTreeValue = NFInstTypes.AvlTreeValue;
public type AvlKey = NFInstTypes.AvlKey;
public type AvlValue = NFInstTypes.AvlValue;

public constant AvlTree emptyAvlTree = NFInstTypes.AVLTREENODE(NONE(), 0, NONE(), NONE());

public function new
  "Return an empty tree"
  output AvlTree tree;
algorithm
  tree := emptyAvlTree;
end new;

public function add
  "Inserts a new value into the tree. If the key already exists, then the value
   is updated with the given update function."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input AvlValue inValue;
  input UpdateFunc inUpdateFunc;
  output AvlTree outAvlTree;

  partial function UpdateFunc
    input AvlValue inOldValue;
    input AvlValue inNewValue;
    output AvlValue outValue;
  end UpdateFunc;
algorithm
  outAvlTree := match(inAvlTree, inKey, inValue, inUpdateFunc)
    local
      AvlKey key;
      Integer key_comp;
      AvlTree tree;

    // Empty node, create a new node for the value.
    case (NFInstTypes.AVLTREENODE(value = NONE(), left = NONE(), right = NONE()), _, _, _)
      then NFInstTypes.AVLTREENODE(SOME(NFInstTypes.AVLTREEVALUE(inKey, inValue)), 1, NONE(), NONE());

    case (NFInstTypes.AVLTREENODE(value = SOME(NFInstTypes.AVLTREEVALUE(key = key))), _, _, _)
      equation
        key_comp = stringCompare(inKey, key);
        tree = add2(inAvlTree, key_comp, inKey, inValue, inUpdateFunc);
        tree = balance(tree);
      then
        tree;

  end match;
end add;

protected function add2
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  input AvlValue inValue;
  input UpdateFunc inUpdateFunc;
  output AvlTree outAvlTree;

  partial function UpdateFunc
    input AvlValue inOldValue;
    input AvlValue inNewValue;
    output AvlValue outValue;
  end UpdateFunc;
algorithm
  outAvlTree := match(inAvlTree, inKeyComp, inKey, inValue, inUpdateFunc)
    local
      AvlKey key;
      AvlValue value;
      Option<AvlTree> left, right;
      Integer h;
      AvlTree t;
      Option<AvlTreeValue> oval;

    // Existing node, update it with the given update function.
    case (NFInstTypes.AVLTREENODE(SOME(NFInstTypes.AVLTREEVALUE(key, value)), h, left, right), 0, _, _, _)
      equation
        value = inUpdateFunc(value, inValue);
      then
        NFInstTypes.AVLTREENODE(SOME(NFInstTypes.AVLTREEVALUE(key, value)), h, left, right);

    // Insert into right subtree.
    case (NFInstTypes.AVLTREENODE(oval, h, left, right), 1, _, _, _)
      equation
        t = createEmptyIfNone(right);
        t = add(t, inKey, inValue, inUpdateFunc);
      then
        NFInstTypes.AVLTREENODE(oval, h, left, SOME(t));

    // Insert into left subtree.
    case (NFInstTypes.AVLTREENODE(oval, h, left, right), -1, _, _, _)
      equation
        t = createEmptyIfNone(left);
        t = add(t, inKey, inValue, inUpdateFunc);
      then
        NFInstTypes.AVLTREENODE(oval, h, SOME(t), right);

  end match;
end add2;

public function addUnique
  "Inserts a new value into the tree. Fails if the key already exists in the tree."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKey, inValue)
    local
      AvlKey key, rkey;
      AvlValue value;

    // empty tree
    case (NFInstTypes.AVLTREENODE(value = NONE(), left = NONE(), right = NONE()), _, _)
      then NFInstTypes.AVLTREENODE(SOME(NFInstTypes.AVLTREEVALUE(inKey, inValue)), 1, NONE(), NONE());

    case (NFInstTypes.AVLTREENODE(value = SOME(NFInstTypes.AVLTREEVALUE(key = rkey))), key, value)
      then balance(addUnique2(inAvlTree, stringCompare(key, rkey), key, value));

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"NFEnvAvlTree.addUnique failed"});
      then fail();

  end match;
end addUnique;

protected function addUnique2
  "Helper function to addUnique."
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKeyComp, inKey, inValue)
    local
      AvlKey key;
      AvlValue value;
      Option<AvlTree> left, right;
      Integer h;
      AvlTree t;
      Option<AvlTreeValue> oval;
      SourceInfo info;

    // Insert into right subtree.
    case (NFInstTypes.AVLTREENODE(value = oval, height = h, left = left, right = right),
        1, key, value)
      equation
        t = createEmptyIfNone(right);
        t = addUnique(t, key, value);
      then
        NFInstTypes.AVLTREENODE(oval, h, left, SOME(t));

    // Insert into left subtree.
    case (NFInstTypes.AVLTREENODE(value = oval, height = h, left = left, right = right),
        -1, key, value)
      equation
        t = createEmptyIfNone(left);
        t = addUnique(t, key, value);
      then
        NFInstTypes.AVLTREENODE(oval, h, SOME(t), right);
  end match;
end addUnique2;

public function get
  "Get a value from the binary tree given a key."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  output AvlValue outValue;
protected
  AvlKey rkey;
algorithm
  NFInstTypes.AVLTREENODE(value = SOME(NFInstTypes.AVLTREEVALUE(key = rkey))) := inAvlTree;
  outValue := get2(inAvlTree, stringCompare(inKey, rkey), inKey);
end get;

protected function get2
  "Helper function to get."
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  output AvlValue outValue;
algorithm
  outValue := match(inAvlTree, inKeyComp, inKey)
    local
      AvlKey key;
      AvlValue rval;
      AvlTree left, right;

    // Found match.
    case (NFInstTypes.AVLTREENODE(value = SOME(NFInstTypes.AVLTREEVALUE(value = rval))), 0, _)
      then rval;

    // Search to the right.
    case (NFInstTypes.AVLTREENODE(right = SOME(right)), 1, key)
      then get(right, key);

    // Search to the left.
    case (NFInstTypes.AVLTREENODE(left = SOME(left)), -1, key)
      then get(left, key);
  end match;
end get2;

public function replace
  "Replaces the value of an already existing node in the tree with a new value."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKey, inValue)
    local
      AvlKey key, rkey;
      AvlValue value;

    case (NFInstTypes.AVLTREENODE(value = SOME(NFInstTypes.AVLTREEVALUE(key = rkey))), key, value)
      then replace2(inAvlTree, stringCompare(key, rkey), key, value);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"NFEnvAvlTree.replace failed"});
      then fail();

  end match;
end replace;

protected function replace2
  "Helper function to replace."
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKeyComp, inKey, inValue)
    local
      Option<AvlTree> left, right;
      Integer h;
      AvlTree t;
      Option<AvlTreeValue> oval;

    // Replace this node.
    case (NFInstTypes.AVLTREENODE(SOME(_), h, left, right), 0, _, _)
      then NFInstTypes.AVLTREENODE(SOME(NFInstTypes.AVLTREEVALUE(inKey, inValue)), h, left, right);

    // Insert into right subtree.
    case (NFInstTypes.AVLTREENODE(oval, h, left, SOME(t)), 1, _, _)
      equation
        t = replace(t, inKey, inValue);
      then
        NFInstTypes.AVLTREENODE(oval, h, left, SOME(t));

    // Insert into left subtree.
    case (NFInstTypes.AVLTREENODE(oval, h, SOME(t), right), -1, _, _)
      equation
        t = replace(t, inKey, inValue);
      then
        NFInstTypes.AVLTREENODE(oval, h, SOME(t), right);

  end match;
end replace2;

public function update
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input UpdateFunc inUpdateFunc;
  input ArgType inArg;
  output AvlTree outAvlTree;
  output Option<AvlValue> outUpdatedValue;

  partial function UpdateFunc
    input AvlValue inValue;
    input ArgType inArg;
    output AvlValue outValue;
  end UpdateFunc;

  replaceable type ArgType subtypeof Any;
algorithm
  (outAvlTree, outUpdatedValue) :=
  matchcontinue(inAvlTree, inKey, inUpdateFunc, inArg)
    local
      AvlKey key;
      Integer key_comp;
      AvlTree tree;
      Option<AvlValue> updated_val;

    case (NFInstTypes.AVLTREENODE(value = SOME(NFInstTypes.AVLTREEVALUE(key = key))), _, _, _)
      equation
        key_comp = stringCompare(key, inKey);
        (tree, updated_val) =
          update2(inAvlTree, key_comp, inKey, inUpdateFunc, inArg);
      then
        (tree, updated_val);

    else (inAvlTree, NONE());
  end matchcontinue;
end update;

protected function update2
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  input UpdateFunc inUpdateFunc;
  input ArgType inArg;
  output AvlTree outAvlTree;
  output Option<AvlValue> outUpdatedValue;

  partial function UpdateFunc
    input AvlValue inValue;
    input ArgType inArg;
    output AvlValue outValue;
  end UpdateFunc;

  replaceable type ArgType subtypeof Any;
algorithm
  (outAvlTree, outUpdatedValue) :=
  match(inAvlTree, inKeyComp, inKey, inUpdateFunc, inArg)
    local
      AvlKey key;
      AvlValue value;
      Option<AvlTree> left, right;
      Integer h;
      AvlTree t;
      Option<AvlTreeValue> oval;
      Option<AvlValue> uval;

    case (NFInstTypes.AVLTREENODE(SOME(NFInstTypes.AVLTREEVALUE(key, value)), h, left, right), 0, _, _, _)
      equation
        value = inUpdateFunc(value, inArg);
      then
        (NFInstTypes.AVLTREENODE(SOME(NFInstTypes.AVLTREEVALUE(key, value)), h, left, right), SOME(value));

    case (NFInstTypes.AVLTREENODE(oval, h, left, SOME(t)), -1, _, _, _)
      equation
        (t, uval) = update(t, inKey, inUpdateFunc, inArg);
      then
        (NFInstTypes.AVLTREENODE(oval, h, left, SOME(t)), uval);

    case (NFInstTypes.AVLTREENODE(oval, h, SOME(t), right), 1, _, _, _)
      equation
        (t, uval) = update(t, inKey, inUpdateFunc, inArg);
      then
        (NFInstTypes.AVLTREENODE(oval, h, SOME(t), right), uval);

  end match;
end update2;

public function map
  "Applies a function to all value entries in the AVL tree."
  input AvlTree inTree;
  input MapFunc inMapFunc;
  output AvlTree outTree;

  partial function MapFunc
    input AvlValue inValue;
    output AvlValue outValue;
  end MapFunc;
protected
  Option<AvlTreeValue> value;
  Integer height;
  Option<AvlTree> left, right;
algorithm
  NFInstTypes.AVLTREENODE(value, height, left, right) := inTree;
  value := Util.applyOption1(value, mapValue, inMapFunc);
  left := Util.applyOption1(left, map, inMapFunc);
  right := Util.applyOption1(right, map, inMapFunc);
  outTree := NFInstTypes.AVLTREENODE(value, height, left, right);
end map;

protected function mapValue
  input AvlTreeValue inValue;
  input MapFunc inMapFunc;
  output AvlTreeValue outValue;

  partial function MapFunc
    input AvlValue inValue;
    output AvlValue outValue;
  end MapFunc;
protected
  AvlKey key;
  AvlValue value;
algorithm
  NFInstTypes.AVLTREEVALUE(key, value) := inValue;
  value := inMapFunc(value);
  outValue := NFInstTypes.AVLTREEVALUE(key, value);
end mapValue;

public function fold
  input AvlTree inTree;
  input FoldFunc inFoldFunc;
  input FoldArg inFoldArg;
  output FoldArg outFoldArg;

  partial function FoldFunc
    input AvlValue inValue;
    input FoldArg inFoldArg;
    output FoldArg outFoldArg;
  end FoldFunc;

  replaceable type FoldArg subtypeof Any;
protected
  Option<AvlTreeValue> value;
  Integer height;
  Option<AvlTree> left, right;
  FoldArg fold_arg;
algorithm
  NFInstTypes.AVLTREENODE(value, height, left, right) := inTree;
  fold_arg := Util.applyOptionOrDefault2(value, foldValue, inFoldFunc, inFoldArg, inFoldArg);
  fold_arg := Util.applyOptionOrDefault2(left, fold, inFoldFunc, fold_arg, fold_arg);
  outFoldArg := Util.applyOptionOrDefault2(right, fold, inFoldFunc, fold_arg, fold_arg);
end fold;

protected function foldValue
  input AvlTreeValue inValue;
  input FoldFunc inFoldFunc;
  input FoldArg inFoldArg;
  output FoldArg outFoldArg;

  partial function FoldFunc
    input AvlValue inValue;
    input FoldArg inFoldArg;
    output FoldArg outFoldArg;
  end FoldFunc;

  replaceable type FoldArg subtypeof Any;
protected
  AvlValue value;
algorithm
  NFInstTypes.AVLTREEVALUE(value = value) := inValue;
  outFoldArg := inFoldFunc(value, inFoldArg);
end foldValue;

protected function createEmptyIfNone
  "Help function to add"
  input Option<AvlTree> t;
  output AvlTree outT;
algorithm
  outT := match(t)
    case (NONE()) then new();
    case (SOME(outT)) then outT;
  end match;
end createEmptyIfNone;

protected function balance
  "Balances an AvlTree"
  input AvlTree bt;
  output AvlTree outBt;
protected
  Integer d;
algorithm
  d := differenceInHeight(bt);
  outBt := doBalance(d, bt);
end balance;

protected function doBalance
  "Performs balance if difference is > 1 or < -1"
  input Integer difference;
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := match(difference, bt)
    case(-1, _) then computeHeight(bt);
    case( 0, _) then computeHeight(bt);
    case( 1, _) then computeHeight(bt);
    // d < -1 or d > 1
    else doBalance2(difference < 0, bt);
  end match;
end doBalance;

protected function doBalance2
"help function to doBalance"
  input Boolean inDiffIsNegative;
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := match(inDiffIsNegative,inBt)
    local AvlTree bt;
    case(true,bt)
      equation
        bt = doBalance3(bt);
        bt = rotateLeft(bt);
      then bt;
    case(false,bt)
      equation
        bt = doBalance4(bt);
        bt = rotateRight(bt);
      then bt;
  end match;
end doBalance2;

protected function doBalance3 "help function to doBalance2"
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(inBt)
    local
      AvlTree rr,bt;
    case(bt)
      equation
        true = differenceInHeight(Util.getOption(rightNode(bt))) > 0;
        rr = rotateRight(Util.getOption(rightNode(bt)));
        bt = setRight(bt,SOME(rr));
      then bt;
    else inBt;
  end matchcontinue;
end doBalance3;

protected function doBalance4 "help function to doBalance2"
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(inBt)
    local
      AvlTree rl,bt;
    case (bt)
      equation
        true = differenceInHeight(Util.getOption(leftNode(bt))) < 0;
        rl = rotateLeft(Util.getOption(leftNode(bt)));
        bt = setLeft(bt,SOME(rl));
      then bt;
    else inBt;
  end matchcontinue;
end doBalance4;

protected function setRight
  "set right treenode"
  input AvlTree node;
  input Option<AvlTree> right;
  output AvlTree outNode;
protected
  Option<AvlTreeValue> value;
  Option<AvlTree> l;
  Integer height;
algorithm
  NFInstTypes.AVLTREENODE(value, height, l, _) := node;
  outNode := NFInstTypes.AVLTREENODE(value, height, l, right);
end setRight;

protected function setLeft
  "set left treenode"
  input AvlTree node;
  input Option<AvlTree> left;
  output AvlTree outNode;
protected
  Option<AvlTreeValue> value;
  Option<AvlTree> r;
  Integer height;
algorithm
  NFInstTypes.AVLTREENODE(value, height, _, r) := node;
  outNode := NFInstTypes.AVLTREENODE(value, height, left, r);
end setLeft;

protected function leftNode
  "Retrieve the left subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  NFInstTypes.AVLTREENODE(left = subNode) := node;
end leftNode;

protected function rightNode
  "Retrieve the right subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  NFInstTypes.AVLTREENODE(right = subNode) := node;
end rightNode;

protected function exchangeLeft
  "help function to balance"
  input AvlTree inNode;
  input AvlTree inParent;
  output AvlTree outParent "updated parent";
protected
  AvlTree parent, node;
algorithm
  parent := setRight(inParent, leftNode(inNode));
  parent := balance(parent);
  node := setLeft(inNode, SOME(parent));
  outParent := balance(node);
end exchangeLeft;

protected function exchangeRight
  "help function to balance"
  input AvlTree inNode;
  input AvlTree inParent;
  output AvlTree outParent "updated parent";
protected
  AvlTree parent, node;
algorithm
  parent := setLeft(inParent, rightNode(inNode));
  parent := balance(parent);
  node := setRight(inNode, SOME(parent));
  outParent := balance(node);
end exchangeRight;

protected function rotateLeft
  "help function to balance"
  input AvlTree node;
  output AvlTree outNode "updated node";
algorithm
  outNode := exchangeLeft(Util.getOption(rightNode(node)), node);
end rotateLeft;

protected function rotateRight
  "help function to balance"
  input AvlTree node;
  output AvlTree outNode "updated node";
algorithm
  outNode := exchangeRight(Util.getOption(leftNode(node)), node);
end rotateRight;

protected function differenceInHeight
  "help function to balance, calculates the difference in height between left
  and right child"
  input AvlTree node;
  output Integer diff;
protected
  Option<AvlTree> l, r;
algorithm
  NFInstTypes.AVLTREENODE(left = l, right = r) := node;
  diff := getHeight(l) - getHeight(r);
end differenceInHeight;

protected function computeHeight
  "Compute the height of the AvlTree and store in the node info."
  input AvlTree bt;
  output AvlTree outBt;
protected
  Option<AvlTree> l,r;
  Option<AvlTreeValue> v;
  AvlValue val;
  Integer hl,hr,height;
algorithm
  NFInstTypes.AVLTREENODE(value = v as SOME(NFInstTypes.AVLTREEVALUE(value = val)),
    left = l, right = r) := bt;
  hl := getHeight(l);
  hr := getHeight(r);
  height := intMax(hl, hr) + 1;
  outBt := NFInstTypes.AVLTREENODE(v, height, l, r);
end computeHeight;

protected function getHeight
  "Retrieve the height of a node"
  input Option<AvlTree> bt;
  output Integer height;
algorithm
  height := match(bt)
    case(NONE()) then 0;
    case(SOME(NFInstTypes.AVLTREENODE(height = height))) then height;
  end match;
end getHeight;

protected function printTreeStrPP
  input AvlTree inTree;
  output String outString;
algorithm
  outString := printTreeStrPP2(SOME(inTree), "");
end printTreeStrPP;

protected function printTreeStrPP2
  input Option<AvlTree> inTree;
  input String inIndent;
  output String outString;
algorithm
  outString := match(inTree, inIndent)
    local
      AvlKey rkey;
      Option<AvlTree> l, r;
      String s1, s2, res, indent;

    case (NONE(), _) then "";

    case (SOME(NFInstTypes.AVLTREENODE(value = SOME(NFInstTypes.AVLTREEVALUE(key = rkey)), left = l, right = r)), _)
      equation
        indent = inIndent + "  ";
        s1 = printTreeStrPP2(l, indent);
        s2 = printTreeStrPP2(r, indent);
        res = "\n" + inIndent + rkey + s1 + s2;
      then
        res;

    case (SOME(NFInstTypes.AVLTREENODE(value = NONE(), left = l, right = r)), _)
      equation
        indent = inIndent + "  ";
        s1 = printTreeStrPP2(l, indent);
        s2 = printTreeStrPP2(r, indent);
        res = "\n" + s1 + s2;
      then
        res;
  end match;
end printTreeStrPP2;

annotation(__OpenModelica_Interface="frontend");
end NFEnvAvlTree;
