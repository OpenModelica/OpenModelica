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

encapsulated package FVisit
" file:        FVisit.mo
  package:     FVisit
  description: Visitation info for nodes


"

// public imports
public
import FCore;
import FNode;

// protected imports
protected
import List;
import Error;

public
type Id = FCore.Id;
type Seq = FCore.Seq;
type Next = FCore.Next;
type Node = FCore.Node;
type Ref = FCore.Ref;
type Data = FCore.Data;
type Visit = FCore.Visit;
type VAvlTree = FCore.VAvlTree;
type Visited = FCore.Visited;
type AvlTree = FCore.VAvlTree;
type AvlKey = FCore.VAvlKey;
type AvlValue = FCore.VAvlValue;
type AvlTreeValue = FCore.VAvlTreeValue;

constant Visited emptyVisited = FCore.V(FCore.emptyVAvlTree, FCore.firstId);

public function new
"make a new visited tree"
  output Visited visited;
algorithm
  visited := emptyVisited;
end new;

public function reset
"reset visited information"
  input Visited inVisited;
  output Visited visited;
algorithm
  visited := new();
end reset;

public function next
  input Visited inVisited;
  output Visited outVisited;
  output Next next;
protected
  VAvlTree v;
  Next n;
algorithm
  FCore.V(v, n) := inVisited;
  next := n;
  n := FCore.next(n);
  outVisited := FCore.V(v, n);
end next;

public function visited
"@autor: adrpo
 check if a node was visited"
  input Visited inVisited;
  input Ref inRef;
  output Boolean b;
algorithm
  b := matchcontinue(inVisited, inRef)
    local
      Seq seq;
      AvlTree a;
      Id id;

    // there
    case (FCore.V(tree = a), _)
      equation
        _ = FNode.id(FNode.fromRef(inRef));
        _ = avlTreeGet(a, FNode.id(FNode.fromRef(inRef)));
      then
        true;

    // not there
    else false;
  end matchcontinue;
end visited;

public function seq
 input Visit v;
 output Seq s;
algorithm
 FCore.VN(seq = s) := v;
end seq;

public function ref
 input Visit v;
 output Ref r;
algorithm
 FCore.VN(ref = r) := v;
end ref;

public function tree
 input Visited v;
 output AvlTree a;
algorithm
 FCore.V(tree = a) := v;
end tree;

public function visit
"@autor: adrpo
 add the node to visited"
  input Visited inVisited;
  input Ref inRef;
  output Visited outVisited;
algorithm
  outVisited := matchcontinue(inVisited, inRef)
    local
      Seq s;
      Next n;
      AvlTree a;
      Visit v;
      Id id;

    // already there, something's fishy!
    case (_, _)
      equation
        _ = FNode.id(FNode.fromRef(inRef));
        v = avlTreeGet(tree(inVisited), FNode.id(FNode.fromRef(inRef)));
        print("Already visited: " + FNode.toStr(FNode.fromRef(inRef)) + " seq: " + intString(seq(v)) + "\n");
      then
        fail();

    case (FCore.V(a, _), _)
      equation
        id = FNode.id(FNode.fromRef(inRef));
        failure(_ = avlTreeGet(tree(inVisited), id));
        (FCore.V(next = n), s) = next(inVisited);
        a = avlTreeAdd(a, id, FCore.VN(inRef, s));
        outVisited = FCore.V(a, n);
      then
        outVisited;
  end matchcontinue;
end visit;

// ************************ AVL Tree implementation ***************************
// ************************ AVL Tree implementation ***************************
// ************************ AVL Tree implementation ***************************
// ************************ AVL Tree implementation ***************************

public function keyCompare "compare 2 keys"
  input AvlKey k1;
  input AvlKey k2;
  output Integer i;
algorithm
  i := if intGt(k1, k2) then 1 else (if intLt(k1, k2) then -1 else 0);
end keyCompare;

