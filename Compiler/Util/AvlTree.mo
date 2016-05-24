/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package AvlTree
" file:        AvlTree.mo
  package:     AvlTree
  description: A MetaModelica AvlTree implementation

  RCS: $Id: Tree.mo 9152 2011-05-28 08:08:28Z adrpo $

  @author: adrpo

  A generic AvlTree with type variables for Key and Val."

public

final type Key = polymorphic<Any>;
final type Val = polymorphic<Any>;

partial function FuncTypeKeyToStr<Key>
 input Key key;
 output String outString;
end FuncTypeKeyToStr;

partial function FuncTypeValToStr<Val>
 input Val val;
 output String outString;
end FuncTypeValToStr;

partial function FuncTypeItemUpdateCheck<Key,Val> "function to print an error on duplicate items"
  input Item<Key,Val> inItemNew "the new item";
  input Item<Key,Val> inItemOld "the old item in the tree";
  output Boolean updateAllowed "returns true, the update is performed, false no update, fail, the update will fail";
end FuncTypeItemUpdateCheck;

partial function FuncTypeKeyCompare<Key> "function to compare keys"
 input Key inKey1 "the new key";
 input Key inKey2 "the old key from the tree";
 output Integer order "return -1,0,1 for less than, equal and greater than keys";
end FuncTypeKeyCompare;

uniontype Tree<Key,Val> "a tree is a node and two optional printing functions"
  record TREE "a tree is a node and two optional printing functions"
    Node<Key,Val> root;
    FuncTypeKeyCompare keyCompareFunc "function to compare keys, should return -1, 0, 1 ONLY!";
    Option<FuncTypeKeyToStr> keyStrFuncOpt "optional function for printing Key";
    Option<FuncTypeValToStr> valStrFuncOpt "optional function for printing Val";
    Option<FuncTypeItemUpdateCheck> updateCheckFuncOpt
      "optional function for reporting error on an update of the same item
       if this function is NONE() then updates of items with the same key is allowed!
       this function gets the new item and the old item for easy reporting,
       and should return:
       - true if update is allowed
       - false if update should not be done
       - should print an error message and fail if it wants to fail the update";
    String name "a name for this tree so you know which one it is if you have more";
  end TREE;
end Tree;

uniontype Node<Key,Val>
  "The binary tree data structure"
  record NODE
    Item<Key,Val> item "Val";
    Integer height "height of tree, used for balancing";
    Node<Key,Val> left "left subtree";
    Node<Key,Val> right "right subtree";
  end NODE;

  record NO_NODE "no node, empty tree"
  end NO_NODE;
end Node;

public uniontype Item<Key,Val>
  "Each node in the binary tree can have an item associated with it."
  record ITEM
    Key key "Key";
    Val val "Val";
  end ITEM;

  record NO_ITEM "no item"
  end NO_ITEM;
end Item;

protected import Error;

public function name
"return the name of the tree"
  input Tree<Key,Val> tree;
  output String name;
algorithm
  TREE(name = name) := tree;
end name;

public function create
"Return an empty tree with the given printing functions attached"
  input String name "a name for this tree so you know which one it is if you have more";
  input FuncTypeKeyCompare inKeyCompareFunc;
  input Option<FuncTypeKeyToStr> inKeyStrFuncOpt;
  input Option<FuncTypeValToStr> inValStrFuncOpt;
  input Option<FuncTypeItemUpdateCheck> inUpdateCheckFuncOpt;
  output Tree<Key,Val> tree;
algorithm
  tree := TREE(NODE(NO_ITEM(), 0, NO_NODE(), NO_NODE()), inKeyCompareFunc, inKeyStrFuncOpt, inValStrFuncOpt, inUpdateCheckFuncOpt, name);
end create;

public function hasPrintingFunctions
"returns true if you have set printing functions"
  input Tree<Key,Val> tree;
  output Boolean hasPrinting;
