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

encapsulated package FGraph
" file:        FGraph.mo
  package:     FGraph
  description: A graph for instantiation

  RCS: $Id: FGraph.mo 14085 2012-11-27 12:12:40Z adrpo $

  This module builds a graph out of SCode 
"

public import Absyn;
public import SCode;
public import Util;
public import FNode;
public import DAE;

public type Ident = FNode.Ident;
public type NodeId = FNode.NodeId;
public type Name = FNode.Name;
public type Type = DAE.Type;
public type Types = list<DAE.Type>;
public type Node = FNode.Node;
public type NodeData = FNode.NodeData;

public uniontype Graph
  record G
    AvlTree nodes;
    NodeId lastId;
  end G;
end Graph;

public constant Graph emptyGraph = 
  G(AVLTREENODE(
     SOME(AVLTREEVALUE(FNode.noNodeId, FNode.noNode)), 
     1,
     NONE(),
     SOME(AVLTREENODE(SOME(AVLTREEVALUE(FNode.topNodeId, FNode.topNode)), 0, NONE(), NONE()))),
    FNode.topNodeId) "empty graph containing top node and noNode";

public constant AvlTree emptyAvlTree = AVLTREENODE(NONE(), 0, NONE(), NONE());

public constant Name tyNodeName = "$ty";

protected import System;
protected import List;
protected import Flags;
protected import Error;
protected import Dump;

public function newGraph
  output Graph outGraph;
algorithm
  outGraph := emptyGraph;
end newGraph;

public function getNode
  input Graph inGraph;
  input NodeId inNodeId;
  output Node outNode;
algorithm
  outNode := matchcontinue(inGraph, inNodeId)
    local 
      Node node;
      AvlTree nodes;
    
    case (_, _)
      equation
        G(nodes = nodes) = inGraph;
        node = avlTreeGet(nodes, inNodeId);
      then
        node;
    
    case (_, _) 
      equation 
        print("FGraph.getNode: NodeId " +& keyToStr(inNodeId) +& " not found!\n");
      then
        fail();
  
  end matchcontinue;
end getNode;

public function setNode
  input Graph inGraph;
  input NodeId inNodeId;
  input Node inNode;
  output Graph outGraph;
protected
  AvlTree nodes;
  NodeId last;
algorithm
  G(nodes, last) := inGraph;
  nodes := avlTreeAdd(nodes, inNodeId, inNode, updateNode);
  outGraph := G(nodes, last);
end setNode;

public function getLastNodeId
  input Graph inGraph;
  output NodeId outNodeId;
algorithm
  G(lastId = outNodeId) := inGraph; 
end getLastNodeId;

public function setLastNodeId
  input Graph inGraph;
  input NodeId inNodeId;
  output Graph outGraph;
protected
  AvlTree n;
  NodeId l;
algorithm
  G(n, l) := inGraph;
  outGraph := G(n, inNodeId); 
end setLastNodeId;

public function mkNewId
  input Graph inGraph;
  output Graph outGraph;
  output NodeId outNodeId;
algorithm
  outNodeId := getLastNodeId(inGraph) + 1;
  outGraph := setLastNodeId(inGraph, outNodeId);
end mkNewId;

public function mkChildNode
"@author: adrpo
 makes a new node in the graph and inserts it in the parent children with the given name"
  input Graph inGraph;
  input Name inName;
  input NodeId inParentId;
  input NodeData inData;
  output Graph outGraph;
  output Node outNode;
protected
  NodeId id;
  FNode.AvlTree children;
  Node cnode;
  Graph graph;
algorithm
  (graph, id) := mkNewId(inGraph);
  children := FNode.emptyAvlTree;
  cnode := FNode.N(id, inParentId, inName, children, inData);
  // add it as a child to parentId
  graph := addNodeChild(graph, inParentId, cnode, inName);
  outNode := cnode;
  outGraph := graph;
end mkChildNode;

public function addNodeChild
  input Graph inGraph;
  input NodeId inParentId;
  input Node inChild;
  input Name inName; 
  output Graph outGraph;
protected
  NodeId id;
  Node pnode;
  Graph graph;
algorithm
  id := FNode.getNodeId(inChild);
  pnode := getNode(inGraph, inParentId);
  pnode := FNode.addChildId(pnode, inName, id);
  graph := setNode(inGraph, inParentId, pnode); 
  graph := setNode(graph, id, inChild);
  outGraph := graph;
end addNodeChild;