public function keyStr "prints a key to a string"
  input AvlKey k;
  output String str;
algorithm
  str := intString(k);
end keyStr;

public function valueStr "prints a Value to a string"
  input AvlValue v;
  output String str;
algorithm
  str := match(v)
    local
      Integer seq;
    case (FCore.VN(seq = seq)) then intString(seq);
  end match;
end valueStr;

/* Generic Code below */
public function avlTreeNew "Return an empty tree"
  output AvlTree tree;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  tree := FCore.emptyVAvlTree;
end avlTreeNew;

public function avlTreeAdd
  "Help function to avlTreeAdd."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match (inAvlTree,inKey,inValue)
    local
      AvlKey key,rkey;
      AvlValue value;

    // empty tree
    case (FCore.VAVLTREENODE(value = NONE(),left = NONE(),right = NONE()),key,value)
      then FCore.VAVLTREENODE(SOME(FCore.VAVLTREEVALUE(key,value)),1,NONE(),NONE());

    case (FCore.VAVLTREENODE(value = SOME(FCore.VAVLTREEVALUE(key=rkey))),key,value)
      then balance(avlTreeAdd2(inAvlTree,keyCompare(key,rkey),key,value));

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Env.avlTreeAdd failed"});
      then fail();
  end match;
end avlTreeAdd;

public function avlTreeAdd2
  "Help function to avlTreeAdd."
  input AvlTree inAvlTree;
  input Integer keyComp "0=get value from current node, 1=search right subtree, -1=search left subtree";
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match (inAvlTree,keyComp,inKey,inValue)
    local
      AvlKey key,rkey;
      AvlValue value;
      Option<AvlTree> left,right;
      Integer h;
      AvlTree t_1,t;
      Option<AvlTreeValue> oval;

    /*/ Don't allow replacing of nodes.
    case (_, 0, key, _)
      equation
        info = getItemInfo(inValue);
        Error.addSourceMessage(Error.DOUBLE_DECLARATION_OF_ELEMENTS,
          {inKey}, info);
      then
        fail();*/

    // replace this node
    case (FCore.VAVLTREENODE(value = SOME(FCore.VAVLTREEVALUE(key=rkey)),height=h,left = left,right = right),0,_,value)
      equation
        // inactive for now, but we should check if we don't replace a class with a var or vice-versa!
        // checkValueReplacementCompatible(rval, value);
      then
        FCore.VAVLTREENODE(SOME(FCore.VAVLTREEVALUE(rkey,value)),h,left,right);

    // insert to right
    case (FCore.VAVLTREENODE(value = oval,height=h,left = left,right = right),1,key,value)
      equation
        t = createEmptyAvlIfNone(right);
        t_1 = avlTreeAdd(t, key, value);
      then
        FCore.VAVLTREENODE(oval,h,left,SOME(t_1));

    // insert to left subtree
    case (FCore.VAVLTREENODE(value = oval,height=h,left = left ,right = right),-1,key,value)
      equation
        t = createEmptyAvlIfNone(left);
        t_1 = avlTreeAdd(t, key, value);
      then
        FCore.VAVLTREENODE(oval,h,SOME(t_1),right);

  end match;
end avlTreeAdd2;

protected function createEmptyAvlIfNone "Help function to AvlTreeAdd2"
  input Option<AvlTree> t;
  output AvlTree outT;
algorithm
  outT := match (t)
    case(NONE()) then FCore.VAVLTREENODE(NONE(),0,NONE(),NONE());
    case(SOME(outT)) then outT;
  end match;
end createEmptyAvlIfNone;

protected function nodeValue "return the node value"
  input AvlTree bt;
  output AvlValue v;
algorithm
  v := match (bt)
    case(FCore.VAVLTREENODE(value=SOME(FCore.VAVLTREEVALUE(_,v)))) then v;
  end match;
end nodeValue;