protected
  Option<FuncTypeKeyToStr> kf;
  Option<FuncTypeValToStr> vf;
algorithm
  TREE(keyStrFuncOpt = kf, valStrFuncOpt = vf) := tree;
  hasPrinting := boolNot(boolOr(valueEq(NONE(), kf), valueEq(NONE(), vf)));
end hasPrintingFunctions;

public function hasUpdateCheckFunction
"returns true if you have set printing functions"
  input Tree<Key,Val> tree;
  output Boolean hasUpdateCheck;
protected
  Option<FuncTypeItemUpdateCheck> uf;
algorithm
  TREE(updateCheckFuncOpt = uf) := tree;
  hasUpdateCheck := boolNot(valueEq(NONE(), uf));
end hasUpdateCheckFunction;

public function getUpdateCheckFunc
"return the printing function pointer for the key, fails if you haven't set any"
  input Tree<Key,Val> tree;
  output FuncTypeItemUpdateCheck outUpdateCheckFunc;
algorithm
  TREE(updateCheckFuncOpt = SOME(outUpdateCheckFunc)) := tree;
end getUpdateCheckFunc;

public function getKeyCompareFunc
"return the printing function pointer for the key, fails if you haven't set any"
  input Tree<Key,Val> tree;
  output FuncTypeKeyCompare outKeyCompareFunc;
algorithm
  TREE(keyCompareFunc = outKeyCompareFunc) := tree;
end getKeyCompareFunc;

public function getKeyToStrFunc
"return the printing function pointer for the key, fails if you haven't set any"
  input Tree<Key,Val> tree;
  output FuncTypeKeyToStr outKey2StrFunc;
algorithm
  TREE(keyStrFuncOpt = SOME(outKey2StrFunc)) := tree;
end getKeyToStrFunc;

public function getValToStrFunc
"return the printing function pointer for the val, fails if you haven't set any"
  input Tree<Key,Val> tree;
  output FuncTypeValToStr outVal2StrFunc;
algorithm
  TREE(valStrFuncOpt = SOME(outVal2StrFunc)) := tree;
end getValToStrFunc;

protected function newLeafNode
  input Item<Key,Val> inItem;
  input Integer height;
  output Node<Key,Val> outNode;
algorithm
  outNode := NODE(inItem, 1, NO_NODE(), NO_NODE());
end newLeafNode;

public function add
"inserts a new item into the tree."
  input Tree<Key,Val> inTree;
  input Key inKey;
  input Val inVal;
  output Tree<Key,Val> outTree;
algorithm
  outTree := matchcontinue(inTree, inKey, inVal)
    local
      Key key, rkey;
      Val val;
      Node<Key,Val> node;
      FuncTypeKeyCompare cf;
      Option<FuncTypeKeyToStr> kf;
      Option<FuncTypeValToStr> vf;
      Option<FuncTypeItemUpdateCheck> uf;
      String str, n;

    // call addNode on the root
    case (TREE(node, cf, kf, vf, uf, n), key, val)
      equation
        node = addNode(inTree, node, key, val); // send the tree down to the nodes for compare function and update check
      then
        TREE(node, cf, kf, vf, uf, n);

    else
      equation
        str = "AvlTree.add name: " + name(inTree) + " failed!";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();

  end matchcontinue;
end add;

protected function addNode
"Inserts a new item into the tree root node"
  input Tree<Key,Val> inTree "sent down so we can use the update check function";
  input Node<Key,Val> inNode "the node to add item to";
  input Key inKey;
  input Val inVal;
  output Node<Key,Val> outNode;