public function mkNode
"@author: adrpo
 makes a new node in the graph but it does not insert it in the parent children"
  input Graph inGraph;
  input Name inName;
  input NodeId inParentId;
  input NodeData inData;
  output Graph outGraph;
  output Node outNode;
protected
  NodeId id;
  FNode.AvlTree children;
  Node cnode;
  Graph graph;
algorithm
  (graph, id) := mkNewId(inGraph);
  children := FNode.emptyAvlTree;
  cnode := FNode.N(id, inParentId, inName, children, inData);
  // add it to the graph only
  graph := setNode(graph, id, cnode);
  outNode := cnode;
  outGraph := graph;
end mkNode;

public function getChild
"@author: adrpo
 retreive a child node via parent ID and name"
  input Graph inGraph;
  input NodeId inParentId;
  input Name inName;
  output Node outNode;
algorithm
  outNode := matchcontinue(inGraph, inParentId, inName)
    local
      Node node;
    
    case (_, _, _)
      equation
        node = getNode(inGraph, inParentId);
        node = getNode(inGraph, FNode.getChildId(node, inName));
      then
        node;
    
    case (_, _, _)
      equation 
        print("FGraph.getChild: Node with name: " +& inName +& " not found in parent: " +& keyToStr(inParentId) +& "\n");
      then
        fail();
  
  end matchcontinue;
end getChild;

public function getChildSilent
"@author: adrpo
 retreive a child node via parent ID and name"
  input Graph inGraph;
  input NodeId inParentId;
  input Name inName;
  output Node outNode;
algorithm
  outNode := matchcontinue(inGraph, inParentId, inName)
    local
      Node node;
    
    case (_, _, _)
      equation
        node = getNode(inGraph, inParentId);
        node = getNode(inGraph, FNode.getChildId(node, inName));
      then
        node;
  
  end matchcontinue;
end getChildSilent;

public function updateNode
  input Node inOldNode;
  input Node inNewNode;
  output Node outNode;
algorithm
  outNode := inNewNode;
end updateNode;

// ************************ AVL Tree implementation ***************************
public type AvlKey = NodeId;
public type AvlValue = Node;

public function keyToStr
  input AvlKey k;
  output String s;
algorithm
  s := intString(k);
end keyToStr;

public function keyCompare
  input AvlKey i1;
  input AvlKey i2;
  output Integer o;
algorithm
  o := Util.if_(intLt(i1, i2), -1, Util.if_(intGt(i1, i2), 1, 0)); 
end keyCompare;

public uniontype AvlTree
  "The binary tree data structure"
  record AVLTREENODE
    Option<AvlTreeValue> value "Value";
    Integer height "height of tree, used for balancing";
    Option<AvlTree> left "left subtree";
    Option<AvlTree> right "right subtree";
  end AVLTREENODE;
end AvlTree;

public uniontype AvlTreeValue
  "Each node in the binary tree can have a value associated with it."
  record AVLTREEVALUE
    AvlKey key "Key" ;
    AvlValue value "Value" ;
  end AVLTREEVALUE;
end AvlTreeValue;

protected function avlTreeNew
  "Return an empty tree"
  output AvlTree tree;
algorithm
  tree := emptyAvlTree;
end avlTreeNew;

protected function avlTreeAdd
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
    case (AVLTREENODE(value = NONE(), left = NONE(), right = NONE()), _, _, _)
      then AVLTREENODE(SOME(AVLTREEVALUE(inKey, inValue)), 1, NONE(), NONE());

    case (AVLTREENODE(value = SOME(AVLTREEVALUE(key = key))), _, _, _)
      equation
        key_comp = keyCompare(inKey, key);
        tree = avlTreeAdd2(inAvlTree, key_comp, inKey, inValue, inUpdateFunc);
        tree = avlBalance(tree);
      then
        tree;

  end match;
end avlTreeAdd;

protected function avlTreeAdd2
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
    case (AVLTREENODE(SOME(AVLTREEVALUE(key, value)), h, left, right), 0, _, _, _)
      equation
        value = inUpdateFunc(value, inValue);
      then
        AVLTREENODE(SOME(AVLTREEVALUE(key, value)), h, left, right);

    // Insert into right subtree.
    case (AVLTREENODE(oval, h, left, right), 1, _, _, _)
      equation
        t = avlCreateEmptyIfNone(right);
        t = avlTreeAdd(t, inKey, inValue, inUpdateFunc);
      then
        AVLTREENODE(oval, h, left, SOME(t));

    // Insert into left subtree.
    case (AVLTREENODE(oval, h, left, right), -1, _, _, _)
      equation
        t = avlCreateEmptyIfNone(left);
        t = avlTreeAdd(t, inKey, inValue, inUpdateFunc);
      then
        AVLTREENODE(oval, h, SOME(t), right);

  end match;