protected function balance "Balances a AvlTree"
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := match (inBt)
    local Integer d; AvlTree bt;
    case (bt)
      equation
        d = differenceInHeight(bt);
        bt = doBalance(d,bt);
      then bt;
  end match;
end balance;

protected function doBalance "perform balance if difference is > 1 or < -1"
  input Integer difference;
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := match (difference,inBt)
    local AvlTree bt;
    case(-1,bt) then computeHeight(bt);
    case(0,bt) then computeHeight(bt);
    case(1,bt) then computeHeight(bt);
      /* d < -1 or d > 1 */
    case(_,bt)
      equation
        bt = doBalance2(difference < 0,bt);
      then bt;
  end match;
end doBalance;

protected function doBalance2 "help function to doBalance"
  input Boolean differenceIsNegative;
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := match (differenceIsNegative,inBt)
    local AvlTree bt;
    case (true,bt)
      equation
        bt = doBalance3(bt);
        bt = rotateLeft(bt);
      then bt;
    case (false,bt)
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
        true = differenceInHeight(getOption(rightNode(bt))) > 0;
        rr = rotateRight(getOption(rightNode(bt)));
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
        true = differenceInHeight(getOption(leftNode(bt))) < 0;
        rl = rotateLeft(getOption(leftNode(bt)));
        bt = setLeft(bt,SOME(rl));
      then bt;
    else inBt;
  end matchcontinue;
end doBalance4;

protected function setRight "set right treenode"
  input AvlTree node;
  input Option<AvlTree> right;
  output AvlTree outNode;
algorithm
  outNode := match (node,right)
   local Option<AvlTreeValue> value;
    Option<AvlTree> l,r;
    Integer height;
    case(FCore.VAVLTREENODE(value,height,l,_),_) then FCore.VAVLTREENODE(value,height,l,right);
  end match;
end setRight;

protected function setLeft "set left treenode"
  input AvlTree node;
  input Option<AvlTree> left;
  output AvlTree outNode;
algorithm
  outNode := match (node,left)
  local Option<AvlTreeValue> value;
    Option<AvlTree> l,r;
    Integer height;
    case(FCore.VAVLTREENODE(value,height,_,r),_) then FCore.VAVLTREENODE(value,height,left,r);
  end match;
end setLeft;

protected function leftNode "Retrieve the left subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  subNode := match(node)
    case(FCore.VAVLTREENODE(left = subNode)) then subNode;
  end match;
end leftNode;

protected function rightNode "Retrieve the right subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  subNode := match(node)
    case(FCore.VAVLTREENODE(right = subNode)) then subNode;
  end match;
end rightNode;

protected function exchangeLeft "help function to balance"
  input AvlTree inNode;
  input AvlTree inParent;
  output AvlTree outParent "updated parent";
algorithm
  outParent := match(inNode,inParent)
    local
      AvlTree bt,node,parent;

    case(node,parent) equation
      parent = setRight(parent,leftNode(node));
      parent = balance(parent);
      node = setLeft(node,SOME(parent));
      bt = balance(node);
    then bt;
  end match;
end exchangeLeft;

protected function exchangeRight "help function to balance"
  input AvlTree inNode;
  input AvlTree inParent;
  output AvlTree outParent "updated parent";
algorithm
  outParent := match(inNode,inParent)
  local AvlTree bt,node,parent;
    case(node,parent) equation
      parent = setLeft(parent,rightNode(node));
      parent = balance(parent);
      node = setRight(node,SOME(parent));
      bt = balance(node);
    then bt;
  end match;
end exchangeRight;

protected function rotateLeft "help function to balance"
input AvlTree node;
output AvlTree outNode "updated node";
algorithm
  outNode := exchangeLeft(getOption(rightNode(node)),node);
end rotateLeft;

protected function getOption "Retrieve the value of an option"
  replaceable type T subtypeof Any;
  input Option<T> opt;
  output T val;
algorithm
  val := match(opt)
    case(SOME(val)) then val;
  end match;
end getOption;