algorithm
  outNode := match(inTree, inNode, inKey, inVal)
    local
      Key key, rkey;
      Val val;
      Item<Key,Val> item;
      FuncTypeKeyCompare keyCompareFunc;
      Node<Key,Val> n;
      Integer order;
      String str;

    // empty node
    case (_, NO_NODE(), _, _)
     equation
       n = newLeafNode(ITEM(inKey, inVal), 1);
     then
       n;

    // empty node item
    case (_, NODE(item = NO_ITEM(), left = NO_NODE(), right = NO_NODE()), key, val)
      equation
        n = newLeafNode(ITEM(key, val), 1);
      then
        n;

    case (TREE(keyCompareFunc = keyCompareFunc), NODE(item = ITEM(key = rkey)), key, val)
      equation
        order = keyCompareFunc(key, rkey);
        n = balance(addNode_dispatch(inTree,inNode,order,key, val));
      then
        n;

    else
      equation
        str = "AvlTree.addNode name: " + name(inTree) + " failed!";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();

  end match;
end addNode;

protected function addNode_dispatch
"Helper function to addNode."
  input Tree<Key,Val> inTree "sent down so we can use the update check function";
  input Node<Key,Val> inNode;
  input Integer inKeyComp;
  input Key inKey;
  input Val inVal;
  output Node<Key,Val> outNode;
algorithm
  outNode := matchcontinue(inTree, inNode, inKeyComp, inKey, inVal)
    local
      Key key;
      Val val;
      Node<Key,Val> l, r, n;
      Integer h;
      Item<Key,Val> i;
      FuncTypeItemUpdateCheck updateCheckFunc;

    // replacements of nodes is allowed! no update check function
    case (_, NODE(_, h, l, r), 0, key, val)
      equation
        false = hasUpdateCheckFunction(inTree);
      then
        NODE(ITEM(key,val), h, l, r);

    // replacements of nodes maybe allowed!
    // we have an update check function
    case (_, NODE(i, h, l, r), 0, key, val)
      equation
        true = hasUpdateCheckFunction(inTree);
        updateCheckFunc = getUpdateCheckFunc(inTree);
        // update is allowed
        true = updateCheckFunc(i, ITEM(key, val));
      then
        NODE(ITEM(key,val), h, l, r);

    // replacements of nodes maybe allowed!
    // we have an update check function
    case (_, NODE(i, h, l, r), 0, key, val)
      equation
        true = hasUpdateCheckFunction(inTree);
        updateCheckFunc = getUpdateCheckFunc(inTree);
        // update is NOT allowed
        false = updateCheckFunc(i, ITEM(key, val));
      then
        inNode; // return the same node, no update!

    // insert into right subtree.
    case (_, NODE(item = i, height = h, left = l, right = r), 1, key, val)
      equation
        n = emptyNodeIfNoNode(r);
        n = addNode(inTree, n, key, val);
      then
        NODE(i, h, l, n);

    // Insert into left subtree.
    case (_, NODE(item = i, height = h, left = l, right = r), -1, key, val)
      equation
        n = emptyNodeIfNoNode(l);
        n = addNode(inTree, n, key, val);
      then
        NODE(i, h, n, r);
  end matchcontinue;
end addNode_dispatch;

public function get
"Get a Val from the binary tree given a key."
  input Tree<Key,Val> inTree;
  input Key inKey;
  output Val outVal;
protected
  Node<Key,Val> node;
algorithm
  TREE(root = node) := inTree;
  outVal := getNode(inTree, node, inKey); // send the tree down for the compare func!
end get;

protected function getNode
"Get a Val from the binary tree node given a key."
  input Tree<Key,Val> inTree;
  input Node<Key,Val> inNode;
  input Key inKey;
  output Val outVal;
protected
  Key rkey;
  FuncTypeKeyCompare keyCompareFunc;
  Integer order;
algorithm
  NODE(item = ITEM(key = rkey)) := inNode;
  keyCompareFunc := getKeyCompareFunc(inTree);
  order := keyCompareFunc(inKey, rkey);
  outVal := getNode_dispatch(inTree, inNode, order, inKey);
end getNode;

protected function getNode_dispatch
"Helper function to getNode."
  input Tree<Key,Val> inTree;
  input Node<Key,Val> inNode;
  input Integer inKeyComp;
  input Key inKey;
  output Val outVal;