end avlTreeAdd2;

protected function avlTreeAddUnique
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
    case (AVLTREENODE(value = NONE(), left = NONE(), right = NONE()), _, _)
      then AVLTREENODE(SOME(AVLTREEVALUE(inKey, inValue)), 1, NONE(), NONE());

    case (AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey))), key, value)
      then avlBalance(avlTreeAddUnique2(inAvlTree, keyCompare(key, rkey), key, value));

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Env.avlTreeAddUnique failed"});
      then fail();

  end match;
end avlTreeAddUnique;

protected function avlTreeAddUnique2
  "Helper function to avlTreeAddUnique."
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
      Absyn.Info info;

    // Insert into right subtree.
    case (AVLTREENODE(value = oval, height = h, left = left, right = right),
        1, key, value)
      equation
        t = avlCreateEmptyIfNone(right);
        t = avlTreeAddUnique(t, key, value);
      then
        AVLTREENODE(oval, h, left, SOME(t));

    // Insert into left subtree.
    case (AVLTREENODE(value = oval, height = h, left = left, right = right),
        -1, key, value)
      equation
        t = avlCreateEmptyIfNone(left);
        t = avlTreeAddUnique(t, key, value);
      then
        AVLTREENODE(oval, h, SOME(t), right);
  end match;
end avlTreeAddUnique2;

protected function avlTreeGet
  "Get a value from the binary tree given a key."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  output AvlValue outValue;
protected
  AvlKey rkey;
algorithm
  AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey))) := inAvlTree;
  outValue := avlTreeGet2(inAvlTree, keyCompare(inKey, rkey), inKey);
end avlTreeGet;

protected function avlTreeGet2
  "Helper function to avlTreeGet."
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
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(value = rval))), 0, _)
      then rval;

    // Search to the right.
    case (AVLTREENODE(right = SOME(right)), 1, key)
      then avlTreeGet(right, key);

    // Search to the left.
    case (AVLTREENODE(left = SOME(left)), -1, key)
      then avlTreeGet(left, key);
  end match;
end avlTreeGet2;

protected function avlTreeReplace
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

    case (AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey))), key, value)
      then avlTreeReplace2(inAvlTree, keyCompare(key, rkey), key, value);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Env.avlTreeReplace failed"});
      then fail();

  end match;
end avlTreeReplace;

protected function avlTreeReplace2
  "Helper function to avlTreeReplace."
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
    case (AVLTREENODE(SOME(_), h, left, right), 0, _, _)
      then AVLTREENODE(SOME(AVLTREEVALUE(inKey, inValue)), h, left, right);

    // Insert into right subtree.
    case (AVLTREENODE(oval, h, left, SOME(t)), 1, _, _)
      equation
        t = avlTreeReplace(t, inKey, inValue);
      then
        AVLTREENODE(oval, h, left, SOME(t));

    // Insert into left subtree.
    case (AVLTREENODE(oval, h, SOME(t), right), -1, _, _)
      equation
        t = avlTreeReplace(t, inKey, inValue);
      then
        AVLTREENODE(oval, h, SOME(t), right);

  end match;
end avlTreeReplace2;

protected function avlTreeUpdate
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input UpdateFunc inUpdateFunc;
  input ArgType inArg;
  output AvlTree outAvlTree;

  partial function UpdateFunc
    input AvlValue inValue;
    input ArgType inArg;
    output AvlValue outValue;
  end UpdateFunc;

  replaceable type ArgType subtypeof Any;
protected
  AvlKey key;
  Integer key_comp;
algorithm
  AVLTREENODE(value = SOME(AVLTREEVALUE(key = key))) := inAvlTree;
  key_comp := keyCompare(key, inKey);
  outAvlTree := avlTreeUpdate2(inAvlTree, key_comp, inKey, inUpdateFunc, inArg);
end avlTreeUpdate;

protected function avlTreeUpdate2
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  input UpdateFunc inUpdateFunc;
  input ArgType inArg;
  output AvlTree outAvlTree;

  partial function UpdateFunc
    input AvlValue inValue;
    input ArgType inArg;
    output AvlValue outValue;
  end UpdateFunc;

  replaceable type ArgType subtypeof Any;
