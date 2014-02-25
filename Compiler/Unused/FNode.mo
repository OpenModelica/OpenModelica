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

encapsulated package FNode
" file:        FNode.mo
  package:     FNode
  description: A node structure to hold Modelica constructs

  RCS: $Id: FNode.mo 14085 2012-11-27 12:12:40Z adrpo $

  This module builds nodes out of SCode 
"

public import Absyn;
public import SCode;
public import Util;
public import DAE;

public type Ident = Absyn.Ident;
public type NodeId = Integer;
public type Name = Absyn.Ident;
public type Type = DAE.Type;
public type Types = list<DAE.Type>;

public 
uniontype NameRef
  record R "resolved to nodeid"
    Ident name;
    Refs subs;
    NodeId id;
  end R;
  record U "unresolved"
    Ident name;
    Refs subs;
  end U;
end NameRef;

type Ref = list<NameRef>;
type Refs = list<Ref> "multiple references";
type SRefs = Refs "subscripts ref";
type DRefs = Refs "dimension ref";

public uniontype NodeData
  record CL "class"
    SCode.Element e;
    // we don't add the extends and imports in 
    // node's children as they don't have a name
    list<NodeId> exts "extends";
    list<NodeId> imps "imports";
  end CL;
  
  record CO "component"
    SCode.Element e;
  end CO;
  
  record EX "extends"
    SCode.Element e;
  end EX;

  record EN "enum"
    SCode.Enum en;
  end EN;

  record IM "import"
    SCode.Element e;
  end IM;

  record DU "unit"
    SCode.Element e;
  end DU;
  
  record MO "modifier"
    SCode.Mod m;
  end MO;
  
  record BI "binding"
         
  end BI;
  
  record EP "expression"
      
  end EP;
  
  record EQ "equation"
        
  end EQ;
  
  record AL "algorithm"
       
  end AL;
  
  record CR "comp reference"
    Absyn.ComponentRef c;
    Ref r;
  end CR;

  record TR "type reference"
    Absyn.TypeSpec t;
    Ref r;
  end TR;

  record TY "type node"
    Types tys "list since several types with the same name can exist in the same scope (overloading)";
  end TY;

  record ND "no data"
    
  end ND;

end NodeData;

public uniontype Node
  record N
    NodeId id "node id, unique";
    NodeId pid "parent id";
    Name name "the name of the class or comp";
    AvlTree children "the children of a node, i.e. components and classes in a class";
    NodeData data "the node data, i.e. depending on what kind of node it is, a class, a component, etc";
  end N;
end Node;

public constant Node topNode = N(topNodeId, topNodeId, topNodeName, emptyAvlTree, ND());
public constant NodeId topNodeId = -1;
public constant Name topNodeName = ".";

public constant Node noNode = N(noNodeId, noNodeId, noNodeName, emptyAvlTree, ND());
public constant NodeId noNodeId = -2;
public constant Name noNodeName = "$No";

public constant AvlTree emptyAvlTree = AVLTREENODE(NONE(), 0, NONE(), NONE());

public constant Name tyNodeName = "$ty";

protected import Error;
protected import FRef;

public function isTopNodeId
  input NodeId inNodeId;
  output Boolean isTop;
algorithm
  isTop := (inNodeId == topNodeId);
end isTopNodeId;

public function isNoNodeId
  input NodeId inNodeId;
  output Boolean isNo;
algorithm
  isNo := (inNodeId == noNodeId);
end isNoNodeId;

public function getTopNode
  output Node outNode;
algorithm
  outNode := topNode;
end getTopNode;

public function getNodeId
  input Node inNode; 
  output NodeId outNodeId;
algorithm
  N(id = outNodeId) := inNode;
end getNodeId;

public function getNodeName
  input Node inNode;
  output Name outName;
algorithm
  N(name = outName) := inNode;
end getNodeName;

public function getNodeIdName
  input Node inNode;
  output String outStr;
protected
  Name n;
  NodeId id;
algorithm
  N(id = id, name = n) := inNode;
  outStr := n +& "(" +& intString(id) +& ")";
end getNodeIdName;

public function getNodeData
  input Node inNode; 
  output NodeData outNodeData;
algorithm
  N(data = outNodeData) := inNode;
end getNodeData;

public function getNodeParentId
  input Node inNode; 
  output NodeId outNodeId;
algorithm
  N(pid = outNodeId) := inNode;
end getNodeParentId;

public function getChildren
  input Node inNode; 
  output AvlTree outChildren;
algorithm
  N(children = outChildren) := inNode;
end getChildren;

public function getChildId
"@author: adrpo
 retreive a child ID via name"
  input Node inNode;
  input Name inName;
  output NodeId outNodeId;
algorithm
  outNodeId := matchcontinue(inNode, inName)
    local 
      AvlTree children;
      NodeId node;
      NodeId id;
    
    case (_, _)
      equation
        N(children = children) = inNode;
        node = avlTreeGet(children, inName);
      then
        node;
    
    case (N(id = id), _) 
      equation 
        print("FNode.getChildId: Node with name: " +& inName +& " not found in node with id: " +& intString(id));
      then
        fail();
  
  end matchcontinue;
end getChildId;

public function addChildId
  input Node inNode;
  input Name inName;
  input NodeId inChildId;
  output Node outNode;
protected
  AvlTree children;
  NodeId id, pid;
  Name name;
  NodeData data;
algorithm
  N(id, pid, name, children, data) := inNode;
  children := avlTreeAdd(children, inName, inChildId, updateNodeValue);
  outNode := N(id, pid, name, children, data);