algorithm
  outVal := match(inTree, inNode, inKeyComp, inKey)
    local
      Key key;
      Val val;
      Node<Key,Val> l, r;

    // found match.
    case (_, NODE(item = ITEM(val = val)), 0, _)
      then val;

    // search to the right.
    case (_, NODE(right = r), 1, key)
      then getNode(inTree, r, key);

    // search to the left.
    case (_, NODE(left = l), -1, key)
      then getNode(inTree, l, key);

  end match;
end getNode_dispatch;

public function replace
"Replaces the item of an already existing node in the tree with a new item.
 Note that the update check function is not used if replace is called!"
  input Tree<Key,Val> inTree;
  input Key inKey;
  input Val inVal;
  output Tree<Key,Val> outTree;
algorithm
  outTree := match(inTree, inKey, inVal)
    local
      Key key, rkey;
      Val val;
      FuncTypeKeyCompare keyCompareFunc;
      Option<FuncTypeKeyToStr> kf;
      Option<FuncTypeValToStr> vf;
      Option<FuncTypeItemUpdateCheck> uf;
      Node<Key,Val> node;
      Integer order;
      String n, str;

    case (TREE(node, keyCompareFunc, kf, vf, uf, n), key, val)
      equation
        node = replaceNode(inTree, node, key, val);
      then
        TREE(node, keyCompareFunc, kf, vf, uf, n);

    else
      equation
        str = "AvlTree.replace name: " + name(inTree) + " failed!";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();

  end match;
end replace;

public function replaceNode
"Replaces the item of an already existing node in the tree with a new value."
  input Tree<Key,Val> inTree "send down for comparison function";
  input Node<Key,Val> inNode;
  input Key inKey;
  input Val inVal;
  output Node<Key,Val> outNode;
algorithm
  outNode := match(inTree, inNode, inKey, inVal)
    local
      Key key, rkey;
      Val val;
      FuncTypeKeyCompare keyCompareFunc;
      Node<Key, Val> n;
      Integer order;

    case (TREE(keyCompareFunc = keyCompareFunc),
          NODE(item = ITEM(key = rkey)),
          key, val)
      equation
        order = keyCompareFunc(key, rkey);
        n = replaceNode_dispatch(inTree, inNode, order, key, val);
      then
        n;

  end match;
end replaceNode;

protected function replaceNode_dispatch
"Helper function to replaceNode."
  input Tree<Key,Val> inTree "send down for comparison function";
  input Node<Key,Val> inNode;
  input Integer inKeyComp;
  input Key inKey;
  input Val inVal;
  output Node<Key,Val> outNode;
algorithm
  outNode := match(inTree, inNode, inKeyComp, inKey, inVal)
    local
      Key key, rkey;
      Val val;
      Node<Key,Val> l, r, n;
      Integer h;
      Item<Key,Val> i;

    // replace this node.
    case (_, NODE(item = ITEM(key = _), height = h, left = l, right = r), 0, key, val)
      then
        NODE(ITEM(key, val), h, l, r);

    // insert into right subtree.
    case (_, NODE(item = i, height = h, left = l, right = r), 1, key, val)
      equation
        n = emptyNodeIfNoNode(r);
        n = replaceNode(inTree, n, key, val);
      then
        NODE(i, h, l, n);

    // insert into left subtree.
    case (_, NODE(item = i, height = h, left = l, right = r), -1, key, val)
      equation
        n = emptyNodeIfNoNode(l);
        n = replaceNode(inTree, n, key, val);
      then
        NODE(i, h, n, r);
  end match;
end replaceNode_dispatch;

protected function emptyNodeIfNoNode
"creates an empty node if the node is NO_NODE"
  input Node<Key,Val> inNode;
  output Node<Key,Val> outNode;