protected function rotateRight "help function to balance"
input AvlTree node;
output AvlTree outNode "updated node";
algorithm
  outNode := exchangeRight(getOption(leftNode(node)),node);
end rotateRight;

protected function differenceInHeight "help function to balance, calculates the difference in height
between left and right child"
  input AvlTree node;
  output Integer diff;
algorithm
  diff := match (node)
    local
      Integer lh,rh;
      Option<AvlTree> l,r;
    case(FCore.VAVLTREENODE(left=l,right=r))
      equation
        lh = getHeight(l);
        rh = getHeight(r);
      then lh - rh;
  end match;
end differenceInHeight;

public function avlTreeGet
  "Get a value from the binary tree given a key."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  output AvlValue outValue;
algorithm
  outValue := match (inAvlTree,inKey)
    local
      AvlKey rkey,key;
    case (FCore.VAVLTREENODE(value = SOME(FCore.VAVLTREEVALUE(key=rkey))),key)
      then avlTreeGet2(inAvlTree,keyCompare(key,rkey),key);
  end match;
end avlTreeGet;

protected function avlTreeGet2
  "Get a value from the binary tree given a key."
  input AvlTree inAvlTree;
  input Integer keyComp "0=get value from current node, 1=search right subtree, -1=search left subtree";
  input AvlKey inKey;
  output AvlValue outValue;
algorithm
  outValue := match (inAvlTree,keyComp,inKey)
    local
      AvlKey key;
      AvlValue rval;
      AvlTree left,right;

    // hash func Search to the right
    case (FCore.VAVLTREENODE(value = SOME(FCore.VAVLTREEVALUE(value=rval))),0,_)
      then rval;

    // search to the right
    case (FCore.VAVLTREENODE(right = SOME(right)),1,key)
      then avlTreeGet(right, key);

    // search to the left
    case (FCore.VAVLTREENODE(left = SOME(left)),-1,key)
      then avlTreeGet(left, key);
  end match;
end avlTreeGet2;

protected function getOptionStr "Retrieve the string from a string option.
  If NONE() return empty string."
  input Option<Type_a> inTypeAOption;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm
  outString:=
  match (inTypeAOption,inFuncTypeTypeAToString)
    local
      String str;
      Type_a a;
      FuncTypeType_aToString r;
    case (SOME(a),r)
      equation
        str = r(a);
      then
        str;
    case (NONE(),_) then "";
  end match;
end getOptionStr;

protected function printAvlTreeStr "
  Prints the avl tree to a string"
  input AvlTree inAvlTree;
  output String outString;
algorithm
  outString:=
  match (inAvlTree)
    local
      AvlKey rkey;
      String s2,s3,res;
      AvlValue rval;
      Option<AvlTree> l,r;
      Integer h;

    case (FCore.VAVLTREENODE(value = SOME(FCore.VAVLTREEVALUE(_,rval)),left = l,right = r))
      equation
        s2 = getOptionStr(l, printAvlTreeStr);
        s3 = getOptionStr(r, printAvlTreeStr);
        res = "\n" + valueStr(rval) + ",  " + (if stringEq(s2, "") then "" else (s2 + ", ")) + s3;
      then
        res;
    case (FCore.VAVLTREENODE(value = NONE(),left = l,right = r))
      equation
        s2 = getOptionStr(l, printAvlTreeStr);
        s3 = getOptionStr(r, printAvlTreeStr);
        res = (if stringEq(s2, "") then "" else (s2 + ", ")) + s3;
      then
        res;
  end match;
end printAvlTreeStr;

protected function computeHeight "compute the heigth of the AvlTree and store in the node info"
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := match(bt)
    local
      Option<AvlTree> l,r;
      Option<AvlTreeValue> v;
      Integer hl,hr,height;
    case(FCore.VAVLTREENODE(value=v as SOME(_),left=l,right=r))
      equation
        hl = getHeight(l);
        hr = getHeight(r);
        height = intMax(hl,hr) + 1;
      then FCore.VAVLTREENODE(v,height,l,r);
  end match;