algorithm
  outAvlTree := match(inAvlTree, inKeyComp, inKey, inUpdateFunc, inArg)
    local
      AvlKey key;
      AvlValue value;
      Option<AvlTree> left, right;
      Integer h;
      AvlTree t;
      Option<AvlTreeValue> oval;

    case (AVLTREENODE(SOME(AVLTREEVALUE(key, value)), h, left, right), 0, _, _, _)
      equation
        value = inUpdateFunc(value, inArg);
      then
        AVLTREENODE(SOME(AVLTREEVALUE(key, value)), h, left, right);

    case (AVLTREENODE(oval, h, left, SOME(t)), 1, _, _, _)
      equation
        t = avlTreeUpdate(t, inKey, inUpdateFunc, inArg);
      then
        AVLTREENODE(oval, h, left, SOME(t));

    case (AVLTREENODE(oval, h, SOME(t), right), -1, _, _, _)
      equation
        t = avlTreeUpdate(t, inKey, inUpdateFunc, inArg);
      then
        AVLTREENODE(oval, h, SOME(t), right);

  end match;
end avlTreeUpdate2;

protected function avlCreateEmptyIfNone
  "Help function to AvlTreeAdd"
    input Option<AvlTree> t;
    output AvlTree outT;
algorithm
  outT := match(t)
    case (NONE()) then avlTreeNew();
    case (SOME(outT)) then outT;
  end match;
end avlCreateEmptyIfNone;

protected function avlBalance
  "Balances an AvlTree"
  input AvlTree bt;
  output AvlTree outBt;
protected
  Integer d;
algorithm
  d := avlDifferenceInHeight(bt);
  outBt := avlDoBalance(d, bt);
end avlBalance;

protected function avlDoBalance
  "Performs balance if difference is > 1 or < -1"
  input Integer difference;
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := match(difference, bt)
    case(-1, _) then avlComputeHeight(bt);
    case( 0, _) then avlComputeHeight(bt);
    case( 1, _) then avlComputeHeight(bt);
    // d < -1 or d > 1
    else avlDoBalance2(difference < 0, bt);
  end match;
end avlDoBalance;

protected function avlDoBalance2
"help function to doBalance"
  input Boolean inDiffIsNegative;
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := match(inDiffIsNegative,inBt)
    local AvlTree bt;
    case(true,bt)
      equation
        bt = avlDoBalance3(bt);
        bt = avlRotateLeft(bt);
      then bt;
    case(false,bt)
      equation
        bt = avlDoBalance4(bt);
        bt = avlRotateRight(bt);
      then bt;
  end match;
end avlDoBalance2;

protected function avlDoBalance3 "help function to doBalance2"
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(inBt)
    local
      AvlTree rr,bt;
    case(bt)
      equation
        true = avlDifferenceInHeight(Util.getOption(avlRightNode(bt))) > 0;
        rr = avlRotateRight(Util.getOption(avlRightNode(bt)));
        bt = avlSetRight(bt,SOME(rr));
      then bt;
    else inBt;
  end matchcontinue;
end avlDoBalance3;

protected function avlDoBalance4 "help function to doBalance2"
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(inBt)
    local
      AvlTree rl,bt;
    case (bt)
      equation
        true = avlDifferenceInHeight(Util.getOption(avlLeftNode(bt))) < 0;
        rl = avlRotateLeft(Util.getOption(avlLeftNode(bt)));
        bt = avlSetLeft(bt,SOME(rl));
      then bt;
    else inBt;
  end matchcontinue;
end avlDoBalance4;

protected function avlSetRight
  "set right treenode"
  input AvlTree node;
  input Option<AvlTree> right;
  output AvlTree outNode;
protected
  Option<AvlTreeValue> value;
  Option<AvlTree> l;
  Integer height;
algorithm
  AVLTREENODE(value, height, l, _) := node;
  outNode := AVLTREENODE(value, height, l, right);
end avlSetRight;

protected function avlSetLeft
  "set left treenode"
  input AvlTree node;
  input Option<AvlTree> left;
  output AvlTree outNode;
protected
  Option<AvlTreeValue> value;
  Option<AvlTree> r;
  Integer height;
algorithm
  AVLTREENODE(value, height, _, r) := node;
  outNode := AVLTREENODE(value, height, left, r);
end avlSetLeft;

protected function avlLeftNode
  "Retrieve the left subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  AVLTREENODE(left = subNode) := node;
end avlLeftNode;

protected function avlRightNode
  "Retrieve the right subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  AVLTREENODE(right = subNode) := node;