algorithm
  outNode := match(inNode)
    case (NO_NODE()) then NODE(NO_ITEM(), 0, NO_NODE(), NO_NODE());
    case (NODE(item = _)) then inNode;
  end match;
end emptyNodeIfNoNode;

protected function balance
"Balances an Node<Key,Val>"
  input Node<Key,Val> inNode;
  output Node<Key,Val> outNode;
protected
  Integer d;
algorithm
  d := differenceInHeight(inNode);
  outNode := doBalance(d, inNode);
end balance;

protected function doBalance
"Performs balance if difference is > 1 or < -1"
  input Integer difference;
  input Node<Key,Val> inNode;
  output Node<Key,Val> outNode;
algorithm
  outNode := match(difference, inNode)
    case(-1, _) then computeHeight(inNode);
    case( 0, _) then computeHeight(inNode);
    case( 1, _) then computeHeight(inNode);
    // d < -1 or d > 1
    else doBalance2(difference < 0, inNode);
  end match;
end doBalance;

protected function doBalance2
"Help function to doBalance"
  input Boolean inDiffIsNegative;
  input Node<Key,Val> inNode;
  output Node<Key,Val> outNode;
algorithm
  outNode := match(inDiffIsNegative, inNode)
    local
      Node<Key,Val> n;

    case(true, n)
      equation
        n = doBalance3(n);
        n = rotateLeft(n);
      then n;

    case(false,n)
      equation
        n = doBalance4(n);
        n = rotateRight(n);
      then n;
  end match;
end doBalance2;

protected function doBalance3
"help function to doBalance2"
  input Node<Key,Val> inNode;
  output Node<Key,Val> outNode;
algorithm
  outNode := matchcontinue(inNode)
    local
      Node<Key,Val> n, rr, rN;

    case(n)
      equation
        rN = rightNode(n);
        true = differenceInHeight(rN) > 0;
        rr = rotateRight(rN);
        n = setRight(n, rr);
      then n;

    else inNode;
  end matchcontinue;
end doBalance3;

protected function doBalance4
"Help function to doBalance2"
  input Node<Key,Val> inNode;
  output Node<Key,Val> outNode;
algorithm
  outNode := matchcontinue(inNode)
    local
      Node<Key,Val> rl, n, lN;

    case (n)
      equation
        lN = leftNode(n);
        true = differenceInHeight(lN) < 0;
        rl = rotateLeft(lN);
        n = setLeft(n, rl);
      then n;

    else inNode;
  end matchcontinue;
end doBalance4;

protected function setRight
"set right treenode"
  input Node<Key,Val> node;
  input Node<Key,Val> right;
  output Node<Key,Val> outNode;
protected
  Item<Key,Val> item;
  Node<Key,Val> l;
  Integer height;
algorithm
  NODE(item, height, l, _) := node;
  outNode := NODE(item, height, l, right);
end setRight;

protected function setLeft
"set left node"
  input Node<Key,Val> node;
  input Node<Key,Val> left;
  output Node<Key,Val> outNode;
protected
  Item<Key,Val> item;
  Node<Key,Val> r;
  Integer height;
algorithm
  NODE(item, height, _, r) := node;
  outNode := NODE(item, height, left, r);
end setLeft;

protected function leftNode
"Retrieve the left subnode"
  input Node<Key,Val> node;
  output  Node<Key,Val> subNode;
algorithm
  NODE(left = subNode) := node;
end leftNode;

protected function rightNode
"Retrieve the right subnode"
  input Node<Key,Val> node;
  output Node<Key,Val> subNode;
algorithm
  NODE(right = subNode) := node;
end rightNode;

protected function exchangeLeft
  "help function to balance"
  input Node<Key,Val> inNode;
  input Node<Key,Val> inParent;
  output Node<Key,Val> outParent "updated parent";
protected
  Node<Key,Val> parent, node;
algorithm
  parent := setRight(inParent, leftNode(inNode));
  parent := balance(parent);
  node := setLeft(inNode, parent);
  outParent := balance(node);