end computeHeight;

protected function getHeight "Retrieve the height of a node"
  input Option<AvlTree> bt;
  output Integer height;
algorithm
  height := match (bt)
    case(NONE()) then 0;
    case(SOME(FCore.VAVLTREENODE(height = height))) then height;
  end match;
end getHeight;

public function printAvlTreeStrPP
  input AvlTree inTree;
  output String outString;
algorithm
  outString := printAvlTreeStrPP2(SOME(inTree), "");
end printAvlTreeStrPP;

protected function printAvlTreeStrPP2
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

    case (SOME(FCore.VAVLTREENODE(value = SOME(FCore.VAVLTREEVALUE(key = rkey)), left = l, right = r)), _)
      equation
        indent = inIndent + "  ";
        s1 = printAvlTreeStrPP2(l, indent);
        s2 = printAvlTreeStrPP2(r, indent);
        res = "\n" + inIndent + keyStr(rkey) + s1 + s2;
      then
        res;

    case (SOME(FCore.VAVLTREENODE(value = NONE(), left = l, right = r)), _)
      equation
        indent = inIndent + "  ";
        s1 = printAvlTreeStrPP2(l, indent);
        s2 = printAvlTreeStrPP2(r, indent);
        res = "\n" + s1 + s2;
      then
        res;
  end match;
end printAvlTreeStrPP2;

public function avlTreeReplace
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

    case (FCore.VAVLTREENODE(value = SOME(FCore.VAVLTREEVALUE(key = rkey))), key, value)
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
      AvlKey key;
      AvlValue value;
      Option<AvlTree> left, right;
      Integer h;
      AvlTree t;
      Option<AvlTreeValue> oval;

    // Replace this node.
    case (FCore.VAVLTREENODE(value = SOME(_), height = h, left = left, right = right),
        0, key, value)
      then FCore.VAVLTREENODE(SOME(FCore.VAVLTREEVALUE(key, value)), h, left, right);

    // Insert into right subtree.
    case (FCore.VAVLTREENODE(value = oval, height = h, left = left, right = right),
        1, key, value)
      equation
        t = createEmptyAvlIfNone(right);
        t = avlTreeReplace(t, key, value);
      then
        FCore.VAVLTREENODE(oval, h, left, SOME(t));

    // Insert into left subtree.
    case (FCore.VAVLTREENODE(value = oval, height = h, left = left, right = right),
        -1, key, value)
      equation
        t = createEmptyAvlIfNone(left);
        t = avlTreeReplace(t, key, value);
      then
        FCore.VAVLTREENODE(oval, h, SOME(t), right);
  end match;
end avlTreeReplace2;

public function getAvlTreeValues
  input list<Option<AvlTree>> tree;
  input list<AvlTreeValue> acc;
  output list<AvlTreeValue> res;
algorithm
  res := match (tree,acc)
    local
      Option<AvlTreeValue> value;
      Option<AvlTree> left,right;
      list<Option<AvlTree>> rest;
    case ({},_) then acc;
    case (SOME(FCore.VAVLTREENODE(value=value,left=left,right=right))::rest,_)
      then getAvlTreeValues(left::right::rest,List.consOption(value,acc));
    case (NONE()::rest,_) then getAvlTreeValues(rest,acc);
  end match;
end getAvlTreeValues;

public function getAvlValue
  input AvlTreeValue inValue;
  output AvlValue res;
algorithm
  res := match (inValue)
    case FCore.VAVLTREEVALUE(value = res) then res;
  end match;
end getAvlValue;

// ************************ END AVL Tree implementation ***************************
// ************************ END AVL Tree implementation ***************************
// ************************ END AVL Tree implementation ***************************
// ************************ END AVL Tree implementation ***************************

annotation(__OpenModelica_Interface="frontend");
end FVisit;