end avlRightNode;

protected function avlExchangeLeft
  "help function to balance"
  input AvlTree inNode;
  input AvlTree inParent;
  output AvlTree outParent "updated parent";
protected
  AvlTree parent, node;
algorithm
  parent := avlSetRight(inParent, avlLeftNode(inNode));
  parent := avlBalance(parent);
  node := avlSetLeft(inNode, SOME(parent));
  outParent := avlBalance(node);
end avlExchangeLeft;

protected function avlExchangeRight
  "help function to balance"
  input AvlTree inNode;
  input AvlTree inParent;
  output AvlTree outParent "updated parent";
protected
  AvlTree parent, node;
algorithm
  parent := avlSetLeft(inParent, avlRightNode(inNode));
  parent := avlBalance(parent);
  node := avlSetRight(inNode, SOME(parent));
  outParent := avlBalance(node);
end avlExchangeRight;

protected function avlRotateLeft
  "help function to balance"
  input AvlTree node;
  output AvlTree outNode "updated node";
algorithm
  outNode := avlExchangeLeft(Util.getOption(avlRightNode(node)), node);
end avlRotateLeft;

protected function avlRotateRight
  "help function to balance"
  input AvlTree node;
  output AvlTree outNode "updated node";
algorithm
  outNode := avlExchangeRight(Util.getOption(avlLeftNode(node)), node);
end avlRotateRight;

protected function avlDifferenceInHeight
  "help function to balance, calculates the difference in height between left
  and right child"
  input AvlTree node;
  output Integer diff;
protected
  Option<AvlTree> l, r;
algorithm
  AVLTREENODE(left = l, right = r) := node;
  diff := avlGetHeight(l) - avlGetHeight(r);
end avlDifferenceInHeight;

protected function avlComputeHeight
  "Compute the height of the AvlTree and store in the node info."
  input AvlTree bt;
  output AvlTree outBt;
protected
  Option<AvlTree> l,r;
  Option<AvlTreeValue> v;
  AvlValue val;
  Integer hl,hr,height;
algorithm
  AVLTREENODE(value = v as SOME(AVLTREEVALUE(value = val)),
    left = l, right = r) := bt;
  hl := avlGetHeight(l);
  hr := avlGetHeight(r);
  height := intMax(hl, hr) + 1;
  outBt := AVLTREENODE(v, height, l, r);
end avlComputeHeight;

protected function avlGetHeight
  "Retrieve the height of a node"
  input Option<AvlTree> bt;
  output Integer height;
algorithm
  height := match(bt)
    case(NONE()) then 0;
    case(SOME(AVLTREENODE(height = height))) then height;
  end match;
end avlGetHeight;

protected function avlPrintTreeStrPP
  input AvlTree inTree;
  output String outString;
algorithm
  outString := avlPrintTreeStrPP2(SOME(inTree), "");
end avlPrintTreeStrPP;

protected function avlPrintTreeStrPP2
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

    case (SOME(AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey)), left = l, right = r)), _)
      equation
        indent = inIndent +& "  ";
        s1 = avlPrintTreeStrPP2(l, indent);
        s2 = avlPrintTreeStrPP2(r, indent);
        res = "\n" +& inIndent +& keyToStr(rkey) +& s1 +& s2;
      then
        res;

    case (SOME(AVLTREENODE(value = NONE(), left = l, right = r)), _)
      equation
        indent = inIndent +& "  ";
        s1 = avlPrintTreeStrPP2(l, indent);
        s2 = avlPrintTreeStrPP2(r, indent);
        res = "\n" +& s1 +& s2;
      then
        res;
  end match;
end avlPrintTreeStrPP2;

public function getNodes
  input Option<AvlTree> inTree;
  input list<AvlValue> inAcc;
  output list<AvlValue> outValues;
algorithm
  outValues := matchcontinue(inTree, inAcc)
    local
      AvlKey rkey;
      Option<AvlTree> l, r;
      list<AvlValue> acc;
      AvlValue val;

    case (NONE(), _) then inAcc;

    case (SOME(AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey, value = val)), left = l, right = r)), acc)
      equation
        acc = getNodes(l, val::acc);
        acc = getNodes(r, acc);
      then
        acc;

    case (SOME(AVLTREENODE(value = NONE(), left = l, right = r)), acc)
      equation
        acc = getNodes(l, acc);
        acc = getNodes(r, acc);
      then
        acc;
  
  end matchcontinue;
end getNodes;

end FGraph;