end exchangeLeft;

protected function exchangeRight
  "help function to balance"
  input Node<Key,Val> inNode;
  input Node<Key,Val> inParent;
  output Node<Key,Val> outParent "updated parent";
protected
  Node<Key,Val> parent, node;
algorithm
  parent := setLeft(inParent, rightNode(inNode));
  parent := balance(parent);
  node := setRight(inNode, parent);
  outParent := balance(node);
end exchangeRight;

protected function rotateLeft
"help function to balance"
  input Node<Key,Val> node;
  output Node<Key,Val> outNode "updated node";
algorithm
  outNode := exchangeLeft(rightNode(node), node);
end rotateLeft;

protected function rotateRight
  "help function to balance"
  input Node<Key,Val> node;
  output Node<Key,Val> outNode "updated node";
algorithm
  outNode := exchangeRight(leftNode(node), node);
end rotateRight;

protected function differenceInHeight
  "help function to balance, calculates the difference in height between left
  and right child"
  input Node<Key,Val> node;
  output Integer diff;
protected
  Node<Key,Val> l, r;
algorithm
  NODE(left = l, right = r) := node;
  diff := getHeight(l) - getHeight(r);
end differenceInHeight;

protected function computeHeight
  "compute the heigth of the Tree and store in the node info"
  input Node<Key,Val> inNode;
  output Node<Key,Val> outNode;
protected
  Node<Key,Val> l,r;
  Item<Key,Val> i;
  Val val;
  Integer hl,hr,height;
algorithm
  NODE(item = i as ITEM(), left = l, right = r) := inNode;
  hl := getHeight(l);
  hr := getHeight(r);
  height := intMax(hl, hr) + 1;
  outNode := NODE(i, height, l, r);
end computeHeight;

protected function getHeight
  "Retrieve the height of a node"
  input Node<Key,Val> bt;
  output Integer height;
algorithm
  height := match(bt)
    case NO_NODE() then 0;
    case NODE(height = height) then height;
  end match;
end getHeight;

public function prettyPrintTreeStr
  input Tree<Key,Val> inTree;
  output String outString;
algorithm
  outString := prettyPrintTreeStr_dispatch(inTree, "");
end prettyPrintTreeStr;

protected function prettyPrintTreeStr_dispatch
  input Tree<Key,Val> inTree;
  input String inIndent;
  output String outString;
protected
  Node<Key,Val> node;
algorithm
  if not hasPrintingFunctions(inTree) then
    outString := "TreePrintError<NO_PRINTING_FUNCTIONS_ATTACHED> name[" + name(inTree) + "]";
    return;
  end if;
  TREE(root = node) := inTree;
  outString := prettyPrintNodeStr(inTree, node, inIndent);
end prettyPrintTreeStr_dispatch;

protected function prettyPrintNodeStr
  input Tree<Key,Val> inTree;
  input Node<Key,Val> inNode;
  input String inIndent;
  output String outString;
algorithm
  outString := match(inTree, inNode, inIndent)
    local
      Item<Key,Val> item;
      Node<Key,Val> node, l, r;
      FuncTypeKeyToStr keyStrFunc;
      FuncTypeValToStr valStrFunc;
      String indent, s1, s2, res;

    case (_, NO_NODE(), _) then "";

    case (_, NODE(item = NO_ITEM(), left = l, right = r), _)
      equation
        indent = inIndent + "  ";
        s1 = prettyPrintNodeStr(inTree, l, indent);
        s2 = prettyPrintNodeStr(inTree, r, indent);
        res = "\n" + s1 + s2;
      then
        res;

    case (_, NODE(item = item as ITEM(key = _), left = l, right = r), _)
      equation
        indent = inIndent + "  ";
        s1 = prettyPrintNodeStr(inTree, l, indent);
        s2 = prettyPrintNodeStr(inTree, r, indent);
        res = "\n" + inIndent + printItemStr(inTree, item) + s1 + s2;
      then
        res;

  end match;