end addChildId;

public function refName
  input NodeData inNodeData;
  output String outName;
algorithm
  outName := match(inNodeData)
    local 
      Absyn.ComponentRef cr;
      Absyn.TypeSpec ts;
      String name;
    
    case (CR(cr,_))
      equation
        name = Absyn.crefString(cr);
      then
        name;
    
    case (TR(ts,_))
      equation
        name = Absyn.typeSpecString(ts);
      then
        name;
    
    else 
     equation
       print("FNode.refName: not a reference node!\n"); 
     then
       fail();
  end match;
end refName;

public function mkTRData
  input Absyn.TypeSpec inTs;
  output NodeData outNodeData;
protected
   Ref r;
algorithm
  r := FRef.fromTypeSpec(inTs);
  outNodeData := TR(inTs, r);
end mkTRData;

public function isClass
  input Node inNode;
  output Boolean itIs;
algorithm
  itIs := matchcontinue(inNode)
    case (N(data = CL(e = _))) then true;
    else false;  
  end matchcontinue;
end isClass;

public function isComponent
  input Node inNode;
  output Boolean itIs;
algorithm
  itIs := matchcontinue(inNode)
    case (N(data = CO(e = _))) then true;
    else false;  
  end matchcontinue;
end isComponent;

public function isExtends
  input Node inNode;
  output Boolean itIs;
algorithm
  itIs := matchcontinue(inNode)
    case (N(data = EX(e = _))) then true;
    else false;  
  end matchcontinue;
end isExtends;

public function isImport
  input Node inNode;
  output Boolean itIs;
algorithm
  itIs := matchcontinue(inNode)
    case (N(data = IM(e = _))) then true;
    else false;  
  end matchcontinue;
end isImport;

public function isElement
  input Node n;
  output Boolean itIs;
algorithm
  itIs := isClass(n) or isComponent(n) or isExtends(n) or isImport(n);  
end isElement;

public function nodeDataStr
  input NodeData inNodeData;
  output String outStr;
algorithm
  outStr := match(inNodeData)
    case (CL(e = _)) then "CL";
    case (CO(e = _)) then "CO";
    case (EX(_)) then "EX";
    case (EN(_)) then "EN";
    case (IM(_)) then "IM";
    case (DU(_)) then "DU";
    case (MO(m = _)) then "MO";
    case (BI()) then "BI";
    case (EP()) then "EP";
    case (EQ()) then "EQ";
    case (AL()) then "AL";
    case (CR(c = _)) then "CR";
    case (TR(t = _)) then "TR";
    case (TY(_)) then "TY";
    case (ND()) then "ND";
    else "UKNOWN NODE DATA";
  end match;
end nodeDataStr;

public function getExtendsIds
  input Node inNode;
  output list<NodeId> outExtends;
algorithm
  N(data = CL(exts = outExtends)) := inNode;
end getExtendsIds;

public function getImportIds
  input Node inNode;
  output list<NodeId> outImports;
algorithm
  N(data = CL(imps = outImports)) := inNode;
end getImportIds;

public function addExtendsIds
  input Node inNode;
  input NodeId inId;
  output Node outNode;
protected
  AvlTree children;
  NodeId id, pid;
  Name name;
  NodeData data;
  SCode.Element e;
  list<NodeId> exts;
  list<NodeId> imps;
algorithm
  N(id, pid, name, children, CL(e, exts, imps)) := inNode;
  outNode := N(id, pid, name, children, CL(e, inId::exts, imps));
end addExtendsIds;

public function addImportIds
  input Node inNode;
  input NodeId inId;
  output Node outNode;
protected
  AvlTree children;
  NodeId id, pid;
  Name name;
  NodeData data;
  SCode.Element e;
  list<NodeId> exts;
  list<NodeId> imps;
algorithm
  N(id, pid, name, children, CL(e, exts, imps)) := inNode;
  outNode := N(id, pid, name, children, CL(e, exts, inId::imps));
end addImportIds;

// ************************ AVL Tree implementation ***************************
// ************************ AVL Tree implementation ***************************
// ************************ AVL Tree implementation ***************************
// ************************ AVL Tree implementation ***************************

public type AvlKey = Name;
public type AvlValue = NodeId;

public function updateNodeValue
  input NodeId inOldNodeId;
  input NodeId inNewNodeId;
  output NodeId outNodeId;
algorithm
  outNodeId := inNewNodeId;
end updateNodeValue;

public function compareKey
  input AvlKey i1;
  input AvlKey i2;
  output Integer o;
algorithm
  o := stringCompare(i1, i2); 
end compareKey;

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
        key_comp = compareKey(inKey, key);
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
      then avlBalance(avlTreeAddUnique2(inAvlTree, compareKey(key, rkey), key, value));

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
  outValue := avlTreeGet2(inAvlTree, compareKey(inKey, rkey), inKey);
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
      then avlTreeReplace2(inAvlTree, compareKey(key, rkey), key, value);

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
  key_comp := compareKey(key, inKey);
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
        res = "\n" +& inIndent +& rkey +& s1 +& s2;
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

public function getChildrenIds
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
        acc = getChildrenIds(l, val::acc);
        acc = getChildrenIds(r, acc);
      then
        acc;

    case (SOME(AVLTREENODE(value = NONE(), left = l, right = r)), acc)
      equation
        acc = getChildrenIds(l, acc);
        acc = getChildrenIds(r, acc);
      then
        acc;
  
  end matchcontinue;
end getChildrenIds;

end FNode;