end prettyPrintNodeStr;

public function printTreeStr
  input Tree<Key,Val> inTree;
  output String outString;
protected
  Node<Key,Val> node;
algorithm
  if not hasPrintingFunctions(inTree) then
    outString := "TreePrintError<NO_PRINTING_FUNCTIONS_ATTACHED> name[" + name(inTree) + "]";
    return;
  end if;
  TREE(root = node) := inTree;
  outString := printNodeStr(inTree, node);
end printTreeStr;

protected function printNodeStr
  input Tree<Key,Val> inTree;
  input Node<Key,Val> inNode;
  output String outString;
algorithm
  outString := match(inTree, inNode)
    local
      Node<Key,Val> left, right;
      Item<Key,Val> item;
      String left_str, right_str, item_str, str;

    case (_, NO_NODE()) then "";
    case (_, NODE(item = NO_ITEM())) then "";
    case (_, NODE(item = item as ITEM(_,_), left = left, right = right))
      equation
        left_str = printNodeStr(inTree, left);
        right_str = printNodeStr(inTree, right);
        item_str = printItemStr(inTree, item);
        str = stringAppendList({"i: ",item_str, ", l: ", left_str, ", r: ", right_str});
      then
        str;

  end match;
end printNodeStr;

public function printItemStr
  input Tree<Key,Val> inTree;
  input Item<Key,Val> inItem;
  output String outString;
algorithm
  outString := match(inTree, inItem)
    local
      String str, keyStr, valStr;
      FuncTypeKeyToStr key2Str;
      FuncTypeValToStr val2Str;
      Key key;
      Val val;

    case (_, NO_ITEM()) then "[]";
    case (_, ITEM(key = key, val = val))
      equation
        key2Str = getKeyToStrFunc(inTree);
        val2Str = getValToStrFunc(inTree);
        keyStr = key2Str(key);
        valStr = val2Str(val);
        str = "[" + keyStr + ", " + valStr + "]";
      then
        str;
  end match;
end printItemStr;

public function getKeyOfVal
"search for a key that has val as value, fails if it cannot find it;
 if there are multiple keys pointing to the same value only the first
 one encountered is returned"
  input Tree<Key,Val> inTree;
  input Val inVal;
  output Key outKey;
protected
  Node<Key,Val> node;
  Key key;
algorithm
  TREE(root = node) := inTree;
  outKey := getKeyOfValNode(inTree, node, inVal);
end getKeyOfVal;

protected function getKeyOfValNode
  input Tree<Key,Val> inTree;
  input Node<Key,Val> inNode;
  input Val inVal;
  output Key outKey;
algorithm
  outKey := matchcontinue inNode
    local
      Node<Key,Val> left, right;
      Item<Key,Val> item;
      Val v;
      Key k;

    case NODE(item = item as ITEM(k,v), left = left, right = right)
      equation
        true = valueEq(v, inVal);
      then
        k;

    // search left
    case NODE(item = item as ITEM(k,v), left = left, right = right)
      equation
        false = valueEq(v, inVal);
        k = getKeyOfValNode(inTree, left, inVal);
      then
        k;

    // search right
    case NODE(item = item as ITEM(k,v), left = left, right = right)
      equation
        false = valueEq(v, inVal);
        k = getKeyOfValNode(inTree, right, inVal);
      then
        k;

  end matchcontinue;
end getKeyOfValNode;

public function addUnique
"inserts a new item into the tree if is not there
 and returns the new item.
 if the key is there then it returns the already
 exiting item and doe not update the tree."
  input Tree<Key,Val> inTree;
  input Key inKey;
  input Val inVal;
  output Tree<Key,Val> outTree;
  output Item<Key,Val> outItem;
algorithm
  (outTree, outItem) := matchcontinue(inTree, inKey, inVal)
    local
      Key key, rkey;
      Val val;
      Node<Key,Val> node;
      FuncTypeKeyCompare cf;
      Option<FuncTypeKeyToStr> kf;
      Option<FuncTypeValToStr> vf;
      Option<FuncTypeItemUpdateCheck> uf;
      String str, n;
      Item<Key,Val> item;

    // call addNode on the root
    case (TREE(node, cf, kf, vf, uf, n), key, val)
      equation
        (node, item) = addNodeUnique(inTree, node, key, val); // send the tree down to the nodes for compare function and update check
      then
        (TREE(node, cf, kf, vf, uf, n), item);

    else
      equation
        str = "AvlTree.addUnique name: " + name(inTree) + " failed!";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();

  end matchcontinue;
end addUnique;

protected function addNodeUnique
"Inserts a new item into the tree root node if is not there and returns the new item.
 if is there it returns the existing item."
  input Tree<Key,Val> inTree "sent down so we can use the update check function";
  input Node<Key,Val> inNode "the node to add item to";
  input Key inKey;
  input Val inVal;
  output Node<Key,Val> outNode;
  output Item<Key,Val> outItem;
algorithm
  (outNode, outItem) := match(inTree, inNode, inKey, inVal)
    local
      Key key, rkey;
      Val val;
      Item<Key,Val> item;
      FuncTypeKeyCompare keyCompareFunc;
      Node<Key,Val> n;
      Integer order;
      String str;

    // empty node
    case (_, NO_NODE(), _, _)
     equation
       item = ITEM(inKey, inVal);
       n = newLeafNode(item, 1);
     then
       (n, item);

    // empty node item
    case (_, NODE(item = NO_ITEM(), left = NO_NODE(), right = NO_NODE()), key, val)
      equation
        item = ITEM(key, val);
        n = newLeafNode(item, 1);
      then
        (n, item);

    case (TREE(keyCompareFunc = keyCompareFunc), NODE(item = ITEM(key = rkey)), key, val)
      equation
        order = keyCompareFunc(key, rkey);
        (n, item) = addNodeUnique_dispatch(inTree,inNode,order,key,val);
        n = balance(n);
      then
        (n, item);

    else
      equation
        str = "AvlTree.addNodeUnique name: " + name(inTree) + " failed!";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();
  end match;
end addNodeUnique;

protected function addNodeUnique_dispatch
"Helper function to addNode."
  input Tree<Key,Val> inTree "sent down so we can use the update check function";
  input Node<Key,Val> inNode;
  input Integer inKeyComp;
  input Key inKey;
  input Val inVal;
  output Node<Key,Val> outNode;
  output Item<Key,Val> outItem;
algorithm
  (outNode, outItem) := matchcontinue(inTree, inNode, inKeyComp, inKey, inVal)
    local
      Key key;
      Val val;
      Node<Key,Val> l, r, n;
      Integer h;
      Item<Key,Val> i, it;
      FuncTypeItemUpdateCheck updateCheckFunc;

    // replacements of nodes are not allowed in addUnique
    // we don't care about update check functions here
    case (_, NODE(i, h, l, r), 0, key, val)
      then
        (inNode, i); // return the same node, no update for addUnique!

    // insert into right subtree.
    case (_, NODE(item = i, height = h, left = l, right = r), 1, key, val)
      equation
        n = emptyNodeIfNoNode(r);
        (n, it) = addNodeUnique(inTree, n, key, val);
      then
        (NODE(i, h, l, n), it);

    // Insert into left subtree.
    case (_, NODE(item = i, height = h, left = l, right = r), -1, key, val)
      equation
        n = emptyNodeIfNoNode(l);
        (n, it) = addNodeUnique(inTree, n, key, val);
      then
        (NODE(i, h, n, r), it);
  end matchcontinue;
end addNodeUnique_dispatch;

annotation(__OpenModelica_Interface="backend");
end AvlTree;

